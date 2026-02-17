import 'dart:math';
import 'user_profile.dart';
import '../services/api_service.dart';
import '../services/risk_engine.dart';

enum RiskCategory { low, medium, high }

class RiskAnalysisResult {
  final double score;
  final RiskCategory category;
  final List<String> factors;
  final bool isBlocked;
  final double behaviorScore;
  final double amountScore;
  final double receiverScore;
  final String? transactionId; // Transaction ID from backend
  final String? icon;
  final String? color;
  final String? background;
  final String? label;

  RiskAnalysisResult({
    required this.score,
    required this.category,
    required this.factors,
    this.isBlocked = false,
    this.behaviorScore = 0.0,
    this.amountScore = 0.0,
    this.receiverScore = 0.0,
    this.transactionId,
    this.icon,
    this.color,
    this.background,
    this.label,
  });
}

class FraudStore {
  // 1. App-Level User Identity
  static String appUserId =
      "USER-${Random().nextInt(99999).toString().padLeft(5, '0')}";

  // 2. Demo Mode Flag
  static bool isDemoMode = false;

  // 3. Local "Legit" & "Fraud" Database (Simulation)
  static final Map<String, double> _receiverReputation = {
    "merchant@upi": 0.1, // Safe
    "friend@upi": 0.0, // Safe
    "unknown@upi": 0.5, // Unknown
    "scammer@upi": 0.95, // Fraud
  };

  static final Set<String> _reportedIDs = {};

  // Transaction History Storage
  static final List<Map<String, dynamic>> _transactionHistory = [];

  // Get transaction history
  static List<Map<String, dynamic>> get transactionHistory =>
      List.unmodifiable(_transactionHistory);

  // Add transaction to history
  static void addTransaction({
    required String receiver,
    required double amount,
    required String risk,
    required DateTime timestamp,
  }) {
    _transactionHistory.insert(0, {
      'receiver': receiver,
      'amount': amount,
      'risk': risk,
      'timestamp': timestamp,
      'via': 'UPI',
    });

    // Keep only last 50 transactions
    if (_transactionHistory.length > 50) {
      _transactionHistory.removeLast();
    }
  }

  static void syncHistory(List<Map<String, dynamic>> transactions) {
    _transactionHistory.clear();
    _transactionHistory.addAll(transactions);
  }

  static void init() {
    // Generate ID on startup if not exists (mock)
    print("App User Security ID: $appUserId");
  }

  static void toggleDemoMode(bool value) {
    isDemoMode = value;
  }

  // Verify Receiver (Simulated Lookup)
  static String? verifyRecipient(String id) {
    if (isDemoMode) {
      if (id.contains("scammer")) return "Suspicious Account";
      if (id.contains("merchant")) return "Mega Store Ltd";
    }

    // In normal mode, simulate based on hardcoded DB
    if (_receiverReputation.containsKey(id)) {
      double score = _receiverReputation[id]!;
      if (score < 0.3) return "Verified Merchant";
      if (score > 0.8) return "Flagged Account";
    }

    return null; // Unknown
  }

  static void report(String id) {
    _reportedIDs.add(id);
    _receiverReputation[id] = 1.0; // Mark local as high risk

    // Call Backend (Fire and forget)
    ApiService.reportFraud(id);
  }

  static bool isReported(String id) {
    return _reportedIDs.contains(id);
  }

  // Core Risk Logic using Real Risk Engine
  static RiskAnalysisResult analyzeRisk(
    String recipientId,
    double amount, {
    UserProfile? user,
  }) {
    // Get list of known receivers
    List<String> previousReceivers = _transactionHistory
        .map((t) => t['receiver'] as String? ?? '')
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();

    // Check if receiver is new
    bool isNewReceiver =
        !previousReceivers.contains(recipientId) &&
        !(user?.commonVPAs.contains(recipientId) ?? false);

    // Call the real risk engine
    final riskData = RiskEngine.analyze(
      amount: amount,
      receiverId: recipientId,
      isNewReceiver: isNewReceiver,
      timestamp: DateTime.now(),
      userProfile: user,
      deviceId: user?.deviceId,
      previousReceivers: previousReceivers,
    );

    // Convert RiskData to RiskAnalysisResult
    RiskCategory category;
    if (riskData.score < 0.4) {
      category = RiskCategory.low;
    } else if (riskData.score < 0.7) {
      category = RiskCategory.medium;
    } else {
      category = RiskCategory.high;
    }

    // Extract component scores from factors for backward compatibility
    // These are approximations since RiskEngine doesn't expose them directly
    double behaviorScore = user != null && user.loginCount < 5 ? 0.6 : 0.3;
    double amountScore = amount > 5000 ? 0.7 : (amount > 2000 ? 0.4 : 0.2);
    double receiverScore = isNewReceiver ? 0.6 : 0.2;

    return RiskAnalysisResult(
      score: riskData.score,
      category: category,
      factors: riskData.explanations,
      isBlocked: riskData.status == 'Blocked',
      behaviorScore: behaviorScore,
      amountScore: amountScore,
      receiverScore: receiverScore,
    );
  }

  // ADDED ASYNC VERSION FOR BACKEND CALLS
  static Future<RiskAnalysisResult> analyzeRiskAsync(
    String recipientId,
    double amount, {
    UserProfile? user,
    String? token,
  }) async {
    // 1. Try to get result from backend
    final result = await ApiService.analyzeRisk(
      receiverUpi: recipientId,
      amount: amount,
      token:
          token ??
          "demo-token", // Pass fallback if null here or let ApiService handle
    );

    if (result != null) {
      return result;
    }

    // 2. Fallback to local logic if backend is down
    return analyzeRisk(recipientId, amount, user: user);
  }
}
