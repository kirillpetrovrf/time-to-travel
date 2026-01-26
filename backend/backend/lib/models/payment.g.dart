// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String? ?? 'RUB',
  method: Payment._methodFromJson(json['method'] as String),
  status: Payment._statusFromJson(json['status'] as String),
  transactionId: json['transactionId'] as String?,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'currency': instance.currency,
  'method': Payment._methodToJson(instance.method),
  'status': Payment._statusToJson(instance.status),
  'transactionId': instance.transactionId,
  'paidAt': instance.paidAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

CreatePaymentDto _$CreatePaymentDtoFromJson(Map<String, dynamic> json) =>
    CreatePaymentDto(
      orderId: json['orderId'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] == null
          ? PaymentMethod.cash
          : CreatePaymentDto._methodFromJson(json['method'] as String),
    );

Map<String, dynamic> _$CreatePaymentDtoToJson(CreatePaymentDto instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'amount': instance.amount,
      'method': CreatePaymentDto._methodToJson(instance.method),
    };
