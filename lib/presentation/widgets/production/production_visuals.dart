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

enum OperationSignalLevel { neutral, ready, warning, error }

class OperationStepData {
  final String label;
  final IconData icon;
  final bool done;
  final bool active;

  const OperationStepData({
    required this.label,
    required this.icon,
    this.done = false,
    this.active = false,
  });
}

class OperationSummaryItem {
  final String label;
  final String value;
  final IconData icon;

  const OperationSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class OperationFlowGuide extends StatelessWidget {
  final String title;
  final String statusLabel;
  final String helperText;
  final OperationSignalLevel signal;
  final List<OperationStepData> steps;
  final List<OperationSummaryItem> summary;
  final Color accentColor;

  const OperationFlowGuide({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.helperText,
    required this.signal,
    required this.steps,
    this.summary = const [],
    this.accentColor = CorporateTokens.cobalt600,
  });

  @override
  Widget build(BuildContext context) {
    final signalColor = _signalColor(signal);
    return AnimatedContainer(
      duration: CorporateTokens.motionFast,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: signalColor.withValues(alpha: 0.22)),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SignalBeacon(color: signalColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: CorporateTokens.navy900,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helperText,
                      style: const TextStyle(
                        color: CorporateTokens.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: signalColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: signalColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _StepGrid(steps: steps, accentColor: accentColor),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SummaryGrid(summary: summary, accentColor: accentColor),
          ],
        ],
      ),
    );
  }

  Color _signalColor(OperationSignalLevel level) {
    switch (level) {
      case OperationSignalLevel.ready:
        return const Color(0xFF16A34A);
      case OperationSignalLevel.warning:
        return const Color(0xFFF59E0B);
      case OperationSignalLevel.error:
        return const Color(0xFFDC2626);
      case OperationSignalLevel.neutral:
        return CorporateTokens.slate500;
    }
  }
}

class _SignalBeacon extends StatelessWidget {
  final Color color;

  const _SignalBeacon({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: CorporateTokens.motionNormal,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.80, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _StepGrid extends StatelessWidget {
  final List<OperationStepData> steps;
  final Color accentColor;

  const _StepGrid({required this.steps, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 760
                ? steps.length
                : (constraints.maxWidth >= 480 ? 2 : 1);
        final safeColumns = columns.clamp(1, steps.length).toInt();
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - ((safeColumns - 1) * spacing)) /
            safeColumns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              steps
                  .map(
                    (step) => SizedBox(
                      width: width,
                      child: _StepTile(step: step, accentColor: accentColor),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  final OperationStepData step;
  final Color accentColor;

  const _StepTile({required this.step, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color =
        step.done
            ? const Color(0xFF16A34A)
            : (step.active ? accentColor : CorporateTokens.slate300);

    return AnimatedContainer(
      duration: CorporateTokens.motionFast,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color:
            step.active
                ? accentColor.withValues(alpha: 0.08)
                : CorporateTokens.surfaceTop,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color:
              step.done || step.active
                  ? color.withValues(alpha: 0.34)
                  : CorporateTokens.borderSoft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              step.done ? Icons.check_rounded : step.icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<OperationSummaryItem> summary;
  final Color accentColor;

  const _SummaryGrid({required this.summary, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 720
                ? 4
                : (constraints.maxWidth >= 460 ? 2 : 1);
        final safeColumns = columns.clamp(1, summary.length).toInt();
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - ((safeColumns - 1) * spacing)) /
            safeColumns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              summary
                  .map(
                    (item) => SizedBox(
                      width: width,
                      child: _SummaryTile(item: item, accentColor: accentColor),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final OperationSummaryItem item;
  final Color accentColor;

  const _SummaryTile({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final value = item.value.trim().isEmpty ? '-' : item.value.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 16, color: accentColor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CorporateTokens.slate500,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
