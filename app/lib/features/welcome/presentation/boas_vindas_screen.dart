import 'package:flutter/material.dart';

import 'onboarding_screen.dart';

/// Alias legado de `/boas-vindas`.
///
/// Entry canônico do marketplace é [OnboardingScreen] (splash → onboarding → shell).
/// Mantido para deep links, HML e testes que ainda usam [AppRoutes.boasVindas].
class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingScreen();
}
