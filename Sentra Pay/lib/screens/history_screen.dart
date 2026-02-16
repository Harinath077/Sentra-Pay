import 'package:flutter/material.dart';
import '../models/transaction_history.dart';
import '../theme/app_theme.dart';
import '../widgets/risk_trend_graph.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../models/auth_provider.dart';
import '../models/fraud_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaction> _history = [];
  bool _isLoading = true;
  String _trustTier = "Bronze";
  double _trustScore = 50.0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  DateTime _parseTimestamp(dynamic input) {
    String ts = input?.toString() ?? '';
    // If empty, return now
    if (ts.isEmpty) return DateTime.now();
    
    // Assume UTC if no timezone info and looks like ISO date
    if (!ts.endsWith('Z') && !ts.contains('+')) {
      ts += 'Z';
    }
    
    return DateTime.tryParse(ts)?.toLocal() ?? DateTime.now();
  }

  Future<void> _fetchHistory() async {
    // 1. Fetch from backend
    // Since we don't have a real token stored in this demo flow yet,
    // we'll try to use a dummy one or skip if not implemented.
    // For now, let's mix local + backend.
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token ?? "demo-token";
      final backendData = await ApiService.getTransactionHistory(token);
      
      if (backendData.isNotEmpty) {
        final List<Transaction> backendTransactions = backendData.map((data) {
          return Transaction(
            id: data['transaction_id'] ?? 'unknown',
            recipient: data['receiver'] ?? 'Unknown',
            amount: (data['amount'] ?? 0).toDouble(),
            riskScore: (data['risk_score'] ?? 0).toDouble(),
            riskCategory: data['risk_level'] ?? 'LOW',
            // Handle UTC timestamp from backend
            timestamp: _parseTimestamp(data['timestamp']),
            wasBlocked: (data['status'] ?? '').toString().toUpperCase() == 'BLOCKED',
          );
        }).toList();

        // Sync with FraudStore for Analytics screen
        final List<Map<String, dynamic>> analyticsData = backendData.map((data) => {
          'recipient': data['receiver'] ?? 'Unknown',
          'amount': (data['amount'] ?? 0).toDouble(),
          'risk': (data['risk_level'] ?? 'LOW').toString().toLowerCase(),
          'timestamp': _parseTimestamp(data['timestamp']),
        }).toList();
        FraudStore.syncHistory(analyticsData);

        if (mounted) {
          setState(() {
            _history = backendTransactions;
            _isLoading = false;
            
            // Calculate trust score based on history for now
            // In a real app, we'd fetch the user profile for accurate trust score
            if (_history.isNotEmpty) {
               // Simple calculation for UI feedback
               int safeTxns = _history.where((t) => t.riskScore < 0.3).length;
               _trustScore = (safeTxns / _history.length * 100).clamp(0, 100).toDouble();
            }
            
            _trustTier = TransactionHistory.getTrustTier();
          });
        }
      } else {
        // Backend returned empty, maybe new user or failure.
        // If empty list, check if we should show dummy data or just empty state.
        // For demo purposes, if empty, we fall back to dummy data so the UI isn't empty.
        _loadLocalHistory();
      }
    } catch (e) {
      print("Error fetching history: $e");
      _loadLocalHistory();
    }
  }

  void _loadLocalHistory() {
     if (mounted) {
      setState(() {
        _history = TransactionHistory.getRecentTransactions(20);
        _isLoading = false;
        _trustScore = TransactionHistory.getTrustScore(); 
        _trustTier = TransactionHistory.getTrustTier();
      });
     }
  }
  
  Color _getRiskColor(double score) {
    if (score < 0.35) return const Color(0xFF10B981);
    if (score < 0.65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getRiskIcon(double score) {
    if (score < 0.35) return Icons.check_circle;
    if (score < 0.65) return Icons.warning_amber_rounded;
    return Icons.dangerous;
  }
  
  IconData _getTierIcon(String tier) {
    switch (tier) {
      case "Platinum":
        return Icons.workspace_premium;
      case "Gold":
        return Icons.stars;
      case "Silver":
        return Icons.star;
      default:
        return Icons.shield;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final textColor = isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryColor = isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B);

    final riskTrend = TransactionHistory.getRiskTrend(10); // Still using local calc for graph

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Transaction History",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: textColor,
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchHistory();
              },
            ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trust Score Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getTierIcon(_trustTier),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "$_trustTier User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${_trustScore.toStringAsFixed(0)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Trust Score",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_history.length} transactions analyzed",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Risk Trend Graph
            if (riskTrend.isNotEmpty) ...[
              RiskTrendGraph(riskScores: riskTrend),
              const SizedBox(height: 24),
            ],

            // Transaction List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (_history.isNotEmpty)
                  Text(
                    "${_history.length} total",
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Transaction List
            if (_history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: secondaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No transactions yet",
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your transaction history will appear here",
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._history.map((transaction) => _buildTransactionCard(
                    transaction,
                    cardColor,
                    textColor,
                    secondaryColor,
                    isDark,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    Color cardColor,
    Color textColor,
    Color secondaryColor,
    bool isDark,
  ) {
    final riskColor = _getRiskColor(transaction.riskScore);
    final riskIcon = _getRiskIcon(transaction.riskScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              riskIcon,
              color: riskColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.recipient,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.timestamp),
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${transaction.amount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${(transaction.riskScore * 100).toInt()}% risk",
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
