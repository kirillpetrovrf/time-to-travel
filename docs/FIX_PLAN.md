# ПЛАН ИСПРАВЛЕНИЯ КРАША В ОСНОВНОМ ПРОЕКТЕ

## Проблема
`SearchSuggestSessionSuggestListener` вызывает SIGSEGV при создании из-за НЕПРАВИЛЬНОЙ ИНИЦИАЛИЗАЦИИ MapKit.

## Причина
В основном проекте MapKit инициализируется в **MainApplication.kt** через **Native Android API**:
```kotlin
MapKitFactory.initialize(this)
```

В рабочем примере Яндекса MapKit инициализируется в **main.dart** через **Flutter Plugin API**:
```dart
await init.initMapkit(apiKey: "...")
```

## Решение

### Шаг 1: Удалить инициализацию из MainApplication.kt
❌ **УДАЛИТЬ** весь класс `MainApplication.kt` или закомментировать инициализацию MapKit

**Файл:** `android/app/src/main/kotlin/com/timetotravel/app/MainApplication.kt`

**Что удалить:**
```kotlin
// УДАЛИТЬ ВСЕ ЭТО:
MapKitFactory.setApiKey("2f1d6a75-b751-4077-b305-c6abaea0b542")
MapKitFactory.setLocale("ru_RU")
MapKitFactory.initialize(this)
```

### Шаг 2: Добавить инициализацию в main.dart
✅ **ДОБАВИТЬ** инициализацию MapKit через Flutter Plugin

**Файл:** `lib/main.dart`

**Что добавить:**
```dart
import 'package:yandex_maps_mapkit/init.dart' as init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Инициализация Yandex MapKit (КРИТИЧЕСКИ ВАЖНО!)
  await init.initMapkit(apiKey: "2f1d6a75-b751-4077-b305-c6abaea0b542");
  
  // ... остальной код
}
```

### Шаг 3: Проверить AndroidManifest.xml
⚠️ **ПРОВЕРИТЬ** наличие API ключа в манифесте (опционально, но рекомендуется)

**Файл:** `android/app/src/main/AndroidManifest.xml`

**Должно быть:**
```xml
<application>
    <meta-data
        android:name="com.yandex.mapkit.ApiKey"
        android:value="2f1d6a75-b751-4077-b305-c6abaea0b542" />
    <!-- ... -->
</application>
```

### Шаг 4: Протестировать автозаполнение
1. Запустить приложение
2. Перейти в тестовый экран автозаполнения
3. Ввести адрес в поле поиска
4. Проверить, что НЕТ краша и приходят подсказки

## Важные замечания

### ⚠️ Двойная инициализация - запрещена!
**НЕЛЬЗЯ** инициализировать MapKit и в `MainApplication.kt`, и в `main.dart`!

Это приведет к конфликту и крашу. Нужен только ОДИН способ инициализации.

### ✅ Правильный способ (Flutter Plugin)
```dart
// В main.dart:
import 'package:yandex_maps_mapkit/init.dart' as init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init.initMapkit(apiKey: "YOUR_API_KEY");
  runApp(const MyApp());
}
```

### ❌ Неправильный способ (Native Android)
```kotlin
// В MainApplication.kt - НЕ ДЕЛАЙТЕ ТАК при использовании Flutter Plugin!
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.initialize(this) // ❌ Конфликт с Flutter Plugin!
    }
}
```

## Почему это важно?

### Native инициализация vs Flutter Plugin
1. **Native Android API** (`MapKitFactory.initialize()`):
   - Инициализирует MapKit на уровне Android
   - НЕ создает Flutter-привязки к нативному коду
   - Listener'ы из Flutter не могут подключиться к нативным объектам
   - Результат: **SIGSEGV при создании listener'а**

2. **Flutter Plugin API** (`init.initMapkit()`):
   - Инициализирует MapKit через Flutter Plugin
   - Создает все необходимые Flutter↔Native привязки
   - Listener'ы из Flutter корректно подключаются
   - Результат: **Все работает без краша**

## Следующие действия
1. [ ] Закомментировать инициализацию в `MainApplication.kt`
2. [ ] Добавить импорт в `main.dart`: `import 'package:yandex_maps_mapkit/init.dart' as init;`
3. [ ] Добавить инициализацию в `main()`: `await init.initMapkit(apiKey: "...")`
4. [ ] Пересобрать приложение
5. [ ] Протестировать автозаполнение
6. [ ] Если ключ невалиден - получить новый ключ в личном кабинете Яндекса
