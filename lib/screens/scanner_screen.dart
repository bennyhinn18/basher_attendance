import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import '../services/attendance_service.dart';
import '../services/supabase_service.dart';
import '../models/event.dart';
import '../models/member.dart';
import '../models/attendance_record.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final SupabaseService _supabaseService = SupabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  
  String _lastScannedCode = '';
  bool _isScanning = false;
  bool _showSuccess = false;
  bool _isLoadingEvents = true;
  List<Event> _activeEvents = [];
  Event? _selectedEvent;
  Member? _lastScannedMember;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadActiveEvents();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadActiveEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final events = await _supabaseService.getEvents();
      final activeEvents = events.where((event) => event.isActive).toList();
      
      setState(() {
        _activeEvents = activeEvents;
        // Select the most recent event by default
        if (activeEvents.isNotEmpty) {
          _selectedEvent = activeEvents.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: $e')),
      );
    } finally {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _scanBarcode() async {
    if (_isScanning) return;
    
    if (_selectedEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event first')),
      );
      return;
    }
    
    setState(() {
      _isScanning = true;
      _showSuccess = false;
      _lastScannedMember = null;
    });

    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6750A4',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        // Get member from Supabase
        final member = await _supabaseService.getMemberByRollNumber(barcodeScanRes);
        
        if (member == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Member with roll number $barcodeScanRes not found')),
            );
          }
          return;
        }
        
        // Record attendance in Supabase
        final record = AttendanceRecord(
          memberId: member.id,
          eventId: _selectedEvent!.id,
          rollNumber: barcodeScanRes,
          type: 'scan',
          timestamp: DateTime.now(), // Add this line
          memberName: member.name,
        );
        
        await _supabaseService.recordAttendance(record);
        
        // Also save locally
        await _attendanceService.addRecord(
          barcodeScanRes,
          name: member.name,
          eventId: _selectedEvent!.id, // Add this missing required parameter
          userId: member.id,
        );
        
        // Provide feedback
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 200);
        }
        
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        
        setState(() {
          _lastScannedCode = barcodeScanRes;
          _lastScannedMember = member;
          _showSuccess = true;
        });
        
        _animationController.reset();
        _animationController.forward();
      }
    } on PlatformException {
      // Handle platform exceptions
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording attendance: $e')),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance'),
        centerTitle: true,
      ),
      body: _isLoadingEvents
          ? const Center(child: CircularProgressIndicator())
          : _activeEvents.isEmpty
              ? _buildNoEventsState()
              : _buildScannerContent(),
    );
  }

  Widget _buildNoEventsState() {
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
            'No active events found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/events');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEventSelector(),
          const SizedBox(height: 24),
          if (_showSuccess)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Lottie.asset(
                    'assets/animations/success.json',
                    controller: _animationController,
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attendance Marked!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_lastScannedMember != null) ...[
                    Text(
                      _lastScannedMember!.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      'Roll Number: ${_lastScannedMember!.rollNumber}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else
                    Text(
                      'Roll Number: $_lastScannedCode',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  Text(
                    'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Event: ${_selectedEvent?.title}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Points: +${_selectedEvent?.pointValue}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Lottie.asset(
              'assets/animations/scan.json',
              height: 250,
              width: 250,
            ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(_isScanning ? 'Scanning...' : 'Scan Barcode'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<Event>(
        value: _selectedEvent,
        hint: const Text('Select Event'),
        underline: const SizedBox(),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down),
        items: _activeEvents.map((Event event) {
          return DropdownMenuItem<Event>(
            value: event,
            child: Row(
              children: [
                _buildEventTypeIcon(event.type),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${event.pointValue} points',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (Event? newValue) {
          setState(() {
            _selectedEvent = newValue;
          });
        },
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
      radius: 12,
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor, size: 12),
    );
  }
}
