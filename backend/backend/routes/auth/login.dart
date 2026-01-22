import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/user.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /auth/login - Вход пользователя
Future<Response> onRequest(RequestContext context) async {
  // Проверяем метод
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    // Получаем сервисы из контекста
    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = LoginDto.fromJson(json);

    // Валидация
    if (dto.email.isEmpty || dto.password.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Email and password are required'},
      );
    }

    // Находим пользователя
    final user = await userRepo.findByEmail(dto.email);
    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid credentials'},
      );
    }

    // Проверяем активность
    if (!user.isActive) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Account is deactivated'},
      );
    }

    // Проверяем пароль
    final passwordValid = await userRepo.verifyPassword(user, dto.password);
    if (!passwordValid) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid credentials'},
      );
    }

    // Создаем токены
    final accessToken = jwtHelper.createAccessToken(
      userId: user.id,
      email: user.email,
    );

    final refreshToken = jwtHelper.createRefreshToken(
      userId: user.id,
    );

    // Сохраняем refresh token в БД
    await _saveRefreshToken(db, user.id, refreshToken);

    // Возвращаем ответ
    return Response.json(
      body: {
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Login failed: ${e.toString()}'},
    );
  }
}

/// Сохранить refresh token в БД
Future<void> _saveRefreshToken(
  DatabaseService db,
  String userId,
  String token,
) async {
  // Вычисляем дату истечения (7 дней)
  final expiresAt = DateTime.now().add(Duration(days: 7));

  await db.execute(
    '''
    INSERT INTO refresh_tokens (user_id, token, expires_at)
    VALUES (@userId, @token, @expiresAt)
    ''',
    parameters: {
      'userId': userId,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    },
  );
}
