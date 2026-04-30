import 'package:coolimport_pcp/core/utils/qr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrParser', () {
    test('parsea hilos 16 campos', () {
      const raw =
          'PCP-1001,CK-9981,HILO RING,40/1,BLANCO,L-01,PROVEEDOR SAC,SERVICIO X,G-222,12,240,420.5,415.2,RACK-A1,PLANTA 1,2026-02-11';

      final result = QrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.tipo, QrTipo.hilos16);
      expect(result.hilos?.codigoPcp, 'PCP-1001');
      expect(result.hilos?.almacen, 'PLANTA 1');
      expect(result.hilos?.fechaIngreso, '2026-02-11');
    });

    test('parsea hilos 14 con coma interna en texto', () {
      const raw =
          'PCP-1002,CK-9982,HILO PEINADO, ALGODON,30/1,NEGRO,L-02,PROV SAC,SERV Y,G-333,10,210,380,372,RACK-B2';

      final result = QrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.tipo, QrTipo.hilos14);
      expect(result.hilos?.material, 'HILO PEINADO,ALGODON');
      expect(result.hilos?.titulo, '30/1');
    });

    test('parsea tela 8 con comillas y comas internas', () {
      const raw =
          '"T1C150126-01",23,46,OPV2512001,"TOCUYO GRUESO, TIPO A",166,288,JOSE MESONES';

      final result = QrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.tipo, QrTipo.telaCruda8);
      expect(result.telaCruda?.codigoTela, 'T1C150126-01');
      expect(result.telaCruda?.articulo, 'TOCUYO GRUESO, TIPO A');
    });

    test('parsea legacy 6 con coma interna en articulo', () {
      const raw = 'LGC-01,ARTICULO PREMIUM, CRUDO,120.5,210,U-3,2026-02-10';

      final result = QrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.tipo, QrTipo.legacy6);
      expect(result.legacy?.articulo, 'ARTICULO PREMIUM,CRUDO');
      expect(result.legacy?.metros, 120.5);
    });

    test(
      'normaliza numericos con coma decimal cuando vienen entre comillas',
      () {
        const raw = 'T1-01,1,2,OP1,ART X,"166,5","288,25",REV';

        final result = QrParser.parse(raw);

        expect(result.isValid, isTrue);
        expect(result.tipo, QrTipo.telaCruda8);
        expect(result.telaCruda?.metraje, 166.5);
        expect(result.telaCruda?.peso, 288.25);
      },
    );

    test('retorna error si el QR esta vacio', () {
      final result = QrParser.parse('   ');

      expect(result.isValid, isFalse);
      expect(result.tipo, QrTipo.desconocido);
      expect(result.error, contains('vacio'));
    });

    test('retorna error en formato no reconocido', () {
      final result = QrParser.parse('dato1,dato2,dato3');

      expect(result.isValid, isFalse);
      expect(result.tipo, QrTipo.desconocido);
      expect(result.error, contains('Formato QR no reconocido'));
    });
  });
}
