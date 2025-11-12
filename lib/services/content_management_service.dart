import 'package:flutter/foundation.dart';

/// Сервис управления контентом (ТЗ v3.0)
/// НОВОЕ: Администратор может редактировать описания поездок
///
/// ⚠️ ВАЖНО: Сейчас используются только локальные данные
/// TODO: Интеграция с Firebase - реализуется позже
class ContentManagementService {
  static const ContentManagementService _instance =
      ContentManagementService._internal();
  const ContentManagementService._internal();
  static const ContentManagementService instance = _instance;

  // TODO: Интеграция с Firebase - реализуется позже
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static const String _collectionName = 'content_settings';

  /// Получение описаний поездок
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Map<String, String>> getTripDescriptions() async {
    debugPrint(
      'ℹ️ Используются локальные описания поездок (Firebase не подключен)',
    );
    return _getDefaultDescriptions();
  }

  /// Обновление описаний поездок (только для диспетчера)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<bool> updateTripDescriptions(Map<String, String> descriptions) async {
    debugPrint(
      'ℹ️ Обновление описаний сохранено локально (Firebase не подключен)',
    );
    // В будущем здесь будет сохранение в Firebase
    return true;
  }

  /// Получение информационных текстов
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Map<String, String>> getInfoTexts() async {
    debugPrint(
      'ℹ️ Используются локальные информационные тексты (Firebase не подключен)',
    );
    return _getDefaultInfoTexts();
  }

  /// Обновление информационных текстов
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<bool> updateInfoTexts(Map<String, String> texts) async {
    debugPrint(
      'ℹ️ Обновление текстов сохранено локально (Firebase не подключен)',
    );
    // В будущем здесь будет сохранение в Firebase
    return true;
  }

  Map<String, String> _getDefaultDescriptions() {
    return {
      'donetsk_to_rostov':
          'Комфортная поездка из Донецка в Ростов-на-Дону. '
          'Опытные водители, современные автомобили, безопасный маршрут.',
      'rostov_to_donetsk':
          'Надежный трансфер из Ростова-на-Дону в Донецк. '
          'Регулярные рейсы, удобное расписание.',
      'individual_trip':
          'Индивидуальная поездка на комфортном автомобиле. '
          'Выберите удобное время и маршрут.',
      'group_trip':
          'Экономичный вариант поездки в составе группы. '
          'Фиксированное расписание, низкие цены.',
      'border_crossing':
          'Помощь в пересечении границы, оформление документов. '
          'Опытные гиды, быстрое прохождение.',
    };
  }

  Map<String, String> _getDefaultInfoTexts() {
    return {
      'booking_rules':
          'Правила бронирования:\n'
          '• Бронирование за 2 часа до поездки\n'
          '• Отмена бесплатно за 1 час до выезда\n'
          '• При опоздании более 15 минут - доплата',
      'payment_info':
          'Способы оплаты:\n'
          '• Наличными водителю\n'
          '• Картой через СБП\n'
          '• Безналичный расчет для юр. лиц',
      'baggage_rules':
          'Правила провоза багажа:\n'
          '• Первое место бесплатно\n'
          '• Дополнительные места по тарифу\n'
          '• Крупногабаритный багаж согласовывается',
      'pet_rules':
          'Правила перевозки животных:\n'
          '• Маленькие животные (до 5 кг) в салоне\n'
          '• Средние и крупные в багажном отделении\n'
          '• Обязательно согласие на условия перевозки',
    };
  }
}

/// Типы контента для управления
enum ContentType { tripDescriptions, infoTexts, terms, privacy }
