import 'package:json_annotation/json_annotation.dart';
import '../utils/db_helpers.dart';

part 'payment.g.dart';

/// Статус платежа
enum PaymentStatus {
  pending,     // Ожидает оплаты
  processing,  // В обработке
  completed,   // Оплачен
  failed,      // Ошибка оплаты
  refunded;    // Возврат средств

  String toDb() => name;

  static PaymentStatus fromDb(String status) {
    return PaymentStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Метод оплаты
enum PaymentMethod {
  cash,        // Наличные (текущий метод по умолчанию)
  card,        // Банковская карта (будущее)
  sbp,         // Система быстрых платежей (будущее)
  yookassa,    // ЮKassa (будущее)
  tinkoff;     // Тинькофф (будущее)

  String toDb() => name;

  static PaymentMethod fromDb(String method) {
    return PaymentMethod.values.firstWhere(
      (m) => m.name == method,
      orElse: () => PaymentMethod.cash,
    );
  }

  /// Требует ли онлайн-обработки
  bool get requiresOnlineProcessing {
    return this != PaymentMethod.cash;
  }
}

/// Модель платежа
/// 
/// ВАЖНО: Это STUB для будущей реализации онлайн-платежей.
/// Сейчас все платежи проходят наличными (cash), но структура готова
/// для интеграции с платёжными системами (ЮKassa, Тинькофф, СБП).
@JsonSerializable()
class Payment {
  /// ID платежа (UUID)
  final String id;

  /// ID заказа, к которому относится платеж
  final String orderId;

  /// Сумма платежа
  final double amount;

  /// Валюта (по умолчанию RUB)
  final String currency;

  /// Метод оплаты
  @JsonKey(fromJson: _methodFromJson, toJson: _methodToJson)
  final PaymentMethod method;

  /// Статус платежа
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final PaymentStatus status;

  /// ID транзакции во внешней платёжной системе
  final String? transactionId;

  /// Когда был оплачен
  final DateTime? paidAt;

  /// Когда создан
  final DateTime createdAt;

  /// Когда обновлен
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    this.currency = 'RUB',
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON serialization helpers
  static PaymentMethod _methodFromJson(String value) => PaymentMethod.fromDb(value);
  static String _methodToJson(PaymentMethod method) => method.toDb();
  static PaymentStatus _statusFromJson(String value) => PaymentStatus.fromDb(value);
  static String _statusToJson(PaymentStatus status) => status.toDb();

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  /// Создание из строки БД
  factory Payment.fromDb(Map<String, dynamic> row) {
    return Payment(
      id: row['id'] as String,
      orderId: row['order_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      currency: row['currency'] as String? ?? 'RUB',
      method: PaymentMethod.fromDb(row['payment_method'] as String),
      status: PaymentStatus.fromDb(row['status'] as String),
      transactionId: row['transaction_id'] as String?,
      paidAt: row['paid_at'] != null ? parseDbDateTime(row['paid_at']) : null,
      createdAt: parseDbDateTime(row['created_at']),
      updatedAt: parseDbDateTime(row['updated_at']),
    );
  }

  /// Копирование с изменениями
  Payment copyWith({
    String? id,
    String? orderId,
    double? amount,
    String? currency,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// DTO для создания платежа
/// 
/// Используется при создании нового платежа через API.
/// Сейчас не используется, так как все платежи наличные,
/// но готово для будущей интеграции.
@JsonSerializable()
class CreatePaymentDto {
  /// ID заказа
  final String orderId;

  /// Сумма платежа
  final double amount;

  /// Метод оплаты (по умолчанию наличные)
  @JsonKey(fromJson: _methodFromJson, toJson: _methodToJson)
  final PaymentMethod method;

  const CreatePaymentDto({
    required this.orderId,
    required this.amount,
    this.method = PaymentMethod.cash,
  });

  static PaymentMethod _methodFromJson(String value) => PaymentMethod.fromDb(value);
  static String _methodToJson(PaymentMethod method) => method.toDb();

  factory CreatePaymentDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentDtoToJson(this);
}

// TODO: Реализовать PaymentRepository когда будет онлайн-оплата
// TODO: Интеграция с ЮKassa API (https://yookassa.ru/developers)
// TODO: Интеграция с Тинькофф Acquiring (https://www.tinkoff.ru/kassa/)
// TODO: СБП интеграция (https://sbp.nspk.ru/)
// TODO: Webhook handlers для callback'ов от платёжных систем
// TODO: Автоматическое обновление статуса заказа при успешной оплате
