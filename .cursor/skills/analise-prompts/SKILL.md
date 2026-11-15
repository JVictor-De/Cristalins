---
name: analise-prompts
description: >-
  Corrige e melhora prompts colados no chat: lógica, clareza, nomenclatura,
  nomes reais de variáveis/funções no repo, completude e alinhamento com
  regras de negócio. Entrega o prompt corrigido (não relatório). Use when
  the user asks to revisar/analisar/melhorar um prompt, auditar prompts,
  alinhar prompt às regras de negócio, ou cola um prompt para correção
  (setembro 2026+).
---

# Análise de prompts (corrigir + devolver no chat)

Skill de **correção e melhoria** de texto de prompt. O agente **corrige** e
**devolve o prompt pronto para usar** no chat (ou edita o arquivo se o usuário
apontou um path). **Não** entrega relatório estruturado. **Não** implementa
código de produto nem cria testes unitários.

**Irmãs:** código → `revisao-pos-implementacao`; docs gerais → `revisao-pos-docs`;
prompt → fila Cursor CLI → `prompt-super-x`.

## Prompt canônico (verbatim)

Ao aplicar esta skill, trate o pedido como equivalente a:

> Por favor, revise minuciosamente o(s) prompt(s) indicado(s) (ou o prompt colado abaixo), garantindo que a lógica e o conteúdo estejam corretos e que a nomenclatura esteja adequada. Corrija erros, ambiguidades, instruções contraditórias, trechos desatualizados e pendências (pontas soltas). Melhore clareza, escopo, critérios de done e ordem das instruções quando necessário. Confirme no repositório que os nomes de variáveis, funções, classes, endpoints e símbolos mencionados no prompt estão corretos e atualizados; se estiverem errados, corrija-os no texto do prompt.
>
> Etapa obrigatória — alinhamento com o projeto:
> 1. Analise o repositório/contexto disponível (docs de domínio, rules em `.cursor/rules`, skills relevantes, manuais/VISÃO do feature, e código só quando necessário para confirmar comportamento real e nomes de símbolos).
> 2. Extraia as regras de negócio e restrições que se aplicam ao tema do prompt (ex.: SAC ≠ bot de produto, multi-tenant/clube, permissões, fluxos do jogador/admin, o que o agente pode/não pode fazer).
> 3. Compare o prompt sob análise com essas regras: corrija desalinhamentos, omissões e instruções que contradizem o projeto.
> 4. Corrija o prompt para ficar alinhado às regras de negócio atuais; se algo for ambíguo no projeto, faça uma pergunta curta no chat em vez de inventar regra — e ainda assim entregue a melhor versão possível do prompt.
>
> Nota: o material deve estar alinhado ao estado atual do projeto e ao calendário de referência (setembro de 2026+). Não invente paths, APIs, tools, variáveis, funções ou regras que não existam no contexto fornecido ou no repositório.
>
> obs: nenhuma seção, passo, critério de done, restrição ou referência importante se perdeu, ficou pela metade ou ficou inconsistente? Os nomes de variáveis e funções citados estão corretos no repo? O prompt resultante está coerente com as regras de negócio do projeto?
>
> Entrega: devolva no chat o prompt completo já corrigido e melhorado (pronto para copiar/usar). Não entregue relatório, checklist de achados nem seção “correções feitas”. No máximo uma frase curta antes do prompt se houver bloqueio (ex.: símbolo inexistente no repo).
>
> Escopo: o(s) prompt(s) sob análise, artefatos diretamente citados por eles, e a leitura mínima do projeto necessária para validar regras de negócio e nomes de símbolos. Não expandir para refatorar o app inteiro nem para implementar código de produto. Não criar testes unitários nem tratamentos de erro de runtime — o alvo é o texto do prompt.

## Quando aplicar

- Usuário cola/pede análise, revisão ou melhoria de um prompt
- Auditar prompts de fila (`ORQUESTRADOR`, passos, `fila.json` descriptions)
- Checar se o prompt bate com regras de negócio / rules / domínio
- Prompt novo ou legado suspeito de estar desatualizado (set/2026+)
- Inconsistência entre prompts irmãos do mesmo feature

**Não usar** quando o pedido for só implementar código, só revisão pós-código, ou
só converter prompt em fila Cursor CLI (aí: `prompt-super-x`). Se o prompt estiver
ruim **e** o usuário quiser fila, corrigir com esta skill (ou pedir) **antes** de
`prompt-super-x`.

## Escopo

1. **Prioridade:** prompt(s) colados no chat; senão arquivos nomeados / diff.
2. **Expandir para regras de negócio e símbolos:** rules, skills, VISÃO/manual do
   feature, e Grep/Read no código para nomes reais.
3. **Não** reescrever o monorepo; **não** refatorar app; **não** inventar regra/símbolo.
4. **Data de referência:** set/2026+ — paths, tools e nomes devem bater com o repo.

## Pipeline (obrigatório)

```
Task Progress:
- [ ] 1. Inventário do(s) prompt(s)
- [ ] 2. Completude (seções / passos / done / refs)
- [ ] 3. Qualidade do prompt (lógica, clareza, nomenclatura)
- [ ] 4. Alinhamento com regras de negócio do projeto
- [ ] 5. Validar paths / tools / variáveis / funções / símbolos
- [ ] 6. Entregar o prompt corrigido no chat (sem relatório)
```

### 1) Inventário

- Identificar o texto-alvo: bloco colado, arquivo(s), ou pasta de fila.
- Listar partes: objetivo, escopo, passos, restrições, critérios de done, inputs/outputs.
- Se for fila: incluir passos, `ORQUESTRADOR`, `TRACKER`, descrições em `fila.json`.

### 2) Completude — “nada se perdeu / ficou pela metade?”

| Checagem | Falha típica |
|----------|----------------|
| Passo anunciado sem instrução | Stub / `TODO` |
| Sem critério de done | Agente não sabe quando parar |
| Sem escopo / anti-escopo | Expande para o app inteiro |
| Ref a path/tool inexistente | Prompt quebrado |
| Prompt irmão desatualizado | Um lado corrigido, outro não |

**Ação:** completar o que falta; restaurar o que sumiu; remover só se obsoleto confirmado.

### 3) Qualidade do prompt

- Ordem das instruções coerente; pré-requisitos antes do uso.
- Uma intenção clara por seção; sem contradições internas.
- Nomenclatura alinhada ao projeto (pastas, ids de fase, SAC ≠ bot).
- Ambiguidade: quem faz o quê, em qual ambiente (local / VPS / Coolify).
- Preferir verbos acionáveis e critérios verificáveis.

Detalhes: [checklist.md](checklist.md). Fontes de regras: [reference.md](reference.md).

### 4) Alinhamento com regras de negócio (obrigatório)

Leitura mínima orientada ao **tema do prompt** (não varrer o repo inteiro):

1. `.cursor/rules/` relevantes (`permissoes-agente`, `sac-vs-bot-produto`,
   `coolify-mcp`, visão, etc.).
2. Skills / docs do domínio citados ou óbvios pelo tema.
3. VISÃO / IMPORTANTE / manual do feature, se existirem.
4. Código **só** para confirmar comportamento real e nomes de símbolos.

Compare e corrija **dentro do texto do prompt**:

| Tipo | Ação |
|------|------|
| Contradiz rule/domínio | Reescrever a instrução |
| Omite restrição crítica | Incluir restrição explícita |
| Inventa permissão/deploy/env | Remover ou condicionar a “pedir sim” |
| Ambíguo no projeto | Pergunta curta + melhor versão possível; não inventar |

### 5) Validar no repo (paths + variáveis + funções)

Para cada path, comando, tool, **variável**, **função**, classe, endpoint ou
símbolo importante citado no prompt:

1. Existe no repo? (Grep/Read — não confiar na memória)
2. Nome, casing e módulo batem com o código atual?
3. Se errado, renomeado ou removido → **corrigir no texto do prompt** (usar o nome real)
4. Se não existir e for crítico → trocar por referência correta ou remover a instrução falsa; avisar em **uma frase** antes do prompt

Não rode suíte de testes de produto. Opcional: `--list` / dry-run de fila **só**
se o alvo for fila CLI e isso validar completude.

### 6) Entrega (obrigatória) — prompt corrigido, sem relatório

**Formato da resposta ao usuário:**

1. Opcional: no máximo 1–2 frases se houver bloqueio ou pergunta inevitável.
2. O **prompt completo** já corrigido e melhorado, em um único bloco copiável.
3. Se o usuário apontou um arquivo: editar o arquivo **e** mostrar o texto final no chat.

**Proibido na resposta padrão:**

- Seções tipo “Análise”, “Correções”, “Completude”, “Validação”, “Pendências”
- Checklist de achados / diff narrado / “o que eu mudei”
- Relatório estruturado da skill

Trabalho interno (pipeline, Grep, rules) permanece nos bastidores.

## Regras do projeto

- Não ler/editar `.env` / secrets.
- Não commit/push a menos que o usuário peça.
- Não confundir SAC (`sac/`) com bot de produto (`app/bot/`).
- Não inventar regras de negócio nem nomes de símbolos.
- **Não** implementar feature nem escrever testes unitários “por completude”.
- **Não** substituir a entrega do prompt por um relatório.

## Anti-padrões

- Entregar relatório em vez do prompt corrigido
- Só listar problemas sem reescrever o prompt
- Declarar símbolos “ok” sem Grep/Read no repo
- Inventar nome de variável/função que “parece certo”
- Varrer o app inteiro “por garantia”
- Aplicar checklist de código (pytest, try/except) ao texto do prompt
- Transformar em fila CLI sem o usuário pedir (`prompt-super-x`)

## Relação com as irmãs

| Alvo | Skill |
|------|--------|
| Corrigir / melhorar **prompts** no chat + regras de negócio | `analise-prompts` (esta) |
| Docs / manuais / trackers em geral | `revisao-pos-docs` |
| Código de produto | `revisao-pos-implementacao` |
| Converter prompt em fila Cursor Agent CLI | `prompt-super-x` |

## Exemplos

Ver [examples.md](examples.md).
