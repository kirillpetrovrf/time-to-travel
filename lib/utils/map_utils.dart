import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

// Утилитарные функции для работы с картой

class MapUtils {
  // Проверка валидности координат
  static bool isValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  // Форматирование координат для отображения
  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  // Вычисление расстояния между двумя точками (формула гаверсинуса)
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // км
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * 
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Перевод градусов в радианы
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Цвета для разных типов точек
  static Color getPointColor(String pointType) {
    switch (pointType) {
      case 'from':
        return CupertinoColors.activeGreen;
      case 'to':
        return CupertinoColors.destructiveRed;
      case 'waypoint':
        return CupertinoColors.systemBlue;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  // Получить описание типа точки
  static String getPointTypeDescription(String pointType) {
    switch (pointType) {
      case 'from':
        return 'Откуда';
      case 'to':
        return 'Куда';
      case 'waypoint':
        return 'Промежуточная точка';
      default:
        return 'Неизвестная точка';
    }
  }

  // Форматирование времени поездки
  static String formatTravelTime(int minutes) {
    if (minutes < 60) {
      return '$minutes мин';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ч';
      } else {
        return '$hours ч $remainingMinutes мин';
      }
    }
  }

  // Форматирование расстояния
  static String formatDistance(double kilometers) {
    if (kilometers < 1) {
      return '${(kilometers * 1000).round()} м';
    } else if (kilometers < 10) {
      return '${kilometers.toStringAsFixed(1)} км';
    } else {
      return '${kilometers.round()} км';
    }
  }

  // Получить центр между двумя точками
  static Map<String, double> getCenterBetweenPoints(
    double lat1, double lng1, 
    double lat2, double lng2
  ) {
    double centerLat = (lat1 + lat2) / 2;
    double centerLng = (lng1 + lng2) / 2;
    
    return {
      'latitude': centerLat,
      'longitude': centerLng,
    };
  }

  // Вычислить подходящий зум для отображения маршрута
  static double calculateZoomForRoute(
    double lat1, double lng1, 
    double lat2, double lng2
  ) {
    double distance = calculateDistance(lat1, lng1, lat2, lng2);
    
    if (distance < 1) return 15.0;
    if (distance < 5) return 13.0;
    if (distance < 10) return 12.0;
    if (distance < 50) return 10.0;
    if (distance < 100) return 9.0;
    if (distance < 500) return 7.0;
    return 6.0;
  }

  // Проверка, находится ли точка в пределах России
  static bool isWithinRussia(double lat, double lng) {
    // Примерные границы России
    return lat >= 41.0 && lat <= 82.0 && 
           lng >= 19.0 && lng <= 169.0;
  }

  // Проверка, находится ли точка в Ростовской области
  static bool isWithinRostovRegion(double lat, double lng) {
    // Примерные границы Ростовской области
    return lat >= 45.5 && lat <= 49.9 && 
           lng >= 38.2 && lng <= 44.0;
  }

  // Получить название региона по координатам (упрощенная версия)
  static String getRegionName(double lat, double lng) {
    if (isWithinRostovRegion(lat, lng)) {
      return 'Ростовская область';
    } else if (isWithinRussia(lat, lng)) {
      return 'Россия';
    } else {
      return 'За пределами России';
    }
  }

  // Валидация адреса (базовая проверка)
  static bool isValidAddress(String address) {
    return address.trim().isNotEmpty && address.length >= 3;
  }

  // Очистка адреса от лишних символов
  static String cleanAddress(String address) {
    return address.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Извлечь город из полного адреса
  static String? extractCityFromAddress(String fullAddress) {
    // Простой парсинг - ищем город после запятой
    List<String> parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return parts[1].trim();
    }
    return null;
  }

  // Сокращенный адрес для отображения
  static String getShortAddress(String fullAddress, {int maxLength = 30}) {
    if (fullAddress.length <= maxLength) {
      return fullAddress;
    }
    return '${fullAddress.substring(0, maxLength - 3)}...';
  }

  // Конвертация адреса в coordinates placeholder
  static Map<String, double> addressToCoordinatesPlaceholder(String address) {
    // Заглушка - в реальном приложении это должно быть через геокодинг API
    // Возвращаем координаты центра Ростова-на-Дону
    return {
      'latitude': 47.2357,
      'longitude': 39.7015,
    };
  }
}