import 'package:flutter_test/flutter_test.dart';

import 'package:coolimport_pcp/data/models/etiqueta_payload.dart';

void main() {
  group('EtiquetaPayloadBuilder', () {
    test('construye payload para QR de tela 8 campos', () {
      const raw = 'T14F211125-1,NC-11,TELAR-02,OP-778,RIP STOP,127,45,JULIO';

      final payload = EtiquetaPayloadBuilder.fromQrRaw(raw);

      expect(payload.codigo, 'T14F211125-1');
      expect(payload.lote, 'NC-11');
      expect(payload.articulo, 'RIP STOP');
      expect(payload.metraje, '127.00');
      expect(payload.revisador, 'JULIO');
      expect(payload.text.contains('RIP STOP'), isTrue);
    });

    test('hace fallback cuando QR no es reconocido', () {
      const raw = 'valor1,valor2,valor3';

      final payload = EtiquetaPayloadBuilder.fromQrRaw(raw);

      expect(payload.qrRaw, raw);
      expect(payload.text.contains('\n'), isTrue);
    });

    test('aplica kardex generado a QR de hilos antes de imprimir', () {
      const raw =
          'H180225-302,,POLYESTER,75/36/1 P.A,VERDE MILITAR 577-18,108,'
          'IMPORTADO,NO,GUIA-1,302,0,7.94,2.78,A';

      final payload = EtiquetaPayloadBuilder.fromQrRaw(
        raw,
        codigoKardexOverride: '100175/36/1PA/VERMIL577-18',
      );

      expect(payload.codigo, 'H180225-302');
      expect(payload.codigoKardex, '100175/36/1PA/VERMIL577-18');
      expect(payload.text.contains('100175/36/1PA/VERMIL577-18'), isTrue);
      expect(payload.qrRaw.split(',')[1], '100175/36/1PA/VERMIL577-18');
    });
  });
}
