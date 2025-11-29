import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/booking.dart';
import '../../../models/trip_type.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';
import 'home_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  User? _currentUser;
  List<Booking> _recentBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.getCurrentUser();
      if (user != null) {
        final bookings = await BookingService().getClientBookings(user.id);
        setState(() {
          _currentUser = user;
          _recentBookings = bookings.take(3).toList(); // Последние 3 заказа
        });
      }
    } catch (e) {
      // Обработка ошибки
      print('Ошибка загрузки данных: $e');
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
        middle: Text('Главная', style: TextStyle(color: theme.label)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loadData,
          child: Icon(CupertinoIcons.refresh, color: theme.primary),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildClientContent(theme),
      ),
    );
  }

  Widget _buildClientContent(theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Приветствие клиента
            _buildClientWelcomeCard(theme),

            const SizedBox(height: 24),

            // Быстрые действия для клиента
            _buildClientQuickActions(theme),

            const SizedBox(height: 24),

            // Последние поездки
            _buildRecentTrips(theme),

            // Отступ снизу для системных кнопок навигации
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildClientWelcomeCard(theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.systemBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_circle,
                color: CupertinoColors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать!',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _currentUser?.name ?? 'Клиент',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                'Всего поездок',
                '${_recentBookings.length}',
                CupertinoIcons.car,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                'Активных',
                '${_getActiveBookingsCount()}',
                CupertinoIcons.time,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.white.withOpacity(0.8), size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: CupertinoColors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getActiveBookingsCount() {
    return _recentBookings
        .where(
          (booking) =>
              booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.confirmed ||
              booking.status == BookingStatus.assigned ||
              booking.status == BookingStatus.inProgress,
        )
        .length;
  }

  Widget _buildClientQuickActions(theme) {
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
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Групповая поездка',
                'Забронировать место в автобусе',
                CupertinoIcons.group,
                CupertinoColors.systemGreen,
                () => _switchToBookingTab(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Индивидуальная',
                'Заказать личный трансфер',
                CupertinoIcons.car_detailed,
                CupertinoColors.systemOrange,
                () => _switchToBookingTab(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToBookingTab() {
    print('🚀 Попытка переключения на вкладку бронирования');
    // Переключаемся на вкладку бронирования (индекс 0 для клиентов)
    final homeScreenState = HomeScreen.homeScreenKey.currentState;
    if (homeScreenState != null) {
      final currentIndex = homeScreenState.currentIndex;
      if (currentIndex != 0) {
        print('✅ HomeScreen найден, переключаемся на таб 0 (бронирование)');
        homeScreenState.switchToTab(0);
      } else {
        print('ℹ️ Уже находимся на экране бронирования');
        // Показываем сообщение что мы уже на экране бронирования
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Информация'),
            content: const Text(
              'Вы уже находитесь на экране бронирования поездки',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } else {
      print('❌ HomeScreen не найден!');
    }
  }

  Widget _buildRecentTrips(theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Последние поездки',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentBookings.isEmpty)
          _buildEmptyTrips(theme)
        else
          ..._recentBookings
              .map((booking) => _buildTripCard(booking, theme))
              .toList(),
      ],
    );
  }

  Widget _buildEmptyTrips(theme) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        print('🔥 Нажатие на пустой блок поездок');
        _switchToBookingTab();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.separator.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              CupertinoIcons.car,
              size: 48,
              color: theme.secondaryLabel.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет поездок',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.secondaryLabel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите чтобы забронировать поездку',
              style: TextStyle(
                fontSize: 14,
                color: theme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Booking booking, theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTripTypeIcon(booking.tripType),
              color: _getStatusColor(booking.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDirectionText(booking.direction),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(booking.departureDate)} • ${booking.departureTime}',
                  style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${booking.totalPrice} ₽',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.label,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы
  IconData _getTripTypeIcon(TripType tripType) {
    switch (tripType) {
      case TripType.group:
        return CupertinoIcons.group;
      case TripType.individual:
        return CupertinoIcons.car_detailed;
    }
  }

  String _getDirectionText(Direction direction) {
    switch (direction) {
      case Direction.donetskToRostov:
        return 'Донецк → Ростов-на-Дону';
      case Direction.rostovToDonetsk:
        return 'Ростов-на-Дону → Донецк';
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает';
      case BookingStatus.confirmed:
        return 'Подтверждён';
      case BookingStatus.assigned:
        return 'Назначен водитель';
      case BookingStatus.inProgress:
        return 'В пути';
      case BookingStatus.completed:
        return 'Завершён';
      case BookingStatus.cancelled:
        return 'Отменён';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return CupertinoColors.systemOrange;
      case BookingStatus.confirmed:
        return CupertinoColors.systemBlue;
      case BookingStatus.assigned:
        return CupertinoColors.systemPurple;
      case BookingStatus.inProgress:
        return CupertinoColors.systemGreen;
      case BookingStatus.completed:
        return CupertinoColors.systemGrey;
      case BookingStatus.cancelled:
        return CupertinoColors.systemRed;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
