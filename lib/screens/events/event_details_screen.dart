import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../models/attendance_record.dart';
import '../../services/supabase_service.dart';
import 'manual_attendance_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  bool _isDeleting = false;
  late Event _event;
  List<AttendanceRecord> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final event = await _supabaseService.getEvent(widget.eventId);
      final records = await _supabaseService.getAttendanceForEvent(widget.eventId);
      
      setState(() {
        _event = event;
        _attendanceRecords = records;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading event details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This will also remove all attendance records for this event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _supabaseService.deleteEvent(widget.eventId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  Future<void> _toggleEventStatus() async {
    try {
      final updatedEvent = _event.copyWith(isActive: !_event.isActive);
      await _supabaseService.updateEvent(updatedEvent);
      
      setState(() {
        _event = updatedEvent;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _event.isActive 
                ? 'Event activated successfully' 
                : 'Event deactivated successfully'
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating event: $e')),
      );
    }
  }

  Future<void> _navigateToManualAttendance() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualAttendanceScreen(event: _event),
      ),
    );

    if (result == true) {
      _loadEventDetails();
    }
  }

  Future<void> _deleteAttendanceRecord(String? recordId) async {
    if (recordId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete record: no ID available')),
      );
      return;
    }
    
    // Show loading indicator 
    setState(() {
      _isLoading = true;
    });
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance Record'),
        content: const Text(
          'Are you sure you want to delete this attendance record? This will also update the member\'s points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  
    if (confirmed != true) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
  
    try {
      await _supabaseService.deleteAttendanceRecord(recordId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance record deleted successfully')),
        );
        // Reload data after successful deletion
        _loadEventDetails();
      }
    } catch (e) {
      print('Error deleting record: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting attendance record: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_event.title),
        actions: [
          IconButton(
            icon: Icon(_event.isActive ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleEventStatus,
            tooltip: _event.isActive ? 'Deactivate Event' : 'Activate Event',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isDeleting ? null : _deleteEvent,
            tooltip: 'Delete Event',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildEventDetailsCard(),
          const SizedBox(height: 16),
          _buildAttendanceHeader(),
          Expanded(
            child: _attendanceRecords.isEmpty
                ? _buildEmptyAttendanceState()
                : _buildAttendanceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToManualAttendance,
        child: const Icon(Icons.person_add),
        tooltip: 'Add Attendance Manually',
      ),
    );
  }

  Widget _buildEventDetailsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildEventTypeIcon(_event.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _event.type.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text('${_event.pointValue} pts'),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_event.date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (_event.description != null && _event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _event.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.circle, size: 12),
                const SizedBox(width: 8),
                Text(
                  _event.isActive ? 'Active' : 'Inactive',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _event.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeIcon(EventType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case EventType.dailyGathering:
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case EventType.weeklyBash:
        iconData = Icons.event;
        iconColor = Colors.purple;
        break;
      case EventType.custom:
        iconData = Icons.event_note;
        iconColor = Colors.orange;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _buildAttendanceHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Attendance Records',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Chip(
            label: Text('${_attendanceRecords.length} members'),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAttendanceState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToManualAttendance,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Manually'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: _attendanceRecords.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        print('Attendance Record: ${record.toJson()}');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                record.memberName != null 
                    ? record.memberName!.substring(0, 1) 
                    : '?'
              ),
            ),
            title: Text(record.memberName ?? 'Unknown Member'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time: ${DateFormat('hh:mm a').format(record.timestamp)}'),
                Text('Type: ${record.type}'),
              ],
            ),
                        trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // Debug print to verify record ID
                print('Record ID about to delete: ${record.id}');
                if (record.id != null) {
                  _deleteAttendanceRecord(record.id!);
                } else {
                  print('WARNING: Cannot delete record - ID is null');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Record ID is null')),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
