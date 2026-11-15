# Checklist detalhado — revisão pós-implementação

Usar como referência durante os passos 2–6 da skill. Marcar mentalmente; não
obrigar o usuário a ver a lista inteira.

## Completude

- [ ] Toda função/classe/rota citada no pedido ou no diff existe e está ligada
- [ ] Nenhum `TODO`/`FIXME`/`pass`/`...` deixado no caminho crítico
- [ ] Callers atualizados após rename/move
- [ ] Exports públicos (`__all__`, `index.ts`, routers) coerentes
- [ ] Migração / schema / seed alinhados se o modelo mudou
- [ ] Feature flag / permissão / papel admin cobertos se a tela/API for gated

## Lógica

- [ ] Regras de negócio batem com o domínio Peladeiros (clube, partida, usuário, etc.)
- [ ] Idempotência onde o projeto já exige (seeds, webhooks, retries)
- [ ] Concorrência / double-submit tratado se houver create sensível
- [ ] Filtros por `clube_id` / escopo de admin respeitados
- [ ] Datas/timezones consistentes com o resto do módulo

## Nomenclatura

- [ ] Mesmo idioma e estilo do arquivo vizinho
- [ ] Nomes de endpoint/campos alinhados FE↔BE
- [ ] Booleans com prefixo claro (`is_`, `has_`, `pode_`) se já for padrão local
- [ ] Evitar shadowing e abreviações opacas (`d`, `x`, `obj`)

## Desatualizado / pontas soltas

- [ ] APIs/componentes substituídos no repo não reintroduzidos
- [ ] Props/deprecated warnings do frontend no escopo
- [ ] Comentários e strings de UI que mentem sobre o comportamento
- [ ] Arquivos criados vazios ou pages sem uso removidos ou concluídos

## Erros

- [ ] Validação de input (Pydantic / form) com mensagens úteis
- [ ] 401/403/404/409/422 usados como no módulo
- [ ] Extrações de `except Exception` justificadas + log
- [ ] UI não quebra em resposta vazia ou erro de rede

## Testes

- [ ] Teste do comportamento novo (não só “compila”)
- [ ] Superfície certa: pytest (`app/`/`sac`), Jest (`admin_frontend`), `flutter test` (`flutter_app`)
- [ ] Formulário admin sem spec Jest → criar no estilo de `src/__tests__` (sem Playwright)
- [ ] Pelo menos um caso de falha/autorização se houver authz
- [ ] Fixtures/factories reutilizam o padrão do diretório
- [ ] Nomes de teste descrevem o comportamento esperado
- [ ] Suite do escopo passa localmente

## Atualidade (2026+)

- [ ] Seguir padrões **já presentes** no repo na data atual (Next/React/FastAPI/pytest)
- [ ] Não copiar snippets de docs marcados como legado
- [ ] Preferir helpers/libs já usadas no módulo ao introduzir dependência nova
