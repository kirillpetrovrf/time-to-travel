import '../models/price_calculation.dart';
import '../models/trip_type.dart';
import 'calculator_settings_service.dart';

/// Сервис для расчёта стоимости поездки
class PriceCalculatorService {
  static final PriceCalculatorService instance = PriceCalculatorService._();
  PriceCalculatorService._();

  final CalculatorSettingsService _settingsService =
      CalculatorSettingsService.instance;

  /// Рассчитать стоимость поездки по расстоянию
  Future<PriceCalculation> calculatePrice(double distanceKm, {
    String? fromCity,
    String? toCity, 
    String? departureTime,
    List<String>? intermediateCities,
    // Координаты для географической проверки коридора Донецк-Ростов
    double? fromLat,
    double? fromLng,
    double? toLat, 
    double? toLng,
  }) async {
    print('💰 [PRICE] ========== РАСЧЁТ СТОИМОСТИ ==========');
    print('💰 [PRICE] Расстояние: ${distanceKm.toStringAsFixed(2)} км');
    print('💰 [PRICE] От: $fromCity → До: $toCity');
    if (intermediateCities?.isNotEmpty == true) {
      print('💰 [PRICE] Промежуточные города: ${intermediateCities!.join(", ")}');
    }

    // Получаем настройки из Firebase
    final settings = await _settingsService.getSettings();
    final pricePerKmBeyondRostov = settings.pricePerKmBeyondRostov ?? 60.0;

    // 🎯 СПЕЦИАЛЬНАЯ ЛОГИКА: Проверяем маршрут Донецк-Ростов
    final specialPrice = TripPricing.getSpecialRoutePrice(
      fromCity: fromCity,
      toCity: toCity,
      departureTime: departureTime,
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      totalDistanceKm: distanceKm,
      pricePerKmBeyondRostov: pricePerKmBeyondRostov,
    );

    if (specialPrice > 0) {
      print('💰 [PRICE] 🎯 СПЕЦИАЛЬНЫЙ МАРШРУТ: Донецк ↔ Ростов');
      print('💰 [PRICE] 🕒 Время: ${departureTime ?? "текущее"}');
      print('💰 [PRICE] 💎 Фиксированная цена: ${specialPrice.toStringAsFixed(0)}₽');
      print('💰 [PRICE] ========== СПЕЦИАЛЬНЫЙ ТАРИФ ==========');

      return PriceCalculation(
        rawPrice: specialPrice,
        finalPrice: specialPrice,
        distance: distanceKm,
        baseCost: specialPrice,
        costPerKm: 0,
        roundedUp: false,
        appliedMinPrice: false,
        isSpecialRoute: true,
      );
    }

    // 🌍 ГЕОГРАФИЧЕСКАЯ ПРОВЕРКА: Проверяем, идет ли маршрут через Ростов
    if (fromLat != null && fromLng != null && toLat != null && toLng != null) {
      // Проверяем, что отправление из Донецка
      final isFromDonetsk = TripPricing.isPointNearDonetsk(fromLat, fromLng);
      
      if (isFromDonetsk) {
        // Проверяем, находится ли конечная точка В ГОРОДЕ Ростов-на-Дону
        final isDestinationInRostov = TripPricing.isPointInRostovCity(toLat, toLng);
        
        if (isDestinationInRostov) {
          // Конечная точка ВНУТРИ Ростова → фиксированная цена 8000₽
          final basePrice = TripPricing.getDonetskRostovBasePrice(departureTime);
          print('💰 [PRICE] 🎯 Конечная точка ВНУТРИ города Ростов-на-Дону');
          print('💰 [PRICE] 📍 Координаты: ($fromLat, $fromLng) → ($toLat, $toLng)');
          print('💰 [PRICE] 💎 Фиксированная цена: ${basePrice.toStringAsFixed(0)}₽');
          
          return PriceCalculation(
            rawPrice: basePrice,
            finalPrice: basePrice,
            distance: distanceKm,
            baseCost: basePrice,
            costPerKm: 0,
            roundedUp: false,
            appliedMinPrice: false,
            isSpecialRoute: true,
          );
        }
        
        // 🎯 УНИВЕРСАЛЬНОЕ ПРАВИЛО: Все маршруты от Донецка → базовая цена 8000₽ + 60₽/км
        // Это применяется к ЛЮБОМУ пункту назначения, не только к городу Ростов
        const double donetskRostovDistance = 190.0;
        final basePrice = TripPricing.getDonetskRostovBasePrice(departureTime);
        
        // Рассчитываем доплату за километры после 190км
        double additionalCost = 0.0;
        if (distanceKm > donetskRostovDistance) {
          double beyondRostovKm = distanceKm - donetskRostovDistance;
          additionalCost = beyondRostovKm * pricePerKmBeyondRostov;
          
          print('💰 [PRICE] 🚗 Маршрут дальше базового расстояния Донецк-Ростов');
          print('💰 [PRICE] 📍 От: $fromLat, $fromLng → До: $toLat, $toLng');
          print('💰 [PRICE] 📏 Общее расстояние: ${distanceKm.toStringAsFixed(2)} км');
          print('💰 [PRICE] 📏 Базовое расстояние: $donetskRostovDistance км');
          print('💰 [PRICE] 📏 Дополнительно: ${beyondRostovKm.toStringAsFixed(2)} км');
          print('💰 [PRICE] 💵 Доплата: ${additionalCost.toStringAsFixed(2)}₽ (${beyondRostovKm.toStringAsFixed(2)} км × $pricePerKmBeyondRostov₽/км)');
          print('💰 [PRICE] 💎 Итоговая цена: ${(basePrice + additionalCost).toStringAsFixed(2)}₽');
        } else {
          print('💰 [PRICE] 🚗 Маршрут в пределах базового расстояния');
          print('💰 [PRICE] 📍 От: $fromLat, $fromLng → До: $toLat, $toLng');
          print('💰 [PRICE] 💎 Базовая цена: ${basePrice.toStringAsFixed(0)}₽');
        }
        
        final finalPrice = basePrice + additionalCost;
        
        return PriceCalculation(
          rawPrice: finalPrice,
          finalPrice: finalPrice,
          distance: distanceKm,
          baseCost: finalPrice,
          costPerKm: 0,
          roundedUp: false,
          appliedMinPrice: false,
          isSpecialRoute: true,
        );
      }
    }

    // Проверяем по промежуточным городам (резервный метод)
    if (intermediateCities?.isNotEmpty == true) {
      final allCities = [fromCity, ...intermediateCities!, toCity]
          .where((city) => city != null)
          .cast<String>()
          .toList();
      
      if (TripPricing.containsDonetskRostovCities(allCities)) {
        final routePrice = TripPricing.getSpecialRoutePrice(
          fromCity: 'Донецк',
          toCity: 'Ростов-на-Дону',
          departureTime: departureTime,
        );
        
        if (routePrice > 0) {
          print('💰 [PRICE] 🎯 МАРШРУТ ПО ГОРОДАМ Донецк-Ростов');
          print('💰 [PRICE] 💎 Фиксированная цена: ${routePrice.toStringAsFixed(0)}₽');
          
          return PriceCalculation(
            rawPrice: routePrice,
            finalPrice: routePrice,
            distance: distanceKm,
            baseCost: routePrice,
            costPerKm: 0,
            roundedUp: false,
            appliedMinPrice: false,
            isSpecialRoute: true,
          );
        }
      }
    }

    // Настройки уже загружены выше, используем их
    print(
      '💰 [PRICE] Настройки: base=${settings.baseCost}₽, perKm=${settings.costPerKm}₽, min=${settings.minPrice}₽',
    );

    // Формула: базовая + (км × коэффициент)
    double rawPrice = settings.baseCost + (distanceKm * settings.costPerKm);
    print('💰 [PRICE] Сырая цена: ${rawPrice.toStringAsFixed(2)}₽');

    // Проверка минимальной цены
    if (rawPrice < settings.minPrice) {
      print(
        '💰 [PRICE] ⚠️ Цена ниже минимума! Применяем минимальную: ${settings.minPrice}₽',
      );
      return PriceCalculation(
        rawPrice: rawPrice,
        finalPrice: settings.minPrice,
        distance: distanceKm,
        baseCost: settings.baseCost,
        costPerKm: settings.costPerKm,
        roundedUp: false,
        appliedMinPrice: true,
      );
    }

    // Округление до тысяч вверх (если включено)
    double finalPrice = rawPrice;
    bool roundedUp = false;

    if (settings.roundToThousands && rawPrice > settings.minPrice) {
      finalPrice = (rawPrice / 1000).ceil() * 1000;
      roundedUp = rawPrice != finalPrice;

      if (roundedUp) {
        print(
          '💰 [PRICE] 🔼 Округлено до тысяч: ${rawPrice.toStringAsFixed(0)}₽ → ${finalPrice.toStringAsFixed(0)}₽',
        );
      }
    }

    final calculation = PriceCalculation(
      rawPrice: rawPrice,
      finalPrice: finalPrice,
      distance: distanceKm,
      baseCost: settings.baseCost,
      costPerKm: settings.costPerKm,
      roundedUp: roundedUp,
      appliedMinPrice: false,
    );

    print(
      '💰 [PRICE] ========== ИТОГО: ${finalPrice.toStringAsFixed(0)}₽ ==========',
    );
    return calculation;
  }

  /// Получить примеры расчёта для админ-панели
  Future<Map<int, double>> getExamples() async {
    final distances = [10, 50, 100, 150, 200];
    final Map<int, double> examples = {};

    for (final distance in distances) {
      final calculation = await calculatePrice(distance.toDouble());
      examples[distance] = calculation.finalPrice;
    }

    return examples;
  }
}
