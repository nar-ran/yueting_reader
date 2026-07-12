import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Pantalla de ajustes de la aplicacion para configurar motores de voz, idioma y aspecto visual
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box _settingsBox;
  
  String _selectedEngine = 'system';
  String _voiceLanguage = 'zh-CN';
  String _appLanguage = 'es';
  double _fontSizeMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    
    // Carga las configuraciones guardadas en Hive o inicializa con los valores por defecto
    _selectedEngine = _settingsBox.get('selected_engine', defaultValue: 'system') as String;
    if (_selectedEngine == 'piper') {
      _selectedEngine = 'system';
      _settingsBox.put('selected_engine', 'system');
    }
    
    _voiceLanguage = _settingsBox.get('voice_language', defaultValue: 'zh-CN') as String;
    _appLanguage = _settingsBox.get('app_language', defaultValue: 'es') as String;
    _fontSizeMultiplier = _settingsBox.get('font_size_multiplier', defaultValue: 1.0) as double;
  }

  // Guarda y actualiza la seleccion del motor de voz
  void _updateEngine(String engineId) {
    setState(() {
      _selectedEngine = engineId;
    });
    _settingsBox.put('selected_engine', engineId);
  }

  // Guarda y actualiza el idioma de voz
  void _updateVoiceLanguage(String langCode) {
    setState(() {
      _voiceLanguage = langCode;
    });
    _settingsBox.put('voice_language', langCode);
  }

  // Guarda y actualiza el idioma de la app
  void _updateAppLanguage(String langCode) {
    setState(() {
      _appLanguage = langCode;
    });
    _settingsBox.put('app_language', langCode);
  }

  // Guarda y actualiza el multiplicador del tamaño de texto
  void _updateFontSize(double value) {
    setState(() {
      _fontSizeMultiplier = value;
    });
    _settingsBox.put('font_size_multiplier', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // Fondo premium gris suave
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionTitle('Motor de Voz (TTS)'),
          const SizedBox(height: 12),
          _buildEngineCard(
            id: 'system',
            title: 'Google System TTS',
            description: 'Usa el motor nativo del celular. No consume datos y es 100% offline.',
            tags: ['Offline', '0 MB', 'Rápido'],
            isRecommended: false,
          ),
          const SizedBox(height: 12),
          _buildEngineCard(
            id: 'edge',
            title: 'Microsoft Edge TTS',
            description: 'Voces neuronales de ultra alta calidad en la nube. Requiere conexión activa.',
            tags: ['Online', 'Ultra Calidad', 'Gratis'],
            isRecommended: true,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Idioma de Lectura (Voz)'),
          const SizedBox(height: 12),
          _buildDropdownTile(
            title: 'Idioma de síntesis',
            subtitle: 'Idioma o acento para leer el texto en chino',
            value: _voiceLanguage,
            items: const [
              DropdownMenuItem(value: 'zh-CN', child: Text('Chino Mandarín (zh-CN)')),
              DropdownMenuItem(value: 'zh-TW', child: Text('Mandarín de Taiwán (zh-TW)')),
              DropdownMenuItem(value: 'zh-HK', child: Text('Cantonés de Hong Kong (zh-HK)')),
            ],
            onChanged: (val) {
              if (val != null) {
                _updateVoiceLanguage(val);
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Idioma de la Aplicación'),
          const SizedBox(height: 12),
          _buildDropdownTile(
            title: 'Idioma de interfaz',
            subtitle: 'Idioma del menú y traducciones de la app',
            value: _appLanguage,
            items: const [
              DropdownMenuItem(value: 'es', child: Text('Español')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (val) {
              if (val != null) {
                _updateAppLanguage(val);
              }
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Tamaño de Texto del Lector'),
          const SizedBox(height: 12),
          _buildFontSizeCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Crea un titulo de seccion estilizado
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  // Tarjeta interactiva para la seleccion de motor de voz
  Widget _buildEngineCard({
    required String id,
    required String title,
    required String description,
    required List<String> tags,
    required bool isRecommended,
  }) {
    final isSelected = _selectedEngine == id;
    return InkWell(
      onTap: () => _updateEngine(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Recomendado',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Radio<String>(
                  value: id,
                  groupValue: _selectedEngine,
                  activeColor: Colors.deepPurple,
                  onChanged: (val) {
                    if (val != null) {
                      _updateEngine(val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: tags.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Muestra una opcion de lista con selector desplegable (dropdown)
  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
            iconEnabledColor: Colors.deepPurple,
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Muestra una tarjeta con un control deslizante y vista previa del tamaño de fuente
  Widget _buildFontSizeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.format_size, size: 20, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _fontSizeMultiplier,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  activeColor: Colors.deepPurple,
                  inactiveColor: Colors.deepPurple.withValues(alpha: 0.2),
                  onChanged: (val) {
                    _updateFontSize(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_fontSizeMultiplier * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Vista previa:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          // Muestra un ejemplo de como se vera el Hanzi y Pinyin con la escala actual
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'hǎo',
                  style: TextStyle(
                    fontSize: 12 * _fontSizeMultiplier,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  '好',
                  style: TextStyle(
                    fontSize: 22 * _fontSizeMultiplier,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
