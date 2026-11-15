# Referência — Cursor + Claude Code (filas)

## Runner

| Peça | Path |
|------|------|
| Genérico | `doc/prompts/run_fila_prompts_cursor.py` |
| Lib | `doc/prompts/agent_cli_lib.py` |
| Estado | `doc/prompts/<area>/<slug>/.<slug>_prompts_state.json` |
| Logs | `doc/prompts/logs/*_claude_*` / `*_cursor_*` |

### Flags úteis

| Flag | Efeito |
|------|--------|
| `--dir AREA/SLUG` | Pasta sob `doc/prompts/` |
| `--list` | Fases + `@runtime` + GATE + skills |
| `--auto --no-login --model auto` | Corrida; **`--model` = só Cursor Agent** (manter `auto`) |
| `--from ID` | Retoma do id. Id já em `concluidos` não reabre (segue depois). `--refazer` reabre |
| `--only ID1,ID2` | Só essas fases (permite a metade Claude do par) |
| `--marcar-concluida IDS` | Grava id(s) em `concluidos` sem rodar. Recusa artefato ausente ou vazio |
| `--aprovar-gate` | Libera `gate_pendente` |
| `--all-claude` | Força `runtime=claude_code` nesta corrida |
| `--claude-session-id UUID` | Resume sessão Claude |
| `--claude-permission-mode MODE` | Sobrescreve fila (`acceptEdits`, `bypassPermissions`, …) |
| `--claude-model ID` | Modelo **Claude Code** (`claude -p --model …`). Fila nova: **`opus`**. Se omitir, a constante do runner hoje é `claude-opus-5-5` |
| `--skip-design-check` | Não valida plugin design (só testes/dry) |
| `--dry-run` | Não spawna; gate não bloqueia |
| `--reset` | Apaga estado da fila |

### Modelos

| Quem | Mecanismo | Padrão |
|------|-----------|--------|
| Cursor Agent | `args.model` → `agent … --model` | `auto` |
| Claude Code | `args.claude_model` → `claude -p --model` | Fila grava **`opus`**. Se omitir, `CLAUDE_MODEL_DEFAULT` hoje é `claude-opus-5-5` |

Prioridade Claude: CLI `--claude-model` > `fila.json` `claude_model` > `CLAUDE_MODEL_DEFAULT`.  
Dry-run imprime `claude_model: …` e o argv do `claude`. Não pinar `claude-opus-5-5` salvo pedido explícito.

### Estado JSON

```json
{
  "concluidos": ["contexto", "ios-0-inventario"],
  "chat_id": "",
  "claude_session_id": "uuid…",
  "gate_pendente": "ios-1-diagnostico",
  "resets_at": null
}
```

- Claude: se `claude_session_id` já existe → `--resume`; senão → `--session-id` novo.
- Gate pendente sem `GATE_APROVADO.md` / `--aprovar-gate` → `SystemExit` com comando de retomada.
- Par aberto: o runner grava `.onda_paralela.json` e sai com código 3. O PS1 trata a onda.

## Plugin design

```powershell
claude plugin list
```

Deve listar `design@knowledge-work-plugins` enabled.

Cache típico (Windows):

`%USERPROFILE%\.claude\plugins\cache\knowledge-work-plugins\design\<versão>\skills\<nome>\SKILL.md`

Helpers na lib: `achar_dir_plugin_design`, `skills_design_faltando`, `garantir_design_plugin`, `bloco_skills_injetadas`.

Check do plugin no runner só roda se alguma fase da corrida tiver `skills` não vazio.

## Schema `fila.json` (trecho Claude)

```json
{
  "handoff_arquivo": "HANDOFF.md",
  "claude_permission_mode": "bypassPermissions",
  "claude_model": "opus",
  "artefatos_contexto": ["INVENTARIO.md", "docs/redesign/diagnostico.md"],
  "fases": [
    {
      "id": "ios-1-diagnostico",
      "arquivo": "prompts/passo_1_diagnostico.md",
      "modo": "somente_leitura",
      "runtime": "claude_code",
      "skills": ["design-critique", "accessibility-review"],
      "gate_humano": true
    }
  ]
}
```

## PS1 Claude-only (template)

Sem `paralelo_com`. Com par, use o template de `prompt-super-x` (`reference.md`).

```powershell
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { exit 2 }
& claude plugin list
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
python doc/prompts/run_fila_prompts_cursor.py --dir AREA/SLUG --auto --no-login --model auto @args
exit $LASTEXITCODE
```

## Permissões

Arquivos: `.cursor/permissions.json` (repo) + `~/.cursor/permissions.json` (usuário; Cursor às vezes só lê o user).

Entradas mínimas para esta skill:

- `claude`, `claude:*`
- `agent`, `agent:*` (se ainda houver fases Cursor)
- `.\scripts\*_run_auto.ps1`, `scripts\*_run_auto.ps1`
- `Set-Content`, `Set-Content:*`

Hooks (sempre): push ask; force/reset/clean deny; `.env` deny; Coolify write ask.

## Testes

```powershell
.\.venv\Scripts\python.exe -m pytest tests/test_agent_cli_lib.py tests/test_run_fila_prompts_cursor.py -q
```

## Troubleshooting

| Sintoma | Ação |
|---------|------|
| Plugin não encontrado | `claude plugin install design@knowledge-work-plugins` |
| Skill slash “não existe” | Usar `/design:nome`; confirmar pasta no cache |
| Gate bloqueia tudo | `GATE_APROVADO.md` ou `--aprovar-gate` + `--from` |
| Sessão Claude estranha | `--claude-session-id` do estado; evitar `--continue` manual |
| Allowlist não pega | Espelhar em `~/.cursor/permissions.json` + reiniciar Cursor |
| Prompt truncado no Windows | Runner já usa arquivo `*_prompt.md` — não passar texto enorme no argv |
| Claude sem Opus / modelo errado | Conferir `claude_model` na fila + dry-run; usar `--claude-model opus` |
| Cursor saiu de `auto` | Não usar Opus em `--model`; PS1/retomada devem ter `--model auto` |
| `--auto` parou com código 3 | Par aberto: o PS1 sobe as duas CLIs e chama `--marcar-concluida` |
| `--marcar-concluida` saiu 2 | Artefato ausente, vazio ou só com espaço |
