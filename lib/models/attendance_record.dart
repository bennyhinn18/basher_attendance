import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 0)
class AttendanceRecord {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final int memberId;

  @HiveField(2)
  final String eventId;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? memberName;

  @HiveField(5)
  final String? type;
  
  @HiveField(6)
  final String? rollNumber;
  
  @HiveField(7)
  final String? name;

  AttendanceRecord({
    this.id,
    required this.memberId,
    required this.eventId,
    required this.timestamp,
    this.memberName,
    this.type,
    this.rollNumber,
    this.name,
  });

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      
      'member_id': memberId,
      'event_id': eventId,
      'timestamp': timestamp.toIso8601String(),
      'member_name': memberName,
      'type': type,
      'roll_number': rollNumber,
      'name': name,
    };
  }

  // Create from JSON for Supabase
  static AttendanceRecord fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      
      memberId: json['member_id'],
      eventId: json['event_id'],
      timestamp: DateTime.parse(json['timestamp']),
      memberName: json['member_name'],
      type: json['type'],
      rollNumber: json['roll_number'],
      name: json['name'],
    );
  }
}

