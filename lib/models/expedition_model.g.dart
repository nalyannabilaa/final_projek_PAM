// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expedition_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpeditionModelAdapter extends TypeAdapter<ExpeditionModel> {
  @override
  final int typeId = 1;

  @override
  ExpeditionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpeditionModel(
      expeditionId: fields[0] as int,
      leaderId: fields[1] as int,
      leaderName: fields[2] as String,
      expeditionName: fields[3] as String,
      location: fields[4] as String,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime,
      status: fields[7] as String,
      totalBudget: fields[8] as double,
      currency: fields[9] as String,
      convertedBudget: fields[10] as double,
      targetCurrency: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExpeditionModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.expeditionId)
      ..writeByte(1)
      ..write(obj.leaderId)
      ..writeByte(2)
      ..write(obj.leaderName)
      ..writeByte(3)
      ..write(obj.expeditionName)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.totalBudget)
      ..writeByte(9)
      ..write(obj.currency)
      ..writeByte(10)
      ..write(obj.convertedBudget)
      ..writeByte(11)
      ..write(obj.targetCurrency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpeditionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
