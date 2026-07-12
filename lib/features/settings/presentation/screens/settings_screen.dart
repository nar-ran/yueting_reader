import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../../../core/theme/theme_colors.dart';

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
  String _activeTheme = 'classic';

  // Controladores y estados para los motores premium
  late TextEditingController _azureKeyController;
  late TextEditingController _azureRegionController;
  late TextEditingController _openaiKeyController;
  
  bool _obscureAzureKey = true;
  bool _obscureOpenaiKey = true;
  
  String _openaiVoice = 'alloy';
  bool _isTtsExpanded = false;
  bool _isThemeExpanded = false;

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
    _activeTheme = _settingsBox.get('active_theme', defaultValue: 'classic') as String;

    // Inicializa controladores para claves de API
    _azureKeyController = TextEditingController(
      text: _settingsBox.get('azure_api_key', defaultValue: '') as String,
    );
    _azureRegionController = TextEditingController(
      text: _settingsBox.get('azure_region', defaultValue: 'eastus') as String,
    );
    _openaiKeyController = TextEditingController(
      text: _settingsBox.get('openai_api_key', defaultValue: '') as String,
    );
    _openaiVoice = _settingsBox.get('openai_voice', defaultValue: 'alloy') as String;
  }

  @override
  void dispose() {
    _azureKeyController.dispose();
    _azureRegionController.dispose();
    _openaiKeyController.dispose();
    super.dispose();
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

  // Guarda y actualiza el tema visual seleccionado
  void _updateTheme(String themeId) {
    setState(() {
      _activeTheme = themeId;
    });
    _settingsBox.put('active_theme', themeId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<ThemeColors>() ?? ThemeColors.defaultColors;

    return Scaffold(
      backgroundColor: colors.background, // Fondo premium gris suave
      appBar: AppBar(
        title: Text(
          l10n.settings_title,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.text),
        ),
        backgroundColor: colors.cardBackground,
        elevation: 0.5,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildTtsAccordion(colors),
          const SizedBox(height: 24),
          _buildThemeAccordion(colors),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.settings_reading_lang_section, colors),
          const SizedBox(height: 12),
          _buildDropdownTile(
            title: l10n.settings_synthesis_lang,
            subtitle: l10n.settings_synthesis_lang_sub,
            value: _voiceLanguage,
            items: [
              DropdownMenuItem(value: 'zh-CN', child: Text(l10n.settings_lang_mandarin)),
              DropdownMenuItem(value: 'zh-TW', child: Text(l10n.settings_lang_taiwan)),
              DropdownMenuItem(value: 'zh-HK', child: Text(l10n.settings_lang_cantonese)),
            ],
            onChanged: (val) {
              if (val != null) {
                _updateVoiceLanguage(val);
              }
            },
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.settings_app_lang_section, colors),
          const SizedBox(height: 12),
          _buildDropdownTile(
            title: l10n.settings_app_lang_label,
            subtitle: l10n.settings_app_lang_sub,
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
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(l10n.settings_text_size_section, colors),
          const SizedBox(height: 12),
          _buildFontSizeCard(colors),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Crea un titulo de seccion estilizado
  Widget _buildSectionTitle(String title, ThemeColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colors.text.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  // Construye la seccion de seleccion de motor de voz tipo acordeon
  Widget _buildTtsAccordion(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    String engineTitle = l10n.settings_system_tts_title;
    if (_selectedEngine == 'edge') engineTitle = l10n.settings_edge_tts_title;
    if (_selectedEngine == 'azure') engineTitle = l10n.settings_azure_tts_title;
    if (_selectedEngine == 'openai') engineTitle = l10n.settings_openai_tts_title;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Fila del encabezado que actua como boton para expandir o contraer
          ListTile(
            title: Text(
              l10n.settings_tts_section,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.text.withValues(alpha: 0.6)),
            ),
            subtitle: Text(
              engineTitle,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.primary),
            ),
            trailing: Icon(
              _isTtsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: colors.primary,
            ),
            onTap: () {
              setState(() {
                _isTtsExpanded = !_isTtsExpanded;
              });
            },
          ),
          
          // Contenido colapsable con animacion de transicion suave
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                children: [
                  Divider(height: 16, color: colors.divider.withValues(alpha: 0.5)),
                  
                  // Tarjeta Google System TTS
                  _buildEngineCard(
                    id: 'system',
                    title: l10n.settings_system_tts_title,
                    description: l10n.settings_system_tts_desc,
                    tags: [l10n.settings_tag_offline, l10n.settings_tag_zero_mb, l10n.settings_tag_fast],
                    isRecommended: false,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  
                  // Tarjeta Microsoft Edge TTS
                  _buildEngineCard(
                    id: 'edge',
                    title: l10n.settings_edge_tts_title,
                    description: l10n.settings_edge_tts_desc,
                    tags: [l10n.settings_tag_online, l10n.settings_tag_ultra_quality, l10n.settings_tag_free],
                    isRecommended: true,
                    colors: colors,
                  ),
                  const SizedBox(height: 12),
                  
                  // Tarjeta Microsoft Azure Speech
                  _buildEngineCard(
                    id: 'azure',
                    title: l10n.settings_azure_tts_title,
                    description: l10n.settings_azure_tts_desc,
                    tags: [l10n.settings_tag_online, l10n.settings_tag_premium, l10n.settings_tag_api_key],
                    isRecommended: false,
                    colors: colors,
                  ),
                  if (_selectedEngine == 'azure') ...[
                    const SizedBox(height: 12),
                    _buildAzureInputs(colors),
                  ],
                  const SizedBox(height: 12),
                  
                  // Tarjeta OpenAI TTS
                  _buildEngineCard(
                    id: 'openai',
                    title: l10n.settings_openai_tts_title,
                    description: l10n.settings_openai_tts_desc,
                    tags: [l10n.settings_tag_online, l10n.settings_tag_premium, l10n.settings_tag_api_key],
                    isRecommended: false,
                    colors: colors,
                  ),
                  if (_selectedEngine == 'openai') ...[
                    const SizedBox(height: 12),
                    _buildOpenAiInputs(colors),
                  ],
                ],
              ),
            ),
            crossFadeState: _isTtsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
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
    required ThemeColors colors,
  }) {
    final isSelected = _selectedEngine == id;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => _updateEngine(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.text.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.settings_recommended_badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: id,
                  groupValue: _selectedEngine,
                  activeColor: colors.primary,
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
                color: colors.text.withValues(alpha: 0.6),
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
                      color: colors.divider.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.text.withValues(alpha: 0.7),
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

  // Campos de texto para la configuracion de Microsoft Azure Speech
  Widget _buildAzureInputs(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.divider.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _azureKeyController,
            obscureText: _obscureAzureKey,
            onChanged: (val) => _settingsBox.put('azure_api_key', val.trim()),
            style: TextStyle(fontSize: 13, color: colors.text),
            decoration: InputDecoration(
              labelText: l10n.settings_azure_api_key,
              labelStyle: TextStyle(color: colors.text.withValues(alpha: 0.7)),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_obscureAzureKey ? Icons.visibility : Icons.visibility_off, size: 18, color: colors.text.withValues(alpha: 0.6)),
                onPressed: () => setState(() => _obscureAzureKey = !_obscureAzureKey),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _azureRegionController,
            onChanged: (val) => _settingsBox.put('azure_region', val.trim()),
            style: TextStyle(fontSize: 13, color: colors.text),
            decoration: InputDecoration(
              labelText: l10n.settings_azure_region,
              labelStyle: TextStyle(color: colors.text.withValues(alpha: 0.7)),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Campos de texto para la configuracion de OpenAI TTS
  Widget _buildOpenAiInputs(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.divider.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _openaiKeyController,
            obscureText: _obscureOpenaiKey,
            onChanged: (val) => _settingsBox.put('openai_api_key', val.trim()),
            style: TextStyle(fontSize: 13, color: colors.text),
            decoration: InputDecoration(
              labelText: l10n.settings_openai_api_key,
              labelStyle: TextStyle(color: colors.text.withValues(alpha: 0.7)),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_obscureOpenaiKey ? Icons.visibility : Icons.visibility_off, size: 18, color: colors.text.withValues(alpha: 0.6)),
                onPressed: () => setState(() => _obscureOpenaiKey = !_obscureOpenaiKey),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.settings_openai_voice, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.text)),
              DropdownButton<String>(
                value: _openaiVoice,
                dropdownColor: colors.cardBackground,
                underline: const SizedBox.shrink(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.primary),
                items: const [
                  DropdownMenuItem(value: 'alloy', child: Text('Alloy')),
                  DropdownMenuItem(value: 'echo', child: Text('Echo')),
                  DropdownMenuItem(value: 'fable', child: Text('Fable')),
                  DropdownMenuItem(value: 'onyx', child: Text('Onyx')),
                  DropdownMenuItem(value: 'nova', child: Text('Nova')),
                  DropdownMenuItem(value: 'shimmer', child: Text('Shimmer')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _openaiVoice = val);
                    _settingsBox.put('openai_voice', val);
                  }
                },
              ),
            ],
          ),
        ],
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
    required ThemeColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: value,
            dropdownColor: colors.cardBackground,
            underline: const SizedBox.shrink(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
            iconEnabledColor: colors.primary,
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Muestra una tarjeta con un control deslizante y vista previa del tamaño de fuente
  Widget _buildFontSizeCard(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.format_size, size: 20, color: colors.text.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _fontSizeMultiplier,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  activeColor: colors.primary,
                  inactiveColor: colors.primary.withValues(alpha: 0.2),
                  onChanged: (val) {
                    _updateFontSize(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_fontSizeMultiplier * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.divider.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            l10n.settings_preview_label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.text.withValues(alpha: 0.4)),
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
                    color: colors.text.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '好',
                  style: TextStyle(
                    fontSize: 22 * _fontSizeMultiplier,
                    fontWeight: FontWeight.w500,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Acordeon colapsable para cambiar el tema visual de la aplicacion
  Widget _buildThemeAccordion(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    
    // Lista completa de los 10 temas soportados (Clasico + 9 de la imagen Cloud)
    final themes = [
      {'id': 'classic', 'name': l10n.localeName == 'es' ? 'Clásico Violeta' : 'Classic Violet'},
      {'id': 'earthy', 'name': l10n.localeName == 'es' ? 'Nube de Atardecer' : 'Sunset Cloud'},
      {'id': 'cloud_2', 'name': l10n.localeName == 'es' ? 'Nube de Ensueño' : 'Dream Cloud'},
      {'id': 'lavender', 'name': l10n.localeName == 'es' ? 'Nube de Lavanda' : 'Lavender Cloud'},
      {'id': 'cloud_4', 'name': l10n.localeName == 'es' ? 'Nube de Menta' : 'Mint Cloud'},
      {'id': 'cloud_5', 'name': l10n.localeName == 'es' ? 'Nube de Vainilla' : 'Vanilla Cloud'},
      {'id': 'cloud_6', 'name': l10n.localeName == 'es' ? 'Nube de Tarde' : 'Evening Cloud'},
      {'id': 'cloud_7', 'name': l10n.localeName == 'es' ? 'Nube de Coral' : 'Coral Cloud'},
      {'id': 'cloud_8', 'name': l10n.localeName == 'es' ? 'Nube de Rosas' : 'Rose Cloud'},
      {'id': 'cloud_9', 'name': l10n.localeName == 'es' ? 'Nube del Alba' : 'Dawn Cloud'},
    ];

    // Busca el nombre del tema activo para mostrarlo como subtitulo
    final currentThemeName = themes.firstWhere(
      (theme) => theme['id'] == _activeTheme,
      orElse: () => themes.first,
    )['name']!;
    
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Fila del encabezado que actua como boton para expandir o contraer
          ListTile(
            title: Text(
              l10n.settings_theme_section,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.text.withValues(alpha: 0.6)),
            ),
            subtitle: Text(
              currentThemeName,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.primary),
            ),
            trailing: Icon(
              _isThemeExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: colors.primary,
            ),
            onTap: () {
              setState(() {
                _isThemeExpanded = !_isThemeExpanded;
              });
            },
          ),
          
          // Contenido colapsable con animacion de transicion suave
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                children: [
                  Divider(height: 16, color: colors.divider.withValues(alpha: 0.5)),
                  ...themes.map((theme) {
                    final themeId = theme['id']!;
                    final themeName = theme['name']!;
                    final isSelected = _activeTheme == themeId;
                    final palette = ThemeColors.getColors(themeId);
                    
                    return InkWell(
                      onTap: () => _updateTheme(themeId),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? colors.primary : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              themeName,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: colors.text),
                            ),
                            Row(
                              children: [
                                // Circulos de previsualizacion de color de la paleta
                                _buildColorDot(palette.primary),
                                const SizedBox(width: 4),
                                _buildColorDot(palette.background),
                                const SizedBox(width: 4),
                                _buildColorDot(palette.accent),
                                const SizedBox(width: 12),
                                Radio<String>(
                                  value: themeId,
                                  groupValue: _activeTheme,
                                  activeColor: colors.primary,
                                  onChanged: (val) {
                                    if (val != null) {
                                      _updateTheme(val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            crossFadeState: _isThemeExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26, width: 0.5),
      ),
    );
  }
}
