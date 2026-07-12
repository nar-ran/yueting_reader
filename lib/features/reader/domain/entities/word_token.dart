import 'cedict_entry.dart';

class WordToken {
  final String text;
  final String pinyin;
  final CedictEntry? dictEntry;
  final bool isPunctuation;

  WordToken({
    required this.text,
    required this.pinyin,
    this.dictEntry,
    required this.isPunctuation,
  });

  @override
  String toString() {
    return 'Token(text: $text, pinyin: $pinyin, isPunctuation: $isPunctuation, hasDict: ${dictEntry != null})';
  }
}
