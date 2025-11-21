class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final String? rideId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.rideId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isFromUser': isFromUser ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'rideId': rideId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isFromUser: (map['isFromUser'] ?? 0) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      rideId: map['rideId'],
    );
  }
}
