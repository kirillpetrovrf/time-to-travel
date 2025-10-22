# 🚨 СРОЧНО: Проверка Suggest API Callback

## Что сделано:
✅ Добавлены диагностические логи в `yandex_maps_service.dart`
✅ Добавлен timeout на 10 секунд
✅ Добавлены логи для каждого этапа

## Что нужно сделать СЕЙЧАС:

### 1. Запустить приложение
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter run
```

### 2. Открыть экран "Индивидуальный трансфер"

### 3. Ввести в поле "Откуда": `Москва`

### 4. Смотреть логи в терминале

## Что должно появиться:

### Сценарий A: API работает ✅
```
💡 [YANDEX SUGGEST] Поиск подсказок для: "Моск"
🌐 [YANDEX SUGGEST] Отправка запроса к API...
⏳ [YANDEX SUGGEST] Ожидание ответа API (timeout 10 сек)...
✅ [YANDEX SUGGEST] CALLBACK onResponse вызван!
✅ [YANDEX SUGGEST] Получено элементов: 10
   📍 Title: "Москва", Subtitle: "Россия"
   📍 Title: "Москва", Subtitle: "Московская область"
📝 [YANDEX SUGGEST] Примеры подсказок:
   1. Москва, Россия
   2. Москва, Московская область
```

### Сценарий B: API возвращает ошибку ❌
```
💡 [YANDEX SUGGEST] Поиск подсказок для: "Моск"
🌐 [YANDEX SUGGEST] Отправка запроса к API...
⏳ [YANDEX SUGGEST] Ожидание ответа API (timeout 10 сек)...
❌ [YANDEX SUGGEST] CALLBACK onError вызван!
❌ [YANDEX SUGGEST] Ошибка: [описание ошибки]
```

### Сценарий C: API не отвечает ⏱️
```
💡 [YANDEX SUGGEST] Поиск подсказок для: "Моск"
🌐 [YANDEX SUGGEST] Отправка запроса к API...
⏳ [YANDEX SUGGEST] Ожидание ответа API (timeout 10 сек)...
⏱️ [YANDEX SUGGEST] Timeout! API не ответил за 10 секунд
```

## Если видите Сценарий B или C:

### Решение 1: Downgrade версии
```bash
# Откройте pubspec.yaml
# Замените:
yandex_maps_mapkit: ^4.8.1

# На:
yandex_maps_mapkit: 4.24.0

# Затем:
flutter clean
flutter pub get
flutter run
```

### Решение 2: Использовать локальную базу
```bash
# Откатиться на локальную базу адресов
# См. файл SUGGEST_API_CALLBACK_PROBLEM.md
```

## Альтернативный мониторинг

### Терминал 1: Запуск приложения
```bash
flutter run
```

### Терминал 2: Мониторинг Suggest API
```bash
./monitor_suggest_api.sh
```

---

**После проверки сообщите какой сценарий увидели!**
