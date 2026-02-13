import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/risk_gauge.dart';
import '../widgets/risk_factor_breakdown.dart';
import '../widgets/community_alert.dart';
import 'payment_success_screen.dart';
import '../models/fraud_store.dart';
import '../models/transaction_history.dart';
import '../models/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/micro_tips.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class EnhancedRiskResultScreen extends StatefulWidget {
  final double amount;
  final String recipient;
  final RiskAnalysisResult? riskResult; // Added optional result
  final String? transactionId; // Transaction ID from backend

  const EnhancedRiskResultScreen({
    super.key,
    required this.amount,
    required this.recipient,
    this.riskResult, // Pass from HomeScreen after async call
    this.transactionId, // For payment confirmation
  });

  @override
  State<EnhancedRiskResultScreen> createState() => _EnhancedRiskResultScreenState();
}

class _EnhancedRiskResultScreenState extends State<EnhancedRiskResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Risk Data
  double _riskScore = 0.0;
  List<String> _riskFactors = [];
  bool _isSafe = true;
  bool _isUserReported = false;
  RiskCategory _riskCategory = RiskCategory.low;
  double _behaviorScore = 0.0;
  double _amountScore = 0.0;
  double _receiverScore = 0.0;
  bool _isLocalAnalysis = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _checkRisk();
  }

  void _checkRisk() {
    RiskAnalysisResult result;
    
    if (widget.riskResult != null) {
      result = widget.riskResult!;
      _isLocalAnalysis = false;
    } else {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      result = FraudStore.analyzeRisk(widget.recipient, widget.amount, user: user);
      _isLocalAnalysis = true;
    }

    setState(() {
      _riskScore = result.score;
      _riskFactors = result.factors;
      _isSafe = !result.isBlocked && result.category != RiskCategory.high;
      _riskCategory = result.category;
      _behaviorScore = result.behaviorScore;
      _amountScore = result.amountScore;
    });


  }

  void _reportFraud() {
    setState(() {
      _isUserReported = true;
      _isSafe = false;
    });
    FraudStore.report(widget.recipient);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✓ Reported ${widget.recipient} as fraud"),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _handleSimulatedPayment(Map<String, dynamic> result) {
    // Handle simulated payment result (for desktop/web)
    if (result['status'] == 'success') {
      // Payment successful! Navigate to success screen
      if (mounted) {
        // Log successful transaction
        TransactionHistory.addTransaction(
          Transaction(
            id: widget.transactionId ?? "TXN-${DateTime.now().millisecondsSinceEpoch}",
            recipient: widget.recipient,
            amount: widget.amount,
            riskScore: _riskScore,
            riskCategory: _riskCategory.toString().split('.').last,
            timestamp: DateTime.now(),
            wasBlocked: false,
          ),
        );

        FraudStore.addTransaction(
          receiver: widget.recipient,
          amount: widget.amount,
          risk: _riskCategory == RiskCategory.high 
              ? 'high' 
              : (_riskCategory == RiskCategory.medium ? 'medium' : 'low'),
          timestamp: DateTime.now(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              amount: widget.amount,
              recipient: widget.recipient,
              utrNumber: result['utr_number'],
              pspName: result['psp_name'],
              transactionId: widget.transactionId,
            ),
          ),
        );
      }
    } else {
      // Payment failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result['message']}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Color _getRiskColor() {
    if (_isUserReported || !_isSafe) return AppTheme.errorColor;
    
    // If backend provided a color, use it
    if (widget.riskResult?.color != null) {
      try {
        final colorStr = widget.riskResult!.color!.replaceFirst('#', '0xFF');
        return Color(int.parse(colorStr));
      } catch (e) {
        print("Error parsing backend color: $e");
      }
    }

    if (_riskScore < 0.4) return AppTheme.successColor;
    if (_riskScore < 0.7) return Colors.orange;
    return AppTheme.errorColor;
  }

  String _getRiskTitle() {
    if (_isUserReported || !_isSafe) return "Fraud Detected";
    
    // If backend provided a label, use it
    if (widget.riskResult?.label != null) {
      return widget.riskResult!.label!;
    }

    switch (_riskCategory) {
      case RiskCategory.low:
        return "Low Risk Detected";
      case RiskCategory.medium:
        return "Moderate Risk Warning";
      case RiskCategory.high:
        return "High Risk Alert";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryColor = isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Risk Analysis",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Gauge Section
                    RiskGauge(score: _riskScore),

                    const SizedBox(height: 30),

                    // Headline
                    Text(
                      _getRiskTitle(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "AI-powered fraud detection analysis",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Behavioral Profile Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_isLocalAnalysis ? Colors.blue : const Color(0xFF4F46E5)).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (_isLocalAnalysis ? Colors.blue : const Color(0xFF4F46E5)).withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isLocalAnalysis ? Icons.security_rounded : Icons.psychology_rounded, 
                            size: 16, 
                            color: _isLocalAnalysis ? Colors.blue : const Color(0xFF4F46E5)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLocalAnalysis ? "Secure Local Verification" : "AI Multi-Layer Analysis",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isLocalAnalysis ? Colors.blue : const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Community Alert
                    CommunityAlertWidget(recipientId: widget.recipient),

                    const SizedBox(height: 16),

                    // Risk Factor Breakdown (NEW!)
                    RiskFactorBreakdown(
                      behaviorScore: _behaviorScore,
                      amountScore: _amountScore,
                      receiverScore: _receiverScore,
                    ),

                    const SizedBox(height: 16),

                    // Factors Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ANALYSIS FACTORS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._riskFactors.map(
                            (factor) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (_isSafe
                                              ? AppTheme.successColor
                                              : AppTheme.errorColor)
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isSafe
                                          ? Icons.check_rounded
                                          : Icons.priority_high_rounded,
                                      size: 14,
                                      color: _isSafe
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      factor,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Micro-Tip Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4F46E5).withOpacity(0.05),
                            const Color(0xFF7C3AED).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFF4F46E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              MicroTips.getContextualTip(_riskScore),
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Report button for medium/high risk
                    if (_riskCategory != RiskCategory.low)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomButton(
                          text: "Report as Fraud",
                          isPrimary: false,
                          isSecondary: true,
                          color: Colors.transparent,
                          icon: Icons.flag_outlined,
                          onPressed: _reportFraud,
                        ),
                      ),
                    
                    // High risk OR User Reported = BLOCKED
                    if (_riskCategory == RiskCategory.high || _isUserReported)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.errorColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: AppTheme.errorColor,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Transaction Blocked for Safety",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Multiple risk factors detected. Please verify the recipient before attempting payment.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    
                    
                    // Low/Medium risk = Show button
                    else
                      Column(
                        children: [
                          // Warning message for MEDIUM risk
                          if (_riskCategory == RiskCategory.medium)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF9800).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: const Color(0xFFFF9800),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "We suggest you verify the account before proceeding with this transaction.",
                                      style: TextStyle(
                                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1F2937),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Payment button
                          CustomButton(
                            text: _riskCategory == RiskCategory.low 
                                ? "Pay Now" 
                                : "Pay Anyway", // Medium risk
                            isPrimary: true,
                            color: _riskCategory == RiskCategory.low 
                                ? null // Default green
                                : const Color(0xFFFF9800), // Amber warning for medium
                            onPressed: () async {
                              // Check if we have transaction ID from backend
                              if (widget.transactionId != null) {
                                // Get auth token
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final token = authProvider.token ?? "demo-token";
                                
                                // Show loading dialog
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Processing Payment...',
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                                
                                // Call payment confirmation API
                                final result = await ApiService.confirmPayment(
                                  transactionId: widget.transactionId!,
                                  token: token,
                                  userAcknowledged: true,
                                );
                                
                                // Close loading dialog
                                if (mounted) Navigator.pop(context);
                                
                                if (result != null) {
                                  // Check if we're on mobile and have a UPI link
                                  final upiLink = result['upi_link'];
                                  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
                                  
                                  if (isMobile && upiLink != null && upiLink.isNotEmpty) {
                                    // MOBILE: Launch real UPI app
                                    print('🚀 Launching UPI app: $upiLink');
                                    
                                    try {
                                      final uri = Uri.parse(upiLink);
                                      final canLaunch = await canLaunchUrl(uri);
                                      
                                      if (canLaunch) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        
                                        // Show message that user should complete payment in PSP app
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Complete payment in your UPI app'),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                        
                                        // In real app, you'd wait for callback from PSP app
                                        // For now, navigate to success screen after delay
                                        await Future.delayed(const Duration(seconds: 3));
                                        
                                        if (result['status'] == 'success' && mounted) {
                                          // Log successful transaction
                                          TransactionHistory.addTransaction(
                                            Transaction(
                                              id: widget.transactionId ?? "TXN-${DateTime.now().millisecondsSinceEpoch}",
                                              recipient: widget.recipient,
                                              amount: widget.amount,
                                              riskScore: _riskScore,
                                              riskCategory: _riskCategory.toString().split('.').last,
                                              timestamp: DateTime.now(),
                                              wasBlocked: false,
                                            ),
                                          );

                                          FraudStore.addTransaction(
                                            receiver: widget.recipient,
                                            amount: widget.amount,
                                            risk: _riskCategory == RiskCategory.high 
                                                ? 'high' 
                                                : (_riskCategory == RiskCategory.medium ? 'medium' : 'low'),
                                            timestamp: DateTime.now(),
                                          );
                                          
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PaymentSuccessScreen(
                                                amount: widget.amount,
                                                recipient: widget.recipient,
                                                utrNumber: result['utr_number'],
                                                pspName: result['psp_name'],
                                                transactionId: widget.transactionId,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        print('❌ Cannot launch UPI link');
                                        // Fallback to simulated payment
                                        _handleSimulatedPayment(result);
                                      }
                                    } catch (e) {
                                      print('Error launching UPI: $e');
                                      _handleSimulatedPayment(result);
                                    }
                                  } else {
                                    // DESKTOP/WEB: Use simulated payment flow
                                    print('💻 Desktop/Web mode - simulated payment');
                                    _handleSimulatedPayment(result);
                                  }
                                } else {
                                  // API call failed
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to process payment. Please try again.'),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                // Fallback: No transaction ID (local mode)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentSuccessScreen(
                                      amount: widget.amount,
                                      recipient: widget.recipient,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    
                    

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
