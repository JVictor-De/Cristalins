import { ClockService } from '../common/clock.service';
import { PrismaService } from '../common/prisma.service';
import { RegraNegocioException } from '../common/regra-negocio.exception';
import { ClientesService } from './clientes.service';
import { CriarClienteDto } from './dto/criar-cliente.dto';

// 00:30 de 15/11/2026 em UTC ainda é 14/11/2026 em São Paulo: a idade usa a data local.
const clockFixo = { agora: () => new Date('2026-11-15T00:30:00.000Z') } as ClockService;
clockFixo.hoje = ClockService.prototype.hoje.bind(clockFixo);
clockFixo.dataNoFuso = ClockService.prototype.dataNoFuso.bind(clockFixo);

function dto(extra: Partial<CriarClienteDto> = {}): CriarClienteDto {
  return {
    nome: 'Ana Souza',
    cpfCnpj: '52998224725',
    email: 'ana@exemplo.com',
    dataNascimento: '1995-05-10',
    senha: 'senha-forte-123',
    aceiteTermos: true,
    ...extra,
  };
}

async function codigoDoErro(promessa: Promise<unknown>): Promise<string> {
  try {
    await promessa;
  } catch (e) {
    if (e instanceof RegraNegocioException) return e.codigo;
    throw e;
  }
  throw new Error('esperava erro');
}

describe('ClientesService', () => {
  let prisma: {
    cliente: { findUnique: jest.Mock; create: jest.Mock; update: jest.Mock };
    $transaction: jest.Mock;
    assinatura: { updateMany: jest.Mock };
    endereco: { updateMany: jest.Mock };
  };
  let service: ClientesService;

  beforeEach(() => {
    prisma = {
      cliente: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation(({ data }) => Promise.resolve({ id: 'c1', ...data })),
        update: jest.fn(),
      },
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) => fn(prisma)),
      assinatura: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
      endereco: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
    };
    service = new ClientesService(prisma as unknown as PrismaService, clockFixo);
  });

  it('CT24: 17 anos na data de São Paulo → MENOR_DE_IDADE', async () => {
    // Em UTC já seria 15/11 (18 anos); em São Paulo ainda é 14/11 (17 anos).
    expect(await codigoDoErro(service.criar(dto({ dataNascimento: '2008-11-15' })))).toBe('MENOR_DE_IDADE');
    expect(prisma.cliente.create).not.toHaveBeenCalled();
  });

  it('grava aceite dos termos com o horário do ClockService e a senha com bcrypt', async () => {
    await service.criar(dto({ dataNascimento: '2008-11-14' }));
    const { data } = prisma.cliente.create.mock.calls[0][0];
    expect(data.aceiteTermosEm).toEqual(new Date('2026-11-15T00:30:00.000Z'));
    expect(data.senhaHash).toMatch(/^\$2[aby]\$10\$/);
    expect(data).not.toHaveProperty('senha');
    expect(data.dataNascimento).toEqual(new Date('2008-11-14T00:00:00.000Z'));
  });

  it('CPF inválido e data inexistente são recusados antes do banco', async () => {
    expect(await codigoDoErro(service.criar(dto({ cpfCnpj: '52998224726' })))).toBe('CPF_INVALIDO');
    expect(await codigoDoErro(service.criar(dto({ dataNascimento: '1995-02-30' })))).toBe('DADOS_INVALIDOS');
    expect(await codigoDoErro(service.criar(dto({ dataNascimento: '2030-01-01' })))).toBe('DADOS_INVALIDOS');
    expect(prisma.cliente.findUnique).not.toHaveBeenCalled();
  });

  it('CPF já usado → CPF_JA_CADASTRADO', async () => {
    prisma.cliente.findUnique.mockResolvedValueOnce({ id: 'outro' });
    expect(await codigoDoErro(service.criar(dto()))).toBe('CPF_JA_CADASTRADO');
  });

  it('corrida no insert (P2002) devolve o código de unicidade', async () => {
    prisma.cliente.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'outro' });
    prisma.cliente.create.mockRejectedValueOnce(Object.assign(new Error('unique'), { code: 'P2002' }));
    expect(await codigoDoErro(service.criar(dto()))).toBe('EMAIL_JA_CADASTRADO');
  });

  it('conta excluída não é encontrada', async () => {
    prisma.cliente.findUnique.mockResolvedValueOnce({ id: 'c1', excluidoEm: new Date() });
    expect(await codigoDoErro(service.buscarAtivo('c1'))).toBe('NAO_AUTENTICADO');
  });

  it('DELETE /clientes/me: anonimiza nome/contato/endereço e marca excluidoEm (RF05)', async () => {
    const ativo = {
      id: 'c1',
      nome: 'Ana',
      email: 'ana@exemplo.com',
      celular: '21999999999',
      cpfCnpj: '52998224725',
      excluidoEm: null,
    };
    prisma.cliente.findUnique.mockResolvedValueOnce(ativo);
    prisma.cliente.update.mockResolvedValueOnce({ ...ativo, excluidoEm: new Date() });
    await service.excluir('c1');
    expect(prisma.assinatura.updateMany).toHaveBeenCalled();
    expect(prisma.endereco.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ logradouro: '—', cep: '00000000', lat: null, lng: null }),
      }),
    );
    const { data } = prisma.cliente.update.mock.calls[0][0];
    expect(data.nome).toBe('Conta excluída');
    expect(data.email).toBe('excluido-c1@anon.local');
    expect(data.celular).toBeNull();
    expect(data.pushToken).toBeNull();
    expect(data.excluidoEm).toEqual(new Date('2026-11-15T00:30:00.000Z'));
    expect(data.senhaHash).toMatch(/^\$2[aby]\$/);
    expect(data).not.toHaveProperty('cpfCnpj'); // CPF permanece no registro (retenção fiscal)
  });
});
