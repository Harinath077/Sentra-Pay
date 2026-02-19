import 'package:flutter/material.dart';
import 'premium_styles.dart';
import 'premium_link_upi_screen.dart';

class PremiumDeviceSuccessScreen extends StatefulWidget {
  const PremiumDeviceSuccessScreen({super.key});

  @override
  State<PremiumDeviceSuccessScreen> createState() => _PremiumDeviceSuccessScreenState();
}

class _PremiumDeviceSuccessScreenState extends State<PremiumDeviceSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const PremiumLinkUPIScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumStyle.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PremiumStyle.accentColor.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: PremiumStyle.accentColor.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 64,
                    color: PremiumStyle.accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    "device secured.",
                    style: PremiumStyle.headingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This device is now trusted for\nsafe transactions.",
                    style: PremiumStyle.subHeading.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PremiumStyle.spacing, vertical: 40),
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumStyle.buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PremiumStyle.cardRadius)),
                  elevation: 0,
                ),
                child: Text(
                  "Continue",
                  style: PremiumStyle.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
