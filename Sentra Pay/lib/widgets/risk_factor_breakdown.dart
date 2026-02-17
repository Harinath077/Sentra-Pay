import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RiskFactorBreakdown extends StatefulWidget {
  final double behaviorScore;
  final double amountScore;
  final double receiverScore;

  const RiskFactorBreakdown({
    super.key,
    required this.behaviorScore,
    required this.amountScore,
    required this.receiverScore,
  });

  @override
  State<RiskFactorBreakdown> createState() => _RiskFactorBreakdownState();
}

class _RiskFactorBreakdownState extends State<RiskFactorBreakdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForScore(double score) {
    if (score < 0.35) return const Color(0xFF10B981);
    if (score < 0.65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDark
        ? AppTheme.darkTextPrimary
        : const Color(0xFF0F172A);
    final secondaryColor = isDark
        ? AppTheme.darkTextSecondary
        : const Color(0xFF64748B);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorderColor
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 20,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "RISK BREAKDOWN",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFactorBar(
                "Behavior Analysis",
                widget.behaviorScore,
                _animation.value,
                textColor,
              ),
              const SizedBox(height: 16),
              _buildFactorBar(
                "Amount Analysis",
                widget.amountScore,
                _animation.value,
                textColor,
              ),
              const SizedBox(height: 16),
              _buildFactorBar(
                "Receiver Analysis",
                widget.receiverScore,
                _animation.value,
                textColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFactorBar(
    String label,
    double score,
    double animationValue,
    Color textColor,
  ) {
    // Determine risk level text and color
    String riskText;
    Color color;

    if (score < 0.35) {
      riskText = "Low Risk";
      color = const Color(0xFF10B981);
    } else if (score < 0.7) {
      riskText = "Moderate Risk";
      color = const Color(0xFFF59E0B);
    } else {
      riskText = "High Risk";
      color = const Color(0xFFEF4444);
    }

    final animatedScore = score * animationValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              riskText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: animatedScore,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
