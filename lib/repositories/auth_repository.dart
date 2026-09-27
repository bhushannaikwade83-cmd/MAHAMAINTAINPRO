import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/supabase_config.dart';

const String _jwtTokenPrefsKey = 'jwtToken';

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthLoading extends AuthResult {
  const AuthLoading();
}

class AuthRequiresMpin extends AuthResult {
  final String phoneNumber;
  const AuthRequiresMpin(this.phoneNumber);
}

class AuthRequiresProfile extends AuthResult {
  final String phoneNumber;
  const AuthRequiresProfile(this.phoneNumber);
}

class AuthError extends AuthResult {
  final String message;
  const AuthError(this.message);
}

class SupabaseAuthRepository {
  // Demo mode flag - set to false to use real OTP/M-PIN
  static const bool DEMO_MODE = false;
  static const String API_BASE_URL = 'https://digitrixmedia.com/mahamaintainpro/api';

  String? _demoUserId;
  String? _demoOtp;
  String? _currentPhoneNumber; // Store current phone for M-PIN operations

  // Static so any screen can attach the auth header without needing
  // Riverpod `ref` access (most screens here are plain StatefulWidgets).
  static String? _authToken; // JWT token returned by verify-otp.php

  /// Global accessor for the current session's JWT, for screens that
  /// build API requests directly instead of going through this repository.
  static String? get currentToken => _authToken;

  /// Store the JWT in memory and persist it so it survives app restarts.
  /// Call this right after any successful login (OTP or M-PIN).
  static Future<void> setToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_jwtTokenPrefsKey, token);
    } else {
      await prefs.remove(_jwtTokenPrefsKey);
    }
  }

  /// Load the persisted JWT back into memory. Call this at app startup
  /// (e.g. splash screen) before any authenticated API call is made.
  static Future<void> restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_jwtTokenPrefsKey);
  }

  /// Standard headers for authenticated PHP API requests, usable statically.
  static Map<String, String> get staticAuthHeaders => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  final SupabaseClient _client = SupabaseConfig.client;

  Future<AuthResult> sendOtp(String phoneNumber) async {
    _currentPhoneNumber = phoneNumber;

    if (DEMO_MODE) {
      // Check if M-PIN exists for this phone
      final mpinExists = await hasMpin(phoneNumber);

      if (mpinExists) {
        return AuthRequiresMpin(phoneNumber);
      }

      // Generate dummy OTP for demo
      _demoOtp = '123456';
      _demoUserId = phoneNumber;
      return const AuthSuccess();
    }

    try {
      // Check if M-PIN exists for this phone
      final mpinExists = await hasMpin(phoneNumber);

      if (mpinExists) {
        return AuthRequiresMpin(phoneNumber);
      }

      // Use your PHP API for OTP instead of Supabase
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }

      final response = await http.post(
        Uri.parse('$API_BASE_URL/send-otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': cleanPhone}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return const AuthSuccess();
        } else {
          return AuthError(data['message'] ?? 'Failed to send OTP');
        }
      } else {
        return AuthError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return AuthError('Error sending OTP: $e');
    }
  }

  Future<AuthResult> verifyOtp(String phoneNumber, String otp) async {
    if (DEMO_MODE) {
      // In demo mode, accept any 6-digit OTP
      if (otp.length == 6) {
        _currentPhoneNumber = phoneNumber; // Store phone number for M-PIN
        return const AuthSuccess();
      }
      return const AuthError('Please enter a valid 6-digit OTP');
    }

    try {
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }

      final response = await http.post(
        Uri.parse('$API_BASE_URL/verify-otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': cleanPhone, 'otp': otp}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _currentPhoneNumber = cleanPhone; // Store phone number for M-PIN
        await SupabaseAuthRepository.setToken(data['token']); // Persist JWT
        return const AuthSuccess();
      } else {
        return AuthError(data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      return AuthError(e.toString());
    }
  }

  Future<AuthResult> resendOtp(String phoneNumber) async {
    if (DEMO_MODE) {
      _demoOtp = '123456';
      return const AuthSuccess();
    }

    try {
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.length > 10) {
        cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
      }

      final response = await http.post(
        Uri.parse('$API_BASE_URL/send-otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': cleanPhone}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return const AuthSuccess();
        } else {
          return AuthError(data['message'] ?? 'Failed to resend OTP');
        }
      } else {
        return AuthError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return AuthError('Error resending OTP: $e');
    }
  }

  String? getCurrentUserId() {
    if (DEMO_MODE) {
      return _demoUserId ?? 'demo_user_123';
    }
    return _client.auth.currentUser?.id;
  }

  String? getCurrentToken() {
    if (DEMO_MODE) {
      return 'demo_token_xyz';
    }
    return _client.auth.currentSession?.accessToken;
  }

  bool isAuthenticated() {
    if (DEMO_MODE) {
      return _demoUserId != null;
    }
    return _client.auth.currentUser != null;
  }

  String? getDemoOtp() => _demoOtp;

  Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  /// Set M-PIN for current user
  Future<AuthResult> setMpin(String mpin) async {
    if (_currentPhoneNumber == null) {
      return const AuthError('Phone number not found. Please login first.');
    }

    if (DEMO_MODE) {
      // In demo mode, accept 4-digit M-PIN
      if (mpin.length == 4 && mpin.contains(RegExp(r'^[0-9]{4}$'))) {
        return const AuthSuccess();
      }
      return const AuthError('Please enter a valid 4-digit M-PIN');
    }

    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/save-mpin.php'),
        headers: staticAuthHeaders,
        body: jsonEncode({
          'mpin': mpin,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return const AuthSuccess();
        } else {
          return AuthError(data['error'] ?? 'Failed to set M-PIN');
        }
      } else {
        return AuthError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return AuthError('Error setting M-PIN: $e');
    }
  }

  /// Verify M-PIN for user
  Future<AuthResult> verifyMpin(String phoneNumber, String mpin) async {
    if (DEMO_MODE) {
      // In demo mode, accept any 4-digit M-PIN
      if (mpin.length == 4 && mpin.contains(RegExp(r'^[0-9]{4}$'))) {
        _currentPhoneNumber = phoneNumber; // Store phone for session
        return const AuthSuccess();
      }
      return const AuthError('Please enter a valid 4-digit M-PIN');
    }

    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/verify-mpin.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'mpin': mpin,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _currentPhoneNumber = phoneNumber; // Store phone for session
          await SupabaseAuthRepository.setToken(data['token']); // Persist JWT
          return const AuthSuccess();
        } else {
          return AuthError(data['error'] ?? 'M-PIN verification failed');
        }
      } else if (response.statusCode == 429) {
        final data = jsonDecode(response.body);
        return AuthError(data['message'] ?? 'Too many attempts. Please try again later.');
      } else {
        return AuthError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      return AuthError('Error verifying M-PIN: $e');
    }
  }

  /// Check if M-PIN exists for a phone number
  Future<bool> hasMpin(String phoneNumber) async {
    if (DEMO_MODE) {
      // In demo mode, always return false so user sees OTP → M-PIN setup flow
      // Change to true after first M-PIN is set to test M-PIN login flow
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/check-mpin.php?phone_number=$phoneNumber'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if individual profile exists for a phone number
  Future<bool> hasProfile(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/check-individual.php?phone_number=$phoneNumber'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout - clears session and stored data
  Future<void> logout() async {
    if (!DEMO_MODE) {
      await _client.auth.signOut();
    }
    _currentPhoneNumber = null;
    _demoUserId = null;
    _demoOtp = null;
    await SupabaseAuthRepository.setToken(null);
  }

  /// Get current logged-in phone number
  String? getCurrentPhoneNumber() {
    return _currentPhoneNumber;
  }

  /// Get the JWT auth token for authenticated API requests
  String? getAuthToken() {
    return _authToken;
  }

  /// Standard headers for authenticated PHP API requests
  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  /// Clear auth state completely
  Future<void> clearAuthState() async {
    _currentPhoneNumber = null;
    _demoUserId = null;
    _demoOtp = null;
    await SupabaseAuthRepository.setToken(null);
  }
}
