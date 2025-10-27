# ОТЧЕТ О ПРОБЛЕМЕ С ЯНДЕКС MAPKIT SEARCH API

## Описание проблемы
SearchManager не возвращает результаты при использовании SuggestSession. Все запросы заканчиваются таймаутом без вызова callback'ов `onResponse` или `onError`.

---

## Информация о приложении

### Платформа
- **OS:** Android
- **Устройство:** Samsung Galaxy (реальное устройство, не эмулятор)
- **Экран:** 1080x2340, DisplayCutout
- **API Level:** Android 14+

### MapKit SDK
- **Версия:** `yandex_maps_mapkit: ^4.17.2` (Flutter plugin)
- **Язык:** Flutter/Dart
- **API ключ:** `2f1d6a75-b751-4077-b305-c6abaea0b542`
- **Package name:** `com.timetotravel.app`

### Статус API ключа
✅ **Активен** (проверено в личном кабинете разработчика)
✅ **Тариф:** Бесплатный
✅ **Израсходовано:** 0 запросов
✅ **Package:** `com.timetotravel.app` добавлен в ограничения

---

## Код инициализации

### Инициализация MapKit (main.dart)
```dart
import 'package:yandex_maps_mapkit/init.dart' as mapkit_init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await mapkit_init.initMapkit(
      apiKey: "2f1d6a75-b751-4077-b305-c6abaea0b542",
    );
    print('✅ Yandex MapKit инициализирован через Flutter Plugin API');
  } catch (e) {
    print('❌ Ошибка инициализации MapKit: $e');
  }

  runApp(const TimeToTravelApp());
}
```

### Использование SearchManager
```dart
import 'package:yandex_maps_mapkit/search.dart';

class YandexSuggestService {
  // SearchManager создается сразу
  final _searchManager = SearchFactory.instance.createSearchManager(
    SearchManagerType.Combined
  );
  
  // SuggestSession создается как late final
  late final _suggestSession = _searchManager.createSuggestSession();
  
  // Listener создается как late final
  late final _suggestListener = SearchSuggestSessionSuggestListener(
    onResponse: _onSuggestResponse,
    onError: _onSuggestError,
  );

  void initialize() {
    print('✅ YandexSuggestService инициализирован');
  }

  Stream<List<SuggestItem>> getSuggestions(String query) async* {
    print('🚀 [Step 3] ОТПРАВЛЯЕМ ЗАПРОС К ЯНДЕКС API...');
    
    final completer = Completer<List<SuggestItem>>();
    
    // Формируем параметры
    final boundingBox = BoundingBox(
      southWest: const Point(latitude: 41.0, longitude: 19.0),
      northEast: const Point(latitude: 82.0, longitude: 180.0),
    );
    
    final options = SuggestOptions(
      suggestTypes: SuggestType.Geo.value | SuggestType.Biz.value,
      resultPageSize: 10,
    );
    
    // ОТПРАВЛЯЕМ ЗАПРОС
    _suggestSession.suggest(
      formattedAddress: query,
      window: boundingBox,
      options: options,
      listener: _suggestListener,
    );
    
    // Ждем ответ с таймаутом 5 секунд
    try {
      final results = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      yield results;
    } on TimeoutException {
      print('⏱️ [Step 4.TIMEOUT] ТАЙМАУТ! Яндекс не ответил за 5 секунд');
      yield [];
    }
  }

  // Эти методы НИКОГДА НЕ ВЫЗЫВАЮТСЯ!
  void _onSuggestResponse(List<SuggestItem> items) {
    print('✅ [Step 4.SUCCESS] Получен ответ от Яндекса!');
    print('✅ [Step 4.1] Количество подсказок: ${items.length}');
  }

  void _onSuggestError(Error error) {
    print('❌ [Step 4.ERROR] Ошибка от Яндекса: $error');
  }
}
```

---

## Что происходит

### ✅ Работает:
1. MapKit инициализируется успешно
2. SearchManager создается без ошибок
3. SuggestSession создается без ошибок
4. Listener создается без ошибок (нет SIGSEGV)
5. Метод `suggest()` вызывается без исключений
6. Интернет работает на устройстве

### ❌ НЕ работает:
1. **Listener callback'и НИКОГДА не вызываются**
2. Ни `onResponse`, ни `onError` не получают управление
3. Все запросы заканчиваются 5-секундным таймаутом
4. Подсказки не приходят

---

## Логи с реального устройства

### Инициализация MapKit (успешно)
```
I/flutter (20937): ✅ Yandex MapKit инициализирован через Flutter Plugin API
```

### Запросы к API (отправляются)
```
I/flutter (20937): 🔍 [Step 1] НОВЫЙ ЗАПРОС АВТОЗАПОЛНЕНИЯ
I/flutter (20937): 🔍 [Step 1.1] Введенный текст: "москва"
I/flutter (20937): 🔍 [Step 1.2] Длина текста: 6 символов
I/flutter (20937): 🔵 [Step 2] Формируем параметры запроса к Яндекс API:
I/flutter (20937):    - BoundingBox: юго-запад=(lat:41.0, lon:19.0), северо-восток=(lat:82.0, lon:180.0)
I/flutter (20937):    - SuggestTypes: GEO | BIZ
I/flutter (20937):    - Лимит результатов: 10
I/flutter (20937): 🚀 [Step 3] ОТПРАВЛЯЕМ ЗАПРОС К ЯНДЕКС API...
I/flutter (20937): ⏳ [Step 3.1] Ждем ответ от Яндекса (таймаут 5 секунд)...
```

### Ответ от Яндекс MapKit (странный)
```
W/yandex.maps(20937): poxHcJDuv2tO5gpI+pN3: No available cache for request
```

### Таймаут (callback не вызван)
```
I/flutter (20937): ⏱️  [Step 4.TIMEOUT] ТАЙМАУТ! Яндекс не ответил за 5 секунд
I/flutter (20937): ⏱️  Возможные причины:
I/flutter (20937):       - Нет интернета
I/flutter (20937):       - Яндекс API недоступен
I/flutter (20937):       - MapKit не инициализирован правильно
I/flutter (20937): ═══════════════════════════════════════════════════════
I/flutter (20937): 
I/flutter (20937): ✅ [FROM] Получено подсказок: 0
```

---

## Ключевое наблюдение

### Проблема: "No available cache for request"

В логах постоянно появляется:
```
W/yandex.maps(20937): poxHcJDuv2tO5gpI+pN3: No available cache for request
```

**Что это означает?**
- MapKit НЕ может загрузить данные с серверов Яндекса
- Нет кэша для запроса
- Callback'и не вызываются, потому что MapKit не получает ответ от сервера

---

## Вопросы к разработчикам Яндекса

### 1. Почему "No available cache for request"?
- Это ошибка инициализации MapKit?
- Это проблема с API ключом?
- Это проблема с сетью?

### 2. Почему callback'и не вызываются?
- Listener создается корректно (нет SIGSEGV)
- Метод `suggest()` вызывается без исключений
- Но ни `onResponse`, ни `onError` никогда не получают управление

### 3. Требуется ли дополнительная инициализация?
- MapKit инициализируется через `init.initMapkit(apiKey: "...")`
- SearchManager создается через `SearchFactory.instance.createSearchManager()`
- Нужно ли что-то еще?

### 4. Работает ли Search API в Flutter plugin?
- В примере `mapkit-flutter-demo/map_search` тот же подход
- Но у нас не работает
- Есть ли известные проблемы с Flutter plugin?

---

## Что мы уже попробовали

### ❌ Не помогло:
1. Инициализация MapKit в `MainApplication.kt` (вызывала SIGSEGV)
2. Инициализация MapKit в `main.dart` (нет краша, но callback'и не вызываются)
3. Создание Listener разными способами (как поле, как локальная переменная)
4. Увеличение таймаута до 10 секунд
5. Тестирование на реальном устройстве (та же проблема)
6. Проверка API ключа (активен, лимит не исчерпан)

### ✅ Помогло (частично):
1. Убрали инициализацию из `MainApplication.kt` → нет SIGSEGV
2. Добавили инициализацию в `main.dart` → MapKit инициализируется
3. Listener создается без краша

---

## Дополнительная информация

### Интернет работает
Устройство имеет доступ к интернету, другие сетевые запросы работают.

### API ключ валиден
Проверено в личном кабинете:
- ✅ Статус: Активен
- ✅ Package: `com.timetotravel.app` добавлен
- ✅ Лимит: Не исчерпан (0 запросов)

### MapKit инициализирован
Логи подтверждают успешную инициализацию:
```
I/flutter (20937): ✅ Yandex MapKit инициализирован через Flutter Plugin API
```

### Яндекс Карты работали ранее
Сегодня на этом же устройстве Яндекс Карты отображались корректно с этим же API ключом.

---

## Запрос

Пожалуйста, подскажите:

1. **Что означает ошибка "No available cache for request"?**
2. **Почему callback'и Listener не вызываются?**
3. **Требуется ли дополнительная настройка для Search API?**
4. **Есть ли известные проблемы с Flutter plugin для Search API?**
5. **Нужно ли активировать Search API отдельно в личном кабинете?**

---

## Контакты для связи

**Разработчик:** Кирилл Петров  
**Email:** [ваш email]  
**Проект:** TimeToTravel  
**Package name:** com.timetotravel.app  
**API ключ:** 2f1d6a75-b751-4077-b305-c6abaea0b542

---

## Версии зависимостей

```yaml
dependencies:
  flutter:
    sdk: flutter
  yandex_maps_mapkit: ^4.17.2
```

```gradle
// android/app/build.gradle
android {
    compileSdk 34
    minSdkVersion 24
    targetSdkVersion 34
}
```

---

**Дата отчета:** 24 октября 2025 г.  
**Устройство:** Samsung Galaxy (реальное устройство)  
**Статус:** Listener callback'и не вызываются, все запросы таймаутят
