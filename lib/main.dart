import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// TODO: Раскомментировать при подключении реального Firebase проекта
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'services/auth_service.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ УСЛОВНАЯ ИНИЦИАЛИЗАЦИЯ Firebase (для совместимости с китайскими телефонами)
  // Попытка инициализировать Firebase, если доступен Google Play Services
  try {
    // TODO: Раскомментировать при подключении реального Firebase проекта
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // print('✅ Firebase успешно инициализирован');
    print('ℹ️ Firebase отключен в коде (раскомментируйте для активации)');
  } catch (e) {
    // ⚠️ Firebase недоступен (китайские телефоны без Google Services)
    // Приложение продолжит работать в OFFLINE режиме на SQLite
    print('⚠️ Firebase недоступен, работаем в offline режиме: $e');
    print(
      'ℹ️ Приложение будет использовать только локальное хранилище (SQLite)',
    );
  }

  // ✅ Yandex MapKit инициализируется автоматически в MainApplication (Android)
  // Не требуется инициализация в Flutter коде

  runApp(const TimeToTravelApp());
}

class TimeToTravelApp extends StatelessWidget {
  const TimeToTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeManagerWidget(child: _TimeToTravelAppContent());
  }
}

class _TimeToTravelAppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;

    return CupertinoApp(
      title: 'Time to Travel',
      theme: AppTheme.getCurrentTheme(themeManager.currentTheme),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), // Заменяем AuthCheckWidget на SplashScreen
      onGenerateRoute: (settings) {
        // Ensure all routes have access to the ThemeManager provider
        Widget child;
        switch (settings.name) {
          case '/auth':
            child = const AuthScreen();
            break;
          case '/home':
            child = HomeScreen();
            break;
          default:
            child = const SplashScreen(); // Заменяем на SplashScreen
        }

        return CupertinoPageRoute(
          builder: (context) => child,
          settings: settings,
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
    );
  }
}

// Виджет для проверки состояния авторизации
class AuthCheckWidget extends StatefulWidget {
  const AuthCheckWidget({super.key});

  @override
  State<AuthCheckWidget> createState() => _AuthCheckWidgetState();
}

class _AuthCheckWidgetState extends State<AuthCheckWidget> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final authService = AuthService.instance;
    final isLoggedIn = await authService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        // Пользователь авторизован, всегда переходим на главный экран
        // Последний экран будет восстановлен внутри HomeScreen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Пользователь не авторизован, показываем экран авторизации
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем загрузочный экран пока проверяем авторизацию
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 20),
            SizedBox(height: 16),
            Text(
              'Загрузка...',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
