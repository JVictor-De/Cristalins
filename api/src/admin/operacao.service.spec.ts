import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { PrismaFake } from '../../test/support/prisma-fake';
import { FakeGateway } from '../asaas/fake.gateway';
import { CobrancaService } from '../asaas/cobranca.service';
import { AssinaturasService } from '../assinaturas/assinaturas.service';
import { MaquinaEstadosService } from '../assinaturas/maquina-estados.service';
import { CreditosService } from '../creditos/creditos.service';
import { NotificacoesService } from '../notificacoes/notificacoes.service';
import { CanalEmail, CanalPush, Mensagem } from '../notificacoes/notificacoes.tipos';
import { MemoriaFotos } from '../ocorrencias/armazenamento-fotos';
import { OcorrenciasService } from '../ocorrencias/ocorrencias.service';
import { PrecoService } from '../precos/preco.service';
import { EstoqueService } from './estoque.service';
import { OperacaoService } from './operacao.service';

class RelogioAjustavel extends ClockService {
  constructor(public instante: Date = new Date('2026-11-14T15:00:00.000Z')) {
    super();
  }
  override agora(): Date {
    return new Date(this.instante);
  }
  irPara(data: string, hora = '12:00'): void {
    this.instante = new Date(`${data}T${hora}:00.000-03:00`);
  }
}

/** Canais de push e e-mail gravando o que seria enviado. */
class Gravador implements CanalPush, CanalEmail {
  pushes: { token: string; m: Mensagem; dados: Record<string, string> }[] = [];
  emails: { para: string; assunto: string; texto: string }[] = [];
  async enviar(a: string, b: Mensagem | string, c: Record<string, string> | string): Promise<void> {
    if (typeof b === 'string') this.emails.push({ para: a, assunto: b, texto: c as string });
    else this.pushes.push({ token: a, m: b, dados: c as Record<string, string> });
  }
}

const ANA = 'cliente-ana';
const END_ANA = 'end-ana';
const JPG = { buffer: Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]), mimetype: 'image/jpeg', size: 7 };

async function codigo(p: Promise<unknown>): Promise<string> {
  try {
    await p;
  } catch (e) {
    if (e instanceof RegraNegocioException) return e.codigo;
    throw e;
  }
  throw new Error('esperava erro');
}

describe('cr-6-operacao — separação, entrega, estoque (RN06), ocorrência (RN15) e avisos', () => {
  let prisma: PrismaFake;
  let relogio: RelogioAjustavel;
  let maquina: MaquinaEstadosService;
  let creditos: CreditosService;
  let cobranca: CobrancaService;
  let assinaturas: AssinaturasService;
  let operacao: OperacaoService;
  let ocorrencias: OcorrenciasService;
  let fotos: MemoriaFotos;
  let canal: Gravador;

  beforeEach(() => {
    process.env.ASAAS_MODE = 'fake';
    prisma = new PrismaFake().carregarCatalogo();
    const zonaSul = prisma.zonas.find((z) => z.nome === 'Zona Sul')!.id;
    prisma.clientes.push({
      id: ANA, nome: 'Ana Teste', cpfCnpj: '52998224725', email: 'ana@cristalins.local', celular: '21999999999',
      senhaHash: 'x', papel: 'CLIENTE', asaasCustomerId: null, indicadoPorId: null, pushToken: 'token-fcm-da-ana-123', excluidoEm: null,
    });
    prisma.enderecos.push({ id: END_ANA, clienteId: ANA, zonaId: zonaSul, cep: '22041001', bairro: 'Copacabana', logradouro: 'Rua A', numero: '1', principal: true });
    relogio = new RelogioAjustavel();
    maquina = new MaquinaEstadosService();
    const db = prisma as unknown as PrismaService;
    canal = new Gravador();
    const notificacoes = new NotificacoesService(db, canal, canal);
    creditos = new CreditosService(db, relogio);
    cobranca = new CobrancaService(db, relogio, maquina, new FakeGateway(), creditos, notificacoes);
    assinaturas = new AssinaturasService(db, new PrecoService(db, relogio), maquina, relogio, cobranca);
    operacao = new OperacaoService(db, maquina, new EstoqueService(creditos), notificacoes);
    fotos = new MemoriaFotos();
    ocorrencias = new OcorrenciasService(db, relogio, creditos, fotos);
  });

  const produto = (codigo: string) => prisma.produtos.find((p) => p.codigo === codigo)!;
  const dia = (d: Date) => d.toISOString().slice(0, 10);

  /** Assinatura de 24 WP500 (Trimestral) com o 1º ciclo pago. */
  async function cicloPago() {
    await assinaturas.criar(ANA, {
      itens: [{ produto: 'WP500', quantidade: 24 }],
      frequencia: 'QUINZENAL',
      plano: 'TRIMESTRAL',
      enderecoId: END_ANA,
      janela: 'MANHA',
      formaPagamento: 'PIX',
    });
    await cobranca.confirmarFake(prisma.pagamentos[0].asaasPaymentId!);
    return prisma.ciclos[0];
  }

  async function entregar(cicloId: string) {
    for (const s of ['SEPARADO', 'EM_ROTA', 'ENTREGUE'] as const) await operacao.atualizarStatus(cicloId, s);
    prisma.ciclos.find((c) => c.id === cicloId)!.atualizadoEm = relogio.agora();
  }

  it('avisos de cobrança e pagamento (RF51) por push e e-mail', async () => {
    await cicloPago();
    expect(canal.pushes.map((p) => p.dados.evento)).toEqual(['COBRANCA', 'PAGAMENTO']);
    expect(canal.emails.map((e) => e.assunto)).toEqual(['Cobrança da sua entrega', 'Pagamento confirmado']);
    expect(canal.emails[0].texto).toContain('R$');
    expect(canal.pushes.every((p) => p.token === 'token-fcm-da-ana-123')).toBe(true);
  });

  it('GET /admin/separacao: ciclos pagos do dia por zona, com a prévia do CT21 e os totais', async () => {
    const c = await cicloPago();
    produto('WP500').estoque = 0;
    produto('FF500').estoque = 50;
    const r = await operacao.separacao(dia(c.dataEntrega));
    expect(r.zonas).toHaveLength(1);
    expect(r.zonas[0].zona).toBe('Zona Sul');
    const [linha] = r.zonas[0].ciclos as Array<{ cliente: string; itens: unknown[]; endereco: { bairro: string } }>;
    expect(linha.cliente).toBe('Ana Teste');
    expect(linha.endereco.bairro).toBe('Copacabana');
    expect(linha.itens).toEqual([expect.objectContaining({ produto: 'FF500', quantidade: 24, acao: 'SUBSTITUIDO', substitui: 'WP500' })]);
    expect(r.totais).toEqual([{ produto: 'FF500', quantidade: 24 }]);
    // Só lista: nada muda antes de separar
    expect(produto('FF500').estoque).toBe(50);
    expect(await codigo(operacao.separacao('30/11/2026'))).toBe('DADOS_INVALIDOS');
    expect((await operacao.separacao('2026-12-25')).zonas).toEqual([]);
  });

  it('CT21 na separação: troca pelo Flow Fiber, baixa o estoque, mantém o preço cobrado e avisa o cliente', async () => {
    const c = await cicloPago();
    const precoCobrado = prisma.itensCiclo.find((i) => i.cicloId === c.id)!.precoUnitario.toString();
    produto('WP500').estoque = 0;
    produto('FF500').estoque = 50;
    canal.pushes = [];
    const r = await operacao.atualizarStatus(c.id, 'SEPARADO');
    expect(r.status).toBe('SEPARADO');
    const itens = prisma.itensCiclo.filter((i) => i.cicloId === c.id);
    expect(itens).toEqual([expect.objectContaining({ produtoId: 'prod-FF500', quantidade: 24 })]);
    expect(itens[0].precoUnitario.toString()).toBe(precoCobrado);
    expect(produto('FF500').estoque).toBe(26);
    expect(r.avisos[0]).toContain('enviamos Flow Fiber');
    expect(canal.pushes).toEqual([expect.objectContaining({ dados: expect.objectContaining({ evento: 'SEPARACAO' }) })]);
    expect(canal.pushes[0].m.corpo).toContain('Sem estoque de Water Protein');
    // Auditoria no cálculo
    expect(prisma.calculos.find((x) => x.cicloId === c.id)!.fatores).toMatchObject({
      estoque: [{ produto: 'WP500', quantidade: 24, acao: 'SUBSTITUIDO', por: 'FF500' }],
    });
  });

  it('RN06 sem substituto: item pulado vira crédito do valor cobrado (90 dias)', async () => {
    const c = await cicloPago();
    produto('WP500').estoque = 0;
    produto('FF500').estoque = 0;
    const item = prisma.itensCiclo.find((i) => i.cicloId === c.id)!;
    const esperado = (Number(item.precoUnitario.toString()) * 24).toFixed(2);
    const r = await operacao.atualizarStatus(c.id, 'SEPARADO');
    expect(prisma.itensCiclo.filter((i) => i.cicloId === c.id)).toEqual([]);
    expect(prisma.creditos).toEqual([expect.objectContaining({ clienteId: ANA, motivo: `ESTOQUE:${c.id}:WP500` })]);
    expect(Number(prisma.creditos[0].valor).toFixed(2)).toBe(esperado);
    expect(r.avisos[0]).toContain('virou crédito');
  });

  it('RN16: só separa ciclo pago (COBRADO → SEPARADO = 409); ciclo inexistente = 404', async () => {
    await assinaturas.criar(ANA, {
      itens: [{ produto: 'WP500', quantidade: 12 }], frequencia: 'QUINZENAL', plano: 'FLEX', enderecoId: END_ANA, janela: 'MANHA', formaPagamento: 'PIX',
    });
    expect(await codigo(operacao.atualizarStatus(prisma.ciclos[0].id, 'SEPARADO'))).toBe('TRANSICAO_INVALIDA');
    expect(await codigo(operacao.atualizarStatus('nao-existe', 'EM_ROTA'))).toBe('NAO_ENCONTRADO');
  });

  it('RN17: 1ª falha remarca grátis no próximo dia de rota da zona; 2ª falha pede nova taxa ou retirada', async () => {
    const c = await cicloPago();
    const original = dia(c.dataEntrega);
    await operacao.atualizarStatus(c.id, 'SEPARADO');
    await operacao.atualizarStatus(c.id, 'EM_ROTA');
    const f1 = await operacao.atualizarStatus(c.id, 'FALHOU');
    expect(f1.tentativasEntrega).toBe(1);
    expect(f1.dataEntrega > original).toBe(true);
    expect(['MON', 'WED', 'FRI'][[1, 3, 5].indexOf(new Date(`${f1.dataEntrega}T00:00:00Z`).getUTCDay())]).toBeDefined(); // seg/qua/sex
    expect(f1.avisos[0]).toContain('sem custo');

    await operacao.atualizarStatus(c.id, 'EM_ROTA');
    const f2 = await operacao.atualizarStatus(c.id, 'FALHOU');
    expect(f2.tentativasEntrega).toBe(2);
    expect(f2.dataEntrega).toBe(f1.dataEntrega);
    expect(f2.avisos[0]).toContain('nova taxa de entrega');
    expect(canal.pushes.filter((p) => p.dados.evento === 'ENTREGA')).toHaveLength(4); // 2× em rota + 2× falhou
  });

  describe('ocorrência (RN15)', () => {
    it('crédito na hora no valor pago do item; foto guardada sem URL pública', async () => {
      const c = await cicloPago();
      await entregar(c.id);
      const preco = Number(prisma.itensCiclo.find((i) => i.cicloId === c.id)!.precoUnitario.toString());
      const r = await ocorrencias.criar(ANA, { cicloId: c.id, tipo: 'AVARIA', produto: 'WP500', quantidade: 2, solucao: 'CREDITO' }, JPG);
      expect(r).toMatchObject({ tipo: 'AVARIA', produto: 'WP500', quantidade: 2, solucao: 'CREDITO', status: 'RESOLVIDA', temFoto: true });
      expect(r.credito).toBeCloseTo(preco * 2, 2);
      expect(prisma.creditos).toEqual([expect.objectContaining({ motivo: `OCORRENCIA:${r.id}` })]);
      expect(prisma.ocorrencias[0].fotoUrl).toBe(`s3://memoria/ocorrencias/${c.id}/${r.id}.jpg`);
      expect(fotos.objetos.size).toBe(1);
      expect(JSON.stringify(r)).not.toContain('s3://');
      expect(await ocorrencias.listar(ANA)).toEqual([expect.objectContaining({ id: r.id, credito: r.credito })]);
    });

    it('reposição: fica aberta, entra na separação da próxima entrega e é resolvida nela', async () => {
      const c1 = await cicloPago();
      await entregar(c1.id);
      const r = await ocorrencias.criar(ANA, { cicloId: c1.id, tipo: 'FALTA', produto: 'WP500', quantidade: 3, solucao: 'REPOSICAO' }, JPG);
      expect(r.status).toBe('ABERTA');
      expect(prisma.creditos).toEqual([]);

      // Próxima entrega: ciclo 2 pago
      const a = prisma.assinaturas[0];
      const c2 = await assinaturas.proximoCicloAberto(a.id);
      await assinaturas.congelarCiclo(c2.id);
      const ciclo2 = prisma.ciclos.find((c) => c.id === c2.id)!;
      await maquina.ciclo(prisma as never, ciclo2 as never, 'COBRADO');
      await maquina.ciclo(prisma as never, ciclo2 as never, 'PAGO');
      produto('WP500').estoque = 100;

      const lista = await operacao.separacao(dia(ciclo2.dataEntrega));
      const linha = lista.zonas[0].ciclos[0] as { reposicoes: unknown[] };
      expect(linha.reposicoes).toEqual([expect.objectContaining({ ocorrenciaId: r.id, produto: 'WP500', quantidade: 3 })]);
      expect(lista.totais).toEqual([{ produto: 'WP500', quantidade: 27 }]);

      const s = await operacao.atualizarStatus(ciclo2.id, 'SEPARADO');
      expect(prisma.ocorrencias[0].status).toBe('RESOLVIDA');
      expect(produto('WP500').estoque).toBe(100 - 24 - 3);
      expect(s.avisos).toContain('A reposição de 3 Water Protein (água com colágeno) vai nesta entrega.');
    });

    it('regras: entrega feita, 24 h, produto da entrega, quantidade, foto e dono', async () => {
      const c = await cicloPago();
      const base = { cicloId: c.id, tipo: 'AVARIA' as const, produto: 'WP500', quantidade: 1, solucao: 'CREDITO' as const };
      expect(await codigo(ocorrencias.criar(ANA, base, JPG))).toBe('OCORRENCIA_INVALIDA'); // ainda não entregue
      await entregar(c.id);
      expect(await codigo(ocorrencias.criar(ANA, base, undefined))).toBe('DADOS_INVALIDOS');
      expect(await codigo(ocorrencias.criar(ANA, base, { ...JPG, mimetype: 'application/pdf' }))).toBe('DADOS_INVALIDOS');
      expect(await codigo(ocorrencias.criar(ANA, { ...base, produto: 'FF500' }, JPG))).toBe('DADOS_INVALIDOS');
      expect(await codigo(ocorrencias.criar(ANA, { ...base, quantidade: 25 }, JPG))).toBe('DADOS_INVALIDOS');
      expect(await codigo(ocorrencias.criar('outro-cliente', base, JPG))).toBe('SEM_PERMISSAO');
      // Já informadas contam no limite da entrega
      await ocorrencias.criar(ANA, { ...base, quantidade: 20 }, JPG);
      expect(await codigo(ocorrencias.criar(ANA, { ...base, quantidade: 5 }, JPG))).toBe('DADOS_INVALIDOS');
      // Depois de 24 h
      relogio.instante = new Date(relogio.agora().getTime() + 24 * 60 * 60 * 1000 + 1);
      expect(await codigo(ocorrencias.criar(ANA, base, JPG))).toBe('PRAZO_OCORRENCIA_ENCERRADO');
    });
  });
});
