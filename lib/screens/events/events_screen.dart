import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../services/supabase_service.dart';
import 'event_details_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _supabaseService.getEvents();
      setState(() {
        _events = events;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _buildEmptyState()
              : _buildEventsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateEvent(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateEvent(),
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: _buildEventTypeIcon(event.type),
            title: Text(event.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd MMM yyyy').format(event.date)),
                Text('${event.pointValue} points'),
              ],
            ),
            trailing: event.isActive
                ? const Icon(Icons.circle, color: Colors.green, size: 12)
                : const Icon(Icons.circle, color: Colors.grey, size: 12),
            onTap: () => _navigateToEventDetails(event),
          ),
        );
      },
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

  Future<void> _navigateToCreateEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventScreen()),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _navigateToEventDetails(Event event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: event.id),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }
}
