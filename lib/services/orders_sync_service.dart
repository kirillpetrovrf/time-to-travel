import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'offline_orders_service.dart';
import 'api/orders_api_service.dart';

/// Сервис автоматической синхронизации заказов
/// ✅ АКТИВЕН: Отправляет старые offline заказы на backend API
class OrdersSyncService {
  static final OrdersSyncService instance = OrdersSyncService._();
  OrdersSyncService._();

  final _offlineService = OfflineOrdersService.instance;
  final _ordersApi = OrdersApiService();
  final _connectivity = Connectivity();
  
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _isSyncing = false;
  
  /// Запустить мониторинг интернета и автосинхронизацию
  void startAutoSync() {
    debugPrint('🔄 [SYNC] Запуск автосинхронизации старых offline заказов...');
    
    // Проверяем синхронизацию при старте (отправляем старые offline заказы)
    _syncOrders();
    
    // Подписываемся на изменения интернета
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      debugPrint('📶 [SYNC] Статус подключения изменился: $result');
      if (result == ConnectivityResult.wifi || result == ConnectivityResult.mobile) {
        debugPrint('✅ [SYNC] Интернет появился - синхронизируем offline заказы');
        _syncOrders();
      }
    });
    
    debugPrint('✅ [SYNC] Автосинхронизация запущена');
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
  
  /// Внутренний метод синхронизации старых offline заказов
  /// ✅ АКТИВНО: Загружает несинхронизированные заказы из SQLite и отправляет на backend
  Future<void> _syncOrders() async {
    // Защита от одновременных вызовов
    if (_isSyncing) {
      debugPrint('⏳ [SYNC] Синхронизация уже выполняется, пропускаем...');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // 1. Проверяем интернет
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        debugPrint('❌ [SYNC] Нет интернета, синхронизация отменена');
        return;
      }
      
      // 2. Получаем несинхронизированные заказы из SQLite
      final unsyncedOrders = await _offlineService.getUnsyncedOrders();
      if (unsyncedOrders.isEmpty) {
        debugPrint('✅ [SYNC] Нет несинхронизированных заказов');
        return;
      }
      
      debugPrint('📤 [SYNC] Найдено ${unsyncedOrders.length} offline заказов для синхронизации');
      
      // 3. Отправляем каждый заказ на backend
      int successCount = 0;
      int failCount = 0;
      
      for (final order in unsyncedOrders) {
        try {
          debugPrint('📤 [SYNC] Отправка заказа ${order.orderId} на backend...');
          
          // Парсим дату и время
          DateTime departureDateTime;
          try {
            if (order.departureDate != null && order.departureTime != null) {
              final date = order.departureDate!; // Уже DateTime
              final timeComponents = order.departureTime!.split(':');
              final hour = int.parse(timeComponents[0]);
              final minute = int.parse(timeComponents[1]);
              
              departureDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                hour,
                minute,
              );
            } else {
              departureDateTime = order.timestamp; // Уже DateTime
            }
          } catch (e) {
            debugPrint('⚠️ [SYNC] Ошибка парсинга даты/времени: $e');
            departureDateTime = order.timestamp; // Уже DateTime
          }
          
          // Подготавливаем метаданные
          final metadata = <String, dynamic>{
            'originalOrderId': order.orderId,
          };
          
          if (order.baggageJson != null) {
            metadata['baggageJson'] = order.baggageJson;
          }
          if (order.passengersJson != null) {
            metadata['passengersJson'] = order.passengersJson;
          }
          if (order.petsJson != null) {
            metadata['petsJson'] = order.petsJson;
          }
          if (order.vehicleClass != null) {
            metadata['vehicleClass'] = order.vehicleClass;
          }
          
          // Отправляем на backend
          final createdOrder = await _ordersApi.createOrder(
            fromAddress: order.fromAddress,
            toAddress: order.toAddress,
            departureTime: departureDateTime,
            passengerCount: 1, // TODO: извлечь из passengersJson
            basePrice: order.rawPrice,
            totalPrice: order.finalPrice,
            notes: order.notes,
            phone: order.clientPhone,
            metadata: metadata,
          );
          
          debugPrint('✅ [SYNC] Заказ ${order.orderId} отправлен, новый ID: ${createdOrder.id}');
          
          // Помечаем как синхронизированный
          await _offlineService.markAsSynced(order.orderId);
          successCount++;
          
        } catch (e) {
          debugPrint('❌ [SYNC] Ошибка отправки заказа ${order.orderId}: $e');
          failCount++;
        }
      }
      
      debugPrint('✅ [SYNC] Синхронизация завершена: успешно $successCount, ошибок $failCount');
      
    } catch (e) {
      debugPrint('❌ [SYNC] Критическая ошибка синхронизации: $e');
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
