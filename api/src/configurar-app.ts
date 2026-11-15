import { INestApplication, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ValidationError } from 'class-validator';
import { FiltroExcecao } from './common/filtro-excecao.filter';
import { RegraNegocioException } from './common/regra-negocio.exception';

export const PREFIXO_API = 'api/v1';

// Uma tag por módulo do Anexo (common não expõe rotas).
export const TAGS_SWAGGER: [string, string][] = [
  ['health', 'Saúde da API e do banco'],
  ['auth', 'Login e renovação de token'],
  ['clientes', 'Cadastro e perfil do cliente'],
  ['produtos', 'Catálogo de produtos'],
  ['kits', 'Kits da assinatura'],
  ['recomendacoes', 'Quiz de recomendação'],
  ['enderecos', 'Endereços e CEP'],
  ['precos', 'Simulação de preço'],
  ['assinaturas', 'Assinaturas do cliente'],
  ['ciclos', 'Ciclos de entrega'],
  ['ocorrencias', 'Ocorrências de entrega'],
  ['asaas', 'Integração de pagamento'],
  ['webhooks', 'Webhooks de pagamento'],
  ['jobs', 'Rotinas agendadas'],
  ['admin', 'Administração'],
  ['cupons', 'Cupons de desconto'],
  ['lista-espera', 'Lista de espera fora da área'],
];

function primeiroErro(erros: ValidationError[]): { campo: string; mensagem: string } {
  const erro = erros[0];
  if (erro?.children?.length) {
    const filho = primeiroErro(erro.children);
    return { campo: `${erro.property}.${filho.campo}`, mensagem: filho.mensagem };
  }
  const mensagem = erro?.constraints ? Object.values(erro.constraints)[0] : 'Dados inválidos.';
  return { campo: erro?.property ?? '', mensagem };
}

/** Configuração comum a main.ts e aos testes e2e. */
export function configurarApp(app: INestApplication): void {
  app.setGlobalPrefix(PREFIXO_API);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (erros) => {
        const { campo, mensagem } = primeiroErro(erros);
        return new RegraNegocioException('DADOS_INVALIDOS', mensagem, 400, campo);
      },
    }),
  );
  app.useGlobalFilters(new FiltroExcecao());

  const builder = new DocumentBuilder()
    .setTitle('API Assinatura Cristalins')
    .setDescription('Assinatura recorrente de Water Protein no município do Rio de Janeiro.')
    .setVersion('0.0.1')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' });
  for (const [nome, descricao] of TAGS_SWAGGER) builder.addTag(nome, descricao);

  const documento = SwaggerModule.createDocument(app, builder.build());
  SwaggerModule.setup('docs', app, documento);
}
