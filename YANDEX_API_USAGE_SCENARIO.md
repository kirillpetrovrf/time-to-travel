# 🗺️ Сценарий использования Yandex Maps API в приложении Time to Travel

**Дата:** 20 октября 2025 г.  
**Приложение:** Time to Travel (Заказ трансфера/такси)  
**Package name:** `com.timetotravel.app`  
**Platform:** Android (Flutter)

---

## 📱 ЧТО ДЕЛАЕТ ПРИЛОЖЕНИЕ

**Time to Travel** - это приложение для заказа индивидуальных трансферов и групповых поездок.

---

## 🎯 КАК МЫ ИСПОЛЬЗУЕМ YANDEX MAPS API

### 1. 🗺️ **Отображение карты** (MapKit)

**Где:** Экран "Свободный маршрут" (`custom_route_with_map_screen.dart`)

**Что делаем:**
- Отображаем интерактивную карту Yandex
- Показываем текущую позицию пользователя
- Пользователь может перемещаться по карте, зумировать
- Визуализируем маршрут на карте

**Код:**
```dart
// lib/features/booking/screens/custom_route_with_map_screen.dart
YandexMap(
  mapObjects: _mapObjects,
  onMapCreated: (controller) async {
    _mapController = controller;
    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: 58.0105, longitude: 56.2502),
          zoom: 11.0,
        ),
      ),
    );
  },
)
```

### 2. 📍 **Геокодирование адресов** (Geocoder API)

**Где:** Расчёт маршрута (`mapkit_service_online.dart`)

**Что делаем:**
- Пользователь вводит адреса в текстовом виде (например: "пермь", "Екатеринбург")
- Мы преобразуем текстовые адреса в координаты
- Используем координаты для расчёта маршрута

**Пример:**
```
Ввод пользователя:
  Откуда: "Пермь, ул. Ленина 51"
  Куда: "Екатеринбург, аэропорт Кольцово"

Наш код:
  "Пермь, ул. Ленина 51" → Point(58.0105, 56.2502)
  "Екатеринбург, аэропорт" → Point(56.743, 60.802)
```

**Код:**
```dart
// lib/services/mapkit_service_online.dart
Future<Coordinates?> _geocodeAddress(String address) async {
  // Используем Yandex Geocoder для преобразования адреса в координаты
  final query = address.trim().toLowerCase();
  
  // Временная заглушка с известными координатами
  final knownCities = {
    'пермь': Coordinates(58.0, 56.3),
    'екатеринбург': Coordinates(56.8, 60.6),
    'москва': Coordinates(55.7, 37.6),
    // ... и т.д.
  };
  
  return knownCities[query];
}
```

**В будущем планируем:**
```dart
// Использовать настоящий Yandex Geocoder API
final searchManager = SearchFactory.instance.createSearchManager(
  SearchManagerType.combined,
);
final searchOptions = SearchOptions();
final geometry = Geometry.fromPoint(Point(latitude: 0, longitude: 0));

searchManager.submit(
  text: address,
  geometry: geometry,
  searchOptions: searchOptions,
  responseHandler: (searchResponse) {
    // Получаем координаты из ответа Yandex
    final geoObject = searchResponse?.items?.first.obj;
    final point = geoObject?.geometry?.first.point;
  },
);
```

### 3. 🚗 **Расчёт маршрута и расстояния** (Routing API)

**Где:** Калькулятор стоимости поездки (`mapkit_service_online.dart`)

**Что делаем:**
- По координатам точек А и Б рассчитываем:
  - **Расстояние** в километрах
  - **Время** в пути в минутах
  - **Маршрут** для отображения на карте

**Зачем:**
- Расстояние нужно для расчёта стоимости поездки
- Время нужно для информирования клиента
- Маршрут нужно показать на карте

**Код:**
```dart
// lib/services/mapkit_service_online.dart
Future<RouteInfo?> calculateRoute({
  required Coordinates from,
  required Coordinates to,
}) async {
  print('🚗 [YANDEX MAPKIT] Расчёт маршрута');
  
  // В идеале используем Yandex Routing API:
  final drivingRouter = DirectionsFactory.instance.createDrivingRouter();
  final requestPoints = [
    RequestPoint(
      point: Point(latitude: from.latitude, longitude: from.longitude),
      requestPointType: RequestPointType.waypoint,
    ),
    RequestPoint(
      point: Point(latitude: to.latitude, longitude: to.longitude),
      requestPointType: RequestPointType.waypoint,
    ),
  ];
  
  final drivingOptions = DrivingOptions(
    routesCount: 1,
    avoidTolls: false,
  );
  
  // Получаем маршрут от Yandex
  final result = await drivingRouter.requestRoutes(
    points: requestPoints,
    drivingOptions: drivingOptions,
  );
  
  // Извлекаем расстояние и время
  final route = result.routes?.first;
  final distanceKm = route?.metadata.weight.distance.value ?? 0;
  final timeMinutes = route?.metadata.weight.time.value ?? 0;
  
  return RouteInfo(
    distanceKm: distanceKm / 1000, // метры → км
    durationMinutes: (timeMinutes / 60).round(), // секунды → минуты
  );
}
```

### 4. 💰 **Расчёт стоимости поездки**

**На основе маршрута:**
```
Расстояние от Yandex API: 290 км
Цена за км: 15₽
Базовая стоимость: 500₽

Итого: 500₽ + (290 км × 15₽) = 4850₽ → 5000₽ (округлено)
```

---

## 📊 ЧАСТОТА ИСПОЛЬЗОВАНИЯ API

### Типичный сценарий:

1. **Пользователь открывает "Свободный маршрут"**
   - 🗺️ Загрузка тайлов карты (1 запрос к MapKit)

2. **Вводит адреса "Откуда" и "Куда"**
   - 📍 Геокодирование 2 адресов (2 запроса к Geocoder API)

3. **Нажимает "Рассчитать стоимость"**
   - 🚗 Расчёт маршрута (1 запрос к Routing API)
   - 🗺️ Отрисовка маршрута на карте (использование уже загруженных тайлов)

4. **Подтверждает заказ**
   - Маршрут сохраняется в базу данных
   - Больше запросов к Yandex API не требуется

### Оценка нагрузки:

- **Тайлы карты:** ~10-50 тайлов на одну загрузку карты
- **Геокодирование:** 2 запроса на каждый расчёт маршрута
- **Маршрутизация:** 1 запрос на каждый расчёт маршрута

**Всего на 1 заказ:** ~15-55 запросов к API

**Ожидаемая нагрузка:**
- Тестирование: ~100 заказов/месяц = 1,500-5,500 запросов
- Продакшн (после запуска): ~500 заказов/месяц = 7,500-27,500 запросов

**Укладываемся в бесплатный тариф:** 25,000 запросов/месяц ✅

---

## 🔑 КАКОЙ ТИП API КЛЮЧА НАМ НУЖЕН

### ✅ **JavaScript API и HTTP Геокодер**

**Почему именно этот тип:**

1. **JavaScript API** - для MapKit SDK (отображение карты в мобильном приложении)
2. **HTTP Геокодер** - для преобразования адресов в координаты

### ❌ **НЕ подходят:**

- ❌ "HTTP Геокодер" (только) - не работает для MapKit
- ❌ "MapKit SDK for Android" (устаревший) - старая версия

---

## 📋 КОНФИГУРАЦИЯ ПРИЛОЖЕНИЯ

### Package name:
```
com.timetotravel.app
```

### Permissions (AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### API Key configuration:
```xml
<meta-data
    android:name="com.yandex.mapkit.ApiKey"
    android:value="2f1d6a75-b751-4077-b305-c6abaea0b542" />
```

### Dart initialization:
```dart
await YandexMapKit.initialize(
  apiKey: '2f1d6a75-b751-4077-b305-c6abaea0b542',
);
```

---

## 🎯 ТЕКУЩАЯ ПРОБЛЕМА

### Что происходит сейчас:

```
✅ MapKit инициализируется успешно (v4.24.0)
✅ Карта создаётся
✅ Камера работает
❌ Тайлы НЕ загружаются (видна только сетка)
```

### Диагностика показала:

- MapKit **НЕ ДЕЛАЕТ HTTP запросов** к серверам Yandex
- В логах нет 403, 404 или других HTTP ошибок
- Интернет на устройстве есть
- Права INTERNET настроены

**Вывод:** API ключ `2f1d6a75-b751-4077-b305-c6abaea0b542` не принимается MapKit SDK

---

## ❓ ВОПРОСЫ К YANDEX SUPPORT

1. **Активен ли API ключ `2f1d6a75-b751-4077-b305-c6abaea0b542`?**

2. **Правильный ли у него тип?**
   - Должен быть: "JavaScript API и HTTP Геокодер"

3. **Есть ли ограничения по bundle ID?**
   - Нужно добавить: `com.timetotravel.app`
   - Или убрать ограничения (`*`)

4. **Требуется ли активация биллинга** для бесплатного тарифа?

5. **Почему MapKit не делает HTTP запросы к серверам Yandex?**

---

## 📞 КОНТАКТЫ

**Проект:** Time to Travel  
**GitHub:** https://github.com/YOUR_USERNAME/time-to-travel  
**Email:** ___________  
**Telegram:** ___________  

---

**Буду благодарен за помощь в решении проблемы!** 🙏
