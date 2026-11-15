# Exemplos — cursor-claude-fila

## Exemplo A — Fila canônica `redesign_ios`

**Pasta:** `doc/prompts/features/redesign_ios/`  
**PS1:** `scripts/redesign_ios_run_auto.ps1`  
**Runtime:** todas `@claude_code`  
**Modelos:** Cursor `--model auto` (PS1); Claude na fila viva ainda pina `"claude_model": "claude-opus-5-5"` (legado). Scaffold novo grava `"opus"`.  
**Gate:** após `ios-1-diagnostico`  
**Skills:** critique/a11y → design-system → ux-copy → critique/a11y → handoff  

```powershell
.\scripts\redesign_ios_run_auto.ps1
# após gate (Cursor continua --model auto; Opus vem da fila/default):
Set-Content doc/prompts/features/redesign_ios/GATE_APROVADO.md "aprovado"
python doc/prompts/run_fila_prompts_cursor.py --dir features/redesign_ios --auto --no-login --model auto --from ios-2-design-system --aprovar-gate
```

## Exemplo B — Prompt para chat Agent (orquestrar)

```markdown
Orquestre a fila redesign iOS até concluir.
Siga `doc/prompts/features/redesign_ios/PROMPT_ORQUESTRAR_CLI.md`.
Pré-voo: `claude plugin list` + `--list`.
Rode `.\scripts\redesign_ios_run_auto.ps1` e monitore.
No gate: peça aprovação; depois GATE_APROVADO + `--from ios-2-design-system --aprovar-gate`.
Se falhar: logs + estado; retome com ids/UUID literais. Sem commit/push/.env/Coolify.
Skills: `/design:design-critique`, `/design:design-system`, `/design:accessibility-review`, `/design:ux-copy`, `/design:design-handoff`.
Modelos: Cursor `--model auto`; Claude `opus` (fila nova) ou o `claude_model` desta fila.
```

## Exemplo C — Fase híbrida (quando fizer sentido)

```json
{
  "id": "xy-0-inventario",
  "runtime": "cursor_agent",
  "modo": "somente_leitura",
  "arquivo": "prompts/passo_0.md"
},
{
  "id": "xy-1-critique",
  "runtime": "claude_code",
  "skills": ["design-critique"],
  "modo": "somente_leitura",
  "arquivo": "prompts/passo_1.md",
  "gate_humano": true
}
```

Memória entre runtimes = `HANDOFF.md` + `artefatos_contexto` (não chat compartilhado).  
Modelos: fases Cursor → `--model auto`; fases Claude → `claude_model` / `--claude-model` (`opus`).

## Exemplo D — Scaffold novo a partir de prompt monólito

1. Aplicar `analise-prompts` se o texto estiver ruim.
2. Aplicar `prompt-super-x` para a estrutura base (Cursor por fase; Claude só onde o monólito cita skill).
3. Aplicar **esta skill** para marcar `runtime`/`skills`/`gate`/`HANDOFF`, `claude_model: opus` e PS1 com `--model auto` (e onda se houver `paralelo_com`).
4. Validar `--list` / dry-run (`claude_model: opus` no log).

## Exemplo E — Irmão admin `redesign_admin_ios`

A fila `redesign_admin_ios` passou a ser **Cursor-only** (`prompt-super-x`).  
Não usar esta skill nela. Canônico híbrido continua `redesign_ios/`.

**Pasta:** `doc/prompts/features/redesign_admin_ios/`  
**PS1:** `scripts/redesign_admin_ios_run_auto.ps1`  
**Runtime:** Cursor Agent (`--model auto`)  
**Escopo:** só `admin_frontend/` (HIG iPadOS/macOS). Não toca `flutter_app/` nem `docs/redesign/`.

```powershell
.\scripts\redesign_admin_ios_run_auto.ps1
```

