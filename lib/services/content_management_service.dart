import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис управления контентом (ТЗ v3.0)
/// НОВОЕ: Администратор может редактировать описания поездок
class ContentManagementService {
  static const ContentManagementService _instance =
      ContentManagementService._internal();
  const ContentManagementService._internal();
  static const ContentManagementService instance = _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'content_settings';

  /// Получение описаний поездок
  Future<Map<String, String>> getTripDescriptions() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc('trip_descriptions')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return Map<String, String>.from(data);
      }

      // Значения по умолчанию
      return _getDefaultDescriptions();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки описаний поездок: $e');
      return _getDefaultDescriptions();
    }
  }

  /// Обновление описаний поездок (только для диспетчера)
  Future<bool> updateTripDescriptions(Map<String, String> descriptions) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc('trip_descriptions')
          .set(descriptions);

      debugPrint('✅ Описания поездок обновлены');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка обновления описаний: $e');
      return false;
    }
  }

  /// Получение информационных текстов
  Future<Map<String, String>> getInfoTexts() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc('info_texts')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return Map<String, String>.from(data);
      }

      return _getDefaultInfoTexts();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки информационных текстов: $e');
      return _getDefaultInfoTexts();
    }
  }

  /// Обновление информационных текстов
  Future<bool> updateInfoTexts(Map<String, String> texts) async {
    try {
      await _firestore.collection(_collectionName).doc('info_texts').set(texts);

      debugPrint('✅ Информационные тексты обновлены');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка обновления текстов: $e');
      return false;
    }
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
