import 'package:flutter/cupertino.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../../theme/theme_manager.dart';
import '../../booking/screens/booking_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../tracking/screens/tracking_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../admin/screens/admin_panel_screen.dart';
import '../../main_screen.dart'; // Импорт MainScreen (Свободный маршрут)
import 'dispatcher_home_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key ?? homeScreenKey);

  // Глобальный ключ для доступа к состоянию HomeScreen
  static final GlobalKey<_HomeScreenState> homeScreenKey =
      GlobalKey<_HomeScreenState>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserType? _userType;
  int _ordersScreenKey = 0; // Счётчик для обновления экрана заказов

  // НОВОЕ (ТЗ v3.0): Секретный вход диспетчера (7 тапов)
  @override
  void initState() {
    super.initState();
    _loadUserType();
    _restoreLastTab();
  }

  Future<void> _loadUserType() async {
    final userType = await AuthService.instance.getUserType();
    print('🔍 HomeScreen: Загружен тип пользователя: $userType');
    setState(() {
      _userType = userType;
    });
  }

  void _restoreLastTab() async {
    final authService = AuthService.instance;
    final lastScreen = await authService.getLastScreen();
    print('📖 _restoreLastTab: Загружена последняя вкладка: $lastScreen');

    if (lastScreen != null) {
      int tabIndex = 0;

      if (_userType == UserType.dispatcher) {
        switch (lastScreen) {
          case '/home':
            tabIndex = 0;
            break;
          case '/admin':
            tabIndex = 1;
            break;
          case '/orders':
            tabIndex = 2;
            break;
          case '/tracking':
            tabIndex = 3;
            break;
          case '/profile':
            tabIndex = 4;
            break;
        }
      } else {
        // Для клиентов
        switch (lastScreen) {
          case '/custom_route':
            tabIndex = 0; // Свободный маршрут - главный экран
            break;
          case '/booking':
            tabIndex = 1;
            break;
          case '/orders':
            tabIndex = 2;
            break;
          case '/tracking':
            tabIndex = 0; // Совместимость: старое "Отслеживание" → Свободный маршрут
            break;
          case '/profile':
            tabIndex = 3;
            break;
        }
      }

      if (mounted) {
        print('📖 _restoreLastTab: Устанавливаем индекс вкладки: $tabIndex');
        setState(() {
          _currentIndex = tabIndex;
        });
      }
    } else {
      print('📖 _restoreLastTab: Последняя вкладка не найдена');
    }
  }

  void _onTabChanged(int index) async {
    print(
      '📱 _onTabChanged вызван с индексом: $index, текущий: $_currentIndex',
    );

    // Если переключаемся на вкладку заказов, обновляем key
    if ((_userType == UserType.dispatcher && index == 2) ||
        (_userType == UserType.client && index == 2)) {
      _ordersScreenKey++;
    }

    setState(() {
      _currentIndex = index;
    });
    print('📱 Состояние обновлено, новый _currentIndex: $_currentIndex');

    // Сохраняем текущую вкладку
    final authService = AuthService.instance;
    String route = '/home';

    if (_userType == UserType.dispatcher) {
      switch (index) {
        case 0:
          route = '/home';
          break;
        case 1:
          route = '/admin';
          break;
        case 2:
          route = '/orders';
          break;
        case 3:
          route = '/tracking';
          break;
        case 4:
          route = '/profile';
          break;
      }
    } else {
      // Для клиентов
      switch (index) {
        case 0:
          route = '/custom_route';
          break;
        case 1:
          route = '/booking';
          break;
        case 2:
          route = '/orders';
          break;
        case 3:
          route = '/profile';
          break;
      }
    }

    await authService.saveLastScreen(route);
  }

  // Публичный метод для переключения вкладок
  void switchToTab(int index) {
    print('🔄 switchToTab вызван с индексом: $index');
    _onTabChanged(index);
  }

  // Метод для "тихого" переключения вкладки после асинхронной операции
  void switchToTabSilently(int index) {
    print('🔇 switchToTabSilently вызван с индексом: $index');
    // Планируем переключение на следующий кадр
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onTabChanged(index);
      }
    });
  }

  // Геттер для получения текущего индекса
  int get currentIndex => _currentIndex;





  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Stack(
      children: [
        CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: theme.secondarySystemBackground,
            activeColor: theme.primary,
            inactiveColor: theme.secondaryLabel,
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
            iconSize: 24.0, // Размер иконок
            height: 55.0, // Компактная высота панели без текста
            items: _userType == UserType.dispatcher
                ? [
                    // Для диспетчеров: Главная, Админ панель, Заказы, Отслеживание, Профиль
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.home, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.settings, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.list_dash, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.location, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.person, size: 24),
                      label: '',
                    ),
                  ]
                : [
                    // Для клиентов: Свободный маршрут, Бронирование, Мои заказы, Профиль
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.map, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.car, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.list_dash, size: 24),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.person, size: 24),
                      label: '',
                    ),
                  ],
          ),
          tabBuilder: (context, index) {
            if (_userType == UserType.dispatcher) {
              switch (index) {
                case 0:
                  return const DispatcherHomeScreen();
                case 1:
                  return AdminPanelScreen();
                case 2:
                  return OrdersScreen(
                    key: ValueKey('orders_$_ordersScreenKey'),
                  );
                case 3:
                  return const TrackingScreen();
                case 4:
                  return const ProfileScreen();
                default:
                  return const DispatcherHomeScreen();
              }
            } else {
              // Для клиентов: Свободный маршрут, Бронирование, Мои заказы, Профиль
              switch (index) {
                case 0:
                  return const MainScreen(); // Свободный маршрут - ГЛАВНЫЙ!
                case 1:
                  return const BookingScreen(); // Бронирование
                case 2:
                  return OrdersScreen(
                    key: ValueKey('orders_$_ordersScreenKey'),
                  ); // Мои заказы
                case 3:
                  return const ProfileScreen(); // Профиль
                default:
                  return const MainScreen();
              }
            }
          },
        ),
      ],
    );
  }
}

// Главная вкладка
class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.getCurrentUser();
      setState(() => _currentUser = user);
    } catch (e) {
      // Обработка ошибки
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Time to Travel', style: TextStyle(color: theme.label)),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildMainContent(theme),
      ),
    );
  }

  Widget _buildMainContent(theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Приветствие
          _buildWelcomeCard(theme),

          const SizedBox(height: 24),

          // Быстрые действия
          _buildQuickActions(theme),

          const SizedBox(height: 24),

          // Информация о маршруте
          _buildRouteInfo(theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary, theme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Привет, ${_currentUser?.name ?? 'Пользователь'}!',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser?.userType == UserType.dispatcher
                ? 'Управляйте заказами и назначайте водителей'
                : 'Забронируйте поездку в Ростов-на-Дону',
            style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 16),

        if (_currentUser?.userType == UserType.client) ...[
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: CupertinoIcons.group,
                  title: 'Групповая поездка',
                  subtitle: '2000 ₽/место',
                  color: theme.primary,
                  onTap: () {
                    final homeState = context
                        .findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onTabChanged(1);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickActionCard(
                  icon: CupertinoIcons.car_detailed,
                  title: 'Индивидуальный',
                  subtitle: '8000 ₽/авто',
                  color: CupertinoColors.systemOrange,
                  onTap: () {
                    final homeState = context
                        .findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onTabChanged(1);
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          _QuickActionCard(
            icon: CupertinoIcons.doc_text,
            title: 'Все заказы',
            subtitle: 'Управление поездками',
            color: theme.primary,
            onTap: () {
              final homeState = context
                  .findAncestorStateOfType<_HomeScreenState>();
              homeState?._onTabChanged(1);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRouteInfo(theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.location, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Наш маршрут',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: theme.separator.withOpacity(0.3),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Донецк (Центральный автовокзал)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Промежуточные остановки: Макеевка, Харцызск, Иловайск, Кутейниково, Амвросиевка, КПП УСПЕНКА, Матвеев-Курган, Покровское, Таганрог',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ростов-на-Дону (Главный автовокзал)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  color: theme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Групповые поездки: 6:00, 9:00, 13:00, 16:00',
                    style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
