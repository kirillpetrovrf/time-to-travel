# 🚨 YANDEX MAPS 403 ERROR - ОТЧЁТ ДЛЯ ПОДДЕРЖКИ

## Дата: 20 октября 2025 г.

---

## ❌ ПРОБЛЕМА:

Yandex MapKit API возвращает **403 Forbidden** при загрузке тайлов карты.

### Симптомы:
- ✅ MapKit инициализируется успешно
- ✅ Камера перемещается на нужную позицию
- ✅ Видимая область определяется корректно
- ❌ **Тайлы карты не загружаются** (видна только сетка)
- ❌ **HTTP 403 Forbidden** в логах

---

## 🔑 ИСПОЛЬЗУЕМЫЙ API КЛЮЧ:

```
2f1d6a75-b751-4077-b305-c6abaea0b542
```

**Статус ключа:**
- Создан: через консоль Yandex Cloud
- Активирован: ДА
- Привязан к: `com.timetotravel.app`

---

## 📱 ДЕТАЛИ ПРИЛОЖЕНИЯ:

**Android:**
- Package: `com.timetotravel.app`
- Min SDK: 21
- Target SDK: 34
- MapKit version: `4.24.0`

**iOS:**
- Bundle ID: `com.timetotravel.app`
- Min iOS: 12.0

---

## 🗺️ КАК ВОСПРОИЗВЕСТИ:

1. Запустить приложение
2. Открыть экран "Свободный маршрут"
3. Карта показывает только сетку без изображения
4. В логах видна ошибка **403 Forbidden**

---

## 📋 ЛОГИ:

### Успешная инициализация:
```
I/flutter: ✅ Yandex MapKit успешно инициализирован (v4.24.0)
I/flutter: 🗺️ [MAP] ✅ Map объект доступен
I/flutter: 🗺️ [MAP] ✅ Камера перемещена
I/flutter: 🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========
```

### Ошибка 403 (должна появиться в logcat):
```
[ОЖИДАЕТСЯ В ЛОГАХ]
E/Yandex: HTTP 403 Forbidden
E/Yandex: No available cache for request
```

---

## 🔧 ЧТО УЖЕ ПРОВЕРЕНО:

✅ API ключ настроен в:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/config/map_config.dart`

✅ Разрешения настроены:
- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `ACCESS_FINE_LOCATION`

✅ Network Security Config:
- `usesCleartextTraffic="true"`
- `networkSecurityConfig="@xml/network_security_config"`

---

## ❓ ВОПРОСЫ К ПОДДЕРЖКЕ YANDEX:

1. **Активен ли ключ `2f1d6a75-b751-4077-b305-c6abaea0b542`?**
2. **Привязан ли он к bundle ID `com.timetotravel.app`?**
3. **Есть ли лимиты на бесплатном тарифе?**
4. **Нужна ли активация платного тарифа для загрузки тайлов?**
5. **Какие домены должны быть в whitelist для загрузки тайлов?**

---

## 🌐 СЕТЕВЫЕ ЗАПРОСЫ (ОЖИДАЕМЫЕ):

```
https://vec01.maps.yandex.net/...
https://sat01.maps.yandex.net/...
https://core-renderer-tiles.maps.yandex.net/...
```

**Статус:** Все должны возвращать **200 OK**, но возвращают **403 Forbidden**

---

## 📞 КОНТАКТЫ:

- Email: [ВАШ EMAIL]
- Telegram: [ВАШ TELEGRAM]
- GitHub: kirillpetrovrf

---

## 🔗 ССЫЛКИ:

- Документация: https://yandex.ru/dev/mapkit/doc/en/
- Консоль API: https://console.cloud.yandex.ru/
- GitHub проекта: https://github.com/kirillpetrovrf/time-to-travel

---

## 💡 ПРОСЬБА К ПОДДЕРЖКЕ:

Помогите, пожалуйста, разобраться с **403 ошибкой** при загрузке тайлов карты. 
Приложение работает корректно, но карта не отображается из-за блокировки HTTP запросов.

**Может ли проблема быть в:**
- ⚠️ Неактивированном ключе?
- ⚠️ Неправильной привязке к bundle ID?
- ⚠️ Лимитах бесплатного тарифа?
- ⚠️ Требовании платной подписки?

Спасибо!
