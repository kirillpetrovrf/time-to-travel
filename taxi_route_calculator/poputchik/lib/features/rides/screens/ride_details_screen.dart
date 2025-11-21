import 'package:flutter/cupertino.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/database_service.dart';
import '../../chat/screens/chat_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final Ride ride;

  const RideDetailsScreen({super.key, required this.ride});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Детали поездки'),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Карточка водителя
              _buildDriverCard(),
              const SizedBox(height: 16),

              // Маршрут
              _buildRouteCard(),
              const SizedBox(height: 16),

              // Детали поездки
              _buildDetailsCard(),

              const SizedBox(height: 24),

              // Кнопки действий
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Аватар водителя
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  CupertinoColors.systemBlue,
                  CupertinoColors.systemGreen,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                widget.ride.driverName.isNotEmpty
                    ? widget.ride.driverName[0]
                    : 'В',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Информация о водителе
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ride.driverName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.star_fill,
                      size: 16,
                      color: CupertinoColors.systemYellow,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      CupertinoIcons.car_detailed,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Toyota Camry',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Маршрут',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 16),

          // Откуда
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ride.fromDistrict,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    if (widget.ride.fromDetails != null &&
                        widget.ride.fromDetails!.isNotEmpty)
                      Text(
                        widget.ride.fromDetails!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Линия
          Container(
            margin: const EdgeInsets.only(left: 6, top: 8, bottom: 8),
            height: 20,
            width: 2,
            color: CupertinoColors.separator,
          ),

          // Куда
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ride.toDistrict,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    if (widget.ride.toDetails != null &&
                        widget.ride.toDetails!.isNotEmpty)
                      Text(
                        widget.ride.toDetails!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Детали поездки',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 16),

          // Время отправления
          _buildDetailRow(
            CupertinoIcons.clock,
            'Отправление',
            _formatDateTime(widget.ride.departureTime),
            CupertinoColors.systemBlue,
          ),

          const SizedBox(height: 12),

          // Свободные места
          _buildDetailRow(
            CupertinoIcons.person_2,
            'Свободных мест',
            '${widget.ride.availableSeats} из ${widget.ride.totalSeats}',
            CupertinoColors.systemGreen,
          ),

          const SizedBox(height: 12),

          // Цена
          _buildDetailRow(
            CupertinoIcons.money_dollar_circle,
            'Цена за место',
            '${widget.ride.pricePerSeat.toInt()} ₽',
            CupertinoColors.systemOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Кнопка бронирования
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(12),
            onPressed: _isLoading ? null : _bookRide,
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Забронировать место',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Кнопка связаться с водителем
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
            onPressed: _contactDriver,
            child: const Text(
              'Связаться с водителем',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == DateTime(today.year, today.month, today.day)) {
      dateStr = 'Сегодня';
    } else if (date == DateTime(tomorrow.year, tomorrow.month, tomorrow.day)) {
      dateStr = 'Завтра';
    } else {
      dateStr = '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }

    return '$dateStr в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _bookRide() async {
    setState(() => _isLoading = true);

    try {
      // Создаем бронирование
      const currentUserId = 'passenger_1';
      const currentUserName = 'Анна';
      const currentUserPhone = '+7 (999) 123-45-67';
      const seatsToBook = 1;

      final booking = Booking(
        id: _databaseService.generateId(),
        rideId: widget.ride.id,
        passengerId: currentUserId,
        passengerName: currentUserName,
        passengerPhone: currentUserPhone,
        seatsBooked: seatsToBook,
        totalPrice: widget.ride.pricePerSeat * seatsToBook,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        rideFrom: widget.ride.fromAddress,
        rideTo: widget.ride.toAddress,
        rideDriverName: widget.ride.driverName,
        rideDepartureTime: widget.ride.departureTime,
      );

      await _databaseService.createBooking(booking);

      if (mounted) {
        setState(() => _isLoading = false);
        _showBookingSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Ошибка бронирования',
          'Не удалось забронировать место: $e',
        );
      }
    }
  }

  void _contactDriver() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => ChatScreen(ride: widget.ride)),
    );
  }

  void _showBookingSuccess() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно!'),
        content: Text(
          'Место забронировано!\n'
          'Водитель получил уведомление.\n'
          'Ожидайте подтверждения от ${widget.ride.driverName}.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог
              Navigator.pop(context); // Возвращаемся на предыдущий экран
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
