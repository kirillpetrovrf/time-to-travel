import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/taxi_order.dart';

/// Сервис для работы с заказами в Firebase Firestore (онлайн режим для продакшена)
class FirebaseOrdersService {
  static final FirebaseOrdersService instance = FirebaseOrdersService._();
  FirebaseOrdersService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'orders';

  /// Сохранение заказа в Firestore
  Future<void> saveOrder(TaxiOrder order) async {
    print('☁️ [FIREBASE] Сохранение заказа: ${order.orderId}');
    
    try {
      await _firestore
          .collection(_collectionName)
          .doc(order.orderId)
          .set(order.toMap());
      
      print('✅ [FIREBASE] Заказ сохранен: ${order.orderId}');
    } catch (e) {
      print('❌ [FIREBASE] Ошибка сохранения заказа: $e');
      rethrow;
    }
  }

  /// Получение потока всех заказов (реал-тайм обновления)
  Stream<List<TaxiOrder>> getOrdersStream() {
    print('📡 [FIREBASE] Подписка на поток заказов...');
    
    return _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => TaxiOrder.fromMap(doc.data()))
          .toList();
      
      print('📡 [FIREBASE] Получено ${orders.length} заказов');
      return orders;
    });
  }

  /// Получение заказа по ID
  Future<TaxiOrder?> getOrderById(String orderId) async {
    print('🔍 [FIREBASE] Поиск заказа: $orderId');
    
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(orderId)
          .get();
      
      if (!doc.exists) {
        print('⚠️ [FIREBASE] Заказ не найден: $orderId');
        return null;
      }
      
      final order = TaxiOrder.fromMap(doc.data()!);
      print('✅ [FIREBASE] Заказ найден: $orderId');
      return order;
    } catch (e) {
      print('❌ [FIREBASE] Ошибка поиска заказа: $e');
      return null;
    }
  }

  /// Обновление статуса заказа
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    print('🔄 [FIREBASE] Обновление статуса заказа $orderId → $newStatus');
    
    try {
      await _firestore
          .collection(_collectionName)
          .doc(orderId)
          .update({'status': newStatus});
      
      print('✅ [FIREBASE] Статус обновлен: $orderId → $newStatus');
    } catch (e) {
      print('❌ [FIREBASE] Ошибка обновления статуса: $e');
      rethrow;
    }
  }

  /// Удаление заказа
  Future<void> deleteOrder(String orderId) async {
    print('🗑️ [FIREBASE] Удаление заказа: $orderId');
    
    try {
      await _firestore
          .collection(_collectionName)
          .doc(orderId)
          .delete();
      
      print('✅ [FIREBASE] Заказ удален: $orderId');
    } catch (e) {
      print('❌ [FIREBASE] Ошибка удаления заказа: $e');
      rethrow;
    }
  }

  /// Получение списка заказов (одноразовый запрос, не реал-тайм)
  Future<List<TaxiOrder>> getAllOrders() async {
    print('📄 [FIREBASE] Загрузка всех заказов...');
    
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .get();
      
      final orders = snapshot.docs
          .map((doc) => TaxiOrder.fromMap(doc.data()))
          .toList();
      
      print('✅ [FIREBASE] Загружено ${orders.length} заказов');
      return orders;
    } catch (e) {
      print('❌ [FIREBASE] Ошибка загрузки заказов: $e');
      return [];
    }
  }

  /// Получение заказов по статусу
  Future<List<TaxiOrder>> getOrdersByStatus(String status) async {
    print('🔍 [FIREBASE] Загрузка заказов со статусом: $status');
    
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .get();
      
      final orders = snapshot.docs
          .map((doc) => TaxiOrder.fromMap(doc.data()))
          .toList();
      
      print('✅ [FIREBASE] Найдено ${orders.length} заказов со статусом "$status"');
      return orders;
    } catch (e) {
      print('❌ [FIREBASE] Ошибка поиска заказов: $e');
      return [];
    }
  }

  /// Получение количества заказов
  Future<int> getOrdersCount() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final count = snapshot.docs.length;
      
      print('📊 [FIREBASE] Всего заказов: $count');
      return count;
    } catch (e) {
      print('❌ [FIREBASE] Ошибка подсчета заказов: $e');
      return 0;
    }
  }
}
