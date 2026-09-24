import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Raw Firebase auth state (logged in / logged out), used by the router
/// redirect logic to decide whether to show the login flow.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The app-level user profile (with role) for the currently signed-in user.
/// This is what screens should read for role-based UI decisions.
final currentAppUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser?>>(
  (ref) => CurrentUserNotifier(),
);

class CurrentUserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  CurrentUserNotifier() : super(const AsyncValue.data(null));

  void setUser(AppUser? user) {
    state = AsyncValue.data(user);
  }

  void setLoading() => state = const AsyncValue.loading();

  void setError(Object error, StackTrace stack) => state = AsyncValue.error(error, stack);

  void clear() => state = const AsyncValue.data(null);
}

/// Drives the email/password login screen.
class EmailAuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final CurrentUserNotifier _currentUser;

  EmailAuthController(this._repo, this._currentUser) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithEmail(email: email, password: password);
      _currentUser.setUser(user);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Sign-in failed', st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerWithEmail(email: email, password: password, name: name);
      _currentUser.setUser(user);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Registration failed', st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final emailAuthControllerProvider =
    StateNotifierProvider<EmailAuthController, AsyncValue<void>>((ref) {
  return EmailAuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(currentAppUserProvider.notifier),
  );
});

/// Drives the mobile OTP screen (request code -> confirm code).
class OtpAuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final CurrentUserNotifier _currentUser;

  String? verificationId;
  String? phoneNumber;

  OtpAuthController(this._repo, this._currentUser) : super(const AsyncValue.data(null));

  Future<void> requestOtp(String phone) async {
    state = const AsyncValue.loading();
    phoneNumber = phone;
    await _repo.requestOtp(
      phoneNumber: phone,
      onCodeSent: (result) {
        verificationId = result.verificationId;
        state = const AsyncValue.data(null);
      },
      onAutoVerified: (user) {
        _currentUser.setUser(user);
        state = const AsyncValue.data(null);
      },
      onError: (e) {
        state = AsyncValue.error(e.message ?? 'Failed to send OTP', StackTrace.current);
      },
    );
  }

  Future<void> confirmOtp(String smsCode) async {
    if (verificationId == null || phoneNumber == null) {
      state = AsyncValue.error('No OTP request in progress', StackTrace.current);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final user = await _repo.confirmOtp(
        verificationId: verificationId!,
        smsCode: smsCode,
        phoneNumber: phoneNumber!,
      );
      _currentUser.setUser(user);
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, st) {
      state = AsyncValue.error(e.message ?? 'Invalid OTP', st);
    }
  }
}

final otpAuthControllerProvider = StateNotifierProvider<OtpAuthController, AsyncValue<void>>(
  (ref) => OtpAuthController(ref.watch(authRepositoryProvider), ref.watch(currentAppUserProvider.notifier)),
);
