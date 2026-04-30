import '../../../core/contracts/api_contracts.dart';
import '../../../core/network/api_client.dart';
import '../../models/etiqueta_payload.dart';

class ImpresionEtiquetaResult {
  final String message;
  final String etapa;

  const ImpresionEtiquetaResult({required this.message, required this.etapa});
}

class ImpresionLocalRemoteDatasource {
  final LocalApiClient _localClient;

  const ImpresionLocalRemoteDatasource(this._localClient);

  Future<bool> isApiDisponible() {
    return _localClient.isAvailable();
  }

  Future<ImpresionEtiquetaResult> generarPdfEtiqueta({
    required EtiquetaPayload payload,
    required String imageBase64,
  }) async {
    final response = await _localClient.post(
      ApiRoutes.localGeneratePdf,
      data: payload.toGeneratePdfBody(imageBase64: imageBase64),
    );

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo generar el PDF de etiqueta',
      );
    }

    final map = response.data;
    if (map is! Map) {
      throw Exception('Respuesta invalida de /generate_pdf');
    }

    final success = map['success'] == true;
    final message = (map['message'] ?? '').toString();

    if (!success) {
      throw Exception(
        message.isNotEmpty ? message : 'La API local rechazo la generacion PDF',
      );
    }

    return ImpresionEtiquetaResult(
      message: message.isNotEmpty ? message : 'PDF de etiqueta generado',
      etapa: 'generate_pdf',
    );
  }

  Future<ImpresionEtiquetaResult> imprimirEtiqueta() async {
    final response = await _localClient.post(ApiRoutes.localImprimir);

    if (!response.success) {
      throw Exception(
        response.message ?? 'No se pudo imprimir etiqueta en Zebra',
      );
    }

    final map = response.data;
    if (map is! Map) {
      throw Exception('Respuesta invalida de /imprimir');
    }

    final success = map['success'] == true;
    final message = (map['message'] ?? '').toString();

    if (!success) {
      throw Exception(
        message.isNotEmpty ? message : 'La API local rechazo la impresion',
      );
    }

    return ImpresionEtiquetaResult(
      message: message.isNotEmpty ? message : 'Etiqueta enviada a Zebra',
      etapa: 'imprimir',
    );
  }
}
