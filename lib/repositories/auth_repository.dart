import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/supabase_config.dart';

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
      final response = await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );

      if (response.session != null) {
        _currentPhoneNumber = phoneNumber; // Store phone number for M-PIN
        return const AuthSuccess();
      } else {
        return const AuthError('Verification failed');
      }
    } on AuthException catch (e) {
      return AuthError(e.message);
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

  Future<void> logout() async {
    if (!DEMO_MODE) {
      await _client.auth.signOut();
    }
    _demoUserId = null;
    _demoOtp = null;
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': _currentPhoneNumber,
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
          return const AuthSuccess();
        } else {
          return AuthError(data['error'] ?? 'M-PIN verification failed');
        }
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


  /// Get current logged-in phone number
  String? getCurrentPhoneNumber() {
    return _currentPhoneNumber;
  }

  /// Clear auth state completely
  Future<void> clearAuthState() async {
    _currentPhoneNumber = null;
    _demoUserId = null;
    _demoOtp = null;
  }
}
