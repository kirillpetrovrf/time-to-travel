import '../models/price_calculation.dart';
import '../models/trip_type.dart';
import 'calculator_settings_service.dart';
import 'route_management_service.dart';

/// Сервис для расчёта стоимости поездки
class PriceCalculatorService {
  static final PriceCalculatorService instance = PriceCalculatorService._();
  PriceCalculatorService._();

  final CalculatorSettingsService _settingsService =
      CalculatorSettingsService.instance;
  final RouteManagementService _routeService =
      RouteManagementService.instance;

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

    // 🎯 ПРИОРИТЕТ 1: Проверяем предустановленные маршруты (новая система)
    
    double? predefinedPrice = await _routeService.getRoutePrice(fromCity, toCity);
    
    if (predefinedPrice != null) {
      print('💰 [PRICE] 🎯 ПРЕДУСТАНОВЛЕННЫЙ МАРШРУТ: $fromCity → $toCity');
      print('💰 [PRICE] 💎 Предустановленная цена: ${predefinedPrice.toStringAsFixed(0)}₽');
      print('💰 [PRICE] 🔄 Двусторонний маршрут (работает в обе стороны)');
      print('💰 [PRICE] ========== ПРЕДУСТАНОВЛЕННЫЙ ТАРИФ ==========');

      return PriceCalculation(
        rawPrice: predefinedPrice,
        finalPrice: predefinedPrice,
        distance: distanceKm,
        baseCost: predefinedPrice,
        costPerKm: 0,
        roundedUp: false,
        appliedMinPrice: false,
        roundedDistanceKm: null,
        isSpecialRoute: true,
      );
    }

    // 🎯 ПРИОРИТЕТ 2: Проверяем фиксированные тарифы (старая система, fallback)
    
    double? fixedPrice = TripPricing.getFixedRoutePrice(fromCity, toCity);
    
    if (fixedPrice != null) {
      print('💰 [PRICE] 🎯 ФИКСИРОВАННЫЙ ТАРИФ (СТАРЫЙ): $fromCity → $toCity');
      print('💰 [PRICE] 💎 Фиксированная цена: ${fixedPrice.toStringAsFixed(0)}₽');
      print('💰 [PRICE] ========== СТАРЫЙ ФИКСИРОВАННЫЙ ТАРИФ ==========');

      return PriceCalculation(
        rawPrice: fixedPrice,
        finalPrice: fixedPrice,
        distance: distanceKm,
        baseCost: fixedPrice,
        costPerKm: 0,
        roundedUp: false,
        appliedMinPrice: false,
        roundedDistanceKm: null,
        isSpecialRoute: true,
      );
    }

    // 🎯 ПРИОРИТЕТ 3: Проверяем специальный маршрут Донецк-Ростов
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
      print('💰 [PRICE] 💎 Специальная цена: ${specialPrice.toStringAsFixed(0)}₽');
      print('💰 [PRICE] ========== СПЕЦИАЛЬНЫЙ ТАРИФ ==========');

      return PriceCalculation(
        rawPrice: specialPrice,
        finalPrice: specialPrice,
        distance: distanceKm,
        baseCost: specialPrice,
        costPerKm: 0,
        roundedUp: false,
        appliedMinPrice: false,
        roundedDistanceKm: null,
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
            roundedDistanceKm: null,
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
          
          // 🔄 УМНОЕ ОКРУГЛЕНИЕ: Округляем дополнительные км до 50км вверх
          double roundedBeyondKm = _roundKilometersUp(beyondRostovKm);
          bool kmRounded = roundedBeyondKm != beyondRostovKm;
          
          additionalCost = roundedBeyondKm * pricePerKmBeyondRostov;
          
          print('💰 [PRICE] 🚗 Маршрут дальше базового расстояния Донецк-Ростов');
          print('💰 [PRICE] 📍 От: $fromLat, $fromLng → До: $toLat, $toLng');
          print('💰 [PRICE] 📏 Общее расстояние: ${distanceKm.toStringAsFixed(2)} км');
          print('💰 [PRICE] 📏 Базовое расстояние: $donetskRostovDistance км');
          if (kmRounded) {
            print('💰 [PRICE] 📏 Дополнительно: ${beyondRostovKm.toStringAsFixed(2)} → ${roundedBeyondKm.toInt()}км (округлено)');
          } else {
            print('💰 [PRICE] � Дополнительно: ${beyondRostovKm.toStringAsFixed(2)} км');
          }
          print('💰 [PRICE] �💵 Доплата: ${additionalCost.toStringAsFixed(2)}₽ (${roundedBeyondKm.toInt()} км × $pricePerKmBeyondRostov₽/км)');
          print('💰 [PRICE] 💎 Итоговая цена: ${(basePrice + additionalCost).toStringAsFixed(2)}₽');
        } else {
          print('💰 [PRICE] 🚗 Маршрут в пределах базового расстояния');
          print('💰 [PRICE] 📍 От: $fromLat, $fromLng → До: $toLat, $toLng');
          print('💰 [PRICE] 💎 Базовая цена: ${basePrice.toStringAsFixed(0)}₽');
        }
        
        double rawPrice = basePrice + additionalCost;
        
        // 🔄 ОКРУГЛЕНИЕ ЦЕНЫ: Применяем округление до тысяч для Донецкой логики
        double finalPrice = rawPrice;
        bool priceRounded = false;
        if (settings.roundToThousands && rawPrice > settings.minPrice) {
          finalPrice = (rawPrice / 1000).ceil() * 1000;
          priceRounded = rawPrice != finalPrice;
          
          if (priceRounded) {
            print('💰 [PRICE] 🔼 Округлено до тысяч: ${rawPrice.toStringAsFixed(2)}₽ → ${finalPrice.toStringAsFixed(0)}₽');
          }
        }
        
        return PriceCalculation(
          rawPrice: rawPrice,
          finalPrice: finalPrice,
          distance: distanceKm,
          baseCost: basePrice,
          costPerKm: pricePerKmBeyondRostov,
          roundedUp: priceRounded,
          appliedMinPrice: false,
          roundedDistanceKm: (distanceKm > donetskRostovDistance) ? _roundKilometersUp(distanceKm - donetskRostovDistance) + donetskRostovDistance : null,
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
            roundedDistanceKm: null,
            isSpecialRoute: true,
          );
        }
      }
    }

    // Настройки уже загружены выше, используем их
    print(
      '💰 [PRICE] Настройки: base=${settings.baseCost}₽, perKm=${settings.costPerKm}₽, min=${settings.minPrice}₽',
    );

    // 🔄 УМНОЕ ОКРУГЛЕНИЕ: Округляем километры до 50км вверх
    double roundedKm = _roundKilometersUp(distanceKm);
    bool kmRounded = roundedKm != distanceKm;
    
    if (kmRounded) {
      print('💰 [PRICE] 📏 Округление км: ${distanceKm.toStringAsFixed(1)} → ${roundedKm.toInt()}км');
    } else {
      print('💰 [PRICE] 📏 Километры: ${distanceKm.toStringAsFixed(1)}км (округление не требуется)');
    }

    // Формула с округленными километрами: базовая + (округленные_км × коэффициент)
    double rawPrice = settings.baseCost + (roundedKm * settings.costPerKm);
    print('💰 [PRICE] Расчет: ${settings.baseCost}₽ + (${roundedKm.toInt()}км × ${settings.costPerKm}₽) = ${rawPrice.toStringAsFixed(0)}₽');

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
        roundedDistanceKm: roundedKm,
      );
    }

    // Округление до тысяч вверх (если включено)
    // ⚠️ ВАЖНО: Округление применяется ТОЛЬКО к расчетным маршрутам (не к предустановленным!)
    double finalPrice = rawPrice;
    bool roundedUp = false;

    if (settings.roundToThousands && rawPrice > settings.minPrice) {
      finalPrice = (rawPrice / 1000).ceil() * 1000;
      roundedUp = rawPrice != finalPrice;

      if (roundedUp) {
        print(
          '💰 [PRICE] 🔼 Округлено до тысяч (живой расчет): ${rawPrice.toStringAsFixed(0)}₽ → ${finalPrice.toStringAsFixed(0)}₽',
        );
      } else {
        print('💰 [PRICE] ✅ Цена уже кратна 1000₽, округление не требуется');
      }
    } else {
      print('💰 [PRICE] ℹ️ Округление отключено или цена ниже минимальной');
    }

    final calculation = PriceCalculation(
      rawPrice: rawPrice,
      finalPrice: finalPrice,
      distance: distanceKm,
      baseCost: settings.baseCost,
      costPerKm: settings.costPerKm,
      roundedUp: roundedUp,
      appliedMinPrice: false,
      roundedDistanceKm: roundedKm,
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

  /// 🔄 Умное округление километров до 50км вверх
  /// Примеры: 430км → 450км, 480км → 500км, 50км → 50км (без изменений)
  double _roundKilometersUp(double km) {
    const int roundingInterval = 50;
    double rounded = (km / roundingInterval).ceil() * roundingInterval.toDouble();
    return rounded;
  }
}
