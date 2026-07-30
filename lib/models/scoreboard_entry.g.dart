// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scoreboard_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreboardEntryAdapter extends TypeAdapter<ScoreboardEntry> {
  @override
  final int typeId = 0;

  @override
  ScoreboardEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreboardEntry(
      id: fields[0] as String,
      categoryName: fields[1] as String,
      correctCount: fields[2] as int,
      totalQuestions: fields[3] as int,
      timestamp: fields[4] as DateTime,
      userId: fields[5] as String?,
      displayName: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreboardEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryName)
      ..writeByte(2)
      ..write(obj.correctCount)
      ..writeByte(3)
      ..write(obj.totalQuestions)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.displayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreboardEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
