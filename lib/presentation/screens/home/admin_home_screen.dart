import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/enterprise_backdrop.dart';
import '../../widgets/local_api_status_chip.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    final usuario = authState.user?.usuario ?? 'Admin';
    final cargo = authState.user?.cargo ?? 'ADMIN';
    final categories = _filteredCategories();

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
                  child: _buildHeader(usuario, cargo),
                ),
                _StaggerSection(
                  controller: _entryController,
                  begin: 0.08,
                  end: 0.30,
                  child: _buildSearchBar(),
                ),
                Expanded(
                  child:
                      categories.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              return _buildCategorySection(
                                category: categories[index],
                                index: index,
                              );
                            },
                          ),
                ),
                _StaggerSection(
                  controller: _entryController,
                  begin: 0.18,
                  end: 0.40,
                  child: _buildLogoutButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String usuario, String cargo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: _GlassPanel(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
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
                Icons.admin_panel_settings_rounded,
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
                    'Hola, $usuario',
                    style: const TextStyle(
                      color: CorporateTokens.navy900,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Panel corporativo de administracion',
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
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
        style: const TextStyle(
          color: CorporateTokens.navy900,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar modulo o proceso...',
          hintStyle: const TextStyle(color: CorporateTokens.slate300),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: CorporateTokens.slate500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: CorporateTokens.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: CorporateTokens.cobalt600,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required _Category category,
    required int index,
  }) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final crossAxisCount =
        width >= 1150
            ? 3
            : width >= 760
            ? 2
            : 1;
    final itemWidth = (width - ((crossAxisCount - 1) * 10)) / crossAxisCount;

    return _StaggerSlideFade(
      controller: _entryController,
      start: (0.08 + (index * 0.06)).clamp(0.0, 0.82),
      end: (0.30 + (index * 0.06)).clamp(0.20, 1.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: category.color.withValues(alpha: 0.20)),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, size: 20, color: category.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.title,
                    style: const TextStyle(
                      color: CorporateTokens.navy900,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: CorporateTokens.cobalt600.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    '${category.modules.length}',
                    style: const TextStyle(
                      color: CorporateTokens.navy900,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  category.modules.map((module) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildModuleCard(
                        module: module,
                        color: category.color,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({required _Module module, required Color color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateTo(module.route),
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.05),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: CorporateTokens.surfaceBottom,
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(module.icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    color: CorporateTokens.navy900,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CorporateTokens.slate500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: CorporateTokens.borderSoft),
          boxShadow: CorporateTokens.cardShadow,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: CorporateTokens.slate500,
              size: 36,
            ),
            SizedBox(height: 8),
            Text(
              'No se encontraron modulos para esa busqueda.',
              style: TextStyle(color: CorporateTokens.slate300, fontSize: 13),
            ),
          ],
        ),
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

  List<_Category> _filteredCategories() {
    final categories = _allCategories();
    if (_searchQuery.isEmpty) {
      return categories;
    }

    final query = _searchQuery.toLowerCase();
    return categories
        .map((category) {
          final modules =
              category.modules
                  .where((module) => module.title.toLowerCase().contains(query))
                  .toList();
          return category.copyWith(modules: modules);
        })
        .where((category) => category.modules.isNotEmpty)
        .toList();
  }

  List<_Category> _allCategories() {
    return [
      _Category(
        title: 'Almacen',
        icon: Icons.warehouse_rounded,
        color: const Color(0xFF31A8FF),
        modules: const [
          _Module(
            'Consulta Stock',
            Icons.qr_code_scanner_rounded,
            '/consulta_stock',
          ),
          _Module(
            'Salida del Almacen',
            Icons.output_rounded,
            '/salida_almacen',
          ),
          _Module(
            'Cambio Almacen (Telar)',
            Icons.swap_horiz_rounded,
            '/cambio_almacen',
          ),
          _Module(
            'Cambio Ubicacion (Hilos)',
            Icons.edit_location_rounded,
            '/cambio_ubicacion',
          ),
        ],
      ),
      _Category(
        title: 'Inventario',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF56CC7D),
        modules: const [
          _Module(
            'Reingresar al Inventario',
            Icons.input_rounded,
            '/reingreso',
          ),
          _Module(
            'Gestion Stock Telas',
            Icons.style_rounded,
            '/gestion_stock_telas',
          ),
          _Module(
            'Inventario Fisico',
            Icons.fact_check_rounded,
            '/inventario_cero',
          ),
        ],
      ),
      _Category(
        title: 'Consultas',
        icon: Icons.search_rounded,
        color: const Color(0xFF25C4D7),
        modules: const [
          _Module(
            'Consultar Ubicacion',
            Icons.location_searching_rounded,
            '/consulta_almacen',
          ),
          _Module('Historial', Icons.history_rounded, '/historial'),
          _Module(
            'Historial Administrativo',
            Icons.manage_search_rounded,
            '/historial_admin',
          ),
        ],
      ),
      _Category(
        title: 'Proveedores',
        icon: Icons.business_rounded,
        color: const Color(0xFFF5A623),
        modules: const [
          _Module(
            'Agregar Proveedor',
            Icons.person_add_rounded,
            '/agregar_proveedor',
          ),
          _Module('Editar Proveedor', Icons.edit_rounded, '/editar_proveedor'),
        ],
      ),
      _Category(
        title: 'Telas',
        icon: Icons.texture_rounded,
        color: const Color(0xFFB08BFF),
        modules: const [
          _Module('Ingreso de Telas', Icons.add_box_rounded, '/ingreso_telas'),
          _Module(
            'Historial Tela Cruda',
            Icons.table_rows_rounded,
            '/historial_tela_cruda',
          ),
          _Module('Contenedor', Icons.local_shipping_rounded, '/contenedor'),
          _Module(
            'Actualizar Etiqueta',
            Icons.print_rounded,
            '/impresion_etiqueta',
          ),
        ],
      ),
      _Category(
        title: 'Produccion',
        icon: Icons.precision_manufacturing_rounded,
        color: const Color(0xFFD48F54),
        modules: const [
          _Module(
            'Ingreso Telar',
            Icons.precision_manufacturing_outlined,
            '/ingreso_telar',
          ),
          _Module('Urdido', Icons.settings_rounded, '/urdido'),
          _Module(
            'Historial Urdido',
            Icons.inventory_rounded,
            '/historial_urdido',
          ),
          _Module('Engomado', Icons.build_rounded, '/engomado'),
          _Module('Telares', Icons.grid_on_rounded, '/telares'),
          _Module(
            'Historial Telar',
            Icons.view_timeline_rounded,
            '/historial_telar',
          ),
        ],
      ),
      _Category(
        title: 'Sistema',
        icon: Icons.settings_applications_rounded,
        color: const Color(0xFF8FA3BD),
        modules: const [
          _Module(
            'Estado de Migracion',
            Icons.track_changes_rounded,
            '/estado_migracion',
          ),
          _Module(
            'Telemetria Operativa',
            Icons.monitor_heart_rounded,
            '/telemetria_operativa',
          ),
          _Module(
            'Release Readiness',
            Icons.fact_check_rounded,
            '/release_readiness',
          ),
          _Module(
            'Config API Local',
            Icons.settings_ethernet_rounded,
            '/local_api_settings',
          ),
          _Module('Administrar Usuarios', Icons.people_rounded, '/admin_users'),
        ],
      ),
    ];
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: CorporateTokens.borderSoft),
        boxShadow: CorporateTokens.cardShadow,
      ),
      child: child,
    );
  }
}

class _StaggerSlideFade extends StatelessWidget {
  final AnimationController controller;
  final double start;
  final double end;
  final Widget child;

  const _StaggerSlideFade({
    required this.controller,
    required this.start,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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

class _Category {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Module> modules;

  const _Category({
    required this.title,
    required this.icon,
    required this.color,
    required this.modules,
  });

  _Category copyWith({List<_Module>? modules}) {
    return _Category(
      title: title,
      icon: icon,
      color: color,
      modules: modules ?? this.modules,
    );
  }
}

class _Module {
  final String title;
  final IconData icon;
  final String route;

  const _Module(this.title, this.icon, this.route);
}
