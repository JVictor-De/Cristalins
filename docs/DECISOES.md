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
