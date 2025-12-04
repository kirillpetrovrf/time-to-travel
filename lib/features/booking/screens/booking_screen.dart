import 'package:flutter/cupertino.dart';
import '../../../models/user.dart';
import '../../../models/route_stop.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_navigation_bar.dart';
import '../../admin/screens/admin_panel_screen.dart';
import 'group_booking_screen.dart';
import 'individual_booking_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  UserType? _userType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final userType = await AuthService.instance.getUserType();
    setState(() {
      _userType = userType;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: theme.systemBackground,
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_userType == UserType.dispatcher) {
      return _buildDispatcherView(theme);
    } else {
      return _buildClientView(theme);
    }
  }

  Widget _buildClientView(CustomTheme theme) {
    print('� [BOOKING SCREEN] Рендерим BookingScreen (MapKit уже активирован на SplashScreen)');
    
    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      child: Column(
        children: [
          // Кастомный navigationBar с серым фоном
          const CustomNavigationBar(title: 'Забронировать поездку'),
          // Контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Групповая поездка
                  _TripTypeOption(
                    icon: CupertinoIcons.group,
                    title: 'Групповая поездка',
                    description: 'Поделитесь автомобилем с другими пассажирами',
                    price: '2000 ₽',
                    features: [
                      'Фиксированное расписание',
                      'Комфортабельные автомобили',
                      'Опытные водители',
                    ],
                    theme: theme,
                    onTap: () {
                      _navigateToBookingWithoutRoute('group');
                    },
                  ),

                  const SizedBox(height: 16),

                  // Индивидуальная поездка
                  _TripTypeOption(
                    icon: CupertinoIcons.car,
                    title: 'Индивидуальная поездка',
                    description: 'Персональный автомобиль только для вас',
                    price: 'от 8000 ₽',
                    features: [
                      'Гибкое расписание',
                      'Личный водитель',
                      'Возможность остановок по пути',
                    ],
                    theme: theme,
                    onTap: () {
                      _navigateToBookingWithoutRoute('individual');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Метод для навигации без выбранного маршрута
  Future<void> _navigateToBookingWithoutRoute(String tripType) async {
    print(
      '🚀 [НАВИГАЦИЯ] Начало _navigateToBookingWithoutRoute, tripType: $tripType',
    );

    // Открываем экран бронирования БЕЗ fromStop и toStop
    // Пользователь выберет направление на самом экране
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => tripType == 'group'
            ? const GroupBookingScreen() // Без параметров
            : const IndividualBookingScreen(), // Без параметров
      ),
    );

    print('✅ [НАВИГАЦИЯ] Вернулись с экрана бронирования');
  }

  Widget _buildDispatcherView(CustomTheme theme) {
    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      child: Column(
        children: [
          // Кастомный navigationBar с серым фоном
          CustomNavigationBar(
            title: 'Управление поездками',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
              child: Icon(CupertinoIcons.settings, color: theme.primary),
            ),
          ),
          // Контент
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Панель диспетчера',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.label,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Управление поездками и маршрутами',
                    style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _DispatcherCard(
                    icon: CupertinoIcons.plus_circle_fill,
                    title: 'Создать поездку',
                    description:
                        'Добавить новую групповую или индивидуальную поездку',
                    theme: theme,
                    onTap: () {
                      // TODO: Реализовать создание поездки
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatcherCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final CustomTheme theme;
  final VoidCallback onTap;

  const _DispatcherCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.separator),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: theme.tertiaryLabel,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Модальное окно для выбора направления и типа поездки (объединенное)
class _PopularRoutesTripSelectionModal extends StatefulWidget {
  final RouteStop donetsk;
  final RouteStop rostov;
  final Function(RouteStop fromStop, RouteStop toStop, String tripType)
  onSelected;

  const _PopularRoutesTripSelectionModal({
    required this.donetsk,
    required this.rostov,
    required this.onSelected,
  });

  @override
  State<_PopularRoutesTripSelectionModal> createState() =>
      _PopularRoutesTripSelectionModalState();
}

class _PopularRoutesTripSelectionModalState
    extends State<_PopularRoutesTripSelectionModal> {
  int _selectedRouteIndex = 0; // 0 = Донецк → Ростов, 1 = Ростов → Донецк

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.separator)),
            ),
            child: Text(
              'Выберите направление и тип поездки',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.label,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Контент
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Секция выбора направления
                    Text(
                      'Направление',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.label,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Донецк → Ростов
                    _RouteOptionCard(
                      fromStop: widget.donetsk,
                      toStop: widget.rostov,
                      isSelected: _selectedRouteIndex == 0,
                      theme: theme,
                      onTap: () {
                        setState(() {
                          _selectedRouteIndex = 0;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Ростов → Донецк
                    _RouteOptionCard(
                      fromStop: widget.rostov,
                      toStop: widget.donetsk,
                      isSelected: _selectedRouteIndex == 1,
                      theme: theme,
                      onTap: () {
                        setState(() {
                          _selectedRouteIndex = 1;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Секция выбора типа поездки
                    Text(
                      'Тип поездки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.label,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Групповая поездка
                    _TripTypeOption(
                      icon: CupertinoIcons.group,
                      title: 'Групповая поездка',
                      description:
                          'Поделитесь автомобилем с другими пассажирами',
                      price: '2000 ₽',
                      features: [
                        'Фиксированное расписание',
                        'Комфортабельные автомобили',
                        'Опытные водители',
                      ],
                      theme: theme,
                      onTap: () {
                        final fromStop = _selectedRouteIndex == 0
                            ? widget.donetsk
                            : widget.rostov;
                        final toStop = _selectedRouteIndex == 0
                            ? widget.rostov
                            : widget.donetsk;
                        widget.onSelected(fromStop, toStop, 'group');
                      },
                    ),

                    const SizedBox(height: 16),

                    // Индивидуальная поездка
                    _TripTypeOption(
                      icon: CupertinoIcons.car,
                      title: 'Индивидуальная поездка',
                      description: 'Персональный автомобиль только для вас',
                      price: 'от 8000 ₽',
                      features: [
                        'Гибкое расписание',
                        'Личный водитель',
                        'Возможность остановок по пути',
                      ],
                      theme: theme,
                      onTap: () {
                        final fromStop = _selectedRouteIndex == 0
                            ? widget.donetsk
                            : widget.rostov;
                        final toStop = _selectedRouteIndex == 0
                            ? widget.rostov
                            : widget.donetsk;
                        widget.onSelected(fromStop, toStop, 'individual');
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Карточка варианта маршрута
class _RouteOptionCard extends StatelessWidget {
  final RouteStop fromStop;
  final RouteStop toStop;
  final bool isSelected;
  final CustomTheme theme;
  final VoidCallback onTap;

  const _RouteOptionCard({
    required this.fromStop,
    required this.toStop,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.systemRed.withOpacity(0.1)
              : theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.systemRed : theme.separator,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: isSelected ? theme.systemRed : theme.secondaryLabel,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromStop.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_right,
                        size: 16,
                        color: theme.systemRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        toStop.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.label,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '2000 ₽',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.systemRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  final List<String> features;
  final CustomTheme theme;
  final VoidCallback onTap;

  const _TripTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.features,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.separator),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.systemGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
