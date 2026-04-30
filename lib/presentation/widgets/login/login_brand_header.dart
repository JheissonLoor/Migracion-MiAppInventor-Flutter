import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Encabezado — empresa + instrucción clara.
class LoginBrandHeader extends StatelessWidget {
  final bool compact;

  const LoginBrandHeader({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 380;

    final companySize = compact
        ? (isSmallMobile ? 22.0 : 24.0)
        : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre de empresa
        Text(
          'CoolImport S.A.C.',
          style: TextStyle(
            fontSize: companySize,
            height: 1.0,
            color: CorporateTokens.loginTextPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: compact ? 6 : 8),

        // Línea decorativa
        Container(
          height: 2,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                CorporateTokens.loginAccent,
                CorporateTokens.loginAccent.withValues(alpha: 0.30),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 10 : 14),

        // Instrucción
        Text(
          'Ingrese su credencial para acceder al sistema.',
          style: TextStyle(
            fontSize: compact ? 12.5 : 13.5,
            color: CorporateTokens.loginTextSecondary,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
