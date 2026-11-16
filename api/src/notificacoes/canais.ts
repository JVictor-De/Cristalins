import { Logger } from '@nestjs/common';
import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';
import * as tls from 'node:tls';
import { CanalEmail, CanalPush, Mensagem, mascararEmail, mascararToken } from './notificacoes.tipos';

/** Sem credencial configurada (dev e testes): só registra no log, mascarado (SEG10). */
export class LogPush implements CanalPush {
  private readonly log = new Logger('Push');
  async enviar(token: string, m: Mensagem): Promise<void> {
    this.log.log(`[sem FCM] push para ${mascararToken(token)}: ${m.titulo}`);
  }
}

export class LogEmail implements CanalEmail {
  private readonly log = new Logger('Email');
  async enviar(para: string, assunto: string): Promise<void> {
    this.log.log(`[sem SMTP] e-mail para ${mascararEmail(para)}: ${assunto}`);
  }
}

// ---------------------------------------------------------------- SMTP

export interface ConfigSmtp {
  host: string;
  porta: number;
  usuario: string;
  senha: string;
}

/** `SMTP_HOST` aceita `host` ou `host:porta` (padrão 465, TLS implícito). */
export function configSmtpDoAmbiente(env = process.env): ConfigSmtp | null {
  const { SMTP_HOST: hostPorta, SMTP_USER: usuario, SMTP_PASS: senha } = env;
  if (!hostPorta || !usuario || !senha) return null;
  const [host, porta] = hostPorta.split(':');
  return { host, porta: porta ? Number(porta) : 465, usuario, senha };
}

const b64 = (s: string) => Buffer.from(s, 'utf8').toString('base64');

/** Corpo RFC 5322 em UTF-8 (assunto e texto em base64). */
export function montarEmail(de: string, para: string, assunto: string, texto: string, data = new Date()): string {
  const corpo = b64(texto).replace(/.{1,76}/g, '$&\r\n');
  return [
    `From: Cristalins <${de}>`,
    `To: <${para}>`,
    `Subject: =?UTF-8?B?${b64(assunto)}?=`,
    `Date: ${data.toUTCString()}`,
    'MIME-Version: 1.0',
    'Content-Type: text/plain; charset=UTF-8',
    'Content-Transfer-Encoding: base64',
    '',
    corpo,
  ].join('\r\n');
}

/**
 * Cliente SMTP mínimo (TLS implícito + AUTH LOGIN), sem dependência nova. O remetente é o
 * `SMTP_USER`. A senha nunca vai para o log.
 */
export class SmtpEmail implements CanalEmail {
  constructor(private readonly cfg: ConfigSmtp) {}

  async enviar(para: string, assunto: string, texto: string): Promise<void> {
    const socket = tls.connect({ host: this.cfg.host, port: this.cfg.porta, servername: this.cfg.host });
    socket.setTimeout(15_000, () => socket.destroy(new Error('SMTP: tempo esgotado')));
    let buffer = '';
    const fila: Array<(linha: string) => void> = [];
    const pendentes: string[] = [];
    socket.on('data', (d: Buffer) => {
      buffer += d.toString('utf8');
      let i: number;
      while ((i = buffer.indexOf('\r\n')) >= 0) {
        const linha = buffer.slice(0, i);
        buffer = buffer.slice(i + 2);
        // Resposta multilinha: "250-..." continua, "250 ..." termina.
        if (/^\d{3} /.test(linha) || /^\d{3}$/.test(linha)) {
          const r = fila.shift();
          if (r) r(linha);
          else pendentes.push(linha);
        }
      }
    });
    const erro = new Promise<never>((_, rej) => socket.once('error', rej));
    const resposta = () =>
      Promise.race([
        new Promise<string>((res) => (pendentes.length ? res(pendentes.shift()!) : fila.push(res))),
        erro,
      ]);
    const esperar = async (codigos: number[], etapa: string) => {
      const linha = await resposta();
      const codigo = Number(linha.slice(0, 3));
      if (!codigos.includes(codigo)) throw new Error(`SMTP ${etapa}: resposta ${codigo}`);
    };
    const comando = async (linha: string, codigos: number[], etapa: string) => {
      socket.write(`${linha}\r\n`);
      await esperar(codigos, etapa);
    };
    try {
      await esperar([220], 'conexão');
      await comando('EHLO cristalins-api', [250], 'EHLO');
      await comando('AUTH LOGIN', [334], 'AUTH');
      await comando(b64(this.cfg.usuario), [334], 'AUTH usuário');
      await comando(b64(this.cfg.senha), [235], 'AUTH senha');
      await comando(`MAIL FROM:<${this.cfg.usuario}>`, [250], 'MAIL FROM');
      await comando(`RCPT TO:<${para}>`, [250, 251], 'RCPT TO');
      await comando('DATA', [354], 'DATA');
      await comando(`${montarEmail(this.cfg.usuario, para, assunto, texto)}\r\n.`, [250], 'envio');
      socket.write('QUIT\r\n');
    } finally {
      socket.end();
    }
  }
}

// ---------------------------------------------------------------- FCM

interface ContaServico {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
}

/** `FCM_CREDENTIALS`: JSON da conta de serviço do Firebase ou caminho para o arquivo. */
export function contaFcmDoAmbiente(env = process.env): ContaServico | null {
  const bruto = env.FCM_CREDENTIALS?.trim();
  if (!bruto) return null;
  const json = bruto.startsWith('{') ? bruto : readFileSync(bruto, 'utf8');
  const conta = JSON.parse(json) as ContaServico;
  if (!conta.client_email || !conta.private_key || !conta.project_id) {
    throw new Error('FCM_CREDENTIALS sem client_email, private_key ou project_id.');
  }
  return conta;
}

const b64url = (b: Buffer | string) => Buffer.from(b).toString('base64url');

/** JWT RS256 da conta de serviço para trocar por um token OAuth (escopo do FCM). */
export function assertionFcm(conta: ContaServico, agora = Date.now()): string {
  const iat = Math.floor(agora / 1000);
  const cabecalho = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const corpo = b64url(
    JSON.stringify({
      iss: conta.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: conta.token_uri ?? 'https://oauth2.googleapis.com/token',
      iat,
      exp: iat + 3600,
    }),
  );
  const assinatura = createSign('RSA-SHA256').update(`${cabecalho}.${corpo}`).sign(conta.private_key);
  return `${cabecalho}.${corpo}.${b64url(assinatura)}`;
}

/** Push pelo FCM HTTP v1, sem SDK. O token OAuth fica em memória até perto de vencer. */
export class FcmPush implements CanalPush {
  private acesso: { token: string; expira: number } | null = null;

  constructor(
    private readonly conta: ContaServico,
    private readonly http: typeof fetch = fetch,
  ) {}

  private async tokenAcesso(): Promise<string> {
    if (this.acesso && this.acesso.expira > Date.now() + 60_000) return this.acesso.token;
    const r = await this.http(this.conta.token_uri ?? 'https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: assertionFcm(this.conta),
      }),
    });
    if (!r.ok) throw new Error(`FCM OAuth: ${r.status}`);
    const j = (await r.json()) as { access_token: string; expires_in: number };
    this.acesso = { token: j.access_token, expira: Date.now() + j.expires_in * 1000 };
    return j.access_token;
  }

  async enviar(token: string, m: Mensagem, dados: Record<string, string>): Promise<void> {
    const r = await this.http(`https://fcm.googleapis.com/v1/projects/${this.conta.project_id}/messages:send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${await this.tokenAcesso()}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: { token, notification: { title: m.titulo, body: m.corpo }, data: dados } }),
    });
    if (!r.ok) throw new Error(`FCM envio: ${r.status}`);
  }
}

export function criarCanalPush(): CanalPush {
  const conta = contaFcmDoAmbiente();
  return conta ? new FcmPush(conta) : new LogPush();
}

export function criarCanalEmail(): CanalEmail {
  const cfg = configSmtpDoAmbiente();
  return cfg ? new SmtpEmail(cfg) : new LogEmail();
}
