import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Hero visual corporativo — limpio, solo imagen con overlay elegante.
class LoginHeroVisual extends StatefulWidget {
  final bool compact;

  const LoginHeroVisual({super.key, this.compact = false});

  @override
  State<LoginHeroVisual> createState() => _LoginHeroVisualState();
}

class _LoginHeroVisualState extends State<LoginHeroVisual>
    with TickerProviderStateMixin {
  static const String _heroAssetPath = 'assets/images/logo_pcp.png';

  late final AnimationController _scanController;
  late final AnimationController _glowController;
  double _tiltX = 0;
  double _tiltY = 0;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Altura adaptable al viewport
    double heroHeight;
    if (widget.compact) {
      heroHeight = (screenHeight * 0.22).clamp(140.0, 200.0);
    } else {
      heroHeight = (screenHeight * 0.36).clamp(230.0, 320.0);
    }

    final tiltScale = _hovering ? 1.015 : 1.0;
    final transform =
        Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tiltX)
          ..rotateY(_tiltY)
          ..scale(tiltScale, tiltScale, 1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:
          (_) => setState(() {
            _hovering = false;
            _tiltX = 0;
            _tiltY = 0;
          }),
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(event.position);
        final nx = (local.dx / box.size.width) - 0.5;
        final ny = (local.dy / box.size.height) - 0.5;
        setState(() {
          _tiltX = ny * -0.06;
          _tiltY = nx * 0.06;
        });
      },
      child: AnimatedContainer(
        duration: CorporateTokens.motionFast,
        curve: Curves.easeOut,
        transform: transform,
        transformAlignment: Alignment.center,
        height: heroHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusLg),
          border: Border.all(
            color: CorporateTokens.loginAccent.withValues(
              alpha: _hovering ? 0.40 : 0.22,
            ),
            width: _hovering ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: CorporateTokens.cobalt800.withValues(
                alpha: _hovering ? 0.50 : 0.35,
              ),
              blurRadius: _hovering ? 34 : 26,
              offset: Offset(0, _hovering ? 16 : 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusLg),
          child: Stack(
            children: [
              // Imagen de fondo
              Positioned.fill(child: _buildHeroImage()),

              // Overlay gradiente sutil inferior
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A1730).withValues(alpha: 0.55),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Scan sweep animado
              Positioned.fill(
                child: _AnimatedSweep(controller: _scanController),
              ),

              // Glow pulsante sutil
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final glow = 0.06 + (_glowController.value * 0.10);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          CorporateTokens.radiusLg,
                        ),
                        gradient: RadialGradient(
                          center: const Alignment(0.5, -0.3),
                          radius: 1.2,
                          colors: [
                            CorporateTokens.loginAccent.withValues(alpha: glow),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Solo un badge pequeño "PCP" abajo a la izquierda
              Positioned(
                left: 14,
                bottom: 12,
                child: _buildPcpBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Image.asset(
      _heroAssetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/images/fondo.jpg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: CorporateTokens.loginHeroGradient,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPcpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: const Text(
        'Plataforma PCP',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AnimatedSweep extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedSweep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final y = (controller.value * 1.3) - 0.2;
        return Align(
          alignment: Alignment(0, y),
          child: IgnorePointer(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    CorporateTokens.loginAccent.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
