# 🚀 Yandex Suggest API - Быстрый Старт

## ✅ Что сделано?

Интегрирован **нативный Yandex Suggest API** для получения онлайн подсказок всех адресов России (города, улицы, дома).

---

## 🎯 Как протестировать?

### 1. Запустить приложение
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter run
```

### 2. Открыть экран с автозаполнением
- Главный экран → **"Индивидуальный трансфер"**
- Или: **"Групповая поездка"** → **"Свой маршрут"**

### 3. Протестировать подсказки

**Тест 1: Города**
```
Ввести: "Москва"
Ожидается: Москва, Россия + другие города
```

**Тест 2: Улицы**
```
Ввести: "Пермь Ленина"
Ожидается: улица Ленина, Пермь, Пермский край, Россия
```

**Тест 3: Дома**
```
Ввести: "Москва Тверская 1"
Ожидается: Тверская улица, 1, Москва, Россия
```

**Тест 4: Любой город России**
```
Попробуйте: Екатеринбург, Казань, Новосибирск, Краснодар, Сочи
```

---

## 📋 Проверка логов

### Во время работы приложения:
```bash
# Окно 1: Запуск приложения
flutter run

# Окно 2: Мониторинг Yandex API
flutter logs | grep YANDEX
```

### Что искать в логах:
```
✅ [YANDEX MAPKIT] Инициализирован успешно
✅ [YANDEX SUGGEST] SuggestSession создана
💡 [YANDEX SUGGEST] Поиск подсказок для: "Москва"
✅ [YANDEX SUGGEST] Получен ответ: 10 элементов
📝 [YANDEX SUGGEST] Примеры:
   1. Москва, Россия
   2. Москва, Московская область
   3. ...
```

---

## ⚡ Основные изменения

### 1. `pubspec.yaml`
```yaml
# Было: yandex_mapkit: ^4.2.1
# Стало:
yandex_maps_mapkit: ^4.8.1  # Установлена 4.25.0-beta
```

### 2. `lib/main.dart`
```dart
import 'package:yandex_maps_mapkit/init.dart' as mapkit_init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Инициализация MapKit
  await mapkit_init.initMapkit(
    apiKey: '2f1d6a75-b751-4077-b305-c6abaea0b542',
  );
  
  runApp(const TimeToTravelApp());
}
```

### 3. `lib/services/yandex_maps_service.dart`
```dart
// ✅ Новые импорты
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

// ✅ Нативный Suggest API
Future<List<String>> getSuggestions(String query) async {
  // Границы России
  final boundingBox = BoundingBox(
    const Point(latitude: 41.0, longitude: 19.0),
    const Point(latitude: 82.0, longitude: 180.0),
  );
  
  // Запрос подсказок
  _suggestSession!.suggest(
    boundingBox,
    suggestOptions,
    SearchSuggestSessionSuggestListener(...),
    text: query,
  );
}
```

---

## 🐛 Если что-то не работает

### Подсказки не появляются?
1. Проверьте интернет соединение
2. Смотрите логи: `flutter logs | grep YANDEX`
3. Убедитесь, что ввели минимум 2 символа

### Ошибка компиляции?
```bash
flutter clean
flutter pub get
flutter run
```

### Нужна помощь?
Смотрите полную документацию:
- `YANDEX_SUGGEST_API_INTEGRATION_COMPLETE.md`

---

## 📊 Что дальше?

После успешного тестирования:

1. ✅ **Проверено онлайн подсказки**
2. 🔄 Обновить метод `geocode()` для реального геокодирования
3. 🔄 Добавить кэширование популярных адресов
4. 🔄 Оптимизировать debounce для уменьшения запросов

---

**Готово к тестированию!** 🎉

Запускайте `flutter run` и проверяйте работу автозаполнения адресов.
