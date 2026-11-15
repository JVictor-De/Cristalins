---
name: apple-style-flutter
description: Aplica a linguagem visual da Apple (Human Interface Guidelines) a apps Flutter, inclusive no Android, mantendo as cores da marca do projeto. Use ao criar ou revisar telas, componentes, tema, tipografia, navegação, listas, formulários, folhas, alertas ou animações em Flutter, e sempre que pedirem "cara de Apple", "estilo iOS", "Cupertino", "HIG" ou "design premium".
---

# Estilo Apple em Flutter

Esta skill faz um app Flutter parecer e se comportar como um app da Apple — tipografia grande e limpa, listas agrupadas, muito respiro, navegação deslizante, háptica e movimento suave — **sem trocar a identidade da marca** e **sem quebrar regras de licença ou de desempenho no Android**.

## 1. Prioridades (em caso de conflito)

1. **Acessibilidade e legibilidade** (contraste ≥ 4,5:1, toque ≥ 48 dp, fonte escalável)
2. **Marca do projeto**: cores, logo e voz definidos no design system do projeto (ex.: `lib/core/theme/`). A cor de destaque da Apple (o "tint") passa a ser a cor primária da marca.
3. **Human Interface Guidelines** da Apple (esta skill)
4. Padrões do Material Design, só onde não houver equivalente Cupertino

Antes de mexer em qualquer tela, leia os tokens do projeto. Se não existirem, crie-os primeiro (seção 3 e `references/tema-flutter.md`).

## 2. Regras que nunca podem ser quebradas

- **Não embarque SF Pro, SF Compact, New York nem SF Symbols** em app Android ou multiplataforma: a licença da Apple só permite uso em plataformas Apple. Use **Inter** (texto) e **CupertinoIcons** (ícones, licença MIT).
- **Não copie logos, imagens ou ícones da Apple.** "Cara de Apple" é linguagem visual, não marca.
- **Sem desfoque (blur/Liquid Glass) no Android.** `BackdropFilter` é caro no rasterizador e pesa em aparelhos simples. No Android, use superfícies sólidas ou levemente translúcidas sem blur. Em iOS, no máximo 2 camadas de blur por tela.
- **Botão voltar do Android continua funcionando** (gesto e botão do sistema). O estilo é Apple; o comportamento do sistema é do Android.

## 3. Base técnica (configure uma vez)

- `MaterialApp` com `theme.platform = TargetPlatform.iOS`. Assim os widgets Material adotam o comportamento iOS (transição de tela, seleção de texto, ícone de voltar em chevron).
- `fontFamily: 'Inter'` no `ThemeData`: com a plataforma iOS, textos sem estilo explícito tentariam usar a fonte do sistema da Apple, que não existe no Android.
- `pageTransitionsTheme` com `CupertinoPageTransitionsBuilder` para Android e iOS: tela nova desliza da direita e o gesto de arrastar da borda volta.
- `scrollBehavior` com `BouncingScrollPhysics` (rolagem elástica) e sem o brilho de overscroll do Android.
- `cupertinoOverrideTheme` com a cor primária da marca e a tipografia Inter, para os widgets Cupertino herdarem o mesmo visual.
- Pacotes: `cupertino_icons`. Nada de pacotes de "liquid glass" de terceiros.
- Código pronto: `references/tema-flutter.md`.

## 4. Tipografia (escala da HIG em Inter)

Use **uma família só (Inter)**, como a Apple usa uma só (SF). Tamanhos em sp, iguais aos pontos da HIG:

| Estilo | Tamanho / altura | Peso | Espaçamento | Uso |
| --- | --- | --- | --- | --- |
| largeTitle | 34 / 41 | Bold 700 | −0,6 | Título grande da tela (encolhe ao rolar) |
| title1 | 28 / 34 | Bold 700 | −0,4 | Destaque de resultado (ex.: preço total) |
| title2 | 22 / 28 | Bold 700 | −0,3 | Título de seção importante |
| title3 | 20 / 25 | SemiBold 600 | −0,2 | Título de card |
| headline | 17 / 22 | SemiBold 600 | −0,2 | Pergunta, nome de produto, texto de botão |
| body | 17 / 22 | Regular 400 | −0,2 | Texto corrido e linhas de lista |
| callout | 16 / 21 | Regular 400 | −0,1 | Texto de apoio maior |
| subheadline | 15 / 20 | Regular 400 | −0,1 | Descrição de produto, subtítulos |
| footnote | 13 / 18 | Regular 400 | 0 | Notas, rodapé de seção agrupada |
| caption1 | 12 / 16 | Regular 400 | 0 | Legendas |
| caption2 | 11 / 13 | Medium 500 | +0,1 | Selos e rótulos pequenos |

- Hierarquia por **peso e tamanho**, não por cor. No máximo 3 níveis por tela.
- Texto em **frase normal** (só a primeira letra maiúscula), inclusive botões. Caixa alta só em selos curtos (caption2).
- Respeite o tamanho de fonte do sistema (`MediaQuery.textScalerOf`). Teste com 130%: nada pode cortar ou sobrepor.
- Números que mudam (preço, contador): `FontFeature.tabularFigures()` para não "pular".

## 5. Cor e superfícies

- **Fundo da tela**: cinza muito claro e frio (padrão: `#F2F5F7`), como o fundo agrupado do iOS.
- **Seções e células**: brancas (`#FFFFFF`), agrupadas, com cantos de 12 dp.
- **Divisórias**: linha fina (0,5 dp) na cor de borda, recuada para alinhar com o texto (não com o ícone).
- **Cor de destaque (tint)**: a primária da marca, em botões principais, seleção, switches e chevrons ativos. Links e ações de texto: um tom mais claro da marca que passe 4,5:1 sobre branco. Sobre o fundo agrupado (que não é branco), confira o contraste de novo e escureça o tom se precisar.
- **Cores de status**: as semânticas do projeto. Ação destrutiva sempre em vermelho e sempre em folha de confirmação.
- **Sem sombras** em cards e listas; a separação vem do agrupamento e do fundo. Sombra suave só em elementos flutuantes (folha, menu).
- **Sem gradientes** em fundo de tela e botão. No máximo uma cor de destaque secundária (ex.: um selo) por tela.
- Modo escuro: quando for feito, siga o par claro/escuro do iOS (fundo `#000000`, células `#1C1C1E`) com os mesmos tokens semânticos.

## 6. Layout

- Margem lateral de **16 dp** (20 dp em telas largas). Espaço entre seções agrupadas: **24–32 dp**.
- **Título grande** no topo (largeTitle) que encolhe para título central ao rolar: `CupertinoSliverNavigationBar` dentro de `CustomScrollView`, com fundo **opaco** no Android (fundo opaco não aplica blur).
- **Uma ação principal por tela**, num botão largo preso ao rodapé, acima da área segura (`SafeArea`), com 16 dp de margem.
- Conteúdo em **listas agrupadas** (estilo app Ajustes): cada grupo com cabeçalho curto em footnote acima e, se preciso, nota explicativa abaixo.
- Toque mínimo de **48 dp** (o Android exige mais que os 44 pt do iOS).
- Imagens de produto em fundo limpo, proporção fixa (1:1), cantos de 12 dp.

## 7. Componentes: qual usar

| Necessidade | Use | Detalhes |
| --- | --- | --- |
| Barra superior com título | `CupertinoSliverNavigationBar` / `CupertinoNavigationBar` | Título grande; voltar em chevron com o nome da tela anterior; fundo opaco no Android |
| Botão principal | `CupertinoButton.filled` dentro de `SizedBox` (altura 50, largura total) | Formato cápsula; texto headline; desabilitado com 40% de opacidade |
| Botão secundário | `CupertinoButton` (sem fundo) ou com fundo tom claro da marca | Texto na cor tint |
| Ação destrutiva | `CupertinoActionSheet` com `isDestructiveAction: true` | Nunca botão vermelho solto na tela |
| Lista e configurações | `CupertinoListSection.insetGrouped` + `CupertinoListTile` | Chevron (`CupertinoListTileChevron`) quando abre outra tela |
| Campo de texto | `CupertinoTextField` (ou `CupertinoTextFormFieldRow` em seção agrupada) | Fundo branco na seção ou cinza claro solto; cantos 10 dp; erro em footnote vermelho abaixo |
| Escolha única curta (2–4 opções) | `CupertinoSlidingSegmentedControl` | Ex.: semanal / quinzenal / mensal |
| Escolha única longa | Linhas de lista com marca de seleção ou `CupertinoRadio` | Linha inteira clicável |
| Marcar opção | `CupertinoCheckbox` | Ex.: aceite de termos |
| Ligar e desligar | `CupertinoSwitch` (`activeTrackColor` = tint) | Efeito imediato, sem botão "salvar" |
| Lista de valores (spinner) | `CupertinoPicker` em folha inferior | Com botão "Concluir" no topo da folha |
| Data | `CupertinoDatePicker` em folha inferior | |
| Carregando | `CupertinoActivityIndicator` | Centralizado; em botão, substitui o texto |
| Progresso por etapas | `LinearProgressIndicator` fino (4 dp), cantos arredondados | Com texto "Etapa 2 de 5" em footnote |
| Confirmação | `CupertinoAlertDialog` | Título curto, 1 frase, ação principal à direita |
| Folha de opções | `showCupertinoModalPopup` | Cantos superiores 16 dp |
| Aviso rápido | SnackBar flutuante com cantos 14 dp, texto subheadline | Ou banner no topo; nunca bloquear a tela |
| Contador de quantidade | `−` e `+` em `CupertinoButton` circulares de 32 dp, número tabular no meio | Passo conforme a regra do produto |
| Ícones | `CupertinoIcons` | Traço fino; 22–24 dp; mesma cor do texto ou tint |

Se um requisito externo (ex.: avaliação acadêmica) pedir um componente com nome Material (RadioButton, Spinner, CheckBox), use o **equivalente Cupertino** da tabela e diga na documentação que ele cumpre o mesmo papel.

## 8. Movimento e háptica

- Durações: 150 ms (toques, seleção), 250–300 ms (troca de etapa, expandir), 350 ms (folhas). Curva `Curves.easeOutCubic` ou mola suave; nada de "quicar" exagerado.
- Animação mostra causa e efeito (o item que foi adicionado, o valor que mudou). Nada decorativo em loop.
- Se `MediaQuery.disableAnimationsOf(context)` for verdadeiro, troque animações por mudança imediata.
- Háptica (`HapticFeedback`): `selectionClick` ao trocar opção ou segmento; `lightImpact` ao confirmar; `mediumImpact` em sucesso importante (assinatura criada); `heavyImpact` nunca.

## 9. Texto e conteúdo

- Frases curtas, em segunda pessoa, verbo no início dos botões ("Assinar agora", "Salvar endereço").
- Botões dizem o que fazem; evite "OK" quando houver verbo melhor.
- Estados vazios: ícone, uma frase e uma ação. Erros: o que aconteceu e o que fazer ("Não conseguimos carregar agora. Tentar de novo").
- Valores sempre formatados no padrão do país (ex.: `R$ 213,19`, `20/11`).

## 10. Checklist antes de dar uma tela por pronta

- [ ] Só tokens do tema (nenhuma cor, fonte ou tamanho fixo na tela)
- [ ] Título grande ou barra de navegação conforme a seção 6
- [ ] Uma ação principal clara, presa ao rodapé
- [ ] Conteúdo agrupado, alinhado à margem de 16 dp
- [ ] Componentes Cupertino da seção 7
- [ ] Sem blur no Android, sem sombra em card, sem gradiente
- [ ] Contraste ≥ 4,5:1, toque ≥ 48 dp, fonte a 130% sem quebrar
- [ ] Estados de carregando, vazio, erro e sucesso
- [ ] Háptica nas escolhas e confirmações; animações respeitam "reduzir movimento"
- [ ] Gesto de voltar e botão voltar do Android funcionando
- [ ] `flutter analyze` sem avisos (troque APIs depreciadas pelas atuais)

## 11. Anti-padrões

- Misturar componentes Material visíveis (FAB, chips Material, AppBar com sombra, ripple) com Cupertino na mesma tela
- Botões em caixa alta, textos centralizados em blocos longos, ícones preenchidos e pesados
- Vários botões coloridos competindo na mesma tela
- Bordas grossas em cards; listas sem agrupamento coladas na borda da tela
- Usar fonte SF Pro "porque fica igual ao iPhone" (proibido pela licença fora de aparelhos Apple)
