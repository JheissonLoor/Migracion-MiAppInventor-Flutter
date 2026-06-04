import 'package:coolimport_pcp/core/contracts/api_contracts.dart';
import 'package:coolimport_pcp/core/network/api_client.dart';
import 'package:coolimport_pcp/core/storage/local_storage.dart';
import 'package:coolimport_pcp/data/datasources/remote/movimiento_telas_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends ApiClient {
  final dynamic postPayload;
  final dynamic getPayload;

  int getCalls = 0;
  String? lastGetEndpoint;

  _FakeApiClient({required this.postPayload, required this.getPayload});

  @override
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    return ApiResponse.success(postPayload, 200);
  }

  @override
  Future<ApiResponse> get(String endpoint) async {
    getCalls++;
    lastGetEndpoint = endpoint;
    return ApiResponse.success(getPayload, 200);
  }
}

void main() {
  group('MovimientoTelasRemoteDatasource catalogos', () {
    test(
      'carga codigos de falla desde read_column legacy cuando no vienen en generales',
      () async {
        final api = _FakeApiClient(
          postPayload: {
            'articulos': ['ART 1', 'ART 2'],
          },
          getPayload: [
            '',
            'T1 - CAMARONES',
            'T2 - COSTURA.TEJ',
            'cod_falla',
            'T1 - CAMARONES',
          ],
        );
        final datasource = MovimientoTelasRemoteDatasource(
          api,
          LocalApiClient(LocalStorage()),
        );

        final data = await datasource.obtenerCatalogos();

        expect(data.articulos, ['ART 1', 'ART 2']);
        expect(data.codigosFalla, ['T1 - CAMARONES', 'T2 - COSTURA.TEJ']);
        expect(api.getCalls, 1);
        expect(api.lastGetEndpoint, ApiRoutes.readDatosKardexColumn(15));
      },
    );
  });
}
