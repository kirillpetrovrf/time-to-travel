import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../rides/screens/create_ride_screen.dart';
import '../../rides/screens/search_rides_screen.dart';
import '../../rides/screens/ride_details_screen.dart';
import '../../rides/screens/my_rides_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../../widgets/badged_icon.dart';
import '../../../services/chat_service.dart';
import '../../../services/database_service.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _unreadChatsCount = 0;
  List<Ride> _completedRides = [];
  List<Booking> _completedBookings = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUnreadCount();
    _loadRideHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Обновляем счетчик при возврате в приложение
    if (state == AppLifecycleState.resumed) {
      _updateUnreadCount();
    }
  }

  void _updateUnreadCount() async {
    final chatService = ChatService.instance;
    final count = await chatService.getTotalUnreadCount();
    if (mounted) {
      setState(() {
        _unreadChatsCount = count;
      });
    }
  }

  void _loadRideHistory() async {
    try {
      setState(() => _isLoadingHistory = true);

      final databaseService = DatabaseService.instance;

      // Загружаем завершенные поездки (ограничиваем до 10 последних)
      final rides = await databaseService.getCompletedRides(limit: 10);

      // Загружаем завершенные бронирования для текущего пользователя
      // В реальном приложении здесь будет ID текущего пользователя
      const currentUserId = 'passenger_1';
      final bookings = await databaseService.getCompletedBookings(
        currentUserId,
        limit: 10,
      );

      // Если истории нет, создаем демо данные
      if (rides.isEmpty && bookings.isEmpty) {
        await databaseService.addDemoRideHistory();
        // Повторно загружаем после создания демо данных
        final newRides = await databaseService.getCompletedRides(limit: 10);
        final newBookings = await databaseService.getCompletedBookings(
          currentUserId,
          limit: 10,
        );

        if (mounted) {
          setState(() {
            _completedRides = newRides;
            _completedBookings = newBookings;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _completedRides = rides;
            _completedBookings = bookings;
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      print('Ошибка при загрузке истории поездок: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: const Color(0xFF007AFF),
        inactiveColor: const Color(0xFF8E8E93),
        backgroundColor: CupertinoColors.systemBackground,
        iconSize: 22.0, // Увеличили до комфортного размера
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Карта',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car_rounded),
            label: 'Найти',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Создать',
          ),
          BottomNavigationBarItem(
            icon: BadgedIcon(
              icon: Icons.chat_bubble_outline,
              badgeCount: _unreadChatsCount,
            ),
            activeIcon: BadgedIcon(
              icon: Icons.chat_bubble_rounded,
              badgeCount: _unreadChatsCount,
            ),
            label: 'Чаты',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt_rounded),
            label: 'Мои поездки',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return MapTab(
              completedRides: _completedRides,
              completedBookings: _completedBookings,
              isLoadingHistory: _isLoadingHistory,
            );
          case 1:
            return const SearchTab();
          case 2:
            return const CreateRideTab();
          case 3:
            return ChatsTab(onChatOpened: _updateUnreadCount);
          case 4:
            return const MyRidesTab();
          default:
            return MapTab(
              completedRides: _completedRides,
              completedBookings: _completedBookings,
              isLoadingHistory: _isLoadingHistory,
            );
        }
      },
    );
  }
}

// Вкладка карты
class MapTab extends StatefulWidget {
  final List<Ride> completedRides;
  final List<Booking> completedBookings;
  final bool isLoadingHistory;

  const MapTab({
    super.key,
    required this.completedRides,
    required this.completedBookings,
    required this.isLoadingHistory,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  // Популярные маршруты с градиентами
  final List<Map<String, dynamic>> _popularRoutes = [
    {
      'title': 'Домой',
      'icon': CupertinoIcons.house_fill,
      'gradient': const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'На работу',
      'icon': CupertinoIcons.building_2_fill,
      'gradient': const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'В спортзал',
      'icon': CupertinoIcons.sportscourt_fill,
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Добавить маршрут',
      'icon': CupertinoIcons.add,
      'gradient': const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  void _navigateToSearch() {
    // Переходим на экран поиска
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SearchRidesScreen()),
    );
  }

  void _navigateToRideDetails(int index) {
    final historyItems = _allHistoryItems;

    if (widget.isLoadingHistory) return;
    if (index >= historyItems.length) return;

    final item = historyItems[index];
    if (item is Ride) {
      // Навигация к деталям поездки
      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => RideDetailsScreen(ride: item)),
      );
    } else if (item is Booking) {
      // Для бронирований нужно сначала получить данные поездки
      _navigateToBookingDetails(item);
    }
  }

  void _navigateToBookingDetails(Booking booking) async {
    try {
      final databaseService = DatabaseService.instance;
      final ride = await databaseService.getRideById(booking.rideId);

      if (ride != null && mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => RideDetailsScreen(ride: ride),
          ),
        );
      }
    } catch (e) {
      print('Ошибка при загрузке данных поездки: $e');
    }
  }

  // Методы для генерации данных истории поездок
  List<Color> _getGradientForIndex(int index) {
    final gradients = [
      [const Color(0xFF4CAF50), const Color(0xFF66BB6A)], // Зеленый
      [const Color(0xFF2196F3), const Color(0xFF42A5F5)], // Синий
      [const Color(0xFFFF9800), const Color(0xFFFFB74D)], // Оранжевый
      [const Color(0xFF9C27B0), const Color(0xFFBA68C8)], // Фиолетовый
    ];
    return gradients[index % gradients.length];
  }

  String _getRouteForIndex(int index) {
    final routes = [
      'Центр → Спальный район',
      'Аэропорт → Центр',
      'Вокзал → Промзона',
      'Университет → Домой',
    ];
    return routes[index % routes.length];
  }

  String _getDateForIndex(int index) {
    final dates = [
      '23 сентября, 14:30',
      '22 сентября, 09:15',
      '21 сентября, 18:45',
      '20 сентября, 12:20',
    ];
    return dates[index % dates.length];
  }

  String _getPriceForIndex(int index) {
    final prices = ['450 ₽', '1200 ₽', '680 ₽', '320 ₽'];
    return prices[index % prices.length];
  }

  // Методы для работы с реальными данными истории
  List<dynamic> get _allHistoryItems {
    final allHistory = <dynamic>[];
    allHistory.addAll(widget.completedRides);
    allHistory.addAll(widget.completedBookings);

    // Сортируем по дате завершения (самые новые сначала)
    allHistory.sort((a, b) {
      DateTime dateA;
      DateTime dateB;

      if (a is Ride) {
        dateA = a.completedAt ?? a.departureTime;
      } else if (a is Booking) {
        dateA = a.rideDepartureTime ?? a.createdAt;
      } else {
        dateA = DateTime.now();
      }

      if (b is Ride) {
        dateB = b.completedAt ?? b.departureTime;
      } else if (b is Booking) {
        dateB = b.rideDepartureTime ?? b.createdAt;
      } else {
        dateB = DateTime.now();
      }

      return dateB.compareTo(dateA);
    });

    return allHistory;
  }

  String _getRouteForHistoryItem(int index) {
    final historyItems = _allHistoryItems;

    if (widget.isLoadingHistory) return 'Загрузка...';
    if (index >= historyItems.length) return _getRouteForIndex(index);

    final item = historyItems[index];
    if (item is Ride) {
      return '${item.fromDistrict} → ${item.toDistrict}';
    } else if (item is Booking) {
      return '${item.rideFrom} → ${item.rideTo}';
    }

    return _getRouteForIndex(index);
  }

  String _getDateForHistoryItem(int index) {
    final historyItems = _allHistoryItems;

    if (widget.isLoadingHistory) return 'Загрузка...';
    if (index >= historyItems.length) return _getDateForIndex(index);

    final item = historyItems[index];
    late DateTime date;

    if (item is Ride) {
      date = item.completedAt ?? item.departureTime;
    } else if (item is Booking) {
      date = item.rideDepartureTime ?? item.createdAt;
    } else {
      return _getDateForIndex(index);
    }

    return '${date.day} ${_getMonthName(date.month)}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPriceForHistoryItem(int index) {
    final historyItems = _allHistoryItems;

    if (widget.isLoadingHistory) return '0 ₽';
    if (index >= historyItems.length) return _getPriceForIndex(index);

    final item = historyItems[index];
    if (item is Ride) {
      return '${(item.pricePerSeat * item.totalSeats).toInt()} ₽';
    } else if (item is Booking) {
      return '${item.totalPrice.toInt()} ₽';
    }

    return _getPriceForIndex(index);
  }

  String _getMonthName(int month) {
    const months = [
      '',
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
    return months[month];
  }

  int get _historyItemsCount {
    if (widget.isLoadingHistory)
      return 4; // Показываем заглушки во время загрузки
    return (_allHistoryItems.length).clamp(
      1,
      4,
    ); // Показываем от 1 до 4 элементов
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Карта',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Приветствие
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Привет, Кирилл!',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Здесь скоро будет карта с живыми поездками',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Популярные маршруты
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Популярные маршруты',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _popularRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _popularRoutes[index];
                    return _PopularRouteCard(
                      title: route['title'],
                      icon: route['icon'],
                      gradient: route['gradient'],
                      onTap: _navigateToSearch,
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // История поездок
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'История поездок',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Список последних поездок
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return GestureDetector(
                    onTap: () => _navigateToRideDetails(index),
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE9ECEF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getGradientForIndex(index),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _getGradientForIndex(
                                    index,
                                  )[0].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.location_solid,
                              color: CupertinoColors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getRouteForHistoryItem(index),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C3E50),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getDateForHistoryItem(index),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6C757D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF28A745,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Завершена',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF28A745),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _getPriceForHistoryItem(index),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF28A745),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '⭐ 4.9',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF667eea),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount:
                    _historyItemsCount, // Показываем реальное количество поездок
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

// Остальные вкладки (заглушки)
class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchRidesScreen();
  }
}

class CreateRideTab extends StatelessWidget {
  const CreateRideTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateRideScreen();
  }
}

class ChatsTab extends StatefulWidget {
  final VoidCallback? onChatOpened;

  const ChatsTab({super.key, this.onChatOpened});

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey _chatListKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Обновляем счетчик при инициализации вкладки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChatOpened?.call();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем счетчик при каждом появлении вкладки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChatOpened?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ChatListScreen(key: _chatListKey, onChatOpened: widget.onChatOpened);
  }
}

class MyRidesTab extends StatelessWidget {
  const MyRidesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyRidesScreen();
  }
}

// Карточка популярного маршрута с анимацией
class _PopularRouteCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _PopularRouteCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PopularRouteCard> createState() => _PopularRouteCardState();
}

class _PopularRouteCardState extends State<_PopularRouteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Иконка в контейнере
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Текст
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
