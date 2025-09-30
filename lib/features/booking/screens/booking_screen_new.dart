import 'package:flutter/cupertino.dart';
import '../../../models/user.dart';
import '../../../models/route_stop.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
import '../../admin/screens/admin_panel_screen.dart';
import 'route_selection_screen.dart';
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
    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Забронировать поездку',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Заголовок
              Text(
                'Выберите тип маршрута',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.label,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Комфортные поездки по маршруту Донецк ⇄ Ростов-на-Дону',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Популярные маршруты
              _RouteTypeCard(
                icon: CupertinoIcons.star_fill,
                title: 'Популярные маршруты',
                description: 'Готовые маршруты с фиксированными остановками',
                features: [
                  'Донецк → Ростов-на-Дону',
                  'Популярные промежуточные города',
                  'Быстрое бронирование',
                ],
                theme: theme,
                onTap: () => _showRouteSelection('popular'),
              ),

              const SizedBox(height: 16),

              // Свободный маршрут
              _RouteTypeCard(
                icon: CupertinoIcons.location,
                title: 'Свободный маршрут',
                description: 'Выберите любые точки отправления и назначения',
                features: [
                  'Все доступные остановки',
                  'Максимальная гибкость',
                  'Индивидуальная настройка',
                ],
                theme: theme,
                onTap: () => _showRouteSelection('free'),
              ),

              const Spacer(),

              // Информация
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: theme.systemBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Информация о ценах',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Групповые поездки: 2000 ₽ за место\nИндивидуальные поездки: от 8000 ₽',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatcherView(CustomTheme theme) {
    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Управление поездками',
          style: TextStyle(color: theme.label),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const AdminPanelScreen(),
              ),
            );
          },
          child: Icon(CupertinoIcons.settings, color: theme.systemRed),
        ),
      ),
      child: SafeArea(
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

              const SizedBox(height: 16),

              _DispatcherCard(
                icon: CupertinoIcons.list_bullet,
                title: 'Управление заказами',
                description: 'Просмотр и редактирование активных заказов',
                theme: theme,
                onTap: () {
                  // TODO: Перейти на экран управления заказами
                },
              ),

              const SizedBox(height: 16),

              _DispatcherCard(
                icon: CupertinoIcons.car_detailed,
                title: 'Управление автопарком',
                description: 'Добавление и настройка автомобилей',
                theme: theme,
                onTap: () {
                  // TODO: Перейти на экран управления автопарком
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteSelection(String routeType) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => RouteSelectionScreen(
          routeDirection: 'donetsk_to_rostov', // По умолчанию
          onRouteSelected: (fromStop, toStop) {
            _showTripTypeSelection(fromStop, toStop, routeType);
          },
        ),
      ),
    );
  }

  void _showTripTypeSelection(
    RouteStop fromStop,
    RouteStop toStop,
    String routeType,
  ) {
    // Возвращаемся к экрану бронирования и показываем выбор типа поездки
    Navigator.of(context).pop();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _TripTypeSelectionModal(
        fromStop: fromStop,
        toStop: toStop,
        routeType: routeType,
        onTripTypeSelected: (tripType) {
          _navigateToBooking(fromStop, toStop, tripType);
        },
      ),
    );
  }

  void _navigateToBooking(
    RouteStop fromStop,
    RouteStop toStop,
    String tripType,
  ) {
    if (tripType == 'group') {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) =>
              GroupBookingScreen(fromStop: fromStop, toStop: toStop),
        ),
      );
    } else {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) =>
              IndividualBookingScreen(fromStop: fromStop, toStop: toStop),
        ),
      );
    }
  }
}

class _RouteTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final CustomTheme theme;
  final VoidCallback onTap;

  const _RouteTypeCard({
    required this.icon,
    required this.title,
    required this.description,
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
                    color: theme.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.systemRed, size: 24),
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
                Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.tertiaryLabel,
                  size: 20,
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
                          color: theme.systemGreen,
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
                color: theme.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.systemRed, size: 24),
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

class _TripTypeSelectionModal extends StatelessWidget {
  final RouteStop fromStop;
  final RouteStop toStop;
  final String routeType;
  final Function(String) onTripTypeSelected;

  const _TripTypeSelectionModal({
    required this.fromStop,
    required this.toStop,
    required this.routeType,
    required this.onTripTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            child: Column(
              children: [
                Text(
                  'Выберите тип поездки',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.label,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${fromStop.name} → ${toStop.name}',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                ),
              ],
            ),
          ),

          // Опции
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                      Navigator.of(context).pop();
                      onTripTypeSelected('group');
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
                      Navigator.of(context).pop();
                      onTripTypeSelected('individual');
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
                    color: theme.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.systemRed, size: 24),
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
                    color: theme.systemRed,
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
                          color: theme.systemGreen,
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
