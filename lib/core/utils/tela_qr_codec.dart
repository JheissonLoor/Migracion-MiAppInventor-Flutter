import 'qr_parser.dart';

class TelaQrNormalized {
  final QrTelaCruda parsed;
  final String codigoQrNormalizado;

  const TelaQrNormalized({
    required this.parsed,
    required this.codigoQrNormalizado,
  });
}

class TelaQrCodec {
  const TelaQrCodec._();

  /// Convierte un QR de tela en un formato estable de 8 campos para backend.
  ///
  /// El backend actual de ingreso de tela usa split(',') simple.
  /// Para evitar desplazamientos de columnas por comas internas,
  /// normalizamos los campos de texto removiendo comas.
  static TelaQrNormalized normalizeForIngreso(String rawQr) {
    final result = QrParser.parse(rawQr);
    if (!result.isValid || result.telaCruda == null) {
      throw Exception(
        'El QR no corresponde al formato de tela cruda (8 campos)',
      );
    }

    final t = result.telaCruda!;
    final articulo = _sanitizeField(t.articulo);
    final revisador = _sanitizeField(t.revisador);
    final op = _sanitizeField(t.op);
    final telar = _sanitizeField(t.telar);
    final numCorte = _sanitizeField(t.numCorte);

    final qr = [
      t.codigoTela.trim(),
      numCorte,
      telar,
      op,
      articulo,
      _normalizeNumber(t.metraje),
      _normalizeNumber(t.peso),
      revisador,
    ].join(',');

    return TelaQrNormalized(parsed: t, codigoQrNormalizado: qr);
  }

  /// Extrae codigo de rollo desde texto libre o QR completo.
  static String extractCodigoRollo(String rawOrCode) {
    final raw = rawOrCode.trim();
    if (raw.isEmpty) return '';

    // Si ya parece codigo simple de rollo, devolver tal cual.
    if (!raw.contains(',')) return raw;

    final parsed = QrParser.parse(raw);
    if (parsed.telaCruda != null) {
      return parsed.telaCruda!.codigoTela.trim();
    }

    // Fallback defensivo: primer token antes de coma.
    return raw.split(',').first.trim();
  }

  static String _sanitizeField(String value) {
    return value.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _normalizeNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }
}
