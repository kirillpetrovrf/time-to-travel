/// Пример РЕАЛЬНОЙ синхронизации цен маршрутов (по образцу CalculatorSettingsService)

// 1. ДИСПЕТЧЕР добавляет маршрут:
await RouteManagementService.instance.addRoute(
  fromCity: 'Донецк', 
  toCity: 'Белгород', 
  price: 50000
);

// 2. FIREBASE автоматически сохраняет в коллекцию 'fixed_routes'

// 3. КЛИЕНТ получает актуальные данные:
final price = await RouteManagementService.instance.getRoutePrice('Донецк', 'Белгород');
// Результат: 50000.0

// 4. КЕШИРОВАНИЕ для быстродействия:
// - При первом запросе: Firebase
// - При повторном: локальный кеш (5 минут)
// - При ошибке сети: fallback к хардкоду в TripPricing