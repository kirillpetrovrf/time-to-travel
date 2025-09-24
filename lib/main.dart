import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'config/map_config.dart';
import 'services/auth_service.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/theme_editor/screens/theme_editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Инициализация карт (если есть API ключ)
  if (MapConfig.hasApiKey) {
    // Здесь будет инициализация Yandex MapKit когда добавим API ключ
  }

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
      home: const AuthCheckWidget(),
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
          case '/theme-editor':
            child = const ThemeEditorScreen();
            break;
          default:
            child = const AuthCheckWidget();
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
