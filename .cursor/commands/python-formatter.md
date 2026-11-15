# Python Formatter

Formate o código Python do contexto atual (arquivos @-mencionados, seleção, ou caminhos passados após o comando) **sem alterar comportamento**.

## Ferramentas (nesta ordem)

1. Preferir `black` (padrão do projeto; alinhado a `flake8 --max-line-length=100`).
2. Se `isort` estiver disponível, rodar depois do Black nos mesmos arquivos.
3. Se Black não estiver instalado, tentar `ruff format`; se nada existir, instalar `black` no venv do projeto e seguir.

## Como executar

- Escopo: só os arquivos `.py` indicados pelo usuário / contexto. Se nenhum arquivo for passado, perguntar ou usar os arquivos Python abertos/alterados na conversa — **não** formatar o repo inteiro sem pedido explícito.
- Comandos típicos (ajuste o path):

```bash
python -m black --line-length 100 <arquivos_ou_dirs>
python -m isort --profile black --line-length 100 <arquivos_ou_dirs>
```

- Não formatar: `.venv/`, `venv/`, `node_modules/`, migrations geradas só se o usuário pedir, nem arquivos fora do workspace.

## Regras

- Apenas formatação (espaços, quebras, imports, aspas/estilo Black). Não refatorar, não renomear, não “melhorar” lógica.
- Não tocar em `.env`, secrets ou arquivos não-Python.
- Se Black e o estilo atual divergirem demais num arquivo enorme, aplicar mesmo assim e resumir o que mudou.
- Se o comando falhar (sintaxe inválida), reportar o erro e **não** “consertar” a lógica — só formatação.

## Resposta ao usuário

Resuma em poucas linhas:

1. Quais arquivos foram formatados
2. Ferramenta usada (`black` / `isort` / `ruff format`)
3. Se algo foi pulado e por quê
