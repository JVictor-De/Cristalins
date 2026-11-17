/// Assets de marca e hero (espelho cristalins-v2 → `assets/images/`).
///
/// Hero WP e origem usam fotos de produto **sem** tipografia/scrollbar de print
/// de landing (BUGS_UX #2–5). `flow_protein.webp` / `colocar_site-fast.webp`
/// ficam no disco só como legado — não usar na UI.
/// Garrafas de produto: PNG transparente em `produtos/` (sem caixa opaca).
/// PNG com fundo transparente (sem ColorFilter / chroma-key).
const assetLogoMarca = 'assets/images/brand/logo.png';

/// Recorte de produto (sem texto de site) — hero WP.
const assetHeroFlowProtein = 'assets/images/produtos/protein.png';

const assetHeroFlowFiber = 'assets/images/produtos/flow_fiber-fast.png';
const assetHeroTodosProdutos = 'assets/images/hero/todos_produtos-fast.webp';

/// Fundo do onboarding sem tipografia de print (substitui `agua-bokeh.webp`).
const assetHeroAguaBokeh = 'assets/images/hero/agua-bokeh-limpa.png';
const assetHeroRespingo = 'assets/images/hero/impacto-respingo.webp';

/// Foto limpa de produto (substitui print `colocar_site-fast.webp`).
const assetHeroColocarSite = 'assets/images/produtos/ams500.png';

const assetHeroSustentabilidade = 'assets/images/hero/sustentabilidade-v2-fast.webp';

/// Alias explícito para o asset de produto no hero.
const assetProdutoWaterProtein = 'assets/images/produtos/protein.png';
const assetProdutoAguaMineral = 'assets/images/produtos/ams500.png';

/// Garrafa WP transparente do onboarding/boas-vindas (PNG anexado).
const assetOnboardingGarrafaWp =
    'assets/images/produtos/cristalins-garrafa-transparente.png';

/// Cena de impacto (site `#inicio` → PDP água mineral).
const assetImpactoFundo = 'assets/images/brand/impacto/impacto-fundo.webp';
const assetImpactoGarrafa = 'assets/images/brand/impacto/impacto-garrafa.webp';
const assetImpactoRespingo = 'assets/images/brand/impacto/impacto-respingo.webp';
const assetImpactoFrase = 'assets/images/brand/impacto/impacto-frase.webp';
const assetImpactoMarca = 'assets/images/brand/impacto/impacto-marca.webp';

/// SKUs de água mineral: mesma cena (fundo + respingo), garrafa = `assetDoProduto`.
const codigosAguaMineralImpacto = {
  'AMS500',
  'AMC510',
  'AMN1500',
  'AMN5000',
  'AMC200',
};

/// Copy/frase do site (“água mineral…”) só nestas SKUs.
bool usaCopyImpactoMineral(String codigo) => codigosAguaMineralImpacto.contains(codigo);

/// Toda PDP de catálogo pode usar a cena; a foto da garrafa vem do código do produto.
bool usaCenaImpactoAgua(String codigo) =>
    codigosAguaMineralImpacto.contains(codigo) ||
    codigo == 'WP500' ||
    codigo == 'FF500' ||
    codigo == 'GUA2000';
