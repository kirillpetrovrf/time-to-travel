import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../models/trip_type.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Заказ #${widget.booking.id.substring(0, 8)}',
          style: TextStyle(color: theme.label),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: theme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(theme),
              const SizedBox(height: 16),
              _buildTripInfoCard(theme),
              const SizedBox(height: 16),
              _buildPassengerInfoCard(theme),
              const SizedBox(height: 16),
              if (widget.booking.baggage.isNotEmpty) ...[
                _buildBaggageCard(theme),
                const SizedBox(height: 16),
              ],
              if (widget.booking.pets.isNotEmpty) ...[
                _buildPetsCard(theme),
                const SizedBox(height: 16),
              ],
              _buildPriceCard(theme),
              const SizedBox(height: 24),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(theme) {
    final statusColor = _getStatusColor(theme);
    final statusText = _getStatusText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Создан: ${_formatDate(widget.booking.createdAt)}',
            style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfoCard(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
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
                'Маршрут',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRouteInfo(theme),
          const SizedBox(height: 12),
          Divider(color: theme.separator.withOpacity(0.3)),
          const SizedBox(height: 12),
          _buildTripTypeInfo(theme),
          const SizedBox(height: 12),
          _buildDateTimeInfo(theme),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(theme) {
    final directionText = widget.booking.direction == Direction.donetskToRostov
        ? 'Донецк → Ростов-на-Дону'
        : 'Ростов-на-Дону → Донецк';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                directionText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.label,
                ),
              ),
              if (widget.booking.pickupPoint != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Место посадки: ${widget.booking.pickupPoint}',
                  style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeInfo(theme) {
    final tripTypeText = widget.booking.tripType == TripType.individual
        ? 'Индивидуальная поездка'
        : 'Групповая поездка';

    return Row(
      children: [
        Icon(
          widget.booking.tripType == TripType.individual
              ? CupertinoIcons.car
              : CupertinoIcons.group,
          color: theme.primary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(tripTypeText, style: TextStyle(fontSize: 16, color: theme.label)),
      ],
    );
  }

  Widget _buildDateTimeInfo(theme) {
    return Row(
      children: [
        Icon(CupertinoIcons.time, color: theme.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          '${_formatDate(widget.booking.departureDate)} в ${widget.booking.departureTime}',
          style: TextStyle(fontSize: 16, color: theme.label),
        ),
      ],
    );
  }

  Widget _buildPassengerInfoCard(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.person_2, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Пассажиры',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Количество: ${widget.booking.passengerCount} ${_getPassengerText(widget.booking.passengerCount)}',
            style: TextStyle(fontSize: 16, color: theme.label),
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageCard(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.bag, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Багаж',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.booking.baggage.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.customDescription != null
                        ? '${item.size.name.toUpperCase()} - ${item.customDescription}'
                        : '${item.size.name.toUpperCase()} багаж (${item.quantity} шт.)',
                    style: TextStyle(fontSize: 16, color: theme.label),
                  ),
                  Text(
                    '+${item.calculateCost().toInt()} ₽',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPetsCard(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.paw, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Животные',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.booking.pets.map((pet) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pet.customDescription != null
                        ? '${pet.breed} (${pet.size.name.toUpperCase()}) - ${pet.weight}кг - ${pet.customDescription}'
                        : '${pet.breed} (${pet.size.name.toUpperCase()}) - ${pet.weight}кг',
                    style: TextStyle(fontSize: 16, color: theme.label),
                  ),
                  Text(
                    '+${pet.cost.toInt()} ₽',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriceCard(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.money_dollar, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Стоимость',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Общая стоимость:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
              Text(
                '${widget.booking.totalPrice} ₽',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Оплата при посадке в автомобиль',
            style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(theme) {
    return Column(
      children: [
        // Кнопка отмены (только если заказ можно отменить)
        if (_canCancelBooking()) ...[
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.systemRed,
              onPressed: _showCancelDialog,
              child: const Text('Отменить заказ'),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Кнопка связи с поддержкой
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: theme.primary,
            onPressed: _contactSupport,
            child: const Text('Связаться с поддержкой'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(theme) {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return CupertinoColors.systemOrange;
      case BookingStatus.confirmed:
        return CupertinoColors.systemBlue;
      case BookingStatus.assigned:
        return CupertinoColors.systemPurple;
      case BookingStatus.inProgress:
        return CupertinoColors.systemGreen;
      case BookingStatus.completed:
        return CupertinoColors.systemGreen;
      case BookingStatus.cancelled:
        return CupertinoColors.systemRed;
    }
  }

  String _getStatusText() {
    switch (widget.booking.status) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения';
      case BookingStatus.confirmed:
        return 'Подтвержден';
      case BookingStatus.assigned:
        return 'Назначен водитель';
      case BookingStatus.inProgress:
        return 'В пути';
      case BookingStatus.completed:
        return 'Завершен';
      case BookingStatus.cancelled:
        return 'Отменен';
    }
  }

  bool _canCancelBooking() {
    return widget.booking.status == BookingStatus.pending ||
        widget.booking.status == BookingStatus.confirmed;
  }

  String _getPassengerText(int count) {
    if (count == 1) return 'пассажир';
    if (count < 5) return 'пассажира';
    return 'пассажиров';
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showCancelDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Отмена заказа'),
        content: const Text(
          'Вы уверены, что хотите отменить этот заказ? '
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Отменить заказ'),
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking();
            },
          ),
        ],
      ),
    );
  }

  void _cancelBooking() async {
    // Показываем диалог подтверждения
    final bool? shouldCancel = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Отменить заказ'),
        content: const Text('Вы уверены, что хотите отменить этот заказ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Отменить заказ'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        // Отменяем бронирование через сервис
        await BookingService().cancelBooking(widget.booking.id);

        if (mounted) {
          // Показываем успешное уведомление
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Заказ отменен'),
              content: const Text('Ваш заказ был успешно отменен.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Возвращаемся к списку заказов
                  },
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          // Показываем ошибку
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Ошибка'),
              content: Text('Не удалось отменить заказ: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _contactSupport() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Поддержка'),
        content: const Text(
          'Для связи с поддержкой звоните:\n+7 (900) 000-00-00\n\n'
          'Или напишите в Telegram:\n@time_to_travel_support',
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
}
