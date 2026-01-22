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
}
