class ChatConversation {
  final String id;
  final String rideId;
  final String driverName;
  final String route;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;
  final String driverAvatar; // Для отображения аватара водителя

  ChatConversation({
    required this.id,
    required this.rideId,
    required this.driverName,
    required this.route,
    required this.lastMessage,
    required this.lastMessageTime,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    this.driverAvatar = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'driverName': driverName,
      'route': route,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'hasUnreadMessages': hasUnreadMessages ? 1 : 0,
      'unreadCount': unreadCount,
      'driverAvatar': driverAvatar,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] ?? '',
      rideId: map['ride_id'] ?? map['rideId'] ?? '',
      driverName: map['driver_name'] ?? map['driverName'] ?? '',
      route: map['route'] ?? '',
      lastMessage: map['last_message'] ?? map['lastMessage'] ?? '',
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.parse(map['last_message_time'])
          : map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : DateTime.now(),
      hasUnreadMessages:
          (map['has_unread_messages'] ?? map['hasUnreadMessages'] ?? 0) == 1,
      unreadCount: map['unread_count'] ?? map['unreadCount'] ?? 0,
      driverAvatar: map['driver_avatar'] ?? map['driverAvatar'] ?? '',
    );
  }

  ChatConversation copyWith({
    String? id,
    String? rideId,
    String? driverName,
    String? route,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? hasUnreadMessages,
    int? unreadCount,
    String? driverAvatar,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      driverName: driverName ?? this.driverName,
      route: route ?? this.route,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      driverAvatar: driverAvatar ?? this.driverAvatar,
    );
  }
}
