import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_engine.dart';

// Implementacion del motor TTS usando la sintesis de voz nativa del dispositivo
class SystemTtsEngine implements TtsEngine {
  final FlutterTts _flutterTts = FlutterTts();
  void Function(int charOffset)? _onProgress;
  VoidCallback? _onComplete;
  void Function(String msg)? _onError;
  String _langCode = 'zh-CN';

  @override
  Future<void> init(String languageCode) async {
    _langCode = languageCode;
    
    // Traduce codigos de error del sistema
    _flutterTts.setErrorHandler((msg) {
      if (_onError != null) {
        String friendlyMsg = msg;
        if (msg.contains('-4') || msg.contains('-5')) {
          friendlyMsg = 'El acento seleccionado no está descargado en tu celular. Abre los ajustes de Texto a Voz de Android e instala el paquete de voz correspondiente (Hong Kong o Taiwán)';
        } else if (msg.contains('-3')) {
          friendlyMsg = 'Error en la salida de audio del celular. Verifica el volumen de tu dispositivo';
        }
        _onError!('Error en motor nativo: $friendlyMsg');
      }
    });

    // Verifica la compatibilidad del idioma 
    try {
      final dynamic isAvailable = await _flutterTts.isLanguageAvailable(languageCode);
      bool supported = false;
      if (isAvailable is bool) {
        supported = isAvailable;
      } else if (isAvailable is int) {
        supported = isAvailable >= 0;
      }
      
      if (!supported) {
        if (_onError != null) {
          _onError!('El idioma/acento ($languageCode) no está instalado o no es compatible con el motor nativo de tu celular');
        }
      }
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      if (_onError != null) {
        _onError!('No se pudo validar el idioma en tu dispositivo: $e');
      }
    }
    
    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      if (_onProgress != null) {
        _onProgress!(start);
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (_onComplete != null) {
        _onComplete!();
      }
    });
  }

  @override
  Future<void> speak(String text, double rate) async {
    await _flutterTts.setLanguage(_langCode);
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.speak(text);
  }

  @override
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
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
    _flutterTts.stop();
  }
}
