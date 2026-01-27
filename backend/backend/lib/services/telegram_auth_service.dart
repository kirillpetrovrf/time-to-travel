import 'package:logging/logging.dart';

final _log = Logger('TelegramAuthService');

/// Сервис для управления сессиями Telegram авторизации
/// Хранит временные данные о попытках авторизации
class TelegramAuthService {
  /// Singleton instance
  static final TelegramAuthService _instance = TelegramAuthService._internal();
  
  factory TelegramAuthService() => _instance;
  
  TelegramAuthService._internal() {
    _log.info('🔐 TelegramAuthService инициализирован');
  }

  /// Хранилище активных сессий: authCode -> session data
  /// В production лучше использовать Redis с TTL
  final Map<String, AuthSession> _sessions = {};
  
  /// Хранилище pending сессий (до нажатия START): authCode -> phone
  final Map<String, PendingSession> _pendingSessions = {};

  /// Сохранить pending сессию (при вызове /init)
  void setPendingSession({
    required String authCode,
    required String phone,
  }) {
    final session = PendingSession(
      phone: phone,
      createdAt: DateTime.now(),
    );
    
    _pendingSessions[authCode] = session;
    
    _log.info('💾 [PENDING] Сохранена pending сессия: authCode=$authCode, phone=$phone');
    _log.info('📊 [PENDING] Всего pending сессий: ${_pendingSessions.length}');
  }

  /// Получить pending сессию по authCode
  PendingSession? getPendingSession(String authCode) {
    final session = _pendingSessions[authCode];
    
    if (session != null) {
      // Проверяем не истекла ли сессия (10 минут)
      final age = DateTime.now().difference(session.createdAt);
      if (age.inMinutes > 10) {
        _log.warning('⏰ [PENDING] Сессия истекла (${age.inMinutes} мин): $authCode');
        _pendingSessions.remove(authCode);
        return null;
      }
      
      _log.info('✅ [PENDING] Найдена pending сессия: authCode=$authCode, phone=${session.phone}');
      return session;
    } else {
      _log.warning('❌ [PENDING] Pending сессия НЕ найдена: $authCode');
      return null;
    }
  }

  /// Удалить pending сессию (после создания auth сессии)
  void removePendingSession(String authCode) {
    final removed = _pendingSessions.remove(authCode);
    if (removed != null) {
      _log.info('🗑️ [PENDING] Pending сессия удалена: $authCode');
    }
  }

  /// Сохранить сессию авторизации после /start в боте
  void setAuthSession({
    required String authCode,
    required String userId,
    String? phone,
  }) {
    final session = AuthSession(
      userId: userId,
      phone: phone,
      createdAt: DateTime.now(),
      status: 'success',
    );
    
    _sessions[authCode] = session;
    
    _log.info('✅ [AUTH_SESSION] Сохранена сессия: authCode=$authCode, userId=$userId, phone=$phone');
    _log.info('📊 [AUTH_SESSION] Всего активных сессий: ${_sessions.length}');
    
    // Автоматически удаляем старые сессии (старше 10 минут)
    _cleanupOldSessions();
  }

  /// Получить сессию по authCode
  AuthSession? getAuthSession(String authCode) {
    final session = _sessions[authCode];
    
    if (session != null) {
      _log.info('✅ [AUTH_SESSION] Найдена сессия: authCode=$authCode, userId=${session.userId}');
      
      // Проверяем не истекла ли сессия (10 минут)
      final age = DateTime.now().difference(session.createdAt);
      if (age.inMinutes > 10) {
        _log.warning('⏰ [AUTH_SESSION] Сессия истекла (${age.inMinutes} мин): $authCode');
        _sessions.remove(authCode);
        return null;
      }
      
      return session;
    } else {
      _log.warning('❌ [AUTH_SESSION] Сессия НЕ найдена: $authCode');
      _log.info('📋 [AUTH_SESSION] Доступные сессии: ${_sessions.keys.join(', ')}');
      return null;
    }
  }

  /// Удалить сессию после успешной авторизации
  void removeAuthSession(String authCode) {
    final removed = _sessions.remove(authCode);
    if (removed != null) {
      _log.info('🗑️ [AUTH_SESSION] Сессия удалена: $authCode');
    }
  }

  /// Очистка старых сессий (старше 10 минут)
  void _cleanupOldSessions() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    _sessions.forEach((authCode, session) {
      final age = now.difference(session.createdAt);
      if (age.inMinutes > 10) {
        toRemove.add(authCode);
      }
    });
    
    for (final authCode in toRemove) {
      _sessions.remove(authCode);
      _log.info('🧹 [AUTH_SESSION] Удалена старая сессия: $authCode');
    }
    
    if (toRemove.isNotEmpty) {
      _log.info('🧹 [AUTH_SESSION] Очищено сессий: ${toRemove.length}');
    }
  }

  /// Получить статистику сессий (для отладки)
  Map<String, dynamic> getStats() {
    return {
      'total_sessions': _sessions.length,
      'session_codes': _sessions.keys.toList(),
    };
  }
}

/// Модель сессии авторизации
class AuthSession {
  final String userId;
  final String? phone;
  final DateTime createdAt;
  final String status;

  AuthSession({
    required this.userId,
    this.phone,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };
}

/// Модель pending сессии (до нажатия START в Telegram)
class PendingSession {
  final String phone;
  final DateTime createdAt;

  PendingSession({
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };
}
