import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../rides/screens/search_rides_screen.dart';
import '../../rides/screens/ride_detail_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../maps/screens/map_screen_new.dart';
import '../../../widgets/badged_icon.dart';
import '../../../services/database_service.dart';
import '../../../models/booking.dart';

/// Главный экран для пассажира
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with WidgetsBindingObserver {
  int _unreadChatsCount = 0;
  List<Booking> _myBookings = [];
  bool _isLoadingBookings = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUnreadCount();
    _loadMyBookings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateUnreadCount();
      _loadMyBookings();
    }
  }

  void _updateUnreadCount() async {
    // Временная заглушка - в будущем будет реализован метод
    final count = 0; // await ChatService.instance.getUnreadChatsCount();
    if (mounted) {
      setState(() {
        _unreadChatsCount = count;
      });
    }
  }

  Future<void> _loadMyBookings() async {
    setState(() => _isLoadingBookings = true);

    try {
      // В реальном приложении здесь будет ID текущего пользователя (пассажира)
      const currentPassengerId = 'passenger_1';
      print(
        '👤 [PASSENGER_HOME] Загружаем бронирования для пассажира: $currentPassengerId',
      );

      final bookings = await DatabaseService.instance.getPassengerBookings(
        currentPassengerId,
      );
      print('✅ [PASSENGER_HOME] Загружено бронирований: ${bookings.length}');

      if (mounted) {
        setState(() {
          _myBookings = bookings;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      print('❌ [PASSENGER_HOME] Ошибка загрузки бронирований: $e');
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.systemBackground,
        activeColor: CupertinoColors.activeBlue,
        iconSize: 28.0, // Увеличили размер иконок
        items: [
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(_myBookings.length.toString()),
              isLabelVisible: _myBookings.isNotEmpty,
              child: const Icon(CupertinoIcons.ticket),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: BadgedIcon(
              icon: CupertinoIcons.chat_bubble_2,
              badgeCount: _unreadChatsCount,
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: '',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return const MapScreenNew();
              case 1:
                return const SearchRidesScreen();
              case 2:
                return _MyBookingsTab(
                  bookings: _myBookings,
                  isLoading: _isLoadingBookings,
                  onRefresh: _loadMyBookings,
                );
              case 3:
                return const ChatListScreen();
              case 4:
                return const ProfileScreen();
              default:
                return const Center(child: Text('Неизвестная вкладка'));
            }
          },
        );
      },
    );
  }
}

/// Вкладка "Мои бронирования"
class _MyBookingsTab extends StatelessWidget {
  final List<Booking> bookings;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _MyBookingsTab({
    required this.bookings,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Мои поездки'),
        backgroundColor: Colors.transparent,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onRefresh,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : bookings.isEmpty
            ? _buildEmptyState()
            : _buildBookingsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.ticket,
            size: 80,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Пока нет бронирований',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Найдите подходящую поездку и забронируйте место',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            onRefresh();
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking, context);
            }, childCount: bookings.length),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Booking booking, BuildContext context) {
    return GestureDetector(
      onTap: () => _openRideDetails(booking, context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Маршрут
            if (booking.rideFrom != null && booking.rideTo != null) ...[
              Text(
                '${booking.rideFrom} → ${booking.rideTo}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Детали
            Row(
              children: [
                const Icon(
                  CupertinoIcons.person_2,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${booking.seatsBooked} ${_getSeatText(booking.seatsBooked)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const Spacer(),
                Text(
                  '${booking.totalPrice.toInt()} ₽',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Статус
            _buildStatusBadge(booking.status),
          ],
        ),
      ),
    );
  }

  // Метод для открытия деталей поездки
  void _openRideDetails(Booking booking, BuildContext context) async {
    print('🔍 [PASSENGER] Открываем детали поездки: ${booking.rideId}');

    try {
      // Получаем данные поездки по ID
      final ride = await DatabaseService.instance.getRideById(booking.rideId);

      if (ride == null) {
        print('❌ [PASSENGER] Поездка не найдена: ${booking.rideId}');
        return;
      }

      print('✅ [PASSENGER] Поездка найдена, открываем экран деталей');

      // Открываем экран с деталями поездки (внутри текущего таба, нижнее меню останется видимым)
      if (!context.mounted) return;

      await Navigator.of(context, rootNavigator: false).push(
        CupertinoPageRoute(builder: (context) => RideDetailScreen(ride: ride)),
      );

      print('🔄 [PASSENGER] Возврат с экрана деталей, обновляем список');
      // После возврата обновляем список бронирований
      onRefresh();
    } catch (e) {
      print('❌ [PASSENGER] Ошибка при открытии деталей поездки: $e');
    }
  }

  Widget _buildStatusBadge(BookingStatus status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo['color'],
        borderRadius: BorderRadius.circular(6),
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
        return {'text': 'Подтверждено', 'color': CupertinoColors.activeGreen};
      case BookingStatus.inProgress:
        return {'text': 'В пути', 'color': CupertinoColors.systemBlue};
      case BookingStatus.completed:
        return {'text': 'Завершено', 'color': CupertinoColors.systemGrey};
      case BookingStatus.rejected:
        return {'text': 'Отклонено', 'color': CupertinoColors.destructiveRed};
      case BookingStatus.cancelled:
        return {'text': 'Отменено', 'color': CupertinoColors.systemGrey};
    }
  }

  String _getSeatText(int seats) {
    if (seats == 1) return 'место';
    if (seats >= 2 && seats <= 4) return 'места';
    return 'мест';
  }
}
