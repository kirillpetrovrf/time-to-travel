import 'package:flutter/cupertino.dart';
import '../../../models/ride.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final Ride ride;

  const ChatScreen({super.key, required this.ride});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;

  final ChatService _chatService = ChatService.instance;
  String? _conversationId;

  // Симуляция ответов водителя
  final List<String> _driverResponses = [
    'Приветствую! 👋',
    'Да, конечно, место забронировано',
    'Хорошо, договорились!',
    'Буду ждать в указанном месте',
    'До встречи! 🚗',
    'Отлично, тогда до свидания',
    'Если что-то изменится - пишите',
    'Хорошего дня!',
  ];
  int _responseIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // Загрузка истории сообщений из базы данных
  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);

    try {
      // Находим чат для этой поездки
      final conversation = await _chatService.findByRideId(widget.ride.id);

      if (conversation != null) {
        _conversationId = conversation.id;

        // Загружаем историю сообщений
        final messages = await _chatService.getChatMessages(conversation.id);
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });

        // Отмечаем чат как прочитанный
        await _chatService.markAsRead(conversation.id);
      } else {
        // Создаем новый чат, если его нет
        final newConversation = await _chatService.createChatForBooking(
          rideId: widget.ride.id,
          driverName: widget.ride.driverName,
          route: '${widget.ride.fromDistrict} → ${widget.ride.toDistrict}',
        );

        _conversationId = newConversation.id;

        // Добавляем приветственное сообщение
        await _sendSystemMessage(
          'Приветствую! Вижу, что вы связались со мной по поездке. Если есть вопросы - задавайте! 😊',
        );

        setState(() => _isLoading = false);
      }

      _scrollToBottom();
    } catch (e) {
      print('Ошибка при загрузке истории чата: $e');
      setState(() => _isLoading = false);
    }
  }

  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4CAF50), // Зеленый
                    Color(0xFF2196F3), // Синий
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.car_detailed,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ride.driverName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Онлайн',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          // Информация о поездке
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.location_solid,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.ride.fromDistrict} → ${widget.ride.toDistrict}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.clock,
                        color: CupertinoColors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDateTime(widget.ride.departureTime),
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${widget.ride.pricePerSeat.toInt()} ₽',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Список сообщений
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 16))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Индикатор печатания
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.car_detailed,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDots(),
                        const SizedBox(width: 8),
                        const Text(
                          'печатает',
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Поле ввода сообщения
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              border: const Border(
                top: BorderSide(color: Color(0xFFE9ECEF), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE9ECEF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Введите сообщение...',
                      placeholderStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_up,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isFromUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4CAF50), // Зеленый
                    Color(0xFF2196F3), // Синий
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.car_detailed,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF667eea), // Градиент синего
                          Color(0xFF764ba2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFFF8F9FA), // Светло-серый
                          Color(0xFFE9ECEF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(6),
                  bottomRight: isMe
                      ? const Radius.circular(6)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? const Color(0xFF667eea).withOpacity(0.3)
                        : CupertinoColors.systemGrey.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? CupertinoColors.white
                          : const Color(0xFF2C3E50),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe
                              ? CupertinoColors.white.withOpacity(0.8)
                              : CupertinoColors.secondaryLabel,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 14,
                          color: CupertinoColors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF6B6B), // Красноватый
                    Color(0xFFFF8E53), // Оранжевый
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: CupertinoColors.white,
                size: 22,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    // Добавляем сообщение пользователя
    final userMessage = ChatMessage(
      id: _generateMessageId(),
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
      rideId: widget.ride.id,
    );

    setState(() {
      _messages.add(userMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    // Сохраняем сообщение в базу данных
    try {
      await _chatService.sendMessage(
        conversationId: _conversationId!,
        rideId: widget.ride.id,
        text: text,
        isFromUser: true,
      );

      // Симулируем ответ водителя через 1-3 секунды
      _simulateDriverResponse();
    } catch (e) {
      print('Ошибка при отправке сообщения: $e');
    }
  }

  // Отправка системного сообщения (от водителя)
  Future<void> _sendSystemMessage(String text) async {
    if (_conversationId == null) return;

    final driverMessage = ChatMessage(
      id: _generateMessageId(),
      text: text,
      isFromUser: false,
      timestamp: DateTime.now(),
      rideId: widget.ride.id,
    );

    setState(() {
      _messages.add(driverMessage);
    });

    // Сохраняем в базу данных
    try {
      await _chatService.sendMessage(
        conversationId: _conversationId!,
        rideId: widget.ride.id,
        text: text,
        isFromUser: false,
      );
    } catch (e) {
      print('Ошибка при отправке системного сообщения: $e');
    }

    _scrollToBottom();
  }

  void _simulateDriverResponse() {
    setState(() {
      _isTyping = true;
    });

    final delay = Duration(
      milliseconds: 1000 + (DateTime.now().millisecond % 2000),
    );

    Future.delayed(delay, () async {
      if (!mounted || _conversationId == null) return;

      setState(() {
        _isTyping = false;
      });

      String responseText;
      if (_responseIndex < _driverResponses.length) {
        responseText = _driverResponses[_responseIndex];
        _responseIndex++;
      } else {
        // Если закончились заготовленные ответы, используем случайные
        final randomResponses = [
          'Понял вас',
          'Хорошо',
          'Договорились',
          'Отлично!',
          'До свидания! 👋',
        ];
        final randomIndex = DateTime.now().millisecond % randomResponses.length;
        responseText = randomResponses[randomIndex];
      }

      // Отправляем ответ водителя через системное сообщение
      await _sendSystemMessage(responseText);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(right: index < 2 ? 3 : 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 200)),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF6C757D).withOpacity(0.6 + (0.4 * value)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
            onEnd: () {
              // Перезапускаем анимацию
              if (mounted && _isTyping) {
                setState(() {});
              }
            },
          ),
        );
      }),
    );
  }
}
