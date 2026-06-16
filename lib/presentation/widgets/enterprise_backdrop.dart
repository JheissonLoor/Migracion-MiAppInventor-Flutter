import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Fondo reutilizable para pantallas internas.
///
/// Mantiene el lenguaje visual familiar del MIT App Inventor (cyan + PCP),
/// pero sin animacion continua para evitar lag en tablets industriales.
class EnterpriseBackdrop extends StatelessWidget {
  final double overlayOpacity;

  const EnterpriseBackdrop({super.key, this.overlayOpacity = 0.0});

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
                colors: [
                  Color(0xFFE9FEFF),
                  Color(0xFFC8F6F8),
                  Color(0xFFEFF6FF),
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _LegacyPatternPainter()),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _OperationalGlowPainter()),
            ),
          ),
        ),
        if (overlayOpacity > 0)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: overlayOpacity.clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 5,
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
}

class _LegacyPatternPainter extends CustomPainter {
  const _LegacyPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: CorporateTokens.mitCyanDeep.withValues(alpha: 0.052),
      fontSize: 30,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.4,
    );

    for (double y = -40; y < size.height + 80; y += 96) {
      for (double x = -50; x < size.width + 140; x += 142) {
        final offset = math.sin(y / 180) * 3;
        final painter = TextPainter(
          text: TextSpan(text: 'PCP', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x + offset, y);
        canvas.rotate(-0.04);
        painter.paint(canvas, Offset.zero);
        canvas.restore();

        final gearPaint =
            Paint()
              ..color = CorporateTokens.mitCyanDeep.withValues(alpha: 0.032)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4;
        final center = Offset(x + 88 + offset, y + 15);
        canvas.drawCircle(center, 13, gearPaint);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final p1 =
              center + Offset(math.cos(angle) * 15, math.sin(angle) * 15);
          final p2 =
              center + Offset(math.cos(angle) * 20, math.sin(angle) * 20);
          canvas.drawLine(p1, p2, gearPaint);
        }
      }
    }

    final amberPaint =
        Paint()
          ..color = CorporateTokens.mitAmber.withValues(alpha: 0.09)
          ..style = PaintingStyle.fill;
    final amberPath =
        Path()
          ..moveTo(0, size.height * 0.78)
          ..quadraticBezierTo(
            size.width * 0.28,
            size.height * 0.70,
            size.width * 0.62,
            size.height * 0.82,
          )
          ..quadraticBezierTo(
            size.width * 0.84,
            size.height * 0.91,
            size.width,
            size.height * 0.84,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
    canvas.drawPath(amberPath, amberPaint);
  }

  @override
  bool shouldRepaint(covariant _LegacyPatternPainter oldDelegate) => false;
}

class _OperationalGlowPainter extends CustomPainter {
  const _OperationalGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cyanGlow =
        Paint()
          ..shader = RadialGradient(
            colors: [
              CorporateTokens.mitCyan.withValues(alpha: 0.16),
              CorporateTokens.mitCyan.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.16, size.height * 0.22),
              radius: 240,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.22),
      240,
      cyanGlow,
    );

    final navyGlow =
        Paint()
          ..shader = RadialGradient(
            colors: [
              CorporateTokens.cobalt600.withValues(alpha: 0.08),
              CorporateTokens.cobalt600.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.86, size.height * 0.18),
              radius: 220,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.18),
      220,
      navyGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _OperationalGlowPainter oldDelegate) => false;
}
