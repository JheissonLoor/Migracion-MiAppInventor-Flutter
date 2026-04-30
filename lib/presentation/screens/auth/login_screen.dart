import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login/login_brand_header.dart';
import '../../widgets/login/login_corporate_shell.dart';
import '../../widgets/login/login_form_card.dart';
import '../../widgets/login/login_hero_visual.dart';
import '../../widgets/login/login_password_field.dart';
import '../../widgets/login/login_primary_button.dart';

// Login enterprise mobile/web con motion pulido.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _fieldTouched = false;
  bool _isNavigating = false;
  String? _inlineError;

  late final AnimationController _entryController;
  late final AnimationController _successController;
  late final Animation<double> _screenFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _formOpacity;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _screenFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _heroOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.08, 0.82, curve: Curves.easeOut),
    );
    _formOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.24, 1.0, curve: Curves.easeOut),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _successController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      if (next.status == AuthStatus.authenticated) {
        final cargo = next.user?.cargo.toUpperCase() ?? '';
        _playSuccessTransition(cargo);
        return;
      }

      if (next.status == AuthStatus.error) {
        setState(() {
          _inlineError = _normalizeBackendError(next.errorMessage);
        });
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          LoginCorporateShell(
            child: FadeTransition(
              opacity: _screenFade,
              child: SlideTransition(
                position: _cardSlide,
                child: LoginFormCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final splitLayout = constraints.maxWidth >= 700;
                      if (splitLayout) {
                        return _buildTabletContent(isLoading: isLoading);
                      }
                      return _buildMobileContent(isLoading: isLoading);
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_isNavigating) Positioned.fill(child: _buildSuccessOverlay()),
        ],
      ),
    );
  }

  Widget _buildTabletContent({required bool isLoading}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: FadeTransition(
            opacity: _heroOpacity,
            child: const LoginHeroVisual(),
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          flex: 9,
          child: FadeTransition(
            opacity: _formOpacity,
            child: _buildFormArea(isLoading: isLoading, compact: false),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContent({required bool isLoading}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeTransition(
          opacity: _heroOpacity,
          child: const LoginHeroVisual(compact: true),
        ),
        const SizedBox(height: 18),
        FadeTransition(
          opacity: _formOpacity,
          child: _buildFormArea(isLoading: isLoading, compact: true),
        ),
      ],
    );
  }

  Widget _buildFormArea({required bool isLoading, required bool compact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: Bienvenido + CoolImport + instrucción
        _StaggerReveal(
          parent: _entryController,
          begin: 0.24,
          end: 0.54,
          child: LoginBrandHeader(compact: compact),
        ),
        SizedBox(height: compact ? 18 : 24),

        // Campo de credencial
        _StaggerReveal(
          parent: _entryController,
          begin: 0.34,
          end: 0.70,
          child: LoginPasswordField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            errorText: _inlineError,
            onChanged: _handlePasswordChanged,
            onToggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            onSubmit: _submitLogin,
          ),
        ),
        SizedBox(height: compact ? 16 : 20),

        // Botón de iniciar sesión
        _StaggerReveal(
          parent: _entryController,
          begin: 0.48,
          end: 0.84,
          child: LoginPrimaryButton(
            isLoading: isLoading,
            enabled: !_hasValidationError,
            onPressed: _submitLogin,
          ),
        ),
        SizedBox(height: compact ? 14 : 18),

        // Badge seguridad — CENTRADO
        _StaggerReveal(
          parent: _entryController,
          begin: 0.58,
          end: 0.90,
          child: _buildSecurityBadge(),
        ),
        SizedBox(height: compact ? 10 : 14),

        // Footer
        _StaggerReveal(
          parent: _entryController,
          begin: 0.66,
          end: 0.98,
          child: _buildFooterSignature(),
        ),
      ],
    );
  }

  /// Badge de seguridad — centrado, compacto, elegante.
  Widget _buildSecurityBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CorporateTokens.loginAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: CorporateTokens.loginAccent.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 14,
              color: CorporateTokens.loginAccent.withValues(alpha: 0.80),
            ),
            const SizedBox(width: 6),
            Text(
              'Conexión segura y encriptada',
              style: TextStyle(
                fontSize: 11,
                color: CorporateTokens.loginTextMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSignature() {
    return const Text(
      'CoolImport S.A.C. © 2026',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        color: CorporateTokens.loginTextMuted,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    final fade = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    );
    final scale = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutBack),
    );

    return IgnorePointer(
      child: FadeTransition(
        opacity: fade,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CorporateTokens.loginSurfaceStrong.withValues(alpha: 0.94),
                CorporateTokens.loginSurface.withValues(alpha: 0.94),
              ],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF16A34A),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Acceso concedido',
                    style: TextStyle(
                      color: CorporateTokens.loginTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasValidationError {
    final validationMessage = _validatePassword(
      _passwordController.text,
      forceRequiredMessage: true,
    );
    return validationMessage != null;
  }

  void _handlePasswordChanged(String value) {
    setState(() {
      if (value.trim().isNotEmpty) _fieldTouched = true;

      _inlineError = _validatePassword(
        value,
        forceRequiredMessage: _fieldTouched,
      );
    });
  }

  void _submitLogin() {
    FocusScope.of(context).unfocus();

    final validationError = _validatePassword(
      _passwordController.text,
      forceRequiredMessage: true,
    );

    setState(() {
      _fieldTouched = true;
      _inlineError = validationError;
    });

    if (validationError != null) return;

    ref.read(authProvider.notifier).login(_passwordController.text.trim());
  }

  Future<void> _playSuccessTransition(String cargo) async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    await _successController.forward();
    if (!mounted) return;

    if (cargo == 'ADMINISTRADOR' || cargo == 'PCP') {
      Navigator.pushReplacementNamed(context, '/admin_home');
    } else {
      Navigator.pushReplacementNamed(context, '/operario_home');
    }
  }

  String? _validatePassword(
    String value, {
    required bool forceRequiredMessage,
  }) {
    final input = value.trim();

    if (input.isEmpty) {
      return forceRequiredMessage ? 'Ingrese su credencial para continuar.' : null;
    }
    if (input.length < 4) {
      return 'La credencial debe tener al menos 4 caracteres.';
    }
    return null;
  }

  String _normalizeBackendError(String? rawMessage) {
    final message = (rawMessage ?? '').replaceAll('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'No fue posible validar la credencial.';
    }
    return message;
  }
}

class _StaggerReveal extends StatelessWidget {
  final AnimationController parent;
  final double begin;
  final double end;
  final Widget child;

  const _StaggerReveal({
    required this.parent,
    required this.begin,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: parent,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
