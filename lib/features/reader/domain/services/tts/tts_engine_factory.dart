import 'package:hive/hive.dart';
import 'tts_engine.dart';
import 'system_tts_engine.dart';
import 'edge_tts_engine.dart';

// Fabrica para instanciar el motor de voz configurado en los ajustes de Hive
class TtsEngineFactory {
  static TtsEngine create() {
    final box = Hive.box('settings');
    final String selectedEngine = box.get('selected_engine', defaultValue: 'system') as String;
    
    switch (selectedEngine) {
      case 'edge':
        return EdgeTtsEngine();
      case 'system':
      default:
        return SystemTtsEngine();
    }
  }
}
