import 'package:flutter/material.dart';
import '../../domain/entities/word_token.dart';

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
          // Drag handle
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
          
          // Word & Pinyin Row
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
          
          // Traditional form if different
          if (entry != null && entry.traditional != entry.simplified) ...[
            const SizedBox(height: 8.0),
            Text(
              'Tradicional: ${entry.traditional}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          
          const Divider(height: 24.0, thickness: 1.0),
          
          // Definitions title
          const Text(
            'Definiciones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),

          // Definitions list
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
                'No se encontró traducción en el diccionario local para esta palabra.',
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
