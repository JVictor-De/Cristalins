import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { FormaPagamento, StatusAssinatura, StatusCiclo, StatusPagamento } from '../../prisma/generated/prisma/client';
import { primeiraEntrega } from '../ciclos/agenda';
import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { PAGAMENTO_GATEWAY, PagamentoGateway, PixQrCode } from './pagamento.gateway';

export interface PixDoCiclo extends PixQrCode {
  pagamentoId: string;
  asaasPaymentId: string;
  vencimento: string;
  valor: number;
}

/**
 * Orquestra cobrança Pix por ciclo e confirmação (webhook / Fake).
 * Status só via `MaquinaEstadosService`.
 */
@Injectable()
export class CobrancaService {
  private readonly log = new Logger(CobrancaService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: ClockService,
    private readonly maquina: MaquinaEstadosService,
    @Inject(PAGAMENTO_GATEWAY) private readonly gateway: PagamentoGateway,
  ) {}

  /** Garante `asaasCustomerId` no cliente e cria cobrança Pix + registro `Pagamento`. */
  async cobrarCicloPix(cicloId: string): Promise<PixDoCiclo> {
    const ciclo = await this.prisma.ciclo.findUnique({
      where: { id: cicloId },
      include: {
        calculoPreco: true,
        assinatura: { include: { cliente: true } },
        pagamentos: { orderBy: { criadoEm: 'desc' } },
      },
    });
    if (!ciclo?.calculoPreco) {
      throw new RegraNegocioException('NAO_ENCONTRADO', 'Ciclo sem cálculo de preço.', HttpStatus.NOT_FOUND);
    }
    const pendente = ciclo.pagamentos.find((p) => p.status === StatusPagamento.PENDENTE && p.asaasPaymentId);
    if (pendente?.asaasPaymentId) {
      const pix = await this.gateway.obterPixQrCode(pendente.asaasPaymentId);
      return {
        ...pix,
        pagamentoId: pendente.id,
        asaasPaymentId: pendente.asaasPaymentId,
        vencimento: pendente.vencimento.toISOString().slice(0, 10),
        valor: Number(pendente.valor),
      };
    }

    const cliente = ciclo.assinatura.cliente;
    let customerId = cliente.asaasCustomerId;
    if (!customerId) {
      customerId = await this.gateway.criarCliente({
        id: cliente.id,
        nome: cliente.nome,
        cpfCnpj: cliente.cpfCnpj,
        email: cliente.email,
        celular: cliente.celular,
      });
      await this.prisma.cliente.update({ where: { id: cliente.id }, data: { asaasCustomerId: customerId } });
    }

    const valor = Number(ciclo.calculoPreco.valorFinal);
    const vencimento = this.clock.hoje();
    const cobranca = await this.gateway.criarCobrancaPix({
      customerId,
      valor,
      vencimento,
      externalReference: ciclo.id,
      descricao: `Ciclo ${ciclo.numero} — Cristalins`,
    });
    const pix = await this.gateway.obterPixQrCode(cobranca.id);
    const pagamento = await this.prisma.pagamento.create({
      data: {
        cicloId: ciclo.id,
        asaasPaymentId: cobranca.id,
        forma: FormaPagamento.PIX,
        valor: String(valor),
        vencimento: new Date(`${vencimento}T00:00:00.000Z`),
        status: StatusPagamento.PENDENTE,
      },
    });
    return {
      ...pix,
      pagamentoId: pagamento.id,
      asaasPaymentId: cobranca.id,
      vencimento,
      valor,
    };
  }

  /**
   * Confirma pagamento do ciclo: AGENDADO→COBRADO→PAGO (ou COBRADO→PAGO),
   * assinatura AGUARDANDO→ATIVA, recalcula 1ª entrega (RN08).
   */
  async confirmarPagamentoDoCiclo(cicloId: string, asaasPaymentId?: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const ciclo = await tx.ciclo.findUnique({
        where: { id: cicloId },
        include: {
          assinatura: { include: { endereco: { include: { zona: true } } } },
          pagamentos: true,
        },
      });
      if (!ciclo) return;

      if (ciclo.status === StatusCiclo.PAGO || ciclo.status === StatusCiclo.CANCELADO || ciclo.status === StatusCiclo.PULADO) {
        return; // idempotente
      }

      if (ciclo.status === StatusCiclo.AGENDADO) {
        await this.maquina.ciclo(tx, ciclo, StatusCiclo.COBRADO);
      }
      if (ciclo.status === StatusCiclo.COBRADO) {
        await this.maquina.ciclo(tx, ciclo, StatusCiclo.PAGO);
      }

      const pagamento =
        ciclo.pagamentos.find((p) => asaasPaymentId && p.asaasPaymentId === asaasPaymentId) ??
        ciclo.pagamentos.find((p) => p.status === StatusPagamento.PENDENTE) ??
        ciclo.pagamentos[0];
      if (pagamento && pagamento.status !== StatusPagamento.PAGO) {
        await tx.pagamento.update({
          where: { id: pagamento.id },
          data: { status: StatusPagamento.PAGO, pagoEm: this.clock.agora() },
        });
      }

      const assinatura = ciclo.assinatura;
      if (assinatura.status === StatusAssinatura.AGUARDANDO_PAGAMENTO) {
        await this.maquina.assinatura(tx, assinatura, StatusAssinatura.ATIVA);
        // RN08: recalcula a 1ª entrega a partir da confirmação
        if (ciclo.numero === 1) {
          const nova = primeiraEntrega(this.clock.hoje(), assinatura.endereco.zona.diasEntrega);
          const { dataCorte } = await import('../ciclos/agenda');
          await tx.ciclo.update({
            where: { id: ciclo.id },
            data: {
              dataEntrega: new Date(`${nova}T00:00:00.000Z`),
              dataCorte: dataCorte(nova),
            },
          });
          await tx.assinatura.update({
            where: { id: assinatura.id },
            data: { inicio: new Date(`${nova}T00:00:00.000Z`) },
          });
        }
      }
    });
  }

  /** Fake: confirma cobrança e aplica o mesmo efeito do webhook. */
  async confirmarFake(asaasPaymentId: string): Promise<void> {
    if (!this.gateway.confirmarPagamento) {
      throw new RegraNegocioException(
        'GATEWAY_INDISPONIVEL',
        'Confirmação manual só existe com ASAAS_MODE=fake.',
        HttpStatus.BAD_GATEWAY,
      );
    }
    await this.gateway.confirmarPagamento(asaasPaymentId);
    const pagamento = await this.prisma.pagamento.findFirst({ where: { asaasPaymentId } });
    if (!pagamento) {
      this.log.warn(`Pagamento local não encontrado para ${asaasPaymentId}`);
      return;
    }
    await this.confirmarPagamentoDoCiclo(pagamento.cicloId, asaasPaymentId);
  }
}
