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
    await _updatePoints(record.memberId, record.eventId.toString());
  }

  Future<List<AttendanceRecord>> getAttendanceForEvent(String eventId) async {
    try {
      print('Fetching attendance records for event: $eventId');
      final response = await _client
          .from('attendance')
          .select('id, member_id, event_id, timestamp, member_name, type, roll_number, name')
          .eq('event_id', eventId);
      
      print('Fetched ${response.length} attendance records');
      for (var record in response) {
        print('Record: ID=${record['id']}, Member=${record['member_name']}');
      }
      
      return response.map((record) => AttendanceRecord.fromJson(record)).toList();
    } catch (e) {
      print('Error fetching attendance records: $e');
      rethrow;
    }
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      print('Starting deletion process for record ID: $recordId');
      
      // First get the record details before deletion
      print('Fetching record details...');
      final recordData = await _client
          .from('attendance')
          .select('member_id, event_id')
          .eq('id', recordId)
          .single();
      
      print('Record data fetched: $recordData');
      
      // Store these values before deletion
      final memberId = recordData['member_id'];
      final eventId = recordData['event_id'];
      print('Extracted memberId: $memberId, eventId: $eventId');
      
      // Now delete the record
      print('Deleting attendance record...');
      final deleteResponse = await _client
          .from('attendance')
          .delete()
          .eq('id', recordId);
      
      print('Delete response: $deleteResponse');
      
      // After successful deletion, recalculate points
      print('Recalculating points...');
      await _recalculatePoints(memberId, eventId);
      print('Points recalculation complete');
      
    } catch (e, stackTrace) {
      print('DETAILED ERROR deleting attendance record:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw to let the UI handle it
    }
  }

  Future<void> manuallyAddAttendance(AttendanceRecord record) async {
    await recordAttendance(record);
  }

  // POINTS
  Future<void> _updatePoints(int memberId, String eventId) async {
    // Get event details to determine points
    final event = await getEvent(eventId);
    int pointsToAdd = event.pointValue;
    
    // Check if points entry exists for this specific event and member
    final existingPointsForEvent = await _client
        .from('points')
        .select()
        .eq('member_id', memberId)
        .eq('event_id', eventId);
    
    // Only add points if no record exists for this event
    if (existingPointsForEvent.isEmpty) {
      // Create new points entry for this event
      await _client
          .from('points')
          .insert({
            'member_id': memberId,
            'event_id': eventId, // Add event_id to track which event these points are for
            'points': pointsToAdd,
            'description': 'Points for attending ${event.title}',
            'updated_at': DateTime.now().toIso8601String(),
          });
    }
    // If a record already exists, do nothing (prevent duplicate points)
  }

  Future<void> _recalculatePoints(dynamic memberId, String eventId) async {
    // Make sure memberId is properly converted to int if needed
    int memberIdInt = memberId is String ? int.parse(memberId) : memberId as int;
    
    try {
      // Delete points entry for this specific event/member combination
      await _client
          .from('points')
          .delete()
          .eq('member_id', memberIdInt)
          .eq('event_id', eventId);
    } catch (e) {
      print('Error recalculating points: $e');
      // We can continue even if points deletion fails
    }
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
