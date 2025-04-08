import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 0)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String rollNumber;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String? name;

  AttendanceRecord({
    required this.rollNumber,
    required this.timestamp,
    this.name,
  });
}

