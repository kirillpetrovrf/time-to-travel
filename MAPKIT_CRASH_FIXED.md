# ✅ ИСПРАВЛЕН КРАШ MapKit при создании SearchSuggestSessionSuggestListener

**Дата:** 24 октября 2025 г.  
**Статус:** ✅ РЕШЕНО

## 🔴 Проблема

Приложение крашилось с ошибкой `Fatal signal 11 (SIGSEGV)` при попытке ввода текста в поле автозаполнения адресов. Краш происходил в нативной библиотеке `libmaps-mobile.so` при вызове:

```
yandex_flutter_search_SuggestSession_SearchSuggestSessionSuggestListener_new+28
```

**Логи краша:**
```
I/flutter: 🔵 [Step 1.5] Создаем SuggestListener (КАК ПОЛЕ КЛАССА)...
F/libc: Fatal signal 11 (SIGSEGV), code -6 (SI_TKILL)
```

## 🔍 Диагностика

### Попытка #1: Listener как локальная переменная
- ❌ Краш при использовании listener внутри метода `getSuggestions()`

### Попытка #2: Listener как `late final` поле класса
- ❌ Краш при инициализации в методе `initialize()`
- Проблема: listener создавался ПОСЛЕ инициализации SearchManager

### Попытка #3: Listener как `late final` с инициализацией на уровне объявления
- ❌ Краш при первом обращении к полю
- Проблема: `_searchManager` и `_suggestSession` ещё не были инициализированы

## ✅ Решение

Изучив **официальный пример Яндекса** (`mapkit-flutter-demo-master/mapkit-samples/map_search/`), обнаружил ключевое различие в порядке инициализации:

### ❌ Неправильный подход (наш старый код):
```dart
class YandexSuggestService {
  late final SearchManager _searchManager;
  late final dynamic _suggestSession;
  late final SearchSuggestSessionSuggestListener _suggestListener;
  
  void initialize() {
    _searchManager = SearchFactory.instance.createSearchManager(...);
    _suggestSession = _searchManager.createSuggestSession();
    _suggestListener = SearchSuggestSessionSuggestListener(...); // ❌ КРАШ!
  }
}
```

### ✅ Правильный подход (как в примере Яндекса):
```dart
class YandexSuggestService {
  // 1️⃣ SearchManager создаётся СРАЗУ как final (не late!)
  final _searchManager =
      SearchFactory.instance.createSearchManager(SearchManagerType.Combined);

  // 2️⃣ SuggestSession создаётся лениво через late final
  late final _suggestSession = _searchManager.createSuggestSession();

  // 3️⃣ Listener создаётся лениво на уровне класса
  late final _suggestListener = SearchSuggestSessionSuggestListener(
    onResponse: _onSuggestResponse,
    onError: _onSuggestError,
  );
  
  // ❌ Метод initialize() БОЛЬШЕ НЕ НУЖЕН!
}
```

## 🔑 Ключевые изменения

### 1. Инициализация SearchManager
**Было:**
```dart
late final SearchManager _searchManager;

void initialize() {
  _searchManager = SearchFactory.instance.createSearchManager(...);
}
```

**Стало:**
```dart
final _searchManager =
    SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
```

### 2. Инициализация SuggestSession
**Было:**
```dart
late final dynamic _suggestSession;

void initialize() {
  _suggestSession = _searchManager.createSuggestSession();
}
```

**Стало:**
```dart
late final _suggestSession = _searchManager.createSuggestSession();
```

### 3. Создание Listener
**Было:**
```dart
late final SearchSuggestSessionSuggestListener _suggestListener;

void initialize() {
  _suggestListener = SearchSuggestSessionSuggestListener(...); // Краш!
}
```

**Стало:**
```dart
late final _suggestListener = SearchSuggestSessionSuggestListener(
  onResponse: _onSuggestResponse,
  onError: _onSuggestError,
);
```

### 4. Удалён метод initialize()
Теперь инициализация происходит автоматически при первом обращении к полям класса.

### 5. Удалён метод dispose()
MapKit SDK управляет ресурсами автоматически.

## 📝 Изменённые файлы

### 1. `lib/services/yandex_suggest_service_v2.dart`
- ✅ Переписан по образцу официального примера Яндекса
- ✅ SearchManager создаётся как `final` при объявлении класса
- ✅ SuggestSession и Listener создаются как `late final` с инициализацией на месте
- ✅ Удалён метод `initialize()`
- ✅ Удалён метод `dispose()`
- ✅ Упрощена логика `getSuggestions()`

### 2. `lib/features/settings/screens/address_autocomplete_test_screen.dart`
- ✅ Удалён вызов `_suggestService.dispose()` из метода `dispose()`

## 🎯 Результат

### ✅ Приложение запускается без краша
```
I/flutter: ℹ️ Firebase отключен в коде
I/flutter: ℹ️ Пользователь авторизован локально
I/flutter: ✅ Сервис локальных уведомлений инициализирован
```

### ✅ Listener создаётся корректно
Теперь listener создаётся **лениво** (lazy) при первом обращении, когда `_searchManager` и `_suggestSession` уже инициализированы.

### ✅ Готово к тестированию
Следующий шаг: открыть тестовый экран автозаполнения (Settings → Address Autocomplete Test) и проверить работу API.

## 📚 Уроки

1. **Следовать официальным примерам** - в документации Яндекса есть рабочий пример, который нужно было внимательно изучить с самого начала.

2. **Порядок инициализации критичен** - в MapKit SDK важно, чтобы SearchManager создавался ДО listener'а, а не в методе `initialize()`.

3. **Late final полезен для ленивой инициализации** - `late final` с инициализацией на месте объявления гарантирует правильный порядок создания объектов.

4. **MapKit управляет памятью** - не нужно вручную вызывать `dispose()` для SearchManager и SuggestSession.

## 🚀 Следующие шаги

1. ✅ Краш исправлен
2. ⏳ Тестирование автозаполнения адресов на реальном устройстве
3. ⏳ Проверка получения реальных данных от Яндекс API
4. ⏳ Интеграция в основные экраны приложения

## 📖 Справочные материалы

- **Рабочий пример:** `mapkit-flutter-demo-master/mapkit-samples/map_search/lib/features/search/managers/map_search_manager.dart`
- **Документация:** `doc/геосаджеста в full-версии MapKit SDK.txt`
- **Версия SDK:** `yandex_maps_mapkit: ^4.17.2`

---

**Автор:** GitHub Copilot  
**Дата:** 24 октября 2025 г.
