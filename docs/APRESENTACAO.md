# Apresentação AP2 — roteiro de ~5 minutos

Defesa prática do app + API Cristalins (assinatura Water Protein, RJ).  
Valores de preço são **didáticos** (seed/CT); não afirmar preço real de prateleira da marca.

**Antes de começar:** API no ar (`docker compose` ou Coolify), seed aplicado, app `dev` ou APK `hml` apontando para a API. Decidir o modo Asaas:

| Plano | `ASAAS_MODE` | Confirmação do Pix |
| --- | --- | --- |
| A (preferido) | `sandbox` | Webhook real do Asaas sandbox |
| B (offline / sem chave) | `fake` | Equipe simula `POST /webhooks/asaas` no servidor com `ASAAS_WEBHOOK_TOKEN` (não no celular) |

Não há botão “Confirmar pagamento” no app — lacuna documentada em `docs/ESTUDO.md`.

---

## Minuto a minuto

### 0:00–0:40 — Abertura e proposta

- Uma frase: “App Flutter + API NestJS; regra de negócio só no servidor; Pix do ciclo via Asaas.”
- Mostrar Swagger (`/docs`) e health (`/api/v1/health`) no projetor ou no notebook.
- Citar pendência em uma linha: preços do seed são de estudo, não catálogo oficial Cristalins.

### 0:40–1:30 — Quiz e compartilhar (telas 3–4)

1. Login rápido (seed `ana.teste@cristalins.local` / `cristalins-dev-123`) ou cadastro curto.
2. Percorrer o quiz → resultado com kit/itens/frequência/preço estimado.
3. Tocar em compartilhar (`share_plus`) — Intent implícita.

### 1:30–2:20 — Cesta (tela 5)

1. Abrir catálogo; ajustar quantidades (−/+).
2. Mostrar que o total vem de `POST /precos/simular` (não é conta local).
3. Opcional: mencionar CT01 (R$ 219,09) como prova na API/testes, sem recalcular na mão no celular.

### 2:20–3:00 — CEP e mapa (tela 6)

1. Informar CEP atendido (ex.: Copacabana / Zona Sul do seed).
2. Salvar endereço; abrir “no mapa” (`geo:`) se o aparelho permitir.
3. Se sobrar tempo: CEP fora → lista de espera (`POST /lista-espera`).

### 3:00–4:10 — Pix (tela 7 → Aguardando)

1. Escolher frequência/plano Flex ou Trimestral; confirmar `POST /assinaturas`.
2. Mostrar QR / copia e cola na tela **Aguardando pagamento**.
3. **Sandbox:** pagar no app/banco de teste Asaas e esperar o webhook.  
   **Fake (plano B):** no notebook da API, rodar o `curl` do webhook (ver abaixo); a tela atualiza sozinha (~5 s de poll + job ~1 min).
4. Ao virar `ATIVA`, haptic / mensagem de confirmado → Minha assinatura.

```bash
# Só no servidor / máquina com o .env — nunca embutir o token no APK
curl -X POST http://localhost:3000/api/v1/webhooks/asaas \
  -H "asaas-access-token: <ASAAS_WEBHOOK_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"id":"evt_demo_1","event":"PAYMENT_CONFIRMED","payment":{"id":"<asaasPaymentId>","externalReference":"<cicloId>"}}'
```

### 4:10–4:40 — Banco, Swagger, pausar e cancelar (tela 8)

1. Voltar ao Swagger: `GET /assinaturas/{id}`, `GET .../ciclos`.
2. No app: pausar entregas (respeita `LIMITE_PAUSAS`) e/ou cancelar (action sheet).
3. Opcional: Prisma Studio / query rápida mostrando `Assinatura` + `Ciclo` + `Pagamento`.

### 4:40–5:00 — Fechamento

- Lembrar: app sem segredo Asaas; confirmação fake só via servidor.
- Próximos passos pós-AP2 se perguntarem: cartão (`cr-5`), operação (`cr-6`), bairros oficiais (`cr-8`).
- Oferecer perguntas (ver as 10 do `docs/ESTUDO.md`).

---

## Checklist rápido (antes de entrar na sala)

- [ ] `GET /api/v1/health` → 200  
- [ ] Swagger `/docs` abre  
- [ ] Seed com Ana/Bruno/admin  
- [ ] App conecta na API certa (`API_URL`)  
- [ ] Plano A: webhook Asaas cadastrado **ou** Plano B: `ASAAS_MODE=fake` + `curl` testado uma vez  
- [ ] Prints em `docs/prints/` (PNGs ou lembrete `.md` para o João)

## O que não fazer na fala

- Prometer benefício de saúde ou preço oficial da Cristalins  
- Mostrar `.env`, chave Asaas ou token de webhook na tela  
- Citar clube, partida ou SAC (outro produto)  
- Inventar número de WhatsApp se `SUPORTE_WHATSAPP` estiver vazio  
