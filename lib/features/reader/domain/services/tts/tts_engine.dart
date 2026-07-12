import 'dart:ui';

// Estados de reproduccion comunes para todos los motores de voz
enum TtsEngineState { playing, stopped, paused }

// Interfaz comun para los diferentes motores de sintesis de voz (TTS)
abstract class TtsEngine {
  Future<void> init(String languageCode);

  // Comienza a reproducir el texto con una velocidad determinada
  Future<void> speak(String text, double rate);

  // Pausa la reproduccion actual
  Future<void> pause();

  // Detiene por completo la reproduccion y limpia el estado
  Future<void> stop();

  // Establece el callback para reportar el progreso del habla
  void setProgressHandler(void Function(int charOffset) onProgress);

  // Establece el callback que se activa al terminar de hablar el texto completo
  void setCompletionHandler(VoidCallback onComplete);

  // Establece el callback para reportar errores de reproduccion o conexion
  void setErrorHandler(void Function(String msg) onError);

  // Libera los recursos asociados al motor
  void dispose();
}
