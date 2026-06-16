import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Tarjeta principal del login con superficie clara y lectura inmediata.
/// Mantiene elevacion suave y borde corporativo para celular y tablet.
class LoginFormCard extends StatelessWidget {
  final Widget child;

  const LoginFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    final horizontalPad = isCompact ? 20.0 : 28.0;
    final verticalPadTop = isCompact ? 20.0 : 28.0;
    final verticalPadBottom = isCompact ? 18.0 : 24.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPad,
        verticalPadTop,
        horizontalPad,
        verticalPadBottom,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CorporateTokens.radiusLg + 2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: CorporateTokens.loginGlassCardGradient,
        ),
        border: Border.all(color: CorporateTokens.loginSurfaceBorder),
        boxShadow: CorporateTokens.loginGlassCardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  colors: [
                    CorporateTokens.mitCyanDeep,
                    CorporateTokens.mitCyan,
                    CorporateTokens.mitAmber,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -38,
            top: -38,
            child: IgnorePointer(
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CorporateTokens.mitCyan.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 6), child: child),
        ],
      ),
    );
  }
}
