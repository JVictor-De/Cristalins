/// Assets de marca e hero (espelho cristalins-v2 → `assets/images/`).
///
/// Hero WP e origem usam fotos de produto **sem** tipografia/scrollbar de print
/// de landing (BUGS_UX #2–5). `flow_protein.webp` / `colocar_site-fast.webp`
/// ficam no disco só como legado — não usar na UI.
const assetLogoMarca = 'assets/images/brand/logo.jpg';

/// Recorte de produto (sem texto de site) — hero WP.
const assetHeroFlowProtein = 'assets/images/produtos/protein.webp';

const assetHeroFlowFiber = 'assets/images/hero/flow_fiber-fast.webp';
const assetHeroTodosProdutos = 'assets/images/hero/todos_produtos-fast.webp';
const assetHeroAguaBokeh = 'assets/images/hero/agua-bokeh.webp';
const assetHeroRespingo = 'assets/images/hero/impacto-respingo.webp';

/// Foto limpa de produto (substitui print `colocar_site-fast.webp`).
const assetHeroColocarSite = 'assets/images/produtos/ams500.webp';

const assetHeroSustentabilidade = 'assets/images/hero/sustentabilidade-v2-fast.webp';

/// Alias explícito para o asset de produto no hero.
const assetProdutoWaterProtein = 'assets/images/produtos/protein.webp';
const assetProdutoAguaMineral = 'assets/images/produtos/ams500.webp';

/// Cena de impacto (site `#inicio` → PDP água mineral).
const assetImpactoFundo = 'assets/images/brand/impacto/impacto-fundo.webp';
const assetImpactoGarrafa = 'assets/images/brand/impacto/impacto-garrafa.webp';
const assetImpactoRespingo = 'assets/images/brand/impacto/impacto-respingo.webp';
const assetImpactoFrase = 'assets/images/brand/impacto/impacto-frase.webp';
const assetImpactoMarca = 'assets/images/brand/impacto/impacto-marca.webp';

/// SKUs de água mineral que usam a cena completa (não WP/Fiber).
const codigosAguaMineralImpacto = {
  'AMS500',
  'AMC510',
  'AMN1500',
  'AMN5000',
  'AMC200',
};

bool usaCenaImpactoAgua(String codigo) => codigosAguaMineralImpacto.contains(codigo);
