import '../models/route_group.dart';

/// ⚠️ DEPRECATED: SQLite удалён, RouteGroups должны храниться в PostgreSQL
/// Сервис для управления группами маршрутов
/// TODO: Переписать на использование PostgreSQL API или удалить если не нужен
class RouteGroupService {
  static final RouteGroupService _instance = RouteGroupService._internal();
  static RouteGroupService get instance => _instance;

  RouteGroupService._internal();

  /// Получить все группы маршрутов
  /// ⚠️ DEPRECATED: LocalRouteGroupsService удалён, возвращаем пустой список
  Future<List<RouteGroup>> getAllGroups({bool forceRefresh = false}) async {
    print('⚠️ RouteGroupService DEPRECATED: SQLite удалён');
    print('💡 TODO: Реализовать загрузку через PostgreSQL API');
    return [];
  }

  /// Получить группу по ID
  /// ⚠️ DEPRECATED
  Future<RouteGroup?> getGroupById(String groupId) async {
    print('⚠️ RouteGroupService.getGroupById DEPRECATED');
    return null;
  }

  /// Создать новую группу
  /// ⚠️ DEPRECATED
  Future<void> createGroup(RouteGroup group) async {
    print('⚠️ RouteGroupService.createGroup DEPRECATED');
  }

  /// Обновить базовую цену группы
  /// ⚠️ DEPRECATED
  Future<void> updateGroupPrice(String groupId, double newPrice) async {
    print('⚠️ RouteGroupService.updateGroupPrice DEPRECATED');
  }

  /// Обновить группу целиком
  /// ⚠️ DEPRECATED
  Future<void> updateGroup(RouteGroup group) async {
    print('⚠️ RouteGroupService.updateGroup DEPRECATED');
  }

  /// Удалить группу
  /// ⚠️ DEPRECATED
  Future<void> deleteGroup(String groupId) async {
    print('⚠️ RouteGroupService.deleteGroup DEPRECATED');
  }

  /// Добавить пакет групп
  /// ⚠️ DEPRECATED
  Future<void> addGroupsBatch(List<RouteGroup> groups) async {
    print('⚠️ RouteGroupService.addGroupsBatch DEPRECATED');
  }

  /// Стрим для отслеживания изменений групп (заглушка - работаем через SQLite)
  /// ⚠️ DEPRECATED
  Stream<List<RouteGroup>> getGroupsStream() {
    print('⚠️ RouteGroupService.getGroupsStream DEPRECATED');
    return Stream.value([]);
  }
}
