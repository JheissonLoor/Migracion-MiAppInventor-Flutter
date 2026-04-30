import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/local_api_health_provider.dart';

class LocalApiStatusChip extends ConsumerWidget {
  final bool compact;

  const LocalApiStatusChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localApiHealthProvider);
    final notifier = ref.read(localApiHealthProvider.notifier);

    final available = state.available;
    final color = available ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final bgColor = color.withValues(alpha: 0.10);
    final borderColor = color.withValues(alpha: 0.30);
    final host = (state.activeBaseUrl ?? state.configuredBaseUrl).trim();
    final shortHost = host.length > 26 ? '${host.substring(0, 26)}...' : host;

    return InkWell(
      onTap: notifier.manualRefresh,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child:
                  state.checking
                      ? CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: CorporateTokens.cobalt600,
                      )
                      : DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
            ),
            const SizedBox(width: 6),
            Text(
              compact
                  ? (available ? 'Impresion OK' : 'Impresion Offline')
                  : (available
                      ? (shortHost.isEmpty
                          ? 'API local: disponible'
                          : 'API local: disponible ($shortHost)')
                      : 'API local: no disponible'),
              style: TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
