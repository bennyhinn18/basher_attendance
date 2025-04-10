import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../../services/supabase_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({Key? key}) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();
  
  EventType _selectedType = EventType.dailyGathering;
  DateTime _selectedDate = DateTime.now();
  int _weeklyBashNumber = 1;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    switch (_selectedType) {
      case EventType.dailyGathering:
        _nameController.text = 'Daily Gathering - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}';
        _pointsController.text = '5';
        break;
      case EventType.weeklyBash:
        _nameController.text = 'Weekly Bash - $_weeklyBashNumber';
        _pointsController.text = '10';
        break;
      case EventType.custom:
        _pointsController.text = '0';
        break;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (_selectedType == EventType.dailyGathering) {
          _nameController.text = 'Daily Gathering - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}';
        }
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      Event event;
      
      switch (_selectedType) {
        case EventType.dailyGathering:
          event = Event.dailyGathering(_selectedDate);
          break;
        case EventType.weeklyBash:
          event = Event.weeklyBash(_weeklyBashNumber, _selectedDate);
          break;
        case EventType.custom:
          event = Event.custom(
            title: _nameController.text,
            date: _selectedDate,
            pointValue: int.parse(_pointsController.text),
            description: _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
          );
          break;
      }
      
      await _supabaseService.createEvent(event);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating event: $e')),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<EventType>(
                      segments: const [
                        ButtonSegment(
                          value: EventType.dailyGathering,
                          label: Text('Daily'),
                          icon: Icon(Icons.calendar_today),
                        ),
                        ButtonSegment(
                          value: EventType.weeklyBash,
                          label: Text('Weekly'),
                          icon: Icon(Icons.event),
                        ),
                        ButtonSegment(
                          value: EventType.custom,
                          label: Text('Custom'),
                          icon: Icon(Icons.event_note),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<EventType> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                          _updateControllers();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an event name';
                        }
                        return null;
                      },
                      enabled: _selectedType == EventType.custom,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: DateFormat('dd MMM yyyy').format(_selectedDate),
                            ),
                            onTap: () => _selectDate(context),
                          ),
                        ),
                        if (_selectedType == EventType.weeklyBash) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Bash Number',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: _weeklyBashNumber.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _weeklyBashNumber = int.tryParse(value) ?? 1;
                                  _nameController.text = 'Weekly Bash - $_weeklyBashNumber';
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Enter a number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter points value';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      enabled: _selectedType == EventType.custom,
                    ),
                    if (_selectedType == EventType.custom) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const CircularProgressIndicator()
                  : const Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
