# 🔍 Анализ краша SearchSuggestSessionSuggestListener

**Дата:** 24 октября 2025 г.  
**Статус:** ❌ КРИТИЧЕСКАЯ ПРОБЛЕМА - Listener вызывает segfault

## 🚨 Суть проблемы

При попытке создать `SearchSuggestSessionSuggestListener` в вашем проекте происходит **нативный краш** (SIGSEGV) в библиотеке `libmaps-mobile.so`.

```
F/libc: Fatal signal 11 (SIGSEGV), code -6 (SI_TKILL)
backtrace:
  #06 pc yandex_flutter_search_SuggestSession_SearchSuggestSessionSuggestListener_new+28
```

## 📋 Что было сделано

### Попытка 1: Создание listener как локальной переменной
```dart
final listener = SearchSuggestSessionSuggestListener(...);
```
**Результат:** ❌ КРАШ

### Попытка 2: Создание listener как `late final` поля класса в методе `initialize()`
```dart
class YandexSuggestService {
  late final SearchSuggestSessionSuggestListener _suggestListener;
  
  void initialize() {
    _suggestListener = SearchSuggestSessionSuggestListener(...); // КРАШ
  }
}
```
**Результат:** ❌ КРАШ

### Попытка 3: Создание listener на уровне объявления поля (как в примере Яндекса)
```dart
class YandexSuggestService {
  late final _suggestListener = SearchSuggestSessionSuggestListener(
    onResponse: _onSuggestResponse,
    onError: _onSuggestError,
  ); // КРАШ
}
```
**Результат:** ❌ КРАШ

### Попытка 4: Использование `final` вместо `late final` для `_searchManager`
```dart
class YandexSuggestService {
  final _searchManager = SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
  late final _suggestSession = _searchManager.createSuggestSession();
  late final _suggestListener = SearchSuggestSessionSuggestListener(...); // КРАШ
}
```
**Результат:** ❌ КРАШ

## 🔬 Технические детали

### Stacktrace краша
```
#00 pc 0000000000000000  <unknown>
#01 pc 0000000000f76118  libmaps-mobile.so (BuildId: 0974c7c9930295e1)
#02 pc 00000000010c3518  libmaps-mobile.so
#03 pc 0000000001a88b28  libmaps-mobile.so
#04 pc 0000000001a88ac4  libmaps-mobile.so
#05 pc 0000000001a882e8  libmaps-mobile.so
#06 pc 0000000001a8828c  libmaps-mobile.so (yandex_flutter_search_SuggestSession_SearchSuggestSessionSuggestListener_new+28)
#07 pc 0000000000058e90  [anon:dart-code]
```

### Версии
- `yandex_maps_mapkit: ^4.17.2` (в вашем проекте)
- API ключ: `2f1d6a75-b751-4077-b305-c6abaea0b542`
- MapKit инициализирован в `MainApplication.kt` через `MapKitFactory.initialize(this)`

### Логи перед крашем
```
I/flutter: ✅ [Step 1.4] SuggestSession создан успешно
I/flutter: 🔵 [Step 1.5] Listener уже создан на уровне класса
F/libc: Fatal signal 11 (SIGSEGV)  <-- КРАШ ЗДЕСЬ
```

## 🎯 Текущая стратегия

### Запускаем оригинальный пример Яндекса

Чтобы исключить проблему в вашем коде, мы:

1. ✅ Взяли оригинальный пример из `mapkit-flutter-demo-master/mapkit-samples/map_search`
2. ✅ Добавили ваш API ключ: `2f1d6a75-b751-4077-b305-c6abaea0b542`
3. ✅ Обновили версию Gradle с 8.1.0 до 8.7.3
4. 🔄 Запускаем на том же устройстве (`sdk gphone16k arm64`)

**Цель:** Проверить, работает ли `SearchSuggestSessionSuggestListener` в чистом примере Яндекса.

### Возможные исходы

#### Вариант A: Пример Яндекса работает ✅
**Выводы:**
- Проблема в вашем коде/конфигурации проекта
- Нужно искать различия между примером и вашим проектом

**Действия:**
- Сравнить конфигурацию Gradle
- Сравнить способ инициализации MapKit
- Проверить версии зависимостей
- Скопировать рабочий код из примера

#### Вариант B: Пример Яндекса тоже крашится ❌
**Выводы:**
- Проблема в SDK `yandex_maps_mapkit: ^4.17.2`
- Возможно, баг в нативной библиотеке `libmaps-mobile.so`
- Проблема может быть специфична для эмулятора `sdk gphone16k arm64`

**Действия:**
1. Попробовать на реальном устройстве
2. Попробовать другую версию SDK (например, `^4.16.0`)
3. Написать багрепорт в Яндекс с stacktrace
4. Использовать альтернативный подход (HTTP Geocoder API)

## 🚀 Следующие шаги

### Немедленно
- [x] Запустить пример Яндекса с вашим API ключом
- [ ] Дождаться сборки Gradle и запуска приложения
- [ ] Протестировать автозаполнение в примере
- [ ] Записать результат (работает/крашится)

### Если пример работает
- [ ] Скопировать точную структуру кода из примера
- [ ] Создать минимальный тестовый экран в вашем проекте
- [ ] Постепенно добавлять функциональность

### Если пример крашится
- [ ] Попробовать на реальном устройстве
- [ ] Откатиться на `yandex_maps_mapkit: ^4.16.0`
- [ ] Написать багрепорт в Яндекс
- [ ] Рассмотреть альтернативные решения

## 📊 Сравнение: Ваш код vs Пример Яндекса

| Аспект | Ваш проект | Пример Яндекса |
|--------|-----------|----------------|
| Инициализация MapKit | `MainApplication.kt` | `main.dart` через `init.initMapkit()` |
| Метод | `MapKitFactory.initialize(this)` | `await init.initMapkit(apiKey: "...")` |
| Создание SearchManager | `late final` / `final` | `final` (инициализация сразу) |
| Создание SuggestSession | `late final` | `late final` |
| Создание Listener | `late final` | `late final` |
| Версия SDK | `^4.17.2` | Вероятно та же |
| Gradle версия | 8.7.3 | 8.1.0 → 8.7.3 (обновили) |

## 💡 Гипотезы

### Гипотеза 1: Разница в способе инициализации MapKit
**Вероятность:** 🟡 Средняя

В вашем проекте MapKit инициализируется в `MainApplication.kt` (Android-специфично), а в примере Яндекса через `init.initMapkit()` в `main.dart` (кросс-платформенно).

**Тест:** Запустить пример Яндекса покажет, имеет ли это значение.

### Гипотеза 2: Баг в SDK версии 4.17.2
**Вероятность:** 🟠 Низкая

Если даже пример Яндекса крашится, это может быть баг в нативной части SDK.

**Тест:** Запустить пример Яндекса + попробовать другую версию SDK.

### Гипотеза 3: Проблема специфична для эмулятора
**Вероятность:** 🟢 Высокая

`sdk gphone16k arm64` - это эмулятор. Возможно, проблема связана с архитектурой ARM64 эмулятора или с версией Android (16).

**Тест:** Запустить на реальном устройстве.

### Гипотеза 4: Конфликт зависимостей
**Вероятность:** 🟡 Средняя

В вашем проекте много других зависимостей (Firebase, Geolocator, и т.д.), которые могут конфликтовать с MapKit.

**Тест:** Запустить минимальный проект только с MapKit.

## 📝 Логи для Яндекса (если будет багрепорт)

```
**Устройство:** Android Emulator sdk gphone16k arm64
**OS:** Android 16 (API level 35)
**Flutter:** (ваша версия)
**SDK:** yandex_maps_mapkit: ^4.17.2
**API Key:** 2f1d6a75-b751-4077-b305-c6abaea0b542

**Crash:**
```
F/libc: Fatal signal 11 (SIGSEGV), code -6 (SI_TKILL) in tid 24579
backtrace:
  #06 pc 0000000001a8828c libmaps-mobile.so (yandex_flutter_search_SuggestSession_SearchSuggestSessionSuggestListener_new+28)
```

**Код:**
```dart
late final _suggestListener = SearchSuggestSessionSuggestListener(
  onResponse: (response) { ... },
  onError: (error) { ... },
); // <-- CRASH HERE
```

**Инициализация:**
```kotlin
// MainApplication.kt
class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("2f1d6a75-b751-4077-b305-c6abaea0b542")
        MapKitFactory.initialize(this)
    }
}
```
```

---

**Обновляется по мере получения новых данных...**
