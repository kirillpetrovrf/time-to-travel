import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/user.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /auth/register - Регистрация нового пользователя
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
    final dto = RegisterUserDto.fromJson(json);

    // Валидация
    if (dto.email.isEmpty || !dto.email.contains('@')) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid email'},
      );
    }

    if (dto.password.length < 6) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Password must be at least 6 characters'},
      );
    }

    if (dto.name.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Name is required'},
      );
    }

    // Создаем пользователя
    final user = await userRepo.create(
      email: dto.email,
      password: dto.password,
      name: dto.name,
      phone: dto.phone,
    );

    // Создаем токены
    final accessToken = jwtHelper.createAccessToken(
      userId: user.id,
      email: user.email,
      additionalClaims: {'role': user.role},
    );

    final refreshToken = jwtHelper.createRefreshToken(
      userId: user.id,
    );

    // Сохраняем refresh token в БД
    await _saveRefreshToken(db, user.id, refreshToken);

    // Возвращаем ответ
    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'user': user.toJson(),
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      },
    );
  } on Exception catch (e) {
    // Проверяем на дублирование email
    if (e.toString().contains('already exists')) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': 'Email already registered'},
      );
    }

    // Общая ошибка
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Registration failed: ${e.toString()}'},
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
    INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
    VALUES (@userId, @token, @expiresAt)
    ''',
    parameters: {
      'userId': userId,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    },
  );
}

