import { Logger } from '@nestjs/common';
import { createHash, createHmac } from 'node:crypto';

/** Onde ficam as fotos das ocorrências (RN15). Devolve a referência interna `s3://bucket/chave`. */
export interface ArmazenamentoFotos {
  salvar(chave: string, conteudo: Buffer, tipo: string): Promise<string>;
}

export const ARMAZENAMENTO_FOTOS = Symbol('ARMAZENAMENTO_FOTOS');

export interface ConfigS3 {
  endpoint: string;
  bucket: string;
  chave: string;
  segredo: string;
  regiao: string;
}

/** `S3_ENDPOINT`, `S3_BUCKET`, `S3_KEY`, `S3_SECRET` (MinIO aceita a região padrão us-east-1). */
export function configS3DoAmbiente(env = process.env): ConfigS3 | null {
  const { S3_ENDPOINT: endpoint, S3_BUCKET: bucket, S3_KEY: chave, S3_SECRET: segredo } = env;
  if (!endpoint || !bucket || !chave || !segredo) return null;
  return { endpoint: endpoint.replace(/\/+$/, ''), bucket, chave, segredo, regiao: 'us-east-1' };
}

const sha256 = (d: Buffer | string) => createHash('sha256').update(d).digest('hex');
const hmac = (k: Buffer | string, d: string) => createHmac('sha256', k).update(d).digest();
const codificar = (s: string) =>
  s
    .split('/')
    .map((p) => encodeURIComponent(p).replace(/[!'()*]/g, (c) => `%${c.charCodeAt(0).toString(16).toUpperCase()}`))
    .join('/');

/**
 * Cabeçalhos de um PUT assinado com AWS Signature V4 (path-style, compatível com MinIO).
 * Puro, para teste: a credencial só aparece na assinatura, nunca na URL.
 */
export function assinarPut(cfg: ConfigS3, chaveObjeto: string, conteudo: Buffer, tipo: string, agora = new Date()) {
  const url = new URL(`${cfg.endpoint}/${cfg.bucket}/${codificar(chaveObjeto)}`);
  const amzData = agora.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  const dia = amzData.slice(0, 8);
  const hashCorpo = sha256(conteudo);
  const host = url.host;
  const assinados = 'content-type;host;x-amz-content-sha256;x-amz-date';
  const canonico = [
    'PUT',
    url.pathname,
    '',
    `content-type:${tipo}`,
    `host:${host}`,
    `x-amz-content-sha256:${hashCorpo}`,
    `x-amz-date:${amzData}`,
    '',
    assinados,
    hashCorpo,
  ].join('\n');
  const escopo = `${dia}/${cfg.regiao}/s3/aws4_request`;
  const paraAssinar = ['AWS4-HMAC-SHA256', amzData, escopo, sha256(canonico)].join('\n');
  const kData = hmac(`AWS4${cfg.segredo}`, dia);
  const kAssinatura = hmac(hmac(hmac(kData, cfg.regiao), 's3'), 'aws4_request');
  const assinatura = createHmac('sha256', kAssinatura).update(paraAssinar).digest('hex');
  return {
    url: url.toString(),
    headers: {
      'Content-Type': tipo,
      'x-amz-content-sha256': hashCorpo,
      'x-amz-date': amzData,
      Authorization: `AWS4-HMAC-SHA256 Credential=${cfg.chave}/${escopo}, SignedHeaders=${assinados}, Signature=${assinatura}`,
    },
  };
}

/** MinIO/S3 por PUT assinado, sem SDK novo. Bucket privado: nada de URL pública. */
export class S3Fotos implements ArmazenamentoFotos {
  constructor(
    private readonly cfg: ConfigS3,
    private readonly http: typeof fetch = fetch,
  ) {}

  async salvar(chave: string, conteudo: Buffer, tipo: string): Promise<string> {
    const { url, headers } = assinarPut(this.cfg, chave, conteudo, tipo);
    const r = await this.http(url, { method: 'PUT', headers, body: new Uint8Array(conteudo) });
    if (!r.ok) throw new Error(`S3 PUT ${r.status}`);
    return `s3://${this.cfg.bucket}/${chave}`;
  }
}

/** Sem `S3_*` (dev e testes): guarda em memória e avisa no log. */
export class MemoriaFotos implements ArmazenamentoFotos {
  private readonly log = new Logger('Fotos');
  readonly objetos = new Map<string, { conteudo: Buffer; tipo: string }>();

  async salvar(chave: string, conteudo: Buffer, tipo: string): Promise<string> {
    this.objetos.set(chave, { conteudo, tipo });
    this.log.warn(`[sem S3_*] foto ${chave} guardada só em memória`);
    return `s3://memoria/${chave}`;
  }
}

export function criarArmazenamentoFotos(): ArmazenamentoFotos {
  const cfg = configS3DoAmbiente();
  return cfg ? new S3Fotos(cfg) : new MemoriaFotos();
}
