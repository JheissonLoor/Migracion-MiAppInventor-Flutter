import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'enterprise_backdrop.dart';

/// Guard de autenticacion/rol para rutas sensibles.
///
/// - Si no hay sesion: muestra pantalla de acceso y lleva al login.
/// - Si hay sesion pero rol no autorizado: bloquea modulo y permite volver.
/// - Si cumple condiciones: renderiza el child real.
class AuthRoleGuard extends ConsumerWidget {
  final Widget child;
  final String moduleName;
  final List<String> allowedRoles;
  final List<String> extraAllowedRoles;

  const AuthRoleGuard({
    super.key,
    required this.child,
    required this.moduleName,
    this.allowedRoles = const [],
    this.extraAllowedRoles = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return const _GuardLoadingScreen();
    }

    final user = authState.user;
    if (authState.status != AuthStatus.authenticated || user == null) {
      return _GuardStatusScreen(
        title: 'Sesion requerida',
        message:
            'Debe iniciar sesion para acceder a "$moduleName" de forma segura.',
        icon: Icons.lock_outline_rounded,
        primaryLabel: 'Ir al login',
        onPrimary: () => Navigator.pushReplacementNamed(context, '/login'),
      );
    }

    if (allowedRoles.isEmpty && extraAllowedRoles.isEmpty) {
      return child;
    }

    final roleUpper = user.cargo.toUpperCase();
    final allowedUpper = {
      ...allowedRoles.map((role) => role.toUpperCase()),
      ...extraAllowedRoles.map((role) => role.toUpperCase()),
    };

    if (allowedUpper.contains(roleUpper)) {
      return child;
    }

    final fallbackRoute =
        AppConstants.rolesAdmin.contains(roleUpper)
            ? '/admin_home'
            : '/operario_home';

    return _GuardStatusScreen(
      title: 'Acceso restringido',
      message:
          'El rol ${user.cargo} no tiene permiso para ingresar a "$moduleName".',
      icon: Icons.gpp_bad_rounded,
      primaryLabel: 'Volver al inicio',
      onPrimary: () => Navigator.pushReplacementNamed(context, fallbackRoute),
      secondaryLabel: 'Cerrar sesion',
      onSecondary: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
    );
  }
}

class _GuardLoadingScreen extends StatelessWidget {
  const _GuardLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CorporateTokens.borderSoft),
                boxShadow: CorporateTokens.cardShadow,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Validando acceso...',
                    style: TextStyle(
                      color: CorporateTokens.navy900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardStatusScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _GuardStatusScreen({
    required this.title,
    required this.message,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: 560,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: CorporateTokens.borderSoft),
                    boxShadow: CorporateTokens.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: CorporateTokens.cobalt600.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: CorporateTokens.cobalt600,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CorporateTokens.navy900,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CorporateTokens.slate700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onPrimary,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(primaryLabel),
                            ),
                          ),
                          if (secondaryLabel != null &&
                              onSecondary != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onSecondary,
                                child: Text(secondaryLabel!),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
