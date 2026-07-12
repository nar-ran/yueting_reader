import 'package:lpinyin/lpinyin.dart';
import '../entities/word_token.dart';
import '../entities/cedict_entry.dart';
import 'dictionary_service.dart';

class SegmenterService {
  final DictionaryService _dictService = DictionaryService();

  /// Convierte el pinyin numerado de CC-CEDICT (ej. "ni3 hao3") a marcas de tono (ej. "nǐ hǎo")
  static String convertNumberedPinyin(String pinyin) {
    if (pinyin.isEmpty) return '';

    final syllables = pinyin.split(' ');
    final List<String> result = [];

    for (var syllable in syllables) {
      syllable = syllable.trim().toLowerCase();
      if (syllable.isEmpty) continue;

      // Extrae el numero de tono (al final de la silaba)
      int tone = 5; // Tono neutro por defecto
      final lastChar = syllable[syllable.length - 1];
      final isNumber = RegExp(r'[1-5]').hasMatch(lastChar);
      
      if (isNumber) {
        tone = int.parse(lastChar);
        syllable = syllable.substring(0, syllable.length - 1);
      }

      // Reemplaza u: con ü
      syllable = syllable.replaceAll('u:', 'ü').replaceAll('v', 'ü');

      if (tone == 5 || tone < 1 || tone > 4) {
        // Tono neutro, no requiere marcas
        result.add(syllable);
        continue;
      }

      final toneIndex = tone - 1;

      // Reglas para colocar la marca de tono:
      // 1. Si contiene 'a' o 'e', se coloca la marca en esa letra.
      // 2. Si contiene 'o', se coloca la marca en la 'o'.
      // 3. Para 'ui' o 'iu', se coloca la marca en la segunda vocal.
      // 4. En otros casos, se coloca en 'i', 'u' o 'ü'.
      
      String? targetVowel;
      if (syllable.contains('a')) {
        targetVowel = 'a';
      } else if (syllable.contains('e')) {
        targetVowel = 'e';
      } else if (syllable.contains('o')) {
        targetVowel = 'o';
      } else if (syllable.contains('ui')) {
        targetVowel = 'i';
      } else if (syllable.contains('iu')) {
        targetVowel = 'u';
      } else if (syllable.contains('i')) {
        targetVowel = 'i';
      } else if (syllable.contains('u')) {
        targetVowel = 'u';
      } else if (syllable.contains('ü')) {
        targetVowel = 'ü';
      }

      if (targetVowel != null) {
        final Map<String, List<String>> toneMaps = {
          'a': ['ā', 'á', 'ǎ', 'à'],
          'e': ['ē', 'é', 'ě', 'è'],
          'o': ['ō', 'ó', 'ǒ', 'ò'],
          'i': ['ī', 'í', 'ǐ', 'ì'],
          'u': ['ū', 'ú', 'ǔ', 'ù'],
          'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ'],
        };
        final toneChar = toneMaps[targetVowel]![toneIndex];
        syllable = syllable.replaceFirst(targetVowel, toneChar);
      }

      result.add(syllable);
    }

    return result.join(' ');
  }

  bool _isChinese(String s) {
    if (s.isEmpty) return false;
    final code = s.codeUnitAt(0);
    // Ideogramas unificados CJK
    return code >= 0x4E00 && code <= 0x9FFF;
  }

  /// Segmenta el texto en chino utilizando el algoritmo de coincidencia maxima (greedy match)
  List<WordToken> segment(String text) {
    final List<WordToken> tokens = [];
    int i = 0;
    final int textLength = text.length;
    const int maxWordLength = 8;

    while (i < textLength) {
      final char = text[i];

      // Manejo de saltos de linea y espacios en blanco
      if (RegExp(r'[\s\n\r\t]').hasMatch(char)) {
        tokens.add(WordToken(
          text: char,
          pinyin: '',
          isPunctuation: true,
        ));
        i++;
        continue;
      }

      // 1. Intenta coincidencia maxima de palabras en el diccionario
      int matchLength = -1;
      List<CedictEntry>? matchedEntries;

      final int maxCheck = (i + maxWordLength > textLength) ? textLength - i : maxWordLength;

      for (int len = maxCheck; len >= 2; len--) {
        final substring = text.substring(i, i + len);
        final entries = _dictService.lookup(substring);
        if (entries != null && entries.isNotEmpty) {
          matchLength = len;
          matchedEntries = entries;
          break;
        }
      }

      if (matchLength != -1) {
        // Palabra de varios caracteres encontrada en el diccionario
        final wordText = text.substring(i, i + matchLength);
        final firstEntry = matchedEntries!.first;
        final pinyinWithTones = convertNumberedPinyin(firstEntry.pinyin);

        tokens.add(WordToken(
          text: wordText,
          pinyin: pinyinWithTones,
          dictEntry: firstEntry,
          isPunctuation: false,
        ));
        i += matchLength;
      } else {
        // Busqueda de un solo caracter
        final charStr = text[i];
        final entries = _dictService.lookup(charStr);

        if (entries != null && entries.isNotEmpty) {
          // Caracter individual encontrado en el diccionario
          final entry = entries.first;
          final pinyinWithTones = convertNumberedPinyin(entry.pinyin);

          tokens.add(WordToken(
            text: charStr,
            pinyin: pinyinWithTones,
            dictEntry: entry,
            isPunctuation: false,
          ));
        } else {
          // Caracter no encontrado en CC-CEDICT, verifica si es un caracter chino
          final isChinese = _isChinese(charStr);
          if (isChinese) {
            // Genera el Pinyin utilizando la biblioteca lpinyin
            final lpinyinStr = PinyinHelper.getPinyin(
              charStr,
              format: PinyinFormat.WITH_TONE_MARK,
            );
            
            tokens.add(WordToken(
              text: charStr,
              pinyin: lpinyinStr,
              isPunctuation: false,
            ));
          } else {
            // Puntuacion, caracter en ingles o simbolo
            tokens.add(WordToken(
              text: charStr,
              pinyin: '',
              isPunctuation: true,
            ));
          }
        }
        i++;
      }
    }

    return tokens;
  }
}
