---
name: cursor-claude-fila
description: >-
  Orquestra filas CLI híbridas Cursor Agent + Claude Code no Peladeiros:
  runtime por fase, skills /design:*, HANDOFF, gate humano, sessão UUID,
  permissões, PS1, Cursor --model auto e Claude sempre no Opus mais novo
  (alias opus). Use when the user mentions Cursor+Claude juntos, fila híbrida,
  redesign_ios, claude -p com plugin design, gate_humano, HANDOFF.md,
  claude_model, orquestrar fila com Claude Code, ou “skills só no Claude”.
---

# Cursor + Claude Code — filas CLI

Padrão Peladeiros para prompts multi-fase em que **skills existem só no Claude Code**
(ex.: plugin `design@knowledge-work-plugins`) e o **Cursor Agent** orquestra /
desbloqueia a fila (ou roda fases sem essas skills).

**Irmã:** scaffold a partir de monólito (Cursor por fase; Claude só onde o prompt cita skill) → [`prompt-super-x`](../prompt-super-x/SKILL.md).  
**Canônico vivo:** `doc/prompts/features/redesign_ios/`.

## Quando aplicar

- “Cursor e Claude juntos” / fila híbrida / skills só no Claude
- Scaffold ou manutenção de fila com `runtime: claude_code`
- Orquestrar `*_run_auto.ps1` + monitorar/retomar gate
- Conferir nomes `/design:…` ou permissões `claude` na allowlist

## Decisão de runtime

| Situação | Runtime |
|----------|---------|
| Fase precisa de skill do plugin design (ou outra só no Claude) | `claude_code` |
| Fase só inventário/shell/consolidação sem skill Claude | `cursor_agent` **ou** `claude_code` |
| Querer 1 login / menos handoff (recomendado se a maioria usa design) | **todas** `claude_code` |

Exemplo `redesign_ios`: **100% `claude_code`**.

## Modelos (não misturar flags)

| Runtime | Flag / campo | Valor padrão |
|---------|--------------|--------------|
| Cursor Agent (`cursor_agent`) | `--model` | **`auto`** (nunca trocar por Opus) |
| Claude Code (`claude_code`) | `claude_model` na fila / `--claude-model` | **`opus`** (alias = **sempre o Opus mais novo**) |

- PS1 e comandos de retomada mantêm `--model auto` mesmo em filas Claude-only (o runner só usa isso nas fases Cursor).
- Não passar Opus em `--model` do Cursor.
- Default Claude = alias **`opus`** (não pinar `claude-opus-5-5` etc., salvo pedido explícito).
- Override só com `--claude-model …` ou `fila.json` → `"claude_model"`.
- Se a fila omitir o campo, a constante `CLAUDE_MODEL_DEFAULT` do runner hoje ainda é `claude-opus-5-5`. Fila nova grava `"opus"`.

## Skills Claude Code (forma correta)

Plugin: `design@knowledge-work-plugins`.

| Slash (invocar) | Pasta em `skills` do plugin (`fila.json` → campo `skills`) |
|-----------------|-----------------------------------------------------------|
| `/design:design-critique` | `design-critique` |
| `/design:design-system` | `design-system` |
| `/design:accessibility-review` | `accessibility-review` |
| `/design:ux-copy` | `ux-copy` |
| `/design:design-handoff` | `design-handoff` |

**Proibido** no prompt: `design:foo` sem `/`, ou `/design-critique` sem namespace.  
O runner **injeta** o `SKILL.md` da pasta + pede o slash (não usar `--bare` no `claude -p`).

## Pipeline (scaffold ou evolução de fila)

```
Task Progress:
- [ ] 1. Definir quais fases precisam de skills Claude
- [ ] 2. Preencher fila.json (runtime, skills, gate_humano, handoff)
- [ ] 3. Passos + CONTEXTO + HANDOFF.md + PROMPT_ORQUESTRAR_CLI.md + PS1
- [ ] 4. Garantir runner/permissões (claude na allowlist)
- [ ] 5. --list / dry-run e mini-relatório
```

### 1) Marcar skills por fase

No `fila.json`, em cada fase Claude que use design:

```json
"runtime": "claude_code",
"skills": ["design-critique", "accessibility-review"],
"gate_humano": true
```

`gate_humano`: pausa após a fase até `GATE_APROVADO.md` ou `--aprovar-gate`.

### 2) Campos de fila (Claude)

| Campo | Função |
|-------|--------|
| `runtime` | `claude_code` \| `cursor_agent` |
| `skills` | pastas do plugin → injeção + slash |
| `gate_humano` | pausa humana |
| `handoff_arquivo` | default `HANDOFF.md` |
| `artefatos_contexto` | paths reinjetados a cada fase |
| `claude_permission_mode` | ex. `bypassPermissions` (fila redesign) |
| `claude_model` | **`opus`** na fila nova. Se o campo faltar, o runner hoje usa `claude-opus-5-5` |

### 3) Mitigações obrigatórias (já no runner)

O genérico `doc/prompts/run_fila_prompts_cursor.py` + `agent_cli_lib.py`:

1. **Memória:** injeta `HANDOFF.md` + artefatos a cada fase (atualizar HANDOFF no fim do passo).
2. **Sessão:** UUID em estado → `--session-id` / `--resume` (nunca `--continue` genérico).
3. **Skills:** texto do `SKILL.md` injetado se `skills` estiver na fase.
4. **Gate:** para após fase com `gate_humano`; retoma com `--aprovar-gate`.
5. **Permissões Claude:** `bypassPermissions` + `--allow-dangerously-skip-permissions` quando a fila pedir; senão `--allowedTools` comuns.
6. **Prompt longo:** arquivo em `doc/prompts/logs/*_prompt.md` (Windows).
7. **Modelo Claude:** `montar_comando_claude` sempre passa `--model`. Fila nova grava `opus`. A constante `CLAUDE_MODEL_DEFAULT`, se a fila omitir o campo, ainda é `claude-opus-5-5`.
8. **Paralelo:** `--auto` para no par aberto (código 3 + `.onda_paralela.json`). `--marcar-concluida` recusa artefato ausente ou vazio. `--from` em id já concluído não reabre a fase.

### 4) Artefatos mínimos

```
doc/prompts/<area>/<slug>/
  fila.json
  CONTEXTO.md
  CONSOLIDACAO.md
  HANDOFF.md
  TRACKER.md
  TECNICAS.md
  ORQUESTRADOR.md
  PROMPT_ORQUESTRAR_CLI.md
  prompts/passo_*.md
  relatorios/.gitkeep
  .gitignore          # estado + GATE_APROVADO.md + .onda_paralela.json
scripts/<slug>_run_auto.ps1
```

PS1 Claude-only, sem `paralelo_com`: checa `claude` + `claude plugin list`, depois  
`python … --dir AREA/SLUG --auto --no-login --model auto`  
(Cursor `auto`; Claude Opus vem de `claude_model` / default do runner).

Fila com `paralelo_com`: esse `--auto` sozinho não serve. O runner sai com
código 3, grava `.onda_paralela.json` e não roda o par em sequência. O PS1
sobe `--only` da fase Claude e `agent` da fase Cursor, espera as duas, e chama
`--marcar-concluida ID_CURSOR` (recusa artefato ausente ou vazio) antes de
voltar ao `--auto`. O script está em `prompt-super-x` (`reference.md`).

### 5) Validar

```powershell
python doc/prompts/run_fila_prompts_cursor.py --dir features/SLUG --list
python doc/prompts/run_fila_prompts_cursor.py --dir features/SLUG --dry-run --only contexto --no-login --model auto --skip-design-check
```

No dry-run de fila nova, conferir log `claude_model: opus` e argv com `--model opus` no `claude -p`. Filas legadas que ainda pinam `claude-opus-5-5` mostram esse ID.

## Orquestrar (chat Agent)

1. Ler `PROMPT_ORQUESTRAR_CLI.md` da fila.
2. Pré-voo: `claude plugin list` + `--list`.
3. Rodar `.\scripts\<slug>_run_auto.ps1`. Se a fila tem `paralelo_com`, o script
   trata o código 3: runner na fase Claude, `agent` na fase Cursor, depois
   `--marcar-concluida` (recusa artefato ausente ou vazio).
4. No gate: resumir artefatos, pedir aprovação, criar `GATE_APROVADO.md`,
   `--from PROXIMA --aprovar-gate`.
5. Falha ou reload numa fase com skill Claude: grave `RETOMA` no passo e no
   `HANDOFF.md` (o que já foi feito, o que falta, comando literal). Avise no
   chat para o usuário retomar **aquele** prompt depois. Não marque a fase
   como concluída.
6. Enquanto essa fase espera e o runner está livre, fases sem skill Claude e
   sem depender do artefato dela rodam no Cursor com `--only` e `--model auto`.
   Par planejado (`paralelo_com`): quem executa é o PS1 (código 3). Não suba
   dois runners da mesma fila. `--marcar-concluida` só grava o id Cursor se o
   artefato existir e não estiver vazio. `--from` num id já em `concluidos`
   não reabre a fase. `--refazer` reabre; o `--auto` continua parando no par.
   O `--auto` linear não pula a fase parada. `gate_humano` não é `RETOMA`:
   aprove e siga com `--aprovar-gate`.
7. Logs `doc/prompts/logs/`, estado `.<slug>_prompts_state.json`, retomada com
   ids/UUID **literais**.
8. Não reimplementar o produto no chat no lugar da fila (só destravar runner).

## Permissões Cursor (menos prompts)

Em `.cursor/permissions.json` **e** `~/.cursor/permissions.json`:

- `claude`, `claude:*`, `agent`, `agent:*`
- `.\scripts\*_run_auto.ps1`, `scripts\*_run_auto.ps1`
- `Set-Content` (gate)

Run Mode: **Allowlist** (ou Allowlist with Sandbox). Reiniciar Cursor se a allowlist não pegar.  
Hooks do repo continuam pedindo push/secrets/Coolify write — correto.

## Anti-padrões

- `--bare` no Claude (mata plugins/skills)
- Slash sem namespace (`/design-critique`)
- Confiar só em `--continue` entre fases com Cursor no meio
- Pedir “posso continuar?” no chat em vez de `gate_humano` + artefato
- Inventar skill que não está no plugin
- Trocar `--model auto` do Cursor por Opus / outro ID fixo
- Rodar Claude sem `claude_model` / default `opus` (ou pinar ID antigo em vez do alias, salvo pedido explícito)
- Commit/push / ler `.env` / Coolify write sem pedido

## Relação com irmãs

| Alvo | Skill |
|------|--------|
| Cursor + Claude (esta) | `cursor-claude-fila` |
| Prompt → fila (Cursor default; Claude na fase com skill) | `prompt-super-x` |
| Corrigir texto de prompt | `analise-prompts` |

## Detalhes

- Schema e flags: [reference.md](reference.md)
- Exemplo redesign_ios + prompt orquestrador: [examples.md](examples.md)
