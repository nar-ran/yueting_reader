import 'package:flutter/material.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../domain/entities/word_token.dart';

// Modal inferior que muestra las traducciones y pinyin de la palabra seleccionada
class TranslationBottomSheet extends StatelessWidget {
  final WordToken token;

  const TranslationBottomSheet({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final entry = token.dictEntry;
    final hasDefinitions = entry != null && entry.definitions.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicador visual de arrastre
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          
          // Fila de palabra y pinyin
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                token.text,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  token.pinyin,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
          
          // Forma tradicional si es diferente de la simplificada
          if (entry != null && entry.traditional != entry.simplified) ...[
            const SizedBox(height: 8.0),
            Text(
              l10n.sheet_traditional(entry.traditional),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const Divider(height: 24.0, thickness: 1.0),
          
          // Titulo de definiciones
          Text(
            l10n.sheet_definitions,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),

          // Lista de definiciones
          if (hasDefinitions)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entry.definitions.asMap().entries.map((item) {
                    final idx = item.key + 1;
                    final def = item.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$idx. ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              def,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                l10n.sheet_no_translation,
                style: TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
