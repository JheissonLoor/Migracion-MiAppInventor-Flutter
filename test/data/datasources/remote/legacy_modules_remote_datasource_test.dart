import 'package:coolimport_pcp/data/datasources/remote/legacy_modules_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IngresoStockActualData', () {
    test('mapea formato legacy de 19 campos en orden MIT', () {
      final data = IngresoStockActualData.fromList(const [
        '100175/36/1PA/VERMIL',
        'H180225-302',
        'POLYESTER',
        '75/36/1 P.A',
        'VERDE MILITAR 577-18',
        '108',
        '302',
        '0',
        '104',
        '7.94',
        '2.78',
        'IMPORTADO',
        '18/2/2025',
        '',
        '',
        'PLANTA 1',
        'A',
        'NO',
        'Percy',
      ]);

      expect(data.codigoKardex, '100175/36/1PA/VERMIL');
      expect(data.codigoPcp, 'H180225-302');
      expect(data.material, 'POLYESTER');
      expect(data.color, 'VERDE MILITAR 577-18');
      expect(data.almacen, 'PLANTA 1');
      expect(data.ubicacion, 'A');
      expect(data.nombre, 'Percy');
    });

    test('mapea formato legacy de 15 campos sin desplazar PCP/Kardex', () {
      final data = IngresoStockActualData.fromList(const [
        'H180225-302',
        'POLYESTER',
        '75/36/1 P.A',
        'VERDE MILITAR 577-18',
        '100175/36/1PA/VERMIL577-18',
        '108',
        'IMPORTADO',
        'NO',
        '302.0',
        '0.0',
        '7.94',
        '2.78',
        'A',
        'PLANTA 1',
        '18/2/2025',
      ]);

      expect(data.codigoPcp, 'H180225-302');
      expect(data.codigoKardex, '100175/36/1PA/VERMIL577-18');
      expect(data.material, 'POLYESTER');
      expect(data.titulo, '75/36/1 P.A');
      expect(data.color, 'VERDE MILITAR 577-18');
      expect(data.numCajas, '302.0');
      expect(data.totalBobinas, '0.0');
      expect(data.fechaIngreso, '18/2/2025');
    });

    test('mapea formato legacy QR de 16 campos', () {
      final data = IngresoStockActualData.fromList(const [
        '100175/36/1PA/LAD1760',
        'H190225-304',
        'POLYESTER',
        '75/36/1 P.A',
        'LADRILLO 1760',
        '127',
        '304',
        '8',
        '0',
        '17.00',
        '14.84',
        'IMPORTADO',
        '',
        'PLANTA 1',
        'A',
        'NO',
      ]);

      expect(data.codigoKardex, '100175/36/1PA/LAD1760');
      expect(data.codigoPcp, 'H190225-304');
      expect(data.material, 'POLYESTER');
      expect(data.almacen, 'PLANTA 1');
      expect(data.ubicacion, 'A');
      expect(data.servicio, 'NO');
    });

    test('usa fallback de PCP/Kardex cuando vienen vacios', () {
      final data = IngresoStockActualData.fromList(
        const ['', '', 'POLYESTER', '75/36/1 P.A'],
        fallbackCodigoPcp: 'H999999-001',
        fallbackCodigoKardex: '100000/TEST',
      );

      expect(data.codigoPcp, 'H999999-001');
      expect(data.codigoKardex, '100000/TEST');
    });
  });
}
