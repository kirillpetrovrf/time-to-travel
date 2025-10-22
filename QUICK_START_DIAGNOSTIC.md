# 🚀 БЫСТРЫЙ СТАРТ: ДИАГНОСТИКА YANDEX MAPS

## 1️⃣ Запустите приложение
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter run
```

## 2️⃣ В НОВОМ терминале запустите мониторинг
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
chmod +x check_yandex_maps_logs.sh
./check_yandex_maps_logs.sh
```

## 3️⃣ Откройте экран с картой
- Перейдите в "Бронирование" → "Индивидуальный трансфер"

## 4️⃣ Смотрите логи

### ✅ ХОРОШО (тайлы загружаются):
```
✅ Yandex MapKit успешно инициализирован
🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========
```

### ❌ ПЛОХО (тайлы НЕ загружаются):
```
W/yandex.maps: No available cache for request
```

---

## 🔍 ЧТО ПРОВЕРИТЬ ЕСЛИ ТАЙЛЫ НЕ ЗАГРУЖАЮТСЯ

1. **Интернет на устройстве:**
   ```bash
   adb shell ping -c 3 maps.yandex.ru
   ```

2. **API-ключ:** `lib/config/map_config.dart`
   ```dart
   static const String yandexMapKitApiKey = '2f1d6a75-b751-4077-b305-c6abaea0b542';
   ```

3. **network_security_config.xml:** `android/app/src/main/res/xml/network_security_config.xml`

4. **AndroidManifest.xml:** `android/app/src/main/AndroidManifest.xml`
   ```xml
   android:usesCleartextTraffic="true"
   android:networkSecurityConfig="@xml/network_security_config"
   ```

---

## 📝 ОТПРАВЬТЕ МНЕ

Если проблема не решена, отправьте:
1. Скриншот экрана с картой (сетка без тайлов)
2. Логи с ошибкой "No available cache for request"
3. Результат команды `adb shell ping maps.yandex.ru`

---

📖 **Подробная инструкция:** `YANDEX_MAPS_DIAGNOSTIC_GUIDE.md`
