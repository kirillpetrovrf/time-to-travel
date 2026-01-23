import '../models/route_group.dart';
import 'local_route_groups_service.dart';

/// Сервис для управления группами маршрутов
/// РАБОТАЕТ БЕЗ FIREBASE - СОХРАНЯЕТ В SQLite!
class RouteGroupService {
  static final RouteGroupService _instance = RouteGroupService._internal();
  static RouteGroupService get instance => _instance;

  RouteGroupService._internal();
  
  // Локальный SQLite сервис (аналогия с маршрутами)
  final LocalRouteGroupsService _localService = LocalRouteGroupsService.instance;

  /// Получить все группы маршрутов
  Future<List<RouteGroup>> getAllGroups({bool forceRefresh = false}) async {
    try {
      print('📂 Загружаем все группы маршрутов...');

      // ✅ ИСПОЛЬЗУЕМ SQLITE ВМЕСТО FIREBASE!
      final groups = await _localService.getAllGroups();

      print('✅ Загружено ${groups.length} групп маршрутов из SQLite');
      return groups;
    } catch (e) {
      print('❌ Ошибка загрузки групп маршрутов: $e');
      return [];
    }
  }

  /// Получить группу по ID
  Future<RouteGroup?> getGroupById(String groupId) async {
    try {
      // ✅ ИСПОЛЬЗУЕМ SQLITE!
      return await _localService.getGroupById(groupId);
    } catch (e) {
      print('❌ Ошибка получения группы $groupId: $e');
      return null;
    }
  }

  /// Создать новую группу
  Future<void> createGroup(RouteGroup group) async {
    try {
      print('📝 Создаем новую группу:');
      print('   ID: ${group.id}');
      print('   Название: ${group.name}');
      print('   Цена: ${group.basePrice}₽');
      print('   Города отправления: ${group.originCities.join(", ")}');
      print('   Города назначения: ${group.destinationCities.join(", ")}');
      
      // ✅ СОХРАНЯЕМ В SQLITE!
      await _localService.saveGroup(group);

      print('✅ Создана группа: ${group.name} (сохранено в SQLite)');
    } catch (e) {
      print('❌ Ошибка создания группы: $e');
      print('   Тип ошибки: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Обновить базовую цену группы
  Future<void> updateGroupPrice(String groupId, double newPrice) async {
    try {
      // ✅ ПОЛУЧАЕМ ИЗ SQLITE И ОБНОВЛЯЕМ
      final group = await _localService.getGroupById(groupId);
      if (group != null) {
        await _localService.updateGroup(group.copyWith(
          basePrice: newPrice,
          updatedAt: DateTime.now(),
        ));
        print('✅ Обновлена цена группы $groupId: $newPrice₽');
      } else {
        print('❌ Группа $groupId не найдена');
      }
    } catch (e) {
      print('❌ Ошибка обновления цены группы: $e');
      rethrow;
    }
  }

  /// Обновить группу целиком
  Future<void> updateGroup(RouteGroup group) async {
    try {
      print('📝 Обновляем группу ${group.id}: ${group.name}');
      
      // ✅ ОБНОВЛЯЕМ В SQLITE!
      await _localService.updateGroup(group);

      print('✅ Обновлена группа: ${group.name}');
    } catch (e) {
      print('❌ Ошибка обновления группы: $e');
      print('   Детали ошибки: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Удалить группу
  Future<void> deleteGroup(String groupId) async {
    try {
      // ✅ УДАЛЯЕМ ИЗ SQLITE!
      await _localService.deleteGroup(groupId);

      print('✅ Удалена группа: $groupId');
    } catch (e) {
      print('❌ Ошибка удаления группы: $e');
      rethrow;
    }
  }

  /// Добавить пакет групп
  Future<void> addGroupsBatch(List<RouteGroup> groups) async {
    try {
      // ✅ СОХРАНЯЕМ ПАКЕТ В SQLITE!
      await _localService.saveGroupsBatch(groups);
      
      print('✅ Добавлено ${groups.length} групп пакетом (в SQLite)');
    } catch (e) {
      print('❌ Ошибка добавления групп пакетом: $e');
      rethrow;
    }
  }

  /// Стрим для отслеживания изменений групп (заглушка - работаем через SQLite)
  Stream<List<RouteGroup>> getGroupsStream() {
    // Возвращаем пустой стрим, т.к. Firebase удалён
    print('⚠️ getGroupsStream() вызван, но Firebase удалён. Используйте getAllGroups()');
    return Stream.value([]);
  }
}
