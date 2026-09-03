import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/supabase_config.dart';
import 'repositories/auth_repository.dart';
import 'screens/splash_screen.dart';
import 'services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Hide splash after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return provider_pkg.MultiProvider(
        providers: [
          provider_pkg.ChangeNotifierProvider(create: (_) => CartService()),
        ],
        child: MaterialApp(
          title: 'MahaMaintain Pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: SplashScreen(
            onSplashComplete: () {
              if (mounted) {
                setState(() => _showSplash = false);
              }
            },
          ),
        ),
      );
    }

    final authRepository = ref.watch(authRepositoryProvider);
    final router = AppRouter.createRouter(authRepository);

    return provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp.router(
        title: 'MahaMaintain Pro',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
