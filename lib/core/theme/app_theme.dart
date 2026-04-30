import 'package:flutter/material.dart';

// Tema base de CoolImport.
// Conserva la paleta original y agrega tokens corporativos reutilizables.
class AppColors {
  // Paleta original usada en varios modulos existentes.
  static const Color primary = Color(0xFF00007C);
  static const Color primaryLight = Color(0xFF00C6D1);
  static const Color accent = Color(0xFFF9BE00);
  static const Color textDark = Color(0xFF050E80);

  // Colores de estado.
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);

  // Superficies.
  static const Color background = Color(0xFFF5F6FA);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
}

/// Tokens semanticos — paleta "Clean Light Industrial"
///
/// Diseñada para operarios de planta: alta legibilidad, colores cálidos
/// y amigables, contrastes suaves pero claros, interfaz que no cansa la
/// vista en jornadas largas.
class CorporateTokens {
  // ── Primary blues (profundidad sin ser oscuro) ──
  static const Color navy900 = Color(0xFF1B2A4A);
  static const Color navy700 = Color(0xFF2C4170);
  static const Color cobalt800 = Color(0xFF1E3F7A);
  static const Color cobalt600 = Color(0xFF3366CC);
  static const Color cyan500 = Color(0xFF2196F3);
  static const Color cyan300 = Color(0xFF64B5F6);

  // ── Deep tones (para overlays y gradientes) ──
  static const Color indigo900 = Color(0xFF1A237E);
  static const Color indigo800 = Color(0xFF283593);
  static const Color indigo700 = Color(0xFF303F9F);
  static const Color midnight = Color(0xFF0D1B2A);

  // ── Neutrals (claros, legibles, friendly) ──
  static const Color slate700 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate300 = Color(0xFF94A3B8);
  static const Color steel300 = Color(0xFFCBD5E1);
  static const Color steel200 = Color(0xFFE2E8F0);
  static const Color goldSoft = Color(0xFFF59E0B);

  // ── Surfaces (fondo principal claro) ──
  static const Color surfaceTop = Color(0xFFF8FAFC);
  static const Color surfaceBottom = Color(0xFFEFF6FF);
  static const Color borderSoft = Color(0xFFE2E8F0);

  // ── Spacing ──
  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;

  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ── Motion ──
  static const Duration motionFast = Duration(milliseconds: 220);
  static const Duration motionNormal = Duration(milliseconds: 500);
  static const Duration motionSlow = Duration(milliseconds: 1200);

  // ── Shadows (suaves, estilo iOS/Material 3) ──
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // ── Gradients (claros, frescos) ──
  static const List<Color> primaryButtonGradient = [
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
  ];

  static const List<Color> loginBackgroundGradient = [
    Color(0xFF040B1A),
    Color(0xFF0A1730),
    Color(0xFF0F2C53),
  ];

  static const List<Color> loginHeroGradient = [
    Color(0xFF15335A),
    Color(0xFF1E5087),
    Color(0xFF2A77BA),
  ];

  static const List<Color> loginPrimaryButtonGradient = [
    Color(0xFF2E6ED0),
    Color(0xFF1A91DE),
  ];

  static const List<Color> loginGlassCardGradient = [
    Color(0xEE16263E),
    Color(0xEB13233A),
    Color(0xE6142135),
  ];

  static const List<BoxShadow> loginGlassCardShadow = [
    BoxShadow(color: Color(0x45000000), blurRadius: 36, offset: Offset(0, 18)),
    BoxShadow(color: Color(0x26020510), blurRadius: 12, offset: Offset(0, 6)),
  ];

  static const List<Color> loginDividerGlowGradient = [
    Color(0x00000000),
    Color(0x4445C7F9),
    Color(0x00000000),
  ];

  static const Color loginSurface = Color(0xFF17273F);
  static const Color loginSurfaceStrong = Color(0xFF111E34);
  static const Color loginSurfaceBorder = Color(0xFF2B4668);
  static const Color loginTextPrimary = Color(0xFFF3F8FF);
  static const Color loginTextSecondary = Color(0xFFA8BEDD);
  static const Color loginTextMuted = Color(0xFF7E97B7);
  static const Color loginAccent = Color(0xFF45C7F9);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CorporateTokens.cobalt600,
        primary: CorporateTokens.cobalt600,
        secondary: CorporateTokens.cyan500,
        surface: Colors.white,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: CorporateTokens.surfaceTop,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: CorporateTokens.navy900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: CorporateTokens.navy900,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CorporateTokens.cobalt600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          side: const BorderSide(color: CorporateTokens.borderSoft),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          borderSide: const BorderSide(color: CorporateTokens.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          borderSide: const BorderSide(color: CorporateTokens.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          borderSide: const BorderSide(
            color: CorporateTokens.cobalt600,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CorporateTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      fontFamily: 'Roboto',
    );
  }
}
