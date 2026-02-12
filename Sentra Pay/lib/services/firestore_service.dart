import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore Database Service
/// Handles all database operations for transactions, fraud reports, and user data
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== TRANSACTION OPERATIONS ==========

  /// Save transaction to Firestore
  Future<String> saveTransaction({
    required String userId,
    required String recipientVPA,
    required String recipientName,
    required double amount,
    required double riskScore,
    required String riskLevel,
    required String decision,
    required Map<String, dynamic> riskBreakdown,
    required List<String> analysisFactors,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('transactions').add({
        'userId': userId,
        'recipientVPA': recipientVPA,
        'recipientName': recipientName,
        'amount': amount,
        'riskScore': riskScore,
        'riskLevel': riskLevel,
        'decision': decision,
        'riskBreakdown': riskBreakdown,
        'analysisFactors': analysisFactors,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      return docRef.id;
    } catch (e) {
      print('Error saving transaction: $e');
      rethrow;
    }
  }

  /// Get user transaction history (stream for real-time updates)
  Stream<List<Map<String, dynamic>>> getTransactionHistoryStream(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get user transaction history (one-time fetch)
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  /// Get transaction count for user
  Future<int> getTransactionCount(String userId) async {
    try {
      AggregateQuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }

  /// Calculate user's average transaction amount
  Future<double> getAverageTransactionAmount(String userId) async {
    try {
      var transactions = await getTransactionHistory(userId, limit: 20);
      if (transactions.isEmpty) return 0.0;

      double total = 0;
      for (var txn in transactions) {
        total += (txn['amount'] as num).toDouble();
      }
      return total / transactions.length;
    } catch (e) {
      print('Error calculating average amount: $e');
      return 0.0;
    }
  }

  // ========== FRAUD REPORT OPERATIONS ==========

  /// Report a VPA as fraudulent
  Future<void> reportFraud({
    required String recipientVPA,
    required String reportedByUserId,
    String? reason,
  }) async {
    try {
      var reportDoc = _firestore.collection('fraudReports').doc(recipientVPA);
      var doc = await reportDoc.get();

      if (doc.exists) {
        var reportedBy = List<String>.from(doc.data()?['reportedBy'] ?? []);
        
        // Don't allow duplicate reports from same user
        if (!reportedBy.contains(reportedByUserId)) {
          await reportDoc.update({
            'reportCount': FieldValue.increment(1),
            'lastReported': FieldValue.serverTimestamp(),
            'reportedBy': FieldValue.arrayUnion([reportedByUserId]),
          });
        }
      } else {
        await reportDoc.set({
          'recipientVPA': recipientVPA,
          'reportCount': 1,
          'reportedBy': [reportedByUserId],
          'firstReported': FieldValue.serverTimestamp(),
          'lastReported': FieldValue.serverTimestamp(),
          'reasons': reason != null ? [reason] : [],
        });
      }
    } catch (e) {
      print('Error reporting fraud: $e');
      rethrow;
    }
  }

  /// Get fraud report count for a VPA
  Future<Map<String, dynamic>> getFraudReport(String recipientVPA) async {
    try {
      var doc = await _firestore.collection('fraudReports').doc(recipientVPA).get();
      
      if (doc.exists) {
        var data = doc.data()!;
        return {
          'reportCount': data['reportCount'] ?? 0,
          'lastReported': data['lastReported'],
          'reportedBy': List<String>.from(data['reportedBy'] ?? []),
        };
      }
      
      return {
        'reportCount': 0,
        'lastReported': null,
        'reportedBy': [],
      };
    } catch (e) {
      print('Error getting fraud report: $e');
      return {
        'reportCount': 0,
        'lastReported': null,
        'reportedBy': [],
      };
    }
  }

  /// Check if VPA has been reported multiple times
  Future<bool> isHighlyReported(String recipientVPA, {int threshold = 5}) async {
    var report = await getFraudReport(recipientVPA);
    return (report['reportCount'] as int) >= threshold;
  }

  // ========== USER COMMON VPAs ==========

  /// Add VPA to user's common recipients list
  Future<void> addCommonVPA(String userId, String vpa) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'commonVPAs': FieldValue.arrayUnion([vpa]),
      });
    } catch (e) {
      print('Error adding common VPA: $e');
    }
  }

  /// Get user's common VPAs
  Future<List<String>> getCommonVPAs(String userId) async {
    try {
      var doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return List<String>.from(doc.data()?['commonVPAs'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting common VPAs: $e');
      return [];
    }
  }

  // ========== ANALYTICS ==========

  /// Get risk trend data (last N transactions)
  Future<List<Map<String, dynamic>>> getRiskTrend(String userId, {int limit = 10}) async {
    try {
      var transactions = await getTransactionHistory(userId, limit: limit);
      return transactions.map((txn) => {
        'riskScore': txn['riskScore'],
        'timestamp': txn['timestamp'],
        'amount': txn['amount'],
      }).toList();
    } catch (e) {
      print('Error getting risk trend: $e');
      return [];
    }
  }

  /// Calculate user's risk exposure change
  Future<double> getRiskExposureChange(String userId) async {
    try {
      var trend = await getRiskTrend(userId, limit: 20);
      if (trend.length < 2) return 0.0;

      // Compare recent 5 vs previous 5
      var recentRisk = trend.take(5).fold<double>(0.0, (sum, txn) => sum + (txn['riskScore'] as num).toDouble()) / 5;
      var previousRisk = trend.skip(5).take(5).fold<double>(0.0, (sum, txn) => sum + (txn['riskScore'] as num).toDouble()) / 5;

      if (previousRisk == 0) return 0.0;
      return ((recentRisk - previousRisk) / previousRisk) * 100;
    } catch (e) {
      print('Error calculating risk exposure change: $e');
      return 0.0;
    }
  }

  // ========== BATCH OPERATIONS ==========

  /// Clear all user data (for testing/reset)
  Future<void> clearUserData(String userId) async {
    try {
      // Delete all transactions
      var transactions = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in transactions.docs) {
        await doc.reference.delete();
      }

      // Reset user stats
      await _firestore.collection('users').doc(userId).update({
        'totalTransactions': 0,
        'blockedTransactions': 0,
        'successfulTransactions': 0,
        'trustScore': 100,
        'trustTier': 'Platinum',
      });
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }
}
