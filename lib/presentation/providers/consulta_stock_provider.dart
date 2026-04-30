import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/consulta_stock_qr_codec.dart';
import '../../data/datasources/remote/consulta_stock_remote_datasource.dart';
import 'auth_provider.dart';

enum ConsultaStockStatus { initial, loading, success, error }

class ConsultaStockState {
  final ConsultaStockStatus status;
  final ConsultaStockResult? result;
  final String? errorMessage;
  final String ultimaConsulta;
  final String codigoPcpDetectado;
  final String codigoKardexDetectado;
  final String inputRaw;

  const ConsultaStockState({
    this.status = ConsultaStockStatus.initial,
    this.result,
    this.errorMessage,
    this.ultimaConsulta = '',
    this.codigoPcpDetectado = '',
    this.codigoKardexDetectado = '',
    this.inputRaw = '',
  });

  ConsultaStockState copyWith({
    ConsultaStockStatus? status,
    ConsultaStockResult? result,
    String? errorMessage,
    String? ultimaConsulta,
    String? codigoPcpDetectado,
    String? codigoKardexDetectado,
    String? inputRaw,
  }) {
    return ConsultaStockState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
      ultimaConsulta: ultimaConsulta ?? this.ultimaConsulta,
      codigoPcpDetectado: codigoPcpDetectado ?? this.codigoPcpDetectado,
      codigoKardexDetectado:
          codigoKardexDetectado ?? this.codigoKardexDetectado,
      inputRaw: inputRaw ?? this.inputRaw,
    );
  }
}

final consultaStockDatasourceProvider = Provider<ConsultaStockRemoteDatasource>(
  (ref) => ConsultaStockRemoteDatasource(ref.read(apiClientProvider)),
);

class ConsultaStockNotifier extends StateNotifier<ConsultaStockState> {
  final ConsultaStockRemoteDatasource _datasource;

  ConsultaStockNotifier(this._datasource) : super(const ConsultaStockState());

  Future<void> consultar(String codigoPcp) async {
    final resolved = ConsultaStockQrCodec.resolveInput(codigoPcp);
    final query = resolved.codigoConsulta.trim();
    if (query.isEmpty) {
      state = const ConsultaStockState(
        status: ConsultaStockStatus.error,
        errorMessage: 'Ingrese un codigo PCP valido',
      );
      return;
    }

    state = ConsultaStockState(
      status: ConsultaStockStatus.loading,
      ultimaConsulta: query,
      codigoPcpDetectado: resolved.codigoPcp,
      codigoKardexDetectado: resolved.codigoKardex,
      inputRaw: resolved.inputRaw,
    );

    try {
      final result = await _datasource.consultarStockActual(
        query,
        fallbackCodigoPcp: resolved.codigoPcp,
        fallbackCodigoKardex: resolved.codigoKardex,
      );
      state = ConsultaStockState(
        status: ConsultaStockStatus.success,
        result: result,
        ultimaConsulta: query,
        codigoPcpDetectado: resolved.codigoPcp,
        codigoKardexDetectado: resolved.codigoKardex,
        inputRaw: resolved.inputRaw,
      );
    } catch (error) {
      state = ConsultaStockState(
        status: ConsultaStockStatus.error,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
        ultimaConsulta: query,
        codigoPcpDetectado: resolved.codigoPcp,
        codigoKardexDetectado: resolved.codigoKardex,
        inputRaw: resolved.inputRaw,
      );
    }
  }

  void reset() {
    state = const ConsultaStockState();
  }
}

final consultaStockProvider =
    StateNotifierProvider<ConsultaStockNotifier, ConsultaStockState>(
      (ref) => ConsultaStockNotifier(ref.read(consultaStockDatasourceProvider)),
    );
