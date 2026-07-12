import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  
  runApp(const YuetingApp());
}

class YuetingApp extends StatelessWidget {
  const YuetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YuèTīng 阅听',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F9FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0.5,
          scrolledUnderElevation: 1.0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
