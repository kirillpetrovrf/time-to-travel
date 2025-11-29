import 'dart:math';

enum TripType {
  group, // Групповая поездка
  individual, // Индивидуальный трансфер
  customRoute, // Свободный маршрут (такси)
}

enum Direction {
  donetskToRostov, // Донецк → Ростов-на-Дону
  rostovToDonetsk, // Ростов-на-Дону → Донецк
}

enum VehicleClass {
  sedan, // Седан (1-3 пассажира)
  wagon, // Универсал (1-4 пассажира, больше багажа)
  minivan, // Минивэн (1-6 пассажиров)
  microbus, // Микроавтобус (1-8 пассажиров)
}

class TripPricing {
  static const int groupTripPrice = 2000; // ₽ за место
  static const int individualTripPrice = 8000; // ₽ за машину
  static const int individualTripNightPrice = 10000; // ₽ за машину после 22:00
  static const int donetskToBorderPrice = 4000; // ₽ до границы

  static const List<String> groupDepartureTimes = [
    '06:00',
    '09:00',
    '13:00',
    '16:00',
  ];

  static const List<String> donetskPickupPoints = ['Центральный автовокзал'];

  static const List<String> rostovPickupPoints = ['Главный автовокзал'];

  static const List<String> donetskDropoffPoints = ['Центральный автовокзал'];

  static const List<String> rostovDropoffPoints = ['Главный автовокзал'];

  /// Проверяет, является ли время выезда ночным (после 22:00)
  static bool isNightTime(String departureTime) {
    final time = departureTime.split(':');
    final hour = int.parse(time[0]);
    return hour >= 22;
  }

  /// Возвращает стоимость индивидуального трансфера в зависимости от времени
  static int getIndividualTripPrice(String departureTime, Direction direction) {
    if (direction == Direction.donetskToRostov) {
      return isNightTime(departureTime)
          ? individualTripNightPrice
          : individualTripPrice;
    }
    return individualTripPrice; // Для обратного направления цена не меняется
  }

  /// Проверяет, является ли маршрут специальным Донецк-Ростов по названиям городов
  static bool isDonetskRostovRoute(String? fromCity, String? toCity) {
    if (fromCity == null || toCity == null) return false;
    
    final fromLower = fromCity.toLowerCase();
    final toLower = toCity.toLowerCase();
    
    // Проверяем различные варианты написания
    final donetskVariants = ['донецк', 'donetsk'];
    
    // ⚠️ ВАЖНО: Проверяем ТОЛЬКО город "Ростов-на-Дону", а НЕ "Ростовская область"
    // Точное совпадение, чтобы исключить районы области
    final rostovExactMatches = [
      'ростов-на-дону',
      'rostov-on-don',
      'г. ростов-на-дону',
      'город ростов-на-дону',
    ];
    
    final isFromDonetsk = donetskVariants.any((variant) => fromLower.contains(variant));
    final isToRostov = rostovExactMatches.any((variant) => toLower.contains(variant));
    
    return isFromDonetsk && isToRostov;
  }

  /// Возвращает специальную цену для маршрута Донецк-Ростов независимо от расстояния
  /// Если маршрут идет дальше Ростова, добавляет стоимость за дополнительные километры
  static double getSpecialRoutePrice({
    String? fromCity, 
    String? toCity, 
    String? departureTime,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    double? totalDistanceKm, // Общее расстояние маршрута
    double pricePerKmBeyondRostov = 60.0, // Цена за км дальше Ростова
  }) {
    bool isSpecialRoute = false;
    
    // 🎯 ПРИОРИТЕТ 1: ГЕОГРАФИЧЕСКАЯ ПРОВЕРКА ПО КООРДИНАТАМ
    // Проверяем координаты ПЕРВЫМ ДЕЛОМ, чтобы исключить ложные срабатывания на "Ростовская область"
    if (toLat != null && toLng != null) {
      final isDestinationInRostovCity = isPointInRostovCity(toLat, toLng);
      final isFromDonetskText = fromCity?.toLowerCase().contains('донецк') ?? false;
      
      // Если точка НЕ в городе Ростов-на-Дону - это НЕ специальный маршрут!
      if (!isDestinationInRostovCity) {
        print('💰 [PRICE] ⚠️ Точка назначения НЕ в городе Ростов-на-Дону');
        print('💰 [PRICE] 📍 Координаты: $toLat, $toLng');
        print('💰 [PRICE] 🚫 Это НЕ специальный маршрут Донецк-Ростов');
        return -1; // Не специальный маршрут
      }
      
      // Точка В городе Ростов-на-Дону И отправление из Донецка
      if (isFromDonetskText && isDestinationInRostovCity) {
        isSpecialRoute = true;
        print('💰 [PRICE] ✅ ГЕОГРАФИЧЕСКАЯ ПРОВЕРКА: Точка назначения В ГОРОДЕ Ростов-на-Дону');
        print('💰 [PRICE] 📍 Координаты назначения: $toLat, $toLng');
      }
    }
    
    // 🎯 ПРИОРИТЕТ 2: ТЕКСТОВАЯ ПРОВЕРКА (только если координат нет)
    if (!isSpecialRoute && toLat == null && toLng == null) {
      isSpecialRoute = isDonetskRostovRoute(fromCity, toCity) || isDonetskRostovRoute(toCity, fromCity);
    }
    
    if (!isSpecialRoute) {
      return -1; // Не специальный маршрут
    }
    
    // Определяем время для расчета цены
    final timeToCheck = departureTime ?? DateTime.now().toString().substring(11, 16);
    
    // Базовая фиксированная цена в зависимости от времени
    double basePrice = isNightTime(timeToCheck) ? 10000.0 : 8000.0;
    
    // Проверяем, едет ли маршрут дальше Ростова
    if (toLat != null && toLng != null && totalDistanceKm != null) {
      // Расстояние от Донецка до Ростова примерно 190 км
      const double donetskRostovDistance = 190.0;
      
      // 🎯 ПРОВЕРКА: Точка за пределами города Ростов → едем дальше
      final isDestinationBeyondRostov = !isPointInRostovCity(toLat, toLng);
      
      // Если точка НЕ в городе Ростов И расстояние больше базового
      if (isDestinationBeyondRostov && totalDistanceKm > donetskRostovDistance) {
        double beyondRostovKm = totalDistanceKm - donetskRostovDistance;
        
        // Защита от отрицательных значений
        if (beyondRostovKm < 0) beyondRostovKm = 0;
        
        double additionalCost = beyondRostovKm * pricePerKmBeyondRostov;
        
        print('💰 [PRICE] 🚗 Маршрут дальше Ростова!');
        print('💰 [PRICE] 📏 Общее расстояние: ${totalDistanceKm.toStringAsFixed(2)} км');
        print('💰 [PRICE] 📏 Базовый маршрут (Донецк-Ростов): $donetskRostovDistance км');
        print('💰 [PRICE] 📏 Дополнительно за Ростовом: ${beyondRostovKm.toStringAsFixed(2)} км');
        print('💰 [PRICE] 💵 Доплата: ${additionalCost.toStringAsFixed(2)}₽ (${beyondRostovKm.toStringAsFixed(2)} км × $pricePerKmBeyondRostov₽/км)');
        print('💰 [PRICE] 💎 Итоговая цена: ${(basePrice + additionalCost).toStringAsFixed(2)}₽');
        
        return basePrice + additionalCost;
      }
    }
    
    // Возвращаем фиксированную цену если не едем дальше Ростова
    return basePrice;
  }

  /// Список городов по маршруту Донецк-Ростов (для определения специального маршрута)
  static const List<String> donetskRostovCities = [
    'Донецк',
    'Макеевка', 
    'Харцызск',
    'Иловайск',
    'Кутейниково',
    'Амвросиевка',
    'КПП Успенка',
    'Матвеев-Курган',
    'Покровское', 
    'Таганрог',
    'Ростов-на-Дону',
  ];

  /// Проверяет, содержит ли маршрут города из списка Донецк-Ростов
  static bool containsDonetskRostovCities(List<String> cities) {
    if (cities.length < 2) return false;
    
    // Проверяем пересечение с городами маршрута
    int matchCount = 0;
    for (final city in cities) {
      if (donetskRostovCities.any((routeCity) => 
          city.toLowerCase().contains(routeCity.toLowerCase()) ||
          routeCity.toLowerCase().contains(city.toLowerCase()))) {
        matchCount++;
      }
    }
    
    // Если больше половины городов из маршрута - считаем специальным
    return matchCount >= 2;
  }

  /// Координаты ключевых городов маршрута Донецк-Ростов
  static const Map<String, Map<String, double>> routeCoordinates = {
    'donetsk': {'lat': 48.015884, 'lng': 37.80285},
    'rostov': {'lat': 47.222109, 'lng': 39.718813},
  };
  
  /// Проверяет, находится ли точка в городе Ростов-на-Дону (не просто в области)
  /// Использует радиус ~8 км от центра города (чтобы исключить Батайск и другие пригороды)
  static bool isPointInRostovCity(double lat, double lng) {
    final rostovLat = routeCoordinates['rostov']!['lat']!;
    final rostovLng = routeCoordinates['rostov']!['lng']!;
    
    // Вычисляем расстояние от точки до центра Ростова в км
    final distance = _calculateDistance(lat, lng, rostovLat, rostovLng);
    
    // Радиус города Ростов-на-Дону примерно 8 км от центра
    // (чтобы исключить Батайск ~11км южнее, Чалтырь ~15км западнее)
    return distance <= 8.0;
  }
  
  /// Проверяет, находится ли точка рядом с Донецком
  /// Использует радиус ~20 км от центра города
  static bool isPointNearDonetsk(double lat, double lng) {
    final donetskLat = routeCoordinates['donetsk']!['lat']!;
    final donetskLng = routeCoordinates['donetsk']!['lng']!;
    
    // Вычисляем расстояние от точки до центра Донецка в км
    final distance = _calculateDistance(lat, lng, donetskLat, donetskLng);
    
    // Радиус города Донецк примерно 20 км от центра
    return distance <= 20.0;
  }
  
  /// Возвращает базовую цену для маршрута Донецк-Ростов в зависимости от времени
  static double getDonetskRostovBasePrice(String? departureTime) {
    final timeToCheck = departureTime ?? DateTime.now().toString().substring(11, 16);
    return isNightTime(timeToCheck) ? 10000.0 : 8000.0;
  }
  
  /// Проверяет, проходит ли маршрут ЧЕРЕЗ Ростов-на-Дону
  /// (маршрут из Донецка, который идет дальше Ростова в направлении от Донецка)
  static bool isRouteThroughRostov({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final donetskLat = routeCoordinates['donetsk']!['lat']!;
    final donetskLng = routeCoordinates['donetsk']!['lng']!;
    final rostovLat = routeCoordinates['rostov']!['lat']!;
    final rostovLng = routeCoordinates['rostov']!['lng']!;
    
    // 1. Проверяем, что конечная точка НЕ в городе Ростов-на-Дону
    final isDestinationInRostov = isPointInRostovCity(toLat, toLng);
    if (isDestinationInRostov) {
      return false; // Если конечная точка В Ростове - это не "через Ростов"
    }
    
    // 2. Вычисляем расстояния
    final distanceToDonetsk = _calculateDistance(toLat, toLng, donetskLat, donetskLng);
    
    // 3. Проверяем, что конечная точка ДАЛЬШЕ от Донецка, чем Ростов
    // (т.е. мы едем В СТОРОНУ от Донецка, а не обратно)
    final donetskToRostovDistance = _calculateDistance(donetskLat, donetskLng, rostovLat, rostovLng);
    
    // Конечная точка должна быть дальше от Донецка чем сам Ростов
    if (distanceToDonetsk <= donetskToRostovDistance) {
      return false; // Точка НЕ дальше Ростова от Донецка
    }
    
    // 4. Проверяем, что маршрут идет через географический коридор Донецк-Ростов
    // (чтобы исключить маршруты в других направлениях)
    if (!isRouteInDonetskRostovCorridor(
      fromLat: fromLat, fromLng: fromLng, 
      toLat: toLat, toLng: toLng
    )) {
      return false;
    }
    
    // ✅ Маршрут проходит ЧЕРЕЗ Ростов и идет дальше
    return true;
  }
  
  /// Вычисляет расстояние между двумя географическими точками в км (формула гаверсинусов)
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Радиус Земли в км
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  /// Переводит градусы в радианы
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Проверяет, находится ли точка в географическом коридоре Донецк-Ростов
  /// Использует расширенную зону вокруг прямой линии между городами
  static bool isPointInDonetskRostovCorridor(double lat, double lng) {
    final donetskLat = routeCoordinates['donetsk']!['lat']!;
    final donetskLng = routeCoordinates['donetsk']!['lng']!;
    final rostovLat = routeCoordinates['rostov']!['lat']!;
    final rostovLng = routeCoordinates['rostov']!['lng']!;
    
    // Проверяем, что точка находится в прямоугольной области между городами (с буфером)
    final minLat = (donetskLat < rostovLat ? donetskLat : rostovLat) - 0.5; // ~55 км буфер
    final maxLat = (donetskLat > rostovLat ? donetskLat : rostovLat) + 0.5;
    final minLng = (donetskLng < rostovLng ? donetskLng : rostovLng) - 0.5;
    final maxLng = (donetskLng > rostovLng ? donetskLng : rostovLng) + 0.5;
    
    if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) {
      return false;
    }
    
    // Вычисляем расстояние от точки до линии Донецк-Ростов
    final distance = _distanceFromPointToLine(
      lat, lng, 
      donetskLat, donetskLng, 
      rostovLat, rostovLng
    );
    
    // Считаем точку в коридоре, если она находится в пределах 30 км от линии маршрута
    return distance <= 30.0;
  }

  /// Вычисляет расстояние от точки до отрезка линии (в километрах)
  static double _distanceFromPointToLine(
    double px, double py,  // координаты точки
    double x1, double y1,  // начало отрезка (Донецк)
    double x2, double y2   // конец отрезка (Ростов)
  ) {
    // Переводим градусы в приблизительные километры (1 градус ≈ 111 км)
    final dx = (x2 - x1) * 111;
    final dy = (y2 - y1) * 111;
    final px_km = (px - x1) * 111;
    final py_km = (py - y1) * 111;
    
    // Длина отрезка в квадрате
    final lengthSq = dx * dx + dy * dy;
    
    if (lengthSq == 0) {
      // Если отрезок - точка, возвращаем расстояние до этой точки
      return _distance(px_km, py_km, 0, 0);
    }
    
    // Проекция точки на отрезок
    double t = (px_km * dx + py_km * dy) / lengthSq;
    t = t < 0 ? 0 : (t > 1 ? 1 : t); // ограничиваем t в пределах [0, 1]
    
    // Ближайшая точка на отрезке
    final projX = t * dx;
    final projY = t * dy;
    
    // Расстояние от точки до проекции
    return _distance(px_km, py_km, projX, projY);
  }

  /// Вычисляет евклидово расстояние между двумя точками
  static double _distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }

  /// Проверяет, является ли маршрут специальным по географическому коридору
  static bool isRouteInDonetskRostovCorridor({
    double? fromLat, double? fromLng,
    double? toLat, double? toLng,
    List<Map>? waypoints,
  }) {
    // Проверяем начальную и конечную точки
    if (fromLat != null && fromLng != null) {
      if (!isPointInDonetskRostovCorridor(fromLat, fromLng)) {
        return false;
      }
    }
    
    if (toLat != null && toLng != null) {
      if (!isPointInDonetskRostovCorridor(toLat, toLng)) {
        return false;
      }
    }
    
    return true;
  }
}
