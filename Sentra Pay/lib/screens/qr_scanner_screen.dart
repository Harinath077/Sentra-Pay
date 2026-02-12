import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';
import '../models/fraud_store.dart';
import 'enhanced_risk_result_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanned = false; // Prevent multiple pops

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isScanned = true;
        });
        // Play success sound or vibe?
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // REAL Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // Scanning Frame
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner borders
                  ..._buildCorners(),
                  // Scanning Line
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: 280 * _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: const Text(
              "Scan Review QR Code",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
           // Hint Text
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: const Text(
              "Align QR code within the frame",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Manual Entry Fallback (Real World Feature)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  // Allow manual entry by popping with null, HomeScreen can handle or we can show a dialog here.
                  // Simplest: Pop with nothing, user uses the text field on home screen.
                  // Or better: Pop with a specific flag or just let user close.
                  // Actually, let's pop with a "MANUAL" signal or just let them close.
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  "Enter UPI ID Manually",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  List<Widget> _buildCorners() {
    const double size = 30;
    const double thickness = 4;
    const Color color = Colors.white; // Clean white corners

    return [
      Positioned(
        top: 0, left: 0,
        child: Container(width: size, height: thickness, color: color)),
      Positioned(
        top: 0, left: 0,
        child: Container(width: thickness, height: size, color: color)),
      Positioned(
        top: 0, right: 0,
        child: Container(width: size, height: thickness, color: color)),
      Positioned(
        top: 0, right: 0,
        child: Container(width: thickness, height: size, color: color)),
      Positioned(
        bottom: 0, left: 0,
        child: Container(width: size, height: thickness, color: color)),
      Positioned(
        bottom: 0, left: 0,
        child: Container(width: thickness, height: size, color: color)),
      Positioned(
        bottom: 0, right: 0,
        child: Container(width: size, height: thickness, color: color)),
      Positioned(
        bottom: 0, right: 0,
        child: Container(width: thickness, height: size, color: color)),
    ];
  }
}
