# Estudo — Assinatura Cristalins

O sistema é um app Android em Flutter e uma API NestJS que vendem assinatura recorrente de Water Protein e complementos Cristalins só no Rio de Janeiro: o cliente faz um quiz, monta a cesta, valida o CEP/bairro, escolhe plano e paga o ciclo (Pix na AP2) via Asaas; a API concentra preço dinâmico, ciclos, jobs e webhooks, e o app só coleta dados e exibe o resultado.

**Pendências da Cristalins (explícitas):** preço de catálogo real, validação de marca/embalagem e validade comercial definitiva **não** estão fechadas. Seed, CT01–CT25 e exemplos deste estudo usam valores **didáticos** do Anexo/CONTEXTO — não são o preço oficial da marca.

## Usuários do seed (só desenvolvimento)

Senha de todos: `cristalins-dev-123` (bcrypt no banco). Nunca usar fora do ambiente local.

| E-mail | Papel |
| --- | --- |
| `admin@cristalins.local` | ADMIN |
| `ana.teste@cristalins.local` | CLIENTE (endereço em Copacabana, Zona Sul) |
| `bruno.teste@cristalins.local` | CLIENTE (endereço na Tijuca, Zona Norte) |

Cupom de exemplo: `BEMVINDO10` (10%, validade 31/12/2027, 100 usos).

---

## 1. Arquitetura (uma página)

```text
┌─────────────────────────────┐         HTTPS /api/v1          ┌──────────────────────────────┐
│  App Flutter (Android)      │ ─────────────────────────────► │  API NestJS (Node 22)         │
│  features/*/presentation    │ ◄──── JSON camelCase ───────── │  Controllers → Services       │
│  Controller = ViewModel     │                                │  Prisma → PostgreSQL 16       │
│  repositories (dio)         │                                │  decimal.js / ClockService    │
│  sem regra de preço/ciclo   │                                │  Jobs + Webhooks Asaas        │
└─────────────────────────────┘                                └──────────────┬───────────────┘
                                                                              │
                     Intents implícitas: site, share, geo:, wa.me             │
                                                                              ▼
                                                                   Asaas (sandbox | fake)
                                                                   ViaCEP (consulta CEP)
```

Princípios:

1. **Regra só na API** — app não calcula preço, quiz nem máquina de estados.
2. **Domínio em português** (`Assinatura`, `/assinaturas`); sufixo técnico em inglês (`AssinaturaService`).
3. **Dinheiro** com `Decimal(10,2)` / `decimal.js`; arredondamento meio-para-cima só no total final.
4. **Datas de regra** em `America/Sao_Paulo` via `ClockService`.
5. **Segredos** só no `.env` do servidor (`ASAAS_*`, `JWT_*`). Nada de chave Asaas ou token de webhook no APK.

Flavors: `dev` / `hml` / `prod` (`main_dev.dart`, `main_hml.dart`, `main_prod.dart`). API por `--dart-define=API_URL=...`.

---

## 2. Telas do app (arquivos)

| Nº | Tela | Screen | Controller / estado | Repository / domínio | Chamadas |
| --- | --- | --- | --- | --- | --- |
| 1 | Boas-vindas | `app/lib/features/welcome/presentation/boas_vindas_screen.dart` | — | — | Intent site `https://www.cristalins.com.br/` |
| 2 | Cadastro e login | `…/auth/presentation/cadastro_login_screen.dart` | `cadastro_login_controller.dart` | `auth_repository.dart`, `validadores.dart` | `POST /clientes`, `POST /auth/login`, `POST /auth/refresh` |
| 3 | Quiz | `…/quiz/presentation/quiz_screen.dart` | `quiz_controller.dart` | `recomendacao_repository.dart`, `quiz.dart` | `POST /recomendacoes` |
| 4 | Resultado | `…/quiz/presentation/resultado_screen.dart` | (usa repositório do quiz) | idem | `GET /recomendacoes/{id}`; `share_plus` |
| 5 | Catálogo e cesta | `…/catalog/presentation/catalogo_screen.dart` | `cesta_controller.dart` | `catalogo_repository.dart`, `catalogo.dart` | `GET /produtos`, `GET /kits`, `POST /precos/simular` |
| 6 | Endereço | `…/address/presentation/endereco_screen.dart` | `endereco_controller.dart` | `endereco_repository.dart`, `endereco.dart` | `GET /cep/{cep}`, `POST /enderecos`, `POST /lista-espera`; Intent `geo:` |
| 7 | Plano e pagamento | `…/subscription/presentation/plano_pagamento_screen.dart` | `plano_pagamento_controller.dart` | `assinatura_repository.dart`, `assinatura.dart` | `POST /precos/simular`, `POST /assinaturas` |
| — | Aguardando pagamento | `…/subscription/presentation/aguardando_pagamento_screen.dart` | `aguardando_pagamento_controller.dart` | idem | `GET /assinaturas/{id}` a cada 5 s até `ATIVA` (Pix de `ciclo.pix` na criação) |
| 8 | Minha assinatura | `…/subscription/presentation/minha_assinatura_screen.dart` | `minha_assinatura_controller.dart` | idem | `GET/PUT/DELETE /assinaturas/{id}`, pausar, retomar, pular-entrega, `GET .../ciclos`; WhatsApp se `SUPORTE_WHATSAPP`; entrega ENTREGUE → ocorrência |
| — | Ocorrência | `…/ocorrencias/presentation/ocorrencia_screen.dart` | `ocorrencia_controller.dart` | `ocorrencia_repository.dart` | `POST /ocorrencias` (multipart + foto) |
| — | Esqueci / Nova senha | `…/auth/presentation/esqueci_senha_screen.dart`, `redefinir_senha_screen.dart` | — | `auth_repository.dart` | `POST /auth/esqueci-senha`, `POST /auth/redefinir-senha` |

Rotas nomeadas: `app/lib/core/routes.dart`. Tema/widgets: `app/lib/core/theme/`, `app/lib/core/widgets/`.

**Nota de rota:** a tela Aguardando pagamento abre por `rotaAguardandoPagamento(criada)` (fluxo da Tela 7) e também por `pushNamed('/aguardando-pagamento', arguments: AssinaturaCriada)` — ambos mapeiam para `AguardandoPagamentoScreen` em `core/routes.dart` (corrigido em `cr-4-revisao`).

---

## 3. Endpoints do fluxo — controller → service → banco

Prefixo real: `/api/v1`.

| Método | Rota | Controller | Service | Persistência (Prisma) |
| --- | --- | --- | --- | --- |
| `GET` | `/health` | `health/health.controller.ts` | checagem Prisma | `SELECT` leve / status banco |
| `POST` | `/clientes` | `clientes/clientes.controller.ts` | `ClientesService.criar` | `Cliente` (+ hash senha) |
| `POST` | `/auth/login` | `auth/auth.controller.ts` | `AuthService.login` | lê `Cliente`; emite JWT |
| `POST` | `/auth/refresh` | idem | `AuthService` (refresh) | — |
| `GET`/`PUT`/`DELETE` | `/clientes/me` | `clientes.controller.ts` | `ClientesService` (excluir = RF05/LGPD) | `Cliente` |
| `GET` | `/produtos` | `produtos/produtos.controller.ts` | listagem | `Produto` |
| `GET` | `/kits` | `kits/kits.controller.ts` | listagem | `Kit` + `KitItem` |
| `POST`/`GET` | `/recomendacoes` | `recomendacoes/recomendacoes.controller.ts` | `RecomendacaoService` | `Recomendacao` (+ itens) |
| `POST` | `/precos/simular` | `precos/precos.controller.ts` | `PrecoService.simular` → `calcular` | lê `Produto`, `FatorPreco`, `Zona`, `Cupom`, ciclos/pagamentos |
| `GET` | `/cep/{cep}` | `enderecos/enderecos.controller.ts` | `EnderecosService` + ViaCEP | cruza bairro com `Zona` do seed |
| `POST` | `/lista-espera` | `lista-espera/lista-espera.controller.ts` | service lista-espera | `ListaEspera` |
| `POST`/`GET`/`PUT`/`DELETE` | `/enderecos` | `enderecos.controller.ts` | `EnderecosService` | `Endereco` |
| `POST` | `/assinaturas` | `assinaturas/assinaturas.controller.ts` | `AssinaturasService.criar` → `PrecoService` → `CobrancaService.cobrarCicloPix` | `Assinatura`, `ItemAssinatura`, `Ciclo`, `ItemCiclo`, `CalculoPreco`, `Pagamento` |
| `GET`/`PUT`/`DELETE` | `/assinaturas/{id}` | idem | `AssinaturasService` + máquina de estados | `Assinatura` / ciclos |
| `POST` | `…/pausar`, `…/retomar`, `…/pular-entrega` | idem | `AssinaturasService.pausar` / `retomar` / pular | status + limites |
| `GET` | `/assinaturas/{id}/ciclos` | idem | listagem | `Ciclo` |
| `POST` | `/webhooks/asaas` | `webhooks/webhooks.controller.ts` | `WebhooksService.receber` → job `processarPendentes` → `CobrancaService.confirmarPagamentoDoCiclo` | `EventoWebhook`, `Pagamento`, `Ciclo`, `Assinatura` |
| `PUT` | `/admin/produtos/{id}`, `/admin/fatores-preco`, `/admin/zonas/{id}` | `admin/admin.controller.ts` | admin services | `Produto` / `FatorPreco` / `Zona` |
| `POST` | `/admin/jobs/gerar-cobrancas` | idem | `JobsService.gerarCobrancas` | novos `Pagamento` / cobranças |
| `GET` | `/admin/separacao?data=` | `admin/admin.controller.ts` | `OperacaoService.separacao` | ciclos PAGO/SEPARADO do dia + prévia RN06 |
| `PUT` | `/admin/ciclos/{id}/status` | idem | `OperacaoService.atualizarStatus` | SEPARADO/EM_ROTA/ENTREGUE/FALHOU + estoque/avisos |
| `POST`/`GET` | `/ocorrencias` | `ocorrencias/ocorrencias.controller.ts` | `OcorrenciasService` | foto MinIO/`S3_*`; crédito ou reposição |
| `PUT` | `/notificacoes/push-token` | `notificacoes/notificacoes.controller.ts` | `NotificacoesService` | token FCM do aparelho |
| `POST` | `/auth/esqueci-senha`, `/auth/redefinir-senha` | `RecuperacaoSenhaController` | `RecuperacaoSenhaService` | código HMAC; SMTP se configurado |

Gateway de pagamento: `api/src/asaas/` — `PagamentoGateway` escolhido por `ASAAS_MODE` (`FakeGateway` ou `AsaasGateway`).
Push/e-mail: `api/src/notificacoes/` (FCM + SMTP; sem credencial → só log mascarado).

### Confirmação Pix (demo) e lacuna

| Modo | Como o pagamento vira `ATIVA` |
| --- | --- |
| `sandbox` | Asaas envia webhook → `POST /webhooks/asaas` com `asaas-access-token` |
| `fake` | **Não há botão no app.** A equipe simula o mesmo webhook no servidor (token só no `.env`). `FakeGateway.confirmarPagamento` e `CobrancaService.confirmarFake` existem, mas **nenhum controller** os expõe |

Sugestão pós-AP2 / correção: `POST /admin/pagamentos/{asaasPaymentId}/confirmar-fake` (ADMIN, só `ASAAS_MODE=fake`).

Exemplo de simulação no servidor (token **não** vai no app):

```bash
curl -X POST http://localhost:3000/api/v1/webhooks/asaas \
  -H "asaas-access-token: <ASAAS_WEBHOOK_TOKEN do .env>" \
  -H "Content-Type: application/json" \
  -d '{"id":"evt_demo_1","event":"PAYMENT_CONFIRMED","payment":{"id":"<asaasPaymentId>","externalReference":"<cicloId>"}}'
```

O job processa a fila ~1×/min; a tela de aguardo consulta a cada 5 s.

---

## 4. CT01 passo a passo (R$ 219,09)

**Entrada (Anexo / testes):** 24× WP500, frequência quinzenal, plano **Trimestral**, **2** ciclos anteriores pagos em dia, data de entrega no **verão** (fator demanda), zona **Zona Sul** (frete R$ 9,90).

Ordem do `PrecoService` (`api/src/precos/preco.service.ts`):

| Passo | Fator | Valor | Efeito |
| --- | --- | --- | --- |
| 1 | Volume (`dVol`) | 24 UE → **8%** | faixa 24–47 |
| 2 | Compromisso (`dComp`) | Trimestral → **7%** | |
| 3 | Fidelidade (`dFid`) | 2 ciclos × 1% → **2%** | teto 5% |
| 4 | Demanda (`aDem`) | verão seed → **+5%** | |
| 5 | Cupom | 0 | |

```text
fator = (1 − 0,08) × (1 − 0,07) × (1 − 0,02) × (1 + 0,05) × (1 − 0)
      = 0,92 × 0,93 × 0,98 × 1,05
      ≈ 0,8804124
```

- Preço base WP500 = **9,90**; piso = **7,50**  
- Unitário = `max(9,90 × fator, piso)` ≈ **8,716…** (sem arredondar ainda)  
- Subtotal = 24 × unitário ≈ **209,186**  
- Frete Zona Sul = **9,90** (subtotal ≤ 50)  
- Total = `max(0, subtotal + frete − créditos)`, arredondamento meio-para-cima 2 casas → **219,09**

Evidência automatizada: `api/src/precos/preco.service.spec.ts` e `preco.simular.spec.ts` (`fatores: { volume: 8, compromisso: 7, fidelidade: 2, demanda: 5, cupom: 0 }`, `total: 219.09`).

**CT02 (contraste):** mesma cesta, 1º ciclo, novembro (sem demanda/fidelidade) → fatores volume 8 + compromisso 7 → **213,19**.

---

## 5. Requisitos cobertos na AP2

Até `cr-4-revisao`:

- Fundação monorepo, Prisma (20 entidades), CI, health/Swagger  
- Auth JWT + cadastro (CT19, CT24)  
- Preço dinâmico + recomendação (CT01–07, 11–13, 25)  
- Ciclo / assinatura / CEP / lista-espera (CT08–10, 16, 17, 20, 23)  
- 8 telas Flutter + Aguardando pagamento  
- Gateway Pix Asaas/Fake, webhook, jobs (CT14, 15, 22)  
- Dockerfile / roteiro Coolify (`docs/DEPLOY.md`)  
- Acessibilidade documentada (`A11Y.md` na pasta da fila; testes de guideline)  
- Este README / estudo / roteiro de apresentação  

**Pós-AP2:** cartão/boleto (`cr-5`), ocorrências/fotos/FCM (`cr-6`), LGPD/SEG/Sentry (`cr-7` → `docs/SEGURANCA.md`), lista oficial de bairros (`cr-8`).

---

## 6. Dez perguntas (e respostas) para a defesa

1. **Por que o preço não é calculado no app?**  
   Para uma única fonte de verdade, testes (CT01+) e para o cliente não manipular descontos. O app só exibe o JSON da API.

2. **O que é o fator composto do preço?**  
   `(1−dVol)×(1−dComp)×(1−dFid)×(1+aDem)×(1−cupom)`, depois `max(base×fator, piso)`, trava ±10% vs ciclo anterior e frete/créditos; arredonda só o total.

3. **Como o Pix entra na criação da assinatura?**  
   `AssinaturasService.criar` persiste assinatura/ciclo e chama `CobrancaService.cobrarCicloPix`; a resposta 201 inclui `ciclo.pix` (copia e cola + QR).

4. **Como a assinatura vira `ATIVA`?**  
   Webhook `PAYMENT_RECEIVED` / `PAYMENT_CONFIRMED` → fila → `confirmarPagamentoDoCiclo` (ciclo `PAGO`, assinatura `ATIVA`, RN08 da 1ª entrega).

5. **E no modo `fake` da apresentação?**  
   O QR/copia e cola são simulados. A confirmação **não** está no app: a equipe posta no webhook com o token do servidor, ou (lacuna) usaria `confirmarFake` se existisse rota admin.

6. **O que acontece se o CEP estiver fora da área?**  
   `422 CEP_FORA_AREA` ou `BAIRRO_NAO_ATENDIDO`; o app pode oferecer `POST /lista-espera`.

7. **Como o quiz vira cesta?**  
   `RecomendacaoService` deriva frequência, kit/itens e `valorEstimado` via `PrecoService` (Flex, sem fidelidade/frete). O app mostra e deixa o cliente ajustar no catálogo.

8. **Onde ficam os segredos do Asaas?**  
   Só variáveis de ambiente no servidor / Coolify. O APK recebe apenas `API_URL` (e opcionalmente WhatsApp).

9. **O que a rubrica de Activities/Intents vira no Flutter?**  
   Rotas nomeadas = passagem explícita de dados; `url_launcher` / `share_plus` = Intents implícitas (site, mapa, WhatsApp, compartilhar). Decisão em `docs/DECISOES.md`.

10. **Quais números da AP2 são “de mentira” comercialmente?**  
    Preços base/piso do seed, totais CT01/CT02 e kits de exemplo. Pendência: alinhar com a Cristalins preço real, marca e validade antes de produção.
