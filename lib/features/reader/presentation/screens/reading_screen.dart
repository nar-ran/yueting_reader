import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/word_token.dart';
import '../../domain/services/segmenter_service.dart';
import '../../domain/services/tts/tts_engine.dart';
import '../../domain/services/tts/tts_engine_factory.dart';
import '../widgets/word_widget.dart';
import '../widgets/translation_bottom_sheet.dart';
import 'package:yueting_reader/features/library/domain/services/library_service.dart';

// Estados de reproduccion de audio
enum TtsState { playing, stopped, paused }

// Pantalla principal de lectura con soporte de resaltado por palabra y audio local
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

  // Variables para la reproduccion de voz (TTS)
  late TtsEngine _ttsEngine;
  TtsState _ttsState = TtsState.stopped;
  int? _playingTokenIndex;
  
  // Velocidad inicial
  double _speechRate = 0.5;
  
  // Multiplicador de escala de texto
  double _fontSizeMultiplier = 1.0;
  
  // Limites de caracteres para cada palabra
  List<int> _tokenStartOffsets = [];
  List<int> _tokenEndOffsets = [];
  
  // Desplazamientos para controlar saltos y repeticiones
  int _currentSpeakCharOffset = 0;
  int _currentSpeakTokenIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFontSizeSettings();
    _segmentText();
    _touchEntry();
  }

  @override
  void dispose() {
    _ttsEngine.dispose(); // Libera los recursos del motor al salir
    super.dispose();
  }

  // Carga el tamaño de texto configurado en Hive
  void _loadFontSizeSettings() {
    final box = Hive.box('settings');
    _fontSizeMultiplier = box.get('font_size_multiplier', defaultValue: 1.0) as double;
  }

  // Actualiza la fecha de ultima apertura en la biblioteca
  void _touchEntry() {
    if (widget.entryId != null) {
      LibraryService().touchEntry(widget.entryId!);
    }
  }

  // Inicializa los manejadores y configuracion del servicio TTS
  Future<void> _initTts() async {
    _ttsEngine = TtsEngineFactory.create();
    
    // Obtiene el idioma de voz configurado en los ajustes de Hive
    final box = Hive.box('settings');
    final String voiceLanguage = box.get('voice_language', defaultValue: 'zh-CN') as String;
    
    // Asocia el manejador de errores antes de inicializar para capturar problemas de inicio
    _ttsEngine.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _playingTokenIndex = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    await _ttsEngine.init(voiceLanguage);

    // Mapea el progreso del audio hablado a los tokens usando la posicion de caracteres
    _ttsEngine.setProgressHandler((charOffset) {
      if (mounted) {
        // Sumamos el offset inicial para obtener la posicion absoluta en el texto completo
        final absoluteOffset = _currentSpeakCharOffset + charOffset;
        final matchedIndex = _findTokenIndexFromCharOffset(absoluteOffset);
        if (matchedIndex != -1) {
          setState(() {
            _playingTokenIndex = matchedIndex;
            _currentSpeakTokenIndex = matchedIndex;
          });
        }
      }
    });

    // Controla la finalizacion natural del habla
    _ttsEngine.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _ttsState = TtsState.stopped;
          _playingTokenIndex = null;
          _currentSpeakTokenIndex = 0; // Reinicia al inicio al finalizar
          _currentSpeakCharOffset = 0;
        });
      }
    });
  }

  // Busca el indice del token correspondiente a una posicion de caracter del texto original
  int _findTokenIndexFromCharOffset(int charOffset) {
    for (int i = 0; i < _tokens.length; i++) {
      if (_tokenStartOffsets[i] <= charOffset && charOffset < _tokenEndOffsets[i]) {
        return i;
      }
    }
    return -1;
  }

  // Segmenta el texto de manera asincrona y calcula las posiciones de caracteres de cada token
  void _segmentText() {
    setState(() {
      _isSegmenting = true;
    });
    
    Future.microtask(() async {
      final tokens = _segmenterService.segment(widget.text);
      
      // Calcula los limites de caracteres de cada palabra para sincronizar el resaltado de audio
      int currentOffset = 0;
      final List<int> starts = [];
      final List<int> ends = [];
      for (final token in tokens) {
        starts.add(currentOffset);
        currentOffset += token.text.length;
        ends.add(currentOffset);
      }

      if (mounted) {
        setState(() {
          _tokens = tokens;
          _tokenStartOffsets = starts;
          _tokenEndOffsets = ends;
          _isSegmenting = false;
        });
        
        // Inicializa el reproductor de voz una vez segmentado el texto
        await _initTts();
      }
    });
  }

  // Comienza a reproducir el texto a partir de un indice de token especifico (soporta saltos y repeticiones)
  Future<void> _speakFromIndex(int index) async {
    await _ttsEngine.stop();
    
    if (index >= _tokens.length) {
      setState(() {
        _ttsState = TtsState.stopped;
        _playingTokenIndex = null;
        _currentSpeakTokenIndex = 0;
        _currentSpeakCharOffset = 0;
      });
      return;
    }

    // Obtiene la posicion de caracter inicial del token seleccionado
    final int startCharOffset = _tokenStartOffsets[index];
    final String substring = widget.text.substring(startCharOffset);

    // Registra el offset inicial para el handler de progreso
    _currentSpeakCharOffset = startCharOffset;
    _currentSpeakTokenIndex = index;

    await _ttsEngine.speak(substring, _speechRate);
    if (mounted) {
      setState(() {
        _ttsState = TtsState.playing;
        _playingTokenIndex = index;
      });
    }
  }

  // Pausa la reproduccion actual
  Future<void> _pause() async {
    await _ttsEngine.pause();
    setState(() {
      _ttsState = TtsState.paused;
    });
  }

  // Detiene por completo la reproduccion y limpia el resaltado de palabra
  Future<void> _stop() async {
    await _ttsEngine.stop();
    setState(() {
      _ttsState = TtsState.stopped;
      _playingTokenIndex = null;
      _currentSpeakCharOffset = 0;
      _currentSpeakTokenIndex = 0;
    });
  }

  // Cambia la velocidad de reproduccion del TTS en tiempo real
  Future<void> _changeSpeed(double rate) async {
    setState(() {
      _speechRate = rate;
    });
    
    // Si se esta reproduciendo actualmente, reinicia el habla desde la palabra actual para aplicar el cambio al instante
    if (_ttsState == TtsState.playing) {
      final indexToResume = _playingTokenIndex ?? _currentSpeakTokenIndex;
      await _speakFromIndex(indexToResume);
    }
  }

  // Muestra el modal inferior con definiciones de diccionario al tocar un token
  void _handleTokenTap(int index, WordToken token) {
    if (token.isPunctuation) return;

    setState(() {
      _selectedTokenIndex = index;
      _currentSpeakTokenIndex = index; // Actualiza el punto de inicio de la reproduccion al tocar
    });

    // Si el audio se esta reproduciendo, salta inmediatamente a la palabra seleccionada
    if (_ttsState == TtsState.playing) {
      _speakFromIndex(index);
    }

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

  // Barra flotante inferior de control de reproduccion de audio
  Widget _buildPlayerBar(ThemeColors colors) {
    if (_isSegmenting) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: colors.text.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botones de control Play/Pause/Stop
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.stop_rounded, size: 28, color: colors.text.withValues(alpha: 0.5)),
                      onPressed: _stop,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_ttsState == TtsState.playing) {
                          _pause();
                        } else {
                          // Reproduce o reanuda desde la posicion guardada actual
                          _speakFromIndex(_playingTokenIndex ?? _currentSpeakTokenIndex);
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _ttsState == TtsState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Etiqueta de estado
                _buildStatusText(colors),
              ],
            ),
            const SizedBox(height: 8),
            // Deslizador de velocidad en tiempo real
            Row(
              children: [
                Icon(Icons.speed_rounded, size: 18, color: colors.text.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  l10n.reader_speed_label(_speechRate.toStringAsFixed(1)),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.text),
                ),
                Expanded(
                  child: Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 1.5,
                    divisions: 14,
                    activeColor: colors.primary,
                    inactiveColor: colors.primary.withValues(alpha: 0.2),
                    onChanged: _changeSpeed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Construye la etiqueta de estado de reproduccion
  Widget _buildStatusText(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    String status = l10n.reader_status_ready;
    if (_ttsState == TtsState.playing) {
      status = l10n.reader_status_playing;
    } else if (_ttsState == TtsState.paused) {
      status = l10n.reader_status_paused;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _ttsState == TtsState.playing 
            ? colors.accent.withValues(alpha: 0.3)
            : colors.divider.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<ThemeColors>() ?? ThemeColors.defaultColors;

    return Scaffold(
      backgroundColor: colors.background, // Fondo premium gris suave
      appBar: AppBar(
        title: Text(
          widget.title.isNotEmpty ? widget.title : l10n.reader_title_fallback,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        backgroundColor: colors.cardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: _isSegmenting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    l10n.reader_processing,
                    style: TextStyle(
                      fontSize: 15,
                      color: colors.text.withValues(alpha: 0.6),
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
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: colors.text.withValues(alpha: 0.02),
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
                      isPlaying: _playingTokenIndex == index,
                      fontSizeMultiplier: _fontSizeMultiplier,
                      onTap: () => _handleTokenTap(index, token),
                    );
                  }),
                ),
              ),
            ),
      bottomNavigationBar: _buildPlayerBar(colors),
    );
  }
}
