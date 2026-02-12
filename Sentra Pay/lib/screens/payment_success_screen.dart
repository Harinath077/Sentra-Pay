import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String recipient;
  final String? utrNumber;
  final String? pspName;
  final String? transactionId;
  
  const PaymentSuccessScreen({
    super.key, 
    required this.amount, 
    required this.recipient,
    this.utrNumber,
    this.pspName,
    this.transactionId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with TickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _checkController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _checkAnimation = CurvedAnimation(parent: _checkController, curve: Curves.elasticOut);
    
    _fadeController = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 600)
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Sequence
    _checkController.forward().then((_) => _fadeController.forward());
  }
  
  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Checkmark
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3310B981),
                        blurRadius: 20,
                        spreadRadius: 8,
                      )
                    ]
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                ),
              ),
              
              const SizedBox(height: 32),
              
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      "Payment Successful",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Paid to ${widget.recipient}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Text(
                      "₹${widget.amount.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Transaction Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          if (widget.transactionId != null)
                            _buildDetailRow("Transaction ID", widget.transactionId!),
                          if (widget.utrNumber != null) ...[
                            Divider(height: 24, color: AppTheme.borderColor.withOpacity(0.5)),
                            _buildDetailRow("UTR Number", widget.utrNumber!),
                          ],
                          if (widget.pspName != null) ...[
                            Divider(height: 24, color: AppTheme.borderColor.withOpacity(0.5)),
                            _buildDetailRow("Paid via", widget.pspName!),
                          ],
                          Divider(height: 24, color: AppTheme.borderColor.withOpacity(0.5)),
                          _buildDetailRow("Date", _formatDate(DateTime.now())),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    CustomButton(
                      text: "Done",
                      isPrimary: true,
                      onPressed: () {
                        // Pop until home
                         Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text("Share Receipt"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
