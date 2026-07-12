import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import 'tts_engine.dart';

// Implementacion de sintesis de voz usando la API REST oficial de Microsoft Azure Speech
class AzureTtsEngine implements TtsEngine {
  final AudioPlayer _audioPlayer = AudioPlayer();
  void Function(int charOffset)? _onProgress;
  VoidCallback? _onComplete;
  void Function(String msg)? _onError;

  String _voice = 'zh-CN-XiaoxiaoNeural';
  String _spokenText = '';
  Duration? _totalDuration;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  @override
  Future<void> init(String languageCode) async {
    _voice = _getVoiceForLanguage(languageCode);

    // Sincronizacion por estimacion lineal basada en la posicion de audioplayers y la longitud del texto
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (_spokenText.isEmpty || _onProgress == null || _totalDuration == null) return;
      if (_totalDuration!.inMilliseconds == 0) return;

      double fraction = position.inMilliseconds / _totalDuration!.inMilliseconds;
      if (fraction > 1.0) fraction = 1.0;

      int charIndex = (fraction * _spokenText.length).round();
      if (charIndex >= _spokenText.length) charIndex = _spokenText.length - 1;
      if (charIndex < 0) charIndex = 0;

      _onProgress!(charIndex);
    });

    // Registra la duracion del audio al ser cargado
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
    });

    // Registra la finalizacion natural del habla
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (_onComplete != null) {
        _onComplete!();
      }
    });
  }

  @override
  Future<void> speak(String text, double rate) async {
    await stop();
    _spokenText = text;
    _totalDuration = null;

    final box = Hive.box('settings');
    final String lang = box.get('app_language', defaultValue: 'es') as String;
    final l10n = lookupAppLocalizations(Locale(lang));
    
    final String apiKey = box.get('azure_api_key', defaultValue: '') as String;
    final String region = box.get('azure_region', defaultValue: 'eastus') as String;

    if (apiKey.trim().isEmpty) {
      _onError?.call(l10n.tts_error_azure_api_key_empty);
      return;
    }

    // Convierte la velocidad de voz al formato de porcentaje de SSML
    int percentage = ((rate - 1.0) * 100).round();
    String rateString = percentage >= 0 ? '+$percentage%' : '$percentage%';

    // Escapa caracteres especiales en el texto para el SSML XML
    final escapedText = _xmlEscape(text);
    final ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='zh-CN'>"
        "<voice name='$_voice'>"
        "<prosody rate='$rateString'>"
        "$escapedText"
        "</prosody></voice></speak>";

    final url = Uri.parse('https://$region.tts.speech.microsoft.com/cognitiveservices/v1');

    try {
      final response = await http.post(
        url,
        headers: {
          'Ocp-Apim-Subscription-Key': apiKey,
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
          'User-Agent': 'YuetingReader',
        },
        body: ssml,
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          _onError?.call(l10n.tts_error_azure_api_key_invalid);
        } else if (response.statusCode == 403) {
          _onError?.call(l10n.tts_error_azure_access_denied);
        } else {
          _onError?.call(l10n.tts_error_native_engine('Azure REST (${response.statusCode})'));
        }
        return;
      }

      final audioBytes = response.bodyBytes;
      if (audioBytes.isEmpty) {
        _onError?.call(l10n.tts_error_no_audio);
        return;
      }

      // Guarda los bytes de audio en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/azure_tts_output.mp3');
      await tempFile.writeAsBytes(audioBytes);

      // Reproduce el archivo temporal
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      debugPrint('Error en Azure TTS: $e');
      if (e is SocketException || e.toString().contains('SocketException')) {
        _onError?.call(l10n.tts_error_network);
      } else {
        _onError?.call(l10n.tts_error_connection(e.toString()));
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
    _spokenText = '';
    _totalDuration = null;
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
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
  }

  // Escapa los caracteres reservados de XML para construir el cuerpo SSML
  String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // Obtiene el identificador oficial de la voz neuronal de Azure
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
