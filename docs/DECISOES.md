# Decisões

## 2026-11-14 — Fundação (`cr-0-repo`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Rubrica pede Activities e Intents nativos | Seguir Flutter: rotas nomeadas = passagem explícita; `url_launcher` / `share_plus` = Intents implícitas. Não reescrever em Kotlin. | Stack fechada no contexto; risco a confirmar com o professor |
| Como serializar dinheiro no JSON | Número com 2 casas (ex.: `118.80`, `219.09`) no contrato Swagger; cálculo interno com `decimal.js` / `Decimal(10,2)` | Exemplos do Anexo são o contrato |
| `applicationId` Android | `br.com.cristalins.assinatura`, `br.com.cristalins.assinatura.dev`, `br.com.cristalins.assinatura.hml` | Monólito não fixa; fila fecha assim |
| Número do WhatsApp de suporte | `--dart-define=SUPORTE_WHATSAPP=` vazio até configuração; não inventar número | Contato comercial da marca não é o WhatsApp do app |
| Download de `docs/flutter-rules.md` | URL `rules_10k.md` retornou 404; arquivo placeholder com o link | Não inventar regras oficiais; baixar de novo quando a URL existir |

## 2026-11-14 — Schema Prisma (`cr-0-prisma`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Versão do Prisma | 7.10.1 fixa (`latest` no npm é `8.0.0-rc.33`) | Não usar RC; Prisma 7 pede `prisma.config.ts` e driver adapter |
| TypeScript | 5.9 fixo (npm trouxe 7.0) | Compatibilidade com o tooling do NestJS em `cr-0-api` |
| Status de `Pagamento` | `PENDENTE`, `PAGO`, `VENCIDO`, `CANCELADO`, `ESTORNADO` | Anexo não lista; mínimo para Pix e régua; `cr-3-gateway` mapeia os status do Asaas |
| Status de `Ocorrencia` | `ABERTA`, `RESOLVIDA` | Anexo só cita `status`; ajustar em `cr-6-operacao` |
| `Zona.dias_entrega` | Lista do enum `DiaSemana` (`SEG`…`SAB`) | Tipado em vez de texto livre |
| `FatorPreco` | Uma linha por chave e vigência (`@@unique([chave, ativoDe])`), valor em fração | Verão sazonal: seed só 01/12/2026–31/03/2027; próximos verões por admin/seed |
| `Recomendacao.kit_id` | Opcional | Caso C (perfil Empresa) não tem kit |
| Migração sem banco | Gerada com `prisma migrate diff --from-empty --script`; não aplicada | Docker não estava rodando e iniciar o Docker Desktop foi negado à sessão |

## 2026-11-14 — API vazia (`cr-0-api`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Cliente Prisma gerado importa `./x.ts` | `rewriteRelativeImportExtensions` no `tsconfig.json` e `moduleNameMapper` `.js → sem extensão` no Jest | Fase não pode alterar o schema (opção `importFileExtension` do generator); Node não resolve `.ts` no `dist` |
| Build inclui `prisma/generated` | `rootDir: "."`; saída `dist/src/main.js`, `start:prod = node dist/src/main` | Cliente gerado fica fora de `src/`; Dockerfile (`cr-4-deploy`) deve rodar `prisma generate` antes do `nest build` |
| Códigos de erro genéricos | 400 `DADOS_INVALIDOS` (validação, com `campo`) / `REQUISICAO_INVALIDA`, 401 `NAO_AUTENTICADO`, 403 `SEM_PERMISSAO`, 404 `NAO_ENCONTRADO`, 409 `CONFLITO`, 422 `REGRA_VIOLADA`, 429 `MUITAS_TENTATIVAS`, 503 `SERVICO_INDISPONIVEL`, 500 `ERRO_INTERNO` | Só quando a exceção não é `RegraNegocioException`; os códigos do Anexo (`SEM_PERMISSAO`, `MUITAS_TENTATIVAS`) batem |
| `/health` sem banco | 503 no formato de erro | Compose e Uptime Kuma enxergam a queda do banco |
| Conexão do Prisma | Sob demanda (sem `$connect` no boot) | API sobe mesmo com o banco fora; o health mostra o estado |
| Versões | NestJS 11, Jest 30, ESLint 9, `@types/node` 22 | Node 22 da stack |
