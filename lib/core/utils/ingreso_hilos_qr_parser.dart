import 'legacy_qr_tokenizer.dart';

enum IngresoHilosQrTipo { campos14, campos16, invalido }

class IngresoHilosQrData {
  final IngresoHilosQrTipo tipo;
  final int camposDetectados;
  final String codigoKardex;
  final String codigoPcp;
  final String material;
  final String titulo;
  final String color;
  final String lote;
  final String numCajas;
  final String totalBobinas;
  final String cantidadReenconado;
  final String pesoBruto;
  final String pesoNeto;
  final String proveedor;
  final String fechaIngreso;
  final String almacen;
  final String ubicacion;
  final String servicio;
  final List<String> tokens;

  const IngresoHilosQrData({
    required this.tipo,
    required this.camposDetectados,
    required this.codigoKardex,
    required this.codigoPcp,
    required this.material,
    required this.titulo,
    required this.color,
    required this.lote,
    required this.numCajas,
    required this.totalBobinas,
    required this.cantidadReenconado,
    required this.pesoBruto,
    required this.pesoNeto,
    required this.proveedor,
    required this.fechaIngreso,
    required this.almacen,
    required this.ubicacion,
    required this.servicio,
    required this.tokens,
  });

  bool get tieneKardex => codigoKardex.trim().isNotEmpty;
}

class IngresoHilosQrParseResult {
  final IngresoHilosQrData? data;
  final String? error;

  const IngresoHilosQrParseResult._({this.data, this.error});

  bool get isValid => data != null && (error == null || error!.isEmpty);

  factory IngresoHilosQrParseResult.success(IngresoHilosQrData data) {
    return IngresoHilosQrParseResult._(data: data);
  }

  factory IngresoHilosQrParseResult.error(String message) {
    return IngresoHilosQrParseResult._(error: message);
  }
}

class IngresoHilosQrParser {
  const IngresoHilosQrParser._();

  static IngresoHilosQrParseResult parse(String raw) {
    final source = LegacyQrTokenizer.splitSmart(raw);
    if (source.isEmpty) {
      return IngresoHilosQrParseResult.error('QR vacio');
    }

    if (source.length == 14 || source.length > 14 && source.length < 16) {
      final normalized = _collapseTokens(
        sourceTokens: source,
        expectedLength: 14,
        mergeIndex: 1,
      );
      if (normalized.length == 14) {
        return IngresoHilosQrParseResult.success(_map14(normalized));
      }
    }

    if (source.length == 16 || source.length > 16) {
      final normalized = _collapseTokens(
        sourceTokens: source,
        expectedLength: 16,
        mergeIndex: 2,
      );
      if (normalized.length == 16) {
        return IngresoHilosQrParseResult.success(_map16(normalized));
      }
    }

    return IngresoHilosQrParseResult.error(
      'Formato no valido (${
          source.length
      } campos). Solo se admite QR de 14 o 16 campos.',
    );
  }

  static IngresoHilosQrData _map14(List<String> tokens) {
    return IngresoHilosQrData(
      tipo: IngresoHilosQrTipo.campos14,
      camposDetectados: 14,
      codigoKardex: '',
      codigoPcp: LegacyQrTokenizer.tokenOneBased(tokens, 1),
      material: LegacyQrTokenizer.tokenOneBased(tokens, 2),
      titulo: LegacyQrTokenizer.tokenOneBased(tokens, 3),
      color: LegacyQrTokenizer.tokenOneBased(tokens, 4),
      lote: LegacyQrTokenizer.tokenOneBased(tokens, 5),
      numCajas: LegacyQrTokenizer.tokenOneBased(tokens, 6),
      totalBobinas: LegacyQrTokenizer.tokenOneBased(tokens, 7),
      cantidadReenconado: LegacyQrTokenizer.tokenOneBased(tokens, 8),
      pesoBruto: LegacyQrTokenizer.tokenOneBased(tokens, 9),
      pesoNeto: LegacyQrTokenizer.tokenOneBased(tokens, 10),
      proveedor: LegacyQrTokenizer.tokenOneBased(tokens, 11),
      fechaIngreso: LegacyQrTokenizer.tokenOneBased(tokens, 12),
      almacen: LegacyQrTokenizer.tokenOneBased(tokens, 13),
      ubicacion: LegacyQrTokenizer.tokenOneBased(tokens, 14),
      servicio: '',
      tokens: tokens,
    );
  }

  static IngresoHilosQrData _map16(List<String> tokens) {
    return IngresoHilosQrData(
      tipo: IngresoHilosQrTipo.campos16,
      camposDetectados: 16,
      codigoKardex: LegacyQrTokenizer.tokenOneBased(tokens, 1),
      codigoPcp: LegacyQrTokenizer.tokenOneBased(tokens, 2),
      material: LegacyQrTokenizer.tokenOneBased(tokens, 3),
      titulo: LegacyQrTokenizer.tokenOneBased(tokens, 4),
      color: LegacyQrTokenizer.tokenOneBased(tokens, 5),
      lote: LegacyQrTokenizer.tokenOneBased(tokens, 6),
      numCajas: LegacyQrTokenizer.tokenOneBased(tokens, 7),
      totalBobinas: LegacyQrTokenizer.tokenOneBased(tokens, 8),
      cantidadReenconado: LegacyQrTokenizer.tokenOneBased(tokens, 9),
      pesoBruto: LegacyQrTokenizer.tokenOneBased(tokens, 10),
      pesoNeto: LegacyQrTokenizer.tokenOneBased(tokens, 11),
      proveedor: LegacyQrTokenizer.tokenOneBased(tokens, 12),
      fechaIngreso: LegacyQrTokenizer.tokenOneBased(tokens, 13),
      almacen: LegacyQrTokenizer.tokenOneBased(tokens, 14),
      ubicacion: LegacyQrTokenizer.tokenOneBased(tokens, 15),
      servicio: LegacyQrTokenizer.tokenOneBased(tokens, 16),
      tokens: tokens,
    );
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
    if (endMergeIndex >= normalized.length) return normalized;

    return <String>[
      ...normalized.sublist(0, mergeIndex),
      normalized.sublist(mergeIndex, endMergeIndex + 1).join(','),
      ...normalized.sublist(endMergeIndex + 1),
    ];
  }
}
