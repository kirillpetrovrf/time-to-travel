import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:logging/logging.dart';

/// Сервис для работы с PostgreSQL
class DatabaseService {
  static final _log = Logger('DatabaseService');
  
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final int poolSize;
  final bool sslMode;

  late final Connection _connection;
  bool _isInitialized = false;

  DatabaseService({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.poolSize = 10,
    this.sslMode = false,
  });

  /// Фабричный метод из environment variables
  factory DatabaseService.fromEnv(Map<String, String> env) {
    return DatabaseService(
      host: env['DB_HOST'] ?? 'localhost',
      port: int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432,
      database: env['DB_NAME'] ?? 'timetotravel',
      username: env['DB_USER'] ?? 'ttadmin',
      password: env['DB_PASSWORD'] ?? '',
      poolSize: int.tryParse(env['DB_POOL_MAX'] ?? '10') ?? 10,
      sslMode: env['DB_SSL_MODE'] == 'require',
    );
  }

  /// Инициализация подключения
  Future<void> initialize() async {
    if (_isInitialized) {
      _log.warning('Database already initialized');
      return;
    }

    try {
      _log.info('Connecting to PostgreSQL at $host:$port/$database');

      _connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: sslMode ? SslMode.require : SslMode.disable,
          connectTimeout: Duration(seconds: 30),
        ),
      );

      _isInitialized = true;
      _log.info('✅ Database connected successfully');
      
      // Проверяем подключение
      final result = await query('SELECT version()');
      _log.info('PostgreSQL version: ${result.first[0]}');
    } catch (e, stack) {
      _log.severe('❌ Failed to connect to database', e, stack);
      rethrow;
    }
  }

  /// Выполнить SELECT запрос
  Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    _ensureInitialized();
    
    try {
      _log.fine('Executing query: $sql');
      
      if (parameters != null && parameters.isNotEmpty) {
        // Конвертируем именованные параметры в позиционные
        final result = await _connection.execute(
          Sql.named(sql),
          parameters: parameters,
        );
        return result;
      } else {
        final result = await _connection.execute(sql);
        return result;
      }
    } catch (e, stack) {
      _log.severe('Query error: $sql', e, stack);
      rethrow;
    }
  }

  /// Выполнить INSERT/UPDATE/DELETE запрос
  Future<int> execute(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    _ensureInitialized();
    
    try {
      _log.fine('Executing command: $sql');
      
      final result = await query(sql, parameters: parameters);
      return result.affectedRows;
    } catch (e, stack) {
      _log.severe('Execute error: $sql', e, stack);
      rethrow;
    }
  }

  /// Выполнить INSERT и вернуть ID
  Future<String> insert(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    _ensureInitialized();
    
    try {
      _log.fine('Executing insert: $sql');
      
      // Добавляем RETURNING id если его нет
      String querySql = sql;
      if (!sql.toUpperCase().contains('RETURNING')) {
        querySql = '$sql RETURNING id';
      }
      
      final result = await query(querySql, parameters: parameters);
      
      if (result.isEmpty) {
        throw Exception('Insert returned no results');
      }
      
      return result.first[0] as String;
    } catch (e, stack) {
      _log.severe('Insert error: $sql', e, stack);
      rethrow;
    }
  }

  /// Выполнить запрос в транзакции
  Future<T> transaction<T>(
    Future<T> Function(Connection connection) callback,
  ) async {
    _ensureInitialized();
    
    try {
      _log.fine('Starting transaction');
      
      // Note: В postgres пакете нет встроенных транзакций,
      // нужно использовать BEGIN/COMMIT/ROLLBACK
      await _connection.execute('BEGIN');
      
      try {
        final result = await callback(_connection);
        await _connection.execute('COMMIT');
        _log.fine('Transaction committed');
        return result;
      } catch (e) {
        await _connection.execute('ROLLBACK');
        _log.warning('Transaction rolled back');
        rethrow;
      }
    } catch (e, stack) {
      _log.severe('Transaction error', e, stack);
      rethrow;
    }
  }

  /// Проверка здоровья подключения
  Future<bool> healthCheck() async {
    try {
      if (!_isInitialized) return false;
      
      final result = await query('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      _log.warning('Health check failed', e);
      return false;
    }
  }

  /// Получить одну строку
  Future<Map<String, dynamic>?> queryOne(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await query(sql, parameters: parameters);
    
    if (result.isEmpty) return null;
    
    return _resultToMap(result.first, result.schema);
  }

  /// Получить несколько строк
  Future<List<Map<String, dynamic>>> queryMany(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await query(sql, parameters: parameters);
    
    return result.map((row) => _resultToMap(row, result.schema)).toList();
  }

  /// Конвертация ResultRow в Map
  Map<String, dynamic> _resultToMap(
    ResultRow row,
    ResultSchema schema,
  ) {
    final map = <String, dynamic>{};
    
    for (var i = 0; i < schema.columns.length; i++) {
      final columnName = schema.columns[i].columnName ?? 'column_$i';
      map[columnName] = row[i];
    }
    
    return map;
  }

  /// Проверка что БД инициализирована
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'Database not initialized. Call initialize() first.',
      );
    }
  }

  /// Закрыть подключение
  Future<void> close() async {
    if (!_isInitialized) return;
    
    try {
      await _connection.close();
      _isInitialized = false;
      _log.info('Database connection closed');
    } catch (e, stack) {
      _log.severe('Error closing database connection', e, stack);
    }
  }

  /// Getter для проверки состояния
  bool get isInitialized => _isInitialized;
}
