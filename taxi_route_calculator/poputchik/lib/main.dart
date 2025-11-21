import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yandex_maps_mapkit/init.dart' as init;
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'services/auth_service.dart';
import 'models/user_role.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/home/screens/driver_home_screen.dart';
import 'features/home/screens/passenger_home_screen.dart';
import 'widgets/custom_splash_screen.dart';

import 'features/rides/screens/create_ride_screen.dart';
import 'features/rides/screens/search_rides_screen.dart';
import 'features/maps/screens/map_screen_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Yandex MapKit (новая версия 4.24.0-beta)
  await init.initMapkit(apiKey: 'b26f4576-b7c8-43bc-bcd9-e971f52910c2');
  print('✅ [MAIN] Yandex MapKit инициализирован');

  runApp(const TaxiPoputchikApp());
}

class TaxiPoputchikApp extends StatelessWidget {
  const TaxiPoputchikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeManagerWidget(child: _TaxiPoputchikAppContent());
  }
}

class _TaxiPoputchikAppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;

    return CupertinoApp(
      title: 'Такси Попутчик',
      theme: AppTheme.getCurrentTheme(themeManager.currentTheme),
      debugShowCheckedModeBanner: false,
      home: const AuthCheckWidget(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
        '/passenger_home': (context) => const PassengerHomeScreen(),
        '/create-ride': (context) => const CreateRideScreen(),
        '/search-rides': (context) => const SearchRidesScreen(),
        '/basic_map': (context) => const MapScreenNew(),
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
    print('🔍 [AUTH_CHECK] Проверка статуса авторизации...');
    final authService = AuthService.instance;
    final isLoggedIn = await authService.isLoggedIn();

    print('   Авторизован: $isLoggedIn');

    if (mounted) {
      if (isLoggedIn) {
        // Проверяем, выбрана ли роль
        final hasRole = await authService.hasSelectedRole();
        print('   Роль выбрана: $hasRole');

        if (hasRole) {
          // Получаем роль и переходим на соответствующий экран
          final role = await authService.getUserRole();
          print('   Роль пользователя: ${role?.displayName}');

          if (role == UserRole.driver) {
            print('➡️ [AUTH_CHECK] Переход на экран водителя');
            Navigator.pushReplacementNamed(context, '/driver_home');
          } else {
            print('➡️ [AUTH_CHECK] Переход на экран пассажира');
            Navigator.pushReplacementNamed(context, '/passenger_home');
          }
        } else {
          // Роль не выбрана, показываем экран выбора роли
          print('➡️ [AUTH_CHECK] Переход на экран выбора роли');
          Navigator.pushReplacementNamed(context, '/role_selection');
        }
      } else {
        // Пользователь не авторизован, показываем экран авторизации
        print('➡️ [AUTH_CHECK] Переход на экран авторизации');
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем наш кастомный splash screen с правильным закруглением
    return const CustomSplashScreen();
  }
}
