import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/fraud_store.dart';
import '../models/receiver_info.dart';

class ApiService {
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://localhost:8000 for Chrome/Web
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://localhost:8000 for Chrome/Web
  // Use http://172.16.124.136:8000 for Physical Device (Same Wi-Fi)
  static const String baseUrl = "http://localhost:8000/api";

  static Future<UserProfile?> signup(String name, String email, String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": name,
          "email": email,
          "phone": phone,
          "password": password
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data contains { ..., "token": "..." }
        // We might need to store token later. For now, just return UserProfile.
        return UserProfile.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        print("Backend Signup Error: ${error['detail']}");
      }
    } catch (e) {
      print("Signup Error: $e (Backend unavailable - using offline mode)");
    }
    
    // Backend unavailable or error - create local offline account
    return _createOfflineUser(name, email, phone);
  }
  
  static Future<UserProfile?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  static Future<RiskAnalysisResult?> analyzeRisk({
    required String receiverUpi,
    required double amount,
    String? userId, // Optional, implies Auth
    String? note,
  }) async {
    try {
      // TODO: Add Authorization header when Token storage is implemented
      final response = await http.post(
        Uri.parse("$baseUrl/payment/intent"),
        headers: {"Content-Type": "application/json"},
        // Note: userId is usually handled by token, but we'll stick to body if backend supports it or ignore it
        // Backend expects: amount, receiver, note, device_id
        body: jsonEncode({
          "amount": amount, // Backend might expect paise if int, but payment.py says float is OK? 
          // Wait, backend model PaymentIntentRequest: val > 0.
          "receiver": receiverUpi,
          "note": note ?? "Transfer",
          "device_id": "DEV-APP-001" 
        }),
      ).timeout(const Duration(seconds: 4));

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
          if (bd['behavior_analysis'] != null) behaviorScore = (bd['behavior_analysis']['score'] ?? 50) / 100.0;
          if (bd['amount_analysis'] != null) amountScore = (bd['amount_analysis']['score'] ?? 50) / 100.0;
          if (bd['receiver_analysis'] != null) receiverScore = (bd['receiver_analysis']['score'] ?? 50) / 100.0;
        }

        return RiskAnalysisResult(
          score: score,
          category: category,
          factors: factors,
          isBlocked: data['action'] == "BLOCK",
          behaviorScore: behaviorScore,
          amountScore: amountScore,
          receiverScore: receiverScore,
          transactionId: data['transaction_id'], // Extract transaction ID from backend
        );
      } else {
        print("Backend Risk Check Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Risk Check Error: $e");
    }
    return null;
  }

  // Check QR Code Risk
  static Future<Map<String, dynamic>?> scanQr(String qrData, {double? amount}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payment/scan-qr"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "qr_data": qrData,
          if (amount != null) "amount": amount,
        }),
      ).timeout(const Duration(seconds: 4));

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
      final response = await http.get(
        Uri.parse("$baseUrl/receiver/validate/$upiId"),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 4));

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
    bool userAcknowledged = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/payment/confirm"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "transaction_id": transactionId,
          "user_acknowledged": userAcknowledged,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Payment Confirmed: ${data['status']}");
        return data;
      } else {
        print("❌ Payment Confirmation Failed: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Payment Confirmation Error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getPaymentStatus({
    required String transactionId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/payment/status/$transactionId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));

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

  // Helper to create offline user when backend is down
  static UserProfile _createOfflineUser(String name, String email, String phone) {
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
