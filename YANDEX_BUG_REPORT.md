# 🐛 БАГ РЕПОРТ: Yandex MapKit Suggest API

**Дата:** 21 октября 2025  
**Пакет:** `yandex_maps_mapkit` версия **4.25.0-beta**  
**Платформа:** Flutter (Android)

---

## 📋 ОПИСАНИЕ ПРОБЛЕМЫ

**Проблема:** Callbacks `onResponse` и `onError` в `SearchSuggestSessionSuggestListener` **НИКОГДА НЕ ВЫЗЫВАЮТСЯ**.

**Ожидаемое поведение:**
- При успешном запросе → вызывается `onResponse`
- При ошибке → вызывается `onError`

**Фактическое поведение:**
- Метод `suggest()` выполняется без exception
- Callbacks НЕ вызываются
- Приложение ждет вечно (timeout)

---

## 🔧 ВОСПРОИЗВЕДЕНИЕ

### 1. Версия пакета

```yaml
dependencies:
  yandex_maps_mapkit: ^4.8.1  # Установлена версия 4.25.0-beta
```

### 2. API ключ

```dart
await mapkit_init.initMapkit(
  apiKey: '2f1d6a75-b751-4077-b305-c6abaea0b542',
);
```

**Тип ключа:** Mobile SDK (iOS + Android)

### 3. Код инициализации

```dart
import 'package:yandex_maps_mapkit/search.dart';

class YandexMapsService {
  SearchManager? _searchManager;
  SearchSuggestSession? _suggestSession;

  Future<void> initialize() async {
    _searchManager = SearchFactory.instance.createSearchManager(
      SearchManagerType.Online,
    );
    
    _suggestSession = _searchManager!.createSuggestSession();
  }
}
```

**Результат:** ✅ Инициализация проходит успешно

---

### 4. Код вызова Suggest API

```dart
Future<List<String>> getSuggestions(String query) async {
  final completer = Completer<List<String>>();
  
  // Таймаут для отладки
  Timer(const Duration(seconds: 15), () {
    if (!completer.isCompleted) {
      print('⏱️ TIMEOUT! API не ответил за 15 секунд');
      completer.complete([]);
    }
  });

  // BoundingBox для всей России
  final boundingBox = BoundingBox(
    Point(latitude: 41.0, longitude: 19.0),   // Юго-запад
    Point(latitude: 82.0, longitude: 180.0),  // Северо-восток
  );

  // Опции
  final suggestOptions = SuggestOptions(
    suggestTypes: SuggestType(
      SuggestType.Geo.value | 
      SuggestType.Biz.value | 
      SuggestType.Transit.value,
    ),
    suggestWords: true,
    userPosition: null,
  );

  // Listener
  final listener = SearchSuggestSessionSuggestListener(
    onResponse: (response) {
      print('✅ ПОЛУЧЕН ОТВЕТ!'); // ❌ НИКОГДА НЕ ВЫЗЫВАЕТСЯ
      completer.complete(
        response.items.map((item) => item.displayText ?? item.title.text).toList()
      );
    },
    onError: (error) {
      print('❌ ОШИБКА: $error'); // ❌ НИКОГДА НЕ ВЫЗЫВАЕТСЯ
      completer.complete([]);
    },
  );

  // ВЫЗОВ API
  _suggestSession!.suggest(
    boundingBox,
    suggestOptions,
    listener,
    text: query,
  );

  return await completer.future;
}
```

**Результат:** ❌ Callbacks НЕ вызываются, всегда timeout

---

## 📊 ЛОГИ ПРИЛОЖЕНИЯ

### Инициализация (успешно)
```
I/flutter: 🗺️ [YANDEX MAPKIT] Инициализация...
I/flutter: ✅ [YANDEX MAPKIT] Инициализирован успешно
I/flutter: ✅ [YANDEX SUGGEST] SearchManager и SuggestSession созданы
```

### Запрос подсказок (timeout)
```
I/flutter: 💡 [YANDEX SUGGEST] Поиск подсказок для: "пермь"
I/flutter: 🌐 [YANDEX SUGGEST] Отправка запроса к API...
I/flutter: 🌐 [YANDEX SUGGEST] Параметры:
I/flutter:    - query: "пермь"
I/flutter:    - boundingBox: Вся Россия
I/flutter:    - suggestType: Geo + Biz + Transit
I/flutter: 🚀 [YANDEX SUGGEST] Вызов _suggestSession.suggest()...
I/flutter: ⏳ [YANDEX SUGGEST] Ожидание ответа API (timeout 15 сек)...
I/flutter: ⏱️ [YANDEX SUGGEST] TIMEOUT! API не ответил за 15 секунд
```

**НЕТ:**
- ✅ `onResponse` НЕ вызывается
- ❌ `onError` НЕ вызывается
- ⚠️ Exception НЕ выбрасывается

---

## 🔬 ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ

### Тестовые запросы
Проблема воспроизводится на **ВСЕХ** запросах:
- `"пе"` → timeout
- `"пер"` → timeout
- `"перм"` → timeout
- `"пермь"` → timeout
- `"ека"` → timeout
- `"Екатеринбург"` → timeout

### Устройство
```
Platform: Android (Эмулятор)
Device: sdk gphone16k arm64
Android API: 34
Flutter: Latest stable
Dart: Latest stable
```

### Сравнение с рабочим примером

Изучили официальный пример из репозитория:
```
mapkit-flutter-demo-master/mapkit-samples/map_search/
```

Используем **ИДЕНТИЧНЫЙ** код из примера:
```dart
_suggestSession.suggest(
  boundingBox,
  suggestOptions,
  listener,
  text: query,
);
```

**Но в нашем проекте не работает!** ❌

---

## ❓ ВОПРОСЫ К РАЗРАБОТЧИКАМ

### 1. Требуется ли дополнительная настройка?
- Нужны ли дополнительные разрешения в `AndroidManifest.xml`?
- Нужна ли активация Suggest API в личном кабинете?

### 2. Есть ли ограничения на beta версию?
- Версия `4.25.0-beta` - может баг в beta?
- Стоит ли попробовать стабильную версию?

### 3. Правильно ли мы используем API?
- Может неправильный `BoundingBox`?
- Может неправильные `SuggestOptions`?

### 4. Как включить debug логи MapKit?
- Есть ли способ увидеть нативные логи MapKit?
- Как узнать отправляется ли запрос на сервер?

---

## 🎯 ЧТО НАМ НУЖНО

**Нужна одна из опций:**

### Вариант 1: Исправление бага
Если это баг в пакете - когда ожидать фикс?

### Вариант 2: Правильное использование
Если мы неправильно используем API - покажите правильный пример для Flutter

### Вариант 3: Альтернативное решение
Если Suggest API не работает - как получить подсказки адресов другим способом?

---

## 📎 ФАЙЛЫ ПРОЕКТА

### pubspec.yaml
```yaml
dependencies:
  flutter:
    sdk: flutter
  yandex_maps_mapkit: ^4.8.1  # Установлена 4.25.0-beta
```

### Полный код сервиса
См. прикрепленный файл: `lib/services/yandex_maps_service.dart`

### Полные логи
См. прикрепленный файл: `yandex_api_test.log`

---

## 🚀 ОЖИДАЕМЫЙ РЕЗУЛЬТАТ

Хотим получить **онлайн подсказки адресов** для всей России:
- Все города
- Все улицы в городах
- Все номера домов

**Это возможно через Suggest API?**

---

## 📞 КОНТАКТЫ

**Проект:** TimeToTravel (Flutter приложение для такси)  
**Разработчик:** Кирилл Петров  

Готовы предоставить дополнительную информацию по запросу!

---

**Дата создания отчета:** 21 октября 2025  
**Версия пакета:** yandex_maps_mapkit 4.25.0-beta  
**Статус:** ⏳ Ожидаем ответа от разработчиков Яндекса
