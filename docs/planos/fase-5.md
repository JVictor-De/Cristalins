# Plano — Fase 5 (pagamento completo, pós-AP2)

Pré-requisito: `REVISAO_AP2.md` marca a AP2 como **aceita** (não bloqueada).

## Esta etapa (`cr-5-cobranca`)

Cobrança avulsa por ciclo no Asaas (nunca a assinatura de valor fixo), agora em **Pix, boleto e cartão tokenizado**, com a régua completa e os RN que faltam.

| Item | Regra | Onde |
| --- | --- | --- |
| Cartão | Tokenizar (`POST /v3/creditCard/tokenize`); guardar só `asaas_token`, bandeira e 4 últimos dígitos. Número e CVV só passam em memória até o Asaas | `api/src/asaas/cartao.service.ts`, `POST/GET /cartoes` |
| Cobrança por forma | Em D-5: Pix (QR), boleto (link, vence em D-5 — RN25) ou cartão (token) | `CobrancaService.cobrarCiclo` |
| CT18 | `PAYMENT_CREDIT_CARD_CAPTURE_REFUSED` → cobrança cancelada, nova tentativa no dia seguinte (1 vez) e aviso ao cliente; na 2ª recusa, pede outra forma | `CobrancaService.processarEvento` + `ReguaService` |
| Eventos | `PAYMENT_OVERDUE` → VENCIDO; `PAYMENT_REFUNDED` → ESTORNADO; `PAYMENT_DELETED` → CANCELADO | `CobrancaService.processarEvento` |
| Régua | Vencimento +7 dias → assinatura SUSPENSA; +30 → CANCELADA e cobrança encerrada; pagar reativa (SUSPENSA → ATIVA) | `api/src/asaas/regua.service.ts` |
| Créditos (RN20) | Válidos 90 dias; abatem o total na geração da cobrança (depois do piso; total nunca negativo); total 0 → ciclo pago sem cobrança no Asaas | `api/src/creditos/`, `CobrancaService` |
| Cupom (RN21) | `POST /admin/cupons`; continua no fator de cada item, sem furar o piso (`PrecoService`) | `api/src/cupons/` |
| Indicação (RN22) | R$ 15 de crédito para quem indicou, uma vez, quando o 1º ciclo do indicado é pago | `CreditosService` + `CobrancaService` |
| Arrependimento (RN14) | Até 7 dias da assinatura: sem entrega → estorno integral; com entrega → registro aguardando devolução | `POST /assinaturas/{id}/arrependimento` (módulo asaas) |
| Troca de forma | Pix, boleto ou cartão salvo; vale para a próxima cobrança | `PUT /assinaturas/{id}/forma-pagamento` (módulo asaas) |
| Faturas | Lista de cobranças do cliente, link do boleto/fatura e comprovante | `GET /faturas`, `GET /faturas/{id}/comprovante` |
| Conciliação diária | Cobrança no Asaas sem ciclo/pagamento local, ou ciclo cobrado sem cobrança → registro de divergência | `api/src/asaas/conciliacao.service.ts` |
| App | Tela de faturas e comprovantes; forma de pagamento em seção agrupada; cadastro de cartão sem guardar número nem CVV | `app/lib/features/subscription/` |

### Pontos fora do "Escreve em" (mínimos e sinalizados no relatório)

- `api/src/webhooks/webhooks.service.ts`: eventos que não sejam pagamento confirmado → `CobrancaService.processarEvento`
- `api/src/jobs/jobs.service.ts`: cobrança D-5 por forma (`cobrarCiclo`) e régua → `ReguaService` + conciliação

### Fora desta etapa

- Push e e-mail do aviso ao cliente (`cr-6-operacao`): o aviso vira log + status da fatura no app
- Transição PAGO → CANCELADO para estorno (diagrama do Anexo não tem): o ciclo estornado fica marcado em `CalculoPreco.fatores.estornado` até uma fase poder mudar a máquina de estados
