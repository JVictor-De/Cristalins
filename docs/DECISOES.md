# Decisões

## 2026-11-14 — Fundação (`cr-0-repo`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Rubrica pede Activities e Intents nativos | Seguir Flutter: rotas nomeadas = passagem explícita; `url_launcher` / `share_plus` = Intents implícitas. Não reescrever em Kotlin. | Stack fechada no contexto; risco a confirmar com o professor |
| Como serializar dinheiro no JSON | Número com 2 casas (ex.: `118.80`, `219.09`) no contrato Swagger; cálculo interno com `decimal.js` / `Decimal(10,2)` | Exemplos do Anexo são o contrato |
| `applicationId` Android | `br.com.cristalins.assinatura`, `br.com.cristalins.assinatura.dev`, `br.com.cristalins.assinatura.hml` | Monólito não fixa; fila fecha assim |
| Número do WhatsApp de suporte | Default fictício `5521999999999` (HML/dev); override via `--dart-define=SUPORTE_WHATSAPP=` | Botão de suporte precisa funcionar em demo; número real da marca ainda não definido |
| Download de `docs/flutter-rules.md` | URL `rules_10k.md` retornou 404; arquivo placeholder com o link | Não inventar regras oficiais; baixar de novo quando a URL existir |

## 2026-11-14 — Schema Prisma (`cr-0-prisma`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Versão do Prisma | 7.10.1 fixa (`latest` no npm é `8.0.0-rc.33`) | Não usar RC; Prisma 7 pede `prisma.config.ts` e driver adapter |
| TypeScript | 5.9 fixo (npm trouxe 7.0) | Compatibilidade com o tooling do NestJS em `cr-0-api` |
| Status de `Pagamento` | `PENDENTE`, `PAGO`, `VENCIDO`, `CANCELADO`, `ESTORNADO` | Anexo não lista; mínimo para Pix e régua; `cr-3-gateway` mapeia os status do Asaas |
| Status de `Ocorrencia` | `ABERTA`, `RESOLVIDA` | Anexo só cita `status`; ajustar em `cr-6-operacao` |
| `Zona.dias_entrega` | Lista do enum `DiaSemana` (`SEG`…`SAB`) | Tipado em vez de texto livre |
| `FatorPreco` | Uma linha por chave e vigência (`@@unique([chave, ativoDe])`), valor em fração | Verão sazonal: seed só 01/12/2026–31/03/2027; próximos verões por admin/seed |
| `Recomendacao.kit_id` | Opcional | Caso C (perfil Empresa) não tem kit |
| Migração sem banco | Gerada com `prisma migrate diff --from-empty --script`; não aplicada | Docker não estava rodando e iniciar o Docker Desktop foi negado à sessão |

## 2026-11-14 — API vazia (`cr-0-api`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Cliente Prisma gerado importa `./x.ts` | `rewriteRelativeImportExtensions` no `tsconfig.json` e `moduleNameMapper` `.js → sem extensão` no Jest | Fase não pode alterar o schema (opção `importFileExtension` do generator); Node não resolve `.ts` no `dist` |
| Build inclui `prisma/generated` | `rootDir: "."`; saída `dist/src/main.js`, `start:prod = node dist/src/main` | Cliente gerado fica fora de `src/`; Dockerfile (`cr-4-deploy`) deve rodar `prisma generate` antes do `nest build` |
| Códigos de erro genéricos | 400 `DADOS_INVALIDOS` (validação, com `campo`) / `REQUISICAO_INVALIDA`, 401 `NAO_AUTENTICADO`, 403 `SEM_PERMISSAO`, 404 `NAO_ENCONTRADO`, 409 `CONFLITO`, 422 `REGRA_VIOLADA`, 429 `MUITAS_TENTATIVAS`, 503 `SERVICO_INDISPONIVEL`, 500 `ERRO_INTERNO` | Só quando a exceção não é `RegraNegocioException`; os códigos do Anexo (`SEM_PERMISSAO`, `MUITAS_TENTATIVAS`) batem |
| `/health` sem banco | 503 no formato de erro | Compose e Uptime Kuma enxergam a queda do banco |
| Conexão do Prisma | Sob demanda (sem `$connect` no boot) | API sobe mesmo com o banco fora; o health mostra o estado |
| Versões | NestJS 11, Jest 30, ESLint 9, `@types/node` 22 | Node 22 da stack |

## 2026-11-15 — Deploy (`cr-4-deploy`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Trust proxy | `app.set('trust proxy', 1)` em `main.ts` | Atrás do Coolify, `req.ip` sem trust junta todo mundo no throttle do login (CT19) |
| Health no container | `/api/v1/health` (não `/health`) | Prefixo real da API; compose e Uptime usam o mesmo path |
| Prisma no runtime | `npm prune --omit=dev` + `prisma@7.10.1` no stage build | CLI fica em devDependencies; `migrate deploy` no entrypoint precisa dela |
| Push de imagem no CI | Só comentário em `docs/DEPLOY.md` | Fase não altera workflow; João pede depois |

## 2026-11-15 — Operação (`cr-6-operacao`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Geocodificação (`Endereco.lat`/`lng`) | Campos ficam **nulos**; nenhum provedor no CONTEXTO/Anexo | Não inventar coordenada; mapa segue com `geo:` do endereço textual |
| Foto da ocorrência | Referência interna `s3://bucket/chave` (PUT SigV4); sem `S3_*` → memória em dev | Bucket privado; resposta da API só `temFoto` (sem URL/credencial) |
| Push FCM no app | `firebase_messaging` sem plugin Gradle/`google-services.json` nesta fase | João adiciona o projeto Firebase real; sem arquivo o app segue e só deixa de registrar token |
| Código de recuperação de senha | HMAC do `JWT_SECRET` + id + hash atual + janela 15 min (vale 15–30 min) | Sem tabela nova; invalida ao trocar a senha |

## 2026-11-15 — Bairros oficiais (`cr-8-bairros`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Fonte da lista | IPP / Prefeitura: [Lista de Bairros e APs](https://www.rio.rj.gov.br/dlstatic/10112/5148142/4145881/ListadeBairroseAPs_Mapa) (+ Decreto 3.158/1981) | Contrato exige fonte pública da prefeitura; gravada em `api/prisma/data/bairros-rj.json` |
| AP oficial ≠ zona de frete | Mapear para as 5 zonas do Anexo sem mudar taxa/dias | CONTEXTO fixa Centro/Zona Sul R$ 9,90; Barra e Recreio / Zona Norte R$ 12,90; Zona Oeste R$ 19,90 — não inventar frete |
| Grande Tijuca (AP2 oficial) | Entra na zona comercial **Zona Norte** (Tijuca, Vila Isabel, Andaraí, Grajaú, Maracanã, Alto da Boa Vista, Praça da Bandeira) | Anexo já coloca Tijuca e Vila Isabel em Zona Norte; manter taxa 12,90 |
| Rocinha (AP2) | Zona Sul comercial | Contígua a São Conrado / Lagoa; mesma taxa 9,90 do Anexo |
| Paquetá (AP1) | Centro comercial, mesma taxa 9,90 | AP oficial Centro; não criar taxa especial |
| Lapa / Recreio / Ilha do Governador | Aliases no JSON (não são sempre a denominação IPP isolada) | Seed AP2 e ViaCEP usam esses nomes; `CepService` compara normalizado |
| Schema | Sem migração nova: `Zona.bairros` já é `String[]` | Só upsert no seed |
| CT23 após lista completa | Testes usam bairro **não oficial** (`Morro do Teste`) | Grajaú passou a ser atendido (Zona Norte); CT23 continua válido para nome fora do mapa |

## 2026-11-16 — Redesign marketplace (`cristalins_marketplace`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Visual Ajustes/Cupertino da fila assinatura | Redesign marketplace **substitui** o estilo Ajustes/Cupertino (sem sombra / sem gradiente / um amarelo) nas telas desta fila | João rejeitou listas cinzas sem fotos; referência iFood + cores/fotos de `cristalins.com.br` |
| Restrições da skill `apple-style-flutter` / seção Cores da assinatura | **Revogadas** para estas telas: sombra, gradiente (só hero/banner), cards, barra de sacola, tipografia serifada de título | Monólito `PROMPT_MONOLITO.md` §3; regras de negócio (preço/quiz/ciclo) inalteradas |
| O que continua proibido | SF Pro, SF Symbols, blur no Android, promessa de saúde, vender Cristalins Ultra, calcular preço/quiz/ciclo no app | Mesmas proibições do CONTEXTO assinatura que o monólito mantém |
| `azulMarca` CTA | Manter `#087FAE` (site); contraste branco ≈ **4,51** (AA ≥ 4,5). Fallback `#076A94` não necessário | Validação WCAG 2.1 AA na fase `mk-1-tokens` |
| `verdeProtein` | `#95CC3C` (média da tampa em `protein.webp`; rótulo iluminado ~`#9DE365`) | Amostra factual do asset; ≈ `#8CC63F` do CONTEXTO |
| ~~Tipografia hero~~ | ~~DM Serif Display Regular (OFL) embarcada; corpo Inter~~ — **REVOGADA 2026-11-17** (P6 cleanup: fonte removida, só Inter) | ~~Monólito §3.2~~ |
| `flow_protein.webp` | Redimensionado para largura 1200 (~64 KB no app) | Monólito pede ≤ ~1200 px / evitar ~1,8 MB |
| UX v3 (registrar) | Home bifurcada; frequência só na sacola; mínimo com sugestão; login contextual | Monólito v3 missão / §2 |
| Âncora de preço nos cards | `A partir de {precoBase.formatado}/un.` (catálogo); total só via simulação | Crítica design 2026-11-16; não inventar preço no app |
| Hero WP asset | Usar `produtos/protein.webp` (não `flow_protein.webp` = print de landing) | BUGS_UX #3–5; tipografia só no widget |
| Origem / Como funciona | Foto `ams500.webp` + copy curta; não crop de `colocar_site-fast.webp` | BUGS_UX #2, #5 |
| Logo header | `brand/logo.png` transparente + `LogoMarca` **sem** ColorFilter (JPG/`ColorFilter` aposentados) | BUGS_UX #7; ver tabela polimento PNG abaixo |
| Ícone aba Assinatura | `Icons.water_drop_outlined` / `water_drop` (substitui `autorenew`) | BUGS_UX #31; recorrência de água mais legível |
| Abrir Produtos | `AbrirProdutosCallback({Categoria?})` no shell — Montar≠Ver águas | BUGS_UX #11, #24 |
| Animação impacto (`mk-5b`+) | Cena na PDP de **todas** as SKUs do catálogo; mineral usa garrafa+copy do site; WP/Fiber/Guaraná usam foto do produto e **sem** frase “água mineral” | Pedido João 2026-11-16 — mesma cena, rótulo honesto |
| Motion impacto | `AnimationController` 1,8 s espelhando CSS site; sem Lottie/Rive; reduced motion → frame final | A11y + parity com `impacto__*.css` |

## 2026-11-16 — Polimento UX pós-smoke P5 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| P5.2 coleta mínima | **Opção B** — CPF + nascimento (ou constituição CNPJ) permanecem no create | API `CriarClienteDto` ainda exige; não fingir deferral |
| Celular | Obrigatório no form; API continua opcional mas app sempre envia | Entregador; sem migrate |
| CNPJ | `nome` = razão social; data = constituição (mesmo campo `dataNascimento`) | Sem coluna IE/razão; P5.10 gate |
| Cabeçalho | AppBar + `LogoMarca`; sem `largeTitle` “Criar conta” | Título só na aba/CTA |
| Explorar | Link discreto **abaixo** do CTA | Fora do miolo do form |
| Destino pós-sucesso | `arguments: 'checkout'` → `pop` (sacola); senão quiz / minha assinatura | P5.7 |
| Termos URL | Default `https://cristalins.peladeiro.cloud/termos.html` e `…/privacidade.html` (`AppConfig`); override via dart-define; vazio desliga links | Páginas em `app/web/*.html`; domínio do projeto (não inventar path em cristalins.com.br) |
| Gates | OAuth/OTP/captcha/HIBP/analytics/IE/biometria | Documentados; não inventar |

## 2026-11-16 — Polimento UX pós-smoke P4 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Título Perfil (aba shell) | `AppTypography.title3` (não `largeTitle`) | P4.1; alinha Sacola/shell |
| CTA guest | “Entrar ou criar conta” navy + “Com e-mail e senha” | P4.2; sem Google/Apple/telefone |
| Termos / privacidade | HTML em `app/web/termos.html` e `privacidade.html`; URLs default no `AppConfig` + Dockerfile | URL pública no domínio hml; Play Store / LGPD |
| Versão app | `AppConfig.versaoApp` default `0.1.0+1` (= pubspec) | Sem `package_info_plus` |
| CEP no Perfil | Mesma sheet/`consultarCep` da Home | API já existe |
| Logado: nome/foto/status | Planejado; copy honest até ligar `/clientes/me` na tela | P4.5 parcial |
| Endereços / Notificações | “Em breve” (sem rota guest-safe) | Não fake |
| Faturas | Deep-link `MinhaAssinatura` (precisa id p/ `FaturasScreen`) | Rota dedicada exige assinaturaId |
| Excluir conta | Só logado; `DELETE /clientes/me` + sheet confirmação | Guest não vê Excluir |

## 2026-11-16 — Polimento UX pós-smoke P3 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Fonte única do total | Helper `SacolaCopy` + `sim.total.formatado` na Sacola e `BarraSacola` | P3.12; evita 72,86×72,88 |
| Continuar / AppBar | `BotaoPrincipal` navy; scaffold/AppBar `AppColors.fundo` | P3.1 |
| Config assinatura | Card único freq+plano; sem subtítulo “Padrão: quinzenal…” | P3.2 / P3.4 |
| ≈/mês | UI: `total × 4/2/1` por SEMANAL/QUINZENAL/MENSAL; caption suave | Aproximação de exibição; não é regra de preço API |
| Empty “Assinar WP” | `adicionarPasso(WP)` se no catálogo; senão shell Produtos (não PDP) | Alinha P1 hero; evita PDP órfã |
| Cupom / CEP na Sacola | Omitidos aqui — cupom no pagamento; CEP no fluxo endereço | Não inventar UI sem wiring completo |
| Seed preço galão | Fora do app (HANDOFF humano) | Contrato “Não fazer” |

## 2026-11-16 — Polimento UX pós-smoke P2 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Ordem carrossel Home | Águas / Fiber / galão primeiro; `WP500` peso 90 (fim); `AMN5000` forçado no `take(8)` se filtro Todos | P2.5; WP já no hero |
| Filtros carrossel | Enum local `FiltroHomeCarrossel` (Todos/Sem gás/Com gás/Funcionais/Galão) por `codigo`/`nome`/`volumeMl` | Não misturar com `Categoria` da aba Produtos |
| Pular / Editar na Home | TextButtons → `onAbrirAssinatura` (aba Assinatura); sem POST na Home | Confirmação/`pularEntrega` já vivem em Minha assinatura |
| Oferta 1º pedido | Faixa tipográfica Pix/frequência **sem** %/R$ | Gate monólito P2.7 |
| FAQ / WhatsApp | FAQ estática (RJ, pausa, cancelamento); WhatsApp só se `suporteWhatsapp` ≠ vazio | Honesty + config já usada no Perfil |
| Banner marca | `assetHeroAguaBokeh` + overlay + “Da fonte ao Rio” | Asset existente; sem inventar serra |
| Selos | Água mineral / entrega RJ / Pix — sem NPS | P2.4 |
| Como funciona | 3 cards com ícones; copy “Semanal, quinzenal ou mensal” | P2.1–P2.2 |
| Skeletons / erro | Hero `SkeletonCard` se `carregandoCatalogo`; carrossel skeletons + `EstadoErro` + retry | P2.9 |

## 2026-11-16 — Polimento UX pós-smoke P1 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Fundo tela | Token `AppColors.fundo` `#F6F9FB`; `gelo` fica accent | P1.1; não quebrar usos de gelo em chips/progress |
| Hero tipografia | Inter (`title2`), não DM Serif | P1.2 monólito |
| Badge hero | **Mais vendido** | Substitui Carro-chefe |
| Chips hero | Uma linha “5 g de proteína por garrafa · 0 açúcar · 0 gordura” | Mesmo copy do monólito; evita overflow em largura estreita |
| Preço no hero | `a partir de {precoBase.formatado}/garrafa` só se WP no catálogo | Mesma fonte `precoBase` dos cards |
| “Ver todas as águas” | Manter, alinhado à **esquerda** sob o CTA | Complementa “Ver todos” da seção (produtos gerais ≠ só águas) |
| Assinar WP | `adicionarPasso(WP)` + `AppRoutes.sacola`; WP ausente → aba Produtos | Sem PDP órfã |
| Badge sacola header | Contador = `SacolaController.totalItens` (soma qty) | P1.5 |
| `BarraSacola` | `BotaoPrincipal` navy “Ver sacola”; copy `N itens · {sim.total.formatado} por entrega` | Mesma fonte da Sacola |
| CEP Home | Sheet + `EnderecoRepository.consultarCep`; rótulo só na sessão | API já existe; sem inventar endpoint / sem store guest |

## 2026-11-16 — Polimento UX pós-smoke P0 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| FF “xadrez” / caixa preta | Reexport `flow_fiber-fast.png` RGBA (fundo preto → alpha 0) + max width 1200 | Prints pediam PNG sem caixa; chroma-key local sem inventar asset novo |
| Nome no card | Helper `nomeCardProduto` (WP/FF curtos; demais = `nome` API) | Monólito P0.4; evita título longo competindo com seção |
| Após 1º “+” no card | Troca para `StepperQuantidade`; SnackBar “Adicionado à sacola” + haptic | P0.7; reusa widget da PDP/sacola |
| ~~Fundo miniatura~~ | ~~`corDoProduto(codigo).withValues(alpha: 0.22)` + card branco/`superficie` + borda~~ — **REVOGADA 2026-11-16** por `dux-1-p0-card-home` (card foto-âncora, ver seção abaixo) | ~~P0.3~~ |
| Banner “Da fonte ao Rio” | Só tipografia — remove mini-garrafa do bloco Como funciona | P0.5; evita órfã flutuante |
| Skeleton hero | `SkeletonCard` enquanto `carregandoCatalogo` no lugar do hero visitante | P0.8 |
| `CardKit` minis | `codigosItens` → até 4 `assetDoProduto`; remove `Spacer` void | P0.6 |
| Preço/% nos cards | Âncora `precoBase` (“A partir de …/un.”); **sem** % promocional inventado | Gate revogado 2026-11-16 (crítica design) |
| Entry canônico | Splash → onboarding → shell; `/boas-vindas` = alias de onboarding | Unifica funil legado login-first com marketplace guest-first |

## 2026-11-16 — Polimento UX marketplace (PNG / catálogo curto)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Assets de produto na UI | PNG transparente em `assets/images/produtos/` (não webp/jpg opacos) | Evitar “caixa”/halo em hero lima, cards gelo e empty |
| WP500 | `protein.png` (não existe `wp500.png`) | Recorte compartilhado com fundo transparente |
| FF500 | `flow_fiber-fast.png` (não existe `ff500.png`) | Idem |
| Demais SKUs seed | `ams500.png`, `amc510.png`, `amn1500.png`, `amn5000.png`, `amc200.png`, `gua2000.png` | 1:1 com código |
| Logo | `brand/logo.png` transparente; `LogoMarca` sem ColorFilter | Fundo preto do asset removido (alpha); JPG legado fora da UI |
| Teste entry | `rotaInicial: AppRoutes.onboarding` ou `boasVindas` (alias) | Só `exibirSplash: false` abre o **shell**; alias garante deep link legado |
| Cena impacto | Camadas `impacto-*.webp` mantidas; garrafa do SKU na PDP usa PNG do produto | Composição ≠ foto de produto |
| `kLimiteCatalogoCurto` | `12` | Seed ~8 SKUs: esconder busca; chips Todos \| Águas \| Funcionais (+ Kits se houver) |
| Empty catálogo | Ícone + título + subtítulo + link “Atualizar” — **nunca** `BotaoPrincipal` filled | Densidade; retry ≠ conversão |
| WP ausente | CTA “Assinar WP” → aba Produtos (nunca PDP órfã) | Catálogo vazio / seed pendente |
| “Ver todas as águas” | Só se ≥1 produto `Categoria.aguas.inclui` | Evitar filtro vazio |
| Onboarding | ≤1 filled (“Assinar Water Protein”); águas/quiz = TextButton/contorno; Pular semi-opaco | Hierarquia de CTA |
| Seed produção | João roda `npx prisma db seed` em `apicristalins` até `GET …/produtos` ≠ `[]`; smoke em `cristalins.peladeiro.cloud` | Agente não executa Coolify/seed; detalhe operacional em `doc/prompts/.../HANDOFF.md` (gitignored) |

## 2026-11-16 — P0 card foto-âncora Home (`dux-1-p0-card-home`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Chrome do card (revoga P0.3 “card branco”) | `CardProduto` sem `Material` branco/borda/`AppSombras.cardGrade`; bloco de cor raio 28 **é** o card; nome/pack/preço soltos sobre `AppColors.fundo`, 12 px abaixo | Monólito P0.1 vence a skill e a decisão anterior |
| Fundos do bloco | Tokens novos `AppColors.blocoAgua` `#E8F3F8`, `blocoWaterProtein` `#E6F3D8`, `blocoFlowFiber` `#FBEFD9` via `fundoBlocoProduto(codigo)`; `corDoProduto` continua para chip/sacola/catálogo | P0.2; não remapear `corDoProduto` evita mexer em sacola/catálogo legado |
| Garrafa | Base alinhada a 12 px; altura útil × escala: 500/510 ml 75%, 1,5 L 90%, demais 85%; galão 85% alt / 90% larg. máx. (asset é retrato — fica limitado pela altura, não chega a 90% da largura) | P0.2; não distorcer o PNG |
| PNGs com margem transparente | Recortes rente ao alpha (+2 px), 600 px de altura (3× do bloco 200) em `assets/images/produtos/card/<sku>.png`, só para o card (`assetCardProduto`) | Originais tinham 20–30% de vazio e bases desalinhadas; hero/PDP mantêm os PNGs originais (composições próprias, goldens) |
| Sombra sob a garrafa | Elipse com `AppSombras.garrafaContato` (blur 12, α 0,12, `heroInk`) | P0.2; sombra de contato, não blur de fundo |
| “+” | Círculo `heroNavy` 40 px, alvo 48, canto inferior direito do **bloco**; haptic `lightImpact` + `AnimatedScale` 0,96 (zero com reduzir movimento) | P0.3 |
| Stepper após 1º toque | Mesmo `StepperQuantidade`, no canto do bloco sobre pílula branca 2 px (contraste dos botões gelo sobre o fundo soft) | P0.3 “manter stepper”; caber na altura do carrossel |
| Badge sacola Home | “Pop” 1,3 → 1 (`easeOutBack`, 250 ms) a cada mudança do contador; sem animação se reduzir movimento | P0.3 |
| Tipografia | `AppTypography.cardNome` 16/600, `cardDetalhe` 13/400, `cardPreco` 16/700; nome 1 linha `heroInk` | P0.4 |
| Linha 2 | `Produto.pack` = `{embalagemQtd} × {volume}`; unitário (galão) = só `5 L` | P0.4/P0.5, pack real do seed |
| Preço | Mantém âncora “A partir de **R$ x**/un.” (`precoBase`). **Sem** preço de pack `precoBase × embalagemQtd` | Simulação aplica fatores (inclusive `DEMANDA`, que pode ser +); total do pack não seria honesto como “a partir de” |
| Nomes curtos | `nomeCardProduto`: AMS500/AMN1500 “Sem gás”, AMC510 “Com gás”, AMN5000 “Galão”, WP “Water Protein”, FF “Flow Fiber”; demais = nome API | P0.5 |
| Semantics | Card = botão “{nome API}, {pack}, a partir de R$ x por unidade”; “+” = “Adicionar {nome API}, {pack}, à assinatura…”; stepper usa nome API | P0.5; desambigua os dois “Sem gás” |
| Sacola (lista) | Linha 2 do item passa a `Produto.pack` (era “N por embalagem”) | Nome curto repetido “Sem gás” precisa do pack para distinguir 500 ml × 1,5 L. Ajuste mínimo; resto da sacola fica para P3 |
| Carrossel | Largura do card = `(larguraTela − 16 − 2×12) / 2,3` limitada a 140–176 (≈152 em 390 dp, ≈162 em 412 dp); bloco mantém proporção 164:200; altura do carrossel considera `TextScaler` | P0.6 ~2,3 cards; alvo 164 só cabe 2,3 em telas ≥ 412 dp |
| Indicador | Máx. 4 “páginas” (pílula navy 18×6 ativa; pontos `textoSuave` 6×6 inativos, ≥ 4,5:1 sobre `#F6F9FB`); `ExcludeSemantics` (decorativo) | P0.6 — não um dot por SKU; ativo diferenciado por forma, não só cor |
| Grade Produtos | Usa o mesmo `CardProduto` (já herda o visual); ajuste de grid/gap fica na P1 | Escopo P0 |

## 2026-11-17 — P1 Home + grade Produtos + shell (`dux-2-p1-home-produtos`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Header Home | `Stack`: “Olá!” à esquerda, `LogoMarca` (44) no **eixo da tela**, `BotaoSacolaBadge` à direita | P1.1 logo centralizada |
| “Olá” personalizado | **Gate**: app só guarda tokens (sem nome do cliente); mantém “Olá!” até existir dado de perfil (ex.: `GET /clientes/me`) | Não inventar endpoint nem decodificar JWT por nome |
| Chip CEP | Texto sem “Alterar CEP”; ação só no trailing “Alterar”; full-width (`Expanded`); alvo 48 dp; Semantics único “… Alterar CEP” | P1.1 sem duplicata |
| Botão sacola | Extraído para `core/widgets/botao_sacola_badge.dart` (Home + Produtos), `excludeSemantics` (rótulo com contador) | P1.4 header Produtos com sacola + contador |
| Hero tipografia | `AppTypography.title1` (28) mobile / `largeTitle` (34) largo; linha `subheadline`/`body`; preço `title1`; apoio/chips `footnote` | P1.2: escala do DS (fim de 44/30/26/12,5 avulsos) |
| “Mais vendido” | **Removido** (sem dado/footnote que sustente) | P1.2 + skill: claim sem fonte não entra |
| Claims hero | “5 g de proteína” + “Com colágeno” (lote PDP). “0 açúcar” **removido** até rótulo confirmar “Zero açúcar” | Gate de rótulo do CONTEXTO |
| Hint frete grátis | Abaixo do hero: “Frete grátis acima de R$ 50,00 por entrega” — limite = `simulacao.freteGratisAcima` ou `kFreteGratisAcimaPadrao` (RN18, = `FRETE_GRATIS_ACIMA` da API) | P1.2 above-the-fold; regra RN18 da spec, não frete inventado |
| Como funciona | Lista numerada vertical (círculo `heroNavy` 32 + título `headline` + apoio `subheadline`), sobre `AppColors.fundo` (faixa branca removida); copy “Flow Fiber” | P1.3 |
| Rodapé “Da fonte ao Rio — água mineral natural” | **Removido** da seção | Seção cobre WP/FF; não misturar denominação “água mineral” com WP |
| Chip “Funcionais” | Rótulo “Proteína e fibras” em `Categoria.funcionais` **e** `FiltroHomeCarrossel.funcionais` | P1.4; mesmo termo nas duas telas |
| Ordem WP × FF | App: `ordenarGradeProdutos` (WP500, FF500, resto na ordem da API). API não alterada | P1.4; menor escopo, sem mexer em testes da API |
| Grade Produtos | Mesmo `CardProduto` P0; `gradeProdutosPara`: gap 16, `mainAxisExtent = CardProduto.alturaPara(bloco 164:200)`; fonte ≥ 160% → 1 coluna (bloco máx. 260) | P1.4 + 200% |
| Fade dos chips | Removido (`LinearGradient`); corte do último chip indica rolagem | P1.4 |
| Shell | `NavigationBar.indicatorColor = AppColors.indicadorAba` `#E3EEF3` | P1.4 |
| `BarraSacola` frete | 2ª linha “Faltam R$ X para frete grátis” com `simulacao.faltaParaFreteGratis` (some se 0 ou se abaixo do mínimo, onde a barra já mostra o progresso do mínimo) | P1.4; valor 100% da API |
| P1.5 Fora da área (Home) | Folha CEP já mostra a mensagem da API (`CEP_FORA_AREA` / `BAIRRO_NAO_ATENDIDO`); bloqueio no “+” **não** implementado — sem CEP de domínio no guest, vale no checkout (endereço + lista de espera) | Não inventar store/regra |
| P1.5 Esgotado / Avise-me | **Gate** — sem flag de estoque na API | CONTEXTO |

## 2026-11-17 — P2 PDP Water Protein (`dux-3-p2-pdp`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Hero | `SliverAppBar` 40% da altura; `CenaImpactoAgua(fullBleed: true)` sem `AspectRatio`/raio (sem faixas laterais nem crop no topo). Modo antigo segue default para outros usos | P2.1 |
| Repetir animação | “Ver de novo” → “Repetir animação”, a 16 px das bordas, alvo 48 dp; some com reduzir movimento | P2.1 |
| Voltar | `_BotaoVoltar`: círculo branco 40 + sombra `cardGrade`, alvo 48, Semantics “Voltar” | P2.1 (some sobre céu claro) |
| Alt da foto | WP “Garrafa de Water Protein Cristalins 500 ml”; FF análogo; águas “{nome}. Garrafa toca a água com um respingo.” (`PdpCopy.altFoto`) | P2.1 |
| Título | `PdpCopy.titulo`: WP/FF = nome curto (“Water Protein”); águas = nome API. Inter `title1` peso 600, 28, `heroInk`. Rótulo `rotuloTipo` acima do título **removido** (duplicava) | P2.2/P2.3; DM Serif fora da PDP |
| Linha de embalagem | “Garrafa de 500 ml · caixa com 6”; galão “Galão de 5 L”; outros unitários “Unidade de {vol}” | P2.3 (unifica “caixa”) |
| Stepper | `PdpCopy.quantidade`: 3 → “½ caixa · 3 garrafas”; 6 → “1 caixa · 6 garrafas”; 9 → “1 caixa e meia · 9 garrafas”. **Passo continua 3** (`SacolaController.passo`) | P2.3 + RN intocável |
| “−” / “+” | `_BotaoQtd` 48 dp, Semantics “Diminuir/Aumentar quantidade”, 40% de opacidade e desabilitado no mínimo (1 passo) e no teto | P2.2/P2.4 |
| Teto | `PdpCopy.tetoPadrao = 120` unidades (= `Simulacao.ueMaxima` padrão), arredondado ao passo; a API revalida | P2.2 “teto no +”, sem regra nova |
| Quantidade ao leitor | `Semantics(container, liveRegion)` “Quantidade: {rótulo}” | P2.4 live qty |
| Preço sob o título | Unitário (`precoUnitario` da simulação se o SKU estiver nela, senão `precoBase`) “/garrafa” + “caixa com 6 ≈ R$ X” | P2.4. “≈” deixa claro que é referência (descontos/`DEMANDA` só na simulação) |
| CTA | `BotaoPrincipal` nova variante `cta` (`heroNavy`, raio 14 = `AppSpacing.raioCta`) em rodapé branco com borda superior 1 px. Rótulo “Adicionar · R$ X por entrega” / “Atualizar quantidade · R$ X por entrega” com X = unitário × qty **local**; nota “Valor deste item; descontos e entrega são calculados na sacola.” | P2.2. Total da assinatura continua só via `/precos/simular` |
| `BotaoPrincipal` altura | Fixa 50 → **mínima** 50 (`ConstrainedBox` + `Center(heightFactor: 1)`); goldens inalterados | P2.4 fonte 200% sem cortar o CTA |
| Chips | WP “5 g de proteína” + “Com colágeno”; FF “5 g de fibras prebióticas”; águas minerais “Água mineral natural”; guaraná sem chip (antes herdava “Água mineral natural” por engano). “Zero açúcar/gordura/sódio” **fora** até rótulo | P2.3 + gate de rótulo |
| Descrição | Mantida a da API (`descricao`) — já honesta (“Cristalins com colágeno em garrafa de 500 ml.”); copy sugerida do rascunho trazia “Sem gás” não verificado | Não inventar claim |
| Mistura WP+FF | Texto “Você pode montar a caixa de 6 com Water Protein e Flow Fiber — por isso a quantidade anda de 3 em 3.” **Sem** botão “Montar caixa” (não há ação dedicada) | P2.3: CTA só se a ação existir |
| Tabela nutricional | **Gate**: sem asset/API → “Tabela nutricional, ingredientes e alergênicos: consulte o rótulo da embalagem.” (WP/FF). Nada de tabela inventada | P2.3 + “não inventar tabela fake” |
| Frequência / frete | Linha “Frequência e plano você escolhe na sacola. Frete grátis acima de R$ 50,00 por entrega.” (RN18 via simulação ou `kFreteGratisAcimaPadrao`) | P2.4 “no próximo passo” |
| Snackbar | “Adicionado à sacola” / “Quantidade atualizada” + ação “Ver sacola” | Nomenclatura alinhada ao card |

## 2026-11-17 — P3 Sacola erro acionável + resumo (`dux-4-p3-sacola`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Resumo com `erroSimulacao` / `sim == null` | `_ResumoEstimado`: subtotal **≈** `precoBase × qty` por linha; total “—”; marca “Estimativa pelo preço base”. Preços de linha no card também com “≈” | P3.1: não sumir com preços; **não** inventar frete/desconto/total da assinatura (só simulação) |
| Limpar `simulacao` no erro | Mantém `simulacao = null` no catch (como antes); UI troca para estimativa — não reutiliza última sim (evita total mentiroso após mudar a cesta) | Honestidade > cache |
| Erro no card | `faltaParaCompletarCaixa` (UI) + `SacolaCopy.faltaCaixa`; um card WP/FF com erro se caixa mista; CTA “Completar caixa (+N)” → `completarCaixa` no **mesmo** SKU | P3.1 acionável; passo continua 3 |
| Copy sem citar FF ausente | `mista` só se WP **e** FF na sacola; API `mensagemCaixaMista` idem (só o presente / ou os dois) | P3.1 + RN04 inalterada |
| Continuar bloqueado | Motivo live region (`motivoCaixaIncompleta` / mínimo / erro API) **acima** do botão; `BotaoPrincipal` `cta` desabilitado com `linha` + `heroInk` (legível) | P3.1 contraste; sem CTA “ativo que só explica” |
| AppBar | “Sacola” + subtítulo “N produto(s)” | P3.2 |
| Frete | `_BarraFreteGratis` texto + barra até `freteGratisAcima` (RN18 da sim) | P3.2 |
| Planos | Chips pill; `SacolaCopy.descricaoPlano` Flex/Trimestral; economia R$ da sim se > 0 | P3.2 |
| CTA | `Continuar · {total.formatado} por entrega` com `VarianteBotaoPrincipal.cta` | P3.2 + HANDOFF P2 |
| Selos | Pix + “Pause quando quiser”; **sem** “Dados protegidos” | P3.2 |
| Undo | SnackBar 4 s + “Desfazer” ao remover (ícone ou swipe) | P3.3 |
| Datas 1ª entrega / cobrança | Copy `proximoPasso` (sem inventar data) | P3.3 |
| LGPD | Links Termos/Privacidade só se `AppConfig` URL não vazia | P3.3 |
| Passo WP/FF | **Intocado** (`embalagemQtd ~/ 2` → 3) | CONFLITO_RN |

## 2026-11-17 — P4 Onboarding / boas-vindas (`dux-5-p4-onboarding`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Hero | Bokeh limpa (`agua-bokeh-limpa.png`) + garrafa WP (`protein.png`) + degradê navy; fallback `heroNavy` se a foto falhar; `filterQuality.high` | P4.1; asset sem tipografia embutida |
| Logo | `LogoMarca(largura: 120, sobreFundoEscuro: true)` — tint branco só no painel escuro; header claro continua sem ColorFilter | P4.1 ~120 px; DECISOES marketplace intacta no header |
| Hierarquia | 1 CTA `cta` (“Montar minha assinatura”) + 1 secundário (“Ver todos os produtos”); “Já sou assinante? Entrar” no topo (pílula `azul900`) | Skill 1+1; P4.2 Pular→Entrar |
| Kit / site | Removidos do onboarding (“Descobrir meu kit”, “Conhecer o site”) | P4.2 + P6 quiz fora; site no Perfil |
| Título “5 g” | **Não** no título (gate rótulo) — “Water Protein no Rio” + subtítulo frequência/RJ/frete RN18 | CONTEXTO gate |
| Preço | “A partir de {precoBase.formatado}/garrafa” só se WP no catálogo | Âncora API; sem inventar |
| CTA destino | WP na PDP se `WP500` no catálogo; senão aba Produtos | Mesmo fluxo útil do CTA antigo, copy nova |
| Splash | Token de acesso presente → shell (pula onboarding); senão `OnboardingPrefs.visto` | P4.3 sessão válida |
| Painel | Mantém `azul900` (código ≥ print HML antigo) | Validar no device; não reintroduzir tipografia no PNG |

## 2026-11-17 — Revisão uma volta (`dux-7-revisao`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| P6 agora? | **Não** — CardKit, goldens 200%, assinante×avulso ficam GATE | João não pediu; monólito marca P6 opcional |
| Quiz entry | Mantém fora do onboarding; `EmptyAssinatura` “Descobrir meu kit” se `onQuiz` | P6 parcial já útil |
| a11y auth (`a11y_semantica_test`) | **Não** reescrever cadastro nesta volta | Fora do núcleo marketplace P0–P5; consolidação/backlog |
| Regressão sugestão mínimo | Testes alinhados a nome curto (“Adicionar Sem gás”) + Semantics API | P5.2; uma correção |
| ~~`heroTitle` DM Serif sem callers~~ | ~~Deixar; limpeza de fonte na consolidação se João quiser~~ — **feito na P6** (ver seção abaixo) | ~~Sem regressão visual urgente~~ |

## 2026-11-17 — P6 + gates implementáveis (`p6-gates`, pedido João)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| CardKit âncora de preço | `≈ {Kit.subtotalBase}/entrega` + nota “Preço base, antes dos descontos” (`CardKit.precoBase`); sem preço → card sem âncora | `subtotalBase` = Σ `precoBase` × qty (API `kits.service`). **Não** “A partir de” no total do kit: a simulação aplica `DEMANDA` até **+8%**, então o total real pode passar do valor base (mesma lógica da P0 que vetou “a partir de” no pack). “≈” segue P2.4/P3.1 |
| CardKit a11y | Semântica única: “{nome}, {resumo}, cerca de R$ x por entrega, preço base antes dos descontos”; “+” com rótulo próprio; altura/largura por `TextScaler` (`alturaPara`/`larguraPara`, largura até 1,6×) | Lista de kits era fixa em 176 dp e já estourava a 100% (conteúdo ≈ 178–216 dp) |
| CardKit visual (skill) | Sem sombra (borda `linha` 1 px); preço `cardPreco` com algarismos tabulares; resumo 1 linha | HIG: separação por borda/fundo; número que muda não “pula” |
| Resumo do kit | `resumoDoKit`: `12× Water Protein`, `6× Water Protein + 2× Galão` (`nomeCurtoPorCodigo`) | Antes mostrava códigos crus (`WP500, AMN5000`); P5.2 nomes curtos |
| Goldens 200% | `test/goldens/p6_fonte_200_test.dart`: Home, Produtos (grade 1 coluna), Produtos › Kits, Sacola em 390 × 844 com `TextScaler.linear(2)`; falham também em overflow | P6; viewport real = o que o usuário vê sem rolar |
| Sacola a 200% (bugs achados pelo golden) | Linha do item: preço **abaixo** do nome com fonte ≥ `kEscalaFonteUmaColuna` (1,6); selos “Pagamento com Pix / Pause…” com texto `Flexible`; indicador Sacola › Entrega › Pagamento com fonte limitada a **130%** (`withClampedTextScaling`) | 4 overflows (72–170 px). O indicador já tem rótulo semântico completo; 3 rótulos lado a lado não cabem em 358 dp a 200% |
| Goldens antigos regravados | `mk_card_kit` (novo visual), `mk_barra_sacola` e `mk_sugestao_minimo` (estavam desatualizados desde P0.5/P5.2: copy “Adicionar {curto} ({pack})”) | Diferença só de texto; widgets não mudaram nesta fase |
| Assinante × avulso nos cards | **Continua gate API** — `Produto` (Prisma e app) só tem `precoBase`/`precoPiso`; não há preço avulso nem canal avulso | Não inventar |
| `heroTitle` / DM Serif | **Removidos**: `AppTypography.heroTitle`, `familiaSerif`, família `DMSerifDisplay` do `pubspec`, `DMSerifDisplay-Regular.ttf` e `OFL-DMSerifDisplay.txt` | Zero callers; uma família só (Inter), skill §4 |
| Quiz entry | Confirmado **fora** do onboarding (onboarding → `CadastroLoginActivity`; quiz via aba Assinatura vazia, Minha assinatura e pós-cadastro). Guarda: `boas_vindas_screen_test` (“Descobrir meu kit” ausente) | A linha “Onboarding → Activity: Descobrir meu kit → `QuizActivity`” da seção AP2 abaixo está **desatualizada** (P4 removeu o CTA) |
| Continuam gate | Tabela nutricional / “Zero…” / ANVISA / watermark; estoque / “Avise-me” / waitlist; “Olá, {nome}” sem `GET /clientes/me`; passo WP/FF = **3** | Sem dado/backend ou decisão humana — **parcialmente revogado** em “Gates demo AP2” abaixo |

## 2026-11-17 — Gates demo AP2 (`gates_demo_coolify`, pedido João)

API e banco são nossos, então os gates de dado viraram **mapas demo na API** (mesmo padrão de `produto-descricoes.ts`). Revoga, só para a demo AP2, as linhas de gate “assinante×avulso”, “Olá, {nome}”, “estoque / Avise-me / waitlist”, “tabela nutricional” e “Zero açúcar/gordura” das seções P2, P5 e P6 acima.

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| `precoAvulso` | Mapa `PRECOS_AVULSO` em `api/src/produtos/produto-descricoes.ts` (string → `dec()`), **sem coluna Prisma**. WP 11,90 · FF 10,90 · AMS 2,60 · AMC510 3,40 · AMN1500 4,50 · AMN5000 11,90 · GUA 9,50; AMC200 (B2B copo) = `null` (sem canal avulso) | Sem migração nem deploy de schema; valores de **exemplo** até a Cristalins confirmar o preço de balcão. App só exibe |
| Card assinante × avulso | Linha do pack vira “{pack} · Avulso ~~R$ x~~” (riscado, `FittedBox`); “A partir de {precoBase}/un.” continua a âncora da assinatura | App não calcula nada: os dois valores vêm de `GET /produtos`; sem % de economia no client |
| PDP avulso | “Avulso: R$ x /garrafa” sob o preço (`PdpCopy.avulso`) | Mesmo dado da API |
| `estoque` | Coluna Prisma já existia; agora sai em `/produtos` (`null` = sem controle). Seed: GUA2000 = **0** (esgotado demo), demais com folga (400–4800) para a separação RN06 não pular itens na apresentação. Mesmo valor em `scripts/sql/seed_gates_demo_produtos.sql` | Seed upsert idempotente; SQL só `UPDATE` por `codigo` |
| Esgotado no card | Selo “Esgotado” no bloco; “+” vira pílula “Avise-me” (48 dp). Se o item **já está** na sacola, o stepper fica (para poder remover) | Não bloquear quem já tinha o item; RN06 cuida da entrega |
| Esgotado na PDP | “Esgotado no momento” (`alerta`); some o stepper; CTA “Avise-me quando voltar” | Uma ação principal (skill) |
| Avise-me → `POST /lista-espera` | Folha `FolhaListaEspera` (`core/widgets/folha_lista_espera.dart`): e-mail (pré-preenchido via `/clientes/me` se logado) + CEP (pré-preenchido com `CepDaSessao`, CEP confirmado na folha da home/perfil). Sem CEP → pede | A tabela `lista_espera` não tem coluna de produto: o Avise-me registra contato + CEP, **não** o SKU. Gravar o SKU = migração futura |
| Waitlist fora da área | Folhas de CEP da **Home** e do **Perfil**: em `CEP_FORA_AREA` / `BAIRRO_NAO_ATENDIDO` aparece “Entrar na lista de espera” → mesma folha só com e-mail (CEP já conhecido). Tela de endereço já tinha (CT23) | Mesmo endpoint e mesma voz |
| “Olá, {nome}” | `AuthRepository.perfil()` → `GET /clientes/me`, cache em memória limpo em entrar/cadastrar/sair/excluir. Home: “Olá, {primeiro nome}!”; sem sessão/erro → “Olá!”. Perfil logado mostra nome + e-mail | Endpoint já existia; app só não chamava |
| Saudação longa | Até meia largura do header; acima disso encolhe (`FittedBox`) | “Olá!” a 200% cabe sem escala (golden P6 intacto) |
| `claims` | Mapa `CLAIMS_PRODUTO`: WP `5 g de proteína · Com colágeno · Zero açúcar · Zero gordura`; FF `5 g de fibras prebióticas`; demais `[]`. PDP usa `claims` quando vierem; sem eles cai nos chips P2 | Demo AP2. Nenhum claim de registro/benefício terapêutico (teste e2e barra “anvisa/registrad/cura/trata/previne”) |
| `tabelaNutricional` | Mapa `TABELAS_NUTRICIONAIS` (porção 500 ml): WP valor energético 20 kcal, carboidratos 0 g, açúcares 0 g, proteínas 5 g, gorduras 0 g; FF fibras 5 g. Só o que os claims sustentam (20 kcal = 5 g × 4 kcal). PDP mostra a tabela da API + “Ingredientes e alergênicos: consulte o rótulo. Em caso de diferença, vale o rótulo.” | Demo AP2 — **trocar pelos valores do rótulo oficial** antes de produção |
| Hero (home) | Continua **sem** “Zero açúcar” (texto fixo, `p1_home_test`) | Claims novos só via API, na PDP |
| ANVISA | **Não** alegar registro nem benefício | Continua gate humano |
| Watermark / licença de foto | **Não** inventar overlay | Continua gate humano |
| Coolify | Nada executado pelo agente (sem tool de SQL no MCP; escrita em banco de produção pede o João). Script pronto: `scripts/sql/seed_gates_demo_produtos.sql`. Os campos novos só aparecem em HML **depois do deploy do código da API** | Regra do repo: sem deploy/migração em produção pelo agente |

## 2026-11-17 — P5 Shell / a11y / conformidade UI (`dux-6-p5-shell-a11y`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Tab indicator | Mantém `AppColors.indicadorAba` `#E3EEF3` (já P1.4); **não** menta | P5.1 confirmado |
| Abas inativas | Labels/ícones `heroInk` `#0B2E3F` sobre `superficie` (antes `tinta`) | P5.1 contraste AA |
| Chips filtro | Inativos: texto `navy` + borda `azulPetroleo` α0,55; sem fade (P1) | P5.1; chip “Proteína e fibras” (não “Funcionais”) |
| Nomes curtos | `nomeCurtoPorCodigo` único; `nomeCardProduto` e `nomeDoProduto` delegam; listas (sacola/assinatura/recibo/quiz/catálogo legado) usam curto; PDP título águas = nome API | P5.2 |
| Claims | Só composição já em P1/P2 (proteína/colágeno/fibras); “Zero açúcar/gordura” e “5 g” em **título** continuam gate de rótulo | P5.3 |
| CDC | PDP: CTA com R$ da qty local + nota “descontos na sacola”; Sacola: “Total por entrega” + frequência/plano **antes** de Continuar | P5.4 (P2+P3); sem inventar total sem simulação |
| ANVISA formal | **Gate humano** — UI não alega registro/benefício terapêutico | P5.5 |
| Licença de foto | **Gate humano** — assets atuais ok para HML; troca comercial = João | P5.5 |
| Watermark em asset | **Gate humano** — não inventar overlay; se asset vier com marca d'água, substituir fora desta fila | P5.5 |
| Lista de espera (fora da área) | **Gate** — domínio CEP/API existe; UI waitlist só com backend/flag | P5.5; não bloquear P0–P4 |
| Tabela nutricional in-app | **Gate** — mantém “consulte o rótulo” (P2) até asset/API | P5.3/P5.5 |
| a11y legado auth | `a11y_semantica_test` Tela 2×3 (CupertinoTextField) **fora** do núcleo marketplace P5; cobertura nova em `p5_shell_a11y_test` | Escopo; revisão P6 pode tocar auth |

## 2026-11-17 — AP2 Activities + Intents explícitas (`ap2-2-activities`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Rubrica ≥5 Activities vs Flutter UI | Cascas `FlutterActivity` (Main launcher + 8 AP2); UI permanece Flutter | SPEC; não reescrever Kotlin puro |
| Estado entre Activities | `FlutterEngineCache` id `cristalins_engine`; `shouldDestroyEngineWithHost = false` | Evitar perder Provider / pedido |
| Intent explícita | MethodChannel `br.com.cristalins.assinatura/navegacao` / `abrirActivity` + whitelist de classes | Demonstrável na oral; component explícito |
| Ordem Dart | Navigator (rota + args) **depois** Intent nativa no mesmo `abrir` | Engine compartilhado ignora `getInitialRoute` nas Activities seguintes |
| Onboarding → Activity | CTA “Descobrir meu kit” → `QuizActivity` (não há CTA cadastro no onboarding atual) | UX real do marketplace; cadastro via sacola/checkout |
| Implícitas | Intactas (`AbridorLinks`, `Compartilhador`, `<queries>`) | Já atendem rubrica; fora do channel |
| Extras | Strings (`recomendacaoId`, `assinaturaId`); pedido via estado Dart | Mínimo viável SPEC §6 |
