/// ============================================================================
/// INPUT DE BÚSQUEDA PREMIUM - CoolImport S.A.C.
/// ============================================================================
/// Campo de búsqueda reutilizable con botón de escanear QR,
/// botón de buscar, y botón de limpiar.
/// ============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearch;
  final VoidCallback? onScan;
  final VoidCallback? onClear;
  final bool isLoading;
  final bool showScanButton;

  const SearchInput({
    super.key,
    required this.controller,
    this.hintText = 'Ingrese código...',
    this.onSearch,
    this.onScan,
    this.onClear,
    this.isLoading = false,
    this.showScanButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Campo de texto
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF5F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch?.call(),
          ),
          const SizedBox(height: 12),

          // Botones de acción
          Row(
            children: [
              // Botón Escanear QR
              if (showScanButton) ...[
                Expanded(
                  child: _ActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'ESCANEAR QR',
                    color: AppColors.primaryLight,
                    textColor: Colors.white,
                    onTap: onScan,
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Botón Buscar
              Expanded(
                child: _ActionButton(
                  icon: isLoading ? null : Icons.search_rounded,
                  label: isLoading ? 'BUSCANDO...' : 'BUSCAR',
                  color: AppColors.primary,
                  textColor: Colors.white,
                  onTap: isLoading ? null : onSearch,
                  isLoading: isLoading,
                ),
              ),

              // Botón Limpiar
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      controller.clear();
                      onClear?.call();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(Icons.refresh_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
