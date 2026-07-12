import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/services/dictionary_service.dart';
import 'reading_screen.dart';
import 'package:yueting_reader/features/library/domain/entities/reading_entry.dart';
import 'package:yueting_reader/features/library/domain/services/library_service.dart';
import 'package:yueting_reader/features/library/presentation/screens/library_screen.dart';
import 'package:yueting_reader/features/settings/presentation/screens/settings_screen.dart';

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
      'title': 'Saludos Básicos',
      'text': '你好！欢迎使用阅听（YuèTīng）。\n这是一个开源 de 读听忆 (leer, escuchar y recordar) 工具。\n希望你喜欢学习中文！',
    },
    {
      'title': 'Pasatiempos',
      'text': '我喜欢听中文歌，也喜欢看中文电影。\n你最喜欢什么歌？我们一起学中文吧！',
    },
    {
      'title': 'Poema Dinastía Tang',
      'text': '静夜思 (Jìng yè sī)\n床前明月光，疑是地上霜。\n举头望明月，低头思故乡。',
    }
  ];

  @override
  void initState() {
    super.initState();
    // Start dictionary initialization when home screen loads
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

  void _useExample(Map<String, String> example) {
    setState(() {
      _titleController.text = example['title']!;
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
        const SnackBar(
          content: Text('Por favor, ingresa o pega un texto en chino mandarín.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    
    // Auto-save to library
    final entry = await LibraryService().createEntry(
      title: title.isEmpty ? 'Lectura Nueva' : title,
      text: text,
    );

    // Clear text inputs
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

  Widget _buildLoaderScreen(DictLoadingState state) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stylized App Logo
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
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
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Progress Bar
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
              
              const Text(
                'Esto es necesario solo en el primer inicio para configurar el diccionario de traducción offline (MDBG CC-CEDICT).',
                textAlign: TextAlign.center,
                style: TextStyle(
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16.0),
              const Text(
                '¡Vaya! Hubo un problema',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                label: const Text('Reintentar'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          'YuèTīng 阅听',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book, color: Colors.deepPurple),
            tooltip: 'Biblioteca',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            tooltip: 'Configuración',
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
            // Welcome Card
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
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lector Universal de Chino',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Pega cualquier texto en chino mandarín para leerlo con Pinyin alineado y traducción interactiva offline al instante.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Continue Reading Section
            ValueListenableBuilder<Box<ReadingEntry>>(
              valueListenable: LibraryService().listenable,
              builder: (context, box, _) {
                final lastOpened = LibraryService().getLastOpened();
                if (lastOpened == null) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Continuar leyendo',
                      style: TextStyle(
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
                          border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
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
                                color: Colors.deepPurple.withOpacity(0.1),
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

            // Form Title
            const Text(
              'Ingresar nuevo texto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12.0),

            // Text input Container
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Title textfield
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Título del texto (opcional)',
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
                  // Chinese Text textfield
                  TextField(
                    controller: _textController,
                    maxLines: 8,
                    minLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Pega aquí el texto en caracteres chinos (Hanzi)...',
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

            // Quick Examples Section
            const Text(
              'Ejemplos rápidos para probar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Grid of examples
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
                          ex['title']!,
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

            // Main Action Button
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chrome_reader_mode_outlined),
                  SizedBox(width: 10),
                  Text(
                    'Comenzar Lectura',
                    style: TextStyle(
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
