import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../entities/cedict_entry.dart';

enum DictLoadingStatus {
  notInitialized,
  downloading,
  extracting,
  loading,
  ready,
  error,
}

class DictLoadingState {
  final DictLoadingStatus status;
  final double progress; // 0.0 a 1.0
  final String message;

  DictLoadingState({
    required this.status,
    required this.progress,
    required this.message,
  });

  factory DictLoadingState.initial() => DictLoadingState(
    status: DictLoadingStatus.notInitialized,
    progress: 0.0,
    message: 'No inicializado',
  );
}

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  final ValueNotifier<DictLoadingState> loadingState =
      ValueNotifier<DictLoadingState>(DictLoadingState.initial());

  Map<String, List<CedictEntry>> _dictionary = {};
  bool _isLoaded = false;

  bool get isReady => _isLoaded;

  // Devuelve el mapa del diccionario en memoria
  Map<String, List<CedictEntry>> get dictionary => _dictionary;

  // Obtiene la ruta local del archivo de texto del diccionario
  Future<File> get _localDictFile async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/cedict_1_0_ts_utf-8_mdbg.txt');
  }

  // Verifica si el archivo del diccionario existe localmente
  Future<bool> checkDictionaryExists() async {
    final file = await _localDictFile;
    return await file.exists();
  }

  // Descarga y extrae el archivo CC-CEDICT si no esta presente
  Future<void> init() async {
    if (_isLoaded) return;

    try {
      final fileExists = await checkDictionaryExists();
      if (!fileExists) {
        await downloadAndExtract();
      }
      await loadDictionary();
    } catch (e, stackTrace) {
      debugPrint('Error al inicializar el diccionario: $e');
      debugPrint(stackTrace.toString());
      loadingState.value = DictLoadingState(
        status: DictLoadingStatus.error,
        progress: 0.0,
        message: 'Error al inicializar el diccionario: $e',
      );
    }
  }

  // Descarga el zip de CC-CEDICT y extrae el archivo de texto
  Future<void> downloadAndExtract() async {
    loadingState.value = DictLoadingState(
      status: DictLoadingStatus.downloading,
      progress: 0.0,
      message: 'Iniciando descarga de CC-CEDICT...',
    );

    final client = http.Client();
    final request = http.Request(
      'GET',
      Uri.parse(
        'https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.zip',
      ),
    );

    final response = await client.send(request);
    final totalBytes = response.contentLength ?? 0;

    final List<int> bytes = [];
    int downloadedBytes = 0;

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      downloadedBytes += chunk.length;

      double progress = 0.0;
      if (totalBytes > 0) {
        progress = downloadedBytes / totalBytes;
      }

      loadingState.value = DictLoadingState(
        status: DictLoadingStatus.downloading,
        progress: progress,
        message:
            'Descargando diccionario: ${(progress * 100).toStringAsFixed(1)}%',
      );
    }

    loadingState.value = DictLoadingState(
      status: DictLoadingStatus.extracting,
      progress: 0.5,
      message: 'Descomprimiendo archivos...',
    );

    // Decodifica el archivo zip
    final archive = ZipDecoder().decodeBytes(bytes);
    File? extractedFile;

    for (final file in archive) {
      if (file.isFile &&
          (file.name.endsWith('.txt') || file.name.endsWith('.u8'))) {
        final data = file.content as List<int>;
        final targetFile = await _localDictFile;
        await targetFile.writeAsBytes(data);
        extractedFile = targetFile;
        break;
      }
    }

    if (extractedFile == null) {
      throw Exception(
        'No se encontró el archivo de texto del diccionario en el ZIP.',
      );
    }

    loadingState.value = DictLoadingState(
      status: DictLoadingStatus.extracting,
      progress: 1.0,
      message: 'Extracción completada',
    );
  }

  // Carga CC-CEDICT desde el archivo local en el mapa de memoria
  Future<void> loadDictionary() async {
    loadingState.value = DictLoadingState(
      status: DictLoadingStatus.loading,
      progress: 0.0,
      message: 'Cargando diccionario en memoria...',
    );

    final file = await _localDictFile;
    if (!await file.exists()) {
      throw Exception('El archivo del diccionario no existe localmente.');
    }

    final newDictionary = <String, List<CedictEntry>>{};

    // Lee el archivo linea por linea
    final stream = file.openRead();
    final lines = stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    int count = 0;
    await for (final line in lines) {
      final entry = CedictEntry.parseLine(line);
      if (entry != null) {
        newDictionary.putIfAbsent(entry.simplified, () => []).add(entry);
        count++;
      }
    }

    _dictionary = newDictionary;
    _isLoaded = true;

    loadingState.value = DictLoadingState(
      status: DictLoadingStatus.ready,
      progress: 1.0,
      message: 'Diccionario listo ($count entradas)',
    );
  }

  // Busca definiciones para una palabra simplificada
  List<CedictEntry>? lookup(String word) {
    if (!_isLoaded) return null;
    return _dictionary[word];
  }
}
