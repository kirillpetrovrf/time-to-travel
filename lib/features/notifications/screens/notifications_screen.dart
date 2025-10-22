import 'package:flutter/cupertino.dart';
import '../../../services/booking_service.dart';
import '../../../models/booking.dart';
import '../../../theme/theme_manager.dart';

/// Экран со списком всех уведомлений
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final bookings = await BookingService().getCurrentClientBookings();

      final notifications = <NotificationItem>[];
      final now = DateTime.now();

      // Создаем список уведомлений для каждого бронирования
      for (final booking in bookings) {
        // Парсим время отправления
        final timeParts = booking.departureTime.split(':');
        final departureDateTime = DateTime(
          booking.departureDate.year,
          booking.departureDate.month,
          booking.departureDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Уведомление за 1 день (в 9:00 утра)
        final reminderDate = departureDateTime.subtract(
          const Duration(days: 1),
        );
        final notification24h = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // 9:00 утра
          0,
        );
        if (notification24h.isAfter(now.subtract(const Duration(days: 7)))) {
          notifications.add(
            NotificationItem(
              booking: booking,
              scheduledTime: notification24h,
              type: NotificationType.reminder24h,
              isDelivered: notification24h.isBefore(now),
            ),
          );
        }

        // Уведомление за 1 час
        final notification1h = departureDateTime.subtract(
          const Duration(hours: 1),
        );
        if (notification1h.isAfter(now.subtract(const Duration(days: 7)))) {
          notifications.add(
            NotificationItem(
              booking: booking,
              scheduledTime: notification1h,
              type: NotificationType.reminder1h,
              isDelivered: notification1h.isBefore(now),
            ),
          );
        }
      }

      // Сортируем по времени (новые сначала)
      notifications.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки уведомлений: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Открыть детали заказа
  void _openBookingDetails(Booking booking) {
    Navigator.of(context).pushNamed('/booking-details', arguments: booking.id);
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Уведомления'),
        backgroundColor: theme.systemBackground,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _notifications.isEmpty
            ? _buildEmptyState(theme)
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationTile(_notifications[index], theme);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.bell_slash,
            size: 80,
            color: theme.secondaryLabel.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Нет уведомлений',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Уведомления появятся после\nсоздания бронирования',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, theme) {
    final booking = notification.booking;
    final isDelivered = notification.isDelivered;

    // Формируем маршрут
    String route = '';
    if (booking.pickupAddress != null && booking.dropoffAddress != null) {
      route = '${booking.pickupAddress} → ${booking.dropoffAddress}';
    } else if (booking.fromStop != null && booking.toStop != null) {
      route = '${booking.fromStop!.name} → ${booking.toStop!.name}';
    } else if (booking.pickupPoint != null) {
      route = 'из ${booking.pickupPoint}';
    }

    // Иконка в зависимости от типа и статуса
    IconData icon;
    Color iconColor;
    String title;

    if (isDelivered) {
      icon = CupertinoIcons.check_mark_circled_solid;
      iconColor = CupertinoColors.systemGreen;
    } else {
      icon = CupertinoIcons.bell_fill;
      iconColor = CupertinoColors.systemBlue;
    }

    if (notification.type == NotificationType.reminder24h) {
      title = isDelivered
          ? 'Отправлено: Поездка завтра'
          : 'Запланировано: Поездка завтра';
    } else {
      title = isDelivered
          ? 'Отправлено: Поездка через час'
          : 'Запланировано: Поездка через час';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDelivered
              ? theme.separator.withOpacity(0.2)
              : CupertinoColors.systemBlue.withOpacity(0.3),
        ),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(
          title,
          style: TextStyle(
            color: theme.label,
            fontWeight: isDelivered ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              route,
              style: TextStyle(color: theme.secondaryLabel, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              isDelivered
                  ? 'Отправлено: ${_formatDateTime(notification.scheduledTime)}'
                  : 'Уведомление придёт: ${_formatDateTime(notification.scheduledTime)}',
              style: TextStyle(
                color: isDelivered
                    ? theme.secondaryLabel.withOpacity(0.7)
                    : CupertinoColors.systemBlue.withOpacity(0.8),
                fontSize: 12,
                fontWeight: isDelivered ? FontWeight.normal : FontWeight.w500,
              ),
            ),
            Text(
              'Поездка: ${_formatDateTime(_getBookingDateTime(booking))}',
              style: TextStyle(
                color: theme.secondaryLabel.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          CupertinoIcons.chevron_forward,
          color: theme.secondaryLabel.withOpacity(0.3),
        ),
        onTap: () => _openBookingDetails(booking),
      ),
    );
  }

  DateTime _getBookingDateTime(Booking booking) {
    final timeParts = booking.departureTime.split(':');
    return DateTime(
      booking.departureDate.year,
      booking.departureDate.month,
      booking.departureDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
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

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month в $hour:$minute';
  }
}

/// Элемент уведомления
class NotificationItem {
  final Booking booking;
  final DateTime scheduledTime;
  final NotificationType type;
  final bool isDelivered;

  NotificationItem({
    required this.booking,
    required this.scheduledTime,
    required this.type,
    required this.isDelivered,
  });
}

/// Тип уведомления
enum NotificationType { reminder24h, reminder1h }
