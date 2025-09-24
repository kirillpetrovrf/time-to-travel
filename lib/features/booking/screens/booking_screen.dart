import 'package:flutter/cupertino.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';
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
                'Выберите тип поездки',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.label,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Комфортные поездки по маршруту Донецк - Ростов-на-Дону',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Групповая поездка
              _BookingCard(
                icon: CupertinoIcons.group,
                title: 'Групповая поездка',
                description: 'Поделитесь автомобилем с другими пассажирами',
                price: '2000 ₽/место',
                features: [
                  'Фиксированное расписание',
                  'Комфортабельные автомобили',
                  'Опытные водители',
                ],
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const GroupBookingScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Индивидуальный трансфер
              _BookingCard(
                icon: CupertinoIcons.car_detailed,
                title: 'Индивидуальный трансфер',
                description: 'Персональная поездка в удобное время',
                price: '8000 ₽/авто',
                features: [
                  'Выберите удобное время',
                  'Персональный автомобиль',
                  'Доставка до места',
                ],
                theme: theme,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const IndividualBookingScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Информация
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.info_circle, color: theme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Важная информация',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Групповые поездки отправляются в 6:00, 9:00, 13:00 и 16:00. '
                      'Индивидуальный трансфер после 22:00 стоит 10000 ₽.',
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
    return AdminPanelScreen();
  }
}

class _BookingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  final List<String> features;
  final CustomTheme theme;
  final VoidCallback onTap;

  const _BookingCard({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.separator.withOpacity(0.3)),
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
                    fontSize: 16,
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
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 16,
                          color: CupertinoColors.systemGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.secondaryLabel,
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
