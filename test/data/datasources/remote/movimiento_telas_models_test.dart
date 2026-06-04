import 'package:coolimport_pcp/data/datasources/remote/movimiento_telas_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Movimiento telas models', () {
    test('parsea busqueda_tela_cruda en orden MIT', () {
      final data = MovimientoTelaEdicionData.fromDynamic({
        'data': [
          '30',
          'T30F030626',
          '1-01',
          'OPV',
          '12345',
          'ART-01',
          '7',
          '288',
          '1.80',
          '24.5',
          '1 - Normal',
          'C',
          '03/06/2026',
          '04/06/2026',
          'F1',
          'F2',
          '',
          'F4',
          'PRINCIPAL',
          '1',
          'Jheisson',
        ],
      });

      expect(data.codigoBase, 'T30F030626-');
      expect(data.correlativo, '1-01');
      expect(data.codigoCompleto, 'T30F030626-1-01');
      expect(data.fallasSecundarias, ['F1', 'F2', '', 'F4']);
      expect(data.fallaPrincipal, 'PRINCIPAL');
    });

    test('parsea correlativo reservado FASE3', () {
      final data = MovimientoTelaCodigoData.fromMap({
        'message': 'ok',
        'corte': '2',
        'correlativo': '02',
        'telas_cod': 'T30F030626-2-',
        'codigo_sugerido': 'T30F030626-2-02',
      });

      expect(data.codigoBase, 'T30F030626-2-');
      expect(data.correlativo, '02');
      expect(data.numCorte, '2');
      expect(data.codigoSugerido, 'T30F030626-2-02');
    });
  });
}
