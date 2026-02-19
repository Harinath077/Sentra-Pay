import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/google_sign_in_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage ?? "Google Sign-In failed.";
      });
    }
  }
    @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Professional Header
                    const Icon(
                      Icons.account_balance_rounded,
                      size: 48,
                      color: Color(0xFF1E1B4B), // Deep Indigo
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Sentra Pay",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E1B4B),
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
                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Input Group
                    Text(
                      "Email or Mobile Number",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black),
                      decoration: InputDecoration(
                        hintText: "Enter your registered id",
                        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF111111) : const Color(0xFFF1F5F9),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : Colors.black),
                      decoration: InputDecoration(
                        hintText: "••••••••",
                        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF111111) : const Color(0xFFF1F5F9),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Main Action Row
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E1B4B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Biometric Button
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF4F46E5), size: 28),
                            onPressed: () => _showBiometricDialog(context),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // OR Separator
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("OR", style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign-In Button (Official Style)
                    GoogleSignInButton(
                      onPressed: _handleGoogleSignIn,
                      isLoading: _isLoading,
                    ),
                      const SizedBox(height: 32),

                    // Footer Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New to Sentra? ",
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
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

  void _showBiometricDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BiometricAuthDialog(),
    ).then((success) {
      if (success == true && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }
}

class _BiometricAuthDialog extends StatefulWidget {
  @override
  State<_BiometricAuthDialog> createState() => _BiometricAuthDialogState();
}

class _BiometricAuthDialogState extends State<_BiometricAuthDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _startAuth();
  }

  void _startAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Provider.of<AuthProvider>(context, listen: false).authenticateBiometric().then((_) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Biometric Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Authenticate using Touch ID", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.05 + (_controller.value * 0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.indigo, size: 64),
                );
              },
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Use Password Instead", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
