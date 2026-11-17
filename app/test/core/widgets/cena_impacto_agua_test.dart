import 'package:cristalins_assinatura/core/marca_assets.dart';
import 'package:cristalins_assinatura/core/theme/app_theme.dart';
import 'package:cristalins_assinatura/core/widgets/cena_impacto_agua.dart';
import 'package:cristalins_assinatura/features/catalog/domain/produto_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget envelopar(Widget filho) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SizedBox(width: 320, height: 400, child: filho),
      ),
    );
  }

  Image? _imagemComAsset(String path) {
    final imagens = find.byType(Image).evaluate().map((e) => e.widget).whereType<Image>();
    for (final img in imagens) {
      final provider = img.image;
      if (provider is AssetImage && provider.assetName == path) return img;
      if (provider is ExactAssetImage && provider.assetName == path) return img;
    }
    return null;
  }

  testWidgets('troca só a garrafa ao mudar o SKU; fundo e respingo permanecem', (tester) async {
    final ams = garrafaDaCenaImpacto('AMS500');
    final galao = garrafaDaCenaImpacto('AMN5000');

    await tester.pumpWidget(
      envelopar(
        CenaImpactoAgua(
          key: const ValueKey('impacto-AMS500'),
          autoPlay: false,
          mostrarReplay: false,
          garrafaAsset: ams,
          mostrarCopyMarca: true,
        ),
      ),
    );
    await tester.pump();

    expect(_imagemComAsset(ams), isNotNull);
    expect(_imagemComAsset(assetImpactoFundo), isNotNull);
    expect(_imagemComAsset(assetImpactoRespingo), isNotNull);
    expect(_imagemComAsset(galao), isNull);

    await tester.pumpWidget(
      envelopar(
        CenaImpactoAgua(
          key: const ValueKey('impacto-AMN5000'),
          autoPlay: false,
          mostrarReplay: false,
          garrafaAsset: galao,
          mostrarCopyMarca: true,
        ),
      ),
    );
    await tester.pump();

    expect(_imagemComAsset(galao), isNotNull);
    expect(_imagemComAsset(ams), isNull);
    expect(_imagemComAsset(assetImpactoFundo), isNotNull);
    expect(_imagemComAsset(assetImpactoRespingo), isNotNull);
  });

  testWidgets('reduced motion deixa a cena no frame final sem crash', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: envelopar(
          CenaImpactoAgua(
            autoPlay: true,
            mostrarReplay: true,
            garrafaAsset: garrafaDaCenaImpacto('AMC510'),
            mostrarCopyMarca: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Repetir animação'), findsNothing);
    expect(_imagemComAsset(garrafaDaCenaImpacto('AMC510')), isNotNull);
  });
}
