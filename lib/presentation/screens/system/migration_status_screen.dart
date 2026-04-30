import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/enterprise_backdrop.dart';

class MigrationStatusScreen extends StatefulWidget {
  const MigrationStatusScreen({super.key});

  @override
  State<MigrationStatusScreen> createState() => _MigrationStatusScreenState();
}

class _MigrationStatusScreenState extends State<MigrationStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fade;

  final List<_MigrationItem> _items = const [
    _MigrationItem(
      title: 'Login + sesiones',
      detail: 'Autenticacion estable y guardado local equivalente a TinyDB.',
      done: true,
    ),
    _MigrationItem(
      title: 'Home Admin / Operario',
      detail: 'Paneles corporativos con navegacion modular y roles.',
      done: true,
    ),
    _MigrationItem(
      title: 'Consulta almacen / historial',
      detail: 'Consulta de ubicaciones y movimientos en produccion.',
      done: true,
    ),
    _MigrationItem(
      title: 'Salida y reingreso',
      detail: 'Flujos criticos con validaciones y cola offline.',
      done: true,
    ),
    _MigrationItem(
      title: 'Inventario cero',
      detail: 'Verificacion y registro de inventario fisico.',
      done: true,
    ),
    _MigrationItem(
      title: 'Impresion etiquetas',
      detail: 'Integracion API local Zebra/Epson + fallback seguro.',
      done: true,
    ),
    _MigrationItem(
      title: 'Gestion stock telas',
      detail: 'Ingreso, despacho y telemetria operativa.',
      done: true,
    ),
    _MigrationItem(
      title: 'Urdido / Engomado / Telares',
      detail: 'Modulos productivos con cola y reintentos.',
      done: true,
    ),
    _MigrationItem(
      title: 'Admin users',
      detail: 'Buscar, crear, editar y eliminar usuarios con payload legacy.',
      done: true,
    ),
    _MigrationItem(
      title: 'Telemetria operativa',
      detail: 'KPIs de cola/reintento para soporte de planta.',
      done: true,
    ),
    _MigrationItem(
      title: 'Cambio almacen (telar)',
      detail: 'Migrado con QR 12/14/16, destino dinamico y cola offline.',
      done: true,
    ),
    _MigrationItem(
      title: 'Cambio ubicacion (hilos)',
      detail:
          'Migrado con consulta de ultima ubicacion y cola offline con reintentos.',
      done: true,
    ),
    _MigrationItem(
      title: 'Editar proveedor',
      detail: 'Busqueda y actualizacion de taras sobre Apps Script legacy.',
      done: true,
    ),
    _MigrationItem(
      title: 'Agregar proveedor / ingreso telas / contenedor',
      detail:
          'Migrado con parser QR 14/16, Google Forms/Sheets y cola offline.',
      done: true,
    ),
    _MigrationItem(
      title: 'Piloto final + despliegue anillos MDM',
      detail: 'Pendiente ejecucion operativa y cierre de regresion.',
      done: false,
      critical: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
    _fade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _items.where((item) => item.done).length;
    final pending = _items.length - done;
    final progress = done / _items.length;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: EnterpriseBackdrop()),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 10),
                    _buildKpi(progress: progress, done: done, pending: pending),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSection(
                            title: 'Bloques cerrados',
                            items: _items.where((item) => item.done).toList(),
                            doneStyle: true,
                          ),
                          const SizedBox(height: 10),
                          _buildSection(
                            title: 'Bloques pendientes',
                            items: _items.where((item) => !item.done).toList(),
                            doneStyle: false,
                          ),
                          const SizedBox(height: 10),
                          _buildEstimateCard(
                            progress: progress,
                            pending: pending,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                'Estado de migracion',
                style: TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Control ejecutivo de avance Flutter vs legado',
                style: TextStyle(color: CorporateTokens.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpi({
    required double progress,
    required int done,
    required int pending,
  }) {
    final percent = (progress * 100).toStringAsFixed(1);
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
          Row(
            children: [
              _kpiChip('Completados', done.toString(), const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _kpiChip(
                'Pendientes',
                pending.toString(),
                const Color(0xFFDC2626),
              ),
              const Spacer(),
              Text(
                '$percent% listo',
                style: const TextStyle(
                  color: CorporateTokens.navy900,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    CorporateTokens.cobalt600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kpiChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_MigrationItem> items,
    required bool doneStyle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CorporateTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CorporateTokens.navy900,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _buildItem(item, doneStyle: doneStyle)),
        ],
      ),
    );
  }

  Widget _buildItem(_MigrationItem item, {required bool doneStyle}) {
    final accent =
        doneStyle ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: doneStyle ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            doneStyle
                ? Icons.check_circle_rounded
                : Icons.pending_actions_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: CorporateTokens.navy900,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.critical && !doneStyle)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFDC2626,
                          ).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Critico',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.detail,
                  style: const TextStyle(
                    color: CorporateTokens.slate700,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateCard({required double progress, required int pending}) {
    final percent = (progress * 100).toStringAsFixed(1);
    final eta =
        pending <= 1
            ? '1-2 semanas'
            : pending <= 3
            ? '2-3 semanas'
            : '3-5 semanas';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimacion de cierre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Avance actual: $percent% | Bloques pendientes: $pending',
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tiempo estimado para cierre funcional: $eta (incluyendo piloto de planta).',
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MigrationItem {
  final String title;
  final String detail;
  final bool done;
  final bool critical;

  const _MigrationItem({
    required this.title,
    required this.detail,
    required this.done,
    this.critical = false,
  });
}
