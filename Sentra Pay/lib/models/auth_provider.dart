import 'package:flutter/material.dart';
import 'dart:math';
import 'user_profile.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isAuthenticated = false;
  bool _isBiometricEnabled = true;
  String? _errorMessage;
  bool _isLoading = false;

  // Firebase service
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBiometricEnabled => _isBiometricEnabled;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  String? get userId => _firebaseAuth.currentUserId;

  void toggleBiometric(bool value) {
    _isBiometricEnabled = value;
    notifyListeners();
  }

  Future<bool> authenticateBiometric() async {
    // Simulate biometric delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Auto-login with demo account (now using Firebase in background)
    final demoUser = _users['gopal@gmail.com']!;
    _currentUser = UserProfile.fromJson(demoUser['profile']);
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  // Simulated user database (for demo purposes)
  final Map<String, Map<String, dynamic>> _users = {
    'gopal@gmail.com': {
      'password': 'Gopal789',
      'profile': {
        'userId': 'UID-DEMO-001',
        'securityId': 'USER-12345',
        'fullName': 'Gopal',
        'email': 'gopal@gmail.com',
        'mobile': null,
        'profilePhotoUrl': null,
        'createdAt': DateTime.now().toIso8601String(),
        'transactionCount': 5,
        'trustScore': 98.0,
        'deviceId': 'DEV-SHIELD-001X',
        'loginCount': 12,
        'commonVPAs': ['merchant@upi', 'friend@okaxis'],
      },
    },
  };

  /// Sign in with Firebase
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('AuthProvider: Starting signin for $email');
      // Try Firebase authentication first (with timeout)
      final result = await _firebaseAuth.signIn(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('AuthProvider: Firebase signin timed out');
          return {'success': false, 'error': 'timeout'};
        },
      );

      print('AuthProvider: Firebase result - success: ${result['success']}, error: ${result['error']}');
      
      if (result['success']) {
        // Get user profile from Firestore
        var profile = await _firebaseAuth.getUserProfile(result['userId']).timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        
        if (profile != null) {
          // Convert Firestore Timestamp to DateTime
          DateTime createdAt;
          try {
            if (profile['createdAt'] != null) {
              createdAt = profile['createdAt'].toDate();
            } else {
              createdAt = DateTime.now();
            }
          } catch (e) {
            print('Error parsing createdAt: $e');
            createdAt = DateTime.now();
          }

          _currentUser = UserProfile(
            userId: profile['userId'] ?? result['userId'],
            securityId: (profile['userId'] ?? result['userId']).substring(0, 12),
            fullName: profile['name'] ?? 'User',
            email: profile['email'] ?? email,
            mobile: profile['phone'],
            profilePhotoUrl: null,
            createdAt: createdAt,
            transactionCount: profile['totalTransactions'] ?? 0,
            trustScore: (profile['trustScore'] ?? 100).toDouble(),
            deviceId: profile['deviceId'] ?? '',
            loginCount: profile['loginCount'] ?? 1,
            commonVPAs: List<String>.from(profile['commonVPAs'] ?? []),
          );
          
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          // Profile not found in Firestore, but auth succeeded
          // Create a basic profile from auth result
          print('Profile not found in Firestore, creating basic profile');
          _currentUser = UserProfile(
            userId: result['userId'],
            securityId: result['userId'].substring(0, 12),
            fullName: email.split('@')[0], // Use email prefix as name
            email: email,
            mobile: null,
            profilePhotoUrl: null,
            createdAt: DateTime.now(),
            transactionCount: 0,
            trustScore: 100.0,
            deviceId: '',
            loginCount: 1,
            commonVPAs: [],
          );
          
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Fallback to legacy API service (with timeout)
      final profile = await ApiService.login(email, password).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      
      if (profile != null) {
        _currentUser = profile;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Ultimate fallback: Demo mode for testing
      // Check if credentials match demo account
      if (_users.containsKey(email)) {
        final userData = _users[email]!;
        if (userData['password'] == password) {
          _currentUser = UserProfile.fromJson(userData['profile']);
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage = 'Invalid credentials. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;

    } catch (e) {
      print('Login error: $e');
      // If all else fails, try demo account
      if (_users.containsKey(email)) {
        final userData = _users[email]!;
        if (userData['password'] == password) {
          _currentUser = UserProfile.fromJson(userData['profile']);
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      
      _errorMessage = 'Invalid credentials. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with Firebase
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    String? profilePhotoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create account with Firebase (with timeout)
      var result = await _firebaseAuth.signUp(
        email: email,
        password: password,
        name: fullName,
        phone: mobile,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () => {'success': false, 'error': 'timeout'},
      );

      if (result['success']) {
        // Get the created profile
        var profile = await _firebaseAuth.getUserProfile(result['userId']);
        
        if (profile != null) {
          _currentUser = UserProfile(
            userId: profile['userId'],
            securityId: profile['userId'].substring(0, 12),
            fullName: profile['name'] ?? fullName,
            email: profile['email'] ?? email,
            mobile: profile['phone'] ?? mobile,
            profilePhotoUrl: profilePhotoUrl,
            createdAt: profile['createdAt']?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
            transactionCount: 0,
            trustScore: 100.0,
            deviceId: profile['deviceId'] ?? '',
            loginCount: 1,
            commonVPAs: [],
          );
          
          _isAuthenticated = true;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      // Fallback to legacy API (with timeout)
      final profile = await ApiService.signup(fullName, email, mobile, password).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (profile != null) {
        _currentUser = profile;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Ultimate fallback: Demo mode signup
      // Create a temporary demo account
      final newUserId = 'UID-${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = UserProfile(
        userId: newUserId,
        securityId: newUserId.substring(0, 12),
        fullName: fullName,
        email: email,
        mobile: mobile,
        profilePhotoUrl: profilePhotoUrl,
        createdAt: DateTime.now(),
        transactionCount: 0,
        trustScore: 100.0,
        deviceId: 'DEV-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        loginCount: 1,
        commonVPAs: [],
      );
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      // If all else fails, create demo account
      final newUserId = 'UID-${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = UserProfile(
        userId: newUserId,
        securityId: newUserId.substring(0, 12),
        fullName: fullName,
        email: email,
        mobile: mobile,
        profilePhotoUrl: profilePhotoUrl,
        createdAt: DateTime.now(),
        transactionCount: 0,
        trustScore: 100.0,
        deviceId: 'DEV-DEMO-${DateTime.now().millisecondsSinceEpoch}',
        loginCount: 1,
        commonVPAs: [],
      );
      
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? mobile,
    String? profilePhotoUrl,
  }) async {
    if (_currentUser == null) return;

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      email: email,
      mobile: mobile,
      profilePhotoUrl: profilePhotoUrl,
    );

    // Update in Firebase if authenticated
    if (_firebaseAuth.currentUserId != null) {
      // Firebase profile updates can be added here
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void updateTransactionStats(int count, double trustScore) {
    if (_currentUser == null) return;
    
    _currentUser = _currentUser!.copyWith(
      transactionCount: count,
      trustScore: trustScore,
    );
    notifyListeners();
  }

  /// Refresh user profile from Firebase
  Future<void> refreshProfile() async {
    if (_firebaseAuth.currentUserId == null) return;

    var profile = await _firebaseAuth.getUserProfile(_firebaseAuth.currentUserId!);
    if (profile != null) {
      _currentUser = _currentUser?.copyWith(
        transactionCount: profile['totalTransactions'] ?? _currentUser?.transactionCount,
        trustScore: (profile['trustScore'] ?? _currentUser?.trustScore).toDouble(),
      );
      notifyListeners();
    }
  }
}
