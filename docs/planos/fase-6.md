# Plano — Fase 6 (operação e notificações, pós-AP2)

Fase `cr-6-operacao`. Fonte: `CONTEXTO.md` e o Anexo de `super-prompt-cristalins.md` (RN06, RN15, RN17, RF22, RF29, RF31, RF32, RF48, RF49, RF51, RF52, CT21). Prefixo `/api/v1`; erro `{ codigo, mensagem, campo? }`.

| Item | Regra | Onde |
| --- | --- | --- |
| Estoque (RN06, RF48, CT21) | Na separação (PAGO → SEPARADO), item sem estoque troca por produto ativo **do mesmo tipo e volume**, com preço base **igual ou menor** e estoque suficiente (o de maior preço base entre os elegíveis). O cliente é avisado. Sem substituto, o item é pulado e vira crédito (`precoUnitario × quantidade`, 90 dias). `estoque = null` = sem controle. Baixa do estoque na separação | `api/src/admin/estoque.service.ts` |
| Separação (RF29) | `GET /admin/separacao?data=AAAA-MM-DD`: ciclos PAGO ou SEPARADO do dia, por zona, com itens, prévia das trocas e reposições pendentes | `api/src/admin/operacao.service.ts` |
| Status da entrega (RF31, RN17) | `PUT /admin/ciclos/{id}/status` (SEPARADO, EM_ROTA, ENTREGUE, FALHOU) pela máquina de estados. 1ª falha: reentrega grátis no próximo dia de rota da zona (nova `dataEntrega`). 2ª falha: registra e avisa "nova taxa ou retirada" (sem inventar valor) | idem |
| Ocorrência (RN15, RF49) | `POST /ocorrencias` (multipart: `foto`, `cicloId`, `tipo` AVARIA/FALTA, `produto`, `quantidade`, `solucao` REPOSICAO/CREDITO). Só ciclo ENTREGUE do próprio cliente, até 24 h depois da entrega. CREDITO: crédito na hora (valor pago do item) e ocorrência RESOLVIDA. REPOSICAO: fica ABERTA e entra na separação da próxima entrega da assinatura, ficando RESOLVIDA quando ela é separada. `GET /ocorrencias` lista as do cliente | `api/src/ocorrencias/` |
| Foto no MinIO | PUT assinado (AWS SigV4, sem SDK novo) no bucket `S3_BUCKET` de `S3_ENDPOINT`. O banco guarda `s3://bucket/chave`: nenhuma URL pública nem com credencial. Sem `S3_*`, guarda em memória (dev/teste) | `api/src/ocorrencias/armazenamento-fotos.ts` |
| Push (RF51, RF22) | FCM HTTP v1 com `FCM_CREDENTIALS` (JSON da conta de serviço). Eventos **só** COBRANCA, PAGAMENTO, SEPARACAO, ENTREGA e AUMENTO_PRECO. Token do aparelho: `PUT /notificacoes/push-token` | `api/src/notificacoes/` |
| E-mail (RF51, RF52) | SMTP (TLS implícito, porta 465 por padrão) com `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`. Mesmos eventos + recuperação de senha. Sem variável → só log mascarado | idem |
| Aumento de preço (RF22) | Na geração da cobrança (D-5): total maior que o do ciclo anterior → aviso "pode pular ou alterar até o corte" | `CobrancaService` (toque mínimo) |
| Senha (RF52) | `POST /auth/esqueci-senha {email}` sempre 200 (não revela cadastro) e envia um código de 6 dígitos válido por 30 min. O código é HMAC do `JWT_SECRET` com o id, o hash atual e a janela: vale uma vez, porque o hash muda. `POST /auth/redefinir-senha {email, codigo, novaSenha}`: 5 erros por e-mail em 30 min → 429 | `api/src/notificacoes/recuperacao-senha.*` |
| Geocodificação | Sem provedor no contexto: `lat`/`lng` continuam nulos; pendência em `docs/DECISOES.md` | — |
| App | Tela de ocorrência (foto pelo `image_picker`, tipo, item, reposição ou crédito) a partir de uma entrega entregue na Tela 8; telas "Esqueci a senha" e "Nova senha" a partir do login; registro do token de push (`firebase_messaging`) sem quebrar sem `google-services.json` | `app/lib/features/ocorrencias/`, `app/lib/features/auth/`, `app/lib/core/push/` |

## Fora desta fase

- Rota de entrega (RF30), cobrança da nova taxa na 2ª falha (valor não definido), painel admin (RF39) e nota fiscal (RF40)
- `google-services.json` e o plugin Gradle do Firebase: o João adiciona com o projeto Firebase real
- Sentry (`cr-7-qualidade`)
