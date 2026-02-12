import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Authentication Service
/// Handles user authentication using Firebase Auth
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get ID token for backend API calls
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);

      // Create user profile in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'userId': result.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'trustScore': 100,
        'trustTier': 'Platinum',
        'loginCount': 1,
        'deviceId': '', // Will be updated on first login
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'totalTransactions': 0,
        'blockedTransactions': 0,
        'successfulTransactions': 0,
        'commonVPAs': [], // Initialize empty array for common VPAs
      });

      return {
        'success': true,
        'user': result.user,
        'userId': result.user!.uid,
        'message': 'Account created successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _handleAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('FirebaseAuthService: Attempting signin for $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('FirebaseAuthService: Signin successful for ${result.user!.uid}');
      
      // Update login count and last login time
      try {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'loginCount': FieldValue.increment(1),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('FirebaseAuthService: Updated login stats');
      } catch (updateError) {
        print('FirebaseAuthService: Error updating login stats: $updateError');
        // Continue anyway - login succeeded
      }

      return {
        'success': true,
        'user': result.user,
        'userId': result.user!.uid,
        'message': 'Signed in successfully',
      };
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthService: FirebaseAuthException - Code: ${e.code}, Message: ${e.message}');
      return {
        'success': false,
        'error': _handleAuthError(e),
        'errorCode': e.code,
      };
    } catch (e) {
      print('FirebaseAuthService: Unexpected error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Update user device ID
  Future<void> updateDeviceId(String userId, String deviceId) async {
    await _firestore.collection('users').doc(userId).update({
      'deviceId': deviceId,
    });
  }

  /// Update trust score
  Future<void> updateTrustScore(String userId, int newScore, String tier) async {
    await _firestore.collection('users').doc(userId).update({
      'trustScore': newScore,
      'trustTier': tier,
    });
  }

  /// Update transaction stats
  Future<void> updateTransactionStats(String userId, {
    required bool wasBlocked,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'totalTransactions': FieldValue.increment(1),
      if (wasBlocked)
        'blockedTransactions': FieldValue.increment(1)
      else
        'successfulTransactions': FieldValue.increment(1),
    });
  }

  /// Send password reset email
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _handleAuthError(e),
      };
    }
  }

  /// Handle Firebase Auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get auth state changes stream
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
