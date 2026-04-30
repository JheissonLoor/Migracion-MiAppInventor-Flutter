import 'legacy_qr_tokenizer.dart';

enum CambioUbicacionQrTipo { campos14, campos16, invalido }

class CambioUbicacionQrData {
  final CambioUbicacionQrTipo tipo;
  final int camposDetectados;
  final String codigoKardex;
  final String codigoPcp;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCaja;
  final String servicio;
  final List<String> tokens;

  const CambioUbicacionQrData({
    required this.tipo,
    required this.camposDetectados,
    required this.codigoKardex,
    required this.codigoPcp,
    required this.material,
    required this.titulo,
    required this.color,
    required this.lote,
    required this.numCaja,
    required this.servicio,
    required this.tokens,
  });

  bool get tieneKardex => codigoKardex.trim().isNotEmpty;
}

class CambioUbicacionQrParseResult {
  final CambioUbicacionQrData? data;
  final String? error;

  const CambioUbicacionQrParseResult._({this.data, this.error});

  bool get isValid => data != null && (error == null || error!.isEmpty);

  factory CambioUbicacionQrParseResult.success(CambioUbicacionQrData data) {
    return CambioUbicacionQrParseResult._(data: data);
  }

  factory CambioUbicacionQrParseResult.error(String message) {
    return CambioUbicacionQrParseResult._(error: message);
  }
}

class CambioUbicacionQrParser {
  const CambioUbicacionQrParser._();

  static CambioUbicacionQrParseResult parse(String raw) {
    final tokens = LegacyQrTokenizer.splitSmart(raw);
    if (tokens.isEmpty) {
      return CambioUbicacionQrParseResult.error('QR vacio');
    }

    final count = tokens.length;
    if (count != 14 && count != 16) {
      return CambioUbicacionQrParseResult.error(
        'Formato no valido para cambio ubicacion ($count campos). Se espera 14 o 16.',
      );
    }

    final data = count == 16 ? _mapCampos16(tokens) : _mapCampos14(tokens);

    if (data.codigoPcp.trim().isEmpty) {
      return CambioUbicacionQrParseResult.error(
        'No se pudo extraer codigo PCP del QR',
      );
    }

    return CambioUbicacionQrParseResult.success(data);
  }

  static CambioUbicacionQrData _mapCampos14(List<String> tokens) {
    return CambioUbicacionQrData(
      tipo: CambioUbicacionQrTipo.campos14,
      camposDetectados: 14,
      codigoKardex: '',
      codigoPcp: LegacyQrTokenizer.tokenOneBased(tokens, 1),
      material: LegacyQrTokenizer.tokenOneBased(tokens, 2),
      titulo: LegacyQrTokenizer.tokenOneBased(tokens, 3),
      color: LegacyQrTokenizer.tokenOneBased(tokens, 4),
      lote: LegacyQrTokenizer.tokenOneBased(tokens, 5),
      numCaja: LegacyQrTokenizer.tokenOneBased(tokens, 6),
      servicio: '',
      tokens: tokens,
    );
  }

  static CambioUbicacionQrData _mapCampos16(List<String> tokens) {
    return CambioUbicacionQrData(
      tipo: CambioUbicacionQrTipo.campos16,
      camposDetectados: 16,
      codigoKardex: LegacyQrTokenizer.tokenOneBased(tokens, 1),
      codigoPcp: LegacyQrTokenizer.tokenOneBased(tokens, 2),
      material: LegacyQrTokenizer.tokenOneBased(tokens, 3),
      titulo: LegacyQrTokenizer.tokenOneBased(tokens, 4),
      color: LegacyQrTokenizer.tokenOneBased(tokens, 5),
      lote: LegacyQrTokenizer.tokenOneBased(tokens, 6),
      numCaja: LegacyQrTokenizer.tokenOneBased(tokens, 7),
      servicio: LegacyQrTokenizer.tokenOneBased(tokens, 16),
      tokens: tokens,
    );
  }
}
