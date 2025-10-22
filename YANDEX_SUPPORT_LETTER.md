# Обращение в поддержку Yandex Maps API

**Тема:** MapKit инициализируется, но не загружает тайлы карты

---

## Описание проблемы

Разрабатываю мобильное приложение на Flutter с использованием `yandex_mapkit_full: ^4.24.0`.

**Проблема:** MapKit успешно инициализируется, но тайлы карты не загружаются - отображается только сетка.

## Детали

### Приложение:
- **Package name:** `com.timetotravel.app`
- **Platform:** Android
- **Yandex MapKit version:** 4.24.0
- **Flutter version:** latest stable

### API ключ:
```
2f1d6a75-b751-4077-b305-c6abaea0b542
```

### Логи приложения:

```
I/flutter: ✅ Yandex MapKit успешно инициализирован (v4.24.0)
I/flutter: 🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========
I/flutter: 🗺️ [MAP] MapWindow создан: true
I/flutter: 🗺️ [MAP] Map объект: true
I/flutter: 🗺️ [MAP] ✅ Map объект доступен
I/flutter: 🗺️ [MAP] ✅ Камера перемещена
I/flutter: 🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========
```

### Но тайлы не загружаются!

**В логах Android НЕТ:**
- HTTP запросов к `*.yandex.ru` или `*.maps.yandex.net`
- 403 ошибок
- SSL/Certificate ошибок
- Network connection ошибок

**Есть только:**
```
W/yandex.maps: Clearing cache
```

## Конфигурация

### AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<application>
    <meta-data
        android:name="com.yandex.mapkit.ApiKey"
        android:value="2f1d6a75-b751-4077-b305-c6abaea0b542" />
</application>
```

### Dart код:
```dart
await YandexMapKit.initialize(
  apiKey: '2f1d6a75-b751-4077-b305-c6abaea0b542',
);
```

## Сценарий использования API

**Приложение:** Заказ индивидуальных трансферов и групповых поездок

**Что мы используем:**

1. **MapKit** - отображение интерактивной карты в экране "Свободный маршрут"
   - Показываем карту города
   - Отображаем маршрут между точками А и Б
   - Пользователь может перемещаться и зумировать

2. **Geocoder API** - преобразование адресов в координаты
   - Пользователь вводит: "Пермь, ул. Ленина 51"
   - Мы получаем: Point(58.0105, 56.2502)

3. **Routing API** - расчёт маршрута и расстояния
   - Рассчитываем расстояние в км (для стоимости)
   - Рассчитываем время в пути
   - Строим маршрут на карте

**Частота использования:**
- Тестирование: ~100 заказов/месяц = 1,500-5,500 запросов
- Продакшн: ~500 заказов/месяц = 7,500-27,500 запросов
- ✅ Укладываемся в бесплатный тариф 25,000 запросов/месяц

**Нужен тип ключа:** "JavaScript API и HTTP Геокодер"

## Вопросы

1. **Правильно ли настроен API ключ `2f1d6a75-b751-4077-b305-c6abaea0b542`?**
   - Активен ли ключ?
   - Какой у него тип? (нужен "JavaScript API и HTTP Геокодер" для мобильных приложений)
   - Есть ли ограничения по bundle ID?

2. **Требуется ли активация биллинга** даже для бесплатного тарифа?

3. **Нужно ли добавить** `com.timetotravel.app` в список разрешённых приложений?

4. **Почему MapKit не делает HTTP запросы** к серверам Yandex для загрузки тайлов?

## Скриншоты

![Карта показывает только сетку](screenshot.png)

## Ссылка на GitHub репозиторий

https://github.com/YOUR_USERNAME/time-to-travel

(код приложения с полной конфигурацией)

---

**Буду благодарен за помощь!**

Контакты:
- Email: ___________
- Telegram: ___________
