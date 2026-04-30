// Parser robusto para formatos QR usados en CoolImport.
//
// Casos soportados:
// - Hilos 14 campos
// - Hilos 16 campos
// - Tela cruda 8 campos
// - Legacy 6 campos
//
// Reglas de robustez:
// - Soporta valores con comas internas (merge por plantilla esperada).
// - Soporta valores encerrados en comillas dobles.
// - Normaliza numericos con coma o punto decimal.

class QrHilos {
  final String codigoPcp;
  final String codigoKardex;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String proveedor;
  final String servicio;
  final String guia;
  final double numCajas;
  final double totalBobinas;
  final double pesoBruto;
  final double pesoNeto;
  final String ubicacion;
  final String? almacen;
  final String? fechaIngreso;

  const QrHilos({
    required this.codigoPcp,
    required this.codigoKardex,
    required this.material,
    required this.titulo,
    required this.color,
    required this.lote,
    required this.proveedor,
    required this.servicio,
    required this.guia,
    required this.numCajas,
    required this.totalBobinas,
    required this.pesoBruto,
    required this.pesoNeto,
    required this.ubicacion,
    this.almacen,
    this.fechaIngreso,
  });

  String get resumen =>
      '$codigoPcp | $material $titulo | $color | $lote | Cajas: $numCajas | '
      'Bobinas: $totalBobinas | Bruto: $pesoBruto | Neto: $pesoNeto';
}

class QrTelaCruda {
  final String codigoTela;
  final String numCorte;
  final String telar;
  final String op;
  final String articulo;
  final double metraje;
  final double peso;
  final String revisador;

  const QrTelaCruda({
    required this.codigoTela,
    required this.numCorte,
    required this.telar,
    required this.op,
    required this.articulo,
    required this.metraje,
    required this.peso,
    required this.revisador,
  });

  String get textoEtiqueta =>
      '$codigoTela\n$op\n$articulo\n$metraje Mts\n$revisador';
  String get resumen =>
      '$codigoTela | $articulo | $metraje m | $peso kg | $revisador';
}

class QrLegacy {
  final String codigo;
  final String articulo;
  final double metros;
  final double peso;
  final String ubicacion;
  final String fecha;

  const QrLegacy({
    required this.codigo,
    required this.articulo,
    required this.metros,
    required this.peso,
    required this.ubicacion,
    required this.fecha,
  });
}

enum QrTipo { hilos14, hilos16, telaCruda8, legacy6, desconocido }

class QrParseResult {
  final QrTipo tipo;
  final QrHilos? hilos;
  final QrTelaCruda? telaCruda;
  final QrLegacy? legacy;
  final String? error;
  final String rawData;
  final List<String> tokens;

  const QrParseResult._({
    required this.tipo,
    required this.rawData,
    required this.tokens,
    this.hilos,
    this.telaCruda,
    this.legacy,
    this.error,
  });

  bool get isValid => error == null;

  factory QrParseResult.success({
    required QrTipo tipo,
    required String rawData,
    required List<String> tokens,
    QrHilos? hilos,
    QrTelaCruda? telaCruda,
    QrLegacy? legacy,
  }) {
    return QrParseResult._(
      tipo: tipo,
      rawData: rawData,
      tokens: tokens,
      hilos: hilos,
      telaCruda: telaCruda,
      legacy: legacy,
    );
  }

  factory QrParseResult.error({
    required String message,
    required String rawData,
    required List<String> tokens,
  }) {
    return QrParseResult._(
      tipo: QrTipo.desconocido,
      rawData: rawData,
      tokens: tokens,
      error: message,
    );
  }
}

class QrParser {
  static const int _hilos14 = 14;
  static const int _hilos16 = 16;
  static const int _tela8 = 8;
  static const int _legacy6 = 6;

  static QrParseResult parse(String rawData) {
    final cleanInput = _normalizeRaw(rawData);
    if (cleanInput.isEmpty) {
      return QrParseResult.error(
        message: 'Codigo QR vacio',
        rawData: rawData,
        tokens: const <String>[],
      );
    }

    final baseTokens = _splitCsv(cleanInput);

    final hilos16 = _tryParseHilos(
      rawData: rawData,
      sourceTokens: baseTokens,
      expectedLength: _hilos16,
    );
    if (hilos16 != null) return hilos16;

    final hilos14 = _tryParseHilos(
      rawData: rawData,
      sourceTokens: baseTokens,
      expectedLength: _hilos14,
    );
    if (hilos14 != null) return hilos14;

    final tela = _tryParseTela(rawData: rawData, sourceTokens: baseTokens);
    if (tela != null) return tela;

    final legacy = _tryParseLegacy(rawData: rawData, sourceTokens: baseTokens);
    if (legacy != null) return legacy;

    return QrParseResult.error(
      message:
          'Formato QR no reconocido (${baseTokens.length} campos). Se espera 6, 8, 14 o 16.',
      rawData: rawData,
      tokens: baseTokens,
    );
  }

  static QrParseResult? _tryParseHilos({
    required String rawData,
    required List<String> sourceTokens,
    required int expectedLength,
  }) {
    if (sourceTokens.length < expectedLength) return null;

    final tokens = _collapseTokens(
      sourceTokens: sourceTokens,
      expectedLength: expectedLength,
      mergeIndex: 2,
    );

    if (tokens.length != expectedLength) return null;
    if (!_looksLikeHilos(tokens)) return null;

    // Numericos fijos en ambos formatos.
    if (!_isNumeric(tokens[9]) ||
        !_isNumeric(tokens[10]) ||
        !_isNumeric(tokens[11]) ||
        !_isNumeric(tokens[12])) {
      return null;
    }

    final hilos = QrHilos(
      codigoPcp: tokens[0],
      codigoKardex: tokens[1],
      material: tokens[2],
      titulo: tokens[3],
      color: tokens[4],
      lote: tokens[5],
      proveedor: tokens[6],
      servicio: tokens[7],
      guia: tokens[8],
      numCajas: _toDouble(tokens[9]),
      totalBobinas: _toDouble(tokens[10]),
      pesoBruto: _toDouble(tokens[11]),
      pesoNeto: _toDouble(tokens[12]),
      ubicacion: tokens[13],
      almacen: expectedLength == _hilos16 ? tokens[14] : null,
      fechaIngreso: expectedLength == _hilos16 ? tokens[15] : null,
    );

    return QrParseResult.success(
      tipo: expectedLength == _hilos16 ? QrTipo.hilos16 : QrTipo.hilos14,
      rawData: rawData,
      tokens: tokens,
      hilos: hilos,
    );
  }

  static QrParseResult? _tryParseTela({
    required String rawData,
    required List<String> sourceTokens,
  }) {
    if (sourceTokens.length < _tela8) return null;

    final tokens = _collapseTokens(
      sourceTokens: sourceTokens,
      expectedLength: _tela8,
      mergeIndex: 4,
    );

    if (tokens.length != _tela8) return null;
    if (!_looksLikeTela(tokens)) return null;
    if (!_isNumeric(tokens[5]) || !_isNumeric(tokens[6])) return null;

    final tela = QrTelaCruda(
      codigoTela: tokens[0],
      numCorte: tokens[1],
      telar: tokens[2],
      op: tokens[3],
      articulo: tokens[4],
      metraje: _toDouble(tokens[5]),
      peso: _toDouble(tokens[6]),
      revisador: tokens[7],
    );

    return QrParseResult.success(
      tipo: QrTipo.telaCruda8,
      rawData: rawData,
      tokens: tokens,
      telaCruda: tela,
    );
  }

  static QrParseResult? _tryParseLegacy({
    required String rawData,
    required List<String> sourceTokens,
  }) {
    if (sourceTokens.length < _legacy6) return null;

    final tokens = _collapseTokens(
      sourceTokens: sourceTokens,
      expectedLength: _legacy6,
      mergeIndex: 1,
    );

    if (tokens.length != _legacy6) return null;
    if (!_isNumeric(tokens[2]) || !_isNumeric(tokens[3])) return null;

    final legacy = QrLegacy(
      codigo: tokens[0],
      articulo: tokens[1],
      metros: _toDouble(tokens[2]),
      peso: _toDouble(tokens[3]),
      ubicacion: tokens[4],
      fecha: tokens[5],
    );

    return QrParseResult.success(
      tipo: QrTipo.legacy6,
      rawData: rawData,
      tokens: tokens,
      legacy: legacy,
    );
  }

  static bool _looksLikeHilos(List<String> tokens) {
    final codigo = tokens.first.toUpperCase();
    return codigo.contains('PCP') ||
        codigo.contains('H') ||
        codigo.contains('-');
  }

  static bool _looksLikeTela(List<String> tokens) {
    final code = tokens.first.toUpperCase();
    return code.startsWith('T') && code.contains('-');
  }

  static String _normalizeRaw(String value) {
    return value.replaceAll('\r', '').replaceAll('\n', '').trim();
  }

  static List<String> _splitCsv(String input) {
    if (input.isEmpty) return const <String>[];

    final tokens = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final nextChar = i + 1 < input.length ? input[i + 1] : '';

      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          current.write('"');
          i++;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (char == ',' && !inQuotes) {
        tokens.add(current.toString().trim());
        current = StringBuffer();
        continue;
      }

      current.write(char);
    }

    tokens.add(current.toString().trim());
    return tokens;
  }

  static List<String> _collapseTokens({
    required List<String> sourceTokens,
    required int expectedLength,
    required int mergeIndex,
  }) {
    final normalized = sourceTokens.map((token) => token.trim()).toList();
    if (normalized.length <= expectedLength) return normalized;

    final overflow = normalized.length - expectedLength;
    final endMergeIndex = mergeIndex + overflow;

    final merged = <String>[
      ...normalized.sublist(0, mergeIndex),
      normalized.sublist(mergeIndex, endMergeIndex + 1).join(','),
      ...normalized.sublist(endMergeIndex + 1),
    ];

    return merged;
  }

  static bool _isNumeric(String value) {
    final normalized = _normalizeNumber(value);
    return double.tryParse(normalized) != null;
  }

  static double _toDouble(String value) {
    final normalized = _normalizeNumber(value);
    return double.tryParse(normalized) ?? 0;
  }

  static String _normalizeNumber(String value) {
    var normalized = value.trim().replaceAll(' ', '');
    if (normalized.isEmpty) return normalized;

    final hasComma = normalized.contains(',');
    final hasDot = normalized.contains('.');

    if (hasComma && hasDot) {
      final commaIndex = normalized.lastIndexOf(',');
      final dotIndex = normalized.lastIndexOf('.');

      if (commaIndex > dotIndex) {
        normalized = normalized.replaceAll('.', '');
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
      return normalized;
    }

    if (hasComma) {
      return normalized.replaceAll(',', '.');
    }

    return normalized;
  }
}
