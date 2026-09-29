import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/supabase_config.dart';
import 'repositories/auth_repository.dart';
import 'services/cart_service.dart';
import 'services/firebase_service.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // These three don't depend on each other - run them concurrently instead
  // of one after another, so startup only takes as long as the slowest one
  // rather than the sum of all three.
  await Future.wait([
    SupabaseConfig.initialize().catchError((e) => print('Supabase init error: $e')),
    FirebaseService().initialize().catchError((e) => print('Firebase init error: $e')),
    SupabaseAuthRepository.restoreToken(),
  ]);

  runApp(
    const ProviderScope(
      child: MahaMaintainApp(),
    ),
  );
}

final authRepositoryProvider = Provider((ref) => SupabaseAuthRepository());

class MahaMaintainApp extends ConsumerStatefulWidget {
  const MahaMaintainApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MahaMaintainApp> createState() => _MahaMaintainAppState();
}

class _MahaMaintainAppState extends ConsumerState<MahaMaintainApp> {
  late CartService _cartService;

  @override
  void initState() {
    super.initState();
    _cartService = CartService();
    // Load persisted cart from SharedPreferences
    _cartService.loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = ref.watch(authRepositoryProvider);
    final router = AppRouter.createRouter(authRepository);

    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider.value(value: _cartService),
      ],
      child: MaterialApp.router(
        title: 'MahaMaintain Pro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, child) => OfflineBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
