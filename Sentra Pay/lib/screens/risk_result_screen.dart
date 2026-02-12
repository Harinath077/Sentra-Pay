import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/risk_gauge.dart';
import 'payment_success_screen.dart';
import '../models/fraud_store.dart';

class RiskResultScreen extends StatefulWidget {
  final double amount;
  final String recipient;

  const RiskResultScreen({
    super.key,
    required this.amount,
    required this.recipient,
  });

  @override
  State<RiskResultScreen> createState() => _RiskResultScreenState();
}

class _RiskResultScreenState extends State<RiskResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Risk Data
  double _riskScore = 0.0;
  List<String> _riskFactors = [];
  bool _isSafe = true;
  RiskCategory _riskCategory = RiskCategory.low;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    
    _checkRisk();
  }

  void _checkRisk() {
    // Call the central Fraud Simulation Logic
    final result = FraudStore.analyzeRisk(widget.recipient, widget.amount);
    
    setState(() {
      _riskScore = result.score;
      _riskFactors = result.factors;
      _isSafe = !result.isBlocked && result.category != RiskCategory.high;
      _riskCategory = result.category;
    });
  }

  void _reportFraud() {
    FraudStore.report(widget.recipient);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(" Reported ${widget.recipient} as fraud"),
        backgroundColor: AppTheme.errorColor,
      ),
    );
    // Refresh state to show blocked status immediately
    _checkRisk();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Risk Analysis",
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
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
                       "Simulated Risk Analysis based on sender behavior & receiver history.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("DEMO MODE ENABLED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Factors Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
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
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._riskFactors.map((factor) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (_isSafe ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isSafe ? Icons.check_rounded : Icons.priority_high_rounded,
                                    size: 14,
                                    color: _isSafe ? AppTheme.successColor : AppTheme.errorColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  factor,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isSafe || FraudStore.isReported(widget.recipient)) 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomButton(
                          text: "Report as Fraud",
                           isPrimary: false,
                           isSecondary: true,
                           color: Colors.transparent, // Outline style
                           icon: Icons.flag_outlined,
                           onPressed: _reportFraud,
                        ),
                      ),
                    
                    if (!FraudStore.isReported(widget.recipient))
                      CustomButton(
                        text: _isSafe ? "Pay via GPay" : "Proceed Anyway",
                        isPrimary: true,
                        color: _isSafe ? null : AppTheme.errorColor, // Red if risky
                        onPressed: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => PaymentSuccessScreen(
                                 amount: widget.amount, 
                                 recipient: widget.recipient
                               ),
                             ),
                           );
                        },
                      )
                    else 
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Payment Blocked for Safety",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.bold,
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
    );
  }
  Color _getRiskColor() {
    switch (_riskCategory) {
      case RiskCategory.low: return AppTheme.successColor;
      case RiskCategory.medium: return Colors.orange;
      case RiskCategory.high: return AppTheme.errorColor;
    }
  }

  String _getRiskTitle() {
    switch (_riskCategory) {
      case RiskCategory.low: return "Low Risk Detected";
      case RiskCategory.medium: return "Moderate Risk Warning";
      case RiskCategory.high: return "High Risk Alert";
    }
  }
}
