import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// JWT Helper для создания и проверки токенов
class JwtHelper {
  final String secret;
  final int accessExpirySeconds;
  final int refreshExpirySeconds;

  JwtHelper({
    required this.secret,
    this.accessExpirySeconds = 3600, // 1 час
    this.refreshExpirySeconds = 604800, // 7 дней
  });

  /// Фабричный метод из environment
  factory JwtHelper.fromEnv(Map<String, String> env) {
    return JwtHelper(
      secret: env['JWT_SECRET'] ?? 'development_secret_change_in_production',
      accessExpirySeconds: int.tryParse(env['JWT_ACCESS_EXPIRY'] ?? '3600') ?? 3600,
      refreshExpirySeconds: int.tryParse(env['JWT_REFRESH_EXPIRY'] ?? '604800') ?? 604800,
    );
  }

  /// Создать access token
  String createAccessToken({
    required String userId,
    required String email,
    Map<String, dynamic>? additionalClaims,
  }) {
    final jwt = JWT(
      {
        'userId': userId,
        'email': email,
        'type': 'access',
        ...?additionalClaims,
      },
      issuer: 'titotr.ru',
    );

    return jwt.sign(
      SecretKey(secret),
      expiresIn: Duration(seconds: accessExpirySeconds),
    );
  }

  /// Создать refresh token
  String createRefreshToken({
    required String userId,
  }) {
    final jwt = JWT(
      {
        'userId': userId,
        'type': 'refresh',
      },
      issuer: 'titotr.ru',
    );

    return jwt.sign(
      SecretKey(secret),
      expiresIn: Duration(seconds: refreshExpirySeconds),
    );
  }

  /// Проверить и декодировать токен
  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      return jwt.payload as Map<String, dynamic>;
    } on JWTExpiredException {
      return null; // Токен истек
    } on JWTException {
      return null; // Невалидный токен
    }
  }

  /// Извлечь userId из токена
  String? getUserIdFromToken(String token) {
    final payload = verifyToken(token);
    return payload?['userId'] as String?;
  }

  /// Проверить что это access token
  bool isAccessToken(Map<String, dynamic> payload) {
    return payload['type'] == 'access';
  }

  /// Проверить что это refresh token
  bool isRefreshToken(Map<String, dynamic> payload) {
    return payload['type'] == 'refresh';
  }
}
