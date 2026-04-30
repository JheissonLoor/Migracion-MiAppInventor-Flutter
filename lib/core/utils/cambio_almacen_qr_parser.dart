import 'legacy_qr_tokenizer.dart';

enum CambioAlmacenQrTipo { campos12, campos14, campos16, invalido }

class CambioAlmacenQrData {
  final CambioAlmacenQrTipo tipo;
  final int camposDetectados;
  final String numTelar;
  final String codigoTelas;
  final String ordenOperacion;
  final String articulo;
  final String numPlegador;
  final String metroCorte;
  final String pesoKg;
  final String fechaCorte;
  final String fechaRevisado;
  final String servicio;
  final List<String> tokens;

  const CambioAlmacenQrData({
    required this.tipo,
    required this.camposDetectados,
    required this.numTelar,
    required this.codigoTelas,
    required this.ordenOperacion,
    required this.articulo,
    required this.numPlegador,
    required this.metroCorte,
    required this.pesoKg,
    required this.fechaCorte,
    required this.fechaRevisado,
    required this.servicio,
    required this.tokens,
  });
}

class CambioAlmacenQrParseResult {
  final CambioAlmacenQrData? data;
  final String? error;

  const CambioAlmacenQrParseResult._({this.data, this.error});

  bool get isValid => data != null && (error == null || error!.isEmpty);

  factory CambioAlmacenQrParseResult.success(CambioAlmacenQrData data) {
    return CambioAlmacenQrParseResult._(data: data);
  }

  factory CambioAlmacenQrParseResult.error(String message) {
    return CambioAlmacenQrParseResult._(error: message);
  }
}

class CambioAlmacenQrParser {
  const CambioAlmacenQrParser._();

  static CambioAlmacenQrParseResult parse(String raw) {
    final tokens = LegacyQrTokenizer.splitSmart(raw);
    if (tokens.isEmpty) {
      return CambioAlmacenQrParseResult.error('QR vacio');
    }

    final count = tokens.length;
    if (count != 12 && count != 14 && count != 16) {
      return CambioAlmacenQrParseResult.error(
        'Formato no valido para cambio almacen ($count campos). Se espera 12, 14 o 16.',
      );
    }

    final data = count == 12 ? _mapCampos12(tokens) : _mapCampos14o16(tokens);

    if (data.codigoTelas.trim().isEmpty && data.numTelar.trim().isEmpty) {
      return CambioAlmacenQrParseResult.error(
        'No se pudo extraer datos minimos del QR para traslado',
      );
    }

    return CambioAlmacenQrParseResult.success(data);
  }

  static CambioAlmacenQrData _mapCampos12(List<String> tokens) {
    return CambioAlmacenQrData(
      tipo: CambioAlmacenQrTipo.campos12,
      camposDetectados: 12,
      numTelar: LegacyQrTokenizer.tokenOneBased(tokens, 1),
      codigoTelas: LegacyQrTokenizer.tokenOneBased(tokens, 2),
      ordenOperacion: LegacyQrTokenizer.tokenOneBased(tokens, 3),
      articulo: LegacyQrTokenizer.tokenOneBased(tokens, 4),
      numPlegador: LegacyQrTokenizer.tokenOneBased(tokens, 5),
      metroCorte: LegacyQrTokenizer.tokenOneBased(tokens, 6),
      pesoKg: LegacyQrTokenizer.tokenOneBased(tokens, 7),
      fechaCorte: LegacyQrTokenizer.tokenOneBased(tokens, 8),
      fechaRevisado: LegacyQrTokenizer.tokenOneBased(tokens, 9),
      servicio: LegacyQrTokenizer.tokenOneBased(tokens, 12),
      tokens: tokens,
    );
  }

  static CambioAlmacenQrData _mapCampos14o16(List<String> tokens) {
    final count = tokens.length;
    final tipo =
        count == 16
            ? CambioAlmacenQrTipo.campos16
            : CambioAlmacenQrTipo.campos14;

    // En el bloque legacy se sobreescribe codigo telas y se usan offsets
    // distintos al formato de 12 campos. Se replica para compatibilidad.
    final servicioLegacy =
        LegacyQrTokenizer.tokenOneBased(tokens, 16).trim().isNotEmpty
            ? LegacyQrTokenizer.tokenOneBased(tokens, 16)
            : LegacyQrTokenizer.tokenLast(tokens);

    return CambioAlmacenQrData(
      tipo: tipo,
      camposDetectados: count,
      numTelar: _firstNonEmpty([
        LegacyQrTokenizer.tokenOneBased(tokens, 2),
        LegacyQrTokenizer.tokenOneBased(tokens, 1),
      ]),
      codigoTelas: _firstNonEmpty([
        LegacyQrTokenizer.tokenOneBased(tokens, 3),
        LegacyQrTokenizer.tokenOneBased(tokens, 2),
        LegacyQrTokenizer.tokenOneBased(tokens, 1),
      ]),
      ordenOperacion: LegacyQrTokenizer.tokenOneBased(tokens, 4),
      articulo: LegacyQrTokenizer.tokenOneBased(tokens, 5),
      numPlegador: LegacyQrTokenizer.tokenOneBased(tokens, 6),
      metroCorte: LegacyQrTokenizer.tokenOneBased(tokens, 7),
      pesoKg: LegacyQrTokenizer.tokenOneBased(tokens, 8),
      fechaCorte: LegacyQrTokenizer.tokenOneBased(tokens, 9),
      fechaRevisado: LegacyQrTokenizer.tokenOneBased(tokens, 10),
      servicio: servicioLegacy,
      tokens: tokens,
    );
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }
    return '';
  }
}
