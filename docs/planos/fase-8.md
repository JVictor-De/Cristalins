# Plano — Fase 8 (bairros + lançamento, pós-AP2)

Fases `cr-8-bairros` ∥ `cr-8-lancamento` → `cr-8-revisao`. Fonte: Anexo (produção, Play Store, checklist), `CONTEXTO.md`, `docs/DEPLOY.md`, `docs/SEGURANCA.md`.

| Fase | Artefato | Faz | Não faz |
| --- | --- | --- | --- |
| `cr-8-bairros` | `api/prisma/data/bairros-rj.json` + seed | Lista oficial IPP nas 5 zonas; taxas do Anexo | Inventar frete; `migrate reset` |
| `cr-8-lancamento` | `docs/LANCAMENTO.md`, `docs/PLAYSTORE.md` | **Documentar** backup, Uptime, alertas, rollback, checklist, Play (ofuscação, trilhas, gradual) | **Não executa** deploy, Coolify, Play Console nem `git push` |
| `cr-8-revisao` | `REVISAO_POS.md` | Julgar cartão, CT18/21, exclusão, seed de bairros e roteiro que não publica sozinho | Reimplementar AP2 |

## Escopo de `cr-8-lancamento` (esta fase)

1. Checklist do Anexo em `docs/LANCAMENTO.md`, cada item **feito** ou **pendente** (pendências Cristalins: `contato@cristalins.com.br` · `(14) 3523-1001`).
2. Comandos de AAB/APK `prod` com `--obfuscate` / `--split-debug-info` e Play App Signing **sem** chave no repo (`docs/PLAYSTORE.md`).
3. Deixar explícito: o agente **só escreve o roteiro**; o João executa quando houver domínio, Asaas prod e conta Play.

## Fora

- Alterar `api/prisma/`
- Inventar preço real, CNPJ, domínio ou D-U-N-S
- Ligar Coolify / publicar na loja
