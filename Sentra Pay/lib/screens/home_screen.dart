import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/custom_button.dart';
import 'enhanced_risk_result_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'settings_screen.dart';

import 'analytics_screen.dart';
import '../models/fraud_store.dart';
import '../models/auth_provider.dart';
import '../models/settings_provider.dart';
import '../services/micro_tips.dart';
import '../services/api_service.dart';
import '../models/receiver_info.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  
  // State for Recipient Verification
  bool _isChecking = false;
  bool _isVerified = false;
  ReceiverInfo? _receiverInfo;
  
  // State for Payment Processing
  bool _isProcessing = false;
  
  // State for Micro-Tips
  bool _showMicroTip = true;
  String _currentTip = '';
  
  @override
  void initState() {
    super.initState();
    // Get a random tip from MicroTips service
    _currentTip = MicroTips.getRandomTip();
    
    // Polite Location Request (Non-blocking)
    _requestLocationPermission();

    // Auto-hide micro-tip after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showMicroTip = false;
        });
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Just cache/ensure access. 
        // We don't block the UI waiting for the exact fix here.
        Geolocator.getCurrentPosition().then((pos) {
             print("Location Access Granted: ${pos.latitude}, ${pos.longitude}");
        }).catchError((e) {
             print("Location error: $e");
        });
      }
    } catch (e) {
      print("Location permission check failed: $e");
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void _checkRecipient() async {
    if (_recipientController.text.isEmpty) return;

    setState(() {
      _isChecking = true;
      _isVerified = false;
      _receiverInfo = null;
    });

    // Call Backend Validation API
    final receiverInfo = await ApiService.validateReceiver(_recipientController.text);

    if (mounted) {
      if (receiverInfo != null && receiverInfo.name != "Unknown Receiver") {
        setState(() {
          _isChecking = false;
          _isVerified = true;
          _receiverInfo = receiverInfo;
        });
      } else {
          // Unknown or invalid
          setState(() {
          _isChecking = false;
          _isVerified = true; // Allow proceeding as unknown (but trigger warning in risk analysis later)
          _receiverInfo = ReceiverInfo(
            upiId: _recipientController.text,
            name: "Unknown Receiver",
            verified: false,
          );
        });
      }
    }
  }

  Future<void> _handlePayment() async {
    if (_amountController.text.isEmpty || !_isVerified) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount and verify recipient')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final recipientId = _recipientController.text;

      // CALL BACKEND MODELLING
      final riskResult = await FraudStore.analyzeRiskAsync(
        recipientId,
        amount,
        user: authProvider.currentUser,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Save transaction to history
        FraudStore.addTransaction(
          receiver: recipientId,
          amount: amount,
          risk: riskResult.category == RiskCategory.high 
              ? 'high' 
              : (riskResult.category == RiskCategory.medium ? 'medium' : 'low'),
          timestamp: DateTime.now(),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedRiskResultScreen(
              amount: amount,
              recipient: _receiverInfo?.name ?? "Unknown",
              riskResult: riskResult, // Pass the backend result
              transactionId: riskResult.transactionId, // Pass transaction ID for confirmation
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).colorScheme.surface;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: "Profile",
          ),
        ),
        title: Column(
          children: [
            Text(
              "Sentra Pay",
              style: TextStyle(
                fontFamily: 'Outfit', 
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_moon_rounded, size: 12, color: AppTheme.successColor),
                SizedBox(width: 4),
                Text(
                  "Secure UPI Payment",
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: "Settings",
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            tooltip: "Toggle Theme",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Micro-Tip Widget
                  if (_showMicroTip)
                    AnimatedOpacity(
                      opacity: _showMicroTip ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF1E40AF).withOpacity(0.1)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFF60A5FA).withOpacity(0.2)
                                : const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: isDark 
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _currentTip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark 
                                      ? AppTheme.darkTextPrimary
                                      : const Color(0xFF065F46),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.close,
                                size: 16,
                                color: isDark 
                                    ? AppTheme.darkTextSecondary
                                    : const Color(0xFF059669).withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showMicroTip = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Professional Transaction Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCardColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Color(0xFF10B981), // Solid emerald green
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "SECURE TRANSACTION",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "Enter Amount",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "₹",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w400,
                                color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E1B4B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: IntrinsicWidth(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E1B4B),
                                    letterSpacing: -1.0,
                                    height: 1.0,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: "0.00",
                                    hintStyle: TextStyle(
                                      color: isDark 
                                          ? Colors.white10 
                                          : Colors.grey.shade200,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // 2. Recipient Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark 
                            ? AppTheme.darkBorderColor
                            : AppTheme.borderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.5 : 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4), 
                    child: Column(
                      children: [
                        TextField(
                          controller: _recipientController,
                          onChanged: (val) {
                            if (_isVerified) {
                              setState(() {
                                _isVerified = false;
                                _receiverInfo = null;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Enter UPI ID or Number",
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _isChecking 
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20, 
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                  )
                                : _isVerified
                                  ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                                  : TextButton(
                                      onPressed: _checkRecipient,
                                      style: TextButton.styleFrom(
                                        foregroundColor: isDark 
                                            ? const Color(0xFF60A5FA) // Lighter blue for dark mode
                                            : AppTheme.primaryColor,
                                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      child: const Text("Check"),
                                    ),
                            ),
                          ),
                        ),
                        if (_isVerified) ...[
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (_receiverInfo?.verified ?? false) 
                                    ? AppTheme.successColor.withOpacity(0.1) 
                                    : Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                (_receiverInfo?.verified ?? false) ? Icons.verified_user_rounded : Icons.help_outline_rounded,
                                color: (_receiverInfo?.verified ?? false) ? AppTheme.successColor : Colors.orange,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              _receiverInfo?.name ?? "Unknown",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_receiverInfo?.bank != null)
                                  Text(
                                    _receiverInfo!.bank!,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      (_receiverInfo?.verified ?? false) ? Icons.check_circle : Icons.warning_rounded,
                                      size: 12,
                                      color: (_receiverInfo?.verified ?? false) ? AppTheme.successColor : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (_receiverInfo?.verified ?? false) ? "Verified Details" : "Not Verified",
                                      style: TextStyle(
                                        color: (_receiverInfo?.verified ?? false) ? AppTheme.successColor : Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Quick Feature Access
                  Text(
                    "QUICK ACCESS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildFeatureButton(
                              context: context,
                              icon: Icons.history_rounded,
                              label: "History",
                              isLocked: !settings.historyFeatureUnlocked,
                              onTap: () {
                                if (settings.historyFeatureUnlocked) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                                  );
                                } else {
                                  _showFeatureLockedMessage(context, "History");
                                }
                              },
                              isDark: isDark,
                              cardColor: cardColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFeatureButton(
                              context: context,
                              icon: Icons.analytics_rounded,
                              label: "Analytics",
                              isLocked: !settings.advancedAnalyticsUnlocked,
                              onTap: () {
                                if (settings.advancedAnalyticsUnlocked) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                                  );
                                } else {
                                  _showFeatureLockedMessage(context, "Analytics");
                                }
                              },
                              isDark: isDark,
                              cardColor: cardColor,
                            ),
                          ),

                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // 5. Sticky Bottom Action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shield_outlined, size: 14, color: AppTheme.successColor),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "All risk analysis happens on-device • No data shared",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "Scan",
                          icon: Icons.qr_code_scanner_rounded,
                          isPrimary: false,
                          isSecondary: true,
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                            );
                            if (result != null && result is String) {
                              String? vpa;
                              // 1. Try parsing UPI URI
                              if (result.startsWith("upi://")) {
                                try {
                                  final uri = Uri.parse(result);
                                  vpa = uri.queryParameters['pa'];
                                } catch (e) {
                                  // Invalid URI
                                }
                              } 
                              // 2. Try raw VPA (Simple Regex)
                              else if (RegExp(r'^[a-zA-Z0-9.\-_]+@[a-zA-Z0-9.\-_]+$').hasMatch(result)) {
                                vpa = result;
                              }

                              if (vpa != null) {
                                setState(() {
                                  _recipientController.text = vpa!;
                                });
                                _checkRecipient();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🚫 Invalid QR Code. Please scan a valid UPI QR."),
                                    backgroundColor: Color(0xFFEF4444),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: _isProcessing ? "Processing..." : "Pay Now",
                          isLoading: _isProcessing,
                          isPrimary: true,
                          onPressed: _handlePayment,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isLocked,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Stack(
                  children: [
                    Icon(
                      icon,
                      color: isLocked
                          ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                          : AppTheme.primaryColor,
                      size: 28,
                    ),
                    if (isLocked)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 12,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isLocked
                        ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFeatureLockedMessage(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Unlock $featureName in Settings to access this feature'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showReportFraudDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Report Fraud",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Help us keep the community safe by reporting suspicious UPI IDs or phone numbers.",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: "Enter UPI ID or Phone Number",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe the fraudulent activity...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted. Thank you for keeping us safe!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );
  }
}
