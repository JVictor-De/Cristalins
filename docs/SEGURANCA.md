# Segurança e qualidade — Cristalins (`cr-7-qualidade`)

Evidências de SEG01–SEG10 e RNF08–RNF13. Números de cobertura medidos nesta máquina em 2026-11-15. Pendências honestas marcadas.

## SEG01–SEG10

| Id | Requisito | Status | Evidência |
| --- | --- | --- | --- |
| SEG01 | JWT acesso 15 min / refresh 30 dias | ok | `TokenService` (`EXPIRA_ACESSO_SEGUNDOS`, `EXPIRA_REFRESH_SEGUNDOS`); login/refresh em `auth.e2e-spec` |
| SEG02 | Senhas com bcrypt | ok | `gerarHashSenha` / `conferirSenha`; `clientes.service.spec` checa hash `$2…$10$` |
| SEG03 | Papéis cliente/admin; `/admin` protegido | ok | `@Papeis('ADMIN')` em `AdminController`; e2e ciclo devolve 403 a cliente |
| SEG04 | Cliente só acessa os próprios dados | ok | Services usam `usuario.id` do JWT (`SEM_PERMISSAO` / CT16) |
| SEG05 | Validação/sanitização (DTOs) | ok | `class-validator` + filtro `{ codigo, mensagem, campo? }` |
| SEG06 | Login ≤ 5/min/IP | ok | `ThrottlerGuard` no login; CT19 → 429 `MUITAS_TENTATIVAS` |
| SEG07 | Token no `flutter_secure_storage` | ok | `ArmazenamentoSeguro` em `app/lib/core/network/sessao.dart` |
| SEG08 | Segredos só em ambiente | ok | `.gitignore` ignora `.env`; `.env.example` só nomes (`SENTRY_DSN`, `CORS_ORIGINS`, …); `git ls-files` sem `.env` |
| SEG09 | CORS restrito | ok | `main.ts`: `enableCors` só se `CORS_ORIGINS` tiver lista |
| SEG10 | Mascarar CPF, e-mail, telefone nos logs | ok | `api/src/common/mascarar.ts` + `FiltroExcecao` e canais de notificação; testes em `mascarar.spec.ts` |

## RNF08–RNF13

| Id | Requisito | Status | Evidência |
| --- | --- | --- | --- |
| RNF08 | 95% das chamadas &lt; 500 ms | pendente operacional | Critério documentado; medição em hml/prod (Uptime/APM) fica com o João — sem inventar número |
| RNF09 | Conexão lenta: erro + tentar de novo | ok | `ApiErro.semConexao`; `EstadoErro` com botão «Tentar de novo»; golden `estado_erro.png` |
| RNF10 | `GET /health` | ok | `HealthController` + prefixo `/api/v1/health` |
| RNF11 | Sentry app e API | ok | API: `@sentry/node` se `SENTRY_DSN`; app: `sentry_flutter` se `--dart-define=SENTRY_DSN=` |
| RNF12 | Acessibilidade básica | ok | `A11Y.md` + `checklist_telas_test` / `a11y_semantica_test` (TalkBack físico: pendência) |
| RNF13 | pt-BR, R$, datas | ok | `Intl.defaultLocale = pt_BR`; `Dinheiro` / `Datas`; `MaterialApp` locale pt-BR |

## LGPD — `DELETE /clientes/me` (RF05)

Anonimiza `nome`, `email`, `celular`, `pushToken` e campos de endereço; define `excluidoEm`; cancela assinaturas não canceladas. **Mantém** `cpfCnpj` e `dataNascimento` e o histórico de pagamento (retenção fiscal 5 anos). Logs de sistema: política de 90 dias (operacional).

- API: `ClientesService.excluir` + `DELETE /clientes/me`
- App: «Excluir minha conta» na Tela 8 (action sheet) → limpa tokens locais

## Cobertura (números reais)

### API (`npm test -- --coverage`, 2026-11-15)

| Métrica | Valor |
| --- | --- |
| Suites / testes | 19 / **210** passed |
| Statements | **82,85%** (2648/3196) |
| Lines | **84,01%** (2350/2797) |
| Branches | 63,09% |
| Functions | 61,87% |

Alvo Anexo «80% nos services»: linhas/statements do `src` acima de 80%. Branches/funções ainda abaixo — gap honesto.

### App (`flutter test --coverage`)

| Escopo | Linhas | % |
| --- | --- | --- |
| `features/*/domain` | 128/190 | **67,4%** |
| `features/*/data` | 17/305 | **5,6%** |
| domain + data | 145/495 | **29,3%** |

**Meta Anexo 70% em domain+data: não atingida.** Motivo: widget tests usam fakes/mocks e quase não exercitam os repositórios Dio reais.

Gaps principais em `data` (cobertura ≈ 0–5%): `assinatura_repository`, `catalogo_repository`, `recomendacao_repository`, `ocorrencia_repository`, `auth_repository`. Em `domain`, `ocorrencia.dart` e partes de `pagamento.dart` / `quiz.dart`.

`flutter analyze`: **sem issues** (path via `subst X:`).

## Golden (`app/test/goldens/`)

| Prompt | Widget real | Arquivo |
| --- | --- | --- |
| AppButton | `BotaoPrincipal` | `botao_principal.png` |
| QuantityStepper | `SeletorQuantidade` | `seletor_quantidade.png` |
| StatusBadge | `Selo` | `selo.png` |
| EmptyState | `EstadoVazio` | `estado_vazio.png` |
| (RNF09) | `EstadoErro` | `estado_erro.png` |
| ProductCard | — | **não existe** neste app (catálogo usa `LinhaLista`) |

## Pendências (João)

- Definir `SENTRY_DSN` e `CORS_ORIGINS` no Coolify/hml
- Medir RNF08 (p95) sob carga
- TalkBack em aparelho; ofuscação + upload de símbolos Sentry no release (`cr-8`)
- Subir cobertura dos repositórios Flutter (testes unitários Dio) se a rubrica exigir os 70%
