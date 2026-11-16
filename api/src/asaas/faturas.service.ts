import { forwardRef, HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString } from 'class-validator';
import { FormaPagamento, Prisma, StatusAssinatura, StatusCiclo, StatusPagamento } from '../../prisma/generated/prisma/client';
import { AssinaturasService } from '../assinaturas/assinaturas.service';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { dinheiro } from '../precos/preco.service';
import { dec } from '../precos/preco.tipos';
import { CobrancaService } from './cobranca.service';
import { PAGAMENTO_GATEWAY, PagamentoGateway } from './pagamento.gateway';

/** RN14: arrependimento em até 7 dias da primeira compra. */
export const DIAS_ARREPENDIMENTO = 7;

export class FaturaResponse {
  @ApiProperty() id: string;
  @ApiProperty({ example: 2 }) cicloNumero: number;
  @ApiProperty({ example: '2026-11-30' }) dataEntrega: string;
  @ApiProperty({ enum: FormaPagamento }) forma: FormaPagamento;
  @ApiProperty({ example: 213.19 }) valor: number;
  @ApiProperty({ example: '2026-11-25' }) vencimento: string;
  @ApiProperty({ enum: StatusPagamento }) status: StatusPagamento;
  @ApiPropertyOptional({ nullable: true, type: String, description: 'Boleto ou fatura do Asaas' }) link: string | null;
  @ApiProperty({ description: 'Há comprovante (pagas)' }) temComprovante: boolean;
  @ApiPropertyOptional({ nullable: true, type: String, example: 'Cartão recusado. Nova tentativa em 26/11.' })
  observacao: string | null;
}

export class TrocarFormaDto {
  @ApiProperty({ enum: [FormaPagamento.PIX, FormaPagamento.BOLETO, FormaPagamento.CARTAO] })
  @IsIn([FormaPagamento.PIX, FormaPagamento.BOLETO, FormaPagamento.CARTAO], { message: 'Escolha Pix, boleto ou cartão.' })
  formaPagamento: FormaPagamento;

  @ApiPropertyOptional({ description: 'Obrigatório no cartão: um cartão já cadastrado (POST /cartoes)' })
  @IsOptional()
  @IsString()
  cartaoId?: string;
}

export class FormaResponse {
  @ApiProperty({ enum: FormaPagamento }) formaPagamento: FormaPagamento;
  @ApiPropertyOptional({ nullable: true, example: { bandeira: 'VISA', final: '4444' } })
  cartao: { bandeira: string; final: string } | null;
}

export class ArrependimentoResponse {
  @ApiProperty({ enum: ['INTEGRAL', 'APOS_DEVOLUCAO'] }) estorno: 'INTEGRAL' | 'APOS_DEVOLUCAO';
  @ApiProperty({ example: 213.19 }) valorEstornado: number;
  @ApiProperty({ example: 'Assinatura cancelada. O estorno integral foi pedido ao Asaas.' }) mensagem: string;
}

const erro = (codigo: string, mensagem: string, status: HttpStatus, campo?: string) =>
  new RegraNegocioException(codigo, mensagem, status, campo);

@Injectable()
export class FaturasService {
  private readonly log = new Logger(FaturasService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly cobranca: CobrancaService,
    @Inject(PAGAMENTO_GATEWAY) private readonly gateway: PagamentoGateway,
    @Inject(forwardRef(() => AssinaturasService)) private readonly assinaturas: AssinaturasService,
  ) {}

  /** Faturas (cobranças) das assinaturas do cliente, mais recentes primeiro. */
  async listar(clienteId: string): Promise<FaturaResponse[]> {
    const pagamentos = await this.prisma.pagamento.findMany({
      where: { ciclo: { assinatura: { clienteId } } },
      include: { ciclo: true },
      orderBy: { criadoEm: 'desc' },
    });
    return pagamentos.map((p) => ({
      id: p.id,
      cicloNumero: p.ciclo.numero,
      dataEntrega: p.ciclo.dataEntrega.toISOString().slice(0, 10),
      forma: p.forma,
      valor: dinheiro(dec(p.valor)),
      vencimento: p.vencimento.toISOString().slice(0, 10),
      status: p.status,
      link: p.linkPagamento,
      temComprovante: p.status === StatusPagamento.PAGO && !!p.asaasPaymentId,
      observacao: this.observacao(p),
    }));
  }

  private observacao(p: { forma: FormaPagamento; status: StatusPagamento; asaasPaymentId: string | null; valor: { toString(): string } }) {
    if (p.forma === FormaPagamento.CARTAO && p.status === StatusPagamento.CANCELADO) return 'Cartão recusado.';
    if (p.forma === FormaPagamento.CARTAO && p.status === StatusPagamento.PENDENTE && !p.asaasPaymentId) {
      return 'Nova tentativa no cartão agendada.';
    }
    if (p.status === StatusPagamento.PAGO && !p.asaasPaymentId && dec(p.valor).isZero()) return 'Pago com créditos.';
    if (p.status === StatusPagamento.VENCIDO) return 'Vencida. Pague para não suspender a assinatura.';
    return null;
  }

  /** Comprovante de uma fatura paga (link do Asaas). */
  async comprovante(clienteId: string, id: string): Promise<{ url: string }> {
    const p = await this.prisma.pagamento.findUnique({ where: { id }, include: { ciclo: { include: { assinatura: true } } } });
    if (!p) throw erro('NAO_ENCONTRADO', 'Fatura não encontrada.', HttpStatus.NOT_FOUND);
    if (p.ciclo.assinatura.clienteId !== clienteId) throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
    if (p.status !== StatusPagamento.PAGO || !p.asaasPaymentId) {
      throw erro('COMPROVANTE_INDISPONIVEL', 'O comprovante fica disponível depois do pagamento.', HttpStatus.UNPROCESSABLE_ENTITY);
    }
    const detalhe = await this.gateway.obterCobranca(p.asaasPaymentId);
    const url = detalhe.comprovante ?? detalhe.linkFatura;
    if (!url) throw erro('COMPROVANTE_INDISPONIVEL', 'O comprovante ainda não está disponível.', HttpStatus.UNPROCESSABLE_ENTITY);
    return { url };
  }

  /** Troca da forma de pagamento: vale para a próxima cobrança (a atual não muda). */
  async trocarForma(clienteId: string, assinaturaId: string, dto: TrocarFormaDto): Promise<FormaResponse> {
    const a = await this.assinaturaDoCliente(clienteId, assinaturaId);
    if (a.status === StatusAssinatura.CANCELADA) {
      throw erro('TRANSICAO_INVALIDA', 'Assinatura cancelada não pode ser alterada.', HttpStatus.CONFLICT);
    }
    let cartao: { id: string; bandeira: string; final: string } | null = null;
    if (dto.formaPagamento === FormaPagamento.CARTAO) {
      if (!dto.cartaoId) throw erro('DADOS_INVALIDOS', 'Escolha um cartão cadastrado.', HttpStatus.BAD_REQUEST, 'cartaoId');
      cartao = await this.prisma.cartao.findUnique({ where: { id: dto.cartaoId } });
      if (!cartao) throw erro('NAO_ENCONTRADO', 'Cartão não encontrado.', HttpStatus.NOT_FOUND, 'cartaoId');
      if ((cartao as { clienteId?: string }).clienteId !== clienteId) {
        throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
      }
    }
    await this.prisma.assinatura.update({
      where: { id: a.id },
      data: { formaPagamento: dto.formaPagamento, cartaoId: cartao?.id ?? null },
    });
    return { formaPagamento: dto.formaPagamento, cartao: cartao ? { bandeira: cartao.bandeira, final: cartao.final } : null };
  }

  async forma(clienteId: string, assinaturaId: string): Promise<FormaResponse> {
    const a = await this.assinaturaDoCliente(clienteId, assinaturaId);
    const cartao = a.cartaoId ? await this.prisma.cartao.findUnique({ where: { id: a.cartaoId } }) : null;
    return { formaPagamento: a.formaPagamento, cartao: cartao ? { bandeira: cartao.bandeira, final: cartao.final } : null };
  }

  /**
   * RN14: até 7 dias da assinatura. Sem entrega feita: estorno integral das cobranças pagas e
   * assinatura cancelada (sem a diferença do RN13). Com entrega: cancela e registra o pedido;
   * o estorno sai depois da devolução dos produtos lacrados.
   */
  async arrepender(clienteId: string, assinaturaId: string): Promise<ArrependimentoResponse> {
    const a = await this.assinaturaDoCliente(clienteId, assinaturaId);
    if (a.status === StatusAssinatura.CANCELADA) {
      throw erro('TRANSICAO_INVALIDA', 'A assinatura já está cancelada.', HttpStatus.CONFLICT);
    }
    const limite = new Date(a.criadoEm.getTime() + DIAS_ARREPENDIMENTO * 24 * 60 * 60 * 1000);
    if (this.clock.agora() > limite) {
      throw erro(
        'PRAZO_ARREPENDIMENTO_ENCERRADO',
        'O arrependimento vale até 7 dias depois da assinatura. Você ainda pode cancelar.',
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
    const ciclos = await this.prisma.ciclo.findMany({ where: { assinaturaId: a.id }, include: { pagamentos: true } });
    const entregue = ciclos.some((c) => c.status === StatusCiclo.ENTREGUE);
    const pagos = ciclos.flatMap((c) => c.pagamentos).filter((p) => p.status === StatusPagamento.PAGO && p.asaasPaymentId);
    const valorPago = pagos.reduce((s, p) => s.plus(dec(p.valor)), dec(0));

    await this.assinaturas.cancelar(clienteId, a.id);

    if (entregue) {
      await this.registrar(`arrependimento:${a.id}`, 'ARREPENDIMENTO_AGUARDANDO_DEVOLUCAO', { assinaturaId: a.id, valor: valorPago.toFixed(2) });
      return {
        estorno: 'APOS_DEVOLUCAO',
        valorEstornado: 0,
        mensagem: 'Assinatura cancelada. O estorno sai depois da devolução dos produtos lacrados.',
      };
    }
    for (const p of pagos) {
      await this.gateway.estornar(p.asaasPaymentId!);
      await this.cobranca.registrarEstorno(p.id, p.cicloId);
    }
    return {
      estorno: 'INTEGRAL',
      valorEstornado: dinheiro(valorPago),
      mensagem: 'Assinatura cancelada. O estorno integral foi pedido ao Asaas.',
    };
  }

  private async registrar(idEvento: string, tipo: string, payload: Record<string, unknown>) {
    try {
      await this.prisma.eventoWebhook.create({
        data: { idEvento, tipo, payload: payload as Prisma.InputJsonValue, processadoEm: this.clock.agora() },
      });
    } catch (e) {
      if ((e as { code?: string }).code !== 'P2002') throw e;
    }
    this.log.log(`${tipo}: ${JSON.stringify(payload)}`);
  }

  private async assinaturaDoCliente(clienteId: string, id: string) {
    const a = await this.prisma.assinatura.findUnique({ where: { id } });
    if (!a) throw erro('NAO_ENCONTRADO', 'Assinatura não encontrada.', HttpStatus.NOT_FOUND);
    if (a.clienteId !== clienteId) throw erro('SEM_PERMISSAO', 'Você não tem permissão para esta ação.', HttpStatus.FORBIDDEN);
    return a;
  }
}
