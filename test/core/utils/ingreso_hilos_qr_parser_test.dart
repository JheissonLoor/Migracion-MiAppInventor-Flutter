import 'package:coolimport_pcp/core/utils/ingreso_hilos_qr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IngresoHilosQrParser', () {
    test('parsea QR de 14 campos', () {
      const raw =
          'PCP-1001,POLIESTER,30/1,AZUL,LOTE-9,4,80,0,120.5,118.0,PROV-X,01/02/2026,ALM-1,U-09';

      final result = IngresoHilosQrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.data?.camposDetectados, 14);
      expect(result.data?.codigoPcp, 'PCP-1001');
      expect(result.data?.codigoKardex, isEmpty);
      expect(result.data?.almacen, 'ALM-1');
      expect(result.data?.ubicacion, 'U-09');
    });

    test('parsea QR de 16 campos con kardex y servicio', () {
      const raw =
          'KDX-77,PCP-2002,POLIESTER,24/1,"AZUL, REY",LOTE-3,6,120,0,210.0,208.5,PROV-Y,03/02/2026,ALM-2,U-04,SERVICIO-A';

      final result = IngresoHilosQrParser.parse(raw);

      expect(result.isValid, isTrue);
      expect(result.data?.camposDetectados, 16);
      expect(result.data?.codigoKardex, 'KDX-77');
      expect(result.data?.codigoPcp, 'PCP-2002');
      expect(result.data?.color, 'AZUL, REY');
      expect(result.data?.servicio, 'SERVICIO-A');
    });

    test(
      'colapsa overflow cuando hay coma interna sin comillas en formato 14',
      () {
        const raw =
            'PCP-3003,POLI,ESTER,40/1,ROJO,L-7,3,45,0,80.0,78.5,PROV-Z,05/02/2026,ALM-3,U-11';

        final result = IngresoHilosQrParser.parse(raw);

        expect(result.isValid, isTrue);
        expect(result.data?.camposDetectados, 14);
        expect(result.data?.material, 'POLI,ESTER');
        expect(result.data?.titulo, '40/1');
      },
    );

    test('falla cuando no coincide el numero de campos', () {
      const raw = 'A,B,C,D,E';
      final result = IngresoHilosQrParser.parse(raw);

      expect(result.isValid, isFalse);
      expect(result.error, contains('Solo se admite QR de 14 o 16 campos'));
    });
  });
}
