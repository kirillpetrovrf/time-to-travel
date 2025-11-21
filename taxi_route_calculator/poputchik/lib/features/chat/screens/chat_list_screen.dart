import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/chat_conversation.dart';
import '../../../models/ride.dart';
import '../../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback? onChatOpened;

  const ChatListScreen({super.key, this.onChatOpened});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Обновляем чаты когда приложение становится активным (только если не идет загрузка)
    if (state == AppLifecycleState.resumed && !_isLoading) {
      _loadConversations();
    }
  }

  // Убираем didChangeDependencies так как он срабатывает слишком часто
  // Вместо этого будем использовать прямой вызов обновления при переключении вкладок

  // Публичный метод для принудительного обновления чатов
  void refreshChats() {
    if (mounted && !_isLoading) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    // Если уже идет загрузка (но не первоначальная), не запускаем новую
    if (_isLoading && _conversations.isNotEmpty) return;

    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    // Получаем чаты из сервиса или создаем тестовые данные
    try {
      final chatService = ChatService.instance;
      var conversations = await chatService.getAllConversations();

      // Если чатов нет, создаем тестовые данные для демонстрации
      if (conversations.isEmpty) {
        conversations = await _createDemoConversations();
        // Добавляем демо-чаты в сервис
        for (final conversation in conversations) {
          await chatService.createChatForBooking(
            rideId: conversation.rideId,
            driverName: conversation.driverName,
            route: conversation.route,
          );
          await chatService.updateLastMessage(
            conversationId: conversation.id,
            message: conversation.lastMessage,
            isFromUser: false,
          );
        }
        // Перезагружаем из базы данных
        conversations = await chatService.getAllConversations();
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке чатов: $e');
      // В случае ошибки создаем тестовые данные
      final conversations = await _createDemoConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }

    _animationController.forward();
  }

  Future<List<ChatConversation>> _createDemoConversations() async {
    return [
      ChatConversation(
        id: '1',
        rideId: 'ride_1',
        driverName: 'Александр Иванов',
        route: 'Центр → Спальный район',
        lastMessage: 'Хорошо, жду вас на остановке в 15:30',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 15)),
        hasUnreadMessages: true,
        unreadCount: 2,
      ),
      ChatConversation(
        id: '2',
        rideId: 'ride_2',
        driverName: 'Мария Петрова',
        route: 'Аэропорт → Центр',
        lastMessage: 'Спасибо за поездку! Хорошего дня 😊',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
        hasUnreadMessages: false,
        unreadCount: 0,
      ),
      ChatConversation(
        id: '3',
        rideId: 'ride_3',
        driverName: 'Дмитрий Козлов',
        route: 'Вокзал → Университет',
        lastMessage: 'Подъезжаю к месту встречи',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 6)),
        hasUnreadMessages: true,
        unreadCount: 1,
      ),
      ChatConversation(
        id: '4',
        rideId: 'ride_4',
        driverName: 'Елена Смирнова',
        route: 'Торговый центр → Парк',
        lastMessage: 'Отличная поездка была, спасибо!',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
        hasUnreadMessages: false,
        unreadCount: 0,
      ),
      ChatConversation(
        id: '5',
        rideId: 'ride_5',
        driverName: 'Владимир Кузнецов',
        route: 'Больница → Аэропорт',
        lastMessage: 'До свидания, удачного полета!',
        lastMessageTime: DateTime.now().subtract(const Duration(days: 3)),
        hasUnreadMessages: false,
        unreadCount: 0,
      ),
    ];
  }

  void _openChat(ChatConversation conversation) async {
    // Отмечаем чат как прочитанный
    final chatService = ChatService.instance;
    await chatService.markAsRead(conversation.id);

    // Обновляем счетчик в родительском виджете
    widget.onChatOpened?.call();

    // Создаем фиктивную поездку для чата
    final ride = Ride(
      id: conversation.rideId,
      driverId: 'driver_${conversation.id}',
      driverName: conversation.driverName,
      driverPhone: '+7 (999) 123-45-67',
      fromDistrict: conversation.route.split(' → ')[0],
      toDistrict: conversation.route.split(' → ')[1],
      fromAddress: 'Адрес отправления',
      toAddress: 'Адрес назначения',
      departureTime: DateTime.now(),
      pricePerSeat: 150.0,
      totalSeats: 4,
      availableSeats: 2,
      status: RideStatus.active,
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => ChatScreen(ride: ride)),
    ).then((_) {
      // Обновляем список при возврате из чата
      _loadConversations();
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Вчера';
    } else if (now.difference(time).inDays < 7) {
      final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.day}.${time.month}';
    }
  }

  Widget _buildConversationCard(ChatConversation conversation, int index) {
    // Ограничиваем анимацию, чтобы значения не превышали 1.0
    final startTime = (index * 0.05).clamp(0.0, 0.7);
    final endTime = (startTime + 0.3).clamp(0.0, 1.0);

    final animation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(startTime, endTime, curve: Curves.easeOutCubic),
          ),
        );

    return SlideTransition(
      position: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _openChat(conversation),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар водителя
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getGradientForDriver(conversation.driverName),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _getGradientForDriver(
                          conversation.driverName,
                        )[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      conversation.driverName.isNotEmpty
                          ? conversation.driverName[0].toUpperCase()
                          : 'В',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Информация о чате
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя водителя и время
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              conversation.driverName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: conversation.hasUnreadMessages
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: CupertinoColors.label,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(conversation.lastMessageTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: conversation.hasUnreadMessages
                                  ? const Color(0xFF007AFF)
                                  : CupertinoColors.secondaryLabel,
                              fontWeight: conversation.hasUnreadMessages
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Маршрут
                      Text(
                        conversation.route,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Последнее сообщение и счетчик непрочитанных
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage,
                              style: TextStyle(
                                fontSize: 15,
                                color: conversation.hasUnreadMessages
                                    ? CupertinoColors.label
                                    : CupertinoColors.secondaryLabel,
                                fontWeight: conversation.hasUnreadMessages
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.hasUnreadMessages) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Индикатор следующего экрана
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.tertiaryLabel,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientForDriver(String driverName) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
      [const Color(0xFFffecd2), const Color(0xFFfcb69f)],
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    ];

    final hash = driverName.hashCode;
    return gradients[hash.abs() % gradients.length];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2,
              size: 56,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Пока нет чатов',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Забронируйте место в поездке,\nчтобы общаться с водителем',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          CupertinoButton.filled(
            child: const Text('Найти поездку'),
            onPressed: () {
              // Переключаемся на вкладку поиска
              if (context.mounted) {
                DefaultTabController.of(context).animateTo(1);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Чаты',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemBackground,
        border: const Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: (_isLoading && _conversations.isEmpty)
          ? const Center(child: CupertinoActivityIndicator(radius: 16))
          : _conversations.isEmpty
          ? _buildEmptyState()
          : Container(
              color: CupertinoColors.systemGroupedBackground,
              child: CustomScrollView(
                slivers: [
                  // Refresh control
                  CupertinoSliverRefreshControl(onRefresh: _loadConversations),

                  // Список чатов
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationCard(conversation, index);
                    }, childCount: _conversations.length),
                  ),

                  // Пустое место внизу
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }
}
