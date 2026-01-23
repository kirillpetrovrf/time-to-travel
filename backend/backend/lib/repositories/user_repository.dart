import 'package:backend/models/user.dart';
import 'package:backend/services/database_service.dart';
import 'package:bcrypt/bcrypt.dart';

/// Repository для работы с пользователями
class UserRepository {
  final DatabaseService db;

  UserRepository(this.db);

  /// Создать нового пользователя
  Future<User> create({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    // Проверяем что email уникален
    final existing = await findByEmail(email);
    if (existing != null) {
      throw Exception('User with email $email already exists');
    }

    // Хешируем пароль
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    // Вставляем пользователя
    final id = await db.insert(
      '''
      INSERT INTO users (email, password_hash, name, phone)
      VALUES (@email, @passwordHash, @name, @phone)
      ''',
      parameters: {
        'email': email,
        'passwordHash': passwordHash,
        'name': name,
        'phone': phone,
      },
    );

    // Получаем созданного пользователя
    final user = await findById(id);
    if (user == null) {
      throw Exception('Failed to retrieve created user');
    }

    return user;
  }

  /// Найти пользователя по ID
  Future<User?> findById(String id) async {
    final row = await db.queryOne(
      'SELECT * FROM users WHERE id = @id',
      parameters: {'id': id},
    );

    if (row == null) return null;
    return User.fromDb(row);
  }

  /// Найти пользователя по email
  Future<User?> findByEmail(String email) async {
    final row = await db.queryOne(
      'SELECT * FROM users WHERE email = @email',
      parameters: {'email': email},
    );

    if (row == null) return null;
    return User.fromDb(row);
  }

  /// Найти пользователя по телефону
  Future<User?> findByPhone(String phone) async {
    final row = await db.queryOne(
      'SELECT * FROM users WHERE phone = @phone',
      parameters: {'phone': phone},
    );

    if (row == null) return null;
    return User.fromDb(row);
  }

  /// Проверить пароль
  Future<bool> verifyPassword(User user, String password) async {
    if (user.passwordHash == null) return false;
    return BCrypt.checkpw(password, user.passwordHash!);
  }

  /// Обновить пользователя
  Future<User> update(String id, UpdateUserDto dto) async {
    final updates = <String>[];
    final params = <String, dynamic>{'id': id};

    if (dto.name != null) {
      updates.add('name = @name');
      params['name'] = dto.name;
    }

    if (dto.phone != null) {
      updates.add('phone = @phone');
      params['phone'] = dto.phone;
    }

    if (updates.isEmpty) {
      throw Exception('No fields to update');
    }

    await db.execute(
      '''
      UPDATE users
      SET ${updates.join(', ')}
      WHERE id = @id
      ''',
      parameters: params,
    );

    final updated = await findById(id);
    if (updated == null) {
      throw Exception('User not found after update');
    }

    return updated;
  }

  /// Удалить пользователя
  Future<void> delete(String id) async {
    await db.execute(
      'DELETE FROM users WHERE id = @id',
      parameters: {'id': id},
    );
  }

  /// Получить всех пользователей (для админа)
  Future<List<User>> findAll({int? limit, int? offset}) async {
    final sql = StringBuffer('SELECT * FROM users');

    if (limit != null) {
      sql.write(' LIMIT $limit');
    }

    if (offset != null) {
      sql.write(' OFFSET $offset');
    }

    final rows = await db.queryMany(sql.toString());
    return rows.map((row) => User.fromDb(row)).toList();
  }

  /// Подтвердить email
  Future<void> verifyEmail(String userId) async {
    await db.execute(
      'UPDATE users SET is_verified = true WHERE id = @id',
      parameters: {'id': userId},
    );
  }

  /// Деактивировать пользователя
  Future<void> deactivate(String userId) async {
    await db.execute(
      'UPDATE users SET is_active = false WHERE id = @id',
      parameters: {'id': userId},
    );
  }

  /// Активировать пользователя
  Future<void> activate(String userId) async {
    await db.execute(
      'UPDATE users SET is_active = true WHERE id = @id',
      parameters: {'id': userId},
    );
  }

  /// Найти пользователя по Telegram ID
  Future<User?> findByTelegramId(int telegramId) async {
    final row = await db.queryOne(
      'SELECT * FROM users WHERE telegram_id = @telegramId',
      parameters: {'telegramId': telegramId},
    );

    if (row == null) return null;
    return User.fromDb(row);
  }

  /// Создать или обновить пользователя из Telegram
  Future<User> upsertFromTelegram({
    required int telegramId,
    String? phone,
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    print('🔧 [UPSERT] ========== ВЫЗОВ upsertFromTelegram ==========');
    print('📥 [UPSERT] Параметры:');
    print('   • telegramId: $telegramId');
    print('   • phone: $phone');
    print('   • firstName: $firstName');
    print('   • lastName: $lastName');
    print('   • username: $username');
    
    User? existing;
    
    // ПРИОРИТЕТ 1: Ищем по телефону (если номер был введён при /init)
    if (phone != null && phone.isNotEmpty) {
      print('🔍 [UPSERT] ПРИОРИТЕТ 1: Ищем по телефону: $phone');
      existing = await findByPhone(phone);
      
      if (existing != null) {
        print('✅ [UPSERT] Найден пользователь по телефону!');
        print('   • id: ${existing.id}');
        print('   • phone: ${existing.phone}');
        print('   • telegram_id (старый): ${existing.telegramId}');
        
        // Нашли пользователя по телефону - обновляем его telegram_id
        print('💾 [UPSERT] Обновляем telegram_id на: $telegramId');
        
        await db.execute(
          '''
          UPDATE users 
          SET 
            telegram_id = @telegramId,
            first_name = COALESCE(@firstName, first_name),
            last_name = COALESCE(@lastName, last_name),
            username = COALESCE(@username, username)
          WHERE id = @userId
          ''',
          parameters: {
            'userId': existing.id,
            'telegramId': telegramId,
            'firstName': firstName,
            'lastName': lastName,
            'username': username,
          },
        );

        final updated = (await findById(existing.id))!;
        print('✅ [UPSERT] Пользователь обновлён:');
        print('   • id: ${updated.id}');
        print('   • phone: ${updated.phone}');
        print('   • telegram_id (новый): ${updated.telegramId}');
        
        return updated;
      } else {
        print('⚠️ [UPSERT] Пользователь НЕ найден по телефону $phone');
      }
    } else {
      print('ℹ️ [UPSERT] Phone не указан, пропускаем поиск по телефону');
    }
    
    // ПРИОРИТЕТ 2: Ищем по telegram_id
    print('🔍 [UPSERT] ПРИОРИТЕТ 2: Ищем по telegram_id: $telegramId');
    existing = await findByTelegramId(telegramId);

    if (existing != null) {
      print('✅ [UPSERT] Найден пользователь по telegram_id!');
      print('   • id: ${existing.id}');
      print('   • phone (старый): ${existing.phone}');
      
      // Обновляем данные
      print('💾 [UPSERT] Обновляем phone на: $phone');
      
      await db.execute(
        '''
        UPDATE users 
        SET 
          phone = COALESCE(@phone, phone),
          first_name = COALESCE(@firstName, first_name),
          last_name = COALESCE(@lastName, last_name),
          username = COALESCE(@username, username)
        WHERE telegram_id = @telegramId
        ''',
        parameters: {
          'telegramId': telegramId,
          'phone': phone,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
        },
      );

      final updated = (await findByTelegramId(telegramId))!;
      print('✅ [UPSERT] Пользователь обновлён по telegram_id');
      
      return updated;
    } else {
      print('⚠️ [UPSERT] Пользователь НЕ найден по telegram_id: $telegramId');
      
      // Создаём нового пользователя (редкий случай - только если нет ни телефона, ни telegram_id)
      print('➕ [UPSERT] Создаём НОВОГО пользователя');
      
      final id = await db.insert(
        '''
        INSERT INTO users (
          telegram_id, phone, first_name, last_name, 
          username, role, is_active, email, password_hash, name
        ) VALUES (
          @telegramId, @phone, @firstName, @lastName,
          @username, 'passenger', true, '', '', @name
        )
        ''',
        parameters: {
          'telegramId': telegramId,
          'phone': phone,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'name': firstName ?? username ?? 'Пользователь',
        },
      );

      return (await findById(id))!;
    }
  }
}
