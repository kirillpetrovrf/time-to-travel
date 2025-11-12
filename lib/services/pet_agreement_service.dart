import 'package:flutter/foundation.dart';
import '../models/pet_info.dart';

/// Сервис для управления согласиями на перевозку животных (ТЗ v3.0)
/// Тексты согласий редактируются диспетчером через админ-панель
///
/// ⚠️ ВАЖНО: Сейчас используются только локальные данные
/// TODO: Интеграция с Firebase - реализуется позже
class PetAgreementService {
  // TODO: Интеграция с Firebase - реализуется позже
  // static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static const String _collectionPath = 'settings';
  // static const String _documentId = 'pet_agreements';

  /// Получение текста согласия для конкретного размера животного
  /// TODO: Интеграция с Firebase - реализуется позже
  static Future<String> getPetAgreementText(PetSize size) async {
    debugPrint(
      'ℹ️ Используются локальные тексты согласий (Firebase не подключен)',
    );
    return _getDefaultAgreementText(size);
  }

  /// Обновление текстов согласий (только для диспетчера)
  /// TODO: Интеграция с Firebase - реализуется позже
  static Future<void> updatePetAgreementTexts({
    required String smallPetAgreement,
    required String mediumPetAgreement,
    required String largePetAgreement,
  }) async {
    debugPrint(
      'ℹ️ Обновление текстов согласий сохранено локально (Firebase не подключен)',
    );
    // В будущем здесь будет сохранение в Firebase
  }

  /// Стрим для отслеживания изменений текстов в реальном времени
  /// TODO: Интеграция с Firebase - реализуется позже
  static Stream<Map<PetSize, String>> getPetAgreementTextsStream() {
    debugPrint(
      'ℹ️ Используется локальный стрим текстов согласий (Firebase не подключен)',
    );
    // Возвращаем стрим с дефолтными значениями
    return Stream.value(_getDefaultAgreementTexts());
  }

  /// Проверка, требуется ли согласие для конкретного размера
  static bool requiresAgreement(PetSize size) {
    return size == PetSize.m || size == PetSize.l;
  }

  /// Дефолтные тексты согласий
  static String _getDefaultAgreementText(PetSize size) {
    switch (size) {
      case PetSize.s:
        return ''; // Для маленьких животных согласие не требуется
      case PetSize.m:
        return 'Владелец обязуется иметь намордник у собаки и несет ответственность за поведение животного во время поездки.';
      case PetSize.l:
        return 'Владелец обязуется иметь намордник у собаки, согласен с обязательной химчисткой после поездки и несет полную ответственность за предотвращение дискомфорта других пассажиров.';
    }
  }

  /// Получение всех дефолтных текстов
  static Map<PetSize, String> _getDefaultAgreementTexts() {
    return {
      PetSize.s: _getDefaultAgreementText(PetSize.s),
      PetSize.m: _getDefaultAgreementText(PetSize.m),
      PetSize.l: _getDefaultAgreementText(PetSize.l),
    };
  }

  /// Получение краткого описания обязательств для UI
  static String getShortAgreementDescription(PetSize size) {
    switch (size) {
      case PetSize.s:
        return 'Дополнительные обязательства не требуются';
      case PetSize.m:
        return 'Обязательно наличие намордника';
      case PetSize.l:
        return 'Обязательно наличие намордника + химчистка';
    }
  }

  /// Валидация согласия перед созданием заказа
  static bool validatePetAgreement(PetInfo petInfo) {
    if (!requiresAgreement(petInfo.size)) {
      return true; // Согласие не требуется
    }

    return petInfo.agreementAccepted;
  }
}
