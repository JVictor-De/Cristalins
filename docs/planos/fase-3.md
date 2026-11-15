# Plano — Fase 3 (Pix, webhook e jobs)

## Objetivo

Cobrança Pix por ciclo via `PagamentoGateway` (`AsaasGateway` | `FakeGateway`), webhook idempotente e jobs de D-5 / corte / fila.

## Entregas

1. `api/src/asaas/` — interface, Fake, HTTP Asaas, `CobrancaService`
2. Ao `POST /assinaturas` com PIX: cliente no gateway, cobrança avulsa (`externalReference` = id do ciclo), QR + copia-e-cola na resposta
3. `POST /webhooks/asaas` — token `asaas-access-token`; grava `EventoWebhook` antes do 200; processa no job de 1 min (CT14/CT15)
4. Jobs (`America/Sao_Paulo`): 06:00 gerar cobranças D+5; 00:05 corte CT22 + AGUARDANDO+3; a cada minuto processar fila
5. `POST /admin/jobs/gerar-cobrancas` — dispara o job das 06:00
6. Testes CT14, CT15, CT22 + fluxo Fake sem rede

## Fora desta fase

Cartão, boleto, régua +7/+30 (`cr-5`); tela aguardando pagamento (`cr-3-tela`).
