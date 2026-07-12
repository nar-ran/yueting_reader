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

  /// Parses a single line from the CC-CEDICT file.
  /// Returns null if the line is a comment or invalid.
  static CedictEntry? parseLine(String line) {
    if (line.isEmpty || line.startsWith('#')) return null;

    // Format: Traditional Simplified [pinyin] /defn1/defn2/.../
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

    // Remove leading and trailing slashes, then split by slash
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
