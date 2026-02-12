import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class RiskTrendGraph extends StatefulWidget {
  final List<double> riskScores;

  const RiskTrendGraph({
    super.key,
    required this.riskScores,
  });

  @override
  State<RiskTrendGraph> createState() => _RiskTrendGraphState();
}

class _RiskTrendGraphState extends State<RiskTrendGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryColor = isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B);

    // Use provided scores or generate sample data
    final scores = widget.riskScores.isNotEmpty
        ? widget.riskScores
        : List.generate(10, (i) => 20.0 + math.Random().nextDouble() * 40);

    final trend = _calculateTrend(scores);

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_down, size: 20, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    "RISK TREND",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 12,
                      color: trend < 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${trend.abs().toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trend < 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                height: 120,
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _TrendGraphPainter(
                    scores: scores,
                    animationValue: _animation.value,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            trend < 0
                ? "✓ Your risk exposure is decreasing"
                : "⚠️ Risk levels are increasing",
            style: TextStyle(
              fontSize: 12,
              color: trend < 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTrend(List<double> scores) {
    if (scores.length < 2) return 0;
    final recent = scores.take(3).reduce((a, b) => a + b) / 3;
    final older = scores.skip(math.max(0, scores.length - 3)).reduce((a, b) => a + b) / 3;
    return recent - older;
  }
}

class _TrendGraphPainter extends CustomPainter {
  final List<double> scores;
  final double animationValue;
  final bool isDark;

  _TrendGraphPainter({
    required this.scores,
    required this.animationValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withOpacity(0.3),
          const Color(0xFF2563EB).withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final maxScore = 100.0;
    final stepX = size.width / (scores.length - 1);

    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / maxScore * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw gradient fill
    canvas.drawPath(fillPath, gradientPaint);

    // Draw line
    paint.color = const Color(0xFF2563EB);
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < scores.length; i++) {
      final x = i * stepX;
      final y = size.height - (scores[i] / maxScore * size.height);

      final dotPaint = Paint()
        ..color = isDark ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 5, dotPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFF2563EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(x, y), 5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.scores != scores;
  }
}
