# Checklist — revisão pós-docs

Usar nos passos 2–5. Sem itens de teste unitário ou tratamento de erro de runtime.

## Completude

- [ ] Todas as seções/passos anunciados no início ou no índice existem
- [ ] Nenhum `TODO` / `TBD` / `…` crítico deixado no caminho principal
- [ ] Tracker / ORQUESTRADOR / fila alinhados entre si (ids e ordem)
- [ ] Índice pai atualizado se o doc for “a rodar” ou entrada nova
- [ ] Critério de done / artefato de saída explícito onde a fila exige

## Conteúdo e lógica

- [ ] Instruções na ordem correta; pré-requisitos citados antes do uso
- [ ] Sem contradição com o doc irmão do mesmo feature (no escopo)
- [ ] SAC vs bot de produto não misturados
- [ ] Escopos de ambiente claros (local vs VPS vs Coolify) quando relevantes

## Nomenclatura

- [ ] Paths e slugs iguais aos do repo
- [ ] Nomes de fase/id consistentes (`prefixo-n-nome`)
- [ ] Termos de domínio alinhados ao restante do projeto

## Desatualizado / pontas soltas

- [ ] Comandos e scripts existem e batem com a skill/fila atual
- [ ] Sem placeholders `<...>` coláveis no PowerShell
- [ ] Status (“feito”, “pendente”) coerente com o repo
- [ ] Sem segunda pasta canônica duplicada para o mesmo asset
- [ ] Links relativos resolvem a partir do arquivo

## Validação no repo

- [ ] Cada path importante: existe (Read/Glob/Grep)
- [ ] Cada símbolo/comando crítico: confirmado ou corrigido
- [ ] Cross-links do escopo não apontam para arquivo removido
