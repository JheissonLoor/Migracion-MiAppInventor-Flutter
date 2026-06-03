import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProductionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onBack;
  final Widget? trailing;
  final Color accentColor;

  const ProductionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onBack,
    this.trailing,
    this.accentColor = CorporateTokens.cobalt600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: CorporateTokens.borderSoft),
            ),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: CorporateTokens.navy900,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [CorporateTokens.navy900, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class ProductionStatusBanner extends StatelessWidget {
  final String? message;
  final String? errorMessage;

  const ProductionStatusBanner({super.key, this.message, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage?.trim().isNotEmpty == true;
    final hasInfo = message?.trim().isNotEmpty == true;
    if (!hasError && !hasInfo) return const SizedBox.shrink();

    final isError = hasError;
    final text = hasError ? errorMessage!.trim() : message!.trim();
    final color = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFE8F7EF);
    final borderColor =
        isError ? const Color(0xFFFCA5A5) : const Color(0xFF9DE8B5);

    return AnimatedSwitcher(
      duration: CorporateTokens.motionFast,
      child: Container(
        key: ValueKey('$isError$text'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  final Color accentColor;

  const ProductionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.children,
    this.accentColor = CorporateTokens.cobalt600,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  CorporateTokens.cyan500.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: CorporateTokens.navy900,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: CorporateTokens.slate500,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
