import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Botón principal con acabado premium, microinteracciones y estados de carga.
class LoginPrimaryButton extends StatefulWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  const LoginPrimaryButton({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<LoginPrimaryButton> createState() => _LoginPrimaryButtonState();
}

class _LoginPrimaryButtonState extends State<LoginPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPress = widget.enabled && !widget.isLoading;
    final lift = _isHovering && canPress ? -2.0 : 0.0;
    final pressScale = _isPressed && canPress ? 0.97 : 1.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth < 380 ? 50.0 : 56.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapDown: canPress
            ? (_) {
                setState(() => _isPressed = true);
                HapticFeedback.lightImpact();
              }
            : null,
        onTapUp: canPress
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: pressScale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: CorporateTokens.motionFast,
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(0, lift, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CorporateTokens.radiusMd),
              boxShadow:
                  canPress
                      ? [
                          BoxShadow(
                            color: const Color(0xFF117FD4).withValues(
                              alpha: _isPressed ? 0.25 : (_isHovering ? 0.42 : 0.32),
                            ),
                            blurRadius: _isPressed ? 12 : (_isHovering ? 24 : 18),
                            offset: Offset(0, _isPressed ? 6 : (_isHovering ? 12 : 10)),
                          ),
                        ]
                      : const [],
            ),
            child: SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(CorporateTokens.radiusMd),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CorporateTokens.radiusMd),
                    gradient:
                        canPress
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  _isHovering
                                      ? const [Color(0xFF2A76D6), Color(0xFF1CA6E8)]
                                      : CorporateTokens.loginPrimaryButtonGradient,
                            )
                            : LinearGradient(
                              colors: [
                                CorporateTokens.loginSurfaceStrong.withValues(
                                  alpha: 0.82,
                                ),
                                CorporateTokens.loginSurfaceStrong.withValues(
                                  alpha: 0.82,
                                ),
                              ],
                            ),
                    border: Border.all(
                      color:
                          canPress
                              ? CorporateTokens.loginAccent.withValues(alpha: 0.35)
                              : Colors.transparent,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (canPress && !widget.isLoading)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _shineController,
                            builder: (context, child) {
                              final travel = (_shineController.value * 1.8) - 0.4;
                              return FractionalTranslation(
                                translation: Offset(travel, 0),
                                child: Transform.rotate(
                                  angle: -math.pi / 12,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              width: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.00),
                                    Colors.white.withValues(alpha: 0.22),
                                    Colors.white.withValues(alpha: 0.00),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: CorporateTokens.motionFast,
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child:
                              widget.isLoading
                                  ? const Row(
                                    key: ValueKey('loading'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.1,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Validando credencial...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  )
                                  : const Row(
                                    key: ValueKey('normal'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
