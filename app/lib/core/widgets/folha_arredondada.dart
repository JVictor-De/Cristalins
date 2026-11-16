import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sombras.dart';
import '../theme/app_spacing.dart';

/// Folha branca com raio de card e sombra do site.
class FolhaArredondada extends StatelessWidget {
  const FolhaArredondada({
    super.key,
    required this.child,
    this.padding,
    this.cor = AppColors.superficie,
    this.comSombra = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color cor;
  final bool comSombra;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(AppSpacing.raioCard),
        boxShadow: comSombra ? AppSombras.card : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.margem),
        child: child,
      ),
    );
  }
}
