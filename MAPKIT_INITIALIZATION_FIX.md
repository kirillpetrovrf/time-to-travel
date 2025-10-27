# 🔧 Истинная причина краша и решение

## ❌ Проблема

Приложение крашилось с ошибкой:
```
Fatal signal 6 (SIGABRT) in libmaps-mobile.so
yandex_flutter_search_SearchFactory_get_instance
```

## 🎯 Истинная причина

**MapKit SDK НЕ БЫЛ инициализирован!**

### Что было в коде:

```kotlin
// MainApplication.kt
MapKitFactory.setApiKey("...")  // ✅ API ключ установлен
MapKitFactory.setLocale("...")   // ✅ Локаль установлена
// MapKitFactory.initialize(this) // ❌ НЕ ВЫЗЫВАЛОСЬ!
```

### Почему это критично:

Согласно документации Yandex MapKit:
> **MapKitFactory.initialize() ОБЯЗАТЕЛЬНО нужно вызвать перед использованием любых компонентов SDK!**

Без этого вызова:
- ❌ SearchFactory.instance → КРАШ
- ❌ Любые операции с картой → КРАШ
- ❌ Routing, Suggest, Search → КРАШ

## ✅ Решение

Добавлен вызов `MapKitFactory.initialize(this)` в MainApplication:

```kotlin
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // 1. Устанавливаем API ключ
        MapKitFactory.setApiKey("2f1d6a75-b751-4077-b305-c6abaea0b542")
        
        // 2. Устанавливаем локаль
        MapKitFactory.setLocale("ru_RU")
        
        // 3. ⭐ КРИТИЧЕСКИ ВАЖНО: Инициализируем MapKit!
        MapKitFactory.initialize(this)
    }
}
```

## 🔍 Почему раньше не крашилось при открытии карты?

Потому что виджет YandexMap **ВНУТРЕННЕ** вызывает инициализацию при первом создании. Но SearchFactory требует, чтобы MapKit был инициализирован **ДО** его использования.

## 📊 Порядок инициализации

### ✅ Правильно:
```
1. MainApplication.onCreate()
   └─> MapKitFactory.initialize(this)
2. Flutter app запускается
3. Можно использовать SearchFactory ✅
```

### ❌ Неправильно (было раньше):
```
1. MainApplication.onCreate()
   └─> Только setApiKey() и setLocale()
2. Flutter app запускается
3. SearchFactory.instance → КРАШ ❌
```

## 🚀 Что теперь должно работать

После этого исправления:

✅ **SearchFactory.instance** - работает
✅ **SearchManager.createSearchManager()** - работает  
✅ **SuggestSession** - работает
✅ **Реальные подсказки от Яндекса** - работают!

## 🧪 Как проверить

```bash
flutter run
```

Затем:
1. Открыть "Тест автозаполнения адресов"
2. Начать вводить адрес: "Мос"
3. **Должны появиться РЕАЛЬНЫЕ подсказки от Яндекс.Карт!**

В логах должно быть:
```
I/MapKit: 🔄 Начинаем инициализацию MapKit...
I/MapKit: ✅ API ключ установлен
I/MapKit: ✅ Локаль установлена: ru_RU
I/MapKit: ✅ MapKitFactory.initialize() вызван успешно!
I/MapKit: 🎉 MapKit полностью инициализирован и готов к работе
```

А потом при вводе текста:
```
I/flutter: 🔄 [YandexSuggest] Начинаем инициализацию...
I/flutter: ✅ [YandexSuggest] Инициализирован (MapKit SearchManager)
I/flutter: 🔍 [YandexSuggest] Запрос suggest: "Мос"
I/flutter: ✅ [YandexSuggest] Получен ответ: 10 подсказок
```

## 📚 Справка по документации

Из официальной документации Yandex MapKit:

> Before using the API, you should initialize the MapKit with the `initialize` method.
> 
> ```kotlin
> MapKitFactory.initialize(context)
> ```

## 🎯 Выводы

1. **API ключ** сам по себе НЕ достаточен
2. **Нужно явно вызывать** `MapKitFactory.initialize()`
3. Это **одноразовая** операция при старте приложения
4. После этого **ВСЕ** компоненты MapKit работают

---

**Теперь запускайте и проверяйте!** 🚀
