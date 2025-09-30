import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для интеграции с VKontakte (ОБНОВЛЕН под ТЗ v3.0)
/// ИЗМЕНЕНИЯ: Скидка изменена с постоянной на РАЗОВУЮ 300₽
class VKService {
  static const VKService _instance = VKService._internal();

  const VKService._internal();

  static const VKService instance = _instance;

  // Обновленные параметры под ТЗ v3.0
  static const String _mockVKAppId = '8112345';
  static const double _oneTimeDiscount =
      300.0; // НОВОЕ: разовая скидка 300₽ (было 30₽)

  /// Инициализация VK SDK
  Future<bool> initialize() async {
    try {
      // В реальном приложении здесь будет инициализация VK SDK
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('🔵 VK SDK инициализирован');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка инициализации VK SDK: $e');
      return false;
    }
  }

  /// Проверка авторизации пользователя в VK
  Future<bool> isUserAuthorized() async {
    try {
      // В реальном приложении здесь проверка токена VK
      await Future.delayed(const Duration(milliseconds: 300));

      // Мок: случайно возвращаем true/false для тестирования
      final isAuthorized = DateTime.now().millisecond % 2 == 0;
      debugPrint('🔵 VK авторизация проверена: $isAuthorized');
      return isAuthorized;
    } catch (e) {
      debugPrint('❌ Ошибка проверки VK авторизации: $e');
      return false;
    }
  }

  /// Авторизация пользователя в VK
  Future<VKAuthResult> authorize() async {
    try {
      // В реальном приложении здесь будет вызов VK авторизации
      await Future.delayed(const Duration(seconds: 2));

      // Мок: симулируем успешную авторизацию
      final mockResult = VKAuthResult(
        isSuccess: true,
        accessToken: 'vk_mock_token_${DateTime.now().millisecondsSinceEpoch}',
        userId: '123456789',
        firstName: 'Иван',
        lastName: 'Петров',
        photoUrl: 'https://example.com/photo.jpg',
      );

      debugPrint(
        '🔵 VK авторизация успешна: ${mockResult.firstName} ${mockResult.lastName}',
      );
      return mockResult;
    } catch (e) {
      debugPrint('❌ Ошибка VK авторизации: $e');
      return VKAuthResult(isSuccess: false, error: 'Ошибка авторизации: $e');
    }
  }

  /// Аутентификация пользователя в VK (алиас для authorize)
  Future<bool> authenticate() async {
    final result = await authorize();
    return result.isSuccess;
  }

  /// Получение текущего пользователя VK (алиас для getUserInfo)
  Future<VKUserInfo?> getCurrentUser() async {
    return await getUserInfo('mockUserId'); // Используем мок ID
  }

  /// Проверка доступности скидки VK (НОВОЕ под ТЗ v3.0)
  Future<bool> isDiscountAvailable(String vkUserId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vkDiscounts')
          .doc(vkUserId)
          .get();

      // Если записи нет - скидка доступна (первый раз)
      if (!doc.exists) return true;

      // Если уже использована - недоступна
      final data = doc.data()!;
      return !(data['used'] ?? false);
    } catch (e) {
      debugPrint('❌ Ошибка проверки VK скидки: $e');
      return false;
    }
  }

  /// Получение информации о пользователе
  Future<VKUserInfo?> getUserInfo(String accessToken) async {
    try {
      // В реальном приложении здесь API запрос к VK
      await Future.delayed(const Duration(milliseconds: 800));

      final mockUserInfo = VKUserInfo(
        userId: '123456789',
        firstName: 'Иван',
        lastName: 'Петров',
        photoUrl: 'https://example.com/photo.jpg',
        isVerified: true,
        profileUrl: 'https://vk.com/id123456789',
      );

      debugPrint(
        '🔵 Информация о пользователе VK получена: ${mockUserInfo.firstName}',
      );
      return mockUserInfo;
    } catch (e) {
      debugPrint('❌ Ошибка получения информации VK: $e');
      return null;
    }
  }

  /// Отключение от VK
  Future<void> logout() async {
    try {
      // В реальном приложении здесь очистка токенов VK
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('🔵 VK выход выполнен');
    } catch (e) {
      debugPrint('❌ Ошибка выхода из VK: $e');
    }
  }

  /// НОВОЕ: Проверка, может ли пользователь использовать разовую скидку VK
  Future<bool> canUseOneTimeDiscount(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final isVKVerified = userData['isVKVerified'] ?? false;
      final hasUsedVKDiscount = userData['hasUsedVKDiscount'] ?? false;

      // Скидка доступна только если верифицирован И еще не использовал
      return isVKVerified && !hasUsedVKDiscount;
    } catch (e) {
      debugPrint('❌ Ошибка проверки разовой скидки VK: $e');
      return false;
    }
  }

  /// НОВОЕ: Отметить разовую скидку VK как использованную
  Future<void> markOneTimeDiscountAsUsed(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'hasUsedVKDiscount': true,
      });

      debugPrint('🔵 Разовая скидка VK отмечена как использованная');
    } catch (e) {
      debugPrint('❌ Ошибка отметки использования скидки VK: $e');
      throw Exception('Не удалось отметить скидку как использованную');
    }
  }

  /// Получение размера разовой скидки за VK верификацию (ОБНОВЛЕНО)
  double get oneTimeDiscount => _oneTimeDiscount;

  /// Получение описания скидки (ОБНОВЛЕНО)
  String get discountDescription =>
      'Разовая скидка за верификацию VKontakte: ${_oneTimeDiscount.toInt()}₽';

  /// Валидация VK профиля для получения скидки
  Future<VKValidationResult> validateProfileForDiscount(String vkUserId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // В реальном приложении здесь проверка:
      // - Аккаунт не новый (создан более месяца назад)
      // - Есть фото профиля
      // - Заполнена основная информация
      // - Аккаунт не забанен

      final mockResult = VKValidationResult(
        isValid: true,
        hasPhoto: true,
        accountAge: 365, // дней
        isVerified: true,
        reason: null,
      );

      debugPrint('🔵 VK профиль валиден для скидки');
      return mockResult;
    } catch (e) {
      debugPrint('❌ Ошибка валидации VK профиля: $e');
      return VKValidationResult(
        isValid: false,
        hasPhoto: false,
        accountAge: 0,
        isVerified: false,
        reason: 'Ошибка проверки профиля',
      );
    }
  }

  /// Применение скидки VK к заказу
  Future<double> applyVKDiscount(double originalPrice, String vkUserId) async {
    try {
      final isAvailable = await isDiscountAvailable(vkUserId);
      if (!isAvailable) return originalPrice;

      final validation = await validateProfileForDiscount(vkUserId);
      if (!validation.isValid) return originalPrice;

      final discount = _oneTimeDiscount;
      final newPrice = (originalPrice - discount).clamp(0.0, originalPrice);

      debugPrint(
        '🔵 VK скидка применена: -$discount ₽ (${originalPrice} ₽ → ${newPrice} ₽)',
      );
      return newPrice;
    } catch (e) {
      debugPrint('❌ Ошибка применения VK скидки: $e');
      return originalPrice;
    }
  }
}

/// Результат авторизации VK
class VKAuthResult {
  final bool isSuccess;
  final String? accessToken;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? error;

  VKAuthResult({
    required this.isSuccess,
    this.accessToken,
    this.userId,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.error,
  });

  @override
  String toString() {
    return 'VKAuthResult(isSuccess: $isSuccess, userId: $userId, error: $error)';
  }
}

/// Информация о пользователе VK
class VKUserInfo {
  final String userId;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final bool isVerified;
  final String profileUrl;

  VKUserInfo({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.isVerified,
    required this.profileUrl,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'isVerified': isVerified,
      'profileUrl': profileUrl,
    };
  }

  factory VKUserInfo.fromJson(Map<String, dynamic> json) {
    return VKUserInfo(
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      photoUrl: json['photoUrl'],
      isVerified: json['isVerified'] ?? false,
      profileUrl: json['profileUrl'] ?? '',
    );
  }

  @override
  String toString() {
    return 'VKUserInfo(userId: $userId, fullName: $fullName, isVerified: $isVerified)';
  }
}

/// Результат валидации VK профиля
class VKValidationResult {
  final bool isValid;
  final bool hasPhoto;
  final int accountAge; // в днях
  final bool isVerified;
  final String? reason; // причина, если невалиден

  VKValidationResult({
    required this.isValid,
    required this.hasPhoto,
    required this.accountAge,
    required this.isVerified,
    this.reason,
  });

  bool get isEligibleForDiscount {
    return isValid && hasPhoto && accountAge >= 30; // аккаунт старше месяца
  }

  @override
  String toString() {
    return 'VKValidationResult(isValid: $isValid, hasPhoto: $hasPhoto, accountAge: $accountAge, reason: $reason)';
  }
}
