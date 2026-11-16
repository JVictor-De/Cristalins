# Decisões

## 2026-11-14 — Fundação (`cr-0-repo`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Rubrica pede Activities e Intents nativos | Seguir Flutter: rotas nomeadas = passagem explícita; `url_launcher` / `share_plus` = Intents implícitas. Não reescrever em Kotlin. | Stack fechada no contexto; risco a confirmar com o professor |
| Como serializar dinheiro no JSON | Número com 2 casas (ex.: `118.80`, `219.09`) no contrato Swagger; cálculo interno com `decimal.js` / `Decimal(10,2)` | Exemplos do Anexo são o contrato |
| `applicationId` Android | `br.com.cristalins.assinatura`, `br.com.cristalins.assinatura.dev`, `br.com.cristalins.assinatura.hml` | Monólito não fixa; fila fecha assim |
| Número do WhatsApp de suporte | `--dart-define=SUPORTE_WHATSAPP=` vazio até configuração; não inventar número | Contato comercial da marca não é o WhatsApp do app |
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
| Tipografia hero | DM Serif Display Regular (OFL) embarcada; corpo Inter | Monólito §3.2 |
| `flow_protein.webp` | Redimensionado para largura 1200 (~64 KB no app) | Monólito pede ≤ ~1200 px / evitar ~1,8 MB |
| UX v3 (registrar) | Home bifurcada; cards sem preço; frequência só na sacola; mínimo com sugestão; login contextual | Monólito v3 missão / §2 |
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
| Termos URL | Links só se `URL_TERMOS`/`URL_PRIVACIDADE`; senão “(links em breve)” | Não inventar URL |
| Gates | OAuth/OTP/captcha/HIBP/analytics/IE/biometria | Documentados; não inventar |

## 2026-11-16 — Polimento UX pós-smoke P4 (`ux_polimento_pos_smoke`)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Título Perfil (aba shell) | `AppTypography.title3` (não `largeTitle`) | P4.1; alinha Sacola/shell |
| CTA guest | “Entrar ou criar conta” navy + “Com e-mail e senha” | P4.2; sem Google/Apple/telefone |
| Termos / privacidade | `URL_TERMOS` / `URL_PRIVACIDADE` dart-define; vazio = “Em breve” | Não inventar URL LGPD |
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
| Preço no hero | `a partir de {precoBase.formatado}/un.` só se WP no catálogo | Exceção documentada vs cards sem preço |
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
| Fundo miniatura | `corDoProduto(codigo).withValues(alpha: 0.22)` + card branco/`superficie` + borda | P0.3; acento por SKU sem preço |
| Banner “Da fonte ao Rio” | Só tipografia — remove mini-garrafa do bloco Como funciona | P0.5; evita órfã flutuante |
| Skeleton hero | `SkeletonCard` enquanto `carregandoCatalogo` no lugar do hero visitante | P0.8 |
| `CardKit` minis | `codigosItens` → até 4 `assetDoProduto`; remove `Spacer` void | P0.6 |
| Preço/% nos cards | **Gate** — não adicionar | Marketplace v3 |

## 2026-11-16 — Polimento UX marketplace (PNG / catálogo curto)

| Dúvida | Decisão | Motivo |
| --- | --- | --- |
| Assets de produto na UI | PNG transparente em `assets/images/produtos/` (não webp/jpg opacos) | Evitar “caixa”/halo em hero lima, cards gelo e empty |
| WP500 | `protein.png` (não existe `wp500.png`) | Recorte compartilhado com fundo transparente |
| FF500 | `flow_fiber-fast.png` (não existe `ff500.png`) | Idem |
| Demais SKUs seed | `ams500.png`, `amc510.png`, `amn1500.png`, `amn5000.png`, `amc200.png`, `gua2000.png` | 1:1 com código |
| Logo | `brand/logo.png` transparente; `LogoMarca` sem ColorFilter | Fundo preto do asset removido (alpha); JPG legado fora da UI |
| Teste Tela 1 | `CristalinsApp(rotaInicial: AppRoutes.boasVindas, exibirSplash: false)` | Só `exibirSplash: false` abre o **shell** (marketplace); `pumpAndSettle` na home quebrava o teste de boas-vindas |
| Cena impacto | Camadas `impacto-*.webp` mantidas; garrafa do SKU na PDP usa PNG do produto | Composição ≠ foto de produto |
| `kLimiteCatalogoCurto` | `12` | Seed ~8 SKUs: esconder busca; chips Todos \| Águas \| Funcionais (+ Kits se houver) |
| Empty catálogo | Ícone + título + subtítulo + link “Atualizar” — **nunca** `BotaoPrincipal` filled | Densidade; retry ≠ conversão |
| WP ausente | CTA “Assinar WP” → aba Produtos (nunca PDP órfã) | Catálogo vazio / seed pendente |
| “Ver todas as águas” | Só se ≥1 produto `Categoria.aguas.inclui` | Evitar filtro vazio |
| Onboarding | ≤1 filled (“Assinar Water Protein”); águas/quiz = TextButton/contorno; Pular semi-opaco | Hierarquia de CTA |
| Seed produção | João roda `npx prisma db seed` em `apicristalins` até `GET …/produtos` ≠ `[]`; smoke em `cristalins.peladeiro.cloud` | Agente não executa Coolify/seed; detalhe operacional em `doc/prompts/.../HANDOFF.md` (gitignored) |
