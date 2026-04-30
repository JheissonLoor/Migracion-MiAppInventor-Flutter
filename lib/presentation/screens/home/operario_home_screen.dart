import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/local_api_status_chip.dart';

class OperarioHomeScreen extends ConsumerStatefulWidget {
  const OperarioHomeScreen({super.key});

  @override
  ConsumerState<OperarioHomeScreen> createState() => _OperarioHomeScreenState();
}

class _OperarioHomeScreenState extends ConsumerState<OperarioHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.user?.usuario ?? 'Operario';
    final cargo = authState.user?.cargo ?? 'OPERARIO';
    final modules = _getModulesForRole(cargo);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: Column(
              children: [
                _StaggerSection(
                  controller: _entryController,
                  begin: 0.02,
                  end: 0.24,
                  child: _buildHeader(usuario: usuario, cargo: cargo),
                ),
                _StaggerSection(
                  controller: _entryController,
                  begin: 0.08,
                  end: 0.30,
                  child: _buildInstructionBar(),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount =
                          width >= 1200
                              ? 4
                              : width >= 840
                              ? 3
                              : width >= 540
                              ? 2
                              : 1;

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        itemCount: modules.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.18,
                        ),
                        itemBuilder: (context, index) {
                          return _StaggerModuleCard(
                            controller: _entryController,
                            index: index,
                            child: _buildModuleCard(modules[index]),
                          );
                        },
                      );
                    },
                  ),
                ),
                _StaggerSection(
                  controller: _entryController,
                  begin: 0.18,
                  end: 0.42,
                  child: _buildLogoutButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required String usuario, required String cargo}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: CorporateTokens.borderSoft),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    CorporateTokens.cobalt600,
                    CorporateTokens.indigo700,
                  ],
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario,
                    style: const TextStyle(
                      color: CorporateTokens.navy900,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Operacion de planta en tiempo real',
                    style: TextStyle(
                      color: CorporateTokens.slate500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const LocalApiStatusChip(compact: true),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CorporateTokens.cobalt600.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: CorporateTokens.cobalt600.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    cargo.toUpperCase(),
                    style: const TextStyle(
                      color: CorporateTokens.cobalt600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: CorporateTokens.cobalt600.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CorporateTokens.cobalt600.withValues(alpha: 0.18),
          ),
        ),
        child: const Text(
          'Seleccione el movimiento que desea realizar',
          style: TextStyle(
            color: CorporateTokens.navy900,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildModuleCard(_OperarioModule module) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateTo(module.route),
        borderRadius: BorderRadius.circular(16),
        splashColor: module.color.withValues(alpha: 0.15),
        highlightColor: module.color.withValues(alpha: 0.06),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: module.color.withValues(alpha: 0.25)),
            boxShadow: CorporateTokens.cardShadow,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 210;
              if (compact) {
                return Row(
                  children: [
                    _buildIconBadge(module),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTitle(module.label, leftAlign: true)),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: CorporateTokens.slate500,
                      size: 20,
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIconBadge(module),
                  const Spacer(),
                  _buildTitle(module.label, leftAlign: false),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Abrir modulo',
                        style: TextStyle(
                          color: CorporateTokens.slate500,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: CorporateTokens.navy900,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIconBadge(_OperarioModule module) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: module.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(module.icon, size: 25, color: module.color),
    );
  }

  Widget _buildTitle(String label, {required bool leftAlign}) {
    return Text(
      label,
      textAlign: leftAlign ? TextAlign.left : TextAlign.start,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: CorporateTokens.navy900,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: () {
            ref.read(authProvider.notifier).logout();
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: Icon(Icons.logout_rounded, color: CorporateTokens.slate500),
          label: const Text(
            'Cerrar sesion',
            style: TextStyle(
              color: CorporateTokens.slate700,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: CorporateTokens.borderSoft),
            ),
          ),
        ),
      ),
    );
  }

  List<_OperarioModule> _getModulesForRole(String cargo) {
    final modules = <_OperarioModule>[
      const _OperarioModule(
        icon: Icons.output_rounded,
        label: 'Salida del Almacen',
        route: '/salida_almacen',
        color: Color(0xFFE45A64),
      ),
      const _OperarioModule(
        icon: Icons.input_rounded,
        label: 'Reingreso en Almacen',
        route: '/reingreso',
        color: Color(0xFF52C07E),
      ),
      const _OperarioModule(
        icon: Icons.history_rounded,
        label: 'Historial',
        route: '/historial',
        color: Color(0xFF43A4F6),
      ),
      const _OperarioModule(
        icon: Icons.table_rows_rounded,
        label: 'Historial Tela Cruda',
        route: '/historial_tela_cruda',
        color: Color(0xFF26B6C8),
      ),
      const _OperarioModule(
        icon: Icons.location_searching_rounded,
        label: 'Consultar Ubicacion',
        route: '/consulta_almacen',
        color: Color(0xFF35C6C0),
      ),
      const _OperarioModule(
        icon: Icons.print_rounded,
        label: 'Actualizar Etiqueta',
        route: '/impresion_etiqueta',
        color: Color(0xFFB785FF),
      ),
    ];

    if (AppConstants.rolesProduccion.contains(cargo.toUpperCase()) ||
        cargo.toUpperCase() == 'ADMINISTRADOR') {
      modules.add(
        const _OperarioModule(
          icon: Icons.precision_manufacturing_outlined,
          label: 'Ingreso Telar',
          route: '/ingreso_telar',
          color: Color(0xFFC18B61),
        ),
      );
      modules.add(
        const _OperarioModule(
          icon: Icons.precision_manufacturing_rounded,
          label: 'Ingreso Urdidora',
          route: '/urdido',
          color: Color(0xFFD69A63),
        ),
      );
      modules.add(
        const _OperarioModule(
          icon: Icons.inventory_rounded,
          label: 'Historial Urdido',
          route: '/historial_urdido',
          color: Color(0xFF8B7AD1),
        ),
      );
      modules.add(
        const _OperarioModule(
          icon: Icons.settings_suggest_rounded,
          label: 'Engomado',
          route: '/engomado',
          color: Color(0xFFB67A5A),
        ),
      );
      modules.add(
        const _OperarioModule(
          icon: Icons.grid_view_rounded,
          label: 'Telares',
          route: '/telares',
          color: Color(0xFF9A7A57),
        ),
      );
      modules.add(
        const _OperarioModule(
          icon: Icons.view_timeline_rounded,
          label: 'Historial Telar',
          route: '/historial_telar',
          color: Color(0xFF5E90C4),
        ),
      );
    }

    modules.addAll([
      const _OperarioModule(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Consulta Stock',
        route: '/consulta_stock',
        color: Color(0xFFF5A04A),
      ),
      const _OperarioModule(
        icon: Icons.inventory_2_rounded,
        label: 'Inventario Fisico',
        route: '/inventario_cero',
        color: Color(0xFF7A91D5),
      ),
    ]);

    return modules;
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
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

class _StaggerModuleCard extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final Widget child;

  const _StaggerModuleCard({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.08 + (index * 0.05)).clamp(0.0, 0.84);
    final end = (0.30 + (index * 0.05)).clamp(0.22, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}

class _OperarioModule {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _OperarioModule({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
