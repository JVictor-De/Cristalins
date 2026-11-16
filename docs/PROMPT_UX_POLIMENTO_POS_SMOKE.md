# Prompt — polimento design marketplace (pós-smoke + home + sacola + perfil + auth) — Cristalins set/2026

## Papel

Agente de implementação no monorepo Cristalins. Aplicar **todos** os itens **P0–P5** abaixo no app Flutter (`app/`), com testes e notas de decisão. **Não** redesenhar a loja do zero. **Sem** preço / “economize X%” nos **cards do catálogo** (gate). Exceção controlada: **hero** pode mostrar “a partir de …” com `precoBase` do WP500 da API — documentar em DECISOES. Na **sacola**, preço vem **só** de `POST /precos/simular`. Sem Coolify, deploy, seed em produção, push, commit ou leitura de `.env`/secrets — salvo o João pedir explicitamente depois.

Ambiente: máquina local, raiz do repo. Runtime: Cursor Agent. Antes de explorar: se existir `graphify-out/graph.json`, `graphify query "CardProduto CardKit HeroWaterProtein HomeScreen BarraSacola CardProximaEntrega SacolaScreen SacolaController PerfilScreen CadastroLoginScreen"`. Ao terminar: `graphify update .`.

Listas: `docs/UX_POLIMENTO_POS_SMOKE.md` + este monólito.

## Contexto (não inventar)

- Marketplace v3: shell, hero WP, cards **sem preço**, empty honesto, PNG, `kLimiteCatalogoCurto`, impacto PDP.
- Já existem: `BarraSacola` acima da tab bar; `CardProximaEntrega` para assinante; skeletons no carrossel; empty/erro catálogo; `AppConfig.suporteWhatsapp` (vazio = **não** inventar número); persistência da sacola.
- `Assinar` hoje abre PDP WP ou aba Produtos se WP ausente — P1.2 passa a **adicionar WP à sacola** (passo) e ir à `AppRoutes.sacola` (ou shell+rota), sem PDP órfã.
- Galão `AMN5000` está no seed; se some do carrossel Home, é ordenação/`take(8)` — incluir e não começar por WP.
- Perfil guest hoje: título grande à esquerda, CTA “Entrar”, botão morto “Explorar sem entrar”, `ListTile` “Site Cristalins” recuado, WhatsApp só se config; **sem** FAQ/CEP/LGPD/versão.
- Cadastro/login (`CadastroLoginScreen` + `CadastroLoginController` + `Validadores`): Cupertino rows, título grande “Criar conta” + abas + botão repetidos; “Explorar sem entrar” no meio; CPF rótulo ≠ placeholder; celular opcional na API; `marketingOk` já no DTO mas **sem** checkbox UI; nascimento = texto sem roda; sem máscaras/força de senha/opt-in separado.
- Auth real hoje = e-mail + senha. `POST /clientes` **exige** `cpfCnpj` + `dataNascimento` (+ `aceiteTermos`). Reduzir atrito (só nome/contato/senha) **exige** mudança de API + coleta no checkout — ver P5.2 / gate.
- OAuth Google/Apple, OTP SMS/WhatsApp, captcha, HIBP, analytics de abandono = **gate** até existir integração real.
- Exclusão: `DELETE /clientes/me` (RF05). Termos/privacidade: URLs **pendentes** (`LANCAMENTO.md`) — não inventar domínio.
- Tokens: `AppColors`, `AppSpacing`, `AppTypography`, `AppSombras`, `BotaoPrincipal`, `corDoProduto`, `assetDoProduto`, `LogoMarca`.

### Arquivos-alvo

- Tema + `card_produto`, `card_kit`, `hero_water_protein`, `logo_marca`, `barra_sacola`, `card_proxima_entrega`, `skeleton_card`, `home_screen`, `produtos_screen`
- Sacola: `sacola_screen`, `sacola_controller`, `detalhe_preco_expansivel`, `sugestao_minimo_cesta`
- Perfil: `perfil_screen.dart` (guest + planejar logado)
- Auth: `cadastro_login_screen.dart`, `cadastro_login_controller.dart`, `validadores.dart`, `esqueci_senha_screen.dart`; opcional `api/src/clientes/dto/criar-cliente.dto.ts` + checkout se P5.2
- `app_config.dart` (WhatsApp / site / URLs legais se existirem); assets FF PNG
- `docs/DECISOES.md`, `docs/UX_POLIMENTO_POS_SMOKE.md`
- Testes/goldens catalog + home/sacola/perfil/auth tocados

---

## P0 — Bugs visuais / cards / kits

**P0.1** FF PNG sem xadrez.  
**P0.2** `CardProduto`: clip + “+” dentro do card.  
**P0.3** Miniaturas escala fixa + fundo `corDoProduto` suave.  
**P0.4** `nomeCardProduto` curto (WP/FF).  
**P0.5** Banner “Da fonte ao Rio” sem mini-garrafa órfã.  
**P0.6** `CardKit` com minis PNG; layout sem void.

**P0.7 Card → quantidade**  
Após 1º toque no “+”, trocar por seletor/stepper de quantidade no card (reutilizar `StepperQuantidade` / passo).  
Feedback: SnackBar ou animação curta “Adicionado à sacola” + haptic.

**P0.8 a11y imagens**  
Toda `Image.asset` de produto com `semanticLabel` (= nome curto). Skeletons já no carrossel — estender ao **hero** (placeholder) se carregando catálogo.

---

## P1 — Fundo, hero, header, localização, tipografia

**P1.1 Fundo** `#F6F9FB`; cards brancos + sombra + borda 1px; degradê só topo; “Como funciona” faixa branca; verde só hero WP.

**P1.2 Hero (`HeroWaterProtein`)**  
- Badge: **“Mais vendido”** (não “Carro-chefe”).  
- Menos altura; sem Spacer morto.  
- Chips: “5 g de proteína por garrafa”, “0 açúcar”, “0 gordura” (explicar o 5 g).  
- Título Inter (não DM Serif no hero).  
- Garrafa maior + sombra sangrando.  
- Preço de entrada: “a partir de {precoBase.formatado}/un.” **somente** se `produtoDe('WP500')` existir — usar `precoBase` do catálogo; documentar exceção vs cards sem preço.  
- “Ver todas as águas”: alinhar à **esquerda** sob o CTA **ou** remover se redundante com “Ver todos” da seção (escolher uma; DECISOES).  
- CTA “Assinar Water Protein”: `adicionarPasso(WP)` + navegar para **sacola** (não PDP); se WP ausente → aba Produtos (nunca PDP órfã — DECISOES).

**P1.3 Header**  
- “Olá!” menor (`title2`/`title3`); logo ~48–56 dominante.  
- Escala tipográfica: títulos de seção (`title3`) > nomes de card (`headline`); não competir.  
- Margens laterais = `AppSpacing.margem`; ritmo vertical entre seções = `AppSpacing.secao`.  
- “Ver todos” alinhado à **baseline** do título “Produtos” (`SecaoComTitulo` / `CrossAxisAlignment.baseline` ou Row height Intrinsic).  
- Tab bar: mais contraste em labels inativas.

**P1.4 Localização (pílula)**  
- Visual clicável: seta / “Alterar” + `InkWell`.  
- Ao tocar: fluxo CEP (bottom sheet ou rota leve) para **confirmar área** antes da compra — **só** se já existir endpoint CEP/zona no app (`/cep/{cep}` / `Enderecos`); senão sheet “Informe o CEP no checkout” + deep-link para endereço **sem** inventar API.  
- Persistência do CEP informado se o domínio já tiver onde guardar.

**P1.5 Acesso à sacola na Home**  
- Ícone sacola no header com **badge** contador (soma qty ou linhas — documentar).  
- Polir `BarraSacola` (também afeta Perfil/shell):  
  - “Ver sacola” = **botão preenchido** (`BotaoPrincipal` / navy) com área de toque ≥ 44.  
  - Copy: “**N itens · {total} por entrega**” com o valor em destaque; se `simulacao` null → “N itens”.  
  - Total = **mesmo** arredondamento/`formatado` da Sacola (hoje barra pode divergir 72,86 vs 72,88 — uma fonte: `sim.total`).

---

## P2 — Conteúdo Home + carrossel + assinante + suporte

**P2.1** Como funciona → 3 cards com ícones.  
**P2.2** Copy: “semanal, quinzenal ou mensal”.  
**P2.3** Banner marca (fonte/serra se asset).  
**P2.4** Selos honestos (sem inventar NPS).

**P2.5 Carrossel Produtos**  
- Incluir **galão** (`AMN5000`) na lista Home.  
- Ordenação: **não** começar por WP (já no hero) — ex. águas/FF/galão primeiro; WP no fim ou omitir do carrossel se `take` apertado (DECISOES).  
- Filtros rápidos no carrossel/home (chips locais, não precisam ser `Categoria` enum completo): Sem gás, Com gás, Funcionais, Galão — filtrar por `codigo`/`tipo`/`nome` reais do seed; **Kits** continua na aba Produtos.  
- Indicador de scroll (dots ou scrollbar) no carrossel horizontal.

**P2.6 Assinante**  
- Já há `CardProximaEntrega` — garantir topo: “Próxima entrega: …” com `Datas.comDiaDaSemana` se existir.  
- Atalhos: “Pular entrega” / “Editar assinatura” → rotas/callbacks **já existentes** em assinatura; se ação não existir na API, só navegar para aba Assinatura (não inventar endpoint).

**P2.7 Visitante — oferta 1º pedido**  
- **Gate** se exigir desconto inventado. Permitido: faixa tipográfica “Na primeira assinatura você escolhe frequência e paga com Pix” **sem** %/R$ inventado; ou omitir.

**P2.8 Rodapé / suporte**  
- Atalho WhatsApp **somente** se `AppConfig.suporteWhatsapp` não vazio (padrão perfil/assinatura).  
- FAQ curta estática (área RJ, pausa, cancelamento) — copy honesta alinhada aos docs; sem inventar política.

**P2.9 Estados Home**  
- Skeleton hero + cards (estender o que já existe).  
- Falha catálogo: manter/`EstadoErro` + “Tentar de novo” (já parcialmente no carrossel).

---

## P3 — Sacola

(inalterado em espírito — ver versão anterior; resumido)

**P3.1** Dados: não hardcodar preço galão; centavos API; un.×embalagem; Continuar **navy**; AppBar = fundo.  
**P3.2** Layout: sem void; barra inferior sombra; card “Configuração da assinatura”.  
**P3.3** Itens: subtotal linha; lixeira no mínimo; minis maiores; nome curto.  
**P3.4** Freq/plano: sem subtítulo repetido; contraste chips; Flex/Trimestral só com API.  
**P3.5** Preço aberto; frete atual + barra frete grátis; sugestão sem inventar; ≈/mês documentado.  
**P3.6** Steps Sacola→Entrega→Pagamento; título N itens; “Adicionar mais produtos”; Pix; CEP/cupom se API.  
**P3.7–P3.11** Confiança, total animado, swipe, loading, empty polido, a11y.  
**P3.12** Alinhar total exibido na Sacola com `BarraSacola` (mesma formatação/`Decimal` da simulação — ver P1.5).

---

## P4 — Perfil (guest / não logado)

Arquivo: `app/lib/features/profile/presentation/perfil_screen.dart`. Escopo principal = **ninguém logado**; estado logado = **planejar + stubs só com rotas/API existentes**.

**P4.1 Problemas atuais (guest)**  
- Remover **“Explorar sem entrar”** (no-op na aba Perfil).  
- Preencher o vazio abaixo do CTA (lista/blocos — não deixar tela oca).  
- “Site Cristalins”: item de lista com ícone, seta de link externo (`Icons.open_in_new` / chevron), **mesma margem** dos outros botões/itens (hoje recuado).  
- “Entrar”: mesmo **azul-marinho** dos CTAs principais (`BotaoPrincipal` / `AppColors.navy` ou azul marca já usado nos CTAs).  
- Cabeçalho padronizado com Sacola: título consistente (centralizado + back **só** em rotas push; na aba shell, título alinhado ao padrão do shell — documentar em DECISOES; evitar `largeTitle` competindo com hero).

**P4.2 Entrada na conta**  
- Ilustração ou ícone + frase de benefício (ex.: “Acompanhe entregas, pause e edite sua assinatura”).  
- CTA claro: **“Entrar ou criar conta”** (conta no mesmo fluxo `AppRoutes.cadastroLogin`).  
- Indicar **como** se entra **só** com o que existe hoje (e-mail e senha) — subtítulo sob o botão, ex.: “Com e-mail e senha”. **Gate:** não prometer telefone / Google / Apple sem implementação.

**P4.3 Itens sem login (lista agrupada)**  
Blocos com títulos, ex.: **Suporte** e **Sobre**:  
- Ajuda e perguntas frequentes (FAQ curta estática ou rota/sheet — mesma honesty da Home P2.8).  
- Fale conosco → WhatsApp **somente** se `AppConfig.suporteWhatsapp` não vazio.  
- Área de entrega → consulta CEP **só** com fluxo/API existente; senão sheet honesta + deep-link checkout/endereço (mesmo gate P1.4).  
- Termos de uso + Política de privacidade (LGPD): abrir URL se já houver constante/config; senão item desabilitado ou “em breve” + nota DECISOES (**não** inventar URL).  
- Site Cristalins (`AppConfig.siteMarca`) no bloco Sobre.  
- Versão do app no rodapé (`package_info_plus` se já for dep; senão `String.fromEnvironment` / versão do `pubspec` via const gerada existente — não inventar número).

**P4.4 Barra da sacola (visível no Perfil via shell)**  
Mesmas regras P1.5 / P3.12: botão preenchido, copy “N itens · R$ … por entrega”, total idêntico à Sacola.

**P4.5 Estado logado (planejar; implementar só o que a API já cobre)**  
Topo: nome, foto ou iniciais, status da assinatura (dados de `/clientes/me` + assinatura se já carregados).  
Lista: Minha assinatura, Endereços, Pagamento, Faturas, Notificações — **ligar** às rotas existentes; se rota/API faltarem, omitir ou “em breve” (DECISOES), sem fake.  
“Sair” (limpar tokens) + “Excluir conta” → `DELETE /clientes/me` com confirmação (exigência lojas). Guest não mostra Excluir.

---

## P5 — Cadastro e login (`CadastroLoginScreen`)

Escopo: polir **Criar conta** + aba **Já tenho conta**. Preferir Flutter quando a API já cobre; mudanças de contrato (`CriarClienteDto`) só se P5.2 opção A e documentadas em DECISOES — **sem** migrate/Coolify/prod sem o João pedir.

### P5.1 Problemas atuais (UI)

- “Criar conta” **uma vez só**: tirar título grande redundante; abas no topo; botão CTA mantém o rótulo.  
- Rótulo do documento: **“CPF ou CNPJ”** (não só “CPF”).  
- Se documento = CNPJ (14 dígitos): pedir **razão social** no lugar de nascimento (PF continua com nascimento / picker). Sem campo API de razão social → usar `nome` como razão social e copy clara; IE/NF = P5.10 / gate.  
- **Celular obrigatório** (entregador); validar DDD+número. Ajustar app + DTO (`celular` required) se for o caso.  
- “(opcional)” só no **rótulo**, nunca no placeholder (quando algum campo for opcional).  
- Remover “Explorar sem entrar” de **entre** formulário e botão; no máximo link discreto **abaixo** do CTA ou omitir (já está na aba Perfil).  
- Botão CTA = azul-marinho dos outros (`BotaoPrincipal`).  
- Cabeçalho: padronizar com Sacola (seta; sem “Voltar” textual se Sacola só usa ícone — DECISOES).  
- Logo Cristalins no topo do formulário (`LogoMarca`).

### P5.2 Menos atrito (coleta mínima / LGPD)

**Meta (coleta mínima):** **nome** (“Como podemos te chamar?”) + **celular obrigatório** (P5.1) + **e-mail** (API já exige) + **senha**; CPF + nascimento no **checkout** quando fiscais/idade forem necessários. Não é “celular **ou** e-mail” — são os dois no caminho feliz.  
**Hoje** a API exige também `cpfCnpj` + `dataNascimento` no `POST /clientes`. Opções (escolher uma em DECISOES):  
1. **A — API+app:** tornar `cpfCnpj`/`dataNascimento` opcionais no create; exigir no checkout/assinatura antes de cobrar; justificar ou dropar nascimento se só idade mínima for regra noutro passo; `celular` required.  
2. **B — App-only:** manter CPF/nascimento no cadastro até a API mudar (não fingir deferral que quebra create); ainda assim celular obrigatório no form.  

Avisar: “Sua sacola será mantida depois do cadastro” (persistência já existe).  
Informar: endereço é pedido no **checkout**, não aqui.

**Gate / planejar (não inventar):** Google + Apple Sign-In (se Google, Apple é obrigatório nas lojas); entrada por código celular/WhatsApp sem senha; OTP pós-cadastro e-mail/celular.

### P5.3 Campos e teclado

- Rótulos **acima** dos campos (placeholders longos não cortados).  
- Teclado: numérico CPF/CNPJ, nascimento (se texto), celular; `emailAddress` no e-mail; `obscure` + toggle mostrar/ocultar senha.  
- Máscaras automáticas: CPF/CNPJ, data, celular.  
- `autofillHints` em todos (name, username/email, telephone, birthday, newPassword/password).  
- Nascimento (enquanto existir no form): **roda iPhone** — `showCupertinoModalPopup` + `CupertinoDatePicker` (`date`), ≥18 anos, preenche `DD/MM/AAAA` + `paraIso` no submit; Cancelar/Concluir; a11y.  
- Força da senha enquanto digita; regras em **lista com ✓** conforme cumpridas (comprimento, etc.).  
- Bloquear senhas comuns locais (lista curta: `12345678`, `password`…) — **gate** integração HaveIBeenPwned / vazamentos externos.  
- E-mail: trim + minúsculas; sugerir correção de domínio (`gmial.com` → `gmail.com`) com lista local.  
- Opt-in WhatsApp avisos de entrega junto do celular (pode mapear a `marketingOk` ou flag futura — não inventar canal se API não distingue).  
- `TextInputAction.next` / `done` (“Próximo” / “Concluir”); foco no 1º erro ao submeter.

### P5.4 Validação

- Validar **on blur** (ao sair do campo) com erro **logo abaixo**.  
- Dígitos verificadores CPF/CNPJ (`Validadores` — reforçar se preciso).  
- E-mail já cadastrado: mensagem clara + atalho **“Entrar”** (trocar aba); combinar com rate-limit (P5.9) para não virar oráculo de e-mails.  
- Celular obrigatório com mensagem clara.

### P5.5 Termos e consentimento

- Checkbox à **esquerda** do texto; **linha inteira** tocável.  
- “termos de uso” e “política de privacidade” = **links** (URL só se config; senão gate “em breve”).  
- Checkbox **separado e opcional** “Quero receber ofertas” → `marketingOk` (já no DTO).  
- Rodapé “Usamos seus dados…” vira link para política (mesma regra de URL).

### P5.6 Visual e teclado

- Mais contraste em “Seus dados” / “Acesso” e placeholders.  
- Mais espaço entre cards e textos de ajuda.  
- CTA “Criar conta” / “Entrar” **visível acima do teclado** (`rodape` / `viewInsets` — já há padrão `TelaTituloGrande`; garantir).  
- Aba selecionada mais destacada (negrito + cor marca).

### P5.7 Depois do envio

- Loading no botão + bloquear duplo toque (`enviando` — reforçar).  
- Falha de rede: mensagem clara + “Tentar de novo”.  
- Sucesso: confirmação curta (“Conta criada! Vamos finalizar sua assinatura”) se veio da sacola/checkout.  
- Retorno ao **destino de origem** (sacola/checkout), **não** home/quiz cego — respeitar `arguments`/rota de origem; se assinante → minha assinatura (regra atual).  
- Confirmação celular/e-mail com código = **gate** sem serviço OTP.

### P5.8 Aba “Já tenho conta”

- Manter **“Esqueci minha senha”** (já existe — não perder).  
- Biometria nos acessos seguintes = **planejar** (`local_auth`) se tokens/secure storage já permitirem; senão DECISOES.  
- **Preservar** o digitado ao alternar abas (controllers já vivem no State — não limpar no toggle).

### P5.9 Teclado, navegação, a11y, segurança, medição

- Confirmar ao voltar com dados: “Descartar cadastro?”.  
- Semantics em campos e checkboxes; anunciar erros no TalkBack/VoiceOver.  
- Layout ok com fonte do sistema **200%**.  
- Rate-limit tentativas cadastro/login por aparelho (client + preferir API se existir); captcha invisível só suspeito = **gate**.  
- Medir abandono por campo = **gate** (sem inventar analytics); se já houver evento/telemetry no app, instrumentar só com o canal existente.

### P5.10 Empresas (CNPJ)

- Caminho **“Para empresas”**: razão social + inscrição estadual; pergunta NF com CNPJ.  
- **Gate/API:** schema atual não tem IE/razão social separados — UI pode ramificar e mandar razão social em `nome` + CNPJ em `cpfCnpj` até existir modelo; não inventar colunas Prisma sem pedido explícito + migration local documentada.

Testes mínimos P5: sem “Criar conta” triplo; rótulo CPF ou CNPJ; celular required; termos+marketingOk; picker nascimento (PF); máscara; toggle senha; e-mail duplicado → Entrar; destino pós-login = sacola se origem sacola; Explorar fora do miolo do form.

---

## Gate

| Item | Motivo |
| --- | --- |
| Preço / % nos **cards** catálogo | v3 |
| Oferta 1º pedido com R$/% inventado | Sem fonte |
| CEP Home/sacola/perfil com API inexistente | Não inventar endpoint |
| Pular entrega se API não soportar | Só deep-link Assinatura |
| Corrigir preço galão no DB pelo app | Seed/HANDOFF |
| Número WhatsApp inventado | `SUPORTE_WHATSAPP` vazio = ocultar |
| Google / Apple / OTP SMS-WhatsApp | Sem integração |
| Deferir CPF/nascimento sem mudar API | `POST /clientes` exige hoje |
| URL Termos/Privacidade inventada | LANCAMENTO pendente |
| Captcha / HIBP / analytics abandono | Sem serviço |
| Colunas IE/razão social / OTP verify | Sem schema/serviço |
| Excluir conta no guest | Só logado + `DELETE /clientes/me` |
| Coolify / migrate prod | Só se João pedir |

---

## Anti-escopo

Redesenho total / dark / purple / glow genérico; Coolify/seed/push/commit/`.env` sem pedido; Gemini/cerveja; reverter impacto/`EmptyAssinatura`; SAC ≠ app; inventar fotos, assinantes, frete, descontos, estoque, OAuth, OTP, URLs legais, telemetria.

---

## Critério de pronto

- [ ] P0–P2 Home  
- [ ] P3 Sacola + total alinhado à barra  
- [ ] P4 Perfil guest  
- [ ] P5 Auth: UI (P5.1/3–8), nascimento roda, termos+marketingOk; P5.2 só com DECISOES/API alinhada; gates listados  
- [ ] Gates em DECISOES; lista UX marcada  
- [ ] Testes: hero; sacola; perfil; auth (rótulos, celular, picker, destino sacola)  
- [ ] Analyze + `graphify update .`  
- [ ] Relatório P0–P5  

## Ordem

1. P0 cards/kits/FF/stepper-feedback/a11y imagens  
2. P1 fundo + hero + header + tipografia + localização + badge + **BarraSacola**  
3. P2 carrossel/ordem/filtros/dots + assinante + FAQ/WhatsApp + skeletons  
4. P3 Sacola (+ alinhamento total)  
5. P4 Perfil guest (+ planejar logado)  
6. P5 Auth/cadastro/login (UI primeiro; API deferral só se P5.2 opção A)  
7. Testes + docs + relatório  

Implemente agora, na ordem acima.
