# Checklist — análise de prompts

Usar nos passos 2–5 do `SKILL.md`. Alvo = texto de prompt (não código de produto).
Checklist é **interno** — não colar no chat do usuário.

## Completude

- [ ] Objetivo do prompt está explícito
- [ ] Escopo e anti-escopo estão claros (o que **não** fazer)
- [ ] Passos/seções anunciados existem e estão na ordem útil
- [ ] Critério de done / artefato de saída é verificável
- [ ] Inputs necessários (arquivos, IDs, contexto) estão listados
- [ ] Sem `TODO` / `TBD` / `…` crítico no caminho principal
- [ ] Se fila: passos ↔ ORQUESTRADOR ↔ TRACKER ↔ `fila.json` alinhados

## Qualidade do texto

- [ ] Sem contradição interna (duas instruções incompatíveis)
- [ ] Sem ambiguidade de ator/ambiente (local vs VPS vs Coolify)
- [ ] Verbos acionáveis; critérios observáveis
- [ ] Nomenclatura igual à do repo (paths, slugs, ids de fase)
- [ ] SAC ≠ bot de produto quando o tema tocar WhatsApp/atendimento
- [ ] Não pede “analisar o app inteiro” sem necessidade

## Regras de negócio

- [ ] Rules relevantes do tema foram lidas (mínimo necessário)
- [ ] Docs de domínio / VISÃO / skill do feature consultados se existirem
- [ ] Prompt não contradiz permissões do agente (secrets, push, deploy, env Coolify)
- [ ] Restrições críticas do domínio estão explícitas no prompt
- [ ] Omissões perigosas foram preenchidas (ou pergunta curta no chat)
- [ ] Nada inventado onde o projeto está ambíguo

## Validação factual (paths + símbolos)

- [ ] Paths citados existem
- [ ] Comandos/scripts citados existem e a sintaxe faz sentido
- [ ] Tools/MCP citados existem e o uso respeita “pedir sim” quando aplicável
- [ ] Nomes de módulos/pastas batem com o repo (set/2026+)
- [ ] Variáveis mencionadas existem e o nome/casing está correto
- [ ] Funções/métodos mencionados existem e o nome/casing está correto
- [ ] Classes, endpoints, enums e demais símbolos citados batem com o código
- [ ] Sem placeholders PowerShell perigosos (`<ID>` → redirect)

## Entrega

- [ ] Prompt completo corrigido devolvido no chat (bloco copiável)
- [ ] Sem relatório / lista de achados / seção “o que mudou”
- [ ] Arquivo editado só se o usuário apontou path (e texto final ainda no chat)
