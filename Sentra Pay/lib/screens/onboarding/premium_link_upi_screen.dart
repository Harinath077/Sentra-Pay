import 'package:flutter/material.dart';
import 'premium_styles.dart';
import '../home_screen.dart';

class PremiumLinkUPIScreen extends StatefulWidget {
  const PremiumLinkUPIScreen({super.key});

  @override
  State<PremiumLinkUPIScreen> createState() => _PremiumLinkUPIScreenState();
}

class _PremiumLinkUPIScreenState extends State<PremiumLinkUPIScreen> {
  final TextEditingController _upiController = TextEditingController();
  bool _isValid = false;
  String? _validationMessage;

  void _validateUPI(String value) {
    if (value.contains('@') && value.length > 5) {
      setState(() {
        _isValid = true;
        _validationMessage = "UPI format looks valid";
      });
    } else {
      setState(() {
        _isValid = false;
        _validationMessage = null; // Don't show error, just hide success
      });
    }
  }

  void _onActivate() {
    // Navigate to Home Screen and clear stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumStyle.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PremiumStyle.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Text(
                "link your\nUPI.",
                style: PremiumStyle.headingLarge,
              ),
              const SizedBox(height: 12),
              Text(
                "connect your UPI ID to activate\nfraud monitoring.",
                style: PremiumStyle.subHeading.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 60),

              TextField(
                controller: _upiController,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                onChanged: _validateUPI,
                decoration: InputDecoration(
                  hintText: "user@bank",
                  hintStyle: TextStyle(color: PremiumStyle.secondaryText.withOpacity(0.3), fontSize: 24, fontWeight: FontWeight.bold),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: PremiumStyle.inputBorder)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: PremiumStyle.inputBorder)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: PremiumStyle.accentColor)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: _isValid 
                    ? const Icon(Icons.check_circle_rounded, color: PremiumStyle.accentColor) 
                    : null,
                ),
              ),

              const SizedBox(height: 12),

              if (_validationMessage != null)
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: PremiumStyle.accentColor),
                    const SizedBox(width: 6),
                    Text(
                      _validationMessage!,
                      style: const TextStyle(color: PremiumStyle.accentColor, fontSize: 12),
                    ),
                  ],
                ),

              const Spacer(),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PremiumStyle.cardRadius),
                  boxShadow: _isValid ? [
                    BoxShadow(
                      color: PremiumStyle.accentColor.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ] : [],
                ),
                child: ElevatedButton(
                  onPressed: _isValid ? _onActivate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumStyle.buttonColor,
                    disabledBackgroundColor: PremiumStyle.cardBackground,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PremiumStyle.cardRadius)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Activate Protection",
                    style: PremiumStyle.buttonText.copyWith(
                      color: _isValid ? Colors.white : PremiumStyle.secondaryText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
