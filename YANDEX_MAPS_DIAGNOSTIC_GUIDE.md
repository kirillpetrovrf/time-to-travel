# 🔍 ИНСТРУКЦИЯ: МОНИТОРИНГ YANDEX MAPS TILES (ДИАГНОСТИКА)

## Дата: 17 октября 2025

---

## 📋 ЧТО СДЕЛАНО

### ✅ Исправлены ошибки компиляции
- Убраны несуществующие методы/свойства Yandex MapKit API
- Приложение успешно запускается

### ✅ Добавлено детальное логирование карты
**Файл:** `lib/features/booking/screens/custom_route_with_map_screen.dart`

**Новые логи:**
```dart
🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========
🗺️ [MAP] MapWindow создан: true/false
🗺️ [MAP] Map объект: true/false
🗺️ [MAP] ✅ Map объект доступен
🗺️ [MAP] Перемещаем камеру на: Point(...)
🗺️ [MAP] ✅ Камера перемещена
🗺️ [MAP] 🔍 ДИАГНОСТИКА КАРТЫ:
🗺️ [MAP] 🔍 MapType: ...
🗺️ [MAP] 🔍 Камера: ...
🗺️ [MAP] 🔍 Видимая область: ...
🗺️ [MAP] ⚠️ ВНИМАНИЕ: Если тайлы не загружаются:
🗺️ [MAP] ⚠️ 1. Проверьте интернет-соединение
🗺️ [MAP] ⚠️ 2. Проверьте API-ключ Yandex Maps
🗺️ [MAP] ⚠️ 3. Проверьте сетевые разрешения Android
🗺️ [MAP] ⚠️ 4. Поищите в логах "No available cache for request"
🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========
```

### ✅ Добавлены разрешения Android
**Файл:** `android/app/src/main/AndroidManifest.xml`

**Новые разрешения:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### ✅ Создан скрипт мониторинга логов
**Файл:** `check_yandex_maps_logs.sh`

Скрипт автоматически фильтрует и подсвечивает:
- ❌ Ошибки кеша тайлов
- ❌ HTTP ошибки
- ⚠️ SSL предупреждения
- 🌐 Сетевые ошибки
- 🗺️ Логи карты
- ✅ Успешные события

---

## 🎯 КАК ИСПОЛЬЗОВАТЬ

### 1️⃣ Запустите приложение на устройстве
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter run
```

### 2️⃣ В НОВОМ терминале запустите мониторинг логов
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
chmod +x check_yandex_maps_logs.sh
./check_yandex_maps_logs.sh
```

### 3️⃣ Откройте экран с картой в приложении
- Перейдите в раздел "Бронирование"
- Нажмите "Индивидуальный трансфер"
- Откройте экран с картой

### 4️⃣ Наблюдайте за логами в терминале
Скрипт будет автоматически показывать:
- ✅ Успешные события (зеленым)
- ⚠️ Предупреждения (желтым)
- ❌ Ошибки (красным)

---

## 🔍 ЧТО ИСКАТЬ В ЛОГАХ

### ❌ КРИТИЧЕСКАЯ ОШИБКА (тайлы не загружаются):
```
W/yandex.maps: poxHcJDuv2tO5gpI+pN3: No available cache for request
```

**Если видите эту ошибку:**
1. Проверьте интернет-соединение на устройстве
2. Убедитесь, что API-ключ Yandex Maps корректен
3. Проверьте, что `network_security_config.xml` корректно настроен
4. Убедитесь, что в `AndroidManifest.xml` есть `android:usesCleartextTraffic="true"`

### ✅ УСПЕШНАЯ ИНИЦИАЛИЗАЦИЯ КАРТЫ:
```
I/flutter: 🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========
I/flutter: 🗺️ [MAP] MapWindow создан: true
I/flutter: 🗺️ [MAP] Map объект: true
I/flutter: 🗺️ [MAP] ✅ Map объект доступен
I/flutter: 🗺️ [MAP] ✅ Камера перемещена
I/flutter: 🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========
```

### 🔍 ДИАГНОСТИЧЕСКАЯ ИНФОРМАЦИЯ:
```
I/flutter: 🗺️ [MAP] 🔍 ДИАГНОСТИКА КАРТЫ:
I/flutter: 🗺️ [MAP] 🔍 MapType: MapType.vectorMap
I/flutter: 🗺️ [MAP] 🔍 Камера: CameraPosition(...)
I/flutter: 🗺️ [MAP] 🔍 Видимая область: VisibleRegion(...)
```

---

## 🛠️ ВОЗМОЖНЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ

### Проблема 1: "No available cache for request"
**Причина:** Yandex MapKit не может загрузить тайлы карты

**Решения:**
1. Проверьте интернет-соединение:
   ```bash
   adb shell ping -c 3 maps.yandex.ru
   ```

2. Проверьте API-ключ в `lib/config/map_config.dart`:
   ```dart
   static const String yandexMapKitApiKey = '2f1d6a75-b751-4077-b305-c6abaea0b542';
   ```

3. Убедитесь, что `network_security_config.xml` корректен

4. Проверьте `AndroidManifest.xml`:
   ```xml
   android:usesCleartextTraffic="true"
   android:networkSecurityConfig="@xml/network_security_config"
   ```

### Проблема 2: Карта показывает только сетку
**Причина:** Тайлы не загружаются из-за сетевых ограничений

**Решения:**
1. Проверьте разрешения в `AndroidManifest.xml`
2. Убедитесь, что устройство подключено к интернету
3. Попробуйте переключиться между Wi-Fi и мобильным интернетом
4. Очистите кеш приложения:
   ```bash
   flutter clean
   flutter run
   ```

### Проблема 3: Геолокация не работает
**Причина:** Отсутствуют разрешения на геолокацию

**Решение:**
Убедитесь, что в `AndroidManifest.xml` есть:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

## 📝 КОНТРОЛЬНЫЙ ЧЕКЛИСТ

### Перед тестированием:
- [ ] Приложение собрано и установлено на устройстве
- [ ] Устройство подключено к интернету (Wi-Fi или мобильный)
- [ ] Скрипт мониторинга логов запущен в отдельном терминале
- [ ] Экран с картой открыт

### Проверяем логи:
- [ ] Видите "✅ Yandex MapKit успешно инициализирован"
- [ ] Видите "🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ =========="
- [ ] Видите "🗺️ [MAP] ✅ КАРТА ГОТОВА К РАБОТЕ"
- [ ] **НЕ** видите "No available cache for request"
- [ ] **НЕ** видите HTTP ошибок

### Проверяем визуально:
- [ ] Карта показывает тайлы (изображения), а не только сетку
- [ ] Карта позиционирована на Перми (координаты 58.0105, 56.2502)
- [ ] Можно двигать карту пальцами
- [ ] Можно зумить карту (pinch gesture)

---

## 📞 СЛЕДУЮЩИЕ ШАГИ

### Если тайлы НЕ загружаются:
1. Сделайте скриншот логов с ошибкой "No available cache for request"
2. Проверьте интернет-соединение на устройстве
3. Попробуйте запросить геолокацию явно
4. Отправьте мне полные логи для анализа

### Если тайлы загружаются успешно:
1. Протестируйте все функции карты:
   - Перемещение
   - Зум
   - Расчёт маршрута
2. Отметьте проблему как решённую
3. Переходите к дальнейшей разработке

---

## 📚 ПОЛЕЗНЫЕ КОМАНДЫ

### Просмотр логов в реальном времени:
```bash
# Все логи Flutter
adb logcat -v time | grep "I/flutter"

# Только логи Yandex Maps
adb logcat -v time | grep "yandex.maps"

# Только ошибки
adb logcat -v time | grep -E "ERROR|FATAL"
```

### Очистка логов:
```bash
adb logcat -c
```

### Проверка интернет-соединения:
```bash
adb shell ping -c 5 maps.yandex.ru
```

### Перезапуск приложения:
```bash
flutter clean
flutter run
```

---

**Удачного тестирования! 🚀**
