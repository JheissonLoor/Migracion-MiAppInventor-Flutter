import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Contenedor principal del login con fondo claro, corporativo y liviano.
/// Evita animaciones de pantalla completa para mantener fluidez en celulares.
class LoginCorporateShell extends StatelessWidget {
  final Widget child;

  const LoginCorporateShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 600;
        final isDesktop = width >= 1024;

        final maxContentWidth =
            isDesktop
                ? 1120.0
                : isTablet
                ? 900.0
                : 450.0;

        final horizontalPadding =
            isDesktop
                ? 42.0
                : isTablet
                ? 32.0
                : 16.0;

        final verticalPadding = isTablet ? 22.0 : 16.0;

        return Stack(
          children: [
            const Positioned.fill(child: _LightLoginBackdrop()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LightLoginBackdrop extends StatelessWidget {
  const _LightLoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: CorporateTokens.loginBackgroundGradient,
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -90,
          child: _softCircle(300, const Color(0xFFBFEFFF), 0.46),
        ),
        Positioned(
          left: -130,
          bottom: -120,
          child: _softCircle(330, const Color(0xFFDDFBFF), 0.64),
        ),
        Positioned(
          right: 24,
          bottom: 70,
          child: _softCircle(120, const Color(0xFFFFF2B8), 0.28),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LoginGridPainter()),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CorporateTokens.mitCyanDeep,
                  CorporateTokens.mitCyan,
                  CorporateTokens.mitAmber,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _softCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

class _LoginGridPainter extends CustomPainter {
  const _LoginGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint =
        Paint()
          ..color = CorporateTokens.cobalt600.withValues(alpha: 0.035)
          ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final accentPaint =
        Paint()
          ..color = CorporateTokens.mitCyanDeep.withValues(alpha: 0.045)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.10, 180, 180),
        const Radius.circular(44),
      ),
      accentPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.70, 220, 140),
        const Radius.circular(36),
      ),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LoginGridPainter oldDelegate) => false;
}
