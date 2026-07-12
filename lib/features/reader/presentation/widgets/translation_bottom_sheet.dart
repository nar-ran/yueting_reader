import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../domain/entities/word_token.dart';

// Modal inferior que muestra las traducciones y pinyin de la palabra seleccionada
class TranslationBottomSheet extends StatefulWidget {
  final WordToken token;

  const TranslationBottomSheet({
    super.key,
    required this.token,
  });

  @override
  State<TranslationBottomSheet> createState() => _TranslationBottomSheetState();
}

class _TranslationBottomSheetState extends State<TranslationBottomSheet> {
  List<String>? _translatedDefinitions;
  bool _isTranslating = false;

  // Traduce dinamicamente las definiciones del ingles al español usando la API de Google Translate gratis
  Future<void> _translateDefinitions() async {
    final entry = widget.token.dictEntry;
    if (entry == null || entry.definitions.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final List<String> translated = [];
      for (final def in entry.definitions) {
        final url = Uri.parse(
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=es&dt=t&q=${Uri.encodeComponent(def)}',
        );
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
            final parts = decoded[0] as List;
            final text = parts.map((part) => part[0]).join();
            translated.add(text);
          } else {
            translated.add(def);
          }
        } else {
          translated.add(def);
        }
      }

      if (mounted) {
        setState(() {
          _translatedDefinitions = translated;
          _isTranslating = false;
        });
      }
    } catch (e) {
      debugPrint('Error al traducir definiciones: $e');
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo traducir. Verifica tu conexión a Internet'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.token.dictEntry;
    final hasDefinitions = entry != null && entry.definitions.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;
    
    // Solo muestra el boton de traducir si el idioma de la app es Español
    final showTranslateButton = l10n.localeName == 'es' &&
        hasDefinitions &&
        _translatedDefinitions == null;

    final definitionsToShow = _translatedDefinitions ?? entry?.definitions ?? [];

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
                widget.token.text,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  widget.token.pinyin,
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
          
          // Titulo de definiciones con boton opcional de traduccion
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.sheet_definitions,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              if (showTranslateButton) ...[
                if (_isTranslating)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.g_translate_rounded, size: 14, color: Colors.deepPurple),
                    label: const Text(
                      'Traducir',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                    onPressed: _translateDefinitions,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8.0),

          // Lista de definiciones
          if (hasDefinitions)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: definitionsToShow.asMap().entries.map((item) {
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
