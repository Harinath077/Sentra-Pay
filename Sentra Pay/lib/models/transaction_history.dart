class Transaction {
  final String id;
  final String recipient;
  final double amount;
  final double riskScore;
  final String riskCategory;
  final DateTime timestamp;
  final bool wasBlocked;

  Transaction({
    required this.id,
    required this.recipient,
    required this.amount,
    required this.riskScore,
    required this.riskCategory,
    required this.timestamp,
    this.wasBlocked = false,
  });
}

class TransactionHistory {
  static final List<Transaction> _history = [];
  
  static void addTransaction(Transaction transaction) {
    _history.insert(0, transaction); // Add to beginning
    if (_history.length > 50) {
      _history.removeLast(); // Keep only last 50
    }
  }
  
  static List<Transaction> getHistory() {
    return List.unmodifiable(_history);
  }
  
  static List<Transaction> getRecentTransactions(int count) {
    return _history.take(count).toList();
  }
  
  static double getTrustScore() {
    if (_history.isEmpty) return 100.0;
    
    int safeCount = _history.where((t) => t.riskScore < 0.35).length;
    int totalCount = _history.length;
    
    return (safeCount / totalCount * 100).clamp(0.0, 100.0);
  }
  
  static String getTrustTier() {
    double score = getTrustScore();
    if (score >= 95) return "Platinum";
    if (score >= 85) return "Gold";
    if (score >= 70) return "Silver";
    return "Bronze";
  }
  
  static List<double> getRiskTrend(int count) {
    return _history
        .take(count)
        .map((t) => t.riskScore * 100)
        .toList()
        .reversed
        .toList();
  }
}
