import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'tts_engine.dart';

// Implementacion de sintesis de voz usando la API REST oficial de OpenAI TTS
class OpenAiTtsEngine implements TtsEngine {
  final AudioPlayer _audioPlayer = AudioPlayer();
  void Function(int charOffset)? _onProgress;
  VoidCallback? _onComplete;
  void Function(String msg)? _onError;

  String _spokenText = '';
  Duration? _totalDuration;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerCompleteSubscription;

  @override
  Future<void> init(String languageCode) async {
    // OpenAI TTS no requiere configuracion regional ya que sus modelos tts-1 soportan
    // multiples idiomas de forma automatica al pasar el texto en chino

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
    final String apiKey = box.get('openai_api_key', defaultValue: '') as String;
    final String voice = box.get('openai_voice', defaultValue: 'alloy') as String;

    if (apiKey.trim().isEmpty) {
      _onError?.call('Por favor, ingresa tu Clave API de OpenAI en Ajustes');
      return;
    }

    // Adapta el rango del slider de velocidad (0.1 a 1.5) al rango de OpenAI (0.25 a 4.0)
    double openaiSpeed = rate.clamp(0.25, 4.0);

    final url = Uri.parse('https://api.openai.com/v1/audio/speech');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'tts-1',
          'input': text,
          'voice': voice,
          'speed': openaiSpeed,
        }),
      );

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          _onError?.call('Clave API de OpenAI inválida. Verifica tus Ajustes');
        } else if (response.statusCode == 429) {
          _onError?.call('Límite de solicitudes de OpenAI excedido o saldo insuficiente');
        } else {
          _onError?.call('Error de OpenAI TTS (${response.statusCode}): ${response.reasonPhrase}');
        }
        return;
      }

      final audioBytes = response.bodyBytes;
      if (audioBytes.isEmpty) {
        _onError?.call('El servidor de OpenAI devolvió un archivo de audio vacío');
        return;
      }

      // Guarda los bytes de audio en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/openai_tts_output.mp3');
      await tempFile.writeAsBytes(audioBytes);

      // Reproduce el archivo temporal
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      debugPrint('Error en OpenAI TTS: $e');
      if (e is SocketException || e.toString().contains('SocketException')) {
        _onError?.call('Error de red. Verifica tu conexión a Internet para usar OpenAI TTS');
      } else {
        _onError?.call('No se pudo conectar con OpenAI: $e');
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
}
