import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import '../services/attendance_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final AttendanceService _attendanceService = AttendanceService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  String _lastScannedCode = '';
  bool _isScanning = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _showSuccess = false;
    });

    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6750A4',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        // Successfully scanned a barcode
        await _attendanceService.addRecord(barcodeScanRes);
        
        // Provide feedback
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 200);
        }
        
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        
        setState(() {
          _lastScannedCode = barcodeScanRes;
          _showSuccess = true;
        });
        
        _animationController.reset();
        _animationController.forward();
      }
    } on PlatformException {
      // Handle platform exceptions
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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      Text(
                        'Roll Number: $_lastScannedCode',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
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
        ),
      ),
    );
  }
}
