import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:edge_tts/edge_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'tts_engine.dart';

// Implementacion de sintesis de voz usando Microsoft Edge neural TTS (Online y Gratis)
class EdgeTtsEngine implements TtsEngine {
  final AudioPlayer _audioPlayer = AudioPlayer();
  void Function(int charOffset)? _onProgress;
  VoidCallback? _onComplete;
  void Function(String msg)? _onError;
  
  String _voice = 'zh-CN-XiaoxiaoNeural';
  
  final List<WordBoundaryEvent> _events = [];
  final List<int> _eventCharOffsets = [];
  
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;

  @override
  Future<void> init(String languageCode) async {
    _voice = _getVoiceForLanguage(languageCode);
    
    // Escucha el cambio de posicion del reproductor para actualizar el resaltado de palabra
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (_events.isEmpty || _onProgress == null) return;
      
      final current100ns = position.inMicroseconds * 10;
      
      // Busca el evento que corresponda al tiempo de audio actual
      int matchedEventIdx = -1;
      for (int i = 0; i < _events.length; i++) {
        final ev = _events[i];
        if (ev.offset <= current100ns && current100ns <= ev.offset + ev.duration) {
          matchedEventIdx = i;
          break;
        }
      }
      
      if (matchedEventIdx != -1) {
        final charOffset = _eventCharOffsets[matchedEventIdx];
        if (charOffset != -1) {
          _onProgress!(charOffset);
        }
      }
    });

    // Escucha el evento de finalizacion de audio
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (_onComplete != null) {
        _onComplete!();
      }
    });
  }

  @override
  Future<void> speak(String text, double rate) async {
    await stop();
    
    // Convierte la velocidad de reproduccion al formato de Edge TTS (+XX% o -XX%)
    int percentage = ((rate - 1.0) * 100).round();
    String rateString = percentage >= 0 ? '+$percentage%' : '$percentage%';
    
    // Inicializa el objeto Communicate de Edge TTS
    final comm = Communicate(
      text: text,
      voice: _voice,
      rate: rateString,
      wordBoundary: true,
    );
    
    _events.clear();
    _eventCharOffsets.clear();
    final List<int> audioBytes = [];
    int lastSearchIndex = 0;
    
    try {
      await for (final event in comm.stream()) {
        if (event is AudioDataEvent) {
          audioBytes.addAll(event.data);
        } else if (event is WordBoundaryEvent) {
          _events.add(event);
          
          // Mapea al indice de caracteres en el texto hablado
          int charIndex = text.indexOf(event.text, lastSearchIndex);
          if (charIndex != -1) {
            lastSearchIndex = charIndex + event.text.length;
            _eventCharOffsets.add(charIndex);
          } else {
            _eventCharOffsets.add(-1);
          }
        }
      }
      
      if (audioBytes.isEmpty) {
        if (_onError != null) {
          _onError!('No se recibieron datos de audio desde el servidor de Microsoft Edge');
        }
        return;
      }
      
      // Guarda los bytes de audio en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/edge_tts_output.mp3');
      await tempFile.writeAsBytes(audioBytes);
      
      // Reproduce el archivo temporal
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      debugPrint('Error en Edge TTS: $e');
      if (_onError != null) {
        if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          _onError!('Microsoft Edge TTS requiere conexión a Internet. Por favor, verifica tu red o selecciona el motor nativo offline');
        } else {
          _onError!('Error de conexión o de síntesis con Edge TTS: $e');
        }
      }
    }
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _events.clear();
    _eventCharOffsets.clear();
  }

  @override
  void setProgressHandler(void Function(int charOffset) onProgress) {
    _onProgress = onProgress;
  }

  @override
  void setCompletionHandler(VoidCallback onComplete) {
    _onComplete = onComplete;
  }

  @override
  void setErrorHandler(void Function(String msg) onError) {
    _onError = onError;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
  }

  // Obtiene la voz de Microsoft Edge correspondiente a la variante del idioma
  String _getVoiceForLanguage(String langCode) {
    switch (langCode) {
      case 'zh-TW':
        return 'zh-TW-HsiaoChenNeural';
      case 'zh-HK':
        return 'zh-HK-HiuMaanNeural';
      case 'zh-CN':
      default:
        return 'zh-CN-XiaoxiaoNeural';
    }
  }
}
