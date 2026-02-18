import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/fraud_store.dart';
import '../models/receiver_info.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000/api";
    }
    // Assume Android Emulator for non-web local dev
    return "http://10.0.2.2:8000/api";
  }

  static Future<Map<String, dynamic>?> signup(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/signup"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "full_name": name,
              "email": email,
              "phone": phone,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("Backend Signup Error: ${error['detail']}");
      }
    } catch (e) {
      print("Signup Error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("Backend Login Error: ${error['detail']}");
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> googleLogin(String idToken) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/auth/google-login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"id_token": idToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("Backend Google Login Error: ${error['detail']}");
      }
    } catch (e) {
      print("Google Login Error: $e");
    }
    return null;
  }

  static Future<RiskAnalysisResult?> analyzeRisk({
    required String receiverUpi,
    required double amount,
    String? token,
    String? note,
  }) async {
    try {
      final headers = {"Content-Type": "application/json"};
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/payment/intent"),
            headers: headers,
            // Backend expects: amount, receiver, note, device_id
            body: jsonEncode({
              "amount": amount,
              "receiver": receiverUpi,
              "note": note ?? "Transfer",
              "device_id": "DEV-APP-001",
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Map backend response to Flutter RiskAnalysisResult
        String riskLevel = data['risk_level'] ?? "LOW";
        double score = (data['risk_score'] ?? 0.0).toDouble();

        // Safe extraction of factors
        List<String> factors = [];
        if (data['risk_factors'] != null) {
          factors = (data['risk_factors'] as List)
              .map((f) => f['factor'].toString())
              .toList();
        }

        RiskCategory category;
        if (riskLevel == "HIGH" || riskLevel == "VERY_HIGH") {
          category = RiskCategory.high;
        } else if (riskLevel == "MODERATE" || riskLevel == "MEDIUM") {
          category = RiskCategory.medium;
        } else {
          category = RiskCategory.low;
        }

        // Extract Breakdown scores if available
        double behaviorScore = 0.5;
        double amountScore = 0.5;
        double receiverScore = 0.5;

        if (data['risk_breakdown'] != null) {
          final bd = data['risk_breakdown'];
          if (bd['behavior_analysis'] != null) {
            behaviorScore = (bd['behavior_analysis']['score'] ?? 50) / 100.0;
          }
          if (bd['amount_analysis'] != null) {
            amountScore = (bd['amount_analysis']['score'] ?? 50) / 100.0;
          }
          if (bd['receiver_analysis'] != null) {
            receiverScore = (bd['receiver_analysis']['score'] ?? 50) / 100.0;
          }
        }

        return RiskAnalysisResult(
          score: score,
          category: category,
          factors: factors,
          isBlocked: data['action'] == "BLOCK",
          behaviorScore: behaviorScore,
          amountScore: amountScore,
          receiverScore: receiverScore,
          transactionId:
              data['transaction_id'], // Extract transaction ID from backend
          icon: data['icon'],
          color: data['color'],
          background: data['background'],
          label: data['label'],
        );
      } else {
        print(
          "Backend Risk Check Failed: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Risk Check Error: $e");
    }
    return null;
  }

  // Check QR Code Risk
  static Future<Map<String, dynamic>?> scanQr(
    String qrData, {
    double? amount,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/payment/scan-qr"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"qr_data": qrData, "amount": ?amount}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("QR Scan Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("QR Scan Error: $e");
    }
    return null;
  }

  static Future<ReceiverInfo?> validateReceiver(String upiId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/receiver/validate/$upiId"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReceiverInfo.fromJson(data);
      } else {
        print("Receiver Validation Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Receiver Validation Error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> confirmPayment({
    required String transactionId,
    required String token,
    required double amount,
    required String receiver,
    String? note,
    bool userAcknowledged = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/payment/execute"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "transaction_id": transactionId,
              "user_acknowledged": userAcknowledged,
              "amount": amount,
              "receiver": receiver,
              "note": note ?? "Transfer",
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Payment Executed: ${data['status']}");
        return data;
      } else {
        print("❌ Payment Execution Failed: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Payment Execution Error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getPaymentStatus({
    required String transactionId,
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/payment/status/$transactionId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print("Payment Status Check Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Payment Status Error: $e");
    }
    return null;
  }

  static Future<List<dynamic>> getTransactionHistory(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/payment/history"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("History Fetch Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("History Error: $e");
    }
    return [];
  }

  static Future<void> reportFraud(String receiverUpi) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/receiver/report"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "vpa": receiverUpi,
              "reason": "User reported from app",
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        print("Reported fraud successfully.");
      } else {
        print("Report Failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Report Error: $e");
    }
  }

  // Helper to create offline user when backend is down
  static UserProfile _createOfflineUser(
    String name,
    String email,
    String phone,
  ) {
    return UserProfile(
      userId: 'UID-OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
      securityId: 'SEC-OFFLINE',
      fullName: name,
      email: email.isNotEmpty ? email : '$phone@upi.local',
      mobile: phone.isNotEmpty ? phone : null,
      createdAt: DateTime.now(),
      transactionCount: 0,
      trustScore: 100.0,
      deviceId: 'DEV-OFFLINE',
      loginCount: 1,
      commonVPAs: [],
    );
  }
}
