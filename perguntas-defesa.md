# Defesa oral — anotações

Coisas que o professor pode perguntar. Paths relativos à raiz do repo.
Tem mais detalhe em [docs/ESTUDO.md](docs/ESTUDO.md) e [docs/AP2_ACTIVITIES_INTENTS.md](docs/AP2_ACTIVITIES_INTENTS.md).

---

## Arquitetura

**O que é o projeto?**  
App Flutter (Android) + API NestJS + Postgres. Assinatura de água/WP no Rio, quiz, cesta, Pix.

**É MVC?**  
Não no monorepo inteiro. É cliente–servidor. Na API: controller → service → Prisma. No app: tela + controller + repository.

**Onde está a regra de negócio?**  
Só na API. App coleta, chama `/api/v1` e mostra.  
Ex.: preço em [api/src/](api/src/) (PrecoService), assinatura em [api/src/assinaturas/](api/src/assinaturas/).

**Por que preço não calcula no celular?**  
Uma fonte de verdade, dá pra testar (CT), cliente não adultera desconto. App só exibe o JSON.

**É BFF?**  
Não. A Nest é o backend de domínio, não uma camada na frente de vários microserviços.

---

## Intent e Activities

**O que é Intent?**  
Pedido pro Android (abrir app/tela). Não é chamada pra API.

**Onde estão as implícitas?**  
- Declaração: [app/android/app/src/main/AndroidManifest.xml](app/android/app/src/main/AndroidManifest.xml) (`queries` VIEW/SEND)  
- Código: [app/lib/core/intents/abridor_links.dart](app/lib/core/intents/abridor_links.dart) e [app/lib/core/intents/compartilhador.dart](app/lib/core/intents/compartilhador.dart)

**Exemplos pra mostrar rodando**  
- Site → onboarding [app/lib/features/welcome/presentation/onboarding_screen.dart](app/lib/features/welcome/presentation/onboarding_screen.dart)  
- Share → resultado [app/lib/features/quiz/presentation/resultado_screen.dart](app/lib/features/quiz/presentation/resultado_screen.dart)  
- Mapa → endereço [app/lib/features/address/presentation/endereco_screen.dart](app/lib/features/address/presentation/endereco_screen.dart)

**E as explícitas / várias Activities?**  
Casca nativa: [app/android/app/src/main/kotlin/br/com/cristalins/assinatura/RotaFlutterActivity.kt](app/android/app/src/main/kotlin/br/com/cristalins/assinatura/RotaFlutterActivity.kt)  
Channel: [app/lib/core/intents/navegacao_nativa.dart](app/lib/core/intents/navegacao_nativa.dart)  
Launcher ainda é [MainActivity.kt](app/android/app/src/main/kotlin/br/com/cristalins/assinatura/MainActivity.kt).

**routes.dart é Intent?**  
Não. São rotas Flutter. Equivalente de ir de tela em tela com dados.  
[app/lib/core/routes.dart](app/lib/core/routes.dart)

**O Manifest é só pra mostrar?**  
Não. Android usa de verdade (permissão internet, Activities, queries no Android 11+).

---

## API / banco / Swagger

**Onde documenta a API?**  
Swagger em `/docs` (local ou https://apicristalins.peladeiro.cloud/docs). Prefix `/api/v1`.

**CRUD?**  
Assinatura etc. em [api/src/assinaturas/](api/src/assinaturas/) — POST/GET/PUT/DELETE.

**Banco?**  
Postgres via Prisma. Schema em [api/prisma/](api/prisma/). App não fala com o banco.

**Health**  
`GET /api/v1/health`

---

## Pix / Asaas

**O QR é real?**  
Depende do `ASAAS_MODE` no servidor.  
- `sandbox` → Asaas sandbox (banco real costuma rejeitar)  
- `fake` → código com FAKE-PIX  

Gateway: [api/src/asaas/asaas.gateway.ts](api/src/asaas/asaas.gateway.ts) e [api/src/asaas/fake.gateway.ts](api/src/asaas/fake.gateway.ts)  
Escolha: [api/src/asaas/asaas.module.ts](api/src/asaas/asaas.module.ts)

**App fala com Asaas?**  
Não. Só com a nossa API. Chave fica no servidor/Coolify.

**Como vira ATIVA?**  
Webhook Asaas → confirma pagamento do ciclo. Tela: [aguardando_pagamento_screen.dart](app/lib/features/subscription/presentation/aguardando_pagamento_screen.dart)

---

## Quiz / fluxo

**Como o quiz funciona?**  
Perguntas no app → `POST /recomendacoes` → API monta kit/frequência/preço estimado.  
Telas em [app/lib/features/quiz/](app/lib/features/quiz/).

**Fluxo completo**  
Boas-vindas → login → quiz → resultado → catálogo/cesta → endereço → plano/Pix → minha assinatura.  
Roteiro curto: [docs/APRESENTACAO.md](docs/APRESENTACAO.md)

**CEP fora do Rio?**  
API recusa / lista de espera. Endereço no app + rotas de CEP na API.

---

## Código / qualidade

**Organização do Flutter?**  
Por feature: `app/lib/features/...` + `core/`.

**Organização da API?**  
Módulos Nest em `api/src/`.

**Dinheiro**  
decimal.js / Decimal no Prisma — não usar double solto.

**Segredos no APK?**  
Não. Só `API_URL` (e WhatsApp opcional). Asaas/JWT no servidor.

**Preços do seed são oficiais da marca?**  
Não. São didáticos pra disciplina. Falar isso se perguntarem.

---

## Se pedirem pra abrir no IDE

1. Manifest → Activities + queries  
2. `abridor_links` / `compartilhador`  
3. `RotaFlutterActivity`  
4. `routes.dart` (navegação Flutter)  
5. Swagger no browser  
6. Demo: compartilhar ou mapa no emulador
