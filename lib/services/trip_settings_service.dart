import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_settings.dart';

class TripSettingsService {
  static final TripSettingsService _instance = TripSettingsService._internal();
  factory TripSettingsService() => _instance;
  TripSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'trip_settings';

  // Получить текущие настройки
  Future<TripSettings> getCurrentSettings() async {
    try {
      final doc = await _firestore.collection(_collection).doc('current').get();

      if (doc.exists) {
        return TripSettings.fromFirestore(doc);
      } else {
        // Если настроек нет, создаем дефолтные
        final defaultSettings = TripSettings.getDefault();
        await _firestore
            .collection(_collection)
            .doc('current')
            .set(defaultSettings.toFirestore());
        return defaultSettings;
      }
    } catch (e) {
      print('Ошибка получения настроек: $e');
      return TripSettings.getDefault();
    }
  }

  // Сохранить настройки
  Future<void> saveSettings(TripSettings settings) async {
    try {
      await _firestore
          .collection(_collection)
          .doc('current')
          .set(settings.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Ошибка сохранения настроек: $e');
    }
  }

  // Добавить время отправления
  Future<void> addDepartureTime(String time) async {
    final settings = await getCurrentSettings();
    final updatedTimes = List<String>.from(settings.departureTimes);

    if (!updatedTimes.contains(time)) {
      updatedTimes.add(time);
      updatedTimes.sort(); // Сортируем по времени

      await saveSettings(settings.copyWith(departureTimes: updatedTimes));
    }
  }

  // Удалить время отправления
  Future<void> removeDepartureTime(String time) async {
    final settings = await getCurrentSettings();
    final updatedTimes = List<String>.from(settings.departureTimes);

    updatedTimes.remove(time);
    await saveSettings(settings.copyWith(departureTimes: updatedTimes));
  }

  // Добавить место посадки
  Future<void> addPickupPoint(String point, bool isDonetsk) async {
    final settings = await getCurrentSettings();

    if (isDonetsk) {
      final updatedPoints = List<String>.from(settings.donetskPickupPoints);
      if (!updatedPoints.contains(point)) {
        updatedPoints.add(point);
        await saveSettings(
          settings.copyWith(donetskPickupPoints: updatedPoints),
        );
      }
    } else {
      final updatedPoints = List<String>.from(settings.rostovPickupPoints);
      if (!updatedPoints.contains(point)) {
        updatedPoints.add(point);
        await saveSettings(
          settings.copyWith(rostovPickupPoints: updatedPoints),
        );
      }
    }
  }

  // Удалить место посадки
  Future<void> removePickupPoint(String point, bool isDonetsk) async {
    final settings = await getCurrentSettings();

    if (isDonetsk) {
      final updatedPoints = List<String>.from(settings.donetskPickupPoints);
      updatedPoints.remove(point);
      await saveSettings(settings.copyWith(donetskPickupPoints: updatedPoints));
    } else {
      final updatedPoints = List<String>.from(settings.rostovPickupPoints);
      updatedPoints.remove(point);
      await saveSettings(settings.copyWith(rostovPickupPoints: updatedPoints));
    }
  }

  // Добавить место высадки
  Future<void> addDropoffPoint(String point, bool isDonetsk) async {
    final settings = await getCurrentSettings();

    if (isDonetsk) {
      final updatedPoints = List<String>.from(settings.donetskDropoffPoints);
      if (!updatedPoints.contains(point)) {
        updatedPoints.add(point);
        await saveSettings(
          settings.copyWith(donetskDropoffPoints: updatedPoints),
        );
      }
    } else {
      final updatedPoints = List<String>.from(settings.rostovDropoffPoints);
      if (!updatedPoints.contains(point)) {
        updatedPoints.add(point);
        await saveSettings(
          settings.copyWith(rostovDropoffPoints: updatedPoints),
        );
      }
    }
  }

  // Удалить место высадки
  Future<void> removeDropoffPoint(String point, bool isDonetsk) async {
    final settings = await getCurrentSettings();

    if (isDonetsk) {
      final updatedPoints = List<String>.from(settings.donetskDropoffPoints);
      updatedPoints.remove(point);
      await saveSettings(
        settings.copyWith(donetskDropoffPoints: updatedPoints),
      );
    } else {
      final updatedPoints = List<String>.from(settings.rostovDropoffPoints);
      updatedPoints.remove(point);
      await saveSettings(settings.copyWith(rostovDropoffPoints: updatedPoints));
    }
  }

  // Обновить максимальное количество пассажиров
  Future<void> updateMaxPassengers(int maxPassengers) async {
    final settings = await getCurrentSettings();
    await saveSettings(settings.copyWith(maxPassengers: maxPassengers));
  }

  // Обновить цены
  Future<void> updatePricing(Map<String, int> pricing) async {
    final settings = await getCurrentSettings();
    await saveSettings(settings.copyWith(pricing: pricing));
  }

  // Слушать изменения настроек в реальном времени
  Stream<TripSettings> watchSettings() {
    return _firestore.collection(_collection).doc('current').snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return TripSettings.fromFirestore(doc);
      } else {
        return TripSettings.getDefault();
      }
    });
  }
}
