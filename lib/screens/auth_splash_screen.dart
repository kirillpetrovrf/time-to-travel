import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../providers/auth_provider.dart';
import '../services/auth_storage_service.dart';
import '../services/telegram_auth_api_service.dart';
import 'auth/telegram_login_screen.dart';
import '../features/home/screens/home_screen.dart';

/// Splash экран с автоматической проверкой авторизации
class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Небольшая задержка для показа splash
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();

    if (!mounted) return;

    // Навигация на основе статуса авторизации
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelegramLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Time to Travel',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Обёртка для провайдера авторизации
class AuthProviderWrapper extends StatelessWidget {
  final Widget child;

  const AuthProviderWrapper({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider(
      create: (_) => AuthProvider(
        storage: AuthStorageService(),
        api: TelegramAuthApiService(
          baseUrl: 'https://titotr.ru/api',  // ✅ HTTPS настроен!
        ),
      ),
      child: child,
    );
  }
}
