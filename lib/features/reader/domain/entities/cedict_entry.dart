class CedictEntry {
  final String traditional;
  final String simplified;
  final String pinyin;
  final List<String> definitions;

  CedictEntry({
    required this.traditional,
    required this.simplified,
    required this.pinyin,
    required this.definitions,
  });

  // Parsea una sola linea del archivo CC-CEDICT
  // Devuelve null si la linea es un comentario o es invalida
  static CedictEntry? parseLine(String line) {
    if (line.isEmpty || line.startsWith('#')) return null;

    // Formato: Traditional Simplified [pinyin] /defn1/defn2/.../
    final bracketStart = line.indexOf('[');
    final bracketEnd = line.indexOf(']');
    if (bracketStart == -1 || bracketEnd == -1) return null;

    final charactersPart = line.substring(0, bracketStart).trim();
    final charSplit = charactersPart.split(' ');
    if (charSplit.length < 2) return null;

    final traditional = charSplit[0];
    final simplified = charSplit[1];

    final pinyin = line.substring(bracketStart + 1, bracketEnd);

    final slashPart = line.substring(bracketEnd + 1).trim();
    if (!slashPart.startsWith('/') || !slashPart.endsWith('/')) return null;

    // Elimina las barras inicial y final, y luego separa por barras
    final definitionsRaw = slashPart.substring(1, slashPart.length - 1).split('/');
    final definitions = definitionsRaw.map((d) => d.trim()).where((d) => d.isNotEmpty).toList();

    return CedictEntry(
      traditional: traditional,
      simplified: simplified,
      pinyin: pinyin,
      definitions: definitions,
    );
  }

  @override
  String toString() {
    return '$simplified [$pinyin] -> ${definitions.join(", ")}';
  }
}
