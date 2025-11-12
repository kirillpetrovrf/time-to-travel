# Настройка Yandex MapKit

## 1. Получение API ключа

### Шаг 1: Регистрация
1. Перейдите на https://developer.tech.yandex.ru/
2. Войдите в аккаунт Yandex или создайте новый
3. Примите пользовательское соглашение

### Шаг 2: Создание приложения
1. Нажмите "Создать приложение"
2. Выберите "MapKit и геосервисы"
3. Заполните форму:
   - **Название**: Такси Попутчик
   - **Описание**: Мобильное приложение для поиска попутчиков
   - **Платформы**: iOS, Android
   - **Тип**: Мобильное приложение

### Шаг 3: Получение ключа
После создания приложения скопируйте **API ключ**

## 2. Настройка проекта

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<application>
    <!-- Добавить перед закрывающим тегом </application> -->
    <meta-data
        android:name="com.yandex.android.maps.API_KEY"
        android:value="ВАШ_API_КЛЮЧ_ЗДЕСЬ" />
</application>
```

### iOS (ios/Runner/Info.plist)
```xml
<!-- Добавить перед закрывающим тегом </dict> -->
<key>YMKApiKey</key>
<string>ВАШ_API_КЛЮЧ_ЗДЕСЬ</string>
```

### Flutter (lib/config/map_config.dart)
```dart
// Замените строку:
static const String yandexMapKitApiKey = 'ВАШ_API_КЛЮЧ_ЗДЕСЬ';
```

## 3. Инициализация MapKit

### main.dart
```dart
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'config/map_config.dart';

void main() {
  // Инициализация MapKit
  AndroidYandexMap.useAndroidViewSurface = false;
  YandexMapkit.initMapkit(apiKey: MapConfig.yandexMapKitApiKey);
  
  runApp(const TaxiPoputchikApp());
}
```

## 4. Активация функций карты

### Раскомментировать импорты
В файле `lib/features/maps/screens/map_picker_screen.dart`:
```dart
// Раскомментировать:
import 'package:yandex_mapkit/yandex_mapkit.dart';

// Раскомментировать блок с реальной реализацией карты
```

## 5. Добавление иконок маркеров

### Создать папку assets/icons/
```
assets/
  icons/
    pickup_marker.png      # Иконка точки посадки
    dropoff_marker.png     # Иконка точки высадки
    default_marker.png     # Иконка по умолчанию
```

### Добавить в pubspec.yaml
```yaml
flutter:
  assets:
    - assets/icons/
```

## 6. Лимиты и мониторинг

### Бесплатные лимиты:
- 25,000 запросов в месяц
- Без ограничений на отображение карт

### Мониторинг использования:
- Заходите в Developer Console
- Раздел "Статистика"
- Отслеживайте использование API

## 7. Безопасность

### Ограничения по домену/пакету:
В настройках приложения в Developer Console можно настроить:
- **Android**: ограничение по package name
- **iOS**: ограничение по bundle identifier
- **Домены**: для веб-версии

### Пример настройки:
```
Android Package Name: com.example.taxi_poputchik
iOS Bundle ID: com.example.taxiPoputchik
```

## 8. Тестирование

После настройки:
1. Запустите приложение
2. Перейдите в раздел создания поездки
3. Попробуйте выбрать точку на карте
4. Проверьте работу геокодирования

## Troubleshooting

### Ошибка "Invalid API key"
- Проверьте правильность ключа
- Убедитесь, что ключ добавлен во все нужные файлы
- Проверьте ограничения в Developer Console

### Карта не загружается
- Проверьте интернет-соединение
- Убедитесь, что инициализация выполняется в main()
- Проверьте логи на наличие ошибок

### Геокодирование не работает
- Проверьте лимиты в Developer Console
- Убедитесь, что включен сервис "Геокодирование"
