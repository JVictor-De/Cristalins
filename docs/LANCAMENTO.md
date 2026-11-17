# Lançamento — produção (pós-AP2)

Roteiro para o **João** (e a Cristalins) subir a API em produção e operar o dia a dia.  
**Esta fase só documenta.** Não executa Coolify, Play Console, `git push` nem inventa domínio, CNPJ, preço real ou D-U-N-S.

Homologação (AP2): ver `docs/DEPLOY.md`. Segurança: `docs/SEGURANCA.md`. Play Store: `docs/PLAYSTORE.md`.

Contato comercial já citado no CONTEXTO/Anexo (não inventar outro): `contato@cristalins.com.br` · `(14) 3523-1001`.

---

## 1. Ambiente de produção (Coolify)

Estrutura igual à hml, projeto separado (ex.: `cristalins-prod`):

| Peça | Nota |
| --- | --- |
| API | `api/Dockerfile`; health real: `GET /api/v1/health` |
| PostgreSQL 16 | Só seed de catálogo (produtos, kits, zonas/bairros); **sem** usuários de teste |
| MinIO (ou S3) | Fotos de ocorrência (`S3_*`) |
| HTTPS | Let's Encrypt no domínio de produção (definir com a Cristalins; não inventar aqui) |
| Asaas | `ASAAS_MODE` de produção + `ASAAS_API_URL` / chave / webhook **de produção** |

Variáveis: nomes em `.env.example` (`DATABASE_URL`, `JWT_*`, `ASAAS_*`, `SMTP_*`, `FCM_CREDENTIALS`, `S3_*`, `SENTRY_DSN`, `CORS_ORIGINS`, `TZ=America/Sao_Paulo`). Valores só no painel Coolify.

Webhook Asaas (produção):

`https://<dominio-api-prod>/api/v1/webhooks/asaas`

mesmo valor em `ASAAS_WEBHOOK_TOKEN`.

---

## 2. Backup diário (fora da VPS)

| Regra (Anexo) | Como fazer | Status |
| --- | --- | --- |
| Backup automático do Postgres prod todo dia às **03h** | Job/backup do Coolify (ou `pg_dump` agendado) | **pendente** (João configura) |
| Manter **7 diários** + **4 semanais** | Política de retenção no provedor de backup | **pendente** |
| Cópia **fora da VPS** | Enviar dump para armazenamento S3 externo (outro provedor/região que a VPS) | **pendente** |
| Testar restauração **1×/mês** em homologação | Restaurar dump num Postgres hml e conferir `/api/v1/health` + login admin | **pendente** |

Não guardar dump no repositório Git.

---

## 3. Monitoramento e alertas

Path de saúde da API no código: **`/api/v1/health`** (prefixo `api/v1`). O Anexo cita “Uptime Kuma em /health”; no Coolify/Uptime use o path completo.

| O que | Ferramenta | Alerta quando | Status |
| --- | --- | --- | --- |
| API no ar | Uptime Kuma → `GET /api/v1/health` a cada **1 min** | **2 falhas seguidas** | **pendente** (João) |
| Erros API/app | Sentry (`SENTRY_DSN` no Coolify; app com `--dart-define=SENTRY_DSN=`) | Erro novo ou **> 10/hora** | **pendente** (DSN) |
| Job cobranças D-5 | Log do job + Sentry | Não rodou até **07h** ou falhou | **pendente** operacional |
| Webhooks | Tabela `EventoWebhook` | Erro ou pendente **> 10 min** | **pendente** operacional |
| Conciliação Asaas | Job diário | Cobrança sem ciclo ou ciclo sem cobrança | **pendente** operacional |
| Servidor | Painel Coolify | Disco **> 80%** ou memória **> 90%** | **pendente** (João) |

---

## 4. Rollback (< 5 minutos na API)

| Camada | Ação | Status |
| --- | --- | --- |
| API | No Coolify, reimplantar a **imagem Docker da tag/versão anterior** | Roteiro **feito** (doc); execução **pendente** até haver prod |
| Banco | Migrações **compatíveis** com a API anterior (adicionar antes de remover) | Regra **feita** no fluxo Prisma; conferir em cada migrate |
| App | Interromper lançamento gradual no Play Console e publicar build maior | Ver `docs/PLAYSTORE.md` |

Não usar `migrate reset` em produção.

---

## 5. Checklist de lançamento em produção

Cada item: **feito** (já coberto no repo / processo) ou **pendente** (depende de João ou da Cristalins).

| # | Item | Status | Evidência / próximo passo |
| --- | --- | --- | --- |
| 1 | Preços, pesos e validades **reais** da Cristalins no seed de produção | **pendente** | Pedir à Cristalins: `contato@cristalins.com.br` · `(14) 3523-1001`. Seed atual = valores didáticos do Anexo |
| 2 | Conta Asaas de **produção** aprovada; chave e webhook configurados | **pendente** | João no painel Asaas + Coolify; não colar chave no repo |
| 3 | Emissão de **NF-e de produto** definida | **pendente** | Asaas emite NFS-e; emissor de NF-e (ERP/contador) a confirmar com a Cristalins (`contato@cristalins.com.br`) |
| 4 | Termos de uso e política de privacidade em **URL pública** | **feito** no repo | HTML em `app/web/`; URLs default no `AppConfig`. Publicar: deploy web hml. Revisão jurídica Cristalins + domínio prod **pendente** |
| 5 | CT01–CT25 passando | **feito** (código/CI local) | Suites API/app cobrem os CTs; **reexecutar** em hml/prod antes do go-live (**pendente** operacional) |
| 6 | Roteiro de aceite aprovado em **celular físico** | **pendente** | TalkBack + fluxo quiz → Pix → Minha assinatura no aparelho |
| 7 | Backup e restauração **testados** | **pendente** | Seção 2 |
| 8 | Monitoramento e alertas **ativos** | **pendente** | Seção 3 |
| 9 | Teste fechado na Play Store concluído (se conta pessoal) | **pendente** | `docs/PLAYSTORE.md` |
| 10 | Piloto de **30 a 50** assinantes na **Zona Sul** antes de abrir o Rio | **pendente** | Operação comercial; preço/zonas ajustar com dados do piloto |

---

## 6. Ordem sugerida (João)

1. Fechar itens 1–4 com a Cristalins (`contato@cristalins.com.br` · `(14) 3523-1001`).
2. Subir projeto Coolify **prod** (espelho do hml) com HTTPS e variáveis.
3. Ativar backup 03h + cópia externa; testar restore em hml.
4. Ligar Uptime Kuma + Sentry + alertas da tabela.
5. Publicar app (`docs/PLAYSTORE.md`) e só então o piloto Zona Sul.

---

## 7. O que esta documentação não faz

- Não chama Coolify, SSH, Play Console nem `git push`
- Não inventa domínio, CNPJ, D-U-N-S nem preço de catálogo real
- Não publica o app nem troca `ASAAS_MODE` sozinha
