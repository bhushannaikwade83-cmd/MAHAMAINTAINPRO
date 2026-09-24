import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../role_access/models/user_role.dart';
import '../models/user_model.dart';

/// Result of triggering phone OTP — the verificationId is needed to
/// confirm the code the user enters on the next screen.
class OtpRequestResult {
  final String verificationId;
  final int? resendToken;
  OtpRequestResult({required this.verificationId, this.resendToken});
}

/// All authentication I/O (Firebase Auth + the `users` Firestore doc)
/// lives here. Screens/providers never call FirebaseAuth directly.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SecureStorageService _secureStorage;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SecureStorageService? secureStorage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? SecureStorageService.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ---------------- Email + Password ----------------

  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    final credential =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _loadOrThrowUserProfile(credential.user!.uid);
  }

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    // New self-registrations default to the lowest-privilege role.
    // A Super Admin/Admin must promote them via the user management screen.
    final newUser = AppUser(
      uid: uid,
      name: name,
      email: email,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(newUser.toFirestore());
    return newUser;
  }

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ---------------- Mobile OTP ----------------

  /// Kicks off phone verification. [onCodeSent] fires once Firebase has
  /// dispatched the SMS; [onAutoVerified] fires on Android auto-retrieval.
  Future<void> requestOtp({
    required String phoneNumber,
    required void Function(OtpRequestResult result) onCodeSent,
    required void Function(AppUser user) onAutoVerified,
    required void Function(FirebaseAuthException error) onError,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final result = await _auth.signInWithCredential(credential);
        final user = await _loadOrCreateUserProfile(result.user!, phoneNumber: phoneNumber);
        onAutoVerified(user);
      },
      verificationFailed: onError,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(OtpRequestResult(verificationId: verificationId, resendToken: resendToken));
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<AppUser> confirmOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    return _loadOrCreateUserProfile(result.user!, phoneNumber: phoneNumber);
  }

  // ---------------- Shared ----------------

  Future<AppUser> _loadOrCreateUserProfile(User firebaseUser, {String? phoneNumber}) async {
    final docRef = _firestore.collection(AppConstants.usersCollection).doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (doc.exists) {
      final appUser = AppUser.fromFirestore(doc.data()!, firebaseUser.uid);
      await _persistSession(appUser);
      return appUser;
    }
    final newUser = AppUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'New User',
      email: firebaseUser.email,
      phone: phoneNumber ?? firebaseUser.phoneNumber,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    await docRef.set(newUser.toFirestore());
    await _persistSession(newUser);
    return newUser;
  }

  Future<AppUser> _loadOrThrowUserProfile(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    if (!doc.exists) {
      throw FirebaseAuthException(
        code: 'user-profile-missing',
        message: 'No profile found for this account. Contact your administrator.',
      );
    }
    final appUser = AppUser.fromFirestore(doc.data()!, uid);
    await _persistSession(appUser);
    return appUser;
  }

  Future<void> _persistSession(AppUser user) async {
    final token = await _auth.currentUser?.getIdToken();
    if (token != null) await _secureStorage.saveAuthToken(token);
    await _secureStorage.saveUserId(user.uid);
    await _secureStorage.saveUserRole(user.role.name);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _secureStorage.clearAll();
  }
}

