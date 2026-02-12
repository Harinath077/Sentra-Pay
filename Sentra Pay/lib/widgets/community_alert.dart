import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class CommunityAlertWidget extends StatelessWidget {
  final String recipientId;
  final int reportCount;

  const CommunityAlertWidget({
    super.key,
    required this.recipientId,
    this.reportCount = 0,
  });

  int _getReportCount() {
    // Simulate community reports based on recipient ID
    if (recipientId.contains('scammer') || recipientId.contains('fraud')) {
      return math.Random().nextInt(20) + 10; // 10-30 reports
    }
    if (recipientId.contains('unknown')) {
      return math.Random().nextInt(5) + 1; // 1-5 reports
    }
    return reportCount;
  }

  String _getTimeAgo() {
    final hours = math.Random().nextInt(24) + 1;
    if (hours == 1) return "1 hour ago";
    if (hours < 24) return "$hours hours ago";
    return "1 day ago";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = _getReportCount();
    
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "⚠️ Community Alert",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$count users reported this account",
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Last reported: ${_getTimeAgo()}",
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
