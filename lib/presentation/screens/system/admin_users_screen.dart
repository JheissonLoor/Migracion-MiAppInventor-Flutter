import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/admin_users_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/enterprise_backdrop.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _searchController;
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;

  late final AnimationController _entryController;

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(adminUsersProvider);
    _searchController = TextEditingController(text: initial.searchUser);
    _userController = TextEditingController(text: initial.user);
    _passwordController = TextEditingController(text: initial.password);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);
    final actor = ref.watch(authProvider).user?.usuario ?? 'ADMIN';

    ref.listen<AdminUsersState>(adminUsersProvider, (previous, next) {
      if (!mounted) return;
      _syncFromState(next);
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _StaggerSection(
                    controller: _entryController,
                    begin: 0.02,
                    end: 0.24,
                    child: _buildHeader(context),
                  ),
                  const SizedBox(height: 10),
                  _StaggerSection(
                    controller: _entryController,
                    begin: 0.08,
                    end: 0.32,
                    child: _buildStatusBanner(state),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.14,
                              end: 0.40,
                              child: _buildSearchCard(state, notifier),
                            ),
                            const SizedBox(height: 10),
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.20,
                              end: 0.50,
                              child: _buildFormCard(state, notifier),
                            ),
                            const SizedBox(height: 10),
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.26,
                              end: 0.58,
                              child: _buildActionCard(state, notifier, actor),
                            ),
                            const SizedBox(height: 10),
                            _StaggerSection(
                              controller: _entryController,
                              begin: 0.34,
                              end: 0.68,
                              child: _buildSecurityFooter(actor),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: CorporateTokens.borderSoft),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: CorporateTokens.navy900,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrar Usuarios',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Alta, edicion y baja de usuarios operativos',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(AdminUsersState state) {
    final hasError = state.errorMessage?.trim().isNotEmpty == true;
    final hasMessage = state.message?.trim().isNotEmpty == true;

    if (!hasError && !hasMessage) {
      return const SizedBox.shrink();
    }

    final isError = hasError;
    final text = hasError ? state.errorMessage! : state.message!;
    final bgColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final borderColor =
        isError ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC);
    final iconColor =
        isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CorporateTokens.navy900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(AdminUsersState state, AdminUsersNotifier notifier) {
    return _buildCard(
      title: 'Busqueda de usuario',
      children: [
        TextFormField(
          controller: _searchController,
          onChanged: notifier.setSearchUser,
          style: const TextStyle(color: CorporateTokens.navy900),
          decoration: _inputDecoration(
            label: 'Usuario a buscar',
            hint: 'Ejemplo: jrodriguez',
            icon: Icons.search_rounded,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: state.isBusy ? null : notifier.buscarUsuario,
                icon:
                    state.status == AdminUsersStatus.searching
                        ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.person_search_rounded),
                label: const Text('Buscar usuario'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed:
                  state.isBusy
                      ? null
                      : () {
                        notifier.prepararNuevo();
                        _formKey.currentState?.reset();
                      },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(AdminUsersState state, AdminUsersNotifier notifier) {
    final rolSeleccionado = _resolveRol(state.rol);

    return _buildCard(
      title:
          state.existingUser ? 'Usuario encontrado' : 'Formulario de usuario',
      children: [
        TextFormField(
          controller: _userController,
          onChanged: notifier.setUser,
          textInputAction: TextInputAction.next,
          validator: (value) => _required(value, 'usuario'),
          style: const TextStyle(color: CorporateTokens.navy900),
          decoration: _inputDecoration(
            label: 'Usuario',
            hint: 'Nombre de usuario',
            icon: Icons.person_rounded,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          onChanged: notifier.setPassword,
          textInputAction: TextInputAction.done,
          validator: (value) => _required(value, 'contrasena'),
          obscureText: !_showPassword,
          style: const TextStyle(color: CorporateTokens.navy900),
          decoration: _inputDecoration(
            label: 'Contrasena',
            hint: 'Clave del usuario',
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: CorporateTokens.slate500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: rolSeleccionado,
          items:
              adminUsersRoles
                  .map(
                    (rol) =>
                        DropdownMenuItem<String>(value: rol, child: Text(rol)),
                  )
                  .toList(),
          onChanged:
              state.isBusy
                  ? null
                  : (value) => notifier.setRol((value ?? '').trim()),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Seleccione cargo';
            }
            return null;
          },
          decoration: _inputDecoration(
            label: 'Cargo',
            hint: 'Seleccione el cargo',
            icon: Icons.badge_rounded,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: CorporateTokens.surfaceBottom,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CorporateTokens.borderSoft),
          ),
          child: Text(
            state.existingUser
                ? 'Modo edicion: usuario cargado desde backend legacy.'
                : 'Modo alta: complete datos para registrar nuevo usuario.',
            style: const TextStyle(
              color: CorporateTokens.slate700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    AdminUsersState state,
    AdminUsersNotifier notifier,
    String actor,
  ) {
    return _buildCard(
      title: 'Acciones operativas',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 160,
              child: _ActionButton(
                label: 'Registrar',
                icon: Icons.person_add_alt_1_rounded,
                busy: state.status == AdminUsersStatus.saving,
                enabled: !state.isBusy,
                onTap: () => _onRegistrar(notifier, actor),
              ),
            ),
            SizedBox(
              width: 170,
              child: _ActionButton(
                label: 'Guardar cambios',
                icon: Icons.save_as_rounded,
                busy: state.status == AdminUsersStatus.saving,
                enabled: !state.isBusy && state.existingUser,
                color: const Color(0xFF0D9488),
                onTap: () => _onEditar(notifier, actor),
              ),
            ),
            SizedBox(
              width: 150,
              child: _ActionButton(
                label: 'Eliminar',
                icon: Icons.delete_forever_rounded,
                busy: state.status == AdminUsersStatus.deleting,
                enabled: !state.isBusy && state.existingUser,
                color: const Color(0xFFDC2626),
                onTap: () => _onEliminar(notifier, actor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityFooter(String actor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sesion operativa: $actor',
            style: const TextStyle(
              color: CorporateTokens.slate700,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acceso seguro y encriptado',
            style: TextStyle(
              color: CorporateTokens.slate500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'CoolImport S.A.C. (c) 2026',
            style: TextStyle(
              color: CorporateTokens.slate300,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: CorporateTokens.slate500),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(color: Color(0xFFEF4444), fontSize: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CorporateTokens.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CorporateTokens.cobalt600,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Future<void> _onRegistrar(AdminUsersNotifier notifier, String actor) async {
    if (_formKey.currentState?.validate() != true) return;
    await notifier.registrarUsuario(usuarioActor: actor);
  }

  Future<void> _onEditar(AdminUsersNotifier notifier, String actor) async {
    if (_formKey.currentState?.validate() != true) return;

    final confirm = await _confirmAction(
      title: 'Confirmar edicion',
      message: 'Se actualizaran los datos del usuario seleccionado.',
      confirmLabel: 'Actualizar',
      color: const Color(0xFF0D9488),
    );

    if (!confirm) return;
    await notifier.editarUsuario(usuarioActor: actor);
  }

  Future<void> _onEliminar(AdminUsersNotifier notifier, String actor) async {
    if ((_userController.text).trim().isEmpty) return;

    final confirm = await _confirmAction(
      title: 'Eliminar usuario',
      message: 'Esta accion dara de baja al usuario en el sistema legacy.',
      confirmLabel: 'Eliminar',
      color: const Color(0xFFDC2626),
    );

    if (!confirm) return;
    await notifier.eliminarUsuario(usuarioActor: actor);
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: CorporateTokens.slate700,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _syncFromState(AdminUsersState state) {
    if (_searchController.text != state.searchUser) {
      _searchController.text = state.searchUser;
    }
    if (_userController.text != state.user) {
      _userController.text = state.user;
    }
    if (_passwordController.text != state.password) {
      _passwordController.text = state.password;
    }
  }

  String? _resolveRol(String rol) {
    final safe = rol.trim();
    if (safe.isEmpty) return null;

    for (final item in adminUsersRoles) {
      if (item.toLowerCase() == safe.toLowerCase()) {
        return item;
      }
    }

    return null;
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese $field';
    }
    return null;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.busy,
    required this.enabled,
    this.color = CorporateTokens.cobalt600,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || busy;

    return ElevatedButton.icon(
      onPressed: disabled ? null : onTap,
      icon:
          busy
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.35),
      ),
    );
  }
}

class _StaggerSection extends StatelessWidget {
  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  const _StaggerSection({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
