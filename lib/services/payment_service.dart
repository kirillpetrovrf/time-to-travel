import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

/// Сервис для работы с платежами (ТЗ v3.0)
/// НОВОЕ: Подготовка к интеграции с СБП (Система быстрых платежей)
class PaymentService {
  static const PaymentService _instance = PaymentService._internal();
  const PaymentService._internal();
  static const PaymentService instance = _instance;

  /// Генерация QR-кода для оплаты через СБП
  Future<PaymentQRData> generateSBPQRCode({
    required double amount,
    required String bookingId,
    required String description,
  }) async {
    try {
      // В реальном приложении здесь будет вызов API банка для генерации QR
      await Future.delayed(const Duration(milliseconds: 800));

      final paymentId = _generatePaymentId();

      // Формируем данные для QR-кода (стандарт СБП)
      final qrData = SBPQRData(
        version: '01',
        initMethod: '12', // Динамический QR
        merchantAccount: '30570004',
        merchantCategory: '4121', // Такси
        currency: '643', // RUB
        amount: amount.toStringAsFixed(2),
        country: 'RU',
        merchantName: 'TIME TO TRAVEL',
        merchantCity: 'ROSTOV-ON-DON',
        additionalData: {
          'purpose': description,
          'paymentId': paymentId,
          'bookingId': bookingId,
        },
      );

      return PaymentQRData(
        qrContent: qrData.toString(),
        paymentId: paymentId,
        amount: amount,
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        sbpData: qrData,
      );
    } catch (e) {
      debugPrint('❌ Ошибка генерации QR СБП: $e');
      rethrow;
    }
  }

  /// Проверка статуса платежа
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      // В реальном приложении здесь проверка через API банка
      await Future.delayed(const Duration(milliseconds: 500));

      // Мок: случайный статус для демо
      final random = Random();
      final statuses = [
        PaymentStatus.pending,
        PaymentStatus.completed,
        PaymentStatus.failed,
      ];

      return statuses[random.nextInt(statuses.length)];
    } catch (e) {
      debugPrint('❌ Ошибка проверки статуса платежа: $e');
      return PaymentStatus.failed;
    }
  }

  /// Отмена платежа
  Future<bool> cancelPayment(String paymentId) async {
    try {
      // В реальном приложении здесь отмена через API банка
      await Future.delayed(const Duration(milliseconds: 300));

      debugPrint('💳 Платеж $paymentId отменен');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отмены платежа: $e');
      return false;
    }
  }

  String _generatePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'TT_${timestamp}_$random';
  }
}

/// Статусы платежа
enum PaymentStatus {
  pending, // В ожидании
  completed, // Выполнен
  failed, // Не удался
  cancelled, // Отменен
}

/// Данные QR-кода для оплаты
class PaymentQRData {
  final String qrContent;
  final String paymentId;
  final double amount;
  final DateTime expiresAt;
  final SBPQRData sbpData;

  const PaymentQRData({
    required this.qrContent,
    required this.paymentId,
    required this.amount,
    required this.expiresAt,
    required this.sbpData,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Данные СБП QR-кода
class SBPQRData {
  final String version;
  final String initMethod;
  final String merchantAccount;
  final String merchantCategory;
  final String currency;
  final String amount;
  final String country;
  final String merchantName;
  final String merchantCity;
  final Map<String, String> additionalData;

  const SBPQRData({
    required this.version,
    required this.initMethod,
    required this.merchantAccount,
    required this.merchantCategory,
    required this.currency,
    required this.amount,
    required this.country,
    required this.merchantName,
    required this.merchantCity,
    required this.additionalData,
  });

  @override
  String toString() {
    // Упрощенный формат для демо
    return 'SBP|$merchantName|$amount|$currency|${additionalData['paymentId']}';
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'initMethod': initMethod,
      'merchantAccount': merchantAccount,
      'merchantCategory': merchantCategory,
      'currency': currency,
      'amount': amount,
      'country': country,
      'merchantName': merchantName,
      'merchantCity': merchantCity,
      'additionalData': additionalData,
    };
  }
}
