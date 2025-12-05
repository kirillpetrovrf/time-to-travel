import '../models/predefined_route.dart';
import '../services/route_management_service.dart';

/// Инициализация предустановленных маршрутов такси из ДНР
class RouteInitializer {
  
  /// Создать маршрут с групповой ценой
  static PredefinedRoute _createRoute(
    String from,
    String to,
    double price,
    String groupId,
    DateTime now,
  ) {
    return PredefinedRoute(
      id: '',
      fromCity: from,
      toCity: to,
      price: price,
      groupId: groupId,
      useGroupPrice: true,      // Использует цену группы
      customPrice: false,        // НЕ переопределена
      isReverse: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Создать маршрут с индивидуальной ценой (исключение)
  static PredefinedRoute _createRouteWithCustomPrice(
    String from,
    String to,
    double price,
    String groupId,
    DateTime now,
  ) {
    return PredefinedRoute(
      id: '',
      fromCity: from,
      toCity: to,
      price: price,
      groupId: groupId,
      useGroupPrice: false,     // НЕ использует цену группы
      customPrice: true,         // Переопределена вручную
      isReverse: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Полный список всех реальных маршрутов такси из ДНР (44 маршрута - ТОЛЬКО из пользовательского списка)
  static List<PredefinedRoute> get initialRoutes {
    final now = DateTime.now();
    
    return [
      // СТРОГО по пользовательскому списку - никаких придуманных маршрутов!
      PredefinedRoute(
        id: '',
        fromCity: 'Енакиево',
        toCity: 'Ростов',
        price: 12000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Харцызск',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Горловка',
        toCity: 'Ростов',
        price: 15000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Амвросиевка',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Зугрэс',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Шахтёрск',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Торез',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Иловайский',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Старобешево',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Новый свет',
        toCity: 'Ростов',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Новоазовск',
        price: 7000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Седово',
        price: 7000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Мариуполь',
        price: 7000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Мелекино',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Юрьевка',
        price: 8500,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'урзуф',
        price: 8500,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Бердянск',
        price: 12000,
        createdAt: now,
        updatedAt: now,
      ),
      // КРЫМСКИЙ ПОЛУОСТРОВ - все маршруты с единой ценой за весь регион
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Республика Крым',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Симферополь',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Ялта',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Севастополь',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Евпатория',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Феодосия',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Керчь',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Алушта',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Судак',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Балаклава',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Белогорск',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Саки',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Джанкой',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Красноперекопск',
        price: 45000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Волноваха',
        toCity: 'Ростов',
        price: 13000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Еленовка',
        toCity: 'Ростов',
        price: 10000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Мариуполь',
        toCity: 'Ростов',
        price: 10000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Волгоград',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'минводы',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Харцызск',
        toCity: 'Волгоград',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Харцызск',
        toCity: 'минводы',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Анапа',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Сочи',
        price: 50000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Сочи аэропорт',
        price: 55000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Батайск',
        price: 10000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Аксай',
        price: 10000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Докучаевск',
        toCity: 'Ростов',
        price: 12000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Геленджик',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'дивномрское',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Макеевка',
        toCity: 'Волгоград',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Макеевка',
        toCity: 'минводы',
        price: 40000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Ейск',
        price: 22000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Макеевка',
        toCity: 'Ейск',
        price: 22000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Енакиево',
        toCity: 'Ейск',
        price: 24000,
        createdAt: now,
        updatedAt: now,
      ),
      // Дублированный маршрут Донецк-Сочи (второй в списке)
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Москва',
        price: 77000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Ясиноватая',
        toCity: 'Ростов',
        price: 12000,
        createdAt: now,
        updatedAt: now,
      ),
      // Дублированный маршрут Горловка-Ростов (второй в списке)
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Воронеж',
        price: 50000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'РОСТОВ',
        price: 8000,
        createdAt: now,
        updatedAt: now,
      ),
      // НОВЫЕ МАРШРУТЫ С КРАСНОДАРОМ (декабрь 2025) - в обе стороны
      PredefinedRoute(
        id: '',
        fromCity: 'Донецк',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Макеевка',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Харцызск',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Иловайск',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Амвросиевка',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Пункт пропуска Авило Успенка',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      // Дополнительные варианты и обратные направления для надежного совпадения
      PredefinedRoute(
        id: '',
        fromCity: 'Пункт пропуска Авило-Успенка',
        toCity: 'Краснодар',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      // Обратные направления (Краснодар -> исходный город)
      PredefinedRoute(
        id: '',
        fromCity: 'Краснодар',
        toCity: 'Донецк',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Краснодар',
        toCity: 'Макеевка',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Краснодар',
        toCity: 'Харцызск',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Краснодар',
        toCity: 'Иловайск',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Краснодар',
        toCity: 'Амвросиевка',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: '',
        fromCity: 'Краснодар',
        toCity: 'Пункт пропуска Авило-Успенка',
        price: 30000,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
  
  /// Статистика маршрутов
  static Map<String, dynamic> get routeStats {
    final routes = initialRoutes;
    final cities = <String>{};
    double totalPrice = 0;
    
    for (final route in routes) {
      cities.add(route.fromCity);
      cities.add(route.toCity);
      totalPrice += route.price;
    }
    
    return {
      'total_routes': routes.length,
      'unique_cities': cities.length,
      'avg_price': (totalPrice / routes.length).round(),
    };
  }
  
  /// ПОЛНАЯ ОЧИСТКА И ЗАГРУЗКА ТОЛЬКО ПОЛЬЗОВАТЕЛЬСКИХ МАРШРУТОВ
  static Future<void> forceInitializeOnlyUserRoutes() async {
    try {
      print('🧹 ПОЛНАЯ ОЧИСТКА базы от всех маршрутов (включая придуманные)...');
      print('📋 Загружаем ТОЛЬКО ${initialRoutes.length} маршрутов из пользовательского списка...');
      
      final service = RouteManagementService.instance;
      
      // ПОЛНАЯ ОЧИСТКА - удаляем все маршруты
      final existingRoutes = await service.getAllRoutes();
      print('🗑️ Найдено ${existingRoutes.length} маршрутов для удаления...');
      
      for (final route in existingRoutes) {
        await service.deleteRoute(route.id);
      }
      print('✅ Очищено ${existingRoutes.length} маршрутов (включая все придуманные)');
      
      // Добавляем ТОЛЬКО маршруты из пользовательского списка
      await service.addRoutesBatch(initialRoutes);
      
      print('✅ ОЧИСТКА И ЗАГРУЗКА ЗАВЕРШЕНА!');
      print('📊 Добавлено ТОЛЬКО пользовательских маршрутов: ${initialRoutes.length}');
      
      final stats = routeStats;
      print('📈 Финальная статистика:');
      print('   • Всего маршрутов: ${stats['total_routes']}');
      print('   • Уникальных городов: ${stats['unique_cities']}');
      print('   • Средняя цена: ${stats['avg_price']}₽');
      print('   • ✅ Все придуманные маршруты удалены!');
      
    } catch (e) {
      print('❌ Ошибка при очистке и загрузке пользовательских маршрутов: $e');
      rethrow;
    }
  }

  /// Принудительная инициализация всех маршрутов (очистка и повторное добавление)
  static Future<void> forceInitializeRoutes() async {
    // Используем новую функцию для очистки и загрузки только пользовательских
    await forceInitializeOnlyUserRoutes();
  }

  /// Инициализация всех маршрутов в Firebase
  static Future<void> initializeRoutes() async {
    try {
      print('🚀 Начинается инициализация ${initialRoutes.length} маршрутов...');
      
      final service = RouteManagementService.instance;
      
      // Проверяем, есть ли уже маршруты из RouteInitializer в базе
      final existingRoutes = await service.getAllRoutes();
      
      // Считаем, сколько маршрутов из RouteInitializer уже есть в базе
      int existingInitializerRoutes = 0;
      for (final route in initialRoutes) {
        final exists = existingRoutes.any((existing) =>
            existing.fromCity == route.fromCity &&
            existing.toCity == route.toCity);
        if (exists) existingInitializerRoutes++;
      }
      
      if (existingInitializerRoutes >= initialRoutes.length) {
        print('⚠️ Все ${initialRoutes.length} маршрутов RouteInitializer уже есть в базе (всего маршрутов: ${existingRoutes.length}). Пропускаем инициализацию.');
        return;
      }
      
      if (existingInitializerRoutes > 0) {
        print('📊 Найдено ${existingInitializerRoutes} из ${initialRoutes.length} маршрутов RouteInitializer. Добавляем недостающие...');
      }
      
      // Добавляем только те маршруты, которых еще нет в базе
      final routesToAdd = <PredefinedRoute>[];
      for (final route in initialRoutes) {
        final exists = existingRoutes.any((existing) =>
            existing.fromCity == route.fromCity &&
            existing.toCity == route.toCity);
        if (!exists) {
          routesToAdd.add(route);
        }
      }
      
      if (routesToAdd.isNotEmpty) {
        await service.addRoutesBatch(routesToAdd);
        print('✅ Добавлено ${routesToAdd.length} новых маршрутов');
      }
      
      print('✅ Инициализация завершена успешно!');
      if (routesToAdd.isNotEmpty) {
        print('📊 Добавлено новых маршрутов: ${routesToAdd.length}');
      } else {
        print('📊 Новых маршрутов для добавления не найдено');
      }
      
      // Проверяем финальное состояние базы
      final finalRoutes = await service.getAllRoutes();
      print('📈 Итоговая статистика базы данных:');
      print('   • Всего маршрутов в базе: ${finalRoutes.length}');
      
      // Проверяем, сколько именно RouteInitializer маршрутов теперь в базе
      int finalInitializerRoutes = 0;
      for (final route in initialRoutes) {
        final exists = finalRoutes.any((existing) =>
            existing.fromCity == route.fromCity &&
            existing.toCity == route.toCity);
        if (exists) finalInitializerRoutes++;
      }
      
      print('   • RouteInitializer маршрутов в базе: $finalInitializerRoutes/${initialRoutes.length}');
      print('   • Процент инициализации: ${(finalInitializerRoutes * 100 / initialRoutes.length).round()}%');
      
      final stats = routeStats;
      print('📈 Статистика RouteInitializer (ТОЛЬКО пользовательский список):');
      print('   • Всего маршрутов: ${stats['total_routes']}');
      print('   • Уникальных городов: ${stats['unique_cities']}');
      print('   • Средняя цена: ${stats['avg_price']}₽');
      print('   • ⚠️  ВНИМАНИЕ: Используются ТОЛЬКО маршруты из пользовательского списка!');
      
    } catch (e) {
      print('❌ Ошибка при инициализации маршрутов: $e');
      rethrow;
    }
  }
  
  /// Проверка статуса инициализации
  static Future<Map<String, dynamic>> checkInitializationStatus() async {
    try {
      final service = RouteManagementService.instance;
      final existingRoutes = await service.getAllRoutes();
      
      // Считаем, сколько маршрутов из RouteInitializer уже есть в базе
      int existingInitializerRoutes = 0;
      for (final route in initialRoutes) {
        final exists = existingRoutes.any((existing) =>
            existing.fromCity == route.fromCity &&
            existing.toCity == route.toCity);
        if (exists) existingInitializerRoutes++;
      }
      
      final totalInitializerRoutes = initialRoutes.length;
      final missingRoutes = totalInitializerRoutes - existingInitializerRoutes;
      final initializationPercentage = totalInitializerRoutes > 0 
          ? (existingInitializerRoutes * 100 / totalInitializerRoutes).round()
          : 0;
      
      return {
        'total_routes_in_db': existingRoutes.length,
        'initializer_routes_in_db': existingInitializerRoutes,
        'initializer_routes_total': totalInitializerRoutes,
        'missing_routes': missingRoutes,
        'initialization_percentage': initializationPercentage,
        'is_fully_initialized': existingInitializerRoutes >= totalInitializerRoutes,
      };
    } catch (e) {
      print('❌ Ошибка при проверке статуса инициализации: $e');
      return {
        'total_routes_in_db': 0,
        'initializer_routes_in_db': 0,
        'initializer_routes_total': initialRoutes.length,
        'missing_routes': initialRoutes.length,
        'initialization_percentage': 0,
        'is_fully_initialized': false,
      };
    }
  }
}