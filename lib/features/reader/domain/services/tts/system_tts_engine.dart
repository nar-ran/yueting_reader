import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
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
    
    // Carga las traducciones oficiales de la app basadas en el idioma activo
    final String lang = Hive.box('settings').get('app_language', defaultValue: 'es') as String;
    final l10n = lookupAppLocalizations(Locale(lang));
    
    // Traduce codigos de error del sistema
    _flutterTts.setErrorHandler((msg) {
      if (_onError != null) {
        String friendlyMsg = msg;
        if (msg.contains('-4') || msg.contains('-5')) {
          friendlyMsg = l10n.tts_error_accent_not_downloaded;
        } else if (msg.contains('-3')) {
          friendlyMsg = l10n.tts_error_audio_output;
        }
        _onError!(l10n.tts_error_native_engine(friendlyMsg));
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
          _onError!(l10n.tts_error_language_not_installed(languageCode));
        }
      }
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      if (_onError != null) {
        _onError!(l10n.tts_error_validate_language(e.toString()));
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
