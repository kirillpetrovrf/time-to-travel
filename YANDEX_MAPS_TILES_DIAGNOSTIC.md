# 🗺️ ДИАГНОСТИКА ПРОБЛЕМЫ С ОТОБРАЖЕНИЕМ ТАЙЛОВ YANDEX MAPS

## ПРОБЛЕМА
Карта Yandex Maps показывает только **сетку без изображений (тайлов)**.

**Симптомы:**
- ✅ Карта инициализируется успешно
- ✅ Камера перемещается
- ✅ Координаты отображаются
- ❌ **Тайлы карты не загружаются** (видна только пустая сетка)

**Ошибка в логах:**
```
W/yandex.maps( 7742): poxHcJDuv2tO5gpI+pN3: No available cache for request
```

---

## ВОЗМОЖНЫЕ ПРИЧИНЫ

### 1. ❌ Проблемы с сетевым подключением
**Симптомы:**
- Устройство не имеет доступа к интернету
- Wi-Fi подключен, но нет доступа к внешним серверам
- Брандмауэр блокирует запросы к Yandex

**Решение:**
```bash
# Проверка интернета на устройстве
adb shell ping -c 3 maps.yandex.ru
adb shell ping -c 3 8.8.8.8

# Проверка DNS
adb shell nslookup maps.yandex.ru
```

### 2. ❌ API-ключ Yandex Maps недействителен
**Симптомы:**
- Ошибка "No available cache for request"
- Запросы к API отклоняются

**Проверка:**
1. Откройте `AndroidManifest.xml`
2. Найдите: `<meta-data android:name="com.yandex.mapkit.ApiKey" android:value="..."/>`
3. Убедитесь, что API-ключ корректен: `2f1d6a75-b751-4077-b305-c6abaea0b542`

**Где получить новый ключ:**
https://developer.tech.yandex.ru/services

### 3. ❌ Недостаточные разрешения Android
**Требуемые разрешения в `AndroidManifest.xml`:**
```xml
<!-- Сеть -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />

<!-- Геолокация (опционально, но рекомендуется) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 4. ❌ Блокировка cleartext HTTP-трафика (Android 9+)
**Симптомы:**
- Работает на Android 8.x и ниже
- НЕ работает на Android 9+ (API 28+)

**Решение:**
Проверьте `AndroidManifest.xml`:
```xml
<application
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```

Проверьте `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
    
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">yandex.ru</domain>
        <domain includeSubdomains="true">yandex.net</domain>
        <domain includeSubdomains="true">yandex.com</domain>
    </domain-config>
</network-security-config>
```

### 5. ❌ Проблемы с кешем MapKit
**Решение:**
```bash
# Очистить кеш приложения
adb shell pm clear com.timetotravel.app

# Переустановить приложение
flutter clean
flutter run
```

### 6. ❌ Проблемы с DNS в Китае или других странах
Если приложение используется в **Китае** или других странах с ограничениями:
- Yandex Maps может быть заблокирован
- Требуется VPN или альтернативный провайдер карт

---

## ДИАГНОСТИЧЕСКИЕ КОМАНДЫ

### 1. Проверка логов в реальном времени
```bash
# Запустить мониторинг логов Yandex Maps
./check_yandex_maps_logs.sh

# Или вручную
adb logcat | grep -E "yandex.maps|MAP|MAPKIT"
```

### 2. Проверка сетевого трафика
```bash
# Проверка, отправляет ли приложение запросы
adb shell "tcpdump -i any -s 0 -w - 'host maps.yandex.ru'" | tcpdump -r - -A
```

### 3. Проверка разрешений
```bash
# Список всех разрешений приложения
adb shell dumpsys package com.timetotravel.app | grep permission
```

### 4. Проверка доступа к API
```bash
# Тест доступа к Yandex Maps API с устройства
adb shell "curl -v https://maps.yandex.ru"
```

---

## ПОШАГОВАЯ ДИАГНОСТИКА

### Шаг 1: Проверьте интернет-соединение
```bash
adb shell ping -c 5 maps.yandex.ru
```
**Ожидаемый результат:** Пакеты успешно отправлены и получены

---

### Шаг 2: Проверьте логи приложения
```bash
flutter run
```
**Смотрите на:**
```
✅ Yandex MapKit успешно инициализирован (v4.24.0)
🗺️ [MAP] ✅ КАРТА ГОТОВА К РАБОТЕ
❌ W/yandex.maps: No available cache for request  # <-- ОШИБКА!
```

---

### Шаг 3: Проверьте настройки Android
1. Откройте `android/app/src/main/AndroidManifest.xml`
2. Убедитесь, что:
   - `android:usesCleartextTraffic="true"`
   - `android:networkSecurityConfig="@xml/network_security_config"`
   - Все разрешения добавлены

---

### Шаг 4: Пересоберите приложение
```bash
flutter clean
flutter pub get
flutter run
```

---

### Шаг 5: Проверьте API-ключ
1. Перейдите: https://developer.tech.yandex.ru/services
2. Проверьте статус вашего API-ключа
3. Убедитесь, что:
   - Ключ активен
   - Не превышен лимит запросов
   - Включен MapKit API

---

## ДОБАВЛЕННЫЕ ИЗМЕНЕНИЯ

### 1. Добавлено логирование в `custom_route_with_map_screen.dart`
```dart
// После инициализации карты через 3 секунды выводится проверка:
🗺️ [MAP] 🔍 ПРОВЕРКА ПОСЛЕ 3 СЕКУНД:
🗺️ [MAP] 🔍 Если вы видите только сетку без изображения:
🗺️ [MAP] 🔍 ❌ Тайлы НЕ ЗАГРУЗИЛИСЬ от Yandex API
```

### 2. Добавлены разрешения на геолокацию
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 3. Создан скрипт мониторинга
```bash
./check_yandex_maps_logs.sh
```

---

## ТЕСТИРОВАНИЕ

### Тест 1: Запустите приложение
```bash
flutter run
```

### Тест 2: Откройте экран "Свободный маршрут"
Следите за логами:
```
🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========
🗺️ [MAP] 🔍 ДИАГНОСТИКА КАРТЫ:
🗺️ [MAP] 🔍 MapType: ...
🗺️ [MAP] 🔍 ПРОВЕРКА ПОСЛЕ 3 СЕКУНД:
```

### Тест 3: Проверьте, появились ли тайлы
Если **через 3 секунды карта всё ещё пустая**:
```bash
# Запустите мониторинг логов
./check_yandex_maps_logs.sh
```

Смотрите на:
- `❌ [CACHE ERROR]` - проблема с загрузкой тайлов
- `❌ [HTTP ERROR]` - проблема с сетью
- `⚠️  [SSL WARNING]` - проблема с сертификатами

---

## ИЗВЕСТНЫЕ ПРОБЛЕМЫ

### Проблема: Samsung устройства с Knox
**Симптомы:**
- Работает в эмуляторе
- НЕ работает на Samsung с Knox

**Решение:**
```xml
<!-- Добавьте в AndroidManifest.xml -->
<application
    android:networkSecurityConfig="@xml/network_security_config">
    
    <!-- Отключите Knox для отладки -->
    <meta-data
        android:name="com.samsung.android.knox.EXEMPT"
        android:value="true"/>
</application>
```

### Проблема: Устройства без Google Play Services
**Симптомы:**
- Китайские телефоны без GMS
- Huawei с HMS

**Решение:**
- Yandex Maps **работает без Google Play Services**
- Проверьте, что используется именно `yandex_maps_mapkit` v4.24.0+
- Убедитесь, что `play-services-location` установлен (для совместимости)

---

## СЛЕДУЮЩИЕ ШАГИ

1. ✅ **Запустите приложение** и откройте экран карты
2. ✅ **Подождите 3 секунды** и проверьте логи
3. ✅ **Запустите мониторинг**: `./check_yandex_maps_logs.sh`
4. ✅ **Проверьте интернет**: `adb shell ping maps.yandex.ru`
5. ✅ **Если проблема сохраняется**: сообщите мне результаты диагностики

---

**Дата создания:** 17 октября 2025  
**Версия MapKit:** 4.24.0-beta  
**Статус:** 🔍 В ПРОЦЕССЕ ДИАГНОСТИКИ
