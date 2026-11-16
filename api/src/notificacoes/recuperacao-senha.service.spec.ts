import { ClockService } from '../common/clock.service';
import { PrismaFake } from '../../test/support/prisma-fake';
import { NotificacoesService } from './notificacoes.service';
import { CanalEmail, CanalPush, Mensagem } from './notificacoes.tipos';
import { RecuperacaoSenhaService } from './recuperacao-senha.service';

class Relogio extends ClockService {
  constructor(public instante = new Date('2026-11-15T15:00:00.000Z')) {
    super();
  }
  override agora() {
    return new Date(this.instante);
  }
}

class Gravador implements CanalPush, CanalEmail {
  emails: { para: string; assunto: string; texto: string }[] = [];
  async enviar(a: string, b: Mensagem | string, c?: Record<string, string> | string): Promise<void> {
    if (typeof b === 'string') this.emails.push({ para: a, assunto: b, texto: String(c) });
  }
}

describe('RecuperacaoSenhaService (RF52)', () => {
  const senhaAntiga = '$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUV';
  let prisma: PrismaFake;
  let relogio: Relogio;
  let canal: Gravador;
  let svc: RecuperacaoSenhaService;

  beforeEach(() => {
    process.env.JWT_SECRET = 'segredo-de-teste-cr6';
    prisma = new PrismaFake();
    prisma.clientes.push({
      id: 'cli-1',
      nome: 'Ana',
      cpfCnpj: '52998224725',
      email: 'ana@cristalins.local',
      celular: null,
      senhaHash: senhaAntiga,
      papel: 'CLIENTE',
      asaasCustomerId: null,
      indicadoPorId: null,
      pushToken: null,
      excluidoEm: null,
    });
    relogio = new Relogio();
    canal = new Gravador();
    const notificacoes = new NotificacoesService(prisma as never, canal, canal);
    svc = new RecuperacaoSenhaService(prisma as never, relogio, notificacoes);
  });

  it('esqueci: sempre a mesma mensagem; só envia e-mail se o cadastro existir', async () => {
    const r = await svc.esqueci('ana@cristalins.local');
    expect(r.mensagem).toContain('Se o e-mail tiver cadastro');
    expect(canal.emails).toHaveLength(1);
    expect(canal.emails[0].texto).toMatch(/\d{6}/);

    canal.emails = [];
    const r2 = await svc.esqueci('naoexiste@cristalins.local');
    expect(r2.mensagem).toBe(r.mensagem);
    expect(canal.emails).toHaveLength(0);
  });

  it('redefinir: código válido troca a senha; errado → CODIGO_INVALIDO; 5 erros → 429', async () => {
    await svc.esqueci('ana@cristalins.local');
    const codigo = svc.codigoPara({ id: 'cli-1', senhaHash: senhaAntiga }, relogio.agora().getTime());
    const ok = await svc.redefinir({ email: 'ana@cristalins.local', codigo, novaSenha: 'nova-senha-123' });
    expect(ok.mensagem).toContain('Senha alterada');
    expect(prisma.clientes[0].senhaHash).not.toBe(senhaAntiga);

    // Mesmo código não vale de novo (hash mudou)
    await expect(svc.redefinir({ email: 'ana@cristalins.local', codigo, novaSenha: 'outra-senha-123' })).rejects.toMatchObject({
      codigo: 'CODIGO_INVALIDO',
    });

    // Conta limpa para o limite de 5 (o erro acima já registrou 1 falha neste e-mail)
    const outro = new RecuperacaoSenhaService(prisma as never, relogio, new NotificacoesService(prisma as never, canal, canal));
    for (let i = 0; i < 5; i++) {
      await expect(outro.redefinir({ email: 'ana@cristalins.local', codigo: '000000', novaSenha: 'x'.repeat(8) })).rejects.toMatchObject({
        codigo: 'CODIGO_INVALIDO',
      });
    }
    await expect(outro.redefinir({ email: 'ana@cristalins.local', codigo: '000000', novaSenha: 'x'.repeat(8) })).rejects.toMatchObject({
      codigo: 'MUITAS_TENTATIVAS',
    });
  });
});
