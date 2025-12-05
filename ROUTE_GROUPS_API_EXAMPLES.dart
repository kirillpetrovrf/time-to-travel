// 📖 ПРИМЕРЫ ИСПОЛЬЗОВАНИЯ API: Система групп маршрутов
// Скопируйте нужные фрагменты в ваш код

import 'package:time_to_travel/services/route_group_service.dart';
import 'package:time_to_travel/services/route_management_service.dart';
import 'package:time_to_travel/data/route_groups_initializer.dart';
import 'package:time_to_travel/models/route_group.dart';
import 'package:time_to_travel/models/predefined_route.dart';

// ============================================================================
// ПРИМЕР 1: Инициализация групп (один раз при первом запуске)
// ============================================================================

Future<void> initializeGroupsOnce() async {
  // Вариант 1: Безопасная инициализация (только если групп нет)
  await RouteGroupsInitializer.initializeGroups();
  
  // Вариант 2: Принудительная переинициализация (удалит старые группы)
  // await RouteGroupsInitializer.forceInitializeGroups();
  
  print('✅ Группы инициализированы');
}

// ============================================================================
// ПРИМЕР 2: Получение всех групп
// ============================================================================

Future<void> getAllGroupsExample() async {
  final groupService = RouteGroupService.instance;
  
  final groups = await groupService.getAllGroups();
  
  print('📦 Всего групп: ${groups.length}');
  for (final group in groups) {
    print('  - ${group.name}: ${group.basePrice}₽ (${group.potentialRoutesCount} маршрутов)');
  }
}

// ============================================================================
// ПРИМЕР 3: Получение одной группы по ID
// ============================================================================

Future<void> getGroupByIdExample() async {
  final groupService = RouteGroupService.instance;
  
  final group = await groupService.getGroupById('rostov_region');
  
  if (group != null) {
    print('📦 Группа: ${group.name}');
    print('   Базовая цена: ${group.basePrice}₽');
    print('   Описание: ${group.description}');
    print('   Города отправления: ${group.originCities.join(", ")}');
    print('   Города назначения: ${group.destinationCities.join(", ")}');
  }
}

// ============================================================================
// ПРИМЕР 4: Изменение базовой цены группы
// ============================================================================

Future<void> updateGroupPriceExample() async {
  final groupService = RouteGroupService.instance;
  final routeService = RouteManagementService.instance;
  
  const groupId = 'rostov_region';
  const newPrice = 9000.0;
  
  // Шаг 1: Обновить цену в самой группе
  await groupService.updateGroupPrice(groupId, newPrice);
  print('✅ Базовая цена группы обновлена до $newPrice₽');
  
  // Шаг 2: Применить к маршрутам с useGroupPrice=true
  await routeService.updateGroupRoutes(groupId, newPrice);
  print('✅ Цены маршрутов обновлены');
}

// ============================================================================
// ПРИМЕР 5: Получение маршрутов группы
// ============================================================================

Future<void> getRoutesInGroupExample() async {
  final routeService = RouteManagementService.instance;
  
  final routes = await routeService.getRoutesByGroup('rostov_region');
  
  print('📍 Маршруты группы "Ростовская область":');
  for (final route in routes) {
    final priceType = route.customPrice ? '✏️ Своя' : '🔗 Групповая';
    print('  - ${route.fromCity} → ${route.toCity}: ${route.price}₽ ($priceType)');
  }
}

// ============================================================================
// ПРИМЕР 6: Установка индивидуальной цены для маршрута
// ============================================================================

Future<void> setCustomRoutePriceExample() async {
  final routeService = RouteManagementService.instance;
  
  const routeId = 'route123'; // ID маршрута
  const customPrice = 12000.0;
  
  await routeService.updateRoutePrice(routeId, customPrice);
  
  print('✅ Маршрут получил индивидуальную цену $customPrice₽');
  print('   Флаги: useGroupPrice=false, customPrice=true');
}

// ============================================================================
// ПРИМЕР 7: Сброс маршрута к групповой цене
// ============================================================================

Future<void> resetToGroupPriceExample() async {
  final groupService = RouteGroupService.instance;
  final routeService = RouteManagementService.instance;
  
  const routeId = 'route123';
  const groupId = 'rostov_region';
  
  // Получить базовую цену группы
  final group = await groupService.getGroupById(groupId);
  if (group == null) {
    print('❌ Группа не найдена');
    return;
  }
  
  // Сбросить маршрут к групповой цене
  await routeService.resetRouteToGroupPrice(routeId, group.basePrice);
  
  print('✅ Маршрут вернулся к групповой цене ${group.basePrice}₽');
  print('   Флаги: useGroupPrice=true, customPrice=false');
}

// ============================================================================
// ПРИМЕР 8: Создание обратного маршрута
// ============================================================================

Future<void> createReverseRouteExample() async {
  final routeService = RouteManagementService.instance;
  
  // Исходный маршрут: Донецк → Ростов
  final originalRoute = PredefinedRoute(
    id: '',
    fromCity: 'Донецк',
    toCity: 'Ростов',
    price: 8000,
    groupId: 'rostov_region',
    useGroupPrice: true,
    customPrice: false,
    isReverse: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // Создать обратный маршрут: Ростов → Донецк
  // Метод возвращает ID нового маршрута
  final reverseRouteId = await routeService.createReverseRoute(originalRoute);
  
  print('✅ Создан обратный маршрут с ID: $reverseRouteId');
  print('   Ростов → Донецк: 8000₽');
  print('   Флаг isReverse: true');
}

// ============================================================================
// ПРИМЕР 9: Создание новой группы
// ============================================================================

Future<void> createNewGroupExample() async {
  final groupService = RouteGroupService.instance;
  
  final newGroup = RouteGroup(
    id: 'stavropol',
    name: 'Ставропольский край',
    description: 'Города Ставропольского края',
    basePrice: 35000,
    originCities: ['Донецк', 'Макеевка'],
    destinationCities: ['Ставрополь', 'Пятигорск', 'Кисловодск'],
    autoGenerateReverse: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  await groupService.createGroup(newGroup);
  
  print('✅ Создана новая группа: ${newGroup.name}');
}

// ============================================================================
// ПРИМЕР 10: Массовое добавление групп
// ============================================================================

Future<void> batchAddGroupsExample() async {
  final groupService = RouteGroupService.instance;
  
  final groups = [
    RouteGroup(
      id: 'group1',
      name: 'Группа 1',
      description: 'Описание 1',
      basePrice: 10000,
      originCities: ['Город А'],
      destinationCities: ['Город Б'],
      autoGenerateReverse: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    RouteGroup(
      id: 'group2',
      name: 'Группа 2',
      description: 'Описание 2',
      basePrice: 15000,
      originCities: ['Город В'],
      destinationCities: ['Город Г'],
      autoGenerateReverse: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  
  await groupService.addGroupsBatch(groups);
  
  print('✅ Добавлено ${groups.length} групп');
}

// ============================================================================
// ПРИМЕР 11: Удаление группы
// ============================================================================

Future<void> deleteGroupExample() async {
  final groupService = RouteGroupService.instance;
  
  await groupService.deleteGroup('group1');
  
  print('✅ Группа удалена');
  print('⚠️ Маршруты сохранены, но потеряли связь с группой');
}

// ============================================================================
// ПРИМЕР 12: Подписка на изменения групп (realtime)
// ============================================================================

void listenToGroupsExample() {
  final groupService = RouteGroupService.instance;
  
  groupService.getGroupsStream().listen((groups) {
    print('🔄 Группы обновлены в реальном времени');
    print('   Всего групп: ${groups.length}');
    for (final group in groups) {
      print('   - ${group.name}: ${group.basePrice}₽');
    }
  });
}

// ============================================================================
// ПРИМЕР 13: Статистика по группам
// ============================================================================

Future<void> getGroupsStatsExample() async {
  final stats = RouteGroupsInitializer.groupStats;
  
  print('📊 Статистика групп:');
  print('   Всего групп: ${stats['totalGroups']}');
  print('   Потенциальных маршрутов: ${stats['totalPotentialRoutes']}');
  print('   Средняя цена: ${stats['averagePrice']}₽');
}

// ============================================================================
// ПРИМЕР 14: Полный workflow - изменение цены группы
// ============================================================================

Future<void> completeWorkflowExample() async {
  final groupService = RouteGroupService.instance;
  final routeService = RouteManagementService.instance;
  
  // 1. Получить группу
  final group = await groupService.getGroupById('rostov_region');
  if (group == null) {
    print('❌ Группа не найдена');
    return;
  }
  
  print('📦 Группа: ${group.name}');
  print('   Текущая цена: ${group.basePrice}₽');
  
  // 2. Получить маршруты группы
  final routes = await routeService.getRoutesByGroup(group.id);
  print('📍 Маршрутов в группе: ${routes.length}');
  
  // 3. Посчитать сколько маршрутов с групповой ценой
  final groupPriceRoutes = routes.where((r) => !r.customPrice).length;
  final customPriceRoutes = routes.where((r) => r.customPrice).length;
  print('   🔗 С групповой ценой: $groupPriceRoutes');
  print('   ✏️ С индивидуальной: $customPriceRoutes');
  
  // 4. Обновить групповую цену
  const newPrice = 9500.0;
  await groupService.updateGroupPrice(group.id, newPrice);
  print('✅ Базовая цена группы обновлена до $newPrice₽');
  
  // 5. Применить к маршрутам
  await routeService.updateGroupRoutes(group.id, newPrice);
  print('✅ Обновлено $groupPriceRoutes маршрутов');
  print('⚠️ $customPriceRoutes маршрутов с индивидуальной ценой не изменились');
}

// ============================================================================
// 🎯 РЕКОМЕНДАЦИИ
// ============================================================================

/*

1. ИНИЦИАЛИЗАЦИЯ:
   - Вызывайте RouteGroupsInitializer.initializeGroups() один раз при первом запуске
   - Используйте SharedPreferences для хранения флага инициализации

2. ПРОИЗВОДИТЕЛЬНОСТЬ:
   - Используйте getGroupsStream() для realtime обновлений вместо polling
   - Кешируйте результаты getAllGroups() в памяти

3. ОШИБКИ:
   - Всегда оборачивайте вызовы в try-catch
   - Проверяйте null при getGroupById()

4. FIREBASE:
   - Все операции автоматически синхронизируются с Firestore
   - Работает в offline-режиме через SQLite

5. ТЕСТИРОВАНИЕ:
   - Используйте forceInitializeGroups() для сброса данных в тестах
   - Проверяйте флаги useGroupPrice и customPrice после операций

*/
