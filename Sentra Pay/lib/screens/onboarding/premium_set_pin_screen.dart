import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'premium_styles.dart';
import 'premium_device_success_screen.dart';

class PremiumSetPinScreen extends StatefulWidget {
  const PremiumSetPinScreen({super.key});

  @override
  State<PremiumSetPinScreen> createState() => _PremiumSetPinScreenState();
}

class _PremiumSetPinScreenState extends State<PremiumSetPinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  final List<TextEditingController> _confirmControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _confirmFocusNodes =
      List.generate(4, (_) => FocusNode());

  bool _pinSet = false;
  bool _pinsMatch = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var c in _pinControllers) {
      c.dispose();
    }
    for (var f in _pinFocusNodes) {
      f.dispose();
    }
    for (var c in _confirmControllers) {
      c.dispose();
    }
    for (var f in _confirmFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getPin() => _pinControllers.map((c) => c.text).join();
  String _getConfirmPin() => _confirmControllers.map((c) => c.text).join();

  void _onPinChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _pinFocusNodes[index + 1].requestFocus();
      } else {
        _pinFocusNodes[index].unfocus();
        setState(() {
          _pinSet = _getPin().length == 4;
        });
      }
    } else if (index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
    setState(() {
      _errorText = null;
    });
  }

  void _onConfirmChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _confirmFocusNodes[index + 1].requestFocus();
      } else {
        _confirmFocusNodes[index].unfocus();
        _checkMatch();
      }
    } else if (index > 0) {
      _confirmFocusNodes[index - 1].requestFocus();
    }
    setState(() {
      _errorText = null;
    });
  }

  void _checkMatch() {
    final pin = _getPin();
    final confirm = _getConfirmPin();
    if (pin.length == 4 && confirm.length == 4) {
      if (pin == confirm) {
        setState(() {
          _pinsMatch = true;
          _errorText = null;
        });
      } else {
        setState(() {
          _pinsMatch = false;
          _errorText = "PINs don't match. Try again.";
        });
      }
    }
  }

  void _onContinue() {
    if (_pinsMatch) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PremiumDeviceSuccessScreen(),
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
            padding:
                const EdgeInsets.symmetric(horizontal: PremiumStyle.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Text(
                  "set your\nPIN.",
                  style: PremiumStyle.headingLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  "create a 4-digit PIN for secure login.",
                  style: PremiumStyle.subHeading.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Enter PIN
                Text("Enter PIN",
                    style: PremiumStyle.inputLabel
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      4, (i) => _buildPinBox(_pinControllers[i], _pinFocusNodes[i], i, false)),
                ),

                const SizedBox(height: 32),

                // Confirm PIN
                Text("Confirm PIN",
                    style: PremiumStyle.inputLabel
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      4,
                      (i) => _buildPinBox(
                          _confirmControllers[i], _confirmFocusNodes[i], i, true)),
                ),

                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],

                if (_pinsMatch) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          color: PremiumStyle.accentColor, size: 16),
                      SizedBox(width: 6),
                      Text("PINs match",
                          style: TextStyle(
                              color: PremiumStyle.accentColor, fontSize: 13)),
                    ],
                  ),
                ],

                const SizedBox(height: 48),

                // Continue Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(PremiumStyle.cardRadius),
                    boxShadow: _pinsMatch
                        ? [
                            BoxShadow(
                              color:
                                  PremiumStyle.accentColor.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: _pinsMatch ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumStyle.buttonColor,
                      disabledBackgroundColor: PremiumStyle.cardBackground,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              PremiumStyle.cardRadius)),
                      elevation: 0,
                    ),
                    child: Text(
                      "Set PIN & Continue",
                      style: PremiumStyle.buttonText.copyWith(
                        color: _pinsMatch
                            ? Colors.white
                            : PremiumStyle.secondaryText,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 12,
                          color:
                              PremiumStyle.secondaryText.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        "Your PIN is stored securely on this device.",
                        style:
                            PremiumStyle.subHeading.copyWith(fontSize: 11),
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
    );
  }

  Widget _buildPinBox(TextEditingController controller, FocusNode focusNode,
      int index, bool isConfirm) {
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
        border: controller.text.isNotEmpty
            ? Border.all(
                color: PremiumStyle.accentColor.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          obscureText: true,
          obscuringCharacter: '●',
          style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (val) => isConfirm
              ? _onConfirmChanged(val, index)
              : _onPinChanged(val, index),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: "",
          ),
        ),
      ),
    );
  }
}
