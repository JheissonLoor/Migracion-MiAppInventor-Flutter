/// ============================================================================
/// CARD PREMIUM - CoolImport S.A.C.
/// ============================================================================
/// Tarjeta reutilizable con múltiples variantes:
///   - InfoCard: para mostrar datos clave-valor
///   - ResultCard: para resultados de búsqueda con colores de estado
///   - ActionCard: tarjeta con botón de acción
/// ============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Tarjeta base con efecto glass-morphism sutil
class CoolImportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double borderRadius;

  const CoolImportCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Tarjeta para mostrar información clave-valor (ej: Código, Ubicación, etc.)
class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final bool isLarge;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return CoolImportCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 15,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de resultado con indicador lateral de color
class ResultCard extends StatelessWidget {
  final List<ResultField> fields;
  final Color statusColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ResultCard({
    super.key,
    required this.fields,
    this.statusColor = AppColors.primary,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CoolImportCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // Indicador lateral de color
          Container(
            width: 5,
            height: fields.length * 28.0 + 24,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Campos de datos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            field.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            field.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: field.isBold ? FontWeight.bold : FontWeight.normal,
                              color: field.color ?? AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

/// Campo individual de un ResultCard
class ResultField {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const ResultField({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });
}

/// Sección con título para agrupar información
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
