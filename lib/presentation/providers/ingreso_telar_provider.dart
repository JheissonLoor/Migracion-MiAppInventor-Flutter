import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contracts/api_contracts.dart';
import '../../data/datasources/remote/produccion_remote_datasource.dart';
import 'auth_provider.dart';

enum IngresoTelarStatus {
  idle,
  loadingCatalogs,
  loadingProgress,
  loadingArticulo,
  saving,
  completing,
  success,
  error,
}

class IngresoTelarState {
  final IngresoTelarStatus status;
  final Map<String, String> fields;
  final String estadoActual;
  final String? message;
  final String? errorMessage;
  final bool initialized;
  final bool catalogsLoaded;
  final List<String> articulos;
  final List<String> materiales;
  final List<String> titulos;
  final List<String> colores;

  const IngresoTelarState({
    this.status = IngresoTelarStatus.idle,
    this.fields = const {},
    this.estadoActual = 'NUEVO',
    this.message,
    this.errorMessage,
    this.initialized = false,
    this.catalogsLoaded = false,
    this.articulos = const [],
    this.materiales = const [],
    this.titulos = const [],
    this.colores = const [],
  });

  bool get isBusy =>
      status == IngresoTelarStatus.loadingCatalogs ||
      status == IngresoTelarStatus.loadingProgress ||
      status == IngresoTelarStatus.loadingArticulo ||
      status == IngresoTelarStatus.saving ||
      status == IngresoTelarStatus.completing;

  bool get isLoadingCatalogs => status == IngresoTelarStatus.loadingCatalogs;

  IngresoTelarState copyWith({
    IngresoTelarStatus? status,
    Map<String, String>? fields,
    String? estadoActual,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
    bool? initialized,
    bool? catalogsLoaded,
    List<String>? articulos,
    List<String>? materiales,
    List<String>? titulos,
    List<String>? colores,
  }) {
    return IngresoTelarState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      estadoActual: estadoActual ?? this.estadoActual,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialized: initialized ?? this.initialized,
      catalogsLoaded: catalogsLoaded ?? this.catalogsLoaded,
      articulos: articulos ?? this.articulos,
      materiales: materiales ?? this.materiales,
      titulos: titulos ?? this.titulos,
      colores: colores ?? this.colores,
    );
  }
}

final ingresoTelarRemoteDatasourceProvider =
    Provider<ProduccionRemoteDatasource>(
      (ref) => ProduccionRemoteDatasource(
        ref.read(apiClientProvider),
        ref.read(localStorageProvider),
      ),
    );

class IngresoTelarNotifier extends StateNotifier<IngresoTelarState> {
  final ProduccionRemoteDatasource _datasource;
  String _operario = '';

  IngresoTelarNotifier(this._datasource)
    : super(
        IngresoTelarState(
          fields: Map<String, String>.from(_defaultIngresoTelarFields),
        ),
      );

  Future<void> inicializar(String operario) async {
    final safeOperario = operario.trim();
    if (safeOperario.isEmpty) {
      return;
    }

    _operario = safeOperario;
    if (state.initialized && state.catalogsLoaded) {
      return;
    }

    await cargarCatalogos();
  }

  Future<void> cargarCatalogos() async {
    if (state.isBusy) {
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.loadingCatalogs,
      clearError: true,
      clearMessage: true,
    );

    try {
      final results = await Future.wait<List<String>>([
        _safeCatalogLoad(_datasource.cargarArticulosTelar),
        _safeCatalogLoad(_datasource.cargarMaterialesTelar),
        _safeCatalogLoad(_datasource.cargarTitulosTelar),
        _safeCatalogLoad(_datasource.cargarColoresTelar),
      ]);

      state = state.copyWith(
        status: IngresoTelarStatus.success,
        initialized: true,
        catalogsLoaded: true,
        articulos: _sortUnique(results[0]),
        materiales: _sortUnique(results[1]),
        titulos: _sortUnique(results[2]),
        colores: _sortUnique(results[3]),
        message:
            results.every((items) => items.isEmpty)
                ? 'No se pudieron cargar catalogos. Puede escribir manualmente.'
                : 'Catalogos cargados: ${results[0].length} articulos, ${results[1].length} materiales.',
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        initialized: true,
        catalogsLoaded: false,
        errorMessage: _cleanError(error),
      );
    }
  }

  void actualizarCampo(String key, String value) {
    final updated = Map<String, String>.from(state.fields);
    updated[key] = value;
    state = state.copyWith(
      fields: updated,
      status: IngresoTelarStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void seleccionarCatalogo(String key, String value) {
    actualizarCampo(key, value);
  }

  void seleccionarFechaInicio(DateTime date) {
    actualizarCampo('fecha_inicio', _legacyDate(date));
  }

  void seleccionarFechaFinal(DateTime date) {
    actualizarCampo('fecha_final', _legacyDate(date));
  }

  Future<void> cargarProgresoPorTelar() async {
    if (state.isBusy) {
      return;
    }

    final telar = (state.fields['telar'] ?? '').trim();
    if (telar.isEmpty) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: 'Ingrese numero de telar para buscar progreso.',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.loadingProgress,
      clearError: true,
      clearMessage: true,
    );

    try {
      final lookup = await _datasource.cargarProgresoIngresoTelar(telar);
      if (lookup.hasProgress) {
        state = state.copyWith(
          status: IngresoTelarStatus.success,
          initialized: true,
          fields: {
            ...Map<String, String>.from(_defaultIngresoTelarFields),
            ...lookup.progress!.toFields(),
            'telar':
                lookup.progress!.telar.isEmpty ? telar : lookup.progress!.telar,
          },
          estadoActual: 'EN PROGRESO',
          message: 'Registro en progreso cargado para el telar $telar.',
        );
        return;
      }

      final updated = Map<String, String>.from(state.fields);
      if (lookup.articuloSugerido.isNotEmpty) {
        updated['articulo'] = lookup.articuloSugerido;
      }
      if (lookup.pasSugerido.isNotEmpty) {
        updated['pas'] = lookup.pasSugerido;
      }
      if (lookup.anchoPeineSugerido.isNotEmpty) {
        updated['ancho_peine'] = lookup.anchoPeineSugerido;
      }

      state = state.copyWith(
        status: IngresoTelarStatus.success,
        initialized: true,
        fields: updated,
        estadoActual: 'NUEVO',
        message:
            updated['articulo']?.trim().isEmpty == false
                ? 'Sin progreso activo. Se cargaron datos sugeridos del telar.'
                : 'Sin progreso activo. Complete los datos para iniciar.',
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        initialized: true,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> buscarArticuloActual() async {
    if (state.isBusy) {
      return;
    }

    final telar = (state.fields['telar'] ?? '').trim();
    if (telar.isEmpty) {
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.loadingArticulo,
      clearError: true,
      clearMessage: true,
    );

    try {
      final articulo = await _datasource.obtenerArticuloActualTelar(telar);
      final updated = Map<String, String>.from(state.fields);
      if (articulo.isNotEmpty) {
        updated['articulo'] = articulo;
      }
      state = state.copyWith(
        status: IngresoTelarStatus.success,
        fields: updated,
        message:
            articulo.isEmpty
                ? 'No se encontro articulo actual para el telar.'
                : 'Articulo actual autocompletado.',
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> guardarProgreso() async {
    if (state.isBusy) {
      return;
    }

    final missing = _missingRequired(['telar', 'articulo', 'trama']);
    if (missing.isNotEmpty) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: 'Complete campos obligatorios: ${missing.join(', ')}.',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.saving,
      clearError: true,
      clearMessage: true,
    );

    try {
      final payload = _buildPayload(accion: 'guardar', estado: 'EN PROGRESO');
      final message = await _datasource.enviarIngresoTelar(payload);
      state = state.copyWith(
        status: IngresoTelarStatus.success,
        estadoActual: 'EN PROGRESO',
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> completarRegistro() async {
    if (state.isBusy) {
      return;
    }

    final missing = _missingRequired([
      'telar',
      'articulo',
      'trama',
      'fecha_final',
    ]);
    if (missing.isNotEmpty) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: 'Para completar faltan: ${missing.join(', ')}.',
      );
      return;
    }

    state = state.copyWith(
      status: IngresoTelarStatus.completing,
      clearError: true,
      clearMessage: true,
    );

    try {
      final payload = _buildPayload(accion: 'completar', estado: 'COMPLETADO');
      final message = await _datasource.enviarIngresoTelar(payload);
      state = state.copyWith(
        status: IngresoTelarStatus.success,
        estadoActual: 'COMPLETADO',
        message: message,
      );
    } catch (error) {
      state = state.copyWith(
        status: IngresoTelarStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void nuevoRegistro() {
    state = state.copyWith(
      status: IngresoTelarStatus.idle,
      fields: Map<String, String>.from(_defaultIngresoTelarFields),
      estadoActual: 'NUEVO',
      clearError: true,
      message: 'Campos limpiados. Listo para nuevo registro.',
    );
  }

  List<String> _missingRequired(List<String> keys) {
    return keys
        .where((key) => (state.fields[key] ?? '').trim().isEmpty)
        .map(_labelForKey)
        .toList(growable: false);
  }

  Map<String, dynamic> _buildPayload({
    required String accion,
    required String estado,
  }) {
    final fields = state.fields;
    return ApiPayloads.ingresoTelar(
      telar: fields['telar'] ?? '',
      articulo: fields['articulo'] ?? '',
      hilos: fields['hilos'] ?? '',
      titulo: fields['titulo'] ?? '',
      mts: fields['mts'] ?? '',
      material: fields['material'] ?? '',
      color: fields['color'] ?? '',
      pas: fields['pas'] ?? '',
      anchoPeine: fields['ancho_peine'] ?? '',
      trama: fields['trama'] ?? '',
      fechaInicio: fields['fecha_inicio'] ?? '',
      fechaFinal: fields['fecha_final'] ?? '',
      pesoTotal: fields['peso_total'] ?? '',
      estado: estado,
      operario: _operario,
      accion: accion,
    );
  }

  String _legacyDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _cleanError(Object error) {
    return error.toString().replaceAll('Exception: ', '').trim();
  }

  String _labelForKey(String key) {
    return switch (key) {
      'telar' => 'Telar',
      'articulo' => 'Articulo',
      'trama' => 'Trama',
      'fecha_final' => 'Fecha final',
      _ => key,
    };
  }

  List<String> _sortUnique(List<String> items) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final item in items) {
      final value = item.trim();
      if (value.isEmpty) continue;
      if (seen.add(value.toUpperCase())) {
        normalized.add(value);
      }
    }
    normalized.sort((a, b) => a.toUpperCase().compareTo(b.toUpperCase()));
    return normalized;
  }

  Future<List<String>> _safeCatalogLoad(
    Future<List<String>> Function() loader,
  ) async {
    try {
      return await loader();
    } catch (_) {
      return const [];
    }
  }
}

final ingresoTelarProvider =
    StateNotifierProvider<IngresoTelarNotifier, IngresoTelarState>(
      (ref) =>
          IngresoTelarNotifier(ref.read(ingresoTelarRemoteDatasourceProvider)),
    );

const Map<String, String> _defaultIngresoTelarFields = {
  'telar': '',
  'articulo': '',
  'pas': '',
  'ancho_peine': '',
  'material': '',
  'color': '',
  'hilos': '',
  'mts': '',
  'titulo': '',
  'peso_total': '',
  'trama': '',
  'parcial': '',
  'fecha_inicio': '',
  'fecha_final': '',
};
