import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/database_service.dart';
import 'ride_detail_screen.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Ride> _rides = [];
  List<Booking> _pendingBookings = [];
  bool _isLoading = true;
  String _selectedTab = 'Мои поездки';

  final List<String> _tabs = ['Мои поездки', 'Заявки на бронирование'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('🔄 [MY_RIDES] Начало загрузки данных...');
    setState(() => _isLoading = true);

    try {
      // В реальном приложении здесь будет ID текущего пользователя (водителя)
      const currentDriverId = 'driver_1';
      print('👤 [MY_RIDES] Загружаем поездки для водителя: $currentDriverId');

      final rides = await _databaseService.getDriverRides(currentDriverId);
      print('✅ [MY_RIDES] Загружено поездок из БД: ${rides.length}');

      if (rides.isNotEmpty) {
        for (var i = 0; i < rides.length; i++) {
          final ride = rides[i];
          print(
            '   [$i] ID: ${ride.id}, ${ride.fromAddress} → ${ride.toAddress}, статус: ${ride.status}, дата: ${ride.departureTime}',
          );
        }
      } else {
        print('   ⚠️ [MY_RIDES] Список поездок пуст!');
      }

      final bookings = await _databaseService.getDriverBookingRequests(
        currentDriverId,
      );
      print(
        '✅ [MY_RIDES] Загружено заявок на бронирование: ${bookings.length}',
      );

      setState(() {
        _rides = rides;
        _pendingBookings = bookings;
        _isLoading = false;
      });

      print('✅ [MY_RIDES] Данные успешно загружены и отображены');
    } catch (e, stackTrace) {
      print('❌ [MY_RIDES] Ошибка при загрузке данных: $e');
      print('   Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      _showErrorDialog('Ошибка загрузки', 'Не удалось загрузить данные: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Мои поездки'),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Переключатель вкладок
            Container(
              padding: const EdgeInsets.all(16),
              child: CupertinoSegmentedControl<String>(
                children: {
                  for (final tab in _tabs)
                    tab: Text(tab, style: const TextStyle(fontSize: 14)),
                },
                onValueChanged: (value) => setState(() => _selectedTab = value),
                groupValue: _selectedTab,
              ),
            ),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _selectedTab == 'Мои поездки'
                  ? _buildRidesTab()
                  : _buildBookingRequestsTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesTab() {
    if (_rides.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.car_detailed,
              size: 64,
              color: CupertinoColors.systemGrey2,
            ),
            SizedBox(height: 16),
            Text(
              'У вас пока нет поездок',
              style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
            ),
            SizedBox(height: 8),
            Text(
              'Создайте первую поездку на вкладке "Создать"',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final ride = _rides[index];
              return _buildRideCard(ride);
            }, childCount: _rides.length),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingRequestsTab() {
    if (_pendingBookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 64,
              color: CupertinoColors.systemGrey2,
            ),
            SizedBox(height: 16),
            Text(
              'Нет новых заявок',
              style: TextStyle(fontSize: 18, color: CupertinoColors.systemGrey),
            ),
            SizedBox(height: 8),
            Text(
              'Заявки на бронирование появятся здесь',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _loadData),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final booking = _pendingBookings[index];
              return _buildBookingRequestCard(booking);
            }, childCount: _pendingBookings.length),
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showRideDetails(ride),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок со статусом
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ride.fromDistrict} → ${ride.toDistrict}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                  _buildRideStatusBadge(ride.status),
                ],
              ),

              const SizedBox(height: 8),

              // Маршрут
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    size: 16,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.fromAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.location_fill,
                    size: 16,
                    color: CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ride.toAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Время и места
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(ride.departureTime),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.person_2,
                    size: 16,
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ride.availableSeats}/${ride.totalSeats} мест',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Цена
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.money_dollar,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${ride.pricePerSeat.toInt()} ₽ за место',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue,
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

  Widget _buildBookingRequestCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemOrange, width: 1),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: CupertinoColors.activeBlue,
                  child: Text(
                    booking.passengerName.isNotEmpty
                        ? booking.passengerName[0]
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
                      Text(
                        'Заявка от ${_formatDateTime(booking.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Новая заявка',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Детали бронирования
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (booking.rideFrom != null && booking.rideTo != null) ...[
                    Text(
                      'Маршрут: ${booking.rideFrom} → ${booking.rideTo}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_2,
                        size: 14,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.seatsBooked} ${_getSeatText(booking.seatsBooked)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        CupertinoIcons.money_dollar,
                        size: 14,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.totalPrice.toInt()} ₽',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                  if (booking.pickupPoint != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Место посадки: ${booking.pickupPoint}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Кнопки действий
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: CupertinoColors.destructiveRed,
                    onPressed: () => _rejectBooking(booking),
                    child: const Text(
                      'Отклонить',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: CupertinoColors.activeGreen,
                    onPressed: () => _confirmBooking(booking),
                    child: const Text(
                      'Принять',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideStatusBadge(RideStatus status) {
    final statusInfo = _getRideStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusInfo['text'],
        style: const TextStyle(
          fontSize: 12,
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

  void _showRideDetails(Ride ride) {
    print('🔍 [MY_RIDES] Открываем детали поездки: ${ride.id}');
    Navigator.of(context, rootNavigator: false)
        .push(
          CupertinoPageRoute(
            builder: (context) => RideDetailScreen(ride: ride),
          ),
        )
        .then((_) {
          // Перезагружаем данные после возврата с экрана деталей
          print('🔄 [MY_RIDES] Возврат с экрана деталей, перезагружаем данные');
          _loadData();
        });
  }

  Future<void> _confirmBooking(Booking booking) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Подтвердить бронирование?'),
        content: Text(
          'Подтвердить бронирование ${booking.passengerName} на ${booking.seatsBooked} ${_getSeatText(booking.seatsBooked)}?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _databaseService.confirmBooking(booking.id);
                await _loadData(); // Перезагружаем данные

                _showSuccessDialog('Бронирование подтверждено');
              } catch (e) {
                _showErrorDialog(
                  'Ошибка',
                  'Не удалось подтвердить бронирование: $e',
                );
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectBooking(Booking booking) async {
    String rejectionReason = '';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Отклонить бронирование?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Отклонить бронирование ${booking.passengerName}?'),
            const SizedBox(height: 8),
            CupertinoTextField(
              placeholder: 'Причина отклонения (необязательно)',
              onChanged: (value) => rejectionReason = value,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _databaseService.rejectBooking(
                  booking.id,
                  rejectionReason.isNotEmpty
                      ? rejectionReason
                      : 'Без указания причины',
                );
                await _loadData(); // Перезагружаем данные

                _showSuccessDialog('Бронирование отклонено');
              } catch (e) {
                _showErrorDialog(
                  'Ошибка',
                  'Не удалось отклонить бронирование: $e',
                );
              }
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно'),
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

class RefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RefreshControl({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}
