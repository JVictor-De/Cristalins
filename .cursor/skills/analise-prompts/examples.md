# Exemplos — analise-prompts

## Exemplo A — Prompt colado no chat

**Entrada:** usuário cola um prompt longo e pede “analisa e melhora”.

**Ação:** pipeline completo nos bastidores; responder com o **prompt corrigido**
em bloco copiável; sem relatório. Não implementar a feature.

## Exemplo B — Alinhar às regras de negócio

**Entrada:** “Esse prompt de Coolify está ok?”

**Ação:** ler `coolify-mcp` + `permissoes-agente`; se o prompt manda alterar env
sem “sim”, corrigir o texto; devolver o prompt já ajustado.

## Exemplo C — Nome de função errado

**Entrada:** prompt cita `criarCamera()` mas no repo a função é `create_camera`.

**Ação:** Grep no código; substituir pelo nome real no texto do prompt; entregar
o prompt corrigido (sem seção “achei o nome errado”).

## Exemplo D — Fila / ORQUESTRADOR

**Entrada:** “Revisa os prompts da pasta `doc/prompts/features/foo/`.”

**Ação:** corrigir arquivos da fila no escopo; no chat, devolver o(s) prompt(s)
corrigido(s) relevantes. Não re-gerar a fila (`prompt-super-x` fica de fora).

## Exemplo E — SAC vs bot

**Entrada:** prompt que mistura “atender dúvida de login” com comando `gol`.

**Ação:** separar responsabilidades no texto do prompt; devolver versão corrigida.

## Exemplo F — Path / símbolo morto

**Sinal:** prompt aponta para script ou variável removida.

**Ação:** Grep/Glob; atualizar ou remover a referência no prompt; entregar texto
final. Só uma frase de aviso se não houver substituto claro.

## Exemplo G — Pedido misturado (prompt + código)

**Entrada:** “Melhora o prompt e já implementa.”

**Ação:** devolver o prompt corrigido; só implementar se o usuário insistir em
código **depois**.

## Exemplo H — Ambiguidade de domínio

**Sinal:** regra de negócio não documentada.

**Ação:** não inventar; entregar a melhor versão factual do prompt + no máximo
uma pergunta curta sobre a ambiguidade.
