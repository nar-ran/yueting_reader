import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yueting_reader/l10n/app_localizations.dart';
import 'core/theme/theme_colors.dart';
import 'features/library/domain/entities/reading_entry.dart';
import 'features/library/domain/services/library_service.dart';
import 'features/reader/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive y registerAdapter
  await Hive.initFlutter();
  Hive.registerAdapter(ReadingEntryAdapter());
  
  // Inicializar LibraryService
  await LibraryService().init();
  
  // Abrir la caja de configuracion de la aplicacion
  await Hive.openBox('settings');
  
  runApp(const YuetingApp());
}

class YuetingApp extends StatelessWidget {
  const YuetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha de forma reactiva los cambios en la caja de ajustes de Hive
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final String appLang = box.get('app_language', defaultValue: 'es') as String;
        final String activeTheme = box.get('active_theme', defaultValue: 'classic') as String;
        final Locale locale = Locale(appLang);

        return MaterialApp(
          title: 'YuèTīng 阅听',
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeColors.getThemeData(activeTheme),
          home: const HomeScreen(),
        );
      },
    );
  }
}
