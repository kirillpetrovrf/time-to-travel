import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../services/database_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _selectedStatus = 'Все';

  final List<String> _statusFilters = [
    'Все',
    'Ожидает подтверждения',
    'Подтверждено',
    'В процессе',
    'Завершено',
    'Отменено',
    'Отклонено',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      // В реальном приложении здесь будет ID текущего пользователя
      const currentUserId = 'passenger_1';
      final bookings = await _databaseService.getPassengerBookings(
        currentUserId,
      );

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Ошибка загрузки', 'Не удалось загрузить бронирования');
    }
  }

  List<Booking> get _filteredBookings {
    if (_selectedStatus == 'Все') return _bookings;

    final statusMap = {
      'Ожидает подтверждения': BookingStatus.pending,
      'Подтверждено': BookingStatus.confirmed,
      'В процессе': BookingStatus.inProgress,
      'Завершено': BookingStatus.completed,
      'Отменено': BookingStatus.cancelled,
      'Отклонено': BookingStatus.rejected,
    };

    final targetStatus = statusMap[_selectedStatus];
    return _bookings
        .where((booking) => booking.status == targetStatus)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Мои бронирования'),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Фильтр статусов
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final status = _statusFilters[index];
                  final isSelected = status == _selectedStatus;

                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey6,
                    onPressed: () => setState(() => _selectedStatus = status),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isSelected
                            ? CupertinoColors.white
                            : CupertinoColors.label,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Список бронирований
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : RefreshControl(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _filteredBookings[index];
                          return _buildBookingCard(booking);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: CupertinoColors.systemGrey2,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == 'Все'
                ? 'У вас пока нет бронирований'
                : 'Нет бронирований с таким статусом',
            style: const TextStyle(
              fontSize: 18,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Найдите подходящую поездку на вкладке "Поиск"',
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey2),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
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
        onPressed: () => _showBookingDetails(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с статусом
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.rideDriverName ?? 'Водитель',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),

              const SizedBox(height: 8),

              // Маршрут
              if (booking.rideFrom != null && booking.rideTo != null) ...[
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
                        booking.rideFrom!,
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
                        booking.rideTo!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Время и детали
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    booking.rideDepartureTime != null
                        ? _formatDateTime(booking.rideDepartureTime!)
                        : 'Время не указано',
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
                    '${booking.seatsBooked} ${_getSeatText(booking.seatsBooked)}',
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
                    'Общая стоимость: ${booking.totalPrice.toInt()} ₽',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),

              // Кнопки действий
              if (booking.status == BookingStatus.pending) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: CupertinoColors.destructiveRed,
                        onPressed: () => _cancelBooking(booking),
                        child: const Text(
                          'Отменить',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    final statusInfo = _getStatusInfo(status);
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

  Map<String, dynamic> _getStatusInfo(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return {'text': 'Ожидает', 'color': CupertinoColors.systemOrange};
      case BookingStatus.confirmed:
        return {'text': 'Подтверждено', 'color': CupertinoColors.systemGreen};
      case BookingStatus.inProgress:
        return {'text': 'В пути', 'color': CupertinoColors.systemBlue};
      case BookingStatus.completed:
        return {'text': 'Завершено', 'color': CupertinoColors.systemGrey};
      case BookingStatus.cancelled:
        return {'text': 'Отменено', 'color': CupertinoColors.systemGrey2};
      case BookingStatus.rejected:
        return {'text': 'Отклонено', 'color': CupertinoColors.destructiveRed};
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

  void _showBookingDetails(Booking booking) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Бронирование #${booking.id.substring(0, 8)}'),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Водитель: ${booking.rideDriverName}'),
            if (booking.rideFrom != null) Text('Откуда: ${booking.rideFrom}'),
            if (booking.rideTo != null) Text('Куда: ${booking.rideTo}'),
            Text('Мест забронировано: ${booking.seatsBooked}'),
            Text('Стоимость: ${booking.totalPrice.toInt()} ₽'),
            Text('Статус: ${_getStatusInfo(booking.status)['text']}'),
            Text('Создано: ${_formatDateTime(booking.createdAt)}'),
            if (booking.confirmedAt != null)
              Text('Подтверждено: ${_formatDateTime(booking.confirmedAt!)}'),
            if (booking.rejectedAt != null) ...[
              Text('Отклонено: ${_formatDateTime(booking.rejectedAt!)}'),
              if (booking.rejectionReason != null)
                Text('Причина: ${booking.rejectionReason}'),
            ],
          ],
        ),
        actions: [
          if (booking.status == BookingStatus.pending)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(booking);
              },
              child: const Text(
                'Отменить бронирование',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
            ),
          if (booking.status == BookingStatus.confirmed)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                // Здесь будет функция связи с водителем
                _contactDriver(booking);
              },
              child: const Text('Связаться с водителем'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Отменить бронирование?'),
        content: const Text('Это действие нельзя будет отменить.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Не отменять'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);

              try {
                final updatedBooking = booking.copyWith(
                  status: BookingStatus.cancelled,
                );

                await _databaseService.updateBooking(updatedBooking);
                await _loadBookings(); // Перезагружаем список

                _showSuccessDialog('Бронирование отменено');
              } catch (e) {
                _showErrorDialog('Ошибка', 'Не удалось отменить бронирование');
              }
            },
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }

  void _contactDriver(Booking booking) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Связаться с ${booking.rideDriverName}'),
        content: const Text(
          'Функция чата будет доступна в следующих версиях приложения.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
