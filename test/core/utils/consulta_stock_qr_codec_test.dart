import 'package:coolimport_pcp/core/utils/consulta_stock_qr_codec.dart';
import 'package:coolimport_pcp/core/utils/qr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsultaStockQrCodec', () {
    test('extrae PCP y kardex desde QR legacy de 16 campos', () {
      const raw =
          '100175/36/1PA/LAD1760,H190225-304,POLYESTER,75/36/1 P.A,'
          'LADRILLO 1760,127,304,8,0,17.00,14.84,IMPORTADO,,PLANTA 1,A,NO';

      final resolved = ConsultaStockQrCodec.resolveInput(raw);

      expect(resolved.codigoConsulta, 'H190225-304');
      expect(resolved.codigoPcp, 'H190225-304');
      expect(resolved.codigoKardex, '100175/36/1PA/LAD1760');
      expect(resolved.tokens.length, 16);
    });

    test(
      'mantiene codigo directo cuando el usuario lo ingresa manualmente',
      () {
        final resolved = ConsultaStockQrCodec.resolveInput('PCP-2026-001');

        expect(resolved.codigoConsulta, 'PCP-2026-001');
        expect(resolved.codigoPcp, 'PCP-2026-001');
        expect(resolved.codigoKardex, isEmpty);
      },
    );

    test('parsea respuesta backend legacy 16 y mapea campos clave', () {
      const raw =
          '100175/36/1PA/LAD1760,H190225-304,POLYESTER,75/36/1 P.A,'
          'LADRILLO 1760,127,304,8,0,17.00,14.84,IMPORTADO,,PLANTA 1,A,NO';

      final parsed = ConsultaStockQrCodec.parseBackendRaw(raw);

      expect(parsed.isValid, isTrue);
      expect(parsed.tipo, QrTipo.hilos16);
      expect(parsed.hilos?.codigoPcp, 'H190225-304');
      expect(parsed.hilos?.codigoKardex, '100175/36/1PA/LAD1760');
      expect(parsed.hilos?.almacen, 'PLANTA 1');
      expect(parsed.hilos?.ubicacion, 'A');
      expect(parsed.hilos?.servicio, 'NO');
    });

    test('parsea respuesta backend legacy 14 sin kardex', () {
      const raw =
          'H190225-304,POLYESTER,75/36/1 P.A,LADRILLO 1760,127,304,8,0,'
          '17.00,14.84,IMPORTADO,,PLANTA 1,A';

      final parsed = ConsultaStockQrCodec.parseBackendRaw(raw);

      expect(parsed.isValid, isTrue);
      expect(parsed.tipo, QrTipo.hilos14);
      expect(parsed.hilos?.codigoPcp, 'H190225-304');
      expect(parsed.hilos?.codigoKardex, isEmpty);
      expect(parsed.hilos?.almacen, 'PLANTA 1');
      expect(parsed.hilos?.ubicacion, 'A');
    });

    test(
      'usa heuristica para detectar PCP cuando el formato es incompleto',
      () {
        const raw = 'abc/12/34,H190225-304,dato suelto';

        final resolved = ConsultaStockQrCodec.resolveInput(raw);

        expect(resolved.codigoConsulta, 'H190225-304');
        expect(resolved.codigoPcp, 'H190225-304');
      },
    );
  });
}
