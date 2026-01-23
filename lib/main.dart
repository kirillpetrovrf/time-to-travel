import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart' as provider;
import 'package:yandex_maps_mapkit/init.dart' as mapkit_init;
import 'theme/app_theme.dart';
import 'theme/theme_manager.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/offline_routes_service.dart';
import 'services/route_management_service.dart';
import 'services/yandex_search_service.dart';
import 'services/auth_storage_service.dart';
import 'services/telegram_auth_api_service.dart';
import 'providers/auth_provider.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'screens/auth_splash_screen.dart';
import 'features/orders/screens/booking_detail_screen.dart';
import 'models/booking.dart';
import 'data/route_initializer.dart';
import 'data/route_groups_initializer.dart';
import 'utils/clean_false_groups.dart';

/// Глобальный NavigatorKey для навигации из уведомлений
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализация SQLite для маршрутов
  try {
    _initializeOfflineRoutesDatabase();
    print('✅ Инициализация SQLite маршрутов запущена в фоне');
  } catch (e) {
    print('⚠️ Ошибка инициализации SQLite маршрутов: $e');
  }
  
  // ✅ Инициализация предустановленных маршрутов ДНР
  try {
    // Выполняем инициализацию в фоне, чтобы не блокировать запуск
    Future.microtask(() async {
      await _initializePredefinedRoutes();
    });
    print('✅ Инициализация предустановленных маршрутов запущена в фоне');
  } catch (e) {
    print('⚠️ Ошибка при запуску инициализации маршрутов: $e');
  }
  
  // ✅ Инициализация предустановленных ГРУПП маршрутов
  try {
    Future.microtask(() async {
      await _initializeRouteGroups();
      // 🧹 Очистка ложных групп после инициализации
      await _cleanFalseGroups();
    });
    print('✅ Инициализация групп маршрутов запущена в фоне');
  } catch (e) {
    print('⚠️ Ошибка при запуску инициализации групп: $e');
  }

  // ✅ КРИТИЧЕСКИ ВАЖНО: Инициализация Yandex MapKit через Flutter Plugin API
  // Нативная инициализация в MainApplication.kt закомментирована,
  // т.к. она несовместима с Flutter Plugin и вызывает SIGSEGV
  try {
    await mapkit_init.initMapkit(
      apiKey: "2f1d6a75-b751-4077-b305-c6abaea0b542",
    );
    print('✅ Yandex MapKit инициализирован через Flutter Plugin API');
    
    // ✅ НОВОЕ: Инициализация YandexSearchService для автокомплита адресов
    // Это решает проблему когда автокомплит не работает в IndividualBookingScreen
    // если пользователь не посетил сначала вкладку с картой
    await YandexSearchService.initialize();
    print('✅ YandexSearchService готов к использованию в любом месте приложения');
  } catch (e) {
    print('❌ Ошибка инициализации MapKit/SearchService: $e');
  }

  runApp(const TimeToTravelApp());
}

/// Инициализация SQLite базы данных для маршрутов
void _initializeOfflineRoutesDatabase() async {
  try {
    // Запускаем в фоне, чтобы не блокировать UI
    Future.microtask(() async {
      // Инициализируем базу данных и добавляем fallback данные если нужно
      await OfflineRoutesService.instance.getAllRoutes();
      
      // Инициализируем RouteManagementService для проверки fallback данных
      await RouteManagementService.instance.getAllRoutes();
      
      print('✅ SQLite база данных маршрутов инициализирована');
    });
  } catch (e) {
    print('❌ Ошибка инициализации SQLite маршрутов: $e');
  }
}

/// ПОЛНАЯ ОЧИСТКА И ЗАГРУЗКА ТОЛЬКО ПОЛЬЗОВАТЕЛЬСКИХ МАРШРУТОВ
Future<void> _initializePredefinedRoutes() async {
  try {
    print('🔄 БЕЗОПАСНАЯ ИНИЦИАЛИЗАЦИЯ - проверяем базовые маршруты без удаления пользовательских');
    
    // БЕЗОПАСНАЯ ИНИЦИАЛИЗАЦИЯ - добавляем только недостающие базовые маршруты
    await RouteInitializer.initializeRoutes();
    
    // Проверяем финальный статус
    final finalStatus = await RouteInitializer.checkInitializationStatus();
    print('🎯 ИНИЦИАЛИЗАЦИЯ ЗАВЕРШЕНА:');
    print('   • Всего маршрутов в базе: ${finalStatus['total_routes_in_db']}');
    print('   • Базовых маршрутов: ${finalStatus['initializer_routes_in_db']}/${finalStatus['initializer_routes_total']} (${finalStatus['initialization_percentage']}%)');
    print('   • ✅ Пользовательские маршруты сохранены!');
    
  } catch (e) {
    print('❌ Ошибка при очистке и загрузке пользовательских маршрутов: $e');
  }
}

/// Инициализация предустановленных групп маршрутов
Future<void> _initializeRouteGroups() async {
  try {
    print('🚀 Инициализация предустановленных групп маршрутов...');
    
    // Инициализируем группы из route_groups_initializer.dart
    await RouteGroupsInitializer.initializeGroups();
    
    print('✅ Группы маршрутов успешно инициализированы');
  } catch (e) {
    print('❌ Ошибка при инициализации групп маршрутов: $e');
  }
}

/// Очистка ложных групп из базы данных
Future<void> _cleanFalseGroups() async {
  try {
    print('🧹 Запуск очистки ложных групп...');
    await CleanFalseGroups.execute();
    print('✅ Очистка ложных групп завершена');
  } catch (e) {
    print('❌ Ошибка при очистке ложных групп: $e');
  }
}

class TimeToTravelApp extends StatelessWidget {
  const TimeToTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeManagerWidget(
      child: provider.ChangeNotifierProvider(
        create: (_) => AuthProvider(
          storage: AuthStorageService(),
          api: TelegramAuthApiService(
            baseUrl: 'https://titotr.ru/api',
          ),
        ),
        child: _TimeToTravelAppContent(),
      ),
    );
  }
}

class _TimeToTravelAppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;

    return CupertinoApp(
      title: 'Time to Travel',
      navigatorKey: navigatorKey, // Добавляем глобальный ключ
      theme: AppTheme.getCurrentTheme(themeManager.currentTheme),
      debugShowCheckedModeBanner: false,
      home: const AuthSplashScreen(), // Используем наш новый Splash с авто-логином
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
          // Удалили MapScreen - возвращаем на главную
          case '/booking-details':
            // Получаем bookingId из аргументов
            final bookingId = settings.arguments as String;
            child = _BookingDetailsLoader(bookingId: bookingId);
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

/// Виджет для загрузки и отображения деталей заказа по ID
class _BookingDetailsLoader extends StatefulWidget {
  final String bookingId;

  const _BookingDetailsLoader({required this.bookingId});

  @override
  State<_BookingDetailsLoader> createState() => _BookingDetailsLoaderState();
}

class _BookingDetailsLoaderState extends State<_BookingDetailsLoader> {
  Booking? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final bookingService = BookingService();
      final bookings = await bookingService.getCurrentClientBookings();

      // Ищем заказ по ID
      final booking = bookings.firstWhere(
        (b) => b.id == widget.bookingId,
        orElse: () => throw Exception('Заказ не найден'),
      );

      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Загрузка...')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_error != null || _booking == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Ошибка')),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Заказ не найден',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                child: const Text('Вернуться'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    return BookingDetailScreen(booking: _booking!);
  }
}
