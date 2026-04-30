import 'package:coolimport_pcp/core/utils/cambio_almacen_qr_parser.dart';
import 'package:coolimport_pcp/core/utils/cambio_ubicacion_qr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CambioAlmacenQrParser', () {
    test('parsea formato 12 campos', () {
      const raw =
          'TELAR-1,COD-001,OP-999,ART-50,PLG-03,120,24.5,10/02/2026,11/02/2026,X,Y,SERVICIO-A';

      final result = CambioAlmacenQrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.data?.camposDetectados, 12);
      expect(result.data?.numTelar, 'TELAR-1');
      expect(result.data?.codigoTelas, 'COD-001');
      expect(result.data?.servicio, 'SERVICIO-A');
    });

    test('parsea formato 16 campos con offsets legacy', () {
      const raw =
          'A,B,TELAR-77,COD-TELA-9,OP-3,ART-X,NP-5,90,15.1,01/01/2026,02/01/2026,AA,BB,CC,DD,SERV-16';

      final result = CambioAlmacenQrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.data?.camposDetectados, 16);
      expect(result.data?.numTelar, 'B');
      expect(result.data?.codigoTelas, 'TELAR-77');
      expect(result.data?.servicio, 'SERV-16');
    });

    test('falla cuando la cantidad de campos no es valida', () {
      const raw = 'A,B,C';
      final result = CambioAlmacenQrParser.parse(raw);

      expect(result.isValid, isFalse);
      expect(result.error, contains('Se espera 12, 14 o 16'));
    });
  });

  group('CambioUbicacionQrParser', () {
    test('parsea formato 14 campos sin kardex', () {
      const raw = 'PCP-1,MAT,TIT,COL,LOT,8,A,B,C,D,E,F,G,H';

      final result = CambioUbicacionQrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.data?.camposDetectados, 14);
      expect(result.data?.codigoKardex, isEmpty);
      expect(result.data?.codigoPcp, 'PCP-1');
      expect(result.data?.numCaja, '8');
    });

    test('parsea formato 16 campos con kardex', () {
      const raw = 'KDX-9,PCP-99,MAT,TIT,COL,LOT,5,A,B,C,D,E,F,G,H,SERV-X';

      final result = CambioUbicacionQrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.data?.camposDetectados, 16);
      expect(result.data?.codigoKardex, 'KDX-9');
      expect(result.data?.codigoPcp, 'PCP-99');
      expect(result.data?.servicio, 'SERV-X');
    });

    test('falla cuando la cantidad de campos no es valida', () {
      const raw = 'A,B,C,D';
      final result = CambioUbicacionQrParser.parse(raw);

      expect(result.isValid, isFalse);
      expect(result.error, contains('Se espera 14 o 16'));
    });
  });
}
