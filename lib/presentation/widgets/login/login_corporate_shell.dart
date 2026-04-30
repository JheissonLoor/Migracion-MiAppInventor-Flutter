import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Contenedor principal del login con fondo enterprise oscuro y animado.
/// Breakpoints optimizados: mobile < 600, tablet 600-1024, desktop > 1024.
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

        final maxContentWidth = isDesktop
            ? 1120.0
            : isTablet
              ? 900.0
              : 450.0;

        final horizontalPadding = isDesktop
            ? 42.0
            : isTablet
              ? 32.0
              : 16.0;

        final verticalPadding = isTablet ? 22.0 : 16.0;

        return Stack(
          children: [
            const Positioned.fill(child: _AnimatedBackdrop()),
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

class _AnimatedBackdrop extends StatefulWidget {
  const _AnimatedBackdrop();

  @override
  State<_AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<_AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.04, -0.95),
                    radius: 1.15,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _LoginWavePainter(time: t)),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _LoginDotsPainter(time: t)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 172,
              child: Opacity(
                opacity: 0.22 + (math.sin(t * math.pi * 2) * 0.08),
                child: Container(
                  height: 1.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: CorporateTokens.loginDividerGlowGradient,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF175B9A),
                      Color(0xFF2A82C3),
                      Color(0xFF43C3F5),
                    ],
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

class _LoginWavePainter extends CustomPainter {
  final double time;

  _LoginWavePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final glow1 =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              const Color(0xFF2A89D6).withValues(alpha: 0.22),
              const Color(0xFF2A89D6).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.15 + math.sin(time * math.pi * 2) * 30,
                size.height * 0.2 + math.cos(time * math.pi * 2) * 20,
              ),
              radius: 280,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.15 + math.sin(time * math.pi * 2) * 30,
        size.height * 0.2 + math.cos(time * math.pi * 2) * 20,
      ),
      280,
      glow1,
    );

    final glow2 =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              const Color(0xFF45C7F9).withValues(alpha: 0.16),
              const Color(0xFF45C7F9).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(
                size.width * 0.80 + math.cos((time + 0.3) * math.pi * 2) * 25,
                size.height * 0.75 + math.sin((time + 0.3) * math.pi * 2) * 18,
              ),
              radius: 220,
            ),
          );
    canvas.drawCircle(
      Offset(
        size.width * 0.80 + math.cos((time + 0.3) * math.pi * 2) * 25,
        size.height * 0.75 + math.sin((time + 0.3) * math.pi * 2) * 18,
      ),
      220,
      glow2,
    );

    final wavePaint =
        Paint()
          ..color = CorporateTokens.loginAccent.withValues(alpha: 0.09)
          ..style = PaintingStyle.fill;

    final wave = Path();
    wave.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y =
          size.height * 0.78 +
          math.sin((x / size.width * 2 * math.pi) + (time * math.pi * 2)) * 20 +
          math.cos((x / size.width * 3 * math.pi) + (time * math.pi * 3)) * 8;
      wave.lineTo(x, y);
    }
    wave.lineTo(size.width, size.height);
    wave.close();
    canvas.drawPath(wave, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _LoginWavePainter old) => old.time != time;
}

class _LoginDotsPainter extends CustomPainter {
  final double time;

  _LoginDotsPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint =
        Paint()
          ..color = CorporateTokens.loginAccent.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int i = 0; i < 16; i++) {
      final n = i / 16.0;
      final px =
          (n * size.width * 1.3) -
          (size.width * 0.15) +
          math.sin((time + n * 2.8) * math.pi * 2) * 22;
      final py =
          size.height * (0.12 + n * 0.68) +
          math.cos((time + n * 2.2) * math.pi * 2) * 16;
      final r = 2.0 + math.sin((time + n) * math.pi * 2) * 0.9;

      canvas.drawCircle(Offset(px, py), r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginDotsPainter old) => old.time != time;
}
