import 'ingreso_hilos_qr_parser.dart';
import 'legacy_qr_tokenizer.dart';
import 'qr_parser.dart';

/// Resultado de normalizacion del texto ingresado en Consulta Stock.
///
/// `codigoConsulta` es el valor final que se enviara al backend.
class ConsultaStockCodeResolution {
  final String inputRaw;
  final String codigoConsulta;
  final String codigoPcp;
  final String codigoKardex;
  final List<String> tokens;

  const ConsultaStockCodeResolution({
    required this.inputRaw,
    required this.codigoConsulta,
    required this.codigoPcp,
    required this.codigoKardex,
    this.tokens = const <String>[],
  });
}

class ConsultaStockQrCodec {
  const ConsultaStockQrCodec._();

  /// Convierte input manual o QR completo al codigo PCP esperado por /consulta_pcp.
  static ConsultaStockCodeResolution resolveInput(String input) {
    final raw = input.replaceAll('\r', '').replaceAll('\n', '').trim();
    if (raw.isEmpty) {
      return const ConsultaStockCodeResolution(
        inputRaw: '',
        codigoConsulta: '',
        codigoPcp: '',
        codigoKardex: '',
      );
    }

    if (!raw.contains(',')) {
      return ConsultaStockCodeResolution(
        inputRaw: raw,
        codigoConsulta: raw,
        codigoPcp: raw,
        codigoKardex: '',
        tokens: const <String>[],
      );
    }

    final legacy = IngresoHilosQrParser.parse(raw);
    if (legacy.isValid && legacy.data != null) {
      final data = legacy.data!;
      final pcp = data.codigoPcp.trim();
      final kardex = data.codigoKardex.trim();
      return ConsultaStockCodeResolution(
        inputRaw: raw,
        codigoConsulta: pcp,
        codigoPcp: pcp,
        codigoKardex: kardex,
        tokens: data.tokens,
      );
    }

    final parsed = QrParser.parse(raw);
    if (parsed.isValid && parsed.hilos != null) {
      final pcp = parsed.hilos!.codigoPcp.trim();
      final kardex = parsed.hilos!.codigoKardex.trim();
      return ConsultaStockCodeResolution(
        inputRaw: raw,
        codigoConsulta: pcp,
        codigoPcp: pcp,
        codigoKardex: kardex,
        tokens: parsed.tokens,
      );
    }

    final tokens = LegacyQrTokenizer.splitSmart(raw);
    final pcp = _guessCodigoPcp(tokens);
    final kardex = _guessCodigoKardex(tokens);
    final fallback = tokens.isNotEmpty ? tokens.first.trim() : raw;
    final consulta = pcp.isNotEmpty ? pcp : fallback;

    return ConsultaStockCodeResolution(
      inputRaw: raw,
      codigoConsulta: consulta,
      codigoPcp: pcp.isNotEmpty ? pcp : consulta,
      codigoKardex: kardex,
      tokens: tokens,
    );
  }

  /// Parser combinado para respuestas de /consulta_pcp:
  /// - Primero intenta parser general.
  /// - Si falla, intenta parser legacy 14/16 usado en MIT.
  static QrParseResult parseBackendRaw(String raw) {
    final primary = QrParser.parse(raw);
    if (primary.isValid) {
      return primary;
    }

    final legacy = IngresoHilosQrParser.parse(raw);
    if (!legacy.isValid || legacy.data == null) {
      return primary;
    }

    final data = legacy.data!;
    final hilos = QrHilos(
      codigoPcp: data.codigoPcp.trim(),
      codigoKardex: data.codigoKardex.trim(),
      material: data.material.trim(),
      titulo: data.titulo.trim(),
      color: data.color.trim(),
      lote: data.lote.trim(),
      proveedor: data.proveedor.trim(),
      servicio: data.servicio.trim(),
      guia: '',
      numCajas: _toDouble(data.numCajas),
      totalBobinas: _toDouble(data.totalBobinas),
      pesoBruto: _toDouble(data.pesoBruto),
      pesoNeto: _toDouble(data.pesoNeto),
      ubicacion: data.ubicacion.trim(),
      almacen: data.almacen.trim().isEmpty ? null : data.almacen.trim(),
      fechaIngreso:
          data.fechaIngreso.trim().isEmpty ? null : data.fechaIngreso.trim(),
    );

    return QrParseResult.success(
      tipo:
          data.tipo == IngresoHilosQrTipo.campos16
              ? QrTipo.hilos16
              : QrTipo.hilos14,
      rawData: raw,
      tokens: data.tokens,
      hilos: hilos,
    );
  }

  static String _guessCodigoPcp(List<String> tokens) {
    for (final token in tokens) {
      if (_looksLikePcp(token)) {
        return token.trim();
      }
    }

    if (tokens.length >= 2 &&
        _looksLikeKardex(tokens[0]) &&
        tokens[1].trim().isNotEmpty) {
      return tokens[1].trim();
    }

    return '';
  }

  static String _guessCodigoKardex(List<String> tokens) {
    for (final token in tokens) {
      if (_looksLikeKardex(token)) {
        return token.trim();
      }
    }
    return '';
  }

  static bool _looksLikePcp(String value) {
    final token = value.trim().toUpperCase();
    if (token.isEmpty) return false;
    if (token.startsWith('PCP-')) return true;
    if (RegExp(r'^H\d{5,}-\d+$').hasMatch(token)) return true;
    if (RegExp(r'^[A-Z]{2,}\d{2,}-\d+$').hasMatch(token)) return true;
    return false;
  }

  static bool _looksLikeKardex(String value) {
    final token = value.trim().toUpperCase();
    if (token.isEmpty) return false;
    if (token.contains('/') && !token.contains(',')) return true;
    return false;
  }

  static double _toDouble(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
}
