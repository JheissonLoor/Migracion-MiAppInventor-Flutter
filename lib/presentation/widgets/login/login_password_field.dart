import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Campo de credencial — minimalista, texto negro, feedback claro.
class LoginPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmit;

  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.obscureText,
    required this.errorText,
    required this.onChanged,
    required this.onToggleVisibility,
    required this.onSubmit,
  });

  @override
  State<LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<LoginPasswordField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant LoginPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final hasError = widget.errorText != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(
              Icons.badge_outlined,
              size: 15,
              color: CorporateTokens.loginTextMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Credencial de acceso',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: CorporateTokens.loginTextSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 8 : 10),

        // Campo de texto
        AnimatedContainer(
          duration: CorporateTokens.motionFast,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
            color: const Color(0xFFF7F9FC),
            border: Border.all(
              color: hasError
                  ? AppColors.error.withValues(alpha: 0.85)
                  : isFocused
                      ? CorporateTokens.loginAccent
                      : const Color(0xFFD0DBEA),
              width: isFocused ? 1.8 : 1.2,
            ),
            boxShadow: [
              if (isFocused && !hasError)
                BoxShadow(
                  color: CorporateTokens.loginAccent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              if (hasError)
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.10),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSubmit(),
            textInputAction: TextInputAction.done,
            cursorColor: CorporateTokens.cobalt800,
            style: TextStyle(
              fontSize: isCompact ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: 'Ingrese su credencial',
              hintStyle: TextStyle(
                color: const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
                fontSize: isCompact ? 14 : 15,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: isFocused
                    ? CorporateTokens.loginAccent
                    : const Color(0xFF6B7280),
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: widget.onToggleVisibility,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    widget.obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    key: ValueKey(widget.obscureText),
                    color: isFocused
                        ? CorporateTokens.loginAccent
                        : const Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                tooltip:
                    widget.obscureText ? 'Mostrar credencial' : 'Ocultar credencial',
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 14,
                vertical: isCompact ? 13 : 15,
              ),
            ),
          ),
        ),

        // Error / helper text
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: CorporateTokens.motionFast,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: hasError
              ? Row(
                  key: const ValueKey('error'),
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: AppColors.error.withValues(alpha: 0.90),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.errorText!,
                      style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.90),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    );
  }
}
