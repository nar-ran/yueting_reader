import 'package:flutter/material.dart';
import '../../domain/entities/word_token.dart';
import '../../domain/services/segmenter_service.dart';
import '../widgets/word_widget.dart';
import '../widgets/translation_bottom_sheet.dart';
import 'package:yueting_reader/features/library/domain/services/library_service.dart';

/// Pantalla principal de lectura con soporte de traducción y registro en biblioteca
class ReadingScreen extends StatefulWidget {
  final String title;
  final String text;
  final String? entryId;

  const ReadingScreen({
    super.key,
    required this.title,
    required this.text,
    this.entryId,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final SegmenterService _segmenterService = SegmenterService();
  List<WordToken> _tokens = [];
  bool _isSegmenting = true;
  int? _selectedTokenIndex;

  @override
  void initState() {
    super.initState();
    _segmentText();
    _touchEntry();
  }

  /// Actualiza la fecha de última apertura en la biblioteca
  void _touchEntry() {
    if (widget.entryId != null) {
      LibraryService().touchEntry(widget.entryId!);
    }
  }

  /// Segmenta el texto de manera asíncrona
  void _segmentText() {
    setState(() {
      _isSegmenting = true;
    });
    
    Future.microtask(() {
      final tokens = _segmenterService.segment(widget.text);
      if (mounted) {
        setState(() {
          _tokens = tokens;
          _isSegmenting = false;
        });
      }
    });
  }

  /// Muestra el modal inferior con definiciones de diccionario al tocar un token
  void _handleTokenTap(int index, WordToken token) {
    if (token.isPunctuation) return;

    setState(() {
      _selectedTokenIndex = index;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TranslationBottomSheet(token: token),
    ).then((_) {
      // Limpia la selección al cerrar el modal
      if (mounted) {
        setState(() {
          _selectedTokenIndex = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // Fondo premium gris suave
      appBar: AppBar(
        title: Text(
          widget.title.isNotEmpty ? widget.title : 'Lectura',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isSegmenting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Procesando texto y pinyin...',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 4.0, // Espaciado horizontal
                  runSpacing: 16.0, // Espaciado vertical
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: List.generate(_tokens.length, (index) {
                    final token = _tokens[index];
                    return WordWidget(
                      token: token,
                      isSelected: _selectedTokenIndex == index,
                      onTap: () => _handleTokenTap(index, token),
                    );
                  }),
                ),
              ),
            ),
    );
  }
}
