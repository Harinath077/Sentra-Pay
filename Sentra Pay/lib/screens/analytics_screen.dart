import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/auth_provider.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late List<Animation<double>> _sectionAnimations;

  int _totalTransactions = 0;
  double _accuracy = 0;
  int _blockedCount = 0;
  int _safeCount = 0;
  int _mediumCount = 0;
  int _highCount = 0;
  double _moneyProtected = 0;
  bool _isLoading = false;

  // Animated values
  double _animatedMoney = 0;
  double _animatedScore = 0;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 5 sections (hero, safety score, risk breakdown, insights, risk factors)
    _sectionAnimations = List.generate(5, (i) {
      final start = i * 0.08;
      final end = start + 0.25;
      return CurvedAnimation(
        parent: _contentController,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );
    });

    _contentController.forward();
    _loadStats();
  }

  void _loadStats() async {
    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';
      print('[Analytics] Fetching history with token: ${token.isNotEmpty ? "present" : "EMPTY"}');
      final history = await ApiService.getTransactionHistory(token);
      print('[Analytics] Got ${history.length} transactions from backend');
      if (mounted) {
        int blocked = 0;
        int safe = 0;
        int medium = 0;
        double totalBlockedAmount = 0;
        for (var t in history) {
          final risk =
              (t['risk_level'] ?? t['risk'] ?? '').toString().toUpperCase();
          final amount = (t['amount'] ?? 0).toDouble();
          if (risk == 'HIGH' || risk == 'VERY_HIGH' || risk == 'BLOCKED') {
            blocked++;
            totalBlockedAmount += amount;
          } else if (risk == 'MODERATE' || risk == 'MEDIUM') {
            medium++;
          } else {
            safe++;
          }
        }
        setState(() {
          _totalTransactions = history.length;
          _blockedCount = blocked;
          _safeCount = safe;
          _mediumCount = medium;
          _highCount = blocked;
          _accuracy =
              history.isEmpty ? 0 : ((safe / history.length) * 100);
          _moneyProtected = totalBlockedAmount;
          _isLoading = false;
        });
        _startAnimations();
      }
    } catch (e) {
      print('[Analytics] Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startAnimations();
      }
    }
  }

  void _startAnimations() {
    _contentController.duration = const Duration(milliseconds: 600);
    _contentController.reset();
    _contentController.forward();

    final moneyTween = Tween<double>(begin: 0, end: _moneyProtected);
    final scoreTween = Tween<double>(begin: 0, end: _accuracy);

    _contentController.addListener(() {
      if (mounted) {
        setState(() {
          _animatedMoney = moneyTween.evaluate(CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ));
          _animatedScore = scoreTween.evaluate(CurvedAnimation(
            parent: _contentController,
            curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final textColor =
        isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryColor =
        isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B);
    final borderColor =
        isDark ? AppTheme.darkBorderColor : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () {
              setState(() => _isLoading = true);
              _contentController.reset();
              _loadStats();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryColor, strokeWidth: 2))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildAnimatedSection(
                      0,
                      _buildHeroCard(
                          isDark, cardColor, textColor, secondaryColor, borderColor)),
                  const SizedBox(height: 16),
                  _buildAnimatedSection(
                      1,
                      _buildSafetyScoreCard(
                          isDark, cardColor, textColor, secondaryColor, borderColor)),
                  const SizedBox(height: 16),
                  _buildAnimatedSection(
                      2,
                      _buildRiskBreakdownCard(
                          isDark, cardColor, textColor, secondaryColor, borderColor)),
                  const SizedBox(height: 16),
                  _buildAnimatedSection(
                      3,
                      _buildBehavioralInsightsCard(
                          isDark, cardColor, textColor, secondaryColor, borderColor)),
                  const SizedBox(height: 16),
                  _buildAnimatedSection(
                      4,
                      _buildRiskFactorsCard(
                          isDark, cardColor, textColor, secondaryColor, borderColor)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    if (index >= _sectionAnimations.length) return child;
    return AnimatedBuilder(
      animation: _sectionAnimations[index],
      builder: (context, _) {
        final value = _sectionAnimations[index].value;
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  // ─── Section 1: Hero Card — Money Protected ───
  Widget _buildHeroCard(bool isDark, Color cardColor, Color textColor,
      Color secondaryColor, Color borderColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent stripe
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.6),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Text(
                    'MONEY PROTECTED',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  Text(
                    _formatCurrency(_animatedMoney),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'shielded from risky transactions',
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats in tinted containers
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFEEF2F6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _totalTransactions.toString(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total Transactions',
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : const Color(0xFFEEF2F6),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _blockedCount.toString(),
                                style: TextStyle(
                                  color: _blockedCount > 0
                                      ? AppTheme.errorColor
                                      : textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Threats Blocked',
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section 2: Safety Score Ring ───
  Widget _buildSafetyScoreCard(bool isDark, Color cardColor, Color textColor,
      Color secondaryColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Score',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on your recent transaction activity',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _SafetyRingPainter(
                  progress: (_animatedScore / 100).clamp(0.0, 1.0),
                  color: AppTheme.successColor,
                  bgColor: (isDark ? Colors.white : Colors.black)
                      .withOpacity(0.08),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _animatedScore.toStringAsFixed(0),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'out of 100',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded,
                      color: AppTheme.successColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _animatedScore >= 90
                        ? 'Excellent'
                        : _animatedScore >= 70
                            ? 'Good'
                            : 'Needs Attention',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 3: Risk Breakdown — fl_chart PieChart ───
  int _touchedIndex = -1;

  Widget _buildRiskBreakdownCard(bool isDark, Color cardColor, Color textColor,
      Color secondaryColor, Color borderColor) {
    final total = _safeCount + _mediumCount + _highCount;
    final safePct = total > 0 ? (_safeCount / total * 100) : 85.0;
    final medPct = total > 0 ? (_mediumCount / total * 100) : 10.0;
    final highPct = total > 0 ? (_highCount / total * 100) : 5.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Risk Breakdown',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Transaction risk distribution',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.successColor,
                          value: safePct,
                          title: '${safePct.toStringAsFixed(0)}%',
                          radius: _touchedIndex == 0 ? 56 : 48,
                          titleStyle: TextStyle(
                            fontSize: _touchedIndex == 0 ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          titlePositionPercentageOffset: 0.55,
                        ),
                        PieChartSectionData(
                          color: AppTheme.warningColor,
                          value: medPct,
                          title: '${medPct.toStringAsFixed(0)}%',
                          radius: _touchedIndex == 1 ? 56 : 48,
                          titleStyle: TextStyle(
                            fontSize: _touchedIndex == 1 ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          titlePositionPercentageOffset: 0.55,
                        ),
                        PieChartSectionData(
                          color: AppTheme.errorColor,
                          value: highPct,
                          title: '${highPct.toStringAsFixed(0)}%',
                          radius: _touchedIndex == 2 ? 56 : 48,
                          titleStyle: TextStyle(
                            fontSize: _touchedIndex == 2 ? 14 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          titlePositionPercentageOffset: 0.55,
                        ),
                      ],
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegendRow('Safe', _safeCount,
                          AppTheme.successColor, textColor, secondaryColor),
                      const SizedBox(height: 16),
                      _buildChartLegendRow('Medium', _mediumCount,
                          AppTheme.warningColor, textColor, secondaryColor),
                      const SizedBox(height: 16),
                      _buildChartLegendRow('High Risk', _highCount,
                          AppTheme.errorColor, textColor, secondaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendRow(String label, int count, Color color,
      Color textColor, Color secondaryColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Section 4: Behavioral Insights ───
  Widget _buildBehavioralInsightsCard(bool isDark, Color cardColor,
      Color textColor, Color secondaryColor, Color borderColor) {

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavioral Insights',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Patterns detected from your recent activity',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Insight 1 — Spending Pattern
          _buildInsightRow(
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            borderColor: borderColor,
            title: 'Typical amount range',
            value: '₹500 – ₹3,000',
            status: 'Normal',
            statusColor: AppTheme.successColor,
          ),

          // Insight 2 — Unusual Activity
          _buildInsightRow(
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            borderColor: borderColor,
            title: 'Late-night attempts',
            value: '2 detected',
            status: 'Review',
            statusColor: AppTheme.warningColor,
          ),

          // Insight 3 — Flagged Receivers
          _buildInsightRow(
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            borderColor: borderColor,
            title: 'Suspicious receivers',
            value: '$_blockedCount flagged',
            status: _blockedCount > 0 ? 'Alert' : 'Clear',
            statusColor: _blockedCount > 0
                ? AppTheme.errorColor
                : AppTheme.successColor,
          ),

          // Insight 4 — Frequency
          _buildInsightRow(
            isDark: isDark,
            textColor: textColor,
            secondaryColor: secondaryColor,
            borderColor: borderColor,
            title: 'Transaction frequency',
            value: 'Within range',
            status: 'Normal',
            statusColor: AppTheme.successColor,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required bool isDark,
    required Color textColor,
    required Color secondaryColor,
    required Color borderColor,
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              // Title + Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: borderColor,
          ),
      ],
    );
  }

  // ─── Section 5: Risk Factors — fl_chart BarChart ───
  Widget _buildRiskFactorsCard(bool isDark, Color cardColor, Color textColor,
      Color secondaryColor, Color borderColor) {
    final factors = [
      _RiskFactor('New Receiver', 35, AppTheme.warningColor),
      _RiskFactor('Amt Spike', 22, AppTheme.successColor),
      _RiskFactor('Suspicious', 68, AppTheme.errorColor),
      _RiskFactor('Device/Loc', 15, AppTheme.successColor),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Risk Factors',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'AI breakdown of threat vectors',
            style: TextStyle(
              color: secondaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${factors[groupIndex].label}\n${rod.toY.toInt()}%',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= factors.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            factors[idx].label,
                            style: TextStyle(
                              color: secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.06),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: factors.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: f.value.toDouble(),
                        color: f.color,
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.04),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Painters ─────────────────────────────────────────────────

class _SafetyRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _SafetyRingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final sweepAngle = 2 * pi * progress;
    const startAngle = -pi / 2;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SafetyRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Data Models ─────────────────────────────────────────────────────

class _InsightData {
  final IconData icon;
  final String text;
  final Color color;
  _InsightData(this.icon, this.text, this.color);
}

class _RiskFactor {
  final String label;
  final int value;
  final Color color;
  _RiskFactor(this.label, this.value, this.color);
}

