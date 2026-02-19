import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'premium_styles.dart';
import 'premium_otp_screen.dart';

class PremiumSignupScreen extends StatefulWidget {
  const PremiumSignupScreen({super.key});

  @override
  State<PremiumSignupScreen> createState() => _PremiumSignupScreenState();
}

class _PremiumSignupScreenState extends State<PremiumSignupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PremiumOTPScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumStyle.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: PremiumStyle.spacing),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    "create your\naccount.",
                    style: PremiumStyle.headingLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "secure your transactions with Sentra Pay.",
                    style: PremiumStyle.subHeading.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  _buildInputLabel("Full Name"),
                  _buildTextField(hint: "e.g. John Doe"),

                  const SizedBox(height: 24),

                  _buildInputLabel("Mobile Number"),
                  _buildTextField(
                    hint: "+91 00000 00000",
                    isNumber: true,
                    prefixIcon: Icons.phone_android_rounded,
                  ),

                  const SizedBox(height: 48),

                  _buildPrimaryButton(context),

                  const SizedBox(height: 24),
                  
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 12, color: PremiumStyle.secondaryText.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Text(
                          "Your data is encrypted and protected.",
                          style: PremiumStyle.subHeading.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: PremiumStyle.inputLabel),
    );
  }

  Widget _buildTextField({
    required String hint,
    bool isOptional = false,
    bool isNumber = false,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PremiumStyle.cardBackground,
        borderRadius: BorderRadius.circular(PremiumStyle.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        style: const TextStyle(color: Colors.white, fontSize: 16),
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: PremiumStyle.secondaryText.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: PremiumStyle.secondaryText) : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PremiumStyle.cardRadius),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PremiumStyle.cardRadius),
            borderSide: BorderSide(color: PremiumStyle.accentColor.withOpacity(0.5), width: 1.5),
          ),
          filled: true,
          fillColor: PremiumStyle.cardBackground,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumStyle.cardRadius),
        boxShadow: [
          BoxShadow(
            color: PremiumStyle.accentColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
          "Continue Securely",
          style: PremiumStyle.buttonText,
        ),
      ),
    );
  }
}
