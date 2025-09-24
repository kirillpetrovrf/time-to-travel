import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/trip_type.dart';

class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicles';

  /// Создание нового транспортного средства
  Future<String> createVehicle(Vehicle vehicle) async {
    final docRef = await _firestore
        .collection(_collection)
        .add(vehicle.toJson());
    return docRef.id;
  }

  /// Получение всех транспортных средств
  Future<List<Vehicle>> getAllVehicles() async {
    final query = await _firestore
        .collection(_collection)
        .orderBy('brand')
        .orderBy('model')
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Vehicle.fromJson(data);
    }).toList();
  }

  /// Получение транспортных средств по классу
  Future<List<Vehicle>> getVehiclesByClass(VehicleClass vehicleClass) async {
    final query = await _firestore
        .collection(_collection)
        .where('vehicleClass', isEqualTo: vehicleClass.toString())
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Vehicle.fromJson(data);
    }).toList();
  }

  /// Получение транспортного средства по ID
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    final doc = await _firestore.collection(_collection).doc(vehicleId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Vehicle.fromJson(data);
    }
    return null;
  }

  /// Обновление данных транспортного средства
  Future<void> updateVehicle(Vehicle vehicle) async {
    final data = vehicle.toJson();
    data.remove('id');
    await _firestore.collection(_collection).doc(vehicle.id).update(data);
  }

  /// Удаление транспортного средства
  Future<void> deleteVehicle(String vehicleId) async {
    await _firestore.collection(_collection).doc(vehicleId).delete();
  }

  /// Получение доступных транспортных средств
  /// (не назначенных на активные поездки)
  Future<List<Vehicle>> getAvailableVehicles() async {
    // Получаем все активные бронирования с назначенными машинами
    final activeBookings = await _firestore
        .collection('bookings')
        .where(
          'status',
          whereIn: ['BookingStatus.assigned', 'BookingStatus.inProgress'],
        )
        .where('assignedVehicleId', isNotEqualTo: null)
        .get();

    final assignedVehicleIds = activeBookings.docs
        .map((doc) => doc.data()['assignedVehicleId'] as String?)
        .where((id) => id != null)
        .toSet();

    // Получаем все машины
    final allVehicles = await getAllVehicles();

    // Фильтруем доступные машины
    return allVehicles
        .where((vehicle) => !assignedVehicleIds.contains(vehicle.id))
        .toList();
  }
}
