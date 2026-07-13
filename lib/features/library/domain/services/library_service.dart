import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../entities/reading_entry.dart';

// Servicio encargado de gestionar el almacenamiento local de las lecturas
class LibraryService {
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  static const String _boxName = 'library';

  Box<ReadingEntry>? _box;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Inicializa la caja de almacenamiento Hive. Debe llamarse antes de cualquier otra operacion
  Future<void> init() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<ReadingEntry>(_boxName);
    _isInitialized = true;
  }

  Box<ReadingEntry> get _safeBox {
    if (_box == null || !_isInitialized) {
      throw StateError('LibraryService has not been initialized. Call init() first.');
    }
    return _box!;
  }

  // Devuelve todas las entradas guardadas, ordenadas por la fecha de ultima apertura (mas reciente primero)
  List<ReadingEntry> getAllEntries() {
    final entries = _safeBox.values.toList();
    entries.sort((a, b) => b.dateLastOpened.compareTo(a.dateLastOpened));
    return entries;
  }

  // Devuelve la lectura abierta mas recientemente, o null si la biblioteca esta vacia
  ReadingEntry? getLastOpened() {
    final entries = getAllEntries();
    return entries.isEmpty ? null : entries.first;
  }

  // Guarda una nueva entrada o actualiza una existente en base a su ID
  Future<void> saveEntry(ReadingEntry entry) async {
    await _safeBox.put(entry.id, entry);
  }

  // Crea y almacena una nueva entrada a partir de un titulo y texto
  Future<ReadingEntry> createEntry({
    required String title,
    required String text,
  }) async {
    final now = DateTime.now();
    final id = 'entry_${now.millisecondsSinceEpoch}';
    final entry = ReadingEntry(
      id: id,
      title: title,
      text: text,
      dateCreated: now,
      dateLastOpened: now,
    );
    await saveEntry(entry);
    return entry;
  }

  // Actualiza la fecha de ultima apertura de un texto a la hora actual
  Future<void> touchEntry(String id) async {
    final entry = _safeBox.get(id);
    if (entry == null) return;
    final updated = entry.copyWith(dateLastOpened: DateTime.now());
    await _safeBox.put(id, updated);
  }

  // Actualiza el progreso de lectura de un texto
  Future<void> updateProgress(String id, double progress) async {
    final entry = _safeBox.get(id);
    if (entry == null) return;
    final updated = entry.copyWith(progress: progress);
    await _safeBox.put(id, updated);
  }

  // Cambia el titulo de una lectura existente
  Future<void> renameEntry(String id, String newTitle) async {
    final entry = _safeBox.get(id);
    if (entry == null) return;
    final updated = entry.copyWith(title: newTitle.trim());
    await _safeBox.put(id, updated);
  }

  // Elimina una lectura en base a su ID
  Future<void> deleteEntry(String id) async {
    await _safeBox.delete(id);
  }

  // Busca lecturas que contengan la consulta en el titulo o el texto (no sensible a mayusculas/minusculas)
  List<ReadingEntry> search(String query) {
    if (query.trim().isEmpty) return getAllEntries();
    final lower = query.toLowerCase();
    return getAllEntries()
        .where((e) =>
            e.title.toLowerCase().contains(lower) ||
            e.text.toLowerCase().contains(lower))
        .toList();
  }

  // Devuelve un escuchador de eventos de la caja Hive para actualizar la UI reactivamente
  ValueListenable<Box<ReadingEntry>> get listenable {
    return _safeBox.listenable();
  }
}
