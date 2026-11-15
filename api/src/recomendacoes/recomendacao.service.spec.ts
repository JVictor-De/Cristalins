import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { PrecoService } from '../precos/preco.service';
import { ClockFixo } from '../../test/support/criar-app';
import { PrismaFake } from '../../test/support/prisma-fake';
import { CriarRecomendacaoDto } from './dto/criar-recomendacao.dto';
import { RecomendacaoService } from './recomendacao.service';

const CLIENTE = 'cliente-1';

function respostas(extra: Partial<CriarRecomendacaoDto> = {}): CriarRecomendacaoDto {
  return { objetivo: 'TREINO', diasSemana: '5-7', pessoas: '1', flowFiber: false, comGas: false, ...extra };
}

const itens = (r: { itens: { produto: string; quantidade: number }[] }) =>
  Object.fromEntries(r.itens.map((i) => [i.produto, i.quantidade]));

describe('RecomendacaoService', () => {
  let prisma: PrismaFake;
  let service: RecomendacaoService;

  function criar(instante = new Date('2026-11-14T15:00:00.000Z')) {
    const clock = new ClockFixo(instante);
    const preco = new PrecoService(prisma as unknown as PrismaService, clock);
    service = new RecomendacaoService(prisma as unknown as PrismaService, preco);
  }

  beforeEach(() => {
    prisma = new PrismaFake().carregarCatalogo();
    criar();
  });

  it('CT03 / caso A: Treino, 5–7 dias, 1 pessoa → KIT-TREINO, 12 WP500, quinzenal, R$ 118,80', async () => {
    const r = await service.recomendar(CLIENTE, respostas());
    expect(r).toMatchObject({
      kit: 'KIT-TREINO',
      multiplicador: 1,
      frequencia: 'QUINZENAL',
      itens: [{ produto: 'WP500', quantidade: 12 }],
      ue: 12,
      valorEstimado: 118.8,
      perfilEmpresa: false,
    });
  });

  it('CT04 / caso B: Casa, 3–4 dias, 3 pessoas, com Flow Fiber → 3 WP500 + 3 FF500 + 2 AMN5000, semanal, R$ 70,10', async () => {
    const r = await service.recomendar(
      CLIENTE,
      respostas({ objetivo: 'CASA', diasSemana: '3-4', pessoas: '3', flowFiber: true }),
    );
    expect(r).toMatchObject({ kit: 'KIT-CASA', multiplicador: 1, frequencia: 'SEMANAL', ue: 26, valorEstimado: 70.1 });
    expect(itens(r)).toEqual({ WP500: 3, FF500: 3, AMN5000: 2 });
  });

  it('CT05 / caso C: Escritório, 5–7 dias, 11–20 pessoas → 249,6 UE → perfil Empresa, sem kit', async () => {
    const r = await service.recomendar(CLIENTE, respostas({ objetivo: 'ESCRITORIO', pessoas: '11-20' }));
    expect(r).toMatchObject({ kit: null, multiplicador: 8, frequencia: 'SEMANAL', ue: 249.6, valorEstimado: null, perfilEmpresa: true });
    expect(itens(r)).toEqual({ WP500: 96, AMC200: 384 });
    expect(r.contatoComercial).toEqual({ email: 'contato@cristalins.com.br', telefone: '(14) 3523-1001' });
  });

  it('frequência: s < 6 → mensal (g = s × 4)', async () => {
    // d = 2, p = 1 → s = 2 → mensal → g = 8 → m = 1
    const r = await service.recomendar(CLIENTE, respostas({ diasSemana: '1-2' }));
    expect(r).toMatchObject({ frequencia: 'MENSAL', multiplicador: 1 });
  });

  it('multiplicador = teto(g ÷ 12): 5–7 dias, 3 pessoas → s = 18 → semanal → m = 2', async () => {
    const r = await service.recomendar(CLIENTE, respostas({ pessoas: '3' }));
    expect(r).toMatchObject({ frequencia: 'SEMANAL', multiplicador: 2, itens: [{ produto: 'WP500', quantidade: 24 }] });
    // 24 UE → −8%: 24 × 9,108 = 218,59
    expect(r.valorEstimado).toBe(218.59);
  });

  it('Flow Fiber em kit que não é Equilíbrio troca metade das WP500, arredondando para baixo', async () => {
    const r = await service.recomendar(CLIENTE, respostas({ flowFiber: true }));
    expect(itens(r)).toEqual({ WP500: 6, FF500: 6 });
  });

  it('Equilíbrio sem Flow Fiber troca as FF500 por WP500', async () => {
    const r = await service.recomendar(CLIENTE, respostas({ objetivo: 'EQUILIBRIO', flowFiber: false }));
    expect(r.kit).toBe('KIT-EQUILIBRIO');
    expect(itens(r)).toEqual({ WP500: 12 });
  });

  it('Equilíbrio com Flow Fiber mantém a caixa mista do kit', async () => {
    const r = await service.recomendar(CLIENTE, respostas({ objetivo: 'EQUILIBRIO', flowFiber: true }));
    expect(itens(r)).toEqual({ WP500: 6, FF500: 6 });
  });

  it('com gás: +1 fardo de 12 AMC510 por entrega', async () => {
    const r = await service.recomendar(CLIENTE, respostas({ comGas: true }));
    expect(itens(r)).toEqual({ WP500: 12, AMC510: 12 });
  });

  it('com gás e AMC510 indisponível → fardo de AMS500', async () => {
    prisma.produtos.find((p) => p.codigo === 'AMC510')!.estoque = 0;
    const r = await service.recomendar(CLIENTE, respostas({ comGas: true }));
    expect(itens(r)).toEqual({ WP500: 12, AMS500: 12 });
  });

  it('limite de 120 UE / 60 kg decide entre kit e perfil Empresa', async () => {
    // Casa, 5–7 dias, 5–10 pessoas: s = 48 → m = 4 → 24 WP500 + 8 AMN5000 = 104 UE e 54,32 kg → kit
    const limite = await service.recomendar(CLIENTE, respostas({ objetivo: 'CASA', pessoas: '5-10' }));
    expect(limite).toMatchObject({ kit: 'KIT-CASA', ue: 104, perfilEmpresa: false });
    // Casa, 5–7 dias, 11–20 pessoas: s = 90 → m = 8 → 48 WP500 + 16 AMN5000 = 208 UE → Empresa
    const grande = await service.recomendar(CLIENTE, respostas({ objetivo: 'CASA', pessoas: '11-20' }));
    expect(grande).toMatchObject({ kit: null, ue: 208, perfilEmpresa: true, valorEstimado: null });
  });

  it('preço estimado usa a demanda vigente na data do cálculo (verão +5%)', async () => {
    criar(new Date('2027-01-10T15:00:00.000Z'));
    const r = await service.recomendar(CLIENTE, respostas());
    // 12 × 9,90 × 1,05 = 124,74
    expect(r.valorEstimado).toBe(124.74);
  });

  it('grava a recomendação com respostas, kit, itens, UE e valor', async () => {
    const r = await service.recomendar(CLIENTE, respostas());
    const gravada = prisma.recomendacoes[0];
    expect(gravada).toMatchObject({
      id: r.id,
      clienteId: CLIENTE,
      kitId: 'kit-KIT-TREINO',
      multiplicador: 1,
      frequencia: 'QUINZENAL',
      perfilEmpresa: false,
      respostas: respostas(),
      itens: [{ produto: 'WP500', quantidade: 12 }],
    });
    expect(gravada.valorEstimado?.toString()).toBe('118.8');
    expect(gravada.ue.toString()).toBe('12');
  });

  it('lista só as recomendações do próprio cliente', async () => {
    await service.recomendar(CLIENTE, respostas());
    await service.recomendar('outro', respostas({ pessoas: '2' }));
    const lista = await service.listar(CLIENTE);
    expect(lista).toHaveLength(1);
    expect(lista[0].kit).toBe('KIT-TREINO');
  });

  it('busca por id: dono vê; outro cliente → SEM_PERMISSAO; inexistente → NAO_ENCONTRADO', async () => {
    const r = await service.recomendar(CLIENTE, respostas());
    await expect(service.buscar(CLIENTE, r.id)).resolves.toMatchObject({ id: r.id, valorEstimado: 118.8 });

    const erro = async (p: Promise<unknown>) => {
      try {
        await p;
      } catch (e) {
        return (e as RegraNegocioException).codigo;
      }
    };
    expect(await erro(service.buscar('outro', r.id))).toBe('SEM_PERMISSAO');
    expect(await erro(service.buscar(CLIENTE, '00000000-0000-0000-0000-000000000000'))).toBe('NAO_ENCONTRADO');
  });
});
