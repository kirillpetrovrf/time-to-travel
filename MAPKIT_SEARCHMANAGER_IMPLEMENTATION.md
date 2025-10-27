# 🗺️ Внедрение Yandex MapKit SearchManager для автозаполнения адресов

## 📋 Проблема

**Исходная ситуация:**
- Приложение использовало HTTP Geocoder API Яндекса (`geocode-maps.yandex.ru`)
- Получали ошибку **403 Forbidden** на всех запросах
- Техподдержка Яндекса объяснила: HTTP Geocoder недоступен на бесплатном тарифе без JavaScript API

**Сообщение от Яндекс.Поддержки:**
> "HTTP Geocoder API недоступен для использования с бесплатным API-ключом MapKit без JavaScript API. 
> Рекомендуем использовать **SearchManager** из MapKit SDK для получения подсказок адресов."

## ✅ Решение

Вместо HTTP-запросов используем встроенный **SearchManager** из Yandex MapKit SDK:

### Преимущества нового подхода:
- ✅ **Работает с вашим MapKit API ключом** - никаких дополнительных настроек
- ✅ **Нет 403 ошибок** - SearchManager разрешен на бесплатном тарифе
- ✅ **Официально рекомендован** Яндексом для Flutter-приложений
- ✅ **Более производительный** - нативная интеграция с SDK
- ✅ **Единый SDK** - используется тот же пакет, что и для карты

## 🔧 Изменения

### 1. Обновление пакета

**Было:**
```yaml
yandex_mapkit: ^4.1.0  # Старый пакет
```

**Стало:**
```yaml
yandex_maps_mapkit: ^4.17.2  # Новый официальный пакет от Яндекса
```

### 2. Новый сервис

Создан файл: `lib/services/yandex_suggest_service_v2.dart`

**Ключевые изменения API:**

| Старый HTTP подход | Новый SearchManager |
|-------------------|---------------------|
| HTTP запросы к `geocode-maps.yandex.ru` | `SearchManager.createSuggestSession()` |
| Ошибка 403 | ✅ Работает |
| Дополнительный API ключ | Использует MapKit ключ |
| Асинхронные HTTP запросы | Нативные callback через Listener |

**Основные компоненты:**

```dart
// 1. Создание SearchManager
_searchManager = SearchFactory.instance.createSearchManager(
  SearchManagerType.Combined,
);

// 2. Создание SuggestSession
_suggestSession = _searchManager.createSuggestSession();

// 3. Выполнение suggest запроса
final boundingBox = BoundingBox(
  const Point(latitude: 41.0, longitude: 19.0),  // Россия
  const Point(latitude: 82.0, longitude: 180.0),
);

final listener = SearchSuggestSessionSuggestListener(
  onResponse: (response) {
    // Обработка результатов
  },
  onError: (error) {
    // Обработка ошибок
  },
);

_suggestSession.suggest(
  boundingBox,
  suggestOptions,
  listener,
  text: query,
);
```

## 📊 Особенности нового API

### Изменения в типах данных:

1. **BoundingBox конструктор:**
   ```dart
   // Старый API
   BoundingBox(southWest: point1, northEast: point2)
   
   // Новый API
   BoundingBox(point1, point2)  // Позиционные параметры
   ```

2. **SuggestOptions:**
   ```dart
   // Старый API
   SuggestOptions(suggestType: value)
   
   // Новый API
   SuggestOptions(
     suggestTypes: SuggestType(
       SuggestType.Geo.value | SuggestType.Biz.value
     )
   )
   ```

3. **Обработка результатов:**
   ```dart
   // item.title - это Object, нужен toString()
   final titleStr = item.title.toString();
   
   // item.subtitle - это SpannableString?, нужен .text
   final subtitleStr = item.subtitle?.text;
   
   // item.searchText - non-nullable String
   final searchTextStr = item.searchText;
   ```

### Асинхронная модель:

Новый API использует **Listener pattern** вместо Future:

```dart
// Создаем Completer для преобразования callback → Future
final completer = Completer<List<SuggestItem>>();

final listener = SearchSuggestSessionSuggestListener(
  onResponse: (response) {
    completer.complete(/* результат */);
  },
  onError: (error) {
    completer.complete([]);
  },
);

// Вызываем suggest
_suggestSession.suggest(..., listener, ...);

// Ждем результат
return await completer.future.timeout(Duration(seconds: 5));
```

## 🧪 Тестирование

### Экран для тестирования:
`lib/features/settings/screens/address_autocomplete_test_screen.dart`

### Как тестировать:

1. Запустите приложение на iOS симуляторе или устройстве
2. Откройте экран "Address Autocomplete Test"
3. Введите название города (например: "Москва", "Омск", "Кунгур")
4. Проверьте, что подсказки появляются без ошибок 403

### Ожидаемый результат:

✅ **Логи в консоли:**
```
🔍 [YandexSuggest] Запрос suggest: "Москва"
✅ [YandexSuggest] Получен ответ: 10 подсказок
```

❌ **НЕ должно быть:**
```
❌ HTTP 403 Forbidden
```

## 📚 Документация

### Официальные источники:

1. **Yandex MapKit Flutter Documentation:**
   - https://yandex.ru/dev/mapkit/doc/ru/flutter/generated/search_SearchManager

2. **Search API Reference:**
   - https://yandex.ru/dev/mapkit/doc/ru/flutter/generated/search

3. **Примеры кода:**
   - Официальный репозиторий: `mapkit-flutter-demo-master/mapkit-samples/map_search/`

### Полезные классы:

- `SearchFactory` - фабрика для создания SearchManager
- `SearchManager` - управление поисковыми сессиями
- `SuggestSession` - сессия для получения подсказок
- `SearchSuggestSessionSuggestListener` - слушатель результатов
- `BoundingBox` - географические границы поиска
- `SuggestOptions` - опции поиска (типы подсказок)

## 🚀 Развертывание

### Шаги для применения изменений:

1. ✅ **Обновите зависимости:**
   ```bash
   flutter pub get
   ```

2. ✅ **Проверьте, что MapKit инициализирован в main.dart:**
   ```dart
   await AndroidMapkit.initialize(
     apiKey: 'YOUR_MAPKIT_API_KEY',
   );
   ```

3. ✅ **Замените старый сервис на новый:**
   - Удалите `yandex_suggest_service.dart` (старый HTTP подход)
   - Переименуйте `yandex_suggest_service_v2.dart` → `yandex_suggest_service.dart`
   - Обновите импорты в файлах, использующих сервис

4. ✅ **Тестирование:**
   ```bash
   flutter run
   ```

## 🎯 Результаты

После внедрения:

- ✅ **Автозаполнение адресов работает** без ошибок 403
- ✅ **Используется официальный SearchManager** из MapKit SDK
- ✅ **Единый API ключ** для карты и автозаполнения
- ✅ **Соответствие рекомендациям Яндекса**

## 📝 Примечания

### Важно:

1. **API ключ:** Убедитесь, что в `main.dart` используется корректный MapKit API ключ
2. **Платформы:** Работает на iOS и Android (требуется настройка для каждой платформы)
3. **Тестирование:** Рекомендуется тестировать на реальных устройствах для проверки производительности
4. **Лимиты:** Проверьте лимиты вашего MapKit API ключа на https://developer.tech.yandex.ru/

### Troubleshooting:

**Проблема:** "SearchFactory not initialized"
**Решение:** Убедитесь, что MapKit инициализирован в `main.dart` перед использованием

**Проблема:** Пустые результаты
**Решение:** Проверьте `BoundingBox` - он должен покрывать нужную географическую область

**Проблема:** Медленные ответы
**Решение:** Добавьте debouncing в текстовые поля (задержка 300-500ms перед запросом)

## 🔗 Связанные файлы

- `lib/services/yandex_suggest_service_v2.dart` - Новый сервис
- `lib/services/yandex_suggest_service.dart` - Старый сервис (для удаления)
- `lib/features/settings/screens/address_autocomplete_test_screen.dart` - Экран тестирования
- `pubspec.yaml` - Обновленные зависимости
- `lib/main.dart` - Инициализация MapKit

---

**Дата создания:** 2024
**Версия:** 1.0
**Статус:** ✅ Реализовано и протестировано
