# 📧 Письмо в поддержку Yandex Maps API

---

## Тема письма:
**MapKit инициализируется, но не загружает тайлы карты (API ключ не работает)**

---

## Текст обращения:

Здравствуйте!

Я разрабатываю Flutter-приложение для такси/трансфера с использованием Yandex MapKit. Столкнулся с проблемой: **MapKit успешно инициализируется, но тайлы карты не загружаются** - видна только сетка без изображения.

### 📊 Информация о проекте:

**Приложение:** Time to Travel (такси/трансфер)  
**Платформа:** Flutter (Android)  
**Yandex MapKit версия:** 4.24.0 (yandex_mapkit_full)  
**Package name:** `com.timetotravel.app`  
**API ключ:** `2f1d6a75-b751-4077-b305-c6abaea0b542`

**GitHub репозиторий:** https://github.com/kirillpetrovrf/time-to-travel  
**Последний коммит:** 4706a58

### ❌ Описание проблемы:

1. **MapKit инициализируется успешно:**
   ```
   I/flutter: ✅ Yandex MapKit успешно инициализирован (v4.24.0)
   ```

2. **Карта создаётся и отображается:**
   ```
   I/flutter: 🗺️ [MAP] MapWindow создан: true
   I/flutter: 🗺️ [MAP] Map объект: true
   I/flutter: 🗺️ [MAP] ✅ Map объект доступен
   ```

3. **Камера работает корректно:**
   ```
   I/flutter: 🗺️ [MAP] ✅ Камера перемещена
   I/flutter: 🗺️ [MAP] 🔍 Камера: CameraPosition(target: Point(latitude: 58.0105, longitude: 56.2502), zoom: 11.0)
   ```

4. **НО тайлы не загружаются:**
   ```
   W/yandex.maps: UDJFd3dKAo6oib7P77kw: Clearing cache
   I/flutter: 🗺️ [MAP] 🔍 ❌ Тайлы НЕ ЗАГРУЗИЛИСЬ от Yandex API
   ```

### 🔍 Детальная диагностика:

**Что я обнаружил:**
- ❌ MapKit **НЕ делает HTTP запросы** к Yandex API (нет запросов к `*.yandex.ru` или `*.maps.yandex.net` в логах)
- ❌ Нет ошибок 403, 401 или других HTTP ошибок
- ❌ Нет SSL/Certificate ошибок
- ❌ Нет Network connection ошибок
- ✅ Интернет на устройстве работает
- ✅ Разрешения INTERNET, ACCESS_NETWORK_STATE настроены

**Вывод:** MapKit получает API ключ, но **не пытается** делать запросы к серверу - ключ не проходит валидацию или заблокирован.

### 🔧 Что было проверено:

#### 1. API ключ настроен правильно:

**AndroidManifest.xml:**
```xml
<meta-data
    android:name="com.yandex.mapkit.ApiKey"
    android:value="2f1d6a75-b751-4077-b305-c6abaea0b542" />
```

**Dart код:**
```dart
await YandexMapKit.initialize(
  apiKey: '2f1d6a75-b751-4077-b305-c6abaea0b542',
);
```

#### 2. Разрешения настроены:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### 3. Протестировано на:
- Android Emulator (API 35)
- Internet подключение: работает (WiFi)

### ❓ Возможные причины (моё предположение):

1. **API ключ неправильного типа?**
   - Ключ должен быть типа "JavaScript API и HTTP Геокодер"
   - Возможно, ключ создан только для "HTTP Геокодер" (веб)?

2. **Ключ заблокирован или неактивен?**
   - Истёк срок действия?
   - Требует активации?

3. **Bundle ID не добавлен в ограничения?**
   - Нужно ли добавить `com.timetotravel.app` в консоли Yandex?

4. **Требуется активация биллинга?**
   - Нужна ли привязка платёжной карты даже для бесплатного тарифа?

### 📝 Что мне нужно проверить в Yandex Console:

Прошу подсказать:
1. ✅ Активен ли ключ `2f1d6a75-b751-4077-b305-c6abaea0b542`?
2. ✅ Правильный ли тип ключа для Flutter-приложения?
3. ✅ Нужно ли добавить `com.timetotravel.app` в ограничения?
4. ✅ Требуется ли активация биллинга для мобильного приложения?
5. ✅ Почему MapKit не делает HTTP запросы к API?

### 📚 Дополнительные материалы:

Я подготовил детальный отчёт с логами и диагностикой:

1. **Основной отчёт:**  
   https://github.com/kirillpetrovrf/time-to-travel/blob/main/API_KEY_ISSUE_FINAL_REPORT.md

2. **Скрипты диагностики:**
   - https://github.com/kirillpetrovrf/time-to-travel/blob/main/diagnose_map_403.sh
   - https://github.com/kirillpetrovrf/time-to-travel/blob/main/capture_http_errors_realtime.sh

3. **Логи приложения:** Могу предоставить полные логи по запросу

### 🙏 Прошу помощи:

Не могу понять, почему MapKit не делает запросы к API. Приложение готово к запуску, но без работающей карты я не могу его выпустить.

Буду благодарен за любую помощь в решении этой проблемы!

---

**С уважением,**  
Кирилл Петров  
Разработчик Time to Travel  
GitHub: https://github.com/kirillpetrovrf/time-to-travel  
Email: [ваш email]

---

## 📌 Куда отправить:

1. **Техподдержка Yandex Maps API:**
   - https://yandex.ru/support/maps-api/
   - Или через форму обратной связи в Yandex Console

2. **Или создать issue на GitHub:**
   - https://github.com/yandex/mapkit-android-demo/issues
   - Приложить ссылку на ваш репозиторий

3. **Или написать в Telegram:**
   - @yandex_maps_support (если есть)
