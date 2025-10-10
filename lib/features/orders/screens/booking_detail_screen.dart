import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/baggage.dart';
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
  late Booking _currentBooking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Заказ #${_currentBooking.id.substring(0, 8)}',
          style: TextStyle(color: theme.label),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: theme.primary),
          onPressed: () => Navigator.of(context).pop('switch_to_orders'),
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
              _buildBaggageCard(theme),
              const SizedBox(height: 16),
              if (_currentBooking.pets.isNotEmpty) ...[
                _buildPetsCard(theme),
                const SizedBox(height: 16),
              ],
              _buildPriceCard(theme),
              const SizedBox(height: 24),
              _buildActionButtons(theme),

              // Отступ снизу для системных кнопок навигации
              const SizedBox(height: 60),
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
            'Создан: ${_formatDate(_currentBooking.createdAt)}',
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
    // Отладочный вывод
    print(
      '🔍 BookingDetail: fromStop = ${_currentBooking.fromStop?.name}, toStop = ${_currentBooking.toStop?.name}',
    );

    // Если есть конкретные остановки, показываем их
    final String directionText;
    if (_currentBooking.fromStop != null && _currentBooking.toStop != null) {
      directionText =
          '${_currentBooking.fromStop!.name} → ${_currentBooking.toStop!.name}';
    } else {
      // Иначе показываем общее направление
      directionText = _currentBooking.direction == Direction.donetskToRostov
          ? 'Донецк → Ростов-на-Дону'
          : 'Ростов-на-Дону → Донецк';
    }

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
              if (_currentBooking.pickupPoint != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Место посадки: ${_currentBooking.pickupPoint}',
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
    final tripTypeText = _currentBooking.tripType == TripType.individual
        ? 'Индивидуальная поездка'
        : 'Групповая поездка';

    return Row(
      children: [
        Icon(
          _currentBooking.tripType == TripType.individual
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
          '${_formatDate(_currentBooking.departureDate)} в ${_currentBooking.departureTime}',
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
            'Количество: ${_currentBooking.passengerCount} ${_getPassengerText(_currentBooking.passengerCount)}',
            style: TextStyle(fontSize: 16, color: theme.label),
          ),
        ],
      ),
    );
  }

  // ========== РАСЧЕТ СТОИМОСТИ БАГАЖА С УЧЕТОМ ПАССАЖИРОВ ==========

  /// Расчет стоимости одного типа багажа с учетом пассажиров
  /// ⚠️ ВНИМАНИЕ: Используется ТОЛЬКО для отображения, НЕ для расчета общей цены!
  /// Реальная цена высчитывается методом _calculateTotalBaggageCost()
  double _calculateBaggageCostForItem(BaggageItem item) {
    // Получаем все багажи
    final allBaggage = _currentBooking.baggage;
    final passengerCount = _currentBooking.passengerCount;

    int totalS = allBaggage
        .where((b) => b.size == BaggageSize.s)
        .fold(0, (sum, b) => sum + b.quantity);
    int totalM = allBaggage
        .where((b) => b.size == BaggageSize.m)
        .fold(0, (sum, b) => sum + b.quantity);
    int totalL = allBaggage
        .where((b) => b.size == BaggageSize.l)
        .fold(0, (sum, b) => sum + b.quantity);

    print(
      '💵 [DETAIL] Расчет для ${item.size.name.toUpperCase()}: всего S=$totalS, M=$totalM, L=$totalL, пассажиров=$passengerCount',
    );

    // ПРАВИЛЬНАЯ ЛОГИКА (как в group_booking_screen.dart):
    // Шаг 1: Распределяем пассажиров на L (по 1 на пассажира)
    int availablePassengers = passengerCount;
    int remainingL = totalL;

    if (remainingL > 0) {
      int passengersWithL = remainingL < availablePassengers
          ? remainingL
          : availablePassengers;
      availablePassengers -= passengersWithL;
      remainingL -= passengersWithL;
      print(
        '💵 [DETAIL] Шаг 1: L ($totalL шт) → $passengersWithL бесплатно, остаток L=$remainingL, пассажиров=$availablePassengers',
      );
    }

    // Шаг 2: Распределяем оставшихся пассажиров на M (по 1 на пассажира)
    int remainingM = totalM;

    if (remainingM > 0 && availablePassengers > 0) {
      int passengersWithM = remainingM < availablePassengers
          ? remainingM
          : availablePassengers;
      availablePassengers -= passengersWithM;
      remainingM -= passengersWithM;
      print(
        '💵 [DETAIL] Шаг 2: M ($totalM шт) → $passengersWithM бесплатно, остаток M=$remainingM, пассажиров=$availablePassengers',
      );
    }

    // Шаг 3: Распределяем S - ЛЮБОЕ количество до лимита бесплатно
    int remainingS = totalS;

    if (remainingS > 0 && availablePassengers > 0) {
      int maxFreeS = availablePassengers * 2;
      int freeS = remainingS < maxFreeS ? remainingS : maxFreeS;
      remainingS -= freeS;
      print(
        '💵 [DETAIL] Шаг 3: S ($totalS шт) → $freeS бесплатно (лимит $maxFreeS), остаток S=$remainingS',
      );
    }

    // Теперь считаем стоимость для КОНКРЕТНОГО item
    if (item.size == BaggageSize.s) {
      if (remainingS == 0) {
        print('💵 [DETAIL] ✅ Все S багажи БЕСПЛАТНЫ (${item.quantity} шт)');
        return 0.0;
      }
      // Есть платные S - считаем пропорционально
      double costPerS = item.pricePerExtraItem;
      double itemCost = remainingS * costPerS;
      print(
        '💵 [DETAIL] ❌ S платные: $remainingS × ${costPerS}₽ = ${itemCost.toStringAsFixed(0)}₽',
      );
      return itemCost;
    }

    if (item.size == BaggageSize.m) {
      if (remainingM == 0) {
        print('💵 [DETAIL] ✅ Все M багажи БЕСПЛАТНЫ (${item.quantity} шт)');
        return 0.0;
      }
      double costPerM = item.pricePerExtraItem;
      double itemCost = remainingM * costPerM;
      print(
        '💵 [DETAIL] ❌ M платные: $remainingM × ${costPerM}₽ = ${itemCost.toStringAsFixed(0)}₽',
      );
      return itemCost;
    }

    if (item.size == BaggageSize.l) {
      if (remainingL == 0) {
        print('💵 [DETAIL] ✅ Все L багажи БЕСПЛАТНЫ (${item.quantity} шт)');
        return 0.0;
      }
      double costPerL = item.pricePerExtraItem;
      double itemCost = remainingL * costPerL;
      print(
        '💵 [DETAIL] ❌ L платные: $remainingL × ${costPerL}₽ = ${itemCost.toStringAsFixed(0)}₽',
      );
      return itemCost;
    }

    // Custom всегда платный
    if (item.size == BaggageSize.custom) {
      double itemCost = item.quantity * item.pricePerExtraItem;
      print(
        '💵 [DETAIL] ❌ Custom платно: ${item.quantity} × ${item.pricePerExtraItem}₽ = ${itemCost.toStringAsFixed(0)}₽',
      );
      return itemCost;
    }

    return 0.0;
  }

  /// Расчет общей стоимости всего багажа с учетом пассажиров
  double _calculateTotalBaggageCost() {
    print('💵 [DETAIL] ========== РАСЧЕТ ОБЩЕЙ СТОИМОСТИ БАГАЖА ==========');
    print(
      '💵 [DETAIL] Количество пассажиров: ${_currentBooking.passengerCount}',
    );
    print(
      '💵 [DETAIL] Бесплатных S багажей: ${_currentBooking.passengerCount * 2}',
    );

    if (_currentBooking.baggage.isEmpty) {
      print('💵 [DETAIL] Багаж не выбран, стоимость: 0₽');
      return 0.0;
    }

    double total = 0.0;
    for (var item in _currentBooking.baggage) {
      final itemCost = _calculateBaggageCostForItem(item);
      total += itemCost;
    }

    print(
      '💵 [DETAIL] ========== ИТОГО БАГАЖ: ${total.toStringAsFixed(0)}₽ ==========',
    );
    return total;
  }

  // ========== КОНЕЦ РАСЧЕТА БАГАЖА ==========

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
          if (_currentBooking.baggage.isEmpty)
            Text(
              'Нет багажа',
              style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
            )
          else
            ..._currentBooking.baggage.map((item) {
              // Используем новую формулу с учетом пассажиров
              final bagCost = _calculateBaggageCostForItem(item);
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
                      bagCost > 0 ? '+${bagCost.toInt()} ₽' : 'Бесплатно',
                      style: TextStyle(
                        fontSize: 16,
                        color: bagCost > 0
                            ? theme.primary
                            : CupertinoColors.systemGreen,
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
          ..._currentBooking.pets.map((pet) {
            // Новая логика: используем categoryDescription вместо breed и size
            String displayText = pet.categoryDescription;

            // Показываем итоговую цену (для over6kg это будет 10000₽ вместо 2000₽)
            final displayCost = pet.requiresIndividualTrip
                ? pet.totalCost
                : pet.cost;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayText,
                          style: TextStyle(fontSize: 16, color: theme.label),
                        ),
                        if (pet.requiresIndividualTrip) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Включая индивидуальный трансфер',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.secondaryLabel,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    pet.cost == 0 ? 'Бесплатно' : '+${displayCost.toInt()} ₽',
                    style: TextStyle(
                      fontSize: 16,
                      color: pet.cost == 0
                          ? CupertinoColors.systemGreen
                          : theme.primary,
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
                '${_currentBooking.totalPrice} ₽',
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
              child: const Text(
                'Отменить заказ',
                style: TextStyle(color: CupertinoColors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Кнопка связи с поддержкой
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemBlue,
            onPressed: _showContactOptions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  CupertinoIcons.phone_fill,
                  color: CupertinoColors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Связаться с поддержкой',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(theme) {
    switch (_currentBooking.status) {
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
    switch (_currentBooking.status) {
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
    return _currentBooking.status == BookingStatus.pending ||
        _currentBooking.status == BookingStatus.confirmed;
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
        await BookingService().cancelBooking(_currentBooking.id);

        // Обновляем локальное состояние
        setState(() {
          _currentBooking = Booking(
            id: _currentBooking.id,
            clientId: _currentBooking.clientId,
            tripType: _currentBooking.tripType,
            direction: _currentBooking.direction,
            departureDate: _currentBooking.departureDate,
            departureTime: _currentBooking.departureTime,
            passengerCount: _currentBooking.passengerCount,
            pickupPoint: _currentBooking.pickupPoint,
            pickupAddress: _currentBooking.pickupAddress,
            dropoffAddress: _currentBooking.dropoffAddress,
            totalPrice: _currentBooking.totalPrice,
            status: BookingStatus.cancelled, // Обновляем статус
            createdAt: _currentBooking.createdAt,
            trackingPoints: _currentBooking.trackingPoints,
            baggage: _currentBooking.baggage,
            pets: _currentBooking.pets,
          );
        });

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
                    Navigator.pop(context); // Закрываем диалог
                    Navigator.pop(
                      context,
                      'cancelled',
                    ); // Возвращаемся к списку заказов
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

  void _showContactOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Связаться с поддержкой'),
        message: const Text('Выберите способ связи'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _makePhoneCall();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  CupertinoIcons.phone_fill,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: 8),
                Text('Позвонить +7 949 499 9329'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _openTelegram();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  CupertinoIcons.chat_bubble_text_fill,
                  color: CupertinoColors.activeBlue,
                ),
                SizedBox(width: 8),
                Text('Написать в Telegram'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUrl = Uri.parse('tel:+79494999329');

    try {
      final bool canLaunch = await canLaunchUrl(phoneUrl);
      if (canLaunch) {
        final bool launched = await launchUrl(
          phoneUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          _showPhoneErrorDialog();
        }
      } else {
        if (mounted) {
          _showPhoneErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showPhoneErrorDialog();
      }
    }
  }

  void _showPhoneErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Телефон'),
        content: const Text('Позвоните нам:\n+7 949 499 9329'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openTelegram() async {
    final Uri telegramUrl = Uri.parse('https://t.me/Time_to_travel_dnr');

    try {
      final bool canLaunch = await canLaunchUrl(telegramUrl);
      if (canLaunch) {
        final bool launched = await launchUrl(
          telegramUrl,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          _showTelegramErrorDialog();
        }
      } else {
        if (mounted) {
          _showTelegramErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showTelegramErrorDialog();
      }
    }
  }

  void _showTelegramErrorDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Telegram'),
        content: const Text('Напишите нам в Telegram:\n@Time_to_travel_dnr'),
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
