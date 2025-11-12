# Интеграция поиска и маршрутизации

## Обзор

Система интеграции обеспечивает двунаправленную синхронизацию между поиском адресов и построением маршрута:

1. **Тап по карте** → автоматическое заполнение поля адреса
2. **Выбор адреса** → автоматическая установка точки на карте и построение маршрута

## Архитектура

### Основные компоненты

1. **`ReverseGeocodingService`** (`lib/services/reverse_geocoding_service.dart`)
   - Преобразует координаты в человекочитаемые адреса
   - Использует Yandex Search API с `SearchManager.submit()`
   - Асинхронная работа с таймаутом 10 секунд

2. **`SearchRoutingIntegration`** (`lib/managers/search_routing_integration.dart`)
   - Координирует взаимодействие между поиском и маршрутизацией
   - Предотвращает циклические обновления
   - Управляет TextEditingController для полей ввода

3. **`MapSearchManager`** (расширен)
   - Добавлен callback `onAddressSelected` для интеграции
   - Уведомляет координатор когда найден адрес

### Интеграционные хуки в MainScreen

```dart
// Инициализация интеграции
_integration = SearchRoutingIntegration(
  searchManager: _searchManager,
  routeManager: _routePointsManager,
);

_integration.setFieldControllers(
  fromController: _fromController,
  toController: _toController,
);

_integration.initialize();

// Хук для тапов по карте
MapInputListener(
  onMapTap: (point, pointType) => _integration.handleMapTap(point, pointType),
)
```

## Использование

### 1. Тап по карте

Когда пользователь тапает по карте:
1. `MapInputListener` перехватывает тап
2. Вызывается `_integration.handleMapTap(point, pointType)`
3. Точка устанавливается на карте через `RoutePointsManager`
4. Запускается reverse geocoding для получения адреса
5. Соответствующее поле ввода обновляется полученным адресом

### 2. Выбор адреса из поиска

Когда пользователь выбирает адрес из автодополнения:
1. `MapSearchManager` находит координаты адреса
2. Вызывается callback `onAddressSelected` 
3. `SearchRoutingIntegration.handleAddressSelection()` устанавливает точку
4. Поле ввода обновляется выбранным адресом

### 3. Предотвращение циклов

Система использует флаги `_isUpdatingFromMap` и `_isUpdatingFromSearch` для предотвращения циклических обновлений между картой и полями ввода.

## API Reference

### ReverseGeocodingService

```dart
// Получение адреса по координатам
Future<String?> getAddressFromPoint(Point point)

// Освобождение ресурсов
void dispose()
```

### SearchRoutingIntegration

```dart
// Настройка контроллеров полей
void setFieldControllers({
  TextEditingController? fromController,
  TextEditingController? toController,
})

// Инициализация
void initialize()

// Обработка тапа по карте
Future<void> handleMapTap(Point point, RoutePointType pointType)

// Обработка выбора адреса
void handleAddressSelection(Point point, String address, RoutePointType pointType)

// Освобождение ресурсов
void dispose()
```

## Технические детали

### Yandex MapKit API

- Использует `SearchManager.submit()` с `Geometry.fromPoint(point)` для reverse geocoding
- Пустой параметр `text: ""` для обратного геокодирования
- Извлекает адрес из `geoObject.name`

### Обработка ошибок

- Все методы содержат try-catch блоки
- Таймауты для предотвращения зависания
- Логирование для отладки

### Очистка ресурсов

Все компоненты имеют методы `dispose()` которые вызываются в `MainScreen.dispose()` для правильной очистки ресурсов Yandex API.

## Тестирование

Для проверки компонентов можно использовать `IntegrationTest.runBasicTest()` - это проверит создание и базовую работу сервисов без полного UI.

## Статус

✅ Полная интеграция реализована и готова к тестированию на реальном устройстве
✅ Reverse geocoding через Yandex Search API
✅ Двунаправленная синхронизация карта ↔ поля ввода  
✅ Предотвращение циклических обновлений
✅ Правильная очистка ресурсов