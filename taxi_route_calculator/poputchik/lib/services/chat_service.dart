import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'database_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  static ChatService get instance => _instance;

  final DatabaseService _databaseService = DatabaseService.instance;
  final List<ChatConversation> _conversations = [];
  bool _isInitialized = false;

  // Инициализация чатов из базы данных
  Future<void> _initializeIfNeeded() async {
    if (!_isInitialized) {
      await _loadConversationsFromDatabase();
      _isInitialized = true;
    }
  }

  // Загрузка чатов из базы данных
  Future<void> _loadConversationsFromDatabase() async {
    try {
      final conversations = await _databaseService.getAllChatConversations();
      _conversations.clear();
      _conversations.addAll(conversations);
    } catch (e) {
      print('Ошибка при загрузке чатов из БД: $e');
    }
  }

  // Получить все разговоры
  Future<List<ChatConversation>> getAllConversations() async {
    await _initializeIfNeeded();
    return List.from(_conversations);
  }

  // Создать новый чат при бронировании
  Future<ChatConversation> createChatForBooking({
    required String rideId,
    required String driverName,
    required String route,
  }) async {
    await _initializeIfNeeded();

    // Проверяем, не существует ли уже чат для этой поездки
    final existingChat = await _databaseService.findChatByRideId(rideId);
    if (existingChat != null) {
      return existingChat;
    }

    final conversation = ChatConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rideId: rideId,
      driverName: driverName,
      route: route,
      lastMessage: 'Чат создан. Водитель получил уведомление о бронировании.',
      lastMessageTime: DateTime.now(),
      hasUnreadMessages: false,
      unreadCount: 0,
    );

    // Сохраняем в базу данных
    await _databaseService.createChatConversation(conversation);

    // Добавляем в локальный список
    _conversations.insert(0, conversation);
    return conversation;
  }

  // Обновить последнее сообщение
  Future<void> updateLastMessage({
    required String conversationId,
    required String message,
    required bool isFromUser,
  }) async {
    await _initializeIfNeeded();

    // Обновляем в базе данных
    await _databaseService.updateChatLastMessage(
      conversationId: conversationId,
      message: message,
      isFromUser: isFromUser,
    );

    // Обновляем локальный список
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      final updated = conversation.copyWith(
        lastMessage: message,
        lastMessageTime: DateTime.now(),
        hasUnreadMessages: !isFromUser,
        unreadCount: isFromUser ? 0 : conversation.unreadCount + 1,
      );
      _conversations[index] = updated;
    }
  }

  // Отметить как прочитанное
  Future<void> markAsRead(String conversationId) async {
    await _initializeIfNeeded();

    // Обновляем в базе данных
    await _databaseService.markChatAsRead(conversationId);

    // Обновляем локальный список
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      final updated = conversation.copyWith(
        hasUnreadMessages: false,
        unreadCount: 0,
      );
      _conversations[index] = updated;
    }
  }

  // Найти чат по ID поездки
  Future<ChatConversation?> findByRideId(String rideId) async {
    await _initializeIfNeeded();

    // Сначала ищем в локальном списке
    final localResult = _conversations
        .where((c) => c.rideId == rideId)
        .firstOrNull;
    if (localResult != null) {
      return localResult;
    }

    // Если не найдено локально, ищем в базе данных
    final dbResult = await _databaseService.findChatByRideId(rideId);
    if (dbResult != null) {
      _conversations.insert(0, dbResult);
    }
    return dbResult;
  }

  // Удалить чат
  Future<void> removeConversation(String conversationId) async {
    await _initializeIfNeeded();

    // Удаляем из базы данных
    await _databaseService.deleteChatConversation(conversationId);

    // Удаляем из локального списка
    _conversations.removeWhere((c) => c.id == conversationId);
  }

  // Получить количество непрочитанных сообщений
  Future<int> getTotalUnreadCount() async {
    await _initializeIfNeeded();

    // Получаем актуальные данные из базы данных
    return await _databaseService.getTotalUnreadChatsCount();
  }

  // ===== МЕТОДЫ ДЛЯ РАБОТЫ С СООБЩЕНИЯМИ =====

  // Отправить сообщение в чат
  Future<void> sendMessage({
    required String conversationId,
    required String rideId,
    required String text,
    required bool isFromUser,
  }) async {
    await _initializeIfNeeded();

    // Сохраняем сообщение в базу данных
    await _databaseService.createChatMessage(
      conversationId: conversationId,
      rideId: rideId,
      text: text,
      isFromUser: isFromUser,
    );

    // Обновляем последнее сообщение в чате
    await updateLastMessage(
      conversationId: conversationId,
      message: text,
      isFromUser: isFromUser,
    );
  }

  // Получить историю сообщений чата
  Future<List<ChatMessage>> getChatMessages(String conversationId) async {
    await _initializeIfNeeded();

    final messagesData = await _databaseService.getChatMessages(conversationId);
    return messagesData
        .map(
          (data) => ChatMessage(
            id: data['id'],
            text: data['text'],
            isFromUser: data['is_from_user'] == 1,
            timestamp: DateTime.parse(data['timestamp']),
            rideId: data['ride_id'],
          ),
        )
        .toList();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
