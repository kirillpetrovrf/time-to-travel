import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/trip_type.dart';

/// ⚠️ ВАЖНО: Сейчас используются только локальные данные
/// TODO: Интеграция с Firebase - реализуется позже
class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  // TODO: Интеграция с Firebase - реализуется позже
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String _collection = 'vehicles';

  /// Создание нового транспортного средства
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<String> createVehicle(Vehicle vehicle) async {
    debugPrint('ℹ️ Создание транспорта локально (Firebase не подключен)');
    return 'local_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Получение всех транспортных средств
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<Vehicle>> getAllVehicles() async {
    debugPrint('ℹ️ Получение транспорта локально (Firebase не подключен)');
    return [];
  }

  /// Получение транспортных средств по классу
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<Vehicle>> getVehiclesByClass(VehicleClass vehicleClass) async {
    debugPrint(
      'ℹ️ Получение транспорта по классу локально (Firebase не подключен)',
    );
    return [];
  }

  /// Получение транспортного средства по ID
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    debugPrint(
      'ℹ️ Получение транспорта по ID локально (Firebase не подключен)',
    );
    return null;
  }

  /// Обновление данных транспортного средства
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateVehicle(Vehicle vehicle) async {
    debugPrint('ℹ️ Обновление транспорта локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Удаление транспортного средства
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> deleteVehicle(String vehicleId) async {
    debugPrint('ℹ️ Удаление транспорта локально (Firebase не подключен)');
    // В будущем здесь будет удаление из Firebase
  }

  /// Получение доступных транспортных средств
  /// (не назначенных на активные поездки)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<Vehicle>> getAvailableVehicles() async {
    debugPrint(
      'ℹ️ Получение доступного транспорта локально (Firebase не подключен)',
    );
    return [];
  }
}
