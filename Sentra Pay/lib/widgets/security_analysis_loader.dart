import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// State 1: User clicks "Pay Now" or "Scan"
class SecurityAnalysisLoader extends StatefulWidget {
  final VoidCallback? onComplete;

  const SecurityAnalysisLoader({super.key, this.onComplete});

  @override
  _SecurityAnalysisLoaderState createState() => _SecurityAnalysisLoaderState();
}

class _SecurityAnalysisLoaderState extends State<SecurityAnalysisLoader>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final List<String> _steps = [
    "Analyzing user behavior",
    "Checking fraud patterns",
    "Verifying receiver",
    "Calculating risk score",
  ];

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() async {
    // Total duration ~2s to feel intentional (500ms per step)
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _currentStep = i;
      });
    }

    // Wait slightly at the end then callback
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine theme colors (support dark mode)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : Colors.white;
    final textColor = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final subTextColor = isDark ? AppTheme.darkTextSecondary : Colors.grey[600];
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Security Icon with subtle scale animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              "Securing Payment",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Sentra Pay AI is analyzing this transaction",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: subTextColor),
            ),

            const SizedBox(height: 30),

            // Progress Steps
            ..._steps.asMap().entries.map((entry) {
              int idx = entry.key;
              String text = entry.value;
              bool isCompleted = idx < _currentStep;
              bool isCurrent = idx == _currentStep;

              // Only show items up to current step + 1 (future steps are hidden or dim)
              // To keep it clean, let's show all but change opacities/icons

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF10B981) // Success Green
                            : (isCurrent
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withOpacity(0.3)),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : (isCurrent
                                ? const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : null),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent || isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCurrent || isCompleted
                              ? textColor
                              : subTextColor!.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
