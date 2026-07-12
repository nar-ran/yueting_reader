import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../domain/services/dictionary_service.dart';
import 'reading_screen.dart';
import 'package:yueting_reader/features/library/domain/entities/reading_entry.dart';
import 'package:yueting_reader/features/library/domain/services/library_service.dart';
import 'package:yueting_reader/features/library/presentation/screens/library_screen.dart';
import 'package:yueting_reader/features/settings/presentation/screens/settings_screen.dart';

// Pantalla principal de la aplicacion que contiene el formulario de ingreso de texto,
// los ejemplos rapidos, el boton de biblioteca, ajustes, e inicializa el diccionario
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DictionaryService _dictService = DictionaryService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  final List<Map<String, String>> _examples = [
    {
      'titleKey': 'example_1',
      'text': '你好！欢迎使用阅听（YuèTīng）。\n这是一个开源 de 读听忆 (leer, escuchar y recordar) 工具。\n希望你喜欢 learning Chinese!',
    },
    {
      'titleKey': 'example_2',
      'text': '我喜欢听中文歌，也喜欢看中文电影。\n你最喜欢什么歌？我们一起学中文吧！',
    },
    {
      'titleKey': 'example_3',
      'text': '静夜思 (Jìng yè sī)\n床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
    }
  ];

  @override
  void initState() {
    super.initState();
    // Inicia la inicializacion del diccionario al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dictService.init();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Obtiene el titulo localizado de cada ejemplo
  String _getExampleTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    if (key == 'example_1') return l10n.home_example_1_title;
    if (key == 'example_2') return l10n.home_example_2_title;
    return l10n.home_example_3_title;
  }

  void _useExample(Map<String, String> example) {
    setState(() {
      _titleController.text = _getExampleTitle(context, example['titleKey']!);
      _textController.text = example['text']!;
    });
  }

  void _openEntry(ReadingEntry entry) async {
    await LibraryService().touchEntry(entry.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReadingScreen(
          title: entry.displayTitle,
          text: entry.text,
          entryId: entry.id,
        ),
      ),
    );
  }

  void _navigateToReader() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.home_empty_input_error),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    
    // Guarda automaticamente en la biblioteca de textos
    final entry = await LibraryService().createEntry(
      title: title.isEmpty ? 'Lectura Nueva' : title,
      text: text,
    );

    // Limpia los campos de texto
    _titleController.clear();
    _textController.clear();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReadingScreen(
          title: entry.displayTitle,
          text: entry.text,
          entryId: entry.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DictLoadingState>(
      valueListenable: _dictService.loadingState,
      builder: (context, state, child) {
        if (state.status == DictLoadingStatus.ready) {
          return _buildMainContent();
        } else if (state.status == DictLoadingStatus.error) {
          return _buildErrorScreen(state.message);
        } else {
          return _buildLoaderScreen(state);
        }
      },
    );
  }

  // Traduce el estado de inicializacion del diccionario usando localizacion
  String _getLoaderMessage(BuildContext context, DictLoadingState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.status) {
      case DictLoadingStatus.downloading:
        return l10n.home_dict_downloading((state.progress * 100).toStringAsFixed(1));
      case DictLoadingStatus.extracting:
        return l10n.home_dict_extracting;
      case DictLoadingStatus.loading:
        return l10n.home_dict_loading;
      case DictLoadingStatus.ready:
        return l10n.home_dict_ready;
      case DictLoadingStatus.error:
        return l10n.home_dict_error(state.message);
      default:
        return state.message;
    }
  }

  Widget _buildLoaderScreen(DictLoadingState state) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo de la aplicacion estilizado
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '阅听',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48.0),
              
              Text(
                _getLoaderMessage(context, state),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.progress > 0 ? state.progress : null,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              ),
              const SizedBox(height: 16.0),
              
              Text(
                l10n.home_loader_desc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16.0),
              Text(
                l10n.home_error_title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: () => _dictService.init(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.home_retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: Text(
          l10n.home_title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book, color: Colors.deepPurple),
            tooltip: l10n.home_library_tooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            tooltip: l10n.home_settings_tooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de bienvenida
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.home_title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    l10n.home_subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Seccion de Continuar leyendo
            ValueListenableBuilder<Box<ReadingEntry>>(
              valueListenable: LibraryService().listenable,
              builder: (context, box, _) {
                final lastOpened = LibraryService().getLastOpened();
                if (lastOpened == null) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.home_continue_reading,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    InkWell(
                      onTap: () => _openEntry(lastOpened),
                      borderRadius: BorderRadius.circular(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lastOpened.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastOpened.preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                  ],
                );
              },
            ),

            // Formulario de ingreso de texto
            Text(
              l10n.home_input_section,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12.0),

            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Campo de texto del titulo
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.home_input_title_hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 1.0),
                  const SizedBox(height: 8.0),
                  // Campo de texto de caracteres chinos
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: l10n.home_input_hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Seccion de Ejemplos rapidos
            Text(
              l10n.home_examples_section,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Fila de ejemplos
            Row(
              children: _examples.map((ex) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => _useExample(ex),
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _getExampleTitle(context, ex['titleKey']!),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32.0),

            // Boton de accion principal
            ElevatedButton(
              onPressed: _navigateToReader,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 2.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chrome_reader_mode_outlined),
                  const SizedBox(width: 10),
                  Text(
                    l10n.home_start_reading,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
