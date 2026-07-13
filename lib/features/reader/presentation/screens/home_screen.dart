import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/services/dictionary_service.dart';
import 'reading_screen.dart';
import 'package:yueting_reader/features/library/domain/entities/reading_entry.dart';
import 'package:yueting_reader/features/library/domain/services/library_service.dart';
import 'package:yueting_reader/features/library/presentation/screens/library_screen.dart';
import 'package:yueting_reader/features/settings/presentation/screens/settings_screen.dart';

// Pantalla principal de la aplicacion con header ilustrado
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
      'text': '你好！欢迎使用阅听（YuèTīng）。\n这是一个开源 de 读听忆 (leer, escuchar y recordar) 工具。\n希望 peacetime 喜欢 learning Chinese!',
    },
    {
      'titleKey': 'example_2',
      'text': '我喜欢听中文歌，也喜欢看中文电影。\n你最喜欢什么歌？我们一起学中文吧！',
    },
    {
      'titleKey': 'example_3',
      'text': '静夜思 (Jìng yè sī)\n床前明月光，疑is地上霜。\n举头望明月，低头思故乡。',
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
      title: title.isEmpty ? AppLocalizations.of(context)!.home_new_reading : title,
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
    final colors = Theme.of(context).extension<ThemeColors>() ?? ThemeColors.defaultColors;

    return ValueListenableBuilder<DictLoadingState>(
      valueListenable: _dictService.loadingState,
      builder: (context, state, child) {
        if (state.status == DictLoadingStatus.ready) {
          return _buildMainContent(colors);
        } else if (state.status == DictLoadingStatus.error) {
          return _buildErrorScreen(state.message, colors);
        } else {
          return _buildLoaderScreen(state, colors);
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

  Widget _buildLoaderScreen(DictLoadingState state, ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
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
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '阅听',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48.0),
              
              Text(
                _getLoaderMessage(context, state),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 24.0),
              
              // Barra de progreso
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: state.progress > 0 ? state.progress : null,
                  minHeight: 10,
                  backgroundColor: colors.divider.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 16.0),
              
              Text(
                l10n.home_loader_desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.text.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message, ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.text),
              ),
              const SizedBox(height: 8.0),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.text.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: () => _dictService.init(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.home_retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text,
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

  // Genera la seccion superior de presentacion con colinas y pagoda china
  Widget _buildLandscapeHeader(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary.withValues(alpha: 0.12), colors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Pintor vectorizado de las montañas y la pagoda
          Positioned.fill(
            child: CustomPaint(
              painter: PagodaPainter(
                primaryColor: colors.primary,
                accentColor: colors.accent,
              ),
            ),
          ),
          // Etiquetas de titulo e info alineados
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 58, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yuè Tīng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.text.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '阅听 ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      'Reader',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.localeName == 'es' ? 'Tu lector universal de chino' : 'Your Universal Reading Tool',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colors.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.menu_book_rounded, color: colors.primary),
            tooltip: l10n.home_library_tooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colors.text.withValues(alpha: 0.6)),
            tooltip: l10n.home_settings_tooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header visual ilustrado
            _buildLandscapeHeader(colors),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8.0),

                  // Seccion de Continuar leyendo
                  ValueListenableBuilder<Box<ReadingEntry>>(
                    valueListenable: LibraryService().listenable,
                    builder: (context, box, _) {
                      final lastOpened = LibraryService().getLastOpened();
                      if (lastOpened == null) return const SizedBox.shrink();

                      final int percent = (lastOpened.readProgress * 100).clamp(0, 100).toInt();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.home_continue_reading,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.text.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          InkWell(
                            onTap: () => _openEntry(lastOpened),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Container(
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(color: colors.divider.withValues(alpha: 0.4), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.text.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Miniatura
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.menu_book_rounded,
                                        color: colors.primary,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Detalles de titulo y progreso
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lastOpened.displayTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: colors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.localeName == 'es'
                                              ? 'Último texto abierto · $percent%'
                                              : 'Last opened text · $percent%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.text.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: lastOpened.readProgress,
                                            minHeight: 4,
                                            backgroundColor: colors.divider.withValues(alpha: 0.3),
                                            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Boton continuar
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.primary, width: 1.5),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.play_arrow_rounded, color: colors.primary, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.localeName == 'es' ? 'Seguir' : 'Continue',
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.text.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: colors.divider.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.text.withValues(alpha: 0.01),
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
                          style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: l10n.home_input_title_hint,
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: colors.text.withValues(alpha: 0.4)),
                          ),
                        ),
                        Divider(height: 1.0, color: colors.divider.withValues(alpha: 0.3)),
                        const SizedBox(height: 8.0),
                        // Campo de texto de caracteres chinos
                        TextField(
                          controller: _textController,
                          maxLines: 8,
                          minLines: 4,
                          style: TextStyle(color: colors.text, fontSize: 16, height: 1.4),
                          decoration: InputDecoration(
                            hintText: l10n.home_input_hint,
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: colors.text.withValues(alpha: 0.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Seccion de Ejemplos rapidos
                  Text(
                    l10n.home_examples_section,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.text.withValues(alpha: 0.6),
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
                                color: colors.cardBackground,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                _getExampleTitle(context, ex['titleKey']!),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
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
                      backgroundColor: colors.primary,
                      foregroundColor: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      elevation: 2.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chrome_reader_mode_outlined, color: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text),
                        const SizedBox(width: 10),
                        Text(
                          l10n.home_start_reading,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.background == const Color(0xFFFFFFFF) ? Colors.white : colors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pintor personalizado para dibujar montañas y pagoda estilizadas adaptables a los temas
class PagodaPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  PagodaPainter({required this.primaryColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujo de colinas en segundo plano
    final paintBackHills = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final pathBack = Path();
    pathBack.moveTo(0, size.height);
    pathBack.quadraticBezierTo(size.width * 0.2, size.height * 0.45, size.width * 0.45, size.height * 0.65);
    pathBack.quadraticBezierTo(size.width * 0.7, size.height * 0.85, size.width, size.height * 0.55);
    pathBack.lineTo(size.width, size.height);
    pathBack.close();
    canvas.drawPath(pathBack, paintBackHills);

    // Dibujo de colinas en primer plano
    final paintFrontHills = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final pathFront = Path();
    pathFront.moveTo(0, size.height);
    pathFront.quadraticBezierTo(size.width * 0.35, size.height * 0.75, size.width * 0.65, size.height * 0.58);
    pathFront.quadraticBezierTo(size.width * 0.82, size.height * 0.48, size.width, size.height * 0.65);
    pathFront.lineTo(size.width, size.height);
    pathFront.close();
    canvas.drawPath(pathFront, paintFrontHills);

    // Dibujo estilizado lineal de pagoda
    final paintPagoda = Paint()
      ..color = primaryColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double px = size.width * 0.84;
    final double py = size.height * 0.56;

    // Estructuras de la pagoda de tres niveles
    canvas.drawRect(Rect.fromLTWH(px - 14, py + 22, 28, 8), paintPagoda);
    canvas.drawRect(Rect.fromLTWH(px - 10, py + 6, 20, 16), paintPagoda);
    canvas.drawLine(Offset(px - 14, py + 6), Offset(px + 14, py + 6), paintPagoda);

    canvas.drawRect(Rect.fromLTWH(px - 7, py - 6, 14, 12), paintPagoda);
    canvas.drawLine(Offset(px - 10, py - 6), Offset(px + 10, py - 6), paintPagoda);

    canvas.drawRect(Rect.fromLTWH(px - 4, py - 16, 8, 10), paintPagoda);
    canvas.drawLine(Offset(px - 6, py - 16), Offset(px + 6, py - 16), paintPagoda);

    // Aguja superior
    canvas.drawLine(Offset(px, py - 16), Offset(px, py - 24), paintPagoda);
    
    // Sol de fondo minimalista
    final paintSun = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(px - 34, py - 16), 12, paintSun);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
