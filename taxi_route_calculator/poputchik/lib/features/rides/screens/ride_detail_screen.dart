import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/database_service.dart';

class RideDetailScreen extends StatefulWidget {
  final Ride ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  late Ride _currentRide;

  @override
  void initState() {
    super.initState();
    _currentRide = widget.ride;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    print(
      '🔄 [RIDE_DETAIL] Загружаем бронирования для поездки ${_currentRide.id}',
    );
    setState(() => _isLoading = true);

    try {
      final bookings = await _databaseService.getRideBookings(_currentRide.id);
      print('✅ [RIDE_DETAIL] Загружено бронирований: ${bookings.length}');

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [RIDE_DETAIL] Ошибка загрузки бронирований: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          '${_currentRide.fromDistrict} → ${_currentRide.toDistrict}',
        ),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : CustomScrollView(
                slivers: [
                  // Основная информация о поездке
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок со статусом
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_currentRide.fromDistrict} → ${_currentRide.toDistrict}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ),
                              _buildRideStatusBadge(_currentRide.status),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Маршрут
                          _buildInfoRow(
                            CupertinoIcons.location,
                            CupertinoColors.systemGreen,
                            'Откуда',
                            _currentRide.fromAddress,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            CupertinoIcons.location_fill,
                            CupertinoColors.systemRed,
                            'Куда',
                            _currentRide.toAddress,
                          ),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),

                          // Время отправления
                          _buildInfoRow(
                            CupertinoIcons.clock,
                            CupertinoColors.systemBlue,
                            'Время отправления',
                            _formatDateTime(_currentRide.departureTime),
                          ),

                          const SizedBox(height: 12),

                          // Места
                          _buildInfoRow(
                            CupertinoIcons.person_2,
                            CupertinoColors.systemOrange,
                            'Свободных мест',
                            '${_currentRide.availableSeats} из ${_currentRide.totalSeats}',
                          ),

                          const SizedBox(height: 12),

                          // Цена
                          _buildInfoRow(
                            CupertinoIcons.money_dollar,
                            CupertinoColors.activeBlue,
                            'Цена за место',
                            '${_currentRide.pricePerSeat.toInt()} ₽',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Бронирования
                  if (_bookings.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Бронирования (${_bookings.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final booking = _bookings[index];
                          return _buildBookingCard(booking);
                        }, childCount: _bookings.length),
                      ),
                    ),
                  ],

                  // Кнопки действий
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildActionButtons(),
                    ),
                  ),

                  // Отступ снизу
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    Color iconColor,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 2),
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

  Widget _buildRideStatusBadge(RideStatus status) {
    final statusInfo = _getRideStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusInfo['text'],
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  Map<String, dynamic> _getRideStatusInfo(RideStatus status) {
    switch (status) {
      case RideStatus.active:
        return {'text': 'Активна', 'color': CupertinoColors.systemGreen};
      case RideStatus.inProgress:
        return {'text': 'В пути', 'color': CupertinoColors.systemBlue};
      case RideStatus.completed:
        return {'text': 'Завершена', 'color': CupertinoColors.systemGrey};
      case RideStatus.cancelled:
        return {'text': 'Отменена', 'color': CupertinoColors.destructiveRed};
    }
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBookingStatusColor(booking.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: CupertinoColors.activeBlue,
            child: Text(
              booking.passengerName.isNotEmpty
                  ? booking.passengerName[0].toUpperCase()
                  : 'П',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.passengerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.seatsBooked} ${_getSeatText(booking.seatsBooked)} • ${booking.totalPrice.toInt()} ₽',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getBookingStatusColor(booking.status),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getBookingStatusText(booking.status),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_currentRide.status == RideStatus.active) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.activeBlue,
                padding: const EdgeInsets.all(16),
                onPressed: _startRide,
                child: const Text(
                  'Начать поездку',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.destructiveRed,
                padding: const EdgeInsets.all(16),
                onPressed: _cancelRide,
                child: const Text(
                  'Отменить поездку',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_currentRide.status == RideStatus.inProgress) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.activeGreen,
            padding: const EdgeInsets.all(16),
            onPressed: _completeRide,
            child: const Text(
              'Завершить поездку',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return CupertinoColors.systemOrange;
      case BookingStatus.confirmed:
        return CupertinoColors.systemGreen;
      case BookingStatus.inProgress:
        return CupertinoColors.systemBlue;
      case BookingStatus.completed:
        return CupertinoColors.systemGrey;
      case BookingStatus.cancelled:
        return CupertinoColors.systemGrey2;
      case BookingStatus.rejected:
        return CupertinoColors.destructiveRed;
    }
  }

  String _getBookingStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.inProgress:
        return 'В пути';
      case BookingStatus.completed:
        return 'Завершено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.rejected:
        return 'Отклонено';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (date == today) {
      dateStr = 'Сегодня';
    } else if (date == tomorrow) {
      dateStr = 'Завтра';
    } else {
      dateStr = '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    }

    return '$dateStr в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getSeatText(int seats) {
    if (seats == 1) return 'место';
    if (seats >= 2 && seats <= 4) return 'места';
    return 'мест';
  }

  Future<void> _startRide() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.light,
          ),
        ),
        child: CupertinoAlertDialog(
          title: const Text('Начать поездку?'),
          content: const Text('Это изменит статус поездки на "В пути".'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Начать'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      try {
        final updatedRide = _currentRide.copyWith(
          status: RideStatus.inProgress,
          startedAt: DateTime.now(),
        );

        await _databaseService.updateRide(updatedRide);

        setState(() => _currentRide = updatedRide);

        _showSuccessDialog('Поездка начата');
      } catch (e) {
        _showErrorDialog('Ошибка', 'Не удалось начать поездку: $e');
      }
    }
  }

  Future<void> _completeRide() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.light,
          ),
        ),
        child: CupertinoAlertDialog(
          title: const Text('Завершить поездку?'),
          content: const Text('Это изменит статус поездки на "Завершена".'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Завершить'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      try {
        final updatedRide = _currentRide.copyWith(
          status: RideStatus.completed,
          completedAt: DateTime.now(),
        );

        await _databaseService.updateRide(updatedRide);

        setState(() => _currentRide = updatedRide);

        _showSuccessDialog('Поездка завершена');
      } catch (e) {
        _showErrorDialog('Ошибка', 'Не удалось завершить поездку: $e');
      }
    }
  }

  Future<void> _cancelRide() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.light,
          ),
        ),
        child: CupertinoAlertDialog(
          title: const Text('Отменить поездку?'),
          content: const Text(
            'Это действие нельзя будет отменить. Все бронирования будут аннулированы.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Не отменять'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Отменить'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      try {
        final updatedRide = _currentRide.copyWith(status: RideStatus.cancelled);

        await _databaseService.updateRide(updatedRide);

        setState(() => _currentRide = updatedRide);

        _showSuccessDialog('Поездка отменена');
      } catch (e) {
        _showErrorDialog('Ошибка', 'Не удалось отменить поездку: $e');
      }
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.light,
          ),
        ),
        child: CupertinoAlertDialog(
          title: const Text('Успешно'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Theme(
        data: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.light,
          ),
        ),
        child: CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
