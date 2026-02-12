import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'backend_api_service.dart';
import '../models/fraud_store.dart';

/// Hybrid Fraud Detection Service
/// Combines Firebase (storage) with your FastAPI backend (ML analysis)
class HybridFraudService {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final BackendApiService _backendService = BackendApiService();
  final FraudStore _localFraudStore = FraudStore();

  /// Analyze transaction using hybrid approach
  /// 1. Try backend ML analysis (primary)
  /// 2. Fall back to local analysis if backend unavailable
  /// 3. Save results to Firestore
  /// 4. Update user stats
  Future<Map<String, dynamic>> analyzeTransaction({
    required String recipientVPA,
    required String recipientName,
    required double amount,
    required String deviceId,
  }) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Map<String, dynamic> analysisResult;
    bool backendUsed = false;

    try {
      // Step 1: Check if backend is available
      bool backendAvailable = await _backendService.isBackendAvailable();

      if (backendAvailable) {
        print('🔥 Using BACKEND ML Analysis');
        
        // Get user profile for context
        var userProfile = await _authService.getUserProfile(userId);
        
        // Call backend for ML-based analysis
        var backendResult = await _backendService.analyzeTransaction(
          userId: userId,
          recipientVPA: recipientVPA,
          amount: amount,
          deviceId: deviceId,
          userProfile: userProfile,
        );

        if (backendResult['success'] == true) {
          analysisResult = backendResult;
          backendUsed = true;
        } else {
          // Backend failed, fall back to local
          print('⚠️ Backend failed, falling back to LOCAL analysis');
          analysisResult = await _localAnalysis(
            userId: userId,
            recipientVPA: recipientVPA,
            recipientName: recipientName,
            amount: amount,
          );
        }
      } else {
        // Backend not available, use local analysis
        print('💻 Backend unavailable, using LOCAL analysis');
        analysisResult = await _localAnalysis(
          userId: userId,
          recipientVPA: recipientVPA,
          recipientName: recipientName,
          amount: amount,
        );
      }

      // Step 2: Enhance with Firestore community data
      analysisResult = await _enhanceWithCommunityData(
        analysisResult: analysisResult,
        recipientVPA: recipientVPA,
      );

      // Step 3: Save transaction to Firestore
      String transactionId = await _firestoreService.saveTransaction(
        userId: userId,
        recipientVPA: recipientVPA,
        recipientName: recipientName,
        amount: amount,
        riskScore: analysisResult['riskScore'],
        riskLevel: analysisResult['riskLevel'],
        decision: analysisResult['decision'],
        riskBreakdown: analysisResult['riskBreakdown'],
        analysisFactors: List<String>.from(analysisResult['analysisFactors'] ?? []),
      );

      // Step 4: Update user stats
      bool wasBlocked = analysisResult['decision'] == 'BLOCK';
      await _authService.updateTransactionStats(userId, wasBlocked: wasBlocked);

      // Step 5: Update trust score
      await _updateTrustScore(userId, analysisResult['riskScore']);

      // Add metadata
      analysisResult['transactionId'] = transactionId;
      analysisResult['analysisMethod'] = backendUsed ? 'BACKEND_ML' : 'LOCAL_RULES';
      analysisResult['timestamp'] = DateTime.now().toIso8601String();

      return analysisResult;

    } catch (e) {
      print('Error in hybrid fraud analysis: $e');
      
      // Ultimate fallback to local analysis
      return await _localAnalysis(
        userId: userId,
        recipientVPA: recipientVPA,
        recipientName: recipientName,
        amount: amount,
      );
    }
  }

  /// Local fraud analysis (fallback when backend unavailable)
  Future<Map<String, dynamic>> _localAnalysis({
    required String userId,
    required String recipientVPA,
    required String recipientName,
    required double amount,
  }) async {
    // Use existing local FraudStore logic
    var localResult = await _localFraudStore.analyzeRisk(
      recipientVPA: recipientVPA,
      recipientName: recipientName,
      amount: amount,
    );

    return {
      'success': true,
      'riskScore': localResult.riskScore,
      'riskLevel': localResult.riskLevel.name,
      'decision': _getDecisionFromRisk(localResult.riskScore),
      'riskBreakdown': {
        'behavior': localResult.behaviorScore,
        'amount': localResult.amountScore,
        'receiver': localResult.receiverScore,
      },
      'analysisFactors': localResult.factors,
      'backendUsed': false,
    };
  }

  /// Enhance analysis with community fraud reports from Firestore
  Future<Map<String, dynamic>> _enhanceWithCommunityData({
    required Map<String, dynamic> analysisResult,
    required String recipientVPA,
  }) async {
    try {
      // Get fraud reports from Firestore
      var fraudReport = await _firestoreService.getFraudReport(recipientVPA);
      int reportCount = fraudReport['reportCount'] ?? 0;

      if (reportCount > 0) {
        // Add community alert
        analysisResult['communityAlert'] = {
          'hasReports': true,
          'reportCount': reportCount,
          'lastReported': fraudReport['lastReported'],
        };

        // Increase risk score if highly reported
        if (reportCount >= 5) {
          double currentRisk = analysisResult['riskScore'];
          double adjustedRisk = (currentRisk + 0.2).clamp(0.0, 1.0);
          analysisResult['riskScore'] = adjustedRisk;
          analysisResult['riskLevel'] = _getRiskLevel(adjustedRisk);
          analysisResult['decision'] = _getDecisionFromRisk(adjustedRisk);
          
          // Add factor
          List<String> factors = List<String>.from(analysisResult['analysisFactors'] ?? []);
          factors.add('⚠️ Community Alert: $reportCount fraud reports');
          analysisResult['analysisFactors'] = factors;
        }
      } else {
        analysisResult['communityAlert'] = {
          'hasReports': false,
          'reportCount': 0,
        };
      }

      return analysisResult;
    } catch (e) {
      print('Error enhancing with community data: $e');
      return analysisResult;
    }
  }

  /// Update user trust score based on transaction risk
  Future<void> _updateTrustScore(String userId, double riskScore) async {
    try {
      var userProfile = await _authService.getUserProfile(userId);
      if (userProfile == null) return;

      int currentScore = userProfile['trustScore'] ?? 100;
      int scoreChange = 0;

      if (riskScore < 0.3) {
        scoreChange = 1; // Low risk: increase trust
      } else if (riskScore < 0.6) {
        scoreChange = -1; // Moderate risk: slight decrease
      } else {
        scoreChange = -5; // High risk: significant decrease
      }

      int newScore = (currentScore + scoreChange).clamp(0, 100);
      String tier = _getTrustTier(newScore);

      await _authService.updateTrustScore(userId, newScore, tier);
    } catch (e) {
      print('Error updating trust score: $e');
    }
  }

  /// Report fraud to Firestore
  Future<void> reportFraud(String recipientVPA, {String? reason}) async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    await _firestoreService.reportFraud(
      recipientVPA: recipientVPA,
      reportedByUserId: userId,
      reason: reason,
    );
  }

  /// Get transaction history from Firestore
  Future<List<Map<String, dynamic>>> getTransactionHistory() async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    return await _firestoreService.getTransactionHistory(userId);
  }

  /// Get transaction history stream (real-time)
  Stream<List<Map<String, dynamic>>> getTransactionHistoryStream() {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestoreService.getTransactionHistoryStream(userId);
  }

  /// Get user's risk trend
  Future<List<Map<String, dynamic>>> getRiskTrend({int limit = 10}) async {
    final userId = _authService.currentUserId;
    if (userId == null) return [];

    return await _firestoreService.getRiskTrend(userId, limit: limit);
  }

  /// Get risk exposure change percentage
  Future<double> getRiskExposureChange() async {
    final userId = _authService.currentUserId;
    if (userId == null) return 0.0;

    return await _firestoreService.getRiskExposureChange(userId);
  }

  // ========== HELPER METHODS ==========

  String _getDecisionFromRisk(double riskScore) {
    if (riskScore < 0.4) return 'ALLOW';
    if (riskScore < 0.7) return 'WARNING';
    return 'BLOCK';
  }

  String _getRiskLevel(double riskScore) {
    if (riskScore < 0.3) return 'LOW';
    if (riskScore < 0.6) return 'MODERATE';
    return 'HIGH';
  }

  String _getTrustTier(int score) {
    if (score >= 95) return 'Platinum';
    if (score >= 85) return 'Gold';
    if (score >= 70) return 'Silver';
    return 'Bronze';
  }
}
