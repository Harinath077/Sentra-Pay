import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';
import '../theme/app_theme.dart';
import 'onboarding/premium_signup_screen.dart';
import 'onboarding/premium_styles.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getPin() => _pinControllers.map((c) => c.text).join();

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _pinFocusNodes[index + 1].requestFocus();
      } else {
        _pinFocusNodes[index].unfocus();
      }
    } else if (index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
    setState(() {
      _errorMessage = null;
    });
  }

  Future<void> _handleSignIn() async {
    final phone = _phoneController.text.trim();
    final pin = _getPin();

    if (phone.isEmpty || phone.length < 10) {
      setState(() => _errorMessage = "Enter a valid mobile number.");
      return;
    }
    if (pin.length < 4) {
      setState(() => _errorMessage = "Enter your 4-digit PIN.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // UI-only auth — use the existing AuthProvider with phone as email
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(phone, pin);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = "Invalid credentials. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumStyle.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PremiumStyle.accentColor.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color:
                                PremiumStyle.accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        size: 32,
                        color: PremiumStyle.accentColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      "Sentra Pay",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Secure Payment Authentication",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: PremiumStyle.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Phone Number
                    Text(
                      "Mobile Number",
                      style: PremiumStyle.inputLabel,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: PremiumStyle.cardBackground,
                        borderRadius:
                            BorderRadius.circular(PremiumStyle.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: "Enter your mobile number",
                          hintStyle: TextStyle(
                              color: PremiumStyle.secondaryText
                                  .withOpacity(0.5)),
                          prefixIcon: const Icon(
                              Icons.phone_android_rounded,
                              color: PremiumStyle.secondaryText),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                PremiumStyle.cardRadius),
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                PremiumStyle.cardRadius),
                            borderSide: BorderSide(
                                color: PremiumStyle.accentColor
                                    .withOpacity(0.5),
                                width: 1.5),
                          ),
                          filled: true,
                          fillColor: PremiumStyle.cardBackground,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // PIN
                    Text(
                      "Enter PIN",
                      style: PremiumStyle.inputLabel,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          4, (i) => _buildPinBox(i)),
                    ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 36),

                    // Sign In Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(PremiumStyle.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color:
                                PremiumStyle.accentColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumStyle.buttonColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  PremiumStyle.cardRadius)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text("Sign In",
                                style: PremiumStyle.buttonText),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Biometric Option
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showBiometricDialog(context),
                        icon: Icon(Icons.fingerprint_rounded,
                            color: PremiumStyle.accentColor, size: 24),
                        label: Text(
                          "Use Biometric Login",
                          style: TextStyle(
                            color: PremiumStyle.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create Account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New to Sentra? ",
                          style: TextStyle(
                              color: PremiumStyle.secondaryText,
                              fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PremiumSignupScreen())),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                                color: PremiumStyle.accentColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinBox(int index) {
    return Container(
      width: 56,
      height: 68,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: PremiumStyle.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: _pinControllers[index].text.isNotEmpty
            ? Border.all(
                color: PremiumStyle.accentColor.withOpacity(0.5),
                width: 1.5)
            : null,
      ),
      child: Center(
        child: TextField(
          controller: _pinControllers[index],
          focusNode: _pinFocusNodes[index],
          textAlign: TextAlign.center,
          obscureText: true,
          obscuringCharacter: '●',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (val) => _onPinChanged(val, index),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
        ),
      ),
    );
  }

  void _showBiometricDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BiometricAuthDialog(),
    ).then((success) {
      if (success == true && mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }
}

class _BiometricAuthDialog extends StatefulWidget {
  @override
  State<_BiometricAuthDialog> createState() => _BiometricAuthDialogState();
}

class _BiometricAuthDialogState extends State<_BiometricAuthDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _startAuth();
  }

  void _startAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false)
          .authenticateBiometric()
          .then((_) {
        Navigator.of(context).pop(true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PremiumStyle.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Biometric Login",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text("Authenticate using Touch ID",
                style: TextStyle(
                    color: PremiumStyle.secondaryText, fontSize: 13)),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PremiumStyle.accentColor
                        .withOpacity(0.05 + (_controller.value * 0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint_rounded,
                      color: PremiumStyle.accentColor, size: 64),
                );
              },
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Use PIN Instead",
                  style: TextStyle(
                      color: PremiumStyle.secondaryText,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
