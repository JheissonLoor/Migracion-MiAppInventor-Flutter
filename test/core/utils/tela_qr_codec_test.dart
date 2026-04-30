import 'package:coolimport_pcp/core/utils/tela_qr_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelaQrCodec', () {
    test('normaliza QR de tela para backend de 8 campos', () {
      const raw =
          '"T1C150126-01",23,46,OPV2512001,"TOCUYO GRUESO, TIPO A",166,288,JOSE MESONES';

      final normalized = TelaQrCodec.normalizeForIngreso(raw);

      expect(
        normalized.codigoQrNormalizado,
        'T1C150126-01,23,46,OPV2512001,TOCUYO GRUESO TIPO A,166,288,JOSE MESONES',
      );
      expect(normalized.parsed.codigoTela, 'T1C150126-01');
    });

    test('extrae codigo de rollo desde QR completo', () {
      const raw = 'T1C150126-01,23,46,OPV2512001,TEX-22A,166,288,JOSE';
      final code = TelaQrCodec.extractCodigoRollo(raw);
      expect(code, 'T1C150126-01');
    });

    test('extrae codigo de rollo cuando se ingresa codigo directo', () {
      const raw = 'T1C150126-01';
      final code = TelaQrCodec.extractCodigoRollo(raw);
      expect(code, 'T1C150126-01');
    });
  });
}
