# Tema Flutter no estilo Apple — código de referência

Ajuste os nomes das cores ao design system do projeto (`AppColors`). Os valores abaixo seguem o padrão da skill; a cor primária deve ser a da marca.

## Tokens extras de superfície

```dart
// lib/core/theme/app_colors.dart (acrescente aos tokens da marca)
static const fundoAgrupado = Color(0xFFF2F5F7); // fundo das telas
static const superficie = Color(0xFFFFFFFF);    // seções e células
```

## Tipografia (escala da HIG em Inter)

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const _familia = 'Inter';

  static TextStyle _estilo(double tamanho, double altura, FontWeight peso, double espacamento) {
    return TextStyle(
      fontFamily: _familia,
      fontSize: tamanho,
      height: altura / tamanho,
      fontWeight: peso,
      letterSpacing: espacamento,
    );
  }

  static final largeTitle = _estilo(34, 41, FontWeight.w700, -0.6);
  static final title1 = _estilo(28, 34, FontWeight.w700, -0.4);
  static final title2 = _estilo(22, 28, FontWeight.w700, -0.3);
  static final title3 = _estilo(20, 25, FontWeight.w600, -0.2);
  static final headline = _estilo(17, 22, FontWeight.w600, -0.2);
  static final body = _estilo(17, 22, FontWeight.w400, -0.2);
  static final callout = _estilo(16, 21, FontWeight.w400, -0.1);
  static final subheadline = _estilo(15, 20, FontWeight.w400, -0.1);
  static final footnote = _estilo(13, 18, FontWeight.w400, 0);
  static final caption1 = _estilo(12, 16, FontWeight.w400, 0);
  static final caption2 = _estilo(11, 13, FontWeight.w500, 0.1);

  /// Mapeia a escala da Apple para os papéis do Material.
  /// `bodyMedium` é o estilo padrão de `Text`, por isso recebe `body`.
  static TextTheme get textTheme => TextTheme(
        displaySmall: largeTitle,
        headlineMedium: title1,
        headlineSmall: title2,
        titleLarge: title3,
        titleMedium: headline,
        titleSmall: subheadline,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: footnote,
        labelLarge: headline,
        labelMedium: caption1,
        labelSmall: caption2,
      );
}
```

## Tema do app

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.azul800,
    onPrimary: Colors.white,
    primaryContainer: AppColors.azul100,
    onPrimaryContainer: AppColors.azul900,
    secondary: AppColors.azul500,
    onSecondary: Colors.white,
    tertiary: AppColors.amareloFlow,
    onTertiary: AppColors.azul900,
    error: AppColors.erro,
    onError: Colors.white,
    surface: AppColors.superficie,
    onSurface: AppColors.texto,
    onSurfaceVariant: AppColors.textoSecundario,
    outline: AppColors.borda,
  );

  return ThemeData(
    useMaterial3: true,
    platform: TargetPlatform.iOS, // comportamento iOS nos widgets Material
    fontFamily: 'Inter', // cobre textos sem estilo explícito
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.fundoAgrupado,
    textTheme: AppTypography.textTheme,
    splashFactory: NoSplash.splashFactory, // sem "ripple" do Android
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      primaryColor: AppColors.azul800,
      scaffoldBackgroundColor: AppColors.fundoAgrupado,
      barBackgroundColor: AppColors.fundoAgrupado, // opaco: sem blur
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.azul800,
        textStyle: AppTypography.body.copyWith(color: AppColors.texto),
        actionTextStyle: AppTypography.body.copyWith(color: AppColors.azul500),
        navTitleTextStyle: AppTypography.headline.copyWith(color: AppColors.texto),
        navLargeTitleTextStyle: AppTypography.largeTitle.copyWith(color: AppColors.texto),
      ),
    ),
    dividerTheme: const DividerThemeData(thickness: 0.5, space: 0.5, color: AppColors.borda),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.texto,
      contentTextStyle: AppTypography.subheadline.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.azul500,
      linearTrackColor: AppColors.azul100,
      linearMinHeight: 4,
    ),
  );
}

/// Rolagem elástica do iOS também no Android, sem o brilho de overscroll.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
```

```dart
// app.dart
MaterialApp(
  theme: buildAppTheme(),
  scrollBehavior: const AppScrollBehavior(),
  locale: const Locale('pt', 'BR'),
  supportedLocales: const [Locale('pt', 'BR')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate, // textos dos widgets Cupertino em português
    GlobalWidgetsLocalizations.delegate,
  ],
  // ...
);
```

## Fontes

Baixe a Inter (Google Fonts ou rsms.me/inter), use os arquivos estáticos e renomeie conforme abaixo.

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-SemiBoldItalic.ttf
          weight: 600
          style: italic
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

## Esqueleto de tela

```dart
Scaffold(
  body: CustomScrollView(
    slivers: [
      const CupertinoSliverNavigationBar(
        largeTitle: Text('Minha assinatura'),
        backgroundColor: AppColors.fundoAgrupado, // opaco: sem blur no Android
        border: null,
      ),
      SliverToBoxAdapter(
        child: CupertinoListSection.insetGrouped(
          header: const Text('Próxima entrega'),
          children: const [
            CupertinoListTile(
              title: Text('Quinta, 20/11'),
              subtitle: Text('Manhã, 8h–12h'),
              trailing: CupertinoListTileChevron(),
            ),
          ],
        ),
      ),
    ],
  ),
  bottomNavigationBar: SafeArea(
    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: SizedBox(
      height: 50,
      child: CupertinoButton.filled(
        borderRadius: BorderRadius.circular(25), // cápsula
        onPressed: () => HapticFeedback.lightImpact(),
        child: const Text('Alterar cesta'),
      ),
    ),
  ),
);
```

## Escolha curta com controle segmentado

```dart
CupertinoSlidingSegmentedControl<Frequencia>(
  groupValue: frequencia,
  children: const {
    Frequencia.semanal: Text('Semanal'),
    Frequencia.quinzenal: Text('Quinzenal'),
    Frequencia.mensal: Text('Mensal'),
  },
  onValueChanged: (valor) {
    if (valor == null) return;
    HapticFeedback.selectionClick();
    controller.alterarFrequencia(valor);
  },
);
```

## Ação destrutiva com confirmação

```dart
showCupertinoModalPopup<void>(
  context: context,
  builder: (ctx) => CupertinoActionSheet(
    title: const Text('Cancelar assinatura?'),
    message: const Text('As entregas já pagas continuam agendadas.'),
    actions: [
      CupertinoActionSheetAction(
        isDestructiveAction: true,
        onPressed: () {
          Navigator.pop(ctx);
          controller.cancelar();
        },
        child: const Text('Cancelar assinatura'),
      ),
    ],
    cancelButton: CupertinoActionSheetAction(
      onPressed: () => Navigator.pop(ctx),
      child: const Text('Manter assinatura'),
    ),
  ),
);
```

## APIs que mudam entre versões

Algumas APIs Cupertino mudaram nas versões recentes do Flutter (ex.: `activeColor` → `activeTrackColor` no `CupertinoSwitch`; rádios passaram a usar um `RadioGroup` ancestral). Sempre rode `flutter analyze` e troque qualquer API marcada como depreciada pela indicada na mensagem.
