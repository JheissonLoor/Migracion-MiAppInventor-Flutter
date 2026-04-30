import '../../core/utils/qr_parser.dart';

class EtiquetaPayload {
  final String qrRaw;
  final String text;
  final String codigo;
  final String codigoKardex;
  final String lote;
  final String articulo;
  final String metraje;
  final String revisador;

  const EtiquetaPayload({
    required this.qrRaw,
    required this.text,
    this.codigo = '',
    this.codigoKardex = '',
    this.lote = '',
    this.articulo = '',
    this.metraje = '',
    this.revisador = '',
  });

  Map<String, dynamic> toGeneratePdfBody({required String imageBase64}) {
    return {
      'image': imageBase64,
      'text': text,
      if (codigo.isNotEmpty) 'codigo': codigo,
      if (codigoKardex.isNotEmpty) 'codigo_kardex': codigoKardex,
      if (lote.isNotEmpty) 'lote': lote,
      if (articulo.isNotEmpty) 'articulo': articulo,
      if (metraje.isNotEmpty) 'metraje': metraje,
      if (revisador.isNotEmpty) 'revisador': revisador,
    };
  }
}

class EtiquetaPayloadBuilder {
  const EtiquetaPayloadBuilder._();

  static EtiquetaPayload fromQrRaw(
    String qrRaw, {
    String codigoKardexOverride = '',
  }) {
    final clean = qrRaw.trim();
    if (clean.isEmpty) {
      throw Exception('Ingrese o escanee un QR para imprimir etiqueta');
    }

    final parsed = QrParser.parse(clean);

    // Caso ideal: QR de tela cruda 8 campos.
    if (parsed.telaCruda != null) {
      final tela = parsed.telaCruda!;
      return EtiquetaPayload(
        qrRaw: clean,
        text: tela.textoEtiqueta,
        codigo: tela.codigoTela,
        lote: tela.numCorte,
        articulo: tela.articulo,
        metraje: tela.metraje.toStringAsFixed(2),
        revisador: tela.revisador,
      );
    }

    // Fallback para otros formatos: imprimir texto multi-linea basico.
    if (parsed.hilos != null) {
      final hilos = parsed.hilos!;
      final generatedKardex = codigoKardexOverride.trim();
      final effectiveKardex =
          generatedKardex.isNotEmpty ? generatedKardex : hilos.codigoKardex;
      final effectiveQrRaw =
          generatedKardex.isNotEmpty && parsed.tokens.length >= 2
              ? _withGeneratedKardex(parsed.tokens, generatedKardex)
              : clean;
      final text = [
        hilos.codigoPcp,
        effectiveKardex,
        '${hilos.material} ${hilos.titulo}',
        hilos.color,
        hilos.lote,
      ].where((line) => line.trim().isNotEmpty).join('\n');

      return EtiquetaPayload(
        qrRaw: effectiveQrRaw,
        text: text,
        codigo: hilos.codigoPcp,
        codigoKardex: effectiveKardex,
        lote: hilos.lote,
        articulo: '${hilos.material} ${hilos.titulo}'.trim(),
        metraje: '',
        revisador: hilos.proveedor,
      );
    }

    // Fallback final: conserva el string QR original.
    final compact = clean.replaceAll(',', '\n');
    return EtiquetaPayload(qrRaw: clean, text: compact);
  }

  static String _withGeneratedKardex(List<String> tokens, String kardex) {
    final next = [...tokens];
    next[1] = kardex.trim();
    return next.join(',');
  }
}
