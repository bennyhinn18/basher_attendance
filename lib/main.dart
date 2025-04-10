import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'models/attendance_record.dart';
import 'services/supabase_service.dart';
import 'screens/events/events_screen.dart';
import 'screens/leaderboard_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(AttendanceRecordAdapter());
  await Hive.openBox<AttendanceRecord>('attendance_records');
  
  // Initialize Supabase
  await SupabaseService.initialize(
    'https://isumphrxbmmdrupzjpth.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlzdW1waHJ4Ym1tZHJ1cHpqcHRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1NzE0NzQsImV4cCI6MjA0NjE0NzQ3NH0.qEmiCWO20wv03hjdxfq9wSLUPBfJ-4UvdCUOweUPyz4',
  );
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      routes: {
        '/events': (context) => const EventsScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
      },
    );
  }
}
