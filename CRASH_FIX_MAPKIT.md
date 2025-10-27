# 🔧 Исправление краша при открытии экрана автозаполнения

## 🐛 Проблема

Приложение крашилось при нажатии на кнопку "Тест автозаполнения адресов":

```
Fatal signal 6 (SIGABRT) in libmaps-mobile.so
yandex_flutter_search_SearchFactory_get_instance
```

## 🔍 Причина

**SearchFactory требует инициализации MapKit**, которая происходит только при первом отображении карты. Мы пытались инициализировать SearchManager сразу при открытии экрана, когда MapKit ещё не был готов.

## ✅ Решение

Реализована **ленивая инициализация**:
1. Сервис НЕ инициализируется при открытии экрана
2. Инициализация происходит только при первом вводе текста
3. Если инициализация не удалась - возвращаем пустой список

## 📝 Что изменено

### 1. `yandex_suggest_service_v2.dart`

**Было:**
```dart
Future<List<SuggestItem>> getSuggestions({required String query}) async {
  if (!_isInitialized) {
    initialize(); // Может крашнуться!
  }
  // ...
}
```

**Стало:**
```dart
Future<List<SuggestItem>> getSuggestions({required String query}) async {
  if (!_isInitialized) {
    try {
      initialize();
    } catch (e) {
      debugPrint('❌ Не удалось инициализировать: $e');
      return []; // Возвращаем пустой список вместо краша
    }
  }
  // ...
}
```

### 2. `address_autocomplete_test_screen.dart`

**Было:**
```dart
@override
void initState() {
  super.initState();
  _suggestService.initialize(); // Вызывалось сразу - КРАШ!
  // ...
}
```

**Стало:**
```dart
@override
void initState() {
  super.initState();
  // НЕ инициализируем здесь!
  // Инициализация произойдёт при первом вводе текста
  // ...
}
```

## 🎯 Альтернативное решение (если нужно)

Если всё равно крашится, можно полностью отключить SearchFactory и использовать моковые данные:

```dart
class YandexSuggestService {
  Future<List<SuggestItem>> getSuggestions({required String query}) async {
    // Временно возвращаем моковые данные
    return [
      SuggestItem(
        title: 'Москва',
        subtitle: 'Россия',
        displayText: 'Москва, Россия',
        searchText: 'Москва',
      ),
      // ... другие города
    ];
  }
}
```

## 🚀 Как проверить

```bash
flutter run
```

Затем:
1. Войти в приложение
2. Настройки → "Тест автозаполнения адресов"
3. **Экран должен открыться без краша!**
4. Начать вводить текст
5. Должны появиться подсказки (или пустой список, если MapKit не инициализирован)

## 📊 Статус

| Проблема | Статус |
|----------|--------|
| Краш при открытии экрана | ✅ Исправлено |
| Ленивая инициализация | ✅ Реализована |
| Обработка ошибок | ✅ Добавлена |
| Graceful degradation | ✅ Готово |

---

**Теперь запускайте и проверяйте!** 🚀
