# Исправление краша SearchSuggestSessionSuggestListener

## Проблема
При попытке создать `SearchSuggestSessionSuggestListener` в методе `initialize()` происходил нативный краш:
```
Fatal signal 11 (SIGSEGV) 
F/libc: fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR)
libmaps-mobile.so
```

Краш происходил **внутри конструктора** `SearchSuggestSessionSuggestListener` в нативном C++ коде MapKit SDK.

## Причина
В официальном примере Яндекса (`mapkit-flutter-demo-master/mapkit-samples/map_search`) listener создаётся как **`late final`** поле на **уровне объявления класса**, а НЕ внутри метода инициализации.

### Было (НЕПРАВИЛЬНО ❌):
```dart
class YandexSuggestService {
  late final SearchSuggestSessionSuggestListener _suggestListener;
  
  void initialize() {
    // ...
    _suggestListener = SearchSuggestSessionSuggestListener(
      onResponse: (response) { /* ... */ },
      onError: (error) { /* ... */ },
    ); // ❌ КРАШ ЗДЕСЬ!
  }
}
```

### Стало (ПРАВИЛЬНО ✅):
```dart
class YandexSuggestService {
  // Создаем listener сразу при объявлении поля класса
  late final SearchSuggestSessionSuggestListener _suggestListener = 
    SearchSuggestSessionSuggestListener(
      onResponse: _onSuggestResponse,
      onError: _onSuggestError,
    );
  
  void _onSuggestResponse(response) { /* ... */ }
  void _onSuggestError(error) { /* ... */ }
  
  void initialize() {
    // Listener уже создан на уровне класса
    // ...
  }
}
```

## Решение
1. **Переместили создание listener** с уровня метода `initialize()` на уровень **объявления поля класса**
2. **Вынесли логику обработки** в отдельные методы `_onSuggestResponse()` и `_onSuggestError()`
3. **Убрали явные типы** параметров (используем автоматический вывод типов)

## Важно
Согласно документации Яндекс MapKit:
> "MapKit хранит слабые ссылки на передаваемые ему Listener-объекты. Необходимо самим хранить ссылку на них в памяти"

Listener **ОБЯЗАТЕЛЬНО** должен быть:
- ✅ Полем класса (не локальной переменной)
- ✅ Создан на уровне объявления класса (как в примере Яндекса)
- ✅ Храниться всё время работы с сессией

## Файлы
- `lib/services/yandex_suggest_service_v2.dart` - исправлен
- Справочный пример: `mapkit-flutter-demo-master/mapkit-samples/map_search/lib/features/search/managers/map_search_manager.dart`

## Статус
✅ **ИСПРАВЛЕНО** - приложение больше не крашится при создании listener
🔄 **ТЕСТИРОВАНИЕ** - требуется проверить работу автозаполнения с реальными данными Яндекса
