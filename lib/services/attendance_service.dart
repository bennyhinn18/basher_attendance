import 'dart:io';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  final Box<AttendanceRecord> _box = Hive.box<AttendanceRecord>('attendance_records');

  // Add a new attendance record
  Future<void> addRecord(String rollNumber, {String? name, required String userId, required String eventId}) async {
    final record = AttendanceRecord(
      memberId: userId,
      eventId: eventId,
      timestamp: DateTime.now(),
      rollNumber: rollNumber,
      name: name,
    );
    await _box.add(record);
  }

  // Get all attendance records
  List<AttendanceRecord> getAllRecords() {
    return _box.values.toList();
  }

  // Get records for a specific date
  List<AttendanceRecord> getRecordsForDate(DateTime date) {
    return _box.values.where((record) {
      return record.timestamp.year == date.year &&
          record.timestamp.month == date.month &&
          record.timestamp.day == date.day;
    }).toList();
  }

  // Get records for a date range
  List<AttendanceRecord> getRecordsForDateRange(DateTime start, DateTime end) {
    return _box.values.where((record) {
      return record.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          record.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Export records to CSV
  Future<String> exportToCSV(List<AttendanceRecord> records) async {
    List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add(['Roll Number', 'Name', 'Date', 'Time']);
    
    // Add data rows
    for (var record in records) {
      rows.add([
        record.rollNumber,
        record.name ?? 'N/A',
        '${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}',
        '${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')}',
      ]);
    }
    
    String csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    return path;
  }

  // Share CSV file
  Future<void> shareCSV(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Attendance Records');
  }

  // Clear all records
  Future<void> clearAllRecords() async {
    await _box.clear();
  }

  // Delete specific record
  Future<void> deleteRecord(int index) async {
    await _box.deleteAt(index);
  }
}
