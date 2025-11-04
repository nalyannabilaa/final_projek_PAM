// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logbook_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogbookModelAdapter extends TypeAdapter<LogbookModel> {
  @override
  final int typeId = 2;

  @override
  LogbookModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogbookModel(
      id: fields[0] as String,
      expeditionId: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      obstacle: fields[14] as String?,
      suggestion: fields[15] as String?,
      date: fields[4] as DateTime,
      location: fields[5] as String,
      latitude: fields[6] as double?,
      longitude: fields[7] as double?,
      elevation: fields[8] as double?,
      weather: fields[9] as String?,
      images: (fields[10] as List).cast<String>(),
      username: fields[11] as String,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      dailyExpense: fields[16] as double,
      remainingBudget: fields[17] as double,
      syncedToKML: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LogbookModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.expeditionId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.elevation)
      ..writeByte(9)
      ..write(obj.weather)
      ..writeByte(10)
      ..write(obj.images)
      ..writeByte(11)
      ..write(obj.username)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.obstacle)
      ..writeByte(15)
      ..write(obj.suggestion)
      ..writeByte(16)
      ..write(obj.dailyExpense)
      ..writeByte(17)
      ..write(obj.remainingBudget)
      ..writeByte(18)
      ..write(obj.syncedToKML);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogbookModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
