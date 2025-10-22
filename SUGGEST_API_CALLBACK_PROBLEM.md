# 🐛 Yandex Suggest API - Проблема: Callback не вызывается

**Дата:** 21 октября 2025  
**Статус:** 🔴 ПРОБЛЕМА ОБНАРУЖЕНА

---

## 🔍 Диагноз

### Что работает ✅
- MapKit инициализируется: `✅ [YANDEX MAPKIT] Инициализирован успешно`
- SuggestSession создается: `✅ [YANDEX SUGGEST] SuggestSession создана`
- Метод `getSuggestions()` вызывается: `💡 [YANDEX SUGGEST] Поиск подсказок для: "пермь"`

### Что НЕ работает ❌
- **Callback `onResponse` НЕ вызывается**
- **Callback `onError` НЕ вызывается**
- **Нет логов от API** (ни ответа, ни ошибки)

### Анализ логов

```
I/flutter: 💡 [YANDEX SUGGEST] Поиск подсказок для: "пе"
I/flutter: 💡 [YANDEX SUGGEST] Поиск подсказок для: "пер"
I/flutter: 💡 [YANDEX SUGGEST] Поиск подсказок для: "перм"
I/flutter: 💡 [YANDEX SUGGEST] Поиск подсказок для: "пермь"
```

**Отсутствуют:**
- `✅ [YANDEX SUGGEST] CALLBACK onResponse вызван!`
- `❌ [YANDEX SUGGEST] CALLBACK onError вызван!`
- `⏱️ [YANDEX SUGGEST] Timeout!`

---

## 🎯 Возможные причины

### 1. Проблема с API версией 4.25.0-beta
**Вероятность: 🔴 ВЫСОКАЯ**

Beta версия может иметь баги:
- Callback не регистрируется правильно
- API изменился и документация устарела
- Thread/isolate проблемы

### 2. Неправильный порядок параметров
**Вероятность: 🟡 СРЕДНЯЯ**

Возможно параметры метода `suggest()` в неправильном порядке:
```dart
_suggestSession!.suggest(
  boundingBox,        // ❓ Правильный ли порядок?
  suggestOptions,
  listener,
  text: query,
);
```

### 3. Проблема с инициализацией MapKit
**Вероятность: 🟢 НИЗКАЯ**

Может быть SearchManager нужно создавать по-другому.

### 4. Требуется нативная инициализация
**Вероятность: 🟡 СРЕДНЯЯ**

Возможно для SearchManager нужна дополнительная инициализация в нативном коде Android/iOS.

---

## 🔧 План действий

### Шаг 1: Проверить сигнатуру метода suggest()
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
cat ~/.pub-cache/hosted/pub.dev/yandex_maps_mapkit-4.25.0-beta/lib/src/search/suggest_session.dart | grep -A 10 "void suggest"
```

### Шаг 2: Добавить диагностические логи
✅ **УЖЕ СДЕЛАНО** - добавлены дополнительные логи в код

### Шаг 3: Тестировать с новыми логами
```bash
flutter run
# Ввести текст в поле адреса
# Проверить появление новых логов
```

### Шаг 4: Попробовать альтернативный подход
Если callback не работает, попробовать:
- Использовать другую версию пакета (4.24.0 вместо 4.25.0-beta)
- Использовать Search API вместо Suggest
- Откатиться на HTTP Geocoder (но с другим API ключом)

---

## 📋 Что проверить СЕЙЧАС

### 1. Запустить с новыми логами
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter run
```

### 2. Ввести текст в поле "Откуда"
Например: `Москва`

### 3. Смотреть логи
Должны появиться новые логи:
```
🌐 [YANDEX SUGGEST] Отправка запроса к API...
⏳ [YANDEX SUGGEST] Ожидание ответа API (timeout 10 сек)...
```

**Потом ЛИБО:**
```
✅ [YANDEX SUGGEST] CALLBACK onResponse вызван!
✅ [YANDEX SUGGEST] Получено элементов: X
```

**ЛИБО:**
```
❌ [YANDEX SUGGEST] CALLBACK onError вызван!
```

**ЛИБО:**
```
⏱️ [YANDEX SUGGEST] Timeout! API не ответил за 10 секунд
```

### 4. Использовать скрипт мониторинга
```bash
./monitor_suggest_api.sh
```

---

## 🔍 Альтернативные решения

### Вариант A: Downgrade на стабильную версию
```yaml
# pubspec.yaml
yandex_maps_mapkit: 4.24.0  # Без -beta
```

### Вариант B: Использовать Search вместо Suggest
```dart
// Вместо SuggestSession использовать SearchSession
final searchSession = _searchManager!.submit(
  Geometry.fromPoint(Point(latitude: 58.0, longitude: 56.3)),
  SearchOptions(...),
  SearchSessionSearchListener(...),
  text: query,
);
```

### Вариант C: HTTP Geocoder с правильным ключом
1. Получить отдельный API ключ для HTTP Geocoder
2. Использовать REST API напрямую
3. Вернуться к старой реализации (но с новым ключом)

---

## 📊 Следующие шаги

1. ✅ **Добавлены диагностические логи**
2. ⏳ **Тестирование с новыми логами** ← **ВЫ ЗДЕСЬ**
3. ⏳ Анализ результатов
4. ⏳ Выбор решения
5. ⏳ Реализация исправления

---

## 🆘 Если проблема не решится

### Быстрое решение: Локальная база + Firebase
```dart
// Временно вернуться на локальную базу адресов
// + Добавить возможность загружать базу из Firebase

// lib/services/address_database_service.dart
class AddressDatabaseService {
  List<String> _addresses = [
    'Москва, Россия',
    'Санкт-Петербург, Россия',
    // ... 1000+ адресов
  ];
  
  Future<void> loadFromFirebase() async {
    // Загрузить базу из Firebase Storage
  }
  
  List<String> search(String query) {
    // Поиск по локальной базе
  }
}
```

**Преимущества:**
- ✅ Работает offline
- ✅ Быстрый отклик
- ✅ Не зависит от Yandex API
- ✅ Можно обновлять базу через Firebase

**Недостатки:**
- ❌ Ограниченное количество адресов
- ❌ Нужно поддерживать базу вручную

---

**СЛЕДУЮЩИЙ ШАГ:** Запустить `flutter run` и проверить новые логи
