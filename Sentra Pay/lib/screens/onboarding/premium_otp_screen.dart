import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'premium_styles.dart';
import 'premium_device_success_screen.dart';

class PremiumOTPScreen extends StatefulWidget {
  const PremiumOTPScreen({super.key});

  @override
  State<PremiumOTPScreen> createState() => _PremiumOTPScreenState();
}

class _PremiumOTPScreenState extends State<PremiumOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isFilled = false;

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        setState(() {
          _isFilled = true;
        });
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {
        _isFilled = false;
      });
    }
  }

  void _onVerify() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const PremiumDeviceSuccessScreen(),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PremiumStyle.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Text(
                "verify your\nnumber.",
                style: PremiumStyle.headingLarge,
              ),
              const SizedBox(height: 12),
              Text(
                "We’ve sent a 6-digit code to +91 98XXX XXXXX",
                style: PremiumStyle.subHeading.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 60),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOTPBox(index)),
              ),

              const SizedBox(height: 48),

              Text(
                "Didn't receive code? Resend in 20s",
                textAlign: TextAlign.center,
                style: PremiumStyle.subHeading.copyWith(color: PremiumStyle.secondaryText.withOpacity(0.6)),
              ),

              const Spacer(),

              _buildVerifyButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(
        color: PremiumStyle.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: _controllers[index].text.isNotEmpty 
          ? Border.all(color: PremiumStyle.accentColor.withOpacity(0.5), width: 1.5)
          : null,
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (val) => _onChanged(val, index),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumStyle.cardRadius),
        boxShadow: _isFilled ? [
          BoxShadow(
            color: PremiumStyle.accentColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ] : [],
      ),
      child: ElevatedButton(
        onPressed: _isFilled ? _onVerify : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: PremiumStyle.buttonColor,
          disabledBackgroundColor: PremiumStyle.cardBackground,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PremiumStyle.cardRadius)),
          elevation: 0,
        ),
        child: Text(
          "Verify & Continue",
          style: PremiumStyle.buttonText.copyWith(
            color: _isFilled ? Colors.white : PremiumStyle.secondaryText,
          ),
        ),
      ),
    );
  }
}
