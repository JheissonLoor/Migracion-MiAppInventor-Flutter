/// Tokenizador CSV defensivo para codigos QR legacy.
///
/// Reglas:
/// - Respeta campos entre comillas dobles.
/// - Soporta comillas escapadas ("").
/// - Remueve espacios alrededor de cada token.
class LegacyQrTokenizer {
  const LegacyQrTokenizer._();

  static List<String> splitSmart(String input) {
    final source = input.replaceAll('\r', '').replaceAll('\n', '').trim();
    if (source.isEmpty) return const <String>[];

    final tokens = <String>[];
    var buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < source.length; i++) {
      final current = source[i];
      final next = i + 1 < source.length ? source[i + 1] : '';

      if (current == '"') {
        if (inQuotes && next == '"') {
          buffer.write('"');
          i++;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      if (current == ',' && !inQuotes) {
        tokens.add(buffer.toString().trim());
        buffer = StringBuffer();
        continue;
      }

      buffer.write(current);
    }

    tokens.add(buffer.toString().trim());
    return tokens;
  }

  static String tokenOneBased(List<String> tokens, int oneBasedIndex) {
    if (oneBasedIndex <= 0) return '';
    final index = oneBasedIndex - 1;
    if (index < 0 || index >= tokens.length) return '';
    return tokens[index].trim();
  }

  static String tokenLast(List<String> tokens) {
    if (tokens.isEmpty) return '';
    return tokens.last.trim();
  }
}
