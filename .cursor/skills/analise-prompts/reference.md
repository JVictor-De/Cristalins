# Reference — fontes de regras de negócio e qualidade

Ler **só o necessário** para o tema do prompt. Não inventariar o monorepo.

## Onde buscar regras (ordem sugerida)

| Prioridade | Fonte | Quando |
|------------|--------|--------|
| 1 | `.cursor/rules/*.mdc` do tema | Sempre que o prompt tocar o domínio da rule |
| 2 | Skill do domínio (`.cursor/skills/…`) | Prompt fala daquele workflow |
| 3 | `doc/` VISÃO / IMPORTANTE / manual do feature | Feature nomeada ou pasta citada |
| 4 | `sac/docs/PROMPTS.md` + `sac/.cursor/rules/` | Tema SAC / suporte |
| 5 | Código mínimo (`app/`, `admin_frontend/`, …) | Prompt afirma API/fluxo/campo que precisa confirmação |

## Rules do projeto (atalhos)

| Rule | Tema |
|------|------|
| `permissoes-agente` | O que o agente pode/não pode (secrets, push, deploy, commit) |
| `sac-vs-bot-produto` | Não misturar SAC (`sac/`) com bot (`app/bot/`) |
| `coolify-mcp` | Env/deploy/restart só com “sim” explícito |
| `visao-computacional` / `visao-fase-workflow` | Pipeline de visão / fases |

## Sinais de desalinhamento com negócio

- Prompt manda editar `.env` / secrets ou fazer deploy sem gate de confirmação
- Mistura comandos de SAC com menu do jogador (gol, ranking, etc.)
- Ignora multi-tenant/clube/permissões quando o feature é admin ou dados por clube
- Cita path, app Coolify ou script que não existe mais
- Pede “modernizar o app” ou “rodar todos os testes” sem critério
- Assume produção/VPS quando o fluxo documentado é só local

## Qualidade mínima de um bom prompt (heurística)

1. **Objetivo** em 1–2 frases
2. **Escopo** + o que está fora
3. **Passos** ordenados (ou seções claras)
4. **Restrições** do projeto / negócio
5. **Done** verificável
6. **Referências** (paths/docs) reais
7. **Símbolos** (variáveis, funções, classes, endpoints) com nomes reais do repo

Se faltar 4, 5 ou 7, a correção deve incluir — não só “sugerir”.

## Entrega

- Resposta = prompt corrigido no chat (copiável).
- Relatório/checklist ficam só no trabalho interno da skill.

## Quando parar a expansão

- Já leu as rules do tema e o doc canônico do feature
- Paths críticos do prompt foram checados
- Restante seria “curiosidade” ou refatoração de código → **parar**
