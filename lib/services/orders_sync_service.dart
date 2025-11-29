import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_orders_service.dart';
import 'firebase_orders_service.dart';

/// Сервис автоматической синхронизации заказов: SQLite → Firebase
/// Отслеживает появление интернета и автоматически загружает несинхронизированные заказы
class OrdersSyncService {
  static final OrdersSyncService instance = OrdersSyncService._();
  OrdersSyncService._();

  final _offlineService = OfflineOrdersService.instance;
  final _firebaseService = FirebaseOrdersService.instance;
  final _connectivity = Connectivity();
  
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _isSyncing = false;
  
  /// Запустить мониторинг интернета и автосинхронизацию
  void startAutoSync() {
    print('🔄 [SYNC] Запуск автосинхронизации заказов...');
    
    // Проверяем синхронизацию при старте
    _syncOrders();
    
    // Подписываемся на изменения интернета
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      print('📶 [SYNC] Статус подключения изменился: $result');

      // result can be either ConnectivityResult or List<ConnectivityResult> depending on
      // connectivity_plus version; handle both cases robustly.
      bool hasConnection = false;

      if (result is ConnectivityResult) {
        hasConnection = result == ConnectivityResult.wifi || result == ConnectivityResult.mobile;
      } else if (result is List) {
        // list may contain ConnectivityResult values
        hasConnection = result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);
      }

      if (hasConnection) {
        print('✅ [SYNC] Интернет доступен, запускаем синхронизацию...');
        _syncOrders();
      } else {
        print('⚠️ [SYNC] Нет интернета, синхронизация отложена');
      }
    });
    
    print('✅ [SYNC] Автосинхронизация запущена');
  }
  
  /// Остановить автосинхронизацию
  void stopAutoSync() {
    print('🛑 [SYNC] Остановка автосинхронизации...');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
  
  /// Принудительная синхронизация всех несинхронизированных заказов
  Future<void> syncNow() async {
    print('🔄 [SYNC] Принудительная синхронизация...');
    await _syncOrders();
  }
  
  /// Внутренний метод синхронизации
  Future<void> _syncOrders() async {
    // Защита от одновременных вызовов
    if (_isSyncing) {
      print('⏳ [SYNC] Синхронизация уже выполняется, пропускаем...');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // Загружаем несинхронизированные заказы из SQLite
      final unsyncedOrders = await _offlineService.getUnsyncedOrders();
      
      if (unsyncedOrders.isEmpty) {
        print('✅ [SYNC] Нет заказов для синхронизации');
        return;
      }
      
      print('🔄 [SYNC] Найдено ${unsyncedOrders.length} заказов для синхронизации');
      
      int successCount = 0;
      int failCount = 0;
      
      // Отправляем каждый заказ в Firebase
      for (final order in unsyncedOrders) {
        try {
          print('📤 [SYNC] Отправка заказа ${order.orderId} в Firebase...');
          
          // Отправляем в Firebase
          await _firebaseService.saveOrder(order);
          
          // Помечаем как синхронизированный в SQLite
          await _offlineService.markAsSynced(order.orderId);
          
          successCount++;
          print('✅ [SYNC] Заказ ${order.orderId} синхронизирован');
        } catch (e) {
          failCount++;
          print('❌ [SYNC] Ошибка синхронизации заказа ${order.orderId}: $e');
          // Продолжаем попытки с другими заказами
        }
      }
      
      print('🎉 [SYNC] Синхронизация завершена: успешно=$successCount, ошибок=$failCount');
      
      if (successCount > 0) {
        print('✅ [SYNC] Успешно синхронизировано заказов: $successCount');
      }
      
      if (failCount > 0) {
        print('⚠️ [SYNC] Не удалось синхронизировать заказов: $failCount');
      }
      
    } catch (e) {
      print('❌ [SYNC] Критическая ошибка синхронизации: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Проверить, есть ли несинхронизированные заказы
  Future<bool> hasUnsyncedOrders() async {
    final count = await _offlineService.getUnsyncedCount();
    return count > 0;
  }
  
  /// Получить количество несинхронизированных заказов
  Future<int> getUnsyncedCount() async {
    return await _offlineService.getUnsyncedCount();
  }
  
  /// Проверить статус интернета
  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    final hasConnection = result == ConnectivityResult.wifi || result == ConnectivityResult.mobile;

    print('📶 [SYNC] Статус интернета: ${hasConnection ? "✅ есть" : "❌ нет"}');
    return hasConnection;
  }
}
