import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_auth_service.dart';

/// Backend API Service
/// Handles communication with your FastAPI backend for ML-based fraud detection
class BackendApiService {
  // Update this to your backend URL
  static const String baseUrl =
      'http://localhost:8000'; // Change for production

  final FirebaseAuthService _authService = FirebaseAuthService();

  /// Get authorization headers with Firebase ID token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== AUTHENTICATION ENDPOINTS ==========

  /// Register user with backend (after Firebase signup)
  Future<Map<String, dynamic>> registerUserWithBackend({
    required String firebaseUserId,
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/signup'),
            headers: headers,
            body: jsonEncode({
              'firebase_user_id': firebaseUserId,
              'email': email,
              'name': name,
              'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error': 'Backend registration failed: ${response.body}',
        };
      }
    } catch (e) {
      print('Error registering with backend: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ========== FRAUD DETECTION ENDPOINTS ==========

  /// Analyze transaction risk using ML backend
  Future<Map<String, dynamic>> analyzeTransaction({
    required String userId,
    required String recipientVPA,
    required double amount,
    required String deviceId,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final headers = await _getHeaders();

      final requestBody = {
        'user_id': userId,
        'recipient_vpa': recipientVPA,
        'amount': amount,
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'user_profile': ?userProfile,
      };

      print('Sending transaction analysis request to backend...');
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/payment/intent'),
            headers: headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return {
          'success': true,
          'riskScore': data['risk_score'] ?? 0.0,
          'riskLevel': data['risk_level'] ?? 'UNKNOWN',
          'decision': data['decision'] ?? 'BLOCK',
          'riskBreakdown': data['risk_breakdown'] ?? {},
          'analysisFactors': List<String>.from(data['factors'] ?? []),
          'mlPrediction': data['ml_prediction'],
          'backendUsed': true,
        };
      } else {
        print('Backend returned error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Backend analysis failed: ${response.body}',
          'backendUsed': false,
        };
      }
    } catch (e) {
      print('Error analyzing transaction with backend: $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
        'backendUsed': false,
      };
    }
  }

  /// Verify OTP for high-risk transaction
  Future<Map<String, dynamic>> verifyOTP({
    required String transactionId,
    required String otp,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/payment/verify-otp'),
            headers: headers,
            body: jsonEncode({'transaction_id': transactionId, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return {
          'success': true,
          'verified': data['verified'] ?? false,
          'message': data['message'],
        };
      } else {
        return {'success': false, 'error': 'OTP verification failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ========== USER PROFILE ENDPOINTS ==========

  /// Get user profile from backend
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/api/user/$userId/profile'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get user profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/user/$userId/profile'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to update user profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ========== ANALYTICS ENDPOINTS ==========

  /// Get user transaction history from backend
  Future<Map<String, dynamic>> getTransactionHistory(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/user/$userId/transactions'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'transactions': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get transaction history'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get risk analytics
  Future<Map<String, dynamic>> getRiskAnalytics(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/analytics/risk/$userId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true, 'analytics': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to get analytics'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ========== HEALTH CHECK ==========

  /// Check if backend is available
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend not available: $e');
      return false;
    }
  }

  /// Get backend status
  Future<Map<String, dynamic>> getBackendStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return {'available': true, 'status': jsonDecode(response.body)};
      } else {
        return {
          'available': false,
          'error': 'Backend returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }
}
