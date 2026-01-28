import 'package:flutter/cupertino.dart';
import '../../../models/booking.dart';
import '../../../models/trip_type.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';
import 'booking_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final UserType? userType; // ✅ ДОБАВЛЕНО: принимаем userType из HomeScreen
  
  const OrdersScreen({super.key, this.userType});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  UserType? _userType;

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
        // ✅ ИСПРАВЛЕНО: используем userType из widget (из HomeScreen), а не из user
        final currentUserType = widget.userType ?? user.userType;
        setState(() => _userType = currentUserType);

        print('📥 Загрузка бронирований через OrdersService...');
        
        if (currentUserType == UserType.client) {
          // Загружаем заказы клиента
          final bookings = await BookingService().getClientBookings(user.id);
          setState(() => _bookings = bookings);
        } else {
          // Загружаем все активные заказы для диспетчера
          final bookings = await BookingService().getActiveBookings(
            userType: 'dispatcher', // ✅ ДОБАВЛЕНО: передаём режим диспетчера
          );
          setState(() => _bookings = bookings);
        }
      }
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
      child: Column(
        children: [
          // Кастомный navigationBar с серым фоном
          Container(
            color: theme.secondarySystemBackground, // Серый цвет как TabBar
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          _userType == UserType.dispatcher
                              ? 'Заказы'
                              : 'Мои заказы',
                          style: TextStyle(
                            color: theme.label,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _loadData,
                      child: Icon(
                        CupertinoIcons.refresh,
                        color: theme.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _buildBookingsList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(theme) {
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 64,
              color: theme.secondaryLabel.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _userType == UserType.dispatcher
                  ? 'Нет активных заказов'
                  : 'У вас пока нет заказов',
              style: TextStyle(
                fontSize: 18,
                color: theme.secondaryLabel.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(booking, theme);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, theme) {
    return GestureDetector(
      onTap: () => _openBookingDetail(booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.separator.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${booking.totalPrice} ₽',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: theme.secondaryLabel,
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Номер заказа (если есть orderId, иначе показываем короткий ID)
              Text(
                booking.orderId != null && booking.orderId!.isNotEmpty
                    ? 'Заказ #${booking.orderId}'
                    : 'Заказ #${booking.id.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.secondaryLabel.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _getDirectionText(booking),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: theme.secondaryLabel.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatDate(booking.departureDate)} в ${booking.departureTime}',
                    style: TextStyle(
                      color: theme.secondaryLabel.withOpacity(0.8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    CupertinoIcons.person_2,
                    size: 16,
                    color: theme.secondaryLabel.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Пассажиров: ${booking.passengerCount}',
                    style: TextStyle(
                      color: theme.secondaryLabel.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookingDetail(Booking booking) async {
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => BookingDetailScreen(booking: booking),
      ),
    );

    // Если заказ был отменен, перезагружаем список
    if (result == true && mounted) {
      await _loadData();
    }
  }

  String _getDirectionText(Booking booking) {
    // Если есть конкретные остановки, показываем их
    if (booking.fromStop != null && booking.toStop != null) {
      return '${booking.fromStop!.name} → ${booking.toStop!.name}';
    }

    // Для свободных маршрутов ИЛИ индивидуальных показываем адреса
    // НО только если это НЕ "Не указан" (старые offline заказы)
    if ((booking.tripType == TripType.customRoute ||
         booking.tripType == TripType.individual) &&
        booking.pickupAddress != null &&
        booking.pickupAddress!.isNotEmpty &&
        booking.pickupAddress != 'Не указан' &&
        booking.dropoffAddress != null &&
        booking.dropoffAddress!.isNotEmpty &&
        booking.dropoffAddress != 'Не указан') {
      return '${booking.pickupAddress} → ${booking.dropoffAddress}';
    }

    // Иначе показываем общее направление
    switch (booking.direction) {
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
