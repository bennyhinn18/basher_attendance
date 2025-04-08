import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendance_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isDarkMode = false;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  bool _isClearing = false;
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Keys for SharedPreferences
  static const String _darkModeKey = 'darkMode';
  static const String _vibrationKey = 'vibration';
  static const String _soundKey = 'sound';

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = _prefs.getBool(_darkModeKey) ?? false;
      _vibrationEnabled = _prefs.getBool(_vibrationKey) ?? true;
      _soundEnabled = _prefs.getBool(_soundKey) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await _saveSetting(_darkModeKey, value);
    
    // Notify the app to change theme
    // This implementation depends on how you're managing theme in your app
    // If using a state management solution like Provider:
    // Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
  }

  Future<void> _toggleVibration(bool value) async {
    setState(() {
      _vibrationEnabled = value;
    });
    await _saveSetting(_vibrationKey, value);
  }

  Future<void> _toggleSound(bool value) async {
    setState(() {
      _soundEnabled = value;
    });
    await _saveSetting(_soundKey, value);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all attendance records? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isClearing = true;
      });

      await _attendanceService.clearAllRecords();

      setState(() {
        _isClearing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All attendance records have been cleared'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Attendance Tracker v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Attendance Tracker',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 Your Organization',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'A barcode scanning attendance system for community events.',
                  ),
                ],
              );
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            secondary: const Icon(Icons.dark_mode),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate on successful scan'),
            secondary: const Icon(Icons.vibration),
            value: _vibrationEnabled,
            onChanged: _toggleVibration,
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound on successful scan'),
            secondary: const Icon(Icons.volume_up),
            value: _soundEnabled,
            onChanged: _toggleSound,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export All Data'),
            subtitle: const Text('Export all attendance records as CSV'),
            onTap: () async {
              final records = _attendanceService.getAllRecords();
              final path = await _attendanceService.exportToCSV(records);
              await _attendanceService.shareCSV(path);
            },
          ),
          ListTile(
            leading: _isClearing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Remove all attendance records'),
            onTap: _isClearing ? null : _clearAllData,
          ),
        ],
      ),
    );
  }
}
