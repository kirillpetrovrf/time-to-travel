import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_info.dart';

/// Сервис для управления согласиями на перевозку животных (ТЗ v3.0)
/// Тексты согласий редактируются диспетчером через админ-панель
class PetAgreementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'settings';
  static const String _documentId = 'pet_agreements';

  /// Получение текста согласия для конкретного размера животного
  static Future<String> getPetAgreementText(PetSize size) async {
    try {
      final doc = await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        return _getDefaultAgreementText(size);
      }

      final data = doc.data() as Map<String, dynamic>;

      switch (size) {
        case PetSize.s:
          return data['small_pet_agreement'] ?? _getDefaultAgreementText(size);
        case PetSize.m:
          return data['medium_pet_agreement'] ?? _getDefaultAgreementText(size);
        case PetSize.l:
          return data['large_pet_agreement'] ?? _getDefaultAgreementText(size);
      }
    } catch (e) {
      print('Ошибка загрузки текста согласия: $e');
      return _getDefaultAgreementText(size);
    }
  }

  /// Обновление текстов согласий (только для диспетчера)
  static Future<void> updatePetAgreementTexts({
    required String smallPetAgreement,
    required String mediumPetAgreement,
    required String largePetAgreement,
  }) async {
    try {
      await _firestore.collection(_collectionPath).doc(_documentId).set({
        'small_pet_agreement': smallPetAgreement,
        'medium_pet_agreement': mediumPetAgreement,
        'large_pet_agreement': largePetAgreement,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Ошибка обновления текстов согласий: $e');
      throw Exception('Не удалось обновить тексты согласий');
    }
  }

  /// Стрим для отслеживания изменений текстов в реальном времени
  static Stream<Map<PetSize, String>> getPetAgreementTextsStream() {
    return _firestore
        .collection(_collectionPath)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return _getDefaultAgreementTexts();
          }

          final data = doc.data() as Map<String, dynamic>;

          return {
            PetSize.s:
                data['small_pet_agreement'] ??
                _getDefaultAgreementText(PetSize.s),
            PetSize.m:
                data['medium_pet_agreement'] ??
                _getDefaultAgreementText(PetSize.m),
            PetSize.l:
                data['large_pet_agreement'] ??
                _getDefaultAgreementText(PetSize.l),
          };
        });
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
