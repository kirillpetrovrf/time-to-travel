import 'package:flutter/foundation.dart';
import '../models/trip_settings.dart';

/// ⚠️ ВАЖНО: Сейчас используются только локальные данные
/// TODO: Интеграция с Firebase - реализуется позже
class TripSettingsService {
  static final TripSettingsService _instance = TripSettingsService._internal();
  factory TripSettingsService() => _instance;
  TripSettingsService._internal();

  // TODO: Интеграция с Firebase - реализуется позже
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String _collection = 'trip_settings';

  // Локальное хранилище настроек
  TripSettings? _cachedSettings;

  // Получить текущие настройки
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<TripSettings> getCurrentSettings() async {
    debugPrint(
      'ℹ️ Используются локальные настройки поездок (Firebase не подключен)',
    );
    _cachedSettings ??= TripSettings.getDefault();
    return _cachedSettings!;
  }

  // Сохранить настройки
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> saveSettings(TripSettings settings) async {
    debugPrint('ℹ️ Настройки сохранены локально (Firebase не подключен)');
    _cachedSettings = settings.copyWith(updatedAt: DateTime.now());
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
  /// TODO: Интеграция с Firebase - реализуется позже
  Stream<TripSettings> watchSettings() {
    debugPrint(
      'ℹ️ Используется локальный стрим настроек (Firebase не подключен)',
    );
    return Stream.value(_cachedSettings ?? TripSettings.getDefault());
  }
}
