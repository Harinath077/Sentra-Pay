import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Google OAuth Authentication Service
/// Handles Google Sign-In and backend token verification
class GoogleAuthService {
  // TODO: Replace with your Google Client ID from Google Cloud Console
  static const String _clientId =
      '1081088412253-1d18e7kbs6jep2mtdre3dm6aijtgk6bd.apps.googleusercontent.com';

  // Backend API endpoint
  static const String _backendUrl = 'http://127.0.0.1:8000';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _clientId,
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google
  /// Returns user data and token on success, null on failure
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('Google Sign-In cancelled by user');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      print('✓ Google Sign-In successful: ${googleUser.email}');
      print('Verifying with backend...');

      // Send ID token to backend for verification
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_token': idToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✓ Backend verification successful');
        print('User: ${data['user']}');

        return {
          'success': true,
          'user': data['user'],
          'token': data['access_token'],
          'message': 'Login successful',
        };
      } else {
        throw Exception(
          'Backend verification failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      print('✗ Google Sign-In error: $error');
      return {'success': false, 'error': error.toString()};
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✓ Signed out from Google');
    } catch (error) {
      print('✗ Sign out error: $error');
    }
  }

  /// Check if user is currently signed in
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  /// Get current Google user
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}
