import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage.dart';
import '../../core/utils/qr_image_encoder.dart';
import '../../data/datasources/remote/movimiento_telas_remote_datasource.dart';
import 'auth_provider.dart';

enum MovimientoTelasStatus {
  idle,
  loadingCatalogos,
  generatingCode,
  sendingCorte,
  generatingQr,
  generatingPdf,
  printing,
  success,
  error,
}

class MovimientoTelasState {
  final MovimientoTelasStatus status;
  final List<String> articulos;
  final List<String> codigosFalla;
  final String codigoBase;
  final String correlativo;
  final String numCorte;
  final String qrRaw;
  final String qrResumen;
  final bool pdfGenerado;
  final String? message;
  final String? errorMessage;

  const MovimientoTelasState({
    this.status = MovimientoTelasStatus.idle,
    this.articulos = const [],
    this.codigosFalla = const [],
    this.codigoBase = '',
    this.correlativo = '',
    this.numCorte = '',
    this.qrRaw = '',
    this.qrResumen = '',
    this.pdfGenerado = false,
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == MovimientoTelasStatus.loadingCatalogos ||
      status == MovimientoTelasStatus.generatingCode ||
      status == MovimientoTelasStatus.sendingCorte ||
      status == MovimientoTelasStatus.generatingQr ||
      status == MovimientoTelasStatus.generatingPdf ||
      status == MovimientoTelasStatus.printing;

  bool get canRegistrarDato => qrRaw.trim().isNotEmpty;

  bool get canImprimir => pdfGenerado;

  MovimientoTelasState copyWith({
    MovimientoTelasStatus? status,
    List<String>? articulos,
    List<String>? codigosFalla,
    String? codigoBase,
    String? correlativo,
    String? numCorte,
    String? qrRaw,
    String? qrResumen,
    bool? pdfGenerado,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MovimientoTelasState(
      status: status ?? this.status,
      articulos: articulos ?? this.articulos,
      codigosFalla: codigosFalla ?? this.codigosFalla,
      codigoBase: codigoBase ?? this.codigoBase,
      correlativo: correlativo ?? this.correlativo,
      numCorte: numCorte ?? this.numCorte,
      qrRaw: qrRaw ?? this.qrRaw,
      qrResumen: qrResumen ?? this.qrResumen,
      pdfGenerado: pdfGenerado ?? this.pdfGenerado,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MovimientoTelasNotifier extends StateNotifier<MovimientoTelasState> {
  static const String _counterPrefix = 'mov_telas_counter_';

  final MovimientoTelasRemoteDatasource _datasource;
  final LocalStorage _storage;

  MovimientoTelasNotifier(this._datasource, this._storage)
    : super(const MovimientoTelasState()) {
    cargarCatalogos();
  }

  Future<void> cargarCatalogos() async {
    state = state.copyWith(
      status: MovimientoTelasStatus.loadingCatalogos,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.obtenerCatalogos();
      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        articulos: data.articulos,
        codigosFalla: data.codigosFalla,
        message:
            'Catalogos cargados: ${data.articulos.length} articulos / '
            '${data.codigosFalla.length} codigos de falla.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> generarCodigo({
    required String numTelar,
    required DateTime fechaRevisado,
  }) async {
    final telar = numTelar.trim();
    if (telar.isEmpty) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: 'Ingrese el numero de telar antes de generar el codigo.',
      );
      return;
    }

    state = state.copyWith(
      status: MovimientoTelasStatus.generatingCode,
      clearError: true,
      clearMessage: true,
    );

    final correlativo = _leerContador(telar).toString();
    final fechaCode = _toFechaCodigo(fechaRevisado);
    final codigoBase = 'T${telar}F$fechaCode-';

    state = state.copyWith(
      status: MovimientoTelasStatus.success,
      codigoBase: codigoBase,
      correlativo: correlativo,
      numCorte: correlativo,
      qrRaw: '',
      qrResumen: '',
      pdfGenerado: false,
      message: 'Codigo generado correctamente.',
      clearError: true,
    );
  }

  void generarQr({
    required String codigoBase,
    required String numCorte,
    required String numTelar,
    required String opPrefijo,
    required String opNumero,
    required String articulo,
    required String mts,
    required String peso,
    required String nombre,
  }) {
    final validationError = _validarCamposQr(
      codigoBase: codigoBase,
      numCorte: numCorte,
      numTelar: numTelar,
      opPrefijo: opPrefijo,
      opNumero: opNumero,
      articulo: articulo,
      mts: mts,
      peso: peso,
      nombre: nombre,
    );
    if (validationError != null) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: validationError,
      );
      return;
    }

    final codigoCompleto = _buildCodigoCompleto(
      codigoBase: codigoBase,
      numCorte: numCorte,
    );
    final opCompleto = _sanitize('$opPrefijo$opNumero');
    final articuloClean = _sanitize(articulo);
    final mtsClean = _sanitize(mts);
    final pesoClean = _sanitize(peso);
    final nombreClean = _sanitize(nombre);

    final raw = [
      codigoCompleto,
      _sanitize(numCorte),
      _sanitize(numTelar),
      opCompleto,
      articuloClean,
      mtsClean,
      pesoClean,
      nombreClean,
      '',
    ].join(',');

    final resumen =
        '$codigoCompleto $opCompleto\n'
        '$articuloClean\n'
        '$mtsClean Mts\n'
        '$pesoClean Kg\n'
        'REVISADOR $nombreClean';

    state = state.copyWith(
      status: MovimientoTelasStatus.success,
      qrRaw: raw,
      qrResumen: resumen,
      pdfGenerado: false,
      message: 'QR generado. Puede registrar e imprimir etiqueta.',
      clearError: true,
    );
  }

  Future<void> registrarCorte(MovimientoTelaCortePayload payload) async {
    state = state.copyWith(
      status: MovimientoTelasStatus.sendingCorte,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.enviarCorte(payload);
      final numActual =
          int.tryParse(payload.numCorte.trim()) ??
          int.tryParse(payload.correlativo.trim()) ??
          _leerContador(payload.numTelar.trim());
      final siguiente = numActual + 1;
      await _guardarContador(payload.numTelar.trim(), siguiente);

      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        correlativo: siguiente.toString(),
        numCorte: siguiente.toString(),
        qrRaw: '',
        qrResumen: '',
        pdfGenerado: false,
        message: message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> registrarDatoQr() async {
    if (state.qrRaw.trim().isEmpty || state.qrResumen.trim().isEmpty) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: 'Primero genere el QR de la etiqueta.',
      );
      return;
    }

    state = state.copyWith(
      status: MovimientoTelasStatus.generatingPdf,
      clearError: true,
      clearMessage: true,
    );

    try {
      final imageBase64 = await QrImageEncoder.toBase64Png(state.qrRaw);
      final text = state.qrResumen.replaceAll('\n', ' ').trim();
      final message = await _datasource.generarPdfEtiqueta(
        imageBase64: imageBase64,
        text: text,
      );

      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        pdfGenerado: true,
        message: message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> imprimirEtiqueta() async {
    if (!state.pdfGenerado) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: 'Primero use "Registrar dato" para generar el PDF local.',
      );
      return;
    }

    state = state.copyWith(
      status: MovimientoTelasStatus.printing,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.imprimirEtiqueta();
      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        qrRaw: '',
        qrResumen: '',
        pdfGenerado: false,
        message: message,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void limpiarWorkflowQr() {
    state = state.copyWith(
      status: MovimientoTelasStatus.idle,
      qrRaw: '',
      qrResumen: '',
      pdfGenerado: false,
      clearError: true,
      clearMessage: true,
    );
  }

  void limpiarMensajes() {
    state = state.copyWith(
      status: MovimientoTelasStatus.idle,
      clearError: true,
      clearMessage: true,
    );
  }

  void notificarError(String message) {
    state = state.copyWith(
      status: MovimientoTelasStatus.error,
      errorMessage: message.trim(),
    );
  }

  void resetFormulario() {
    state = state.copyWith(
      status: MovimientoTelasStatus.idle,
      codigoBase: '',
      correlativo: '',
      numCorte: '',
      qrRaw: '',
      qrResumen: '',
      pdfGenerado: false,
      clearError: true,
      clearMessage: true,
    );
  }

  int _leerContador(String numTelar) {
    final raw = _storage.getValue(
      '$_counterPrefix$numTelar',
      defaultValue: '0',
    );
    return int.tryParse(raw) ?? 0;
  }

  Future<void> _guardarContador(String numTelar, int value) async {
    await _storage.setValue('$_counterPrefix$numTelar', value.toString());
  }

  String _toFechaCodigo(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = (date.year % 100).toString().padLeft(2, '0');
    return '$dd$mm$yy';
  }

  String _buildCodigoCompleto({
    required String codigoBase,
    required String numCorte,
  }) {
    final base = codigoBase.trim();
    final corte = numCorte.trim();
    if (base.isEmpty) return corte;
    if (base.endsWith('-')) return '$base$corte';
    return base;
  }

  String? _validarCamposQr({
    required String codigoBase,
    required String numCorte,
    required String numTelar,
    required String opPrefijo,
    required String opNumero,
    required String articulo,
    required String mts,
    required String peso,
    required String nombre,
  }) {
    if (codigoBase.trim().isEmpty) {
      return 'Primero genere el codigo de tela.';
    }
    if (numCorte.trim().isEmpty ||
        numTelar.trim().isEmpty ||
        opPrefijo.trim().isEmpty ||
        opNumero.trim().isEmpty ||
        articulo.trim().isEmpty ||
        mts.trim().isEmpty ||
        peso.trim().isEmpty ||
        nombre.trim().isEmpty) {
      return 'Complete todos los campos obligatorios antes de generar el QR.';
    }
    return null;
  }

  String _sanitize(String value) {
    return value
        .replaceAll(',', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanError(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.replaceFirst('Exception:', '').trim();
    }
    return raw;
  }
}

final movimientoTelasDatasourceProvider =
    Provider<MovimientoTelasRemoteDatasource>((ref) {
      return MovimientoTelasRemoteDatasource(
        ref.read(apiClientProvider),
        ref.read(localApiClientProvider),
      );
    });

final movimientoTelasProvider =
    StateNotifierProvider<MovimientoTelasNotifier, MovimientoTelasState>((ref) {
      return MovimientoTelasNotifier(
        ref.read(movimientoTelasDatasourceProvider),
        ref.read(localStorageProvider),
      );
    });
