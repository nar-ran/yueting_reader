// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingEntryAdapter extends TypeAdapter<ReadingEntry> {
  @override
  final int typeId = 0;

  @override
  ReadingEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      text: fields[2] as String,
      dateCreated: fields[3] as DateTime,
      dateLastOpened: fields[4] as DateTime,
      progress: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.dateCreated)
      ..writeByte(4)
      ..write(obj.dateLastOpened)
      ..writeByte(5)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
