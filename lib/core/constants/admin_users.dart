/// Список телефонов администраторов с доступом к панели диспетчера
class AdminUsers {
  /// Список телефонов администраторов
  static const List<String> adminPhones = [
    '+79504455444', // Кирилл Петров (разработчик)
    '+79895342496', // Евгений @nepeBo34uk (заказчик)
  ];

  /// Проверка, является ли пользователь администратором
  static bool isAdmin(String? phone) {
    if (phone == null || phone.isEmpty) return false;

    // Нормализация номера (удаление пробелов, дефисов, скобок)
    final normalizedPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    return adminPhones.any((adminPhone) {
      final normalizedAdmin = adminPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      return normalizedAdmin == normalizedPhone;
    });
  }
}
