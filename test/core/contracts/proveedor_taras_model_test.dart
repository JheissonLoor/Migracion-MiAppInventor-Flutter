import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/data/datasources/remote/proveedor_remote_datasource.dart';

void main() {
  group('ProveedorTarasModel parsing legacy', () {
    test('parsea mapa con llaves legacy de Apps Script', () {
      final model = ProveedorTarasModel.fromDynamic({
        'Tara cono': ' 0.45 ',
        'Tara bolsa': '0.80',
        'Tara Caja': ' 1.20',
        'Tara Saco': '2.00 ',
      });

      expect(model.taraCono, '0.45');
      expect(model.taraBolsa, '0.80');
      expect(model.taraCaja, '1.20');
      expect(model.taraSaco, '2.00');
    });

    test('parsea mapa con llaves snake_case internas', () {
      final model = ProveedorTarasModel.fromDynamic({
        'tara_cono': '0.10',
        'tara_bolsa': '0.20',
        'tara_caja': '0.30',
        'tara_saco': '0.40',
      });

      expect(model.taraCono, '0.10');
      expect(model.taraBolsa, '0.20');
      expect(model.taraCaja, '0.30');
      expect(model.taraSaco, '0.40');
    });

    test('parsea respuesta string con JSON', () {
      final model = ProveedorTarasModel.fromDynamic('''
        {"taraCono":"0.55","taraBolsa":"0.75","taraCaja":"1.10","taraSaco":"1.80"}
      ''');

      expect(model.taraCono, '0.55');
      expect(model.taraBolsa, '0.75');
      expect(model.taraCaja, '1.10');
      expect(model.taraSaco, '1.80');
    });

    test('toQueryMap mantiene contrato esperado y trims', () {
      final model = ProveedorTarasModel(
        taraCono: ' 0.5 ',
        taraBolsa: '0.7 ',
        taraCaja: ' 1.1',
        taraSaco: ' 1.9 ',
      );

      final query = model.toQueryMap(codigo: '  PCP-001 ');

      expect(query, {
        'codigo': 'PCP-001',
        'tara_cono': '0.5',
        'tara_bolsa': '0.7',
        'tara_caja': '1.1',
        'tara_saco': '1.9',
      });
    });

    test('lanza excepcion cuando el formato es invalido', () {
      expect(
        () => ProveedorTarasModel.fromDynamic(12345),
        throwsA(isA<Exception>()),
      );
    });
  });
}
