import 'package:http/http.dart' as http;
import 'dart:convert';

/// Сервис для отправки уведомлений в Telegram
class TelegramService {
  final String botToken;
  final String chatId;

  TelegramService({
    required this.botToken,
    required this.chatId,
  });

  /// Фабричный метод из environment variables
  factory TelegramService.fromEnv(Map<String, String> env) {
    return TelegramService(
      botToken: env['TELEGRAM_BOT_TOKEN'] ?? '',
      chatId: env['TELEGRAM_CHAT_ID'] ?? '',
    );
  }

  /// Проверка настроен ли Telegram
  bool get isConfigured => botToken.isNotEmpty && chatId.isNotEmpty;

  /// Отправка уведомления о новом заказе
  Future<bool> sendNewOrderNotification({
    required String orderId,
    required String fromAddress,
    required String toAddress,
    required String departureDate,
    required String departureTime,
    required int passengerCount,
    required double totalPrice,
    String? tripType,
    List<Map<String, dynamic>>? passengers,
    List<Map<String, dynamic>>? baggage,
    List<Map<String, dynamic>>? pets,
  }) async {
    if (!isConfigured) {
      print('⚠️ Telegram не настроен. Пропускаем отправку уведомления.');
      return false;
    }

    try {
      // Формируем красивое сообщение
      final message = _formatOrderMessage(
        orderId: orderId,
        fromAddress: fromAddress,
        toAddress: toAddress,
        departureDate: departureDate,
        departureTime: departureTime,
        passengerCount: passengerCount,
        totalPrice: totalPrice,
        tripType: tripType,
        passengers: passengers,
        baggage: baggage,
        pets: pets,
      );

      // Отправляем в Telegram
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
          'disable_web_page_preview': true,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Уведомление отправлено в Telegram: $orderId');
        return true;
      } else {
        print('❌ Ошибка отправки в Telegram: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Исключение при отправке в Telegram: $e');
      return false;
    }
  }

  /// Форматирование сообщения о заказе
  String _formatOrderMessage({
    required String orderId,
    required String fromAddress,
    required String toAddress,
    required String departureDate,
    required String departureTime,
    required int passengerCount,
    required double totalPrice,
    String? tripType,
    List<Map<String, dynamic>>? passengers,
    List<Map<String, dynamic>>? baggage,
    List<Map<String, dynamic>>? pets,
  }) {
    final buffer = StringBuffer();

    // Заголовок
    buffer.writeln('🚗 <b>НОВЫЙ ЗАКАЗ #$orderId</b>');
    buffer.writeln('');

    // Тип поездки
    if (tripType != null) {
      final typeEmoji = _getTripTypeEmoji(tripType);
      final typeName = _getTripTypeName(tripType);
      buffer.writeln('$typeEmoji <b>Тип:</b> $typeName');
      buffer.writeln('');
    }

    // Маршрут
    buffer.writeln('📍 <b>Маршрут:</b>');
    buffer.writeln('   🔵 Откуда: ${_shortAddress(fromAddress)}');
    buffer.writeln('   🔴 Куда: ${_shortAddress(toAddress)}');
    buffer.writeln('');

    // Дата и время
    buffer.writeln('📅 <b>Отправление:</b> $departureDate в $departureTime');
    buffer.writeln('');

    // Пассажиры
    if (passengers != null && passengers.isNotEmpty) {
      buffer.writeln('👥 <b>Пассажиры:</b>');
      final passengersInfo = _formatPassengers(passengers);
      buffer.writeln('   $passengersInfo');
      buffer.writeln('');
    }

    // Багаж
    if (baggage != null && baggage.isNotEmpty) {
      buffer.writeln('🧳 <b>Багаж:</b>');
      for (final item in baggage) {
        final baggageInfo = _formatBaggage(item);
        buffer.writeln('   $baggageInfo');
      }
      buffer.writeln('');
    }

    // Животные
    if (pets != null && pets.isNotEmpty) {
      buffer.writeln('🐕 <b>Животные:</b>');
      for (final pet in pets) {
        final petInfo = _formatPet(pet);
        buffer.writeln('   $petInfo');
      }
      buffer.writeln('');
    }

    // Цена
    buffer.writeln('💰 <b>ИТОГО:</b> ${totalPrice.toStringAsFixed(0)}₽');
    buffer.writeln('');

    // Ссылка на кабинет
    buffer.writeln('🔗 <a href="https://titotr.ru/dispatcher">Открыть кабинет диспетчера</a>');

    return buffer.toString();
  }

  String _getTripTypeEmoji(String type) {
    switch (type) {
      case 'group':
        return '👥';
      case 'individual':
        return '🚙';
      case 'customRoute':
        return '🗺️';
      default:
        return '🚗';
    }
  }

  String _getTripTypeName(String type) {
    switch (type) {
      case 'group':
        return 'Групповая поездка';
      case 'individual':
        return 'Индивидуальный трансфер';
      case 'customRoute':
        return 'Свободный маршрут';
      default:
        return type;
    }
  }

  String _shortAddress(String address) {
    // Укорачиваем длинные адреса
    if (address.length > 50) {
      return address.substring(0, 47) + '...';
    }
    return address;
  }

  String _formatPassengers(List<Map<String, dynamic>> passengers) {
    int adults = 0;
    int children = 0;
    final childSeats = <String>[];

    for (final p in passengers) {
      if (p['type'] == 'adult') {
        adults++;
      } else if (p['type'] == 'child') {
        children++;
        final seatType = p['seatType'] as String?;
        if (seatType != null) {
          childSeats.add(_getChildSeatName(seatType));
        }
      }
    }

    final parts = <String>[];
    if (adults > 0) parts.add('$adults взр.');
    if (children > 0) {
      if (childSeats.isNotEmpty) {
        parts.add('$children дет. (${childSeats.join(', ')})');
      } else {
        parts.add('$children дет.');
      }
    }

    return parts.join(', ');
  }

  String _getChildSeatName(String seatType) {
    switch (seatType) {
      case 'cradle':
        return 'люлька';
      case 'seat':
        return 'кресло';
      case 'booster':
        return 'бустер';
      case 'none':
        return 'без кресла';
      default:
        return seatType;
    }
  }

  String _formatBaggage(Map<String, dynamic> item) {
    final size = item['size'] as String?;
    final quantity = item['quantity'] as int? ?? 1;

    final sizeName = _getBaggageSizeName(size ?? 's');
    return '$sizeName × $quantity';
  }

  String _getBaggageSizeName(String size) {
    switch (size) {
      case 's':
        return 'Рюкзак (S)';
      case 'm':
        return 'Сумка (M)';
      case 'l':
        return 'Чемодан (L)';
      case 'custom':
        return 'Нестандартный';
      default:
        return size.toUpperCase();
    }
  }

  String _formatPet(Map<String, dynamic> pet) {
    final breed = pet['breed'] as String? ?? 'Животное';
    final category = pet['category'] as String?;

    if (category != null) {
      final categoryName = _getPetCategoryName(category);
      return '$breed ($categoryName)';
    }

    return breed;
  }

  String _getPetCategoryName(String category) {
    switch (category) {
      case 'upTo5kgWithCarrier':
        return 'до 5кг в переноске';
      case 'upTo5kgWithoutCarrier':
        return 'до 5кг без переноски';
      case 'over6kg':
        return 'свыше 6кг';
      default:
        return category;
    }
  }

  /// Отправка тестового сообщения
  Future<bool> sendTestMessage() async {
    if (!isConfigured) {
      print('⚠️ Telegram не настроен.');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'text': '✅ Telegram Bot подключен!\n\nВы будете получать уведомления о новых заказах.',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка тестирования Telegram: $e');
      return false;
    }
  }
}
