import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { PrecoService } from '../precos/preco.service';
import { RelogioAjustavel } from '../../test/support/criar-app';
import { PrismaFake } from '../../test/support/prisma-fake';
import { AssinaturasService } from './assinaturas.service';
import { CriarAssinaturaDto } from './dto/assinatura.dto';
import { MaquinaEstadosService } from './maquina-estados.service';

const ANA = 'cliente-ana';
const BRUNO = 'cliente-bruno';
const END_ANA = 'end-ana'; // Copacabana, Zona Sul (seg/qua/sex)
const END_ANA_NORTE = 'end-ana-norte'; // Tijuca, Zona Norte (ter/qui)
const END_BRUNO = 'end-bruno';

async function codigo(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    if (e instanceof RegraNegocioException) return e.codigo;
    throw e;
  }
  throw new Error('esperava erro');
}

describe('AssinaturasService', () => {
  let prisma: PrismaFake;
  let relogio: RelogioAjustavel;
  let maquina: MaquinaEstadosService;
  let service: AssinaturasService;

  const dto = (extra: Partial<CriarAssinaturaDto> = {}): CriarAssinaturaDto =>
    ({
      itens: [{ produto: 'WP500', quantidade: 24 }],
      frequencia: 'QUINZENAL',
      plano: 'TRIMESTRAL',
      enderecoId: END_ANA,
      janela: 'MANHA',
      formaPagamento: 'PIX',
      ...extra,
    }) as CriarAssinaturaDto;

  /** Simula o que a cr-3 fará: pagamento confirmado do ciclo e assinatura ativa. */
  async function pagar(cicloId: string) {
    const ciclo = prisma.ciclos.find((c) => c.id === cicloId)!;
    if (ciclo.status === 'AGENDADO') await maquina.ciclo(prisma as never, ciclo as never, 'COBRADO');
    await maquina.ciclo(prisma as never, ciclo as never, 'PAGO');
    const a = prisma.assinaturas.find((x) => x.id === ciclo.assinaturaId)!;
    if (a.status === 'AGUARDANDO_PAGAMENTO') await maquina.assinatura(prisma as never, a as never, 'ATIVA');
  }

  const ciclosDe = (assinaturaId: string) =>
    prisma.ciclos.filter((c) => c.assinaturaId === assinaturaId).sort((a, b) => a.numero - b.numero);
  const data = (d: Date) => d.toISOString().slice(0, 10);

  beforeEach(() => {
    prisma = new PrismaFake().carregarCatalogo();
    const zona = (nome: string) => prisma.zonas.find((z) => z.nome === nome)!.id;
    prisma.enderecos.push(
      { id: END_ANA, clienteId: ANA, zonaId: zona('Zona Sul'), cep: '22041001', bairro: 'Copacabana', principal: true },
      { id: END_ANA_NORTE, clienteId: ANA, zonaId: zona('Zona Norte'), cep: '20520050', bairro: 'Tijuca', principal: false },
      { id: END_BRUNO, clienteId: BRUNO, zonaId: zona('Zona Sul'), cep: '22041001', bairro: 'Copacabana', principal: true },
    );
    relogio = new RelogioAjustavel(); // sábado 14/11/2026 12:00 em São Paulo
    maquina = new MaquinaEstadosService();
    const preco = new PrecoService(prisma as unknown as PrismaService, relogio);
    service = new AssinaturasService(prisma as unknown as PrismaService, preco, maquina, relogio);
  });

  describe('criar', () => {
    it('CT02: grava AGUARDANDO_PAGAMENTO, o 1º ciclo de R$ 203,29, CalculoPreco e ItemCiclo (sem Pix)', async () => {
      const r = await service.criar(ANA, dto());
      expect(r).toMatchObject({
        status: 'AGUARDANDO_PAGAMENTO',
        proximaEntrega: '2026-11-16',
        plano: 'TRIMESTRAL',
        fimCompromisso: '2027-02-16',
        ciclo: { numero: 1, valor: 203.29, vencimento: '2026-11-14', dataEntrega: '2026-11-16' },
        detalhePreco: [
          { fator: 'VOLUME', percentual: -8 },
          { fator: 'COMPROMISSO', percentual: -7 },
          { fator: 'FRETE', valor: 0 },
        ],
      });
      expect(r.ciclo).not.toHaveProperty('pix');
      expect(r.ciclo.dataCorte).toBe('2026-11-15T02:59:59.999Z'); // 14/11 23:59 em São Paulo

      const calculo = prisma.calculos[0];
      expect(calculo.subtotal.toString()).toBe('203.29');
      expect(calculo.valorFinal.toString()).toBe('203.29');
      expect(prisma.itensCiclo).toEqual([
        expect.objectContaining({ produtoId: 'prod-WP500', quantidade: 24 }),
      ]);
      expect(prisma.itensCiclo[0].precoUnitario.toString()).toBe('8.47');
      expect(prisma.itensAssinatura).toEqual([expect.objectContaining({ produtoId: 'prod-WP500', quantidade: 24 })]);
      expect(prisma.pagamentos).toHaveLength(0);
    });

    it('primeira entrega estimada no dia da zona ≥ hoje + 2 (Zona Norte: terça 17/11)', async () => {
      const r = await service.criar(ANA, dto({ enderecoId: END_ANA_NORTE, plano: 'FLEX' }));
      expect(r.proximaEntrega).toBe('2026-11-17');
      expect(r.fimCompromisso).toBeNull();
    });

    it('cupom entra no preço e conta um uso', async () => {
      const r = await service.criar(ANA, dto({ plano: 'FLEX', itens: [{ produto: 'WP500', quantidade: 12 }], cupom: 'BEMVINDO10' }));
      expect(r.ciclo.valor).toBe(106.92); // frete grátis acima de R$ 50
      expect(r.cupom).toBe('BEMVINDO10');
      expect(prisma.cupons[0].usos).toBe(1);
    });

    it('endereço de outro cliente → SEM_PERMISSAO; cesta inválida usa o erro do PrecoService', async () => {
      expect(await codigo(service.criar(ANA, dto({ enderecoId: END_BRUNO })))).toBe('SEM_PERMISSAO');
      expect(await codigo(service.criar(ANA, dto({ itens: [{ produto: 'WP500', quantidade: 11 }] })))).toBe('CESTA_ABAIXO_MINIMO');
      expect(await codigo(service.criar(ANA, dto({ itens: [{ produto: 'WP500', quantidade: 5 }, { produto: 'AMS500', quantidade: 12 }] })))).toBe(
        'EMBALAGEM_INVALIDA',
      );
      expect(prisma.assinaturas).toHaveLength(0);
    });

    it('recomendação de outro cliente → SEM_PERMISSAO', async () => {
      prisma.recomendacoes.push({ id: 'rec-bruno', clienteId: BRUNO, criadoEm: new Date() });
      expect(await codigo(service.criar(ANA, dto({ recomendacaoId: 'rec-bruno' })))).toBe('SEM_PERMISSAO');
    });

    it('RN26: cobrança vencida impede criar outra assinatura', async () => {
      const a = await service.criar(ANA, dto());
      prisma.pagamentos.push({ id: 'p1', cicloId: a.ciclo.id, status: 'VENCIDO', vencimento: new Date('2026-11-10T00:00:00Z'), pagoEm: null });
      expect(await codigo(service.criar(ANA, dto()))).toBe('COBRANCA_VENCIDA');
      // Outro cliente não é afetado
      await expect(service.criar(BRUNO, dto({ enderecoId: END_BRUNO }))).resolves.toBeDefined();
    });
  });

  describe('consultar', () => {
    it('CT16: cliente A consultando assinatura do cliente B → SEM_PERMISSAO', async () => {
      const b = await service.criar(BRUNO, dto({ enderecoId: END_BRUNO }));
      expect(await codigo(service.buscar(ANA, b.id))).toBe('SEM_PERMISSAO');
      expect(await codigo(service.ciclos(ANA, b.id))).toBe('SEM_PERMISSAO');
      expect(await codigo(service.alterar(ANA, b.id, { janela: 'TARDE' }))).toBe('SEM_PERMISSAO');
      expect(await codigo(service.cancelar(ANA, b.id))).toBe('SEM_PERMISSAO');
      expect(await codigo(service.pularEntrega(ANA, b.id))).toBe('SEM_PERMISSAO');
      expect(await codigo(service.buscar(ANA, 'nao-existe'))).toBe('NAO_ENCONTRADO');
    });

    it('lista só as do cliente e mostra ciclos com valor e status', async () => {
      const a = await service.criar(ANA, dto());
      await service.criar(BRUNO, dto({ enderecoId: END_BRUNO }));
      expect((await service.listar(ANA)).map((x) => x.id)).toEqual([a.id]);
      const ciclos = await service.ciclos(ANA, a.id);
      expect(ciclos).toEqual([
        expect.objectContaining({ numero: 1, status: 'AGENDADO', valor: 203.29, dataEntrega: '2026-11-16', itens: [{ produto: 'WP500', quantidade: 24, precoUnitario: 8.47 }] }),
      ]);
    });
  });

  describe('pular entrega', () => {
    it('só com a assinatura ativa', async () => {
      const a = await service.criar(ANA, dto());
      expect(await codigo(service.pularEntrega(ANA, a.id))).toBe('TRANSICAO_INVALIDA');
    });

    it('pula a próxima entrega até o corte e agenda a seguinte', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      const r = await service.pularEntrega(ANA, a.id);
      expect(r.pulada).toMatchObject({ numero: 2, dataEntrega: '2026-11-30', status: 'PULADO' });
      expect(r.proximaEntrega).toBe('2026-12-14');
      expect(ciclosDe(a.id).map((c) => [c.numero, c.status])).toEqual([
        [1, 'PAGO'],
        [2, 'PULADO'],
        [3, 'AGENDADO'],
      ]);
    });

    it('CT09: pular depois do corte D-2 → 409 APOS_CORTE', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      await service.ciclos(ANA, a.id);
      // Ciclo 2 entrega 30/11 → corte 28/11 23:59
      await service.pularEntrega(ANA, a.id).then(() => undefined); // pula o 2
      relogio.irPara('2026-12-13', '08:00'); // ciclo 3 entrega 14/12, corte 12/12 23:59 já passou
      expect(await codigo(service.pularEntrega(ANA, a.id))).toBe('APOS_CORTE');
    });

    it('RN10: no máximo 2 pulos seguidos → 422 LIMITE_PULOS', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      await service.pularEntrega(ANA, a.id);
      await service.pularEntrega(ANA, a.id);
      expect(await codigo(service.pularEntrega(ANA, a.id))).toBe('LIMITE_PULOS');
    });
  });

  describe('alterar', () => {
    it('antes do corte, a alteração vale para a próxima entrega (recalcula o 1º ciclo)', async () => {
      const a = await service.criar(ANA, dto());
      const r = await service.alterar(ANA, a.id, { itens: [{ produto: 'WP500', quantidade: 12 }], plano: 'FLEX' });
      expect(r.aplicadaAPartirDe).toEqual({ numero: 1, dataEntrega: '2026-11-16' });
      const [c1] = await service.ciclos(ANA, a.id);
      expect(c1).toMatchObject({ valor: 118.8, itens: [{ produto: 'WP500', quantidade: 12, precoUnitario: 9.9 }] });
      expect(r.fimCompromisso).toBeNull();
    });

    it('CT10: alterar a cesta depois do corte vale para a entrega seguinte', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      await service.pularEntrega(ANA, a.id); // ciclo 2 (30/11) pulado; ciclo 3 em 14/12
      relogio.irPara('2026-12-13'); // depois do corte do ciclo 3 (12/12 23:59)
      const r = await service.alterar(ANA, a.id, { itens: [{ produto: 'WP500', quantidade: 12 }, { produto: 'FF500', quantidade: 12 }] });
      expect(r.aplicadaAPartirDe).toEqual({ numero: 4, dataEntrega: '2026-12-28' });

      const ciclos = await service.ciclos(ANA, a.id);
      const c3 = ciclos.find((c) => c.numero === 3)!;
      // O ciclo 3 fica travado com a cesta antiga
      expect(c3.itens).toEqual([{ produto: 'WP500', quantidade: 24, precoUnitario: expect.any(Number) }]);
      expect(ciclos.find((c) => c.numero === 4)).toMatchObject({ status: 'AGENDADO', dataEntrega: '2026-12-28' });
      // A cesta da assinatura já é a nova (itens em ordem de código)
      expect((await service.buscar(ANA, a.id)).itens).toEqual([
        { produto: 'FF500', quantidade: 12 },
        { produto: 'WP500', quantidade: 12 },
      ]);
    });

    it('cesta inválida, cupom inválido e plano Empresa são recusados', async () => {
      const a = await service.criar(ANA, dto());
      expect(await codigo(service.alterar(ANA, a.id, { itens: [{ produto: 'WP500', quantidade: 6 }] }))).toBe('CESTA_ABAIXO_MINIMO');
      expect(await codigo(service.alterar(ANA, a.id, { cupom: 'NAOEXISTE' }))).toBe('CUPOM_INVALIDO');
    });

    it('Trimestral → Flex durante o compromisso → 422 COMPROMISSO_VIGENTE', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      expect(await codigo(service.alterar(ANA, a.id, { plano: 'FLEX' }))).toBe('COMPROMISSO_VIGENTE');
    });

    it('trocar o endereço muda a zona, o dia e o frete da próxima entrega', async () => {
      const a = await service.criar(ANA, dto());
      const r = await service.alterar(ANA, a.id, { enderecoId: END_ANA_NORTE });
      expect(r.aplicadaAPartirDe).toEqual({ numero: 1, dataEntrega: '2026-11-17' });
      const [c1] = await service.ciclos(ANA, a.id);
      expect(c1).toMatchObject({ dataEntrega: '2026-11-17', valor: 203.29 }); // frete grátis acima de R$ 50
    });

    it('RN26: cobrança vencida bloqueia alterar a cesta, mas não a janela', async () => {
      const a = await service.criar(ANA, dto());
      prisma.pagamentos.push({ id: 'p1', cicloId: a.ciclo.id, status: 'PENDENTE', vencimento: new Date('2026-11-13T00:00:00Z'), pagoEm: null });
      expect(await codigo(service.alterar(ANA, a.id, { itens: [{ produto: 'WP500', quantidade: 12 }] }))).toBe('COBRANCA_VENCIDA');
      await expect(service.alterar(ANA, a.id, { janela: 'TARDE' })).resolves.toMatchObject({ janela: 'TARDE' });
    });
  });

  describe('pausar e retomar', () => {
    it('pausa 1 ou 2 ciclos, adia o fim do compromisso e retoma', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      const r = await service.pausar(ANA, a.id, 2);
      expect(r).toMatchObject({ status: 'PAUSADA', proximaEntrega: '2026-12-28', fimCompromisso: '2027-03-16' });
      expect(ciclosDe(a.id).map((c) => [c.numero, c.status])).toEqual([
        [1, 'PAGO'],
        [2, 'PULADO'],
        [3, 'PULADO'],
        [4, 'AGENDADO'],
      ]);

      // Retomar antes do corte do ciclo 2 devolve as entregas pausadas
      const retomada = await service.retomar(ANA, a.id);
      expect(retomada).toMatchObject({ status: 'ATIVA', proximaEntrega: '2026-11-30', fimCompromisso: '2027-02-16' });
      expect(ciclosDe(a.id).map((c) => [c.numero, c.status, data(c.dataEntrega)])).toEqual([
        [1, 'PAGO', '2026-11-16'],
        [2, 'AGENDADO', '2026-11-30'],
      ]);
    });

    it('CT20: terceira pausa seguida → 422 LIMITE_PAUSAS', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      await service.pausar(ANA, a.id, 1); // ciclo 2 (30/11)
      relogio.irPara('2026-12-01');
      await service.retomar(ANA, a.id); // o ciclo 2 já passou: continua pausado
      await service.pausar(ANA, a.id, 1); // ciclo 3 (14/12): 2 seguidas
      relogio.irPara('2026-12-15');
      await service.retomar(ANA, a.id);
      expect(await codigo(service.pausar(ANA, a.id, 1))).toBe('LIMITE_PAUSAS'); // seria a 3ª seguida
    });

    it('RN11: no máximo 4 ciclos pausados por ano (civil)', async () => {
      relogio.irPara('2027-01-04'); // segunda; semanal na Zona Sul: 1ª entrega qua 06/01
      const a = await service.criar(ANA, dto({ frequencia: 'SEMANAL' }));
      expect(a.proximaEntrega).toBe('2027-01-06');
      await pagar(a.ciclo.id);
      relogio.irPara('2027-01-08');
      await service.pausar(ANA, a.id, 2); // 13/01 e 20/01
      relogio.irPara('2027-01-22');
      await service.retomar(ANA, a.id);
      await pagar(ciclosDe(a.id).find((c) => c.status === 'AGENDADO')!.id); // 27/01 entregue: quebra a sequência
      await service.pausar(ANA, a.id, 2); // 03/02 e 10/02 → 4 em 2027
      relogio.irPara('2027-02-12');
      await service.retomar(ANA, a.id);
      await pagar(ciclosDe(a.id).find((c) => c.status === 'AGENDADO')!.id); // 17/02 entregue
      expect(await codigo(service.pausar(ANA, a.id, 1))).toBe('LIMITE_PAUSAS'); // seria o 5º em 2027
    });

    it('pausar exige assinatura ativa; retomar exige pausada', async () => {
      const a = await service.criar(ANA, dto());
      expect(await codigo(service.pausar(ANA, a.id, 1))).toBe('TRANSICAO_INVALIDA');
      expect(await codigo(service.retomar(ANA, a.id))).toBe('TRANSICAO_INVALIDA');
    });
  });

  describe('cancelar', () => {
    it('Flex: cancela sem multa e não cobra a próxima entrega', async () => {
      const a = await service.criar(ANA, dto({ plano: 'FLEX' }));
      const r = await service.cancelar(ANA, a.id);
      expect(r).toMatchObject({ status: 'CANCELADA', diferencaCompromisso: 0, ciclosPagos: 0 });
      expect(ciclosDe(a.id).map((c) => c.status)).toEqual(['PULADO']);
      expect(await codigo(service.cancelar(ANA, a.id))).toBe('TRANSICAO_INVALIDA');
    });

    it('CT17: Trimestral cancelado no 2º mês → diferença de 7% sobre os ciclos pagos', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      // ciclo 2 (30/11): trava a cesta em D-5 (o job da cr-3 faz isso) e é pago
      const c2 = await service.proximoCicloAberto(a.id);
      await service.congelarCiclo(c2.id);
      await pagar(c2.id);
      relogio.irPara('2027-01-05'); // 2º mês de compromisso (fim em 16/02/2027)
      const r = await service.cancelar(ANA, a.id);
      // 2 ciclos com subtotal 203,29 cada: 203,29 × 7/93 × 2 = 30,60
      expect(r).toMatchObject({ status: 'CANCELADA', ciclosPagos: 2, diferencaCompromisso: 30.6 });
    });

    it('Trimestral depois do fim do compromisso → sem diferença', async () => {
      const a = await service.criar(ANA, dto());
      await pagar(a.ciclo.id);
      relogio.irPara('2027-02-20');
      const r = await service.cancelar(ANA, a.id);
      expect(r.diferencaCompromisso).toBe(0);
    });

    it('ciclo já pago continua para entrega (RN12)', async () => {
      const a = await service.criar(ANA, dto({ plano: 'FLEX' }));
      await pagar(a.ciclo.id);
      relogio.irPara('2026-11-20');
      await service.pularEntrega(ANA, a.id); // cria 2 (pulado) e 3 (agendado)
      await service.cancelar(ANA, a.id);
      expect(ciclosDe(a.id).map((c) => c.status)).toEqual(['PAGO', 'PULADO', 'PULADO']);
    });
  });
});
