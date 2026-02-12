import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/risk_gauge.dart';
import '../models/risk_data.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late RiskData _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Randomly decide if risky or not for demo
    final isRisky = Random().nextBool();
    _data = RiskData.mock(isRisky);
    
    // Simulate analyzing animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   const SizedBox(height: 20),
                  RiskGauge(score: _data.score),
                  const SizedBox(height: 40),
                  
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Report',
                          style: AppTheme.lightTheme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ..._data.explanations.map((reason) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    _data.score > 0.7 
                                      ? Icons.warning_amber_rounded 
                                      : Icons.check_circle_outline,
                                    color: _data.score > 0.7 
                                      ? AppTheme.warningColor 
                                      : AppTheme.secondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (_data.status == 'Approved')
                    CustomButton(
                      text: 'Pay via UPI',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Redirecting to Payment Gateway...')),
                        );
                      },
                    )
                  else
                    Column(
                      children: [
                        CustomButton(
                          text: 'Block Transaction',
                          color: AppTheme.errorColor,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'I trust this receiver',
                          isSecondary: true,
                          onPressed: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked as trusted. Proceeding...')),
                            );
                          },
                        ),
                      ],
                    ),
                    
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
    );
  }
}
