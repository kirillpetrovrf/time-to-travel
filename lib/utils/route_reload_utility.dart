import 'package:flutter/cupertino.dart';
import '../data/route_initializer.dart';

/// 🔄 Утилита для перезагрузки маршрутов в приложении
/// 
/// Использование в коде:
/// await RouteReloadUtility.reloadAllRoutes();
/// 
class RouteReloadUtility {
  
  /// 🔄 ПОЛНАЯ ПЕРЕЗАГРУЗКА ВСЕХ МАРШРУТОВ
  static Future<Map<String, dynamic>> reloadAllRoutes({
    bool showDetails = true,
  }) async {
    if (showDetails) {
      debugPrint('🔄 ЗАПУСК ПЕРЕЗАГРУЗКИ МАРШРУТОВ');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
    
    try {
      // Статистика до перезагрузки
      final statsBefore = RouteInitializer.routeStats;
      if (showDetails) {
        debugPrint('📊 Статистика RouteInitializer:');
        debugPrint('   • Всего маршрутов: ${statsBefore['total_routes']}');
        debugPrint('   • Уникальных городов: ${statsBefore['unique_cities']}');
        debugPrint('   • Средняя цена: ${statsBefore['avg_price']}₽');
        debugPrint('');
        debugPrint('🗑️ ПОЛНАЯ ОЧИСТКА И ПЕРЕЗАГРУЗКА...');
      }
      
      final startTime = DateTime.now();
      
      // Вызываем принудительную перезагрузку
      await RouteInitializer.forceInitializeOnlyUserRoutes();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      // Статистика после перезагрузки
      final statusAfter = await RouteInitializer.checkInitializationStatus();
      
      if (showDetails) {
        debugPrint('');
        debugPrint('✅ ПЕРЕЗАГРУЗКА ЗАВЕРШЕНА УСПЕШНО!');
        debugPrint('⏱️ Время выполнения: ${duration.inMilliseconds}мс');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('');
        debugPrint('📈 ФИНАЛЬНАЯ СТАТИСТИКА:');
        debugPrint('   • Всего маршрутов в БД: ${statusAfter['total_routes_in_db']}');
        debugPrint('   • RouteInitializer маршрутов: ${statusAfter['initializer_routes_in_db']}/${statusAfter['initializer_routes_total']}');
        debugPrint('   • Процент инициализации: ${statusAfter['initialization_percentage']}%');
        debugPrint('');
        debugPrint('🎯 НОВЫЕ МАРШРУТЫ С КРАСНОДАРОМ ДОСТУПНЫ:');
        debugPrint('   • Донецк ⇄ Краснодар (30000₽)');
        debugPrint('   • Макеевка ⇄ Краснодар (30000₽)');
        debugPrint('   • Харцызск ⇄ Краснодар (30000₽)');
        debugPrint('   • Иловайск ⇄ Краснодар (30000₽)');
        debugPrint('   • Амвросиевка ⇄ Краснодар (30000₽)');
        debugPrint('   • КПП Авило-Успенка ⇄ Краснодар (30000₽)');
      }
      
      return {
        'success': true,
        'duration_ms': duration.inMilliseconds,
        'routes_before': statsBefore['total_routes'],
        'routes_after': statusAfter['total_routes_in_db'],
        'initialization_percentage': statusAfter['initialization_percentage'],
        'message': 'Маршруты успешно перезагружены',
      };
      
    } catch (e, stackTrace) {
      debugPrint('❌ ОШИБКА ПРИ ПЕРЕЗАГРУЗКЕ МАРШРУТОВ:');
      debugPrint('   $e');
      debugPrint('');
      debugPrint('📋 Stack trace:');
      debugPrint('   $stackTrace');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Ошибка при перезагрузке маршрутов',
      };
    }
  }
  
  /// 📊 БЫСТРАЯ ПРОВЕРКА СТАТУСА БЕЗ ПЕРЕЗАГРУЗКИ
  static Future<Map<String, dynamic>> checkRoutesStatus() async {
    try {
      final status = await RouteInitializer.checkInitializationStatus();
      final stats = RouteInitializer.routeStats;
      
      debugPrint('📊 СТАТУС МАРШРУТОВ:');
      debugPrint('   • Всего в БД: ${status['total_routes_in_db']}');
      debugPrint('   • RouteInitializer: ${status['initializer_routes_in_db']}/${status['initializer_routes_total']}');
      debugPrint('   • Инициализация: ${status['initialization_percentage']}%');
      debugPrint('   • Средняя цена: ${stats['avg_price']}₽');
      
      return {
        'success': true,
        'total_routes': status['total_routes_in_db'],
        'initializer_routes': status['initializer_routes_in_db'],
        'initialization_percentage': status['initialization_percentage'],
        'is_fully_initialized': status['is_fully_initialized'],
        'avg_price': stats['avg_price'],
      };
      
    } catch (e) {
      debugPrint('❌ Ошибка проверки статуса: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 🎯 ПРОВЕРКА НАЛИЧИЯ КРАСНОДАРСКИХ МАРШРУТОВ
  static Future<List<String>> checkKrasnodarRoutes() async {
    try {
      final foundRoutes = <String>[];
      final expectedRoutes = [
        'Донецк → Краснодар',
        'Макеевка → Краснодар', 
        'Харцызск → Краснодар',
        'Иловайск → Краснодар',
        'Амвросиевка → Краснодар',
        'Пункт пропуска Авило-Успенка → Краснодар',
        'Краснодар → Донецк',
        'Краснодар → Макеевка',
        'Краснодар → Харцызск',
        'Краснодар → Иловайск',
        'Краснодар → Амвросиевка',
        'Краснодар → Пункт пропуска Авило-Успенка',
      ];
      
      // Получаем все маршруты из RouteInitializer
      final routes = RouteInitializer.initialRoutes;
      
      for (final expectedRoute in expectedRoutes) {
        final parts = expectedRoute.split(' → ');
        final from = parts[0];
        final to = parts[1];
        
        final routeExists = routes.any((route) =>
            route.fromCity == from && route.toCity == to);
        
        if (routeExists) {
          foundRoutes.add(expectedRoute);
        }
      }
      
      debugPrint('🎯 НАЙДЕННЫЕ КРАСНОДАРСКИЕ МАРШРУТЫ:');
      for (final route in foundRoutes) {
        debugPrint('   ✅ $route');
      }
      
      final missing = expectedRoutes.length - foundRoutes.length;
      if (missing > 0) {
        debugPrint('   ❌ Отсутствуют: $missing маршрутов');
      }
      
      return foundRoutes;
      
    } catch (e) {
      debugPrint('❌ Ошибка проверки краснодарских маршрутов: $e');
      return [];
    }
  }
}