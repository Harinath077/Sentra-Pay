import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/fraud_store.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate real data based on transaction history
    final transactions = FraudStore.transactionHistory;
    final periodData = _calculatePeriodData(transactions);
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgColor : AppTheme.backgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Fraud Analytics",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Row(
              children: [
                _buildPeriodChip('Week', isDark),
                const SizedBox(width: 12),
                _buildPeriodChip('Month', isDark),
                const SizedBox(width: 12),
                _buildPeriodChip('Year', isDark),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Fraud Detection Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E40AF), const Color(0xFF3B82F6)]
                      : [const Color(0xFF1E40AF), const Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fraud Prevention Summary",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Blocked",
                          _getBlockedCount(),
                          Icons.block,
                          const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Protected",
                          "₹${_getProtectedAmount()}",
                          Icons.shield,
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Risk Distribution Graph
            Text(
              "Risk Distribution",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
                ),
              ),
              child: Column(
                children: [
                  _buildRiskBar("Low Risk", 0.7, const Color(0xFF10B981), isDark),
                  const SizedBox(height: 12),
                  _buildRiskBar("Medium Risk", 0.25, const Color(0xFFF59E0B), isDark),
                  const SizedBox(height: 12),
                  _buildRiskBar("High Risk", 0.05, const Color(0xFFEF4444), isDark),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Fraud Indicators
            Text(
              "Fraud Indicators Detected",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildIndicatorCard(
              "Suspicious VPA",
              "2 blocked",
              Icons.person_off,
              const Color(0xFFEF4444),
              isDark,
            ),
            const SizedBox(height: 12),
            _buildIndicatorCard(
              "Unusual Amount",
              "1 flagged",
              Icons.warning_amber,
              const Color(0xFFF59E0B),
              isDark,
            ),
            const SizedBox(height: 12),
            _buildIndicatorCard(
              "New Device",
              "0 detected",
              Icons.devices,
              const Color(0xFF10B981),
              isDark,
            ),
            
            const SizedBox(height: 24),
            
            // Protection Stats
            Text(
              "Protection Statistics",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
                ),
              ),
              child: Column(
                children: [
                  _buildProtectionStat("Transactions Scanned", _getTotalTransactions(), isDark),
                  const Divider(height: 24),
                  _buildProtectionStat("Fraud Attempts Blocked", _getBlockedCount(), isDark),
                  const Divider(height: 24),
                  _buildProtectionStat("Success Rate", "98.5%", isDark),
                  const Divider(height: 24),
                  _buildProtectionStat("Money Protected", "₹${_getProtectedAmount()}", isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E40AF)
              : (isDark ? AppTheme.darkCardColor : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E40AF)
                : (isDark ? AppTheme.darkBorderColor : AppTheme.borderColor),
          ),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBar(String label, double percentage, Color color, bool isDark) {
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
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            Text(
              "${(percentage * 100).toInt()}%",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicatorCard(String title, String subtitle, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionStat(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculatePeriodData(List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    int days;
    
    switch (_selectedPeriod) {
      case 'Week':
        days = 7;
        break;
      case 'Month':
        days = 30;
        break;
      case 'Year':
        days = 365;
        break;
      default:
        days = 7;
    }
    
    final periodStart = now.subtract(Duration(days: days));
    final periodTransactions = transactions.where((t) {
      final timestamp = t['timestamp'] as DateTime?;
      return timestamp != null && timestamp.isAfter(periodStart);
    }).toList();
    
    final blockedCount = periodTransactions.where((t) => t['risk'] == 'high').length;
    final protectedAmount = periodTransactions
        .where((t) => t['risk'] == 'high')
        .fold(0.0, (sum, t) => sum + (t['amount'] as double));
    
    return {
      'total': periodTransactions.length,
      'blocked': blockedCount,
      'protected': protectedAmount,
    };
  }

  String _getBlockedCount() {
    final transactions = FraudStore.transactionHistory;
    final data = _calculatePeriodData(transactions);
    return data['blocked'].toString();
  }

  String _getProtectedAmount() {
    final transactions = FraudStore.transactionHistory;
    final data = _calculatePeriodData(transactions);
    final amount = data['protected'] as double;
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _getTotalTransactions() {
    final transactions = FraudStore.transactionHistory;
    final data = _calculatePeriodData(transactions);
    return data['total'].toString();
  }
}

