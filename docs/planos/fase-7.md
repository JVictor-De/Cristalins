# Plano — Fase 7 (qualidade, SEG e LGPD, pós-AP2)

Fase `cr-7-qualidade`. Fonte: Anexo (SEG01–SEG10, RNF08–RNF13, RF05), `CONTEXTO.md`, `A11Y.md`. Saída: `docs/SEGURANCA.md`.

| Item | Regra | Onde |
| --- | --- | --- |
| Exclusão LGPD (RF05) | `DELETE /clientes/me`: anonimiza nome, e-mail, celular, push e endereços; marca `excluidoEm`; mantém CPF/nascimento e histórico fiscal/pagamento (retenção 5 anos). Cancela assinaturas ativas | `ClientesService.excluir` |
| Sentry (RNF11) | API e app: init só se `SENTRY_DSN` / `--dart-define=SENTRY_DSN=` | `main.ts`, `bootstrap.dart` |
| SEG07 | Token já em `flutter_secure_storage` | `sessao.dart` (evidência) |
| SEG08 | Segredos só em `.env` / `.env.example` com nomes | evidência em SEGURANCA |
| SEG09 | CORS só com `CORS_ORIGINS` (lista) | `main.ts` (já existe) |
| SEG10 | Mascarar CPF, e-mail e telefone em logs | `common/mascarar.ts` + uso nos canais/filtro |
| RNF09 | Erro claro + “Tentar de novo” | `EstadoErro` + telas que já usam |
| RNF12 | A11Y.md + testes guideline | evidência |
| RNF13 | pt-BR / R$ / datas | `Intl` + `AppConfig` |
| Golden | BotaoPrincipal, SeletorQuantidade, Selo, EstadoVazio (ProductCard não existe) | `app/test/goldens/` |
| Cobertura | API services ≥ 80% alvo Anexo; app domain+data ≥ 70% ou lista honesta do gap | números reais no SEGURANCA |

## Fora desta fase

- Play Store / ofuscação com upload de símbolos (roteiro em `cr-8`)
- Medição real de p95 &lt; 500 ms em produção (RNF08: critério + pendência operacional)
- Inventar preço ou manual da marca
