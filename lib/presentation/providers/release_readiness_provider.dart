import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/local_storage.dart';
import 'auth_provider.dart';

class ReleaseChecklistItem {
  final String id;
  final String title;
  final String detail;
  final bool requiredForGo;

  const ReleaseChecklistItem({
    required this.id,
    required this.title,
    required this.detail,
    this.requiredForGo = true,
  });
}

class ReleaseReadinessState {
  final List<ReleaseChecklistItem> items;
  final Map<String, bool> values;
  final DateTime? updatedAt;

  const ReleaseReadinessState({
    required this.items,
    this.values = const <String, bool>{},
    this.updatedAt,
  });

  bool isChecked(String id) => values[id] ?? false;

  int get completedCount => items.where((item) => isChecked(item.id)).length;

  int get requiredCount => items.where((item) => item.requiredForGo).length;

  int get completedRequiredCount =>
      items.where((item) => item.requiredForGo && isChecked(item.id)).length;

  bool get requiredForGoCompleted =>
      requiredCount > 0 && completedRequiredCount == requiredCount;

  double get completionPercent {
    if (items.isEmpty) return 0;
    return completedCount / items.length;
  }

  ReleaseReadinessState copyWith({
    List<ReleaseChecklistItem>? items,
    Map<String, bool>? values,
    DateTime? updatedAt,
  }) {
    return ReleaseReadinessState(
      items: items ?? this.items,
      values: values ?? this.values,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ReleaseReadinessNotifier extends StateNotifier<ReleaseReadinessState> {
  final LocalStorage _storage;

  ReleaseReadinessNotifier(this._storage)
    : super(ReleaseReadinessState(items: _defaultChecklistItems)) {
    _load();
  }

  static const List<ReleaseChecklistItem> _defaultChecklistItems = [
    ReleaseChecklistItem(
      id: 'preflight_build_ok',
      title: 'Build piloto validado',
      detail: 'flutter clean/pub get/analyze/test + APK listo para planta.',
    ),
    ReleaseChecklistItem(
      id: 'api_principal_ok',
      title: 'API principal operativa',
      detail: 'Endpoints core responden en red real de planta.',
    ),
    ReleaseChecklistItem(
      id: 'api_local_ok',
      title: 'API local de impresion operativa',
      detail: 'Health y pruebas Zebra/Epson completadas.',
    ),
    ReleaseChecklistItem(
      id: 'login_roles_ok',
      title: 'Login y permisos validados',
      detail: 'Ruteo por rol y guardas de acceso sin brechas.',
    ),
    ReleaseChecklistItem(
      id: 'inventario_flujos_ok',
      title: 'Inventario validado',
      detail: 'Salida/Reingreso/Inventario cero sin regresiones.',
    ),
    ReleaseChecklistItem(
      id: 'produccion_flujos_ok',
      title: 'Produccion validada',
      detail: 'Urdido/Engomado/Telares operativos en turno.',
    ),
    ReleaseChecklistItem(
      id: 'telas_flujos_ok',
      title: 'Telas y contenedor validados',
      detail:
          'Gestion stock telas + Ingreso telas + Contenedor con cola offline.',
    ),
    ReleaseChecklistItem(
      id: 'proveedor_flujos_ok',
      title: 'Proveedores validados',
      detail: 'Agregar/Editar proveedor sin romper contrato legacy.',
    ),
    ReleaseChecklistItem(
      id: 'offline_reconexion_ok',
      title: 'Offline/reconexion validados',
      detail: 'Encolado y drenado automatico comprobados con red inestable.',
    ),
    ReleaseChecklistItem(
      id: 'turno_real_ok',
      title: 'Turno real completado',
      detail: 'Minimo 1 turno real con 2 operarios y soporte de guardia.',
    ),
    ReleaseChecklistItem(
      id: 'ring1_mdm_ok',
      title: 'Anillo 1 MDM desplegado',
      detail: 'Supervisores piloto sin incidentes P1/P2.',
      requiredForGo: false,
    ),
    ReleaseChecklistItem(
      id: 'ring2_mdm_ok',
      title: 'Anillo 2 MDM desplegado',
      detail: 'Operacion critica estable y sin perdida de datos.',
      requiredForGo: false,
    ),
    ReleaseChecklistItem(
      id: 'rollback_ready',
      title: 'Rollback confirmado',
      detail: 'APK legacy disponible y plan de retorno probado.',
    ),
  ];

  Future<void> toggle(String id, bool checked) async {
    final updated = Map<String, bool>.from(state.values)..[id] = checked;
    await _persist(updated);
    state = state.copyWith(values: updated, updatedAt: DateTime.now());
  }

  Future<void> markRequiredAsChecked() async {
    final updated = Map<String, bool>.from(state.values);
    for (final item in state.items.where((item) => item.requiredForGo)) {
      updated[item.id] = true;
    }

    await _persist(updated);
    state = state.copyWith(values: updated, updatedAt: DateTime.now());
  }

  Future<void> resetAll() async {
    await _persist(const <String, bool>{});
    state = state.copyWith(
      values: const <String, bool>{},
      updatedAt: DateTime.now(),
    );
  }

  void _load() {
    final raw = _storage.getValue(
      AppConstants.keyReleasePilotChecklist,
      defaultValue: '',
    );
    if (raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final values = <String, bool>{};
      decoded.forEach((key, value) {
        final id = key.toString().trim();
        if (id.isEmpty) return;
        values[id] = value == true;
      });

      state = state.copyWith(values: values);
    } catch (_) {
      state = state.copyWith(values: const <String, bool>{});
    }
  }

  Future<void> _persist(Map<String, bool> values) async {
    await _storage.setValue(
      AppConstants.keyReleasePilotChecklist,
      jsonEncode(values),
    );
  }
}

final releaseReadinessProvider =
    StateNotifierProvider<ReleaseReadinessNotifier, ReleaseReadinessState>(
      (ref) => ReleaseReadinessNotifier(ref.read(localStorageProvider)),
    );
