import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/member.dart';
import '../models/attendance_record.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize(String supabaseUrl, String supabaseKey) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  // EVENTS
  Future<List<Event>> getEvents() async {
    final response = await _client
        .from('events')
        .select()
        .order('created_at', ascending: false);
    
    return response.map((event) => Event.fromJson(event)).toList();
  }

  Future<Event> getEvent(String eventId) async {
    final response = await _client
        .from('events')
        .select()
        .eq('id', eventId)
        .single();
    
    return Event.fromJson(response);
  }

  Future<Event> createEvent(Event event) async {
    final response = await _client
        .from('events')
        .insert(event.toJson())
        .select()
        .single();
    
    return Event.fromJson(response);
  }

  Future<void> updateEvent(Event event) async {
    await _client
        .from('events')
        .update(event.toJson())
        .eq('id', event.id);
  }

  Future<void> deleteEvent(String eventId) async {
    await _client
        .from('events')
        .delete()
        .eq('id', eventId);
  }

  // MEMBERS
  Future<List<Member>> getMembers() async {
    final response = await _client
        .from('members')
        .select()
        .order('name');
    
    return response.map((member) => Member.fromJson(member)).toList();
  }

  Future<Member?> getMemberByRollNumber(String rollNumber) async {
    final response = await _client
        .from('members')
        .select()
        .eq('roll_number', rollNumber);
    
    if (response.isEmpty) {
      return null;
    }
    
    return Member.fromJson(response.first);
  }

  // ATTENDANCE
  Future<void> recordAttendance(AttendanceRecord record) async {
    await _client
        .from('attendance')
        .insert(record.toJson());
    
    // Update points
    await _updatePoints(record.memberId, record.eventId);
  }

  Future<List<AttendanceRecord>> getAttendanceForEvent(String eventId) async {
    final response = await _client
        .from('attendance')
        .select('*, members(name)')
        .eq('event_id', eventId);
    
    return response.map((record) => AttendanceRecord.fromJson(record)).toList();
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    final record = await _client
        .from('attendance')
        .select('member_id, event_id')
        .eq('id', recordId)
        .single();
    
    await _client
        .from('attendance')
        .delete()
        .eq('id', recordId);
    
    // Recalculate points
    await _recalculatePoints(record['member_id'], record['event_id']);
  }

  Future<void> manuallyAddAttendance(AttendanceRecord record) async {
    await recordAttendance(record);
  }

  // POINTS
  Future<void> _updatePoints(String memberId, String eventId) async {
    // Get event details to determine points
    final event = await getEvent(eventId);
    int pointsToAdd = event.pointValue;
    
    // Check if points entry exists
    final existingPoints = await _client
        .from('points')
        .select()
        .eq('member_id', memberId);
    
    if (existingPoints.isEmpty) {
      // Create new points entry
      await _client
          .from('points')
          .insert({
            'member_id': memberId,
            'points': pointsToAdd,
          });
    } else {
      // Update existing points
      int currentPoints = existingPoints.first['points'] ?? 0;
      await _client
          .from('points')
          .update({
            'points': currentPoints + pointsToAdd,
          })
          .eq('member_id', memberId);
    }
  }

  Future<void> _recalculatePoints(String memberId, String eventId) async {
    // Get all attendance records for this member
    final attendanceRecords = await _client
        .from('attendance')
        .select('event_id')
        .eq('member_id', memberId);
    
    // Calculate total points
    int totalPoints = 0;
    for (var record in attendanceRecords) {
      final event = await getEvent(record['event_id']);
      totalPoints += event.pointValue;
    }
    
    // Update points
    await _client
        .from('points')
        .update({
          'points': totalPoints,
        })
        .eq('member_id', memberId);
  }

  // LEADERBOARD
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await _client
        .from('points')
        .select('*, members(name, roll_number)')
        .order('points', ascending: false);
    
    return response;
  }
}
