import { assinarPut, configS3DoAmbiente, MemoriaFotos } from './armazenamento-fotos';

describe('armazenamento-fotos', () => {
  it('sem S3_* devolve null; com as quatro variáveis monta a config', () => {
    expect(configS3DoAmbiente({})).toBeNull();
    expect(
      configS3DoAmbiente({
        S3_ENDPOINT: 'http://localhost:9000/',
        S3_BUCKET: 'cristalins',
        S3_KEY: 'minio',
        S3_SECRET: 'minio123',
      }),
    ).toEqual({
      endpoint: 'http://localhost:9000',
      bucket: 'cristalins',
      chave: 'minio',
      segredo: 'minio123',
      regiao: 'us-east-1',
    });
  });

  it('PUT assinado: Authorization no cabeçalho, nunca na URL (sem credencial pública)', () => {
    const { url, headers } = assinarPut(
      {
        endpoint: 'http://localhost:9000',
        bucket: 'cristalins',
        chave: 'minio',
        segredo: 'minio123',
        regiao: 'us-east-1',
      },
      'ocorrencias/ciclo/foto.jpg',
      Buffer.from('jpeg'),
      'image/jpeg',
      new Date('2026-11-15T12:00:00.000Z'),
    );
    expect(url).toBe('http://localhost:9000/cristalins/ocorrencias/ciclo/foto.jpg');
    expect(url).not.toContain('Signature=');
    expect(url).not.toContain('minio123');
    expect(headers.Authorization).toMatch(/^AWS4-HMAC-SHA256 Credential=minio\//);
    expect(headers.Authorization).toContain('Signature=');
    expect(headers['Content-Type']).toBe('image/jpeg');
  });

  it('MemoriaFotos guarda o buffer e devolve s3://memoria/…', async () => {
    const m = new MemoriaFotos();
    const ref = await m.salvar('ocorrencias/a.jpg', Buffer.from([1, 2]), 'image/jpeg');
    expect(ref).toBe('s3://memoria/ocorrencias/a.jpg');
    expect(m.objetos.get('ocorrencias/a.jpg')?.conteudo.equals(Buffer.from([1, 2]))).toBe(true);
  });
});
