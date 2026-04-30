import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Fondo reutilizable para pantallas internas — estilo "Clean Light Industrial".
///
/// Gradiente blanco-azul suave con ondas delicadas y particulas flotantes.
/// Diseñado para no cansar la vista del operario en jornadas largas.
class EnterpriseBackdrop extends StatefulWidget {
  final double overlayOpacity;

  const EnterpriseBackdrop({super.key, this.overlayOpacity = 0.0});

  @override
  State<EnterpriseBackdrop> createState() => _EnterpriseBackdropState();
}

class _EnterpriseBackdropState extends State<EnterpriseBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
            // ── Base gradient: white → soft blue ──
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CorporateTokens.surfaceTop,
                      CorporateTokens.surfaceBottom,
                      Color(0xFFF0F4FF),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // ── Soft wave shapes ──
            Positioned.fill(
              child: CustomPaint(
                painter: _SoftWavePainter(time: t),
              ),
            ),

            // ── Floating particles ──
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FloatingDotsPainter(time: t),
                ),
              ),
            ),

            // ── Subtle top accent line ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA),
                      Color(0xFF93C5FD),
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

/// Ondas suaves orgánicas en el fondo
class _SoftWavePainter extends CustomPainter {
  final double time;

  _SoftWavePainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    // Wave 1: very subtle blue at bottom
    final wave1Paint = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final wave1 = Path();
    wave1.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height * 0.72 +
          math.sin((x / size.width * 2 * math.pi) + (time * math.pi * 2)) * 24 +
          math.sin((x / size.width * 4 * math.pi) + (time * math.pi * 4)) * 8;
      wave1.lineTo(x, y);
    }
    wave1.lineTo(size.width, size.height);
    wave1.close();
    canvas.drawPath(wave1, wave1Paint);

    // Wave 2: even more subtle
    final wave2Paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final wave2 = Path();
    wave2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height * 0.82 +
          math.sin((x / size.width * 3 * math.pi) + (time * math.pi * 2) + 1.5) * 18 +
          math.cos((x / size.width * 2 * math.pi) + (time * math.pi * 3)) * 10;
      wave2.lineTo(x, y);
    }
    wave2.lineTo(size.width, size.height);
    wave2.close();
    canvas.drawPath(wave2, wave2Paint);

    // Subtle circle glow at top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF3B82F6).withValues(alpha: 0.06),
          const Color(0xFF3B82F6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.85 + math.sin(time * math.pi * 2) * 20,
          size.height * 0.15 + math.cos(time * math.pi * 2) * 15,
        ),
        radius: 200,
      ));
    canvas.drawCircle(
      Offset(
        size.width * 0.85 + math.sin(time * math.pi * 2) * 20,
        size.height * 0.15 + math.cos(time * math.pi * 2) * 15,
      ),
      200,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SoftWavePainter old) => old.time != time;
}

/// Puntos flotantes decorativos muy sutiles
class _FloatingDotsPainter extends CustomPainter {
  final double time;

  _FloatingDotsPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = CorporateTokens.cyan500.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 12; i++) {
      final n = i / 12.0;
      final px = (n * size.width * 1.2) - (size.width * 0.1) +
          math.sin((time + n * 3) * math.pi * 2) * 20;
      final py = size.height * (0.15 + n * 0.65) +
          math.cos((time + n * 2.5) * math.pi * 2) * 15;
      final radius = 1.8 + math.sin((time + n) * math.pi * 2) * 0.8;

      canvas.drawCircle(Offset(px, py), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingDotsPainter old) => old.time != time;
}
