// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 0;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      id: fields[0] as String?,
      memberId: fields[1] as int,
      eventId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      memberName: fields[4] as String?,
      type: fields[5] as String?,
      rollNumber: fields[6] as String?,
      name: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.eventId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.memberName)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.rollNumber)
      ..writeByte(7)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
