import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Tarjeta principal del login con acabado glass oscuro corporativo.
/// Padding responsive para mobile y tablet.
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(CorporateTokens.radiusLg + 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
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
            border: Border.all(
              color: CorporateTokens.loginSurfaceBorder.withValues(alpha: 0.86),
            ),
            boxShadow: CorporateTokens.loginGlassCardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        CorporateTokens.loginAccent.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -36,
                top: -36,
                child: IgnorePointer(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          CorporateTokens.loginAccent.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
