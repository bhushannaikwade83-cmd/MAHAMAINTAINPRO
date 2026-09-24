import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSession());
  }

  Future<void> _resolveSession() async {
    final authState = ref.read(firebaseAuthStateProvider);
    final firebaseUser = authState.valueOrNull;
    if (firebaseUser == null) return;

    ref.read(currentAppUserProvider.notifier).setLoading();
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        ref
            .read(currentAppUserProvider.notifier)
            .setUser(AppUser.fromFirestore(doc.data()!, firebaseUser.uid));
      }
    } catch (e, st) {
      ref.read(currentAppUserProvider.notifier).setError(e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-run resolution whenever Firebase's auth stream settles.
    ref.listen(firebaseAuthStateProvider, (previous, next) {
      if (next.hasValue) _resolveSession();
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apartment_rounded, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
