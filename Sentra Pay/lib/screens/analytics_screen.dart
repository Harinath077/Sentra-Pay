import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../models/fraud_store.dart';
import '../models/auth_provider.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Week';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token ?? "demo-token";
      final backendData = await ApiService.getTransactionHistory(token);

      if (backendData.isNotEmpty) {
        final List<Map<String, dynamic>> analyticsData = backendData
            .map(
              (data) => {
                'recipient': data['receiver'] ?? 'Unknown',
                'amount': (data['amount'] ?? 0).toDouble(),
                'risk': (data['risk_level'] ?? 'LOW').toString().toLowerCase(),
                'timestamp': _parseTimestamp(data['timestamp']),
              },
            )
            .toList();

        FraudStore.syncHistory(analyticsData);
      }
    } catch (e) {
      debugPrint("Error fetching analytics data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _parseTimestamp(dynamic input) {
    String ts = input?.toString() ?? '';
    if (ts.isEmpty) return DateTime.now();
    if (!ts.endsWith('Z') && !ts.contains('+')) ts += 'Z';
    return DateTime.tryParse(ts)?.toLocal() ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: _isLoading ? _buildLoadingShimmer(isDark) : _buildContent(isDark),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(
          5,
          (_) => Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final transactions = FraudStore.transactionHistory;
    final stats = _calculatePeriodData(transactions);

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            title: const Text(
              "Fraud Analytics",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSegmentedFilter(isDark),
                const SizedBox(height: 24),
                _buildKPICards(stats, isDark),
                const SizedBox(height: 24),
                _buildRiskDistribution(stats, isDark),
                const SizedBox(height: 24),
                _buildTrendSection(isDark),
                const SizedBox(height: 24),
                _buildIndicatorsGrid(isDark),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Week', 'Month', 'Year'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF3B82F6) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKPICards(Map<String, dynamic> stats, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            "Fraud Blocked",
            stats['blocked'].toString(),
            AppTheme.errorColor,
            isDark,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            "Protected",
            "₹${_formatAmount(stats['protected'])}",
            AppTheme.successColor,
            isDark,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            "TXNs Scanned",
            stats['total'].toString(),
            AppTheme.primaryColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution(Map<String, dynamic> stats, bool isDark) {
    final medPct = (stats['med_pct'] ?? 0.0) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Risk Distribution",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: AppTheme.successColor,
                        value: (stats['low_pct'] ?? 0.1) * 100,
                        radius: 15,
                        title: '',
                      ),
                      PieChartSectionData(
                        color: AppTheme.warningColor,
                        value: (stats['med_pct'] ?? 0.1) * 100,
                        radius: 15,
                        title: '',
                      ),
                      PieChartSectionData(
                        color: AppTheme.errorColor,
                        value: (stats['high_pct'] ?? 0.1) * 100,
                        radius: 15,
                        title: '',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegend("Low", AppTheme.successColor),
                    _buildLegend("Medium", AppTheme.warningColor),
                    _buildLegend("High", AppTheme.errorColor),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(bool isDark) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fraud Trends",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 1),
                      FlSpot(2, 4),
                      FlSpot(3, 2),
                      FlSpot(4, 5),
                    ],
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildIndicatorCard(
          "Suspicious VPA",
          Icons.person_off,
          AppTheme.errorColor,
          isDark,
        ),
        _buildIndicatorCard(
          "Amount Spike",
          Icons.trending_up,
          AppTheme.warningColor,
          isDark,
        ),
        _buildIndicatorCard(
          "New Device",
          Icons.smartphone,
          AppTheme.primaryColor,
          isDark,
        ),
        _buildIndicatorCard("Velocity", Icons.speed, Colors.purple, isDark),
      ],
    );
  }

  Widget _buildIndicatorCard(
    String title,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  Map<String, dynamic> _calculatePeriodData(
    List<Map<String, dynamic>> transactions,
  ) {
    final now = DateTime.now();
    int days = _selectedPeriod == 'Week'
        ? 7
        : (_selectedPeriod == 'Month' ? 30 : 365);
    final periodStart = now.subtract(Duration(days: days));

    final periodTransactions = transactions.where((t) {
      final ts = t['timestamp'] as DateTime?;
      return ts != null && ts.isAfter(periodStart);
    }).toList();

    final blocked = periodTransactions
        .where(
          (t) => [
            'high',
            'very_high',
          ].contains(t['risk']?.toString().toLowerCase()),
        )
        .toList();
    final protectedAmount = blocked.fold(
      0.0,
      (sum, t) => sum + (t['amount'] as double),
    );

    int lowCount = 0, medCount = 0, highCount = 0;
    for (var t in periodTransactions) {
      final risk = t['risk']?.toString().toLowerCase() ?? '';
      if (risk == 'low') {
        lowCount++;
      } else if (['medium', 'moderate', 'amber'].contains(risk))
        medCount++;
      else if (['high', 'very_high'].contains(risk))
        highCount++;
    }

    final total = periodTransactions.length;
    return {
      'total': total,
      'blocked': blocked.length,
      'protected': protectedAmount,
      'low_pct': total > 0 ? lowCount / total : 0.7,
      'med_pct': total > 0 ? medCount / total : 0.25,
      'high_pct': total > 0 ? highCount / total : 0.05,
    };
  }
}
