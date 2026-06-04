import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/qr_image_encoder.dart';
import '../../data/datasources/remote/movimiento_telas_remote_datasource.dart';
import 'auth_provider.dart';

enum MovimientoTelasStatus {
  idle,
  loadingCatalogos,
  generatingCode,
  searchingEdit,
  sendingCorte,
  savingEdit,
  validatingRendimiento,
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
  final MovimientoTelaEdicionData? edicionData;
  final MovimientoTelaRendimientoData? rendimiento;
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
    this.edicionData,
    this.rendimiento,
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == MovimientoTelasStatus.loadingCatalogos ||
      status == MovimientoTelasStatus.generatingCode ||
      status == MovimientoTelasStatus.searchingEdit ||
      status == MovimientoTelasStatus.sendingCorte ||
      status == MovimientoTelasStatus.savingEdit ||
      status == MovimientoTelasStatus.validatingRendimiento ||
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
    MovimientoTelaEdicionData? edicionData,
    bool clearEdicionData = false,
    MovimientoTelaRendimientoData? rendimiento,
    bool clearRendimiento = false,
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
      edicionData: clearEdicionData ? null : (edicionData ?? this.edicionData),
      rendimiento: clearRendimiento ? null : (rendimiento ?? this.rendimiento),
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MovimientoTelasNotifier extends StateNotifier<MovimientoTelasState> {
  final MovimientoTelasRemoteDatasource _datasource;

  MovimientoTelasNotifier(this._datasource)
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
      clearEdicionData: true,
    );

    try {
      final fechaCode = _toFechaCodigo(fechaRevisado);
      final codigo = await _datasource.reservarSiguienteCodigo(
        numTelar: telar,
        fechaCodigo: fechaCode,
      );

      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        codigoBase: codigo.codigoBase,
        correlativo: codigo.correlativo,
        numCorte: codigo.numCorte,
        qrRaw: '',
        qrResumen: '',
        pdfGenerado: false,
        message:
            codigo.codigoSugerido.isNotEmpty
                ? 'Codigo reservado: ${codigo.codigoSugerido}.'
                : 'Codigo generado correctamente.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void generarQr({
    required String codigoBase,
    required String correlativo,
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
      correlativo: correlativo,
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
      correlativo: correlativo,
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
      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        codigoBase: '',
        correlativo: '',
        numCorte: '',
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

  Future<void> buscarTelaParaEditar(String codigoTela) async {
    final codigo = codigoTela.trim();
    if (codigo.isEmpty) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: 'Ingrese el codigo de tela para editar.',
      );
      return;
    }

    state = state.copyWith(
      status: MovimientoTelasStatus.searchingEdit,
      clearError: true,
      clearMessage: true,
      clearEdicionData: true,
      clearRendimiento: true,
    );

    try {
      final data = await _datasource.buscarTelaCruda(codigo);
      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        edicionData: data,
        codigoBase: data.codigoBase,
        correlativo: data.correlativo,
        numCorte: data.numCorte,
        qrRaw: '',
        qrResumen: '',
        pdfGenerado: false,
        message: 'Tela encontrada. Revise los campos antes de editar.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: MovimientoTelasStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> editarTelaCruda(MovimientoTelaEditPayload payload) async {
    state = state.copyWith(
      status: MovimientoTelasStatus.savingEdit,
      clearError: true,
      clearMessage: true,
    );

    try {
      final message = await _datasource.editarTelaCruda(payload);
      state = state.copyWith(
        status: MovimientoTelasStatus.success,
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

  Future<void> validarRendimiento({
    required String articulo,
    required String mts,
    required String peso,
  }) async {
    if (articulo.trim().isEmpty || mts.trim().isEmpty || peso.trim().isEmpty) {
      return;
    }

    state = state.copyWith(
      status: MovimientoTelasStatus.validatingRendimiento,
      clearError: true,
      clearMessage: true,
    );

    try {
      final data = await _datasource.validarRendimiento(
        articulo: articulo,
        mts: mts,
        peso: peso,
      );
      state = state.copyWith(
        status: MovimientoTelasStatus.success,
        rendimiento: data,
        message: data.message,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        status: MovimientoTelasStatus.idle,
        clearRendimiento: true,
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
      clearEdicionData: true,
      clearRendimiento: true,
      clearError: true,
      clearMessage: true,
    );
  }

  String _toFechaCodigo(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = (date.year % 100).toString().padLeft(2, '0');
    return '$dd$mm$yy';
  }

  String _buildCodigoCompleto({
    required String codigoBase,
    required String correlativo,
  }) {
    final base = codigoBase.trim();
    final suffix = correlativo.trim();
    if (base.isEmpty) return suffix;
    if (base.endsWith('-')) return '$base$suffix';
    return base;
  }

  String? _validarCamposQr({
    required String codigoBase,
    required String correlativo,
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
    if (correlativo.trim().isEmpty ||
        numCorte.trim().isEmpty ||
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
      );
    });
