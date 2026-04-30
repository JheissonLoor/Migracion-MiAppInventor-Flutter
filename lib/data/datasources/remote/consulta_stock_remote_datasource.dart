import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/consulta_stock_qr_codec.dart';
import 'legacy_modules_remote_datasource.dart';

class ConsultaStockResult {
  final String codigoConsultado;
  final IngresoStockActualData stock;

  const ConsultaStockResult({
    required this.codigoConsultado,
    required this.stock,
  });
}

class ConsultaStockRemoteDatasource {
  final ApiClient _client;

  const ConsultaStockRemoteDatasource(this._client);

  Future<ConsultaStockResult> consultarStockActual(
    String codigoPcp, {
    String fallbackCodigoPcp = '',
    String fallbackCodigoKardex = '',
  }) async {
    final resolved = ConsultaStockQrCodec.resolveInput(codigoPcp);
    final query = resolved.codigoConsulta.trim();
    if (query.isEmpty) {
      throw Exception('Ingrese un codigo PCP');
    }

    final response = await _client.post(
      ApiRoutes.stockActualPcp,
      data: ApiPayloads.stockActualPcp(query),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo consultar el stock actual',
      );
    }

    final data = response.responseData;
    if (data is String && data.toLowerCase().contains('not found')) {
      throw Exception(
        response.responseMessage.trim().isNotEmpty
            ? response.responseMessage
            : 'No se encontraron datos para el codigo escaneado',
      );
    }

    IngresoStockActualData stock;
    try {
      stock = IngresoStockActualData.fromDynamic(
        data,
        fallbackCodigoPcp:
            fallbackCodigoPcp.trim().isNotEmpty
                ? fallbackCodigoPcp.trim()
                : resolved.codigoPcp,
        fallbackCodigoKardex:
            fallbackCodigoKardex.trim().isNotEmpty
                ? fallbackCodigoKardex.trim()
                : resolved.codigoKardex,
      );
    } catch (_) {
      final message = response.responseMessage.trim();
      if (message.isNotEmpty) {
        throw Exception(message);
      }
      throw Exception('Respuesta inesperada en /stock_actual_pcp');
    }

    return ConsultaStockResult(codigoConsultado: query, stock: stock);
  }
}
