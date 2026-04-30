import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/utils/qr_parser.dart';
import '../../data/datasources/remote/inventario_cero_remote_datasource.dart';
import 'auth_provider.dart';

enum InventarioCeroStatus {
  idle,
  parsingQr,
  verifyingPcp,
  sending,
  success,
  error,
}

enum TipoContenedor { caja, bolsa, saco }

class InventarioCeroState {
  final InventarioCeroStatus status;
  final String qrRaw;
  final QrHilos? parsed;
  final VerificacionPcpResult? verification;

  final TipoContenedor tipoContenedor;
  final String pesoContenedor;
  final String cantidadBobinas;
  final String cantidadReenconado;
  final String pesoBruto;
  final String pesoNeto;
  final String almacen;
  final String ubicacion;
  final String guia;
  final String observaciones;

  final String? message;
  final String? errorMessage;

  const InventarioCeroState({
    this.status = InventarioCeroStatus.idle,
    this.qrRaw = '',
    this.parsed,
    this.verification,
    this.tipoContenedor = TipoContenedor.caja,
    this.pesoContenedor = '0.50',
    this.cantidadBobinas = '',
    this.cantidadReenconado = '0',
    this.pesoBruto = '',
    this.pesoNeto = '',
    this.almacen = 'PLANTA 1',
    this.ubicacion = 'A',
    this.guia = '',
    this.observaciones = '',
    this.message,
    this.errorMessage,
  });

  bool get isBusy =>
      status == InventarioCeroStatus.parsingQr ||
      status == InventarioCeroStatus.verifyingPcp ||
      status == InventarioCeroStatus.sending;

  bool get canSubmit {
    return parsed != null &&
        _toDouble(cantidadBobinas) > 0 &&
        _toDouble(pesoBruto) > 0 &&
        _toDouble(pesoNeto) > 0 &&
        almacen.trim().isNotEmpty &&
        ubicacion.trim().isNotEmpty;
  }

  InventarioCeroState copyWith({
    InventarioCeroStatus? status,
    String? qrRaw,
    QrHilos? parsed,
    bool clearParsed = false,
    VerificacionPcpResult? verification,
    bool clearVerification = false,
    TipoContenedor? tipoContenedor,
    String? pesoContenedor,
    String? cantidadBobinas,
    String? cantidadReenconado,
    String? pesoBruto,
    String? pesoNeto,
    String? almacen,
    String? ubicacion,
    String? guia,
    String? observaciones,
    String? message,
    bool clearMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InventarioCeroState(
      status: status ?? this.status,
      qrRaw: qrRaw ?? this.qrRaw,
      parsed: clearParsed ? null : (parsed ?? this.parsed),
      verification:
          clearVerification ? null : (verification ?? this.verification),
      tipoContenedor: tipoContenedor ?? this.tipoContenedor,
      pesoContenedor: pesoContenedor ?? this.pesoContenedor,
      cantidadBobinas: cantidadBobinas ?? this.cantidadBobinas,
      cantidadReenconado: cantidadReenconado ?? this.cantidadReenconado,
      pesoBruto: pesoBruto ?? this.pesoBruto,
      pesoNeto: pesoNeto ?? this.pesoNeto,
      almacen: almacen ?? this.almacen,
      ubicacion: ubicacion ?? this.ubicacion,
      guia: guia ?? this.guia,
      observaciones: observaciones ?? this.observaciones,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final inventarioCeroDatasourceProvider =
    Provider<InventarioCeroRemoteDatasource>(
      (ref) => InventarioCeroRemoteDatasource(ref.read(apiClientProvider)),
    );

class InventarioCeroNotifier extends StateNotifier<InventarioCeroState> {
  final InventarioCeroRemoteDatasource _datasource;
  bool _submitLock = false;

  InventarioCeroNotifier(this._datasource) : super(const InventarioCeroState());

  void setQrRaw(String value) {
    state = state.copyWith(qrRaw: value, clearError: true, clearMessage: true);
  }

  void setCantidadBobinas(String value) {
    state = state.copyWith(cantidadBobinas: value, clearError: true);
    recalcularPesoNeto();
  }

  void setCantidadReenconado(String value) {
    state = state.copyWith(cantidadReenconado: value, clearError: true);
  }

  void setPesoBruto(String value) {
    state = state.copyWith(pesoBruto: value, clearError: true);
    recalcularPesoNeto();
  }

  void setPesoContenedor(String value) {
    state = state.copyWith(pesoContenedor: value, clearError: true);
    recalcularPesoNeto();
  }

  void setTipoContenedor(TipoContenedor value) {
    final taraDefault = switch (value) {
      TipoContenedor.caja => '0.50',
      TipoContenedor.bolsa => '0.20',
      TipoContenedor.saco => '0.35',
    };
    state = state.copyWith(
      tipoContenedor: value,
      pesoContenedor: taraDefault,
      clearError: true,
    );
    recalcularPesoNeto();
  }

  void setAlmacen(String value) {
    state = state.copyWith(almacen: value, clearError: true);
  }

  void setUbicacion(String value) {
    state = state.copyWith(ubicacion: value, clearError: true);
  }

  void setGuia(String value) {
    state = state.copyWith(guia: value, clearError: true);
  }

  void setObservaciones(String value) {
    state = state.copyWith(observaciones: value);
  }

  void recalcularPesoNeto() {
    final bruto = _toDouble(state.pesoBruto);
    final pesoContenedor = _toDouble(state.pesoContenedor);
    if (bruto <= 0) {
      state = state.copyWith(pesoNeto: '');
      return;
    }
    final neto = (bruto - pesoContenedor).clamp(0.0, 9999999.0).toDouble();
    state = state.copyWith(pesoNeto: neto.toStringAsFixed(2));
  }

  Future<void> parsearQr() async {
    if (state.qrRaw.trim().isEmpty) {
      state = state.copyWith(
        status: InventarioCeroStatus.error,
        errorMessage: 'Ingrese o escanee el QR para continuar',
      );
      return;
    }

    state = state.copyWith(
      status: InventarioCeroStatus.parsingQr,
      clearError: true,
      clearMessage: true,
    );

    try {
      final result = QrParser.parse(state.qrRaw);
      if (!result.isValid || result.hilos == null) {
        throw Exception('El QR no corresponde al formato hilos 14/16');
      }

      final parsed = result.hilos!;
      state = state.copyWith(
        status: InventarioCeroStatus.success,
        parsed: parsed,
        cantidadBobinas: parsed.totalBobinas.toStringAsFixed(0),
        pesoBruto: parsed.pesoBruto.toStringAsFixed(2),
        message: 'QR de inventario parseado correctamente',
      );
      recalcularPesoNeto();
    } catch (error) {
      state = state.copyWith(
        status: InventarioCeroStatus.error,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> verificarPcp() async {
    final codigo = state.parsed?.codigoPcp ?? '';
    if (codigo.trim().isEmpty) {
      state = state.copyWith(
        status: InventarioCeroStatus.error,
        errorMessage: 'Primero debe parsear un QR valido',
      );
      return;
    }

    state = state.copyWith(
      status: InventarioCeroStatus.verifyingPcp,
      clearError: true,
      clearMessage: true,
    );

    try {
      final verification = await _datasource.verificarPcp(codigo);
      final msg =
          verification.existe
              ? 'PCP ya existe en inventario (fila ${verification.fila})'
              : 'PCP aun no existe en inventario cero';
      state = state.copyWith(
        status: InventarioCeroStatus.success,
        verification: verification,
        message: msg,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: InventarioCeroStatus.error,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> registrarInventario({required String usuario}) async {
    if (_submitLock || state.isBusy) return;
    if (!state.canSubmit || state.parsed == null) {
      state = state.copyWith(
        status: InventarioCeroStatus.error,
        errorMessage: 'Complete los datos obligatorios para registrar',
      );
      return;
    }

    _submitLock = true;
    try {
      final parsed = state.parsed!;
      state = state.copyWith(
        status: InventarioCeroStatus.sending,
        clearError: true,
        clearMessage: true,
      );

      final result = await _datasource.registrarInventario(
        codigoPcp: parsed.codigoPcp,
        codigoKardex: parsed.codigoKardex,
        material: parsed.material,
        titulo: parsed.titulo,
        color: parsed.color,
        lote: parsed.lote,
        caja: parsed.numCajas.toStringAsFixed(0),
        cantidadBobinas: state.cantidadBobinas,
        cantidadReenconado: state.cantidadReenconado,
        pesoBruto: state.pesoBruto,
        pesoNeto: state.pesoNeto,
        proveedor: parsed.proveedor,
        fechaIngreso:
            parsed.fechaIngreso?.trim().isNotEmpty == true
                ? parsed.fechaIngreso!
                : '',
        almacen: state.almacen,
        ubicacion: state.ubicacion,
        servicio: parsed.servicio,
        guia: state.guia.isNotEmpty ? state.guia : parsed.guia,
        responsable: usuario,
      );

      state = state.copyWith(
        status: InventarioCeroStatus.success,
        message:
            '${result.message} | ${result.codigoPcp} | ${result.almacen}-${result.ubicacion}',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: InventarioCeroStatus.error,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      _submitLock = false;
    }
  }

  void limpiar() {
    state = InventarioCeroState(
      almacen: AppConstants.almacenes.first,
      ubicacion: 'A',
    );
  }
}

final inventarioCeroProvider = StateNotifierProvider<
  InventarioCeroNotifier,
  InventarioCeroState
>((ref) => InventarioCeroNotifier(ref.read(inventarioCeroDatasourceProvider)));

double _toDouble(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}
