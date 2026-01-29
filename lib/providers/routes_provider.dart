import 'package:flutter/foundation.dart';
import '../services/api/routes_api_service.dart';
import '../services/api/route_groups_api_service.dart';

/// Состояние загрузки данных
enum RoutesLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider для управления маршрутами и группами
/// Используется в кабинете диспетчера для CRM
class RoutesProvider extends ChangeNotifier {
  final RoutesApiService _routesService;
  final RouteGroupsApiService _groupsService;

  // === Состояние маршрутов ===
  List<ApiPredefinedRoute> _routes = [];
  RoutesLoadingState _routesState = RoutesLoadingState.initial;
  String? _routesError;

  // === Состояние групп ===
  List<ApiRouteGroup> _groups = [];
  RoutesLoadingState _groupsState = RoutesLoadingState.initial;
  String? _groupsError;

  // === Время последнего обновления ===
  DateTime? _lastRoutesUpdate;
  DateTime? _lastGroupsUpdate;

  // === Кэширование (5 минут) ===
  static const Duration _cacheTimeout = Duration(minutes: 5);

  RoutesProvider({
    RoutesApiService? routesService,
    RouteGroupsApiService? groupsService,
  })  : _routesService = routesService ?? RoutesApiService(),
        _groupsService = groupsService ?? RouteGroupsApiService();

  // === Getters ===

  List<ApiPredefinedRoute> get routes => _routes;
  RoutesLoadingState get routesState => _routesState;
  String? get routesError => _routesError;
  bool get isRoutesLoading => _routesState == RoutesLoadingState.loading;

  List<ApiRouteGroup> get groups => _groups;
  RoutesLoadingState get groupsState => _groupsState;
  String? get groupsError => _groupsError;
  bool get isGroupsLoading => _groupsState == RoutesLoadingState.loading;

  /// Проверка валидности кэша маршрутов
  bool get _isRoutesCacheValid {
    if (_lastRoutesUpdate == null) return false;
    return DateTime.now().difference(_lastRoutesUpdate!) < _cacheTimeout;
  }

  /// Проверка валидности кэша групп
  bool get _isGroupsCacheValid {
    if (_lastGroupsUpdate == null) return false;
    return DateTime.now().difference(_lastGroupsUpdate!) < _cacheTimeout;
  }

  // === МАРШРУТЫ ===

  /// Загрузить все маршруты
  Future<void> loadRoutes({bool forceRefresh = false}) async {
    // Используем кэш если не форсируем обновление
    if (!forceRefresh && _isRoutesCacheValid && _routes.isNotEmpty) {
      return;
    }

    _routesState = RoutesLoadingState.loading;
    _routesError = null;
    notifyListeners();

    try {
      _routes = await _routesService.getAllRoutes();
      _routesState = RoutesLoadingState.loaded;
      _lastRoutesUpdate = DateTime.now();
    } catch (e) {
      _routesState = RoutesLoadingState.error;
      _routesError = e.toString();
    }

    notifyListeners();
  }

  /// Поиск маршрутов по направлению
  Future<List<ApiPredefinedRoute>> searchRoutes({
    String? from,
    String? to,
  }) async {
    try {
      final response = await _routesService.searchRoutes(
        from: from,
        to: to,
      );
      return response.routes;
    } catch (e) {
      rethrow;
    }
  }

  /// Создать маршрут
  Future<ApiPredefinedRoute> createRoute({
    required String fromCity,
    required String toCity,
    required double price,
    String? groupId,
  }) async {
    try {
      final route = await _routesService.createRoute(
        fromCity: fromCity,
        toCity: toCity,
        price: price,
        groupId: groupId,
      );

      // Добавляем в локальный список
      _routes.add(route);
      notifyListeners();

      return route;
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить маршрут
  Future<ApiPredefinedRoute> updateRoute({
    required String id,
    String? fromCity,
    String? toCity,
    double? price,
    String? groupId,
    bool? isActive,
  }) async {
    try {
      final updated = await _routesService.updateRoute(
        id: id,
        fromCity: fromCity,
        toCity: toCity,
        price: price,
        groupId: groupId,
        isActive: isActive,
      );

      // Обновляем в локальном списке
      final index = _routes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _routes[index] = updated;
        notifyListeners();
      }

      return updated;
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить маршрут
  Future<bool> deleteRoute(String id) async {
    try {
      await _routesService.deleteRoute(id);

      // Удаляем из локального списка
      _routes.removeWhere((r) => r.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Массовая загрузка маршрутов
  Future<Map<String, dynamic>> batchCreateRoutes({
    required List<Map<String, dynamic>> routes,
    bool skipDuplicates = true,
  }) async {
    try {
      final result = await _routesService.batchCreateRoutes(
        routes: routes,
        skipDuplicates: skipDuplicates,
      );

      // Обновляем список после batch загрузки
      await loadRoutes(forceRefresh: true);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // === ГРУППЫ ===

  /// Загрузить все группы
  Future<void> loadGroups({bool forceRefresh = false}) async {
    // Используем кэш если не форсируем обновление
    if (!forceRefresh && _isGroupsCacheValid && _groups.isNotEmpty) {
      return;
    }

    _groupsState = RoutesLoadingState.loading;
    _groupsError = null;
    notifyListeners();

    try {
      _groups = await _groupsService.getAllGroups();
      _groupsState = RoutesLoadingState.loaded;
      _lastGroupsUpdate = DateTime.now();
    } catch (e) {
      _groupsState = RoutesLoadingState.error;
      _groupsError = e.toString();
    }

    notifyListeners();
  }

  /// Получить группу с маршрутами
  Future<Map<String, dynamic>> getGroupWithRoutes(String id) async {
    try {
      return await _groupsService.getGroupWithRoutes(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Создать группу
  Future<ApiRouteGroup> createGroup({
    required String name,
    String? description,
    double basePrice = 0,
  }) async {
    try {
      final group = await _groupsService.createGroup(
        name: name,
        description: description,
        basePrice: basePrice,
      );

      // Добавляем в локальный список
      _groups.add(group);
      notifyListeners();

      return group;
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить группу
  Future<ApiRouteGroup> updateGroup({
    required String id,
    String? name,
    String? description,
    double? basePrice,
    bool? isActive,
  }) async {
    try {
      final updated = await _groupsService.updateGroup(
        id: id,
        name: name,
        description: description,
        basePrice: basePrice,
        isActive: isActive,
      );

      // Обновляем в локальном списке
      final index = _groups.indexWhere((g) => g.id == id);
      if (index != -1) {
        _groups[index] = updated;
        notifyListeners();
      }

      return updated;
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить группу
  Future<bool> deleteGroup(String id) async {
    try {
      await _groupsService.deleteGroup(id);

      // Удаляем из локального списка
      _groups.removeWhere((g) => g.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // === УТИЛИТЫ ===

  /// Загрузить всё (маршруты и группы)
  Future<void> loadAll({bool forceRefresh = false}) async {
    await Future.wait([
      loadRoutes(forceRefresh: forceRefresh),
      loadGroups(forceRefresh: forceRefresh),
    ]);
  }

  /// Обновить данные (pull-to-refresh)
  Future<void> refresh() async {
    await loadAll(forceRefresh: true);
  }

  /// Получить маршруты по группе
  List<ApiPredefinedRoute> getRoutesByGroup(String groupId) {
    return _routes.where((r) => r.groupId == groupId).toList();
  }

  /// Найти маршрут по ID
  ApiPredefinedRoute? getRouteById(String id) {
    try {
      return _routes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Найти группу по ID
  ApiRouteGroup? getGroupById(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Очистить кэш
  void clearCache() {
    _routes = [];
    _groups = [];
    _lastRoutesUpdate = null;
    _lastGroupsUpdate = null;
    _routesState = RoutesLoadingState.initial;
    _groupsState = RoutesLoadingState.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _routesService.dispose();
    _groupsService.dispose();
    super.dispose();
  }
}
