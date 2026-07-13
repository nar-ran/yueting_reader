import 'package:hive/hive.dart';

part 'reading_entry.g.dart';

// Representa un texto guardado en la biblioteca local del usuario
@HiveType(typeId: 0)
class ReadingEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String text;

  @HiveField(3)
  late DateTime dateCreated;

  @HiveField(4)
  late DateTime dateLastOpened;

  @HiveField(5)
  double? progress;

  ReadingEntry({
    required this.id,
    required this.title,
    required this.text,
    required this.dateCreated,
    required this.dateLastOpened,
    this.progress = 0.0,
  });

  // Devuelve una vista previa del texto limitada a 100 caracteres
  String get preview {
    final clean = text.trim();
    if (clean.length <= 100) return clean;
    return '${clean.substring(0, 100)}…';
  }

  // Devuelve el titulo ingresado o la primera linea del texto como alternativa
  String get displayTitle {
    if (title.isNotEmpty) return title;
    final firstLine = text.trim().split('\n').first.trim();
    return firstLine.length <= 20 ? firstLine : '${firstLine.substring(0, 20)}…';
  }

  // Devuelve el progreso de lectura, cayendo al valor inicial si es nulo
  double get readProgress => progress ?? 0.0;

  ReadingEntry copyWith({
    String? title,
    String? text,
    DateTime? dateLastOpened,
    double? progress,
  }) {
    return ReadingEntry(
      id: id,
      title: title ?? this.title,
      text: text ?? this.text,
      dateCreated: dateCreated,
      dateLastOpened: dateLastOpened ?? this.dateLastOpened,
      progress: progress ?? this.progress,
    );
  }
}
