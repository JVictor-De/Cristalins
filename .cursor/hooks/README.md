# Hooks de segurança do agente

Enforcement técnico das rules [permissoes-agente](../rules/permissoes-agente.mdc) e [coolify-mcp](../rules/coolify-mcp.mdc). Config: [`../hooks.json`](../hooks.json).

| Evento | Script | Efeito |
|--------|--------|--------|
| `beforeShellExecution` | `gate_shell.py` | **ask** `git push` normal; **deny** force (`--force`/`-f`/`+refspec`) / reset --hard / clean -f / config e apagar pastas grandes. Rede/curl/wget **não** passam pelo hook (política soft nas rules). |
| `beforeReadFile` / `beforeTabFileRead` | `gate_secrets.py` | **deny** `.env`, chaves, `.ssh`, credentials/secrets |
| `beforeMCPExecution` | `gate_coolify.py` | **ask** em `deploy` / `control` / `cancel_deployment` do Coolify |
| `afterFileEdit` | `remind_flutter_tests.py` | **fail-open**: se path sob `flutter_app/`, injeta `followup_message` lembrando `flutter test` |

Gates de segurança usam `failClosed: true`. O lembrete Flutter usa `failClosed: false` (nunca bloqueia edição). JSON ilegível no stdin falha aberto — no Windows o Cursor manda BOM UTF-8 e paths com acentos; os scripts leem via `stdin.buffer` + `utf-8-sig`.

## Pré-requisito

`python` ou `py -3` no PATH. No Windows o `hooks.json` chama `run_hook.cmd`, que localiza o interpretador pelo caminho absoluto do script (o cwd do Cursor às vezes não é a raiz do repo) e emite `{"permission":"allow"}` se o Python não arrancar — senão o `failClosed` trava o agente.

## Testes

```powershell
python -m pytest tests/test_cursor_hooks.py -q
# ou
python .cursor/hooks/_smoke_test.py
```

## Ativar no Cursor

1. Salve os arquivos (Cursor recarrega `hooks.json` automaticamente).
2. Se não aparecerem: **Settings → Hooks**, ou reinicie o Cursor.
3. Canal de output **Hooks** ajuda a depurar.

Não edite hooks em `~/.cursor/skills-cursor/` — essa pasta é do Cursor.
