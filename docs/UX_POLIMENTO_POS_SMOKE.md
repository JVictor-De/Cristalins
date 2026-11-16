# UX — polimento pós-smoke (prints 2026-11-16 ~03h)

Fonte: prints Início + Produtos (Kits) + Sacola + Perfil guest + cadastro em `cristalins.peladeiro.cloud` após seed + PNG.

**Status:** **consolidado** (2026-11-16) — P0–P5 + revisão na fila `doc/prompts/features/ux_polimento_pos_smoke/` (`CONSOLIDACAO.md`). Gates (preço cards, OAuth, URLs legais, seed galão…) permanecem humanos/DECISOES.  
**Monólito:** `docs/PROMPT_UX_POLIMENTO_POS_SMOKE.md` (cópia na fila: `PROMPT_MONOLITO.md`).  
**Rodar:** `.\scripts\ux_polimento_pos_smoke_run_auto.ps1`  
**Conflito:** preço/% nos **cards** do catálogo = gate v3. Hero “a partir de R$…” = **exceção** documentável via `precoBase` WP.  
**Nota local:** logo `brand/logo.png` + `LogoMarca` sem ColorFilter já no working tree (fora do monólito P0–P5).

---

## Bugs a corrigir primeiro

1. Flow Fiber: PNG sem xadrez.  
2. Cards: cantos + “+” interno; após 1º toque → seletor qty + feedback “Adicionado”.  
3. Miniaturas: escala padronizada + fundo suave.  
4. Título: “Water Protein” curto.  
5. Banner final: sem garrafa solta.  
6. Kits: minis PNG.  
7. a11y: `semanticLabel` em todas as fotos de produto.

---

## Fundo e profundidade

1. Off-white `#F6F9FB`.  
2. Cards brancos + sombra + borda 1px.  
3. Degradê só no topo.  
4. Faixas alternadas (“Como funciona” branca).  
5. Verde só hero/destaques WP.

---

## Hero

1. Menos altura; sem vazio subtítulo→botão.  
2. Chips: “5 g de proteína **por garrafa**”, “0 açúcar”, “0 gordura”.  
3. Uma família (Inter no hero).  
4. Garrafa maior + sombra sangrando.  
5. Badge **“Mais vendido”** (não “Carro-chefe”).  
6. “a partir de R$ …/un.” com `precoBase` WP (exceção vs cards).  
7. “Ver todas as águas” alinhado à esquerda **ou** removido se redundante.  
8. “Assinar Water Protein” → **adiciona à sacola** + abre sacola.

---

## Localização

1. Pílula clicável (seta / “Alterar”).  
2. CEP na home **só** com API/zona existente; senão gate + copy checkout.

---

## Produtos (carrossel Home)

1. ~~Preço / selo % nos cards~~ → gate.  
2. Fundo suave por produto.  
3. Incluir **galão** na lista.  
4. Não começar por WP (já no hero).  
5. Filtros rápidos: Sem gás, Com gás, Funcionais, Galão.  
6. Indicador de rolagem (dots/barra).  
7. Kits: minis + layout sem void.

---

## Acesso à sacola

1. Ícone + contador no topo da Home.  
2. `BarraSacola`: botão **preenchido** “Ver sacola”; copy “N itens · R$ … **por entrega**” com valor em destaque; **mesmo** total/arredondamento da Sacola (evitar 72,86 × 72,88).

---

## Tipografia e espaçamento

1. Escala: seção > card.  
2. “Olá!” menor; logo com mais peso.  
3. Margens/`secao` padronizados.  
4. “Ver todos” na baseline de “Produtos”.  
5. Contraste cinzas + tabs inativas.

---

## Personalização

1. Assinante: próxima entrega no topo (`CardProximaEntrega`).  
2. Atalhos “Pular entrega” / “Editar assinatura” → fluxos existentes.  
3. Oferta 1º pedido: **sem** % inventado (gate) ou copy Pix/frequência só.

---

## Rodapé e suporte

1. WhatsApp só se `SUPORTE_WHATSAPP` preenchido.  
2. FAQ curta (área, pausa, cancelamento) — copy honesta.

---

## Estados e a11y (Home)

1. Skeletons hero + cards.  
2. Erro catálogo + “Tentar de novo”.  
3. Alt text em imagens de produto.

---

## Sacola — ver monólito § P3

Bugs (galão/seed, centavos, un.×embalagem, navy, AppBar), layout, itens, freq, frete, steps, confiança, total, swipe, empty, a11y + total alinhado à barra.

---

## Perfil (guest / não logado) — monólito § P4

### Problemas atuais

1. Remover “Explorar sem entrar” (no-op na aba).  
2. Preencher o vazio abaixo do CTA.  
3. “Site Cristalins” como item de lista (ícone + seta externa + mesma margem).  
4. “Entrar” no azul-marinho dos CTAs principais.  
5. Cabeçalho padronizado com Sacola/shell (evitar `largeTitle` solto).

### Entrada na conta

1. Ícone/ilustração + benefício (“Acompanhe entregas…”).  
2. CTA **“Entrar ou criar conta”** (mesmo fluxo).  
3. Indicar meio real: **e-mail e senha** — gate: sem Google/Apple/telefone inventados.

### Itens sem login

1. Blocos **Suporte** / **Sobre**.  
2. Ajuda e FAQ.  
3. Fale conosco (WhatsApp se config).  
4. Área de entrega (CEP com gate de API).  
5. Termos + Política de privacidade (LGPD; URL só se existir).  
6. Versão do app no rodapé.

### Barra da sacola no Perfil

Mesmas regras da Home/Sacola (botão preenchido + total único).

### Estado logado (planejar)

Nome/iniciais + status; Minha assinatura, Endereços, Pagamento, Faturas, Notificações; Sair + Excluir conta (`DELETE /clientes/me`) — só o que a API/rota já cobre.

---

## Cadastro e login — monólito § P5

### Problemas atuais

1. “Criar conta” uma vez só (tirar título grande; abas no topo).  
2. Rótulo **“CPF ou CNPJ”**.  
3. CNPJ → razão social no lugar de nascimento.  
4. Celular **obrigatório**.  
5. “(opcional)” no rótulo, não no placeholder.  
6. “Explorar sem entrar” fora do miolo (abaixo do CTA ou omitir).  
7. CTA azul-marinho; cabeçalho alinhado à Sacola; logo no topo.

### Menos atrito / LGPD

1. Ideal: nome + celular **obrigatório** + e-mail + senha; CPF/nascimento no checkout (exige API — DECISOES A/B).  
2. Justificar nascimento ou remover.  
3. Avisar que a sacola se mantém; endereço só no checkout.  
4. Google + Apple / OTP WhatsApp = gate até existir integração.

### Campos / validação / termos

1. Rótulos acima; máscaras; teclados certos; autofill; toggle senha; força + checklist ✓.  
2. Nascimento com `CupertinoDatePicker` (rodas) enquanto o campo existir.  
3. Validar on blur; dígitos CPF/CNPJ; e-mail duplicado + atalho Entrar; foco no 1º erro.  
4. Termos: checkbox à esquerda, linha tocável, links; opt-in ofertas (`marketingOk`).  
5. Nome como “Como podemos te chamar?”; tip domínio; e-mail trim/lower; senhas comuns locais; opt-in WhatsApp junto do celular.

### Visual / pós-envio / login

1. Contraste seções; CTA acima do teclado; aba selecionada destacada.  
2. Loading + anti double-tap; rede com “Tentar de novo”; volta à sacola/checkout; confirmação curta.  
3. OTP e-mail/celular = gate.  
4. “Esqueci minha senha”; biometria = planejar; preservar campos entre abas.  
5. Próximo/Concluir no teclado; “Descartar cadastro?” ao voltar.  
6. a11y + fonte 200%; rate-limit; captcha/HIBP/analytics = gate.  
7. Empresas: caminho CNPJ (razão social/IE/NF) — schema incompleto = gate parcial.

---

## Ordem

| Ordem | Escopo |
| --- | --- |
| P0 | FF, cards, kits, stepper no card, a11y imagens |
| P1 | Fundo, hero, header, CEP pílula, badge + BarraSacola preenchida/total |
| P2 | Carrossel ordem/filtros/dots, assinante, FAQ/WhatsApp, skeletons |
| P3 | Sacola (+ alinhamento total) |
| P4 | Perfil guest (+ planejar logado) |
| P5 | Auth cadastro/login (UI; API deferral só opção A) |
| Gate | Preço cards, OAuth/OTP, deferral sem API, URLs legais, captcha/HIBP, seed galão |
