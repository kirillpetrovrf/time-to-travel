# Техническое Задание: Мобильное Приложение "Такси Попутчик"

## 📋 ОБЩАЯ ИНФОРМАЦИЯ

**Название проекта:** Такси Попутчик  
**Тип приложения:** Мобильное приложение для iOS и Android  
**Архитектура:** Flutter (фронтенд) + Dart Frog (бэкенд) + PostgreSQL  
**Целевая аудитория:** Водители и пассажиры, ищущие попутчиков  
**Версия:** 1.0  

---

## 🎯 КОНЦЕПЦИЯ ПРОЕКТА

### Основная идея
Универсальное приложение-агрегатор для поиска попутчиков, где **один пользователь может быть как водителем, так и пассажиром** в зависимости от ситуации. Приложение объединяет функции:
- 🚗 **Такси-сервиса** (водитель предлагает поездку)
- 👥 **BlaBlaCar-подобного сервиса** (поиск попутчиков)
- 📍 **Геолокационного сервиса** с интерактивными картами

### Уникальные особенности
1. **Двойная роль пользователя** - переключение между водителем/пассажиром
2. **Интерактивная карта** с визуализацией водителей (🚗) и пассажиров (👤)
3. **Предложение маршрутов** - пассажиры могут предлагать водителям маршруты
4. **Система рейтингов и отзывов** для безопасности
5. **Социальная верификация** - связи через ВКонтакте и Telegram
6. **Гибкая настройка тем** приложения

---

## 🏗️ ТЕКУЩАЯ АРХИТЕКТУРА И СТАТУС

### ✅ РЕАЛИЗОВАННАЯ ФУНКЦИОНАЛЬНОСТЬ

#### 🎨 Система тем и UI
- **Адаптивная система тем** с поддержкой светлой/темной тем
- **Кастомизация интерфейса**: настройка цветов, размеров, шрифтов
- **Cupertino Design System** для нативного iOS-подобного интерфейса
- **Редактор тем** для пользовательской настройки

#### 🌍 Локализация
- **Многоязычность**: русский и английский языки
- **ARB-файлы** для удобного перевода
- **Автоматическая генерация** локализационных классов

#### 🏛️ Архитектура кода
```
lib/
├── main.dart                 # Точка входа приложения
├── config/
│   └── map_config.dart      # Конфигурация карт и API ключей
├── theme/
│   ├── app_theme.dart       # Система тем
│   ├── colors.dart          # Цветовая палитра
│   └── theme_manager.dart   # Менеджер тем с сохранением
├── features/                # Модульная архитектура по фичам
│   ├── auth/               # Авторизация пользователей
│   ├── home/               # Главный экран
│   ├── rides/              # Создание и поиск поездок
│   ├── maps/               # Интеграция с картами
│   └── theme_editor/       # Редактор тем
└── l10n/                   # Файлы локализации
```

#### 🔧 Технический стек (фронтенд)
- **Flutter 3.9+** - кроссплатформенная разработка
- **Cupertino UI** - нативный iOS-стиль интерфейса
- **Provider Pattern** - управление состоянием
- **ARB локализация** - интернационализация
- **Custom Theme System** - гибкая система тем

### ⚠️ В РАЗРАБОТКЕ / ТРЕБУЕТ ДОРАБОТКИ

#### 🗺️ Интеграция карт
- **Yandex MapKit** (требует API ключ)
- **Геолокация** пользователей
- **Отображение маршрутов**
- **Интерактивные маркеры**

#### 👤 Система пользователей
- **Авторизация/регистрация**
- **Профили водителей и пассажиров**
- **Переключение ролей**
- **Система рейтингов**
- **Профиль автомобиля водителя** (марка, модель, год, цвет, фото)
- **Проверка ОСАГО** через внешние API сервисы

#### 🚗 Логика поездок
- **Создание поездок водителями**
- **Поиск попутчиков**
- **Бронирование мест**
- **Чат между участниками**

---

## 📱 ДЕТАЛЬНОЕ ОПИСАНИЕ ФУНКЦИОНАЛЬНОСТИ

### 🏠 ГЛАВНЫЙ ЭКРАН (HomeScreen)

#### Интерфейс
- **Переключатель роли** (Водитель/Пассажир) в верхней части
- **Интерактивная карта** на весь экран с текущим местоположением
- **Быстрые действия** внизу экрана:
  - Водитель: "Создать поездку", "Мои поездки"
  - Пассажир: "Найти поездку", "Мои бронирования"

#### Логика отображения на карте
```dart
// Маркеры пользователей
enum UserType {
  driver,    // 🚗 Отображается как машинка
  passenger  // 👤 Отображается как человек
}

class MapMarker {
  final UserType type;
  final LatLng position;
  final String userId;
  final String? routeInfo; // Для водителей - направление маршрута
  final int rating;        // Рейтинг пользователя
}
```

### 🚗 РЕЖИМ ВОДИТЕЛЯ

#### Создание поездки (CreateRideScreen)
**Поля ввода:**
- **Откуда** (автозаполнение текущей геолокации)
- **Куда** (поиск по адресу + выбор на карте)
- **Время отправления** (дата + время)
- **Количество мест** (1-8 пассажиров)
- **Цена за место** (руб.)
- **Комментарий** (дополнительная информация)
- **Настройки**:
  - Только женщины
  - Разрешить курение
  - Можно с животными
  - Багаж включен

**Функциональность:**
```dart
class RideService {
  // Создание новой поездки
  Future<Ride> createRide({
    required String fromAddress,
    required String toAddress,
    required DateTime departureTime,
    required int availableSeats,
    required double pricePerSeat,
    String? comment,
    RidePreferences? preferences
  });
  
  // Управление заявками
  Future<void> acceptBookingRequest(String requestId);
  Future<void> rejectBookingRequest(String requestId);
  
  // Начало/завершение поездки
  Future<void> startRide(String rideId);
  Future<void> completeRide(String rideId);
}
```

#### Мои поездки
- **Активные поездки** (ожидание пассажиров, в пути)
- **Запланированные поездки** 
- **История поездок** с возможностью оценить пассажиров
- **Заявки от пассажиров** (уведомления + чат)

#### 🚗 Профиль автомобиля водителя
**Обязательная информация:**
- **Марка автомобиля** (выбор из предзагруженного списка)
- **Модель автомобиля** (выбор из списка по марке)
- **Год выпуска** (валидация диапазона 1990-2024)
- **Цвет автомобиля** (выбор из стандартной палитры)
- **Государственный номер** (проверка формата российских номеров)

**Фотографии автомобиля (обязательные):**
- 📸 **4 фото экстерьера**: спереди, сзади, слева, справа
- 📸 **2 фото салона**: передняя часть, задняя часть
- ✅ **Автоматическая обработка**: сжатие, водяные знаки, EXIF-очистка

**Функциональность:**
```dart
class CarProfile {
  final String carId;
  final String brand;           // Марка из статического списка
  final String model;           // Модель из статического списка
  final int year;              // Год выпуска
  final String color;          // Цвет
  final String plateNumber;    // Госномер
  
  // Фотографии
  final List<CarPhoto> photos; // 6 обязательных фото
  
  // Статус проверки администратором
  final CarVerificationStatus verificationStatus;
  final DateTime? verifiedAt;  // Дата верификации
  final String? adminComment;  // Комментарий администратора
}

class CarPhoto {
  final String photoId;
  final CarPhotoType type;     // front, back, left, right, interior_front, interior_back
  final String url;            // Ссылка на фото
  final DateTime uploadedAt;   // Дата загрузки
  final bool isApproved;       // Прошло модерацию
}

enum CarPhotoType {
  front,           // Спереди
  back,            // Сзади
  left,            // Слева
  right,           // Справа
  interiorFront,   // Салон спереди
  interiorBack     // Салон сзади
}

enum CarVerificationStatus {
  pending,         // Ожидает проверки
  approved,        // Одобрен администратором
  rejected,        // Отклонён
  requiresUpdate   // Требует обновления фото/данных
}
```

#### 🛡️ Система проверки ОСАГО через фотографию полиса
**Упрощенный подход без API интеграций:**
- **Загрузка фото полиса ОСАГО** - водитель фотографирует полис
- **OCR распознавание текста** - автоматическое извлечение данных из фото
- **Валидация данных** - проверка формата номера, серии и дат полиса
- **Хранение информации** - сохранение данных в базе приложения

**⚡ ПРЕИМУЩЕСТВА ЭТОГО ПОДХОДА:**
- ✅ **Простота реализации** - не требует сложных API интеграций
- ✅ **Быстрый запуск** - нет необходимости получать доступы к внешним системам
- ✅ **Надежность** - не зависит от доступности внешних сервисов
- ✅ **Экономичность** - нет расходов на API вызовы

**Статусы ОСАГО:**
```dart
enum OSAGOStatus {
  verified,        // ✅ Полис загружен и данные распознаны
  pending,         // 🔄 Ожидает загрузки фото полиса
  invalid,         // ❌ Ошибка в данных полиса или истек срок
  processing,      // ⏳ Обработка фотографии в процессе
  rejected         // ⚠️ Фото полиса отклонено (нечитаемо/некорректно)
}

class OSAGOInfo {
  final String plateNumber;
  final OSAGOStatus status;
  final String? policyNumber;     // Номер полиса (распознан с фото)
  final String? policySeries;     // Серия полиса (распознана с фото)
  final String? insuranceCompany; // Страховая компания
  final DateTime? validFrom;      // Начало действия (распознано с фото)
  final DateTime? validUntil;     // Окончание действия (распознано с фото)
  final DateTime? photoTakenAt;   // Когда была сделана фотография
  final String? photoUrl;         // Ссылка на загруженное фото полиса
  final Map<String, dynamic>? ocrData; // Сырые данные OCR для отладки
  final String? errorMessage;     // Сообщение об ошибке OCR
}
```

**OCR Распознавание данных полиса:**
```dart
// lib/services/ocr_service.dart
class OSAGOOCRService {
  // Распознавание данных с фотографии полиса ОСАГО
  Future<OSAGOOCRResult> extractDataFromPhoto(File photoFile) async {
    try {
      // Используем Google ML Kit или Tesseract для OCR
      final inputImage = InputImage.fromFile(photoFile);
      final textRecognizer = TextRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      return _parseOSAGOData(recognizedText.text);
    } catch (e) {
      return OSAGOOCRResult.error('Ошибка распознавания: $e');
    }
  }
  
  OSAGOOCRResult _parseOSAGOData(String text) {
    // Регулярные выражения для поиска данных полиса
    final policyNumberRegex = RegExp(r'№\s*(\d{10,13})');
    final policySeriesRegex = RegExp(r'серия\s*([А-Я]{3})', caseSensitive: false);
    final dateRegex = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})');
    final companyRegex = RegExp(r'(РОСГОССТРАХ|СОГАЗ|РЕСО|АЛЬФАСТРАХОВАНИЕ|ИНГОССТРАХ)', caseSensitive: false);
    
    final policyNumber = policyNumberRegex.firstMatch(text)?.group(1);
    final policySeries = policySeriesRegex.firstMatch(text)?.group(1);
    final company = companyRegex.firstMatch(text)?.group(1);
    
    // Поиск дат (обычно в полисе указаны даты начала и окончания)
    final dates = dateRegex.allMatches(text).map((match) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }).toList();
    
    DateTime? validFrom, validUntil;
    if (dates.length >= 2) {
      dates.sort();
      validFrom = dates[0];
      validUntil = dates[1];
    }
    
    return OSAGOOCRResult.success(
      policyNumber: policyNumber,
      policySeries: policySeries,
      insuranceCompany: company,
      validFrom: validFrom,
      validUntil: validUntil,
      rawText: text,
    );
  }
}

class OSAGOOCRResult {
  final bool isSuccess;
  final String? policyNumber;
  final String? policySeries;
  final String? insuranceCompany;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? rawText;
  final String? errorMessage;
  
  OSAGOOCRResult.success({
    required this.policyNumber,
    required this.policySeries,
    required this.insuranceCompany,
    required this.validFrom,
    required this.validUntil,
    required this.rawText,
  }) : isSuccess = true, errorMessage = null;
  
  OSAGOOCRResult.error(this.errorMessage) 
    : isSuccess = false, 
      policyNumber = null,
      policySeries = null,
      insuranceCompany = null,
      validFrom = null,
      validUntil = null,
      rawText = null;
      
  bool get hasRequiredData => 
    policyNumber != null && 
    validFrom != null && 
    validUntil != null;
    
  bool get isCurrentlyValid {
    if (validUntil == null) return false;
    return DateTime.now().isBefore(validUntil!);
  }
}
```

**Отображение для пассажиров:**
- 🟢 **Зелёный индикатор**: ОСАГО загружен, данные распознаны, полис действителен
- 🟡 **Жёлтый индикатор**: ОСАГО истекает в течение 30 дней
- 🔴 **Красный индикатор**: ОСАГО не загружен или истёк срок действия
- ⚠️ **Серый индикатор**: Фото полиса загружается или обрабатывается

**Предупреждающие сообщения:**
- 🔴 "Внимание! Водитель не предоставил документы ОСАГО. В случае ДТП ущерб может не быть компенсирован."
- ⚠️ "Обработка документов ОСАГО. Данные будут доступны через несколько минут."
- 🟡 "Срок действия ОСАГО истекает через X дней. Рекомендуем уточнить у водителя."

**UI для загрузки полиса ОСАГО:**
```dart
// lib/screens/upload_osago_screen.dart
class UploadOSAGOScreen extends StatefulWidget {
  @override
  _UploadOSAGOScreenState createState() => _UploadOSAGOScreenState();
}

class _UploadOSAGOScreenState extends State<UploadOSAGOScreen> {
  File? _osagoPhoto;
  bool _isProcessing = false;
  OSAGOOCRResult? _ocrResult;
  
  Future<void> _takeOSAGOPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _osagoPhoto = File(pickedFile.path);
        _isProcessing = true;
      });
      
      // Автоматически запускаем OCR
      await _processOSAGOPhoto();
    }
  }
  
  Future<void> _processOSAGOPhoto() async {
    if (_osagoPhoto == null) return;
    
    try {
      final ocrService = OSAGOOCRService();
      final result = await ocrService.extractDataFromPhoto(_osagoPhoto!);
      
      setState(() {
        _ocrResult = result;
        _isProcessing = false;
      });
      
      if (result.isSuccess && result.hasRequiredData) {
        // Показываем распознанные данные для подтверждения
        _showConfirmationDialog();
      } else {
        // Показываем ошибку и предлагаем повторить
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog();
    }
  }
  
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Проверьте данные полиса'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Номер полиса: ${_ocrResult?.policyNumber ?? "не распознан"}'),
            Text('Серия: ${_ocrResult?.policySeries ?? "не распознана"}'),
            Text('Страховая: ${_ocrResult?.insuranceCompany ?? "не распознана"}'),
            Text('Действует с: ${_formatDate(_ocrResult?.validFrom)}'),
            Text('Действует до: ${_formatDate(_ocrResult?.validUntil)}'),
            SizedBox(height: 16),
            Text('Всё верно?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _takeOSAGOPhoto(); // Повторить фото
            },
            child: Text('Переснять'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveOSAGOData();
            },
            child: Text('Подтвердить'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveOSAGOData() async {
    // Сохраняем данные на сервер
    final osagoService = OSAGOService();
    await osagoService.uploadOSAGOInfo(
      photo: _osagoPhoto!,
      ocrResult: _ocrResult!,
    );
    
    Navigator.pop(context, true); // Возвращаем успех
  }
}
```

### 👥 РЕЖИМ ПАССАЖИРА

#### Поиск поездок (SearchRidesScreen)
**Фильтры поиска:**
- **Маршрут** (откуда → куда)
- **Дата и время** (± гибкость по времени)
- **Количество мест**
- **Ценовой диапазон**
- **Рейтинг водителя** (от X звёзд)
- **Дополнительные фильтры**:
  - Только женщины-водители
  - Разрешено курение
  - Можно с животными
  - Только с действующим ОСАГО
  - Только верифицированные профили

**Детальная карточка поездки для пассажира:**
- 📸 **Фотографии автомобиля** (галерея из 6 фото)
- 🚗 **Информация об авто**: марка, модель, год, цвет, номер
- 🛡️ **Статус ОСАГО** с цветовой индикацией
- ⭐ **Рейтинг водителя** и последние отзывы
- 👤 **Профиль водителя** с фотографией и статистикой
- 💰 **Детализация стоимости** поездки

**Результаты поиска:**
```dart
class RideSearchResult {
  final String rideId;
  final Driver driver;          // Информация о водителе
  final CarProfile car;         // Информация об автомобиле
  final OSAGOInfo osagoStatus;  // Статус страховки
  final Route route;           // Маршрут поездки
  final DateTime departureTime;
  final int availableSeats;
  final double pricePerSeat;
  final double rating;         // Рейтинг водителя
  final String? comment;
  final List<RoutePoint> waypoints; // Промежуточные точки
}
```

#### Предложение маршрута водителю
**Уникальная фича:**
Пассажир может нажать на водителя на карте и предложить ему свой маршрут:

```dart
class RouteProposal {
  final String passengerId;
  final String driverId;
  final Route proposedRoute;    // Предлагаемый маршрут
  final double suggestedPrice;  // Предлагаемая цена
  final String message;         // Сообщение водителю
  final DateTime proposedTime;  // Желаемое время
}
```

### 🗺️ ИНТЕРАКТИВНАЯ КАРТА

#### Визуализация пользователей
- **Водители** 🚗: 
  - Зелёные маркеры-машинки для свободных
  - Жёлтые для водителей в поездке
  - При нажатии показывается направление движения
- **Пассажиры** 👤:
  - Синие маркеры-человечки
  - При нажатии показывается желаемый маршрут
- **Кластеризация** при большом скоплении пользователей

#### Интерактивность
- **Построение маршрутов** в реальном времени
- **Выбор точек** на карте для создания поездки
- **Отображение пробок** и времени в пути
- **Geofencing** для уведомлений о прибытии

```dart
class MapController {
  // Отображение пользователей на карте
  void showNearbyUsers(List<User> users, UserType filterType);
  
  // Построение маршрута
  Future<Route> buildRoute(LatLng from, LatLng to, List<LatLng> waypoints);
  
  // Отслеживание местоположения
  Stream<LatLng> trackUserLocation();
  
  // Обработка нажатий на маркеры
  void onMarkerTap(String userId, UserType type);
}
```

### ⭐ СИСТЕМА РЕЙТИНГОВ И ОТЗЫВОВ

#### Модель рейтинга
```dart
class Rating {
  final String rideId;
  final String fromUserId;  // Кто оценивает
  final String toUserId;    // Кого оценивают
  final UserType ratedAs;   // Как водителя или как пассажира
  final double stars;       // 1-5 звёзд
  final String? comment;    // Текстовый отзыв
  final DateTime createdAt;
  
  // Критерии оценки
  final RatingCriteria criteria;
}

class RatingCriteria {
  final double punctuality;    // Пунктуальность
  final double cleanliness;    // Чистота (авто/пассажира)
  final double communication;  // Общение
  final double driving;        // Качество вождения (только для водителей)
  final double behaviour;      // Поведение
}
```

#### Система доверия
- **Общий рейтинг** (среднее от всех оценок)
- **Рейтинг как водителя** / **рейтинг как пассажира** раздельно
- **Бейджи достижений**:
  - "Надёжный водитель" (500+ поездок, рейтинг 4.8+)
  - "Отличный попутчик" (100+ поездок, рейтинг 4.9+)
  - "Новичок" (< 10 поездок)
- **Верификация** через документы

### 💬 СИСТЕМА ЧАТОВ

#### Чат между участниками поездки
```dart
class ChatMessage {
  final String messageId;
  final String senderId;
  final String receiverId; // или groupId для группового чата
  final String text;
  final MessageType type;   // text, location, system
  final DateTime timestamp;
  final bool isRead;
}

class ChatService {
  // Отправка сообщений
  Future<void> sendMessage(String chatId, String text);
  
  // Отправка геолокации
  Future<void> sendLocation(String chatId, LatLng location);
  
  // Системные уведомления
  Future<void> sendSystemMessage(String chatId, SystemMessageType type);
}
```

### 🛡️ СИСТЕМА БЕЗОПАСНОСТИ И МОДЕРАЦИИ

#### Модерация профилей водителей
**Автоматическая проверка:**
- ✅ **Валидация фотографий**: соответствие требованиям, отсутствие неприемлемого контента
- ✅ **Проверка номера авто**: соответствие российским стандартам
- ✅ **Анализ качества фото**: достаточная освещённость, чёткость, полный вид авто

**Ручная модерация:**
- 👤 **Проверка администратором**: все профили проходят ручную проверку
- 📝 **Статусы модерации**: 
  - `pending` - ожидает проверки
  - `approved` - одобрен
  - `rejected` - отклонён с комментарием
  - `requires_correction` - требует исправлений

**Требования к фотографиям:**
```dart
class PhotoRequirements {
  static const int minWidth = 800;       // Минимальная ширина
  static const int minHeight = 600;      // Минимальная высота
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB максимум
  static const List<String> allowedFormats = ['jpg', 'jpeg', 'png'];
  
  // Обязательные углы съёмки
  static const Map<CarPhotoType, String> photoDescriptions = {
    CarPhotoType.front: 'Передняя часть автомобиля с видимым номером',
    CarPhotoType.back: 'Задняя часть автомобиля с видимым номером',
    CarPhotoType.left: 'Левая сторона автомобиля полностью',
    CarPhotoType.right: 'Правая сторона автомобиля полностью',
    CarPhotoType.interiorFront: 'Передняя часть салона (руль, панель)',
    CarPhotoType.interiorBack: 'Задняя часть салона (задние сиденья)'
  };
}
```

---

## 💰 МОНЕТИЗАЦИЯ И БИЗНЕС-МОДЕЛЬ

### Источники дохода
- **Комиссия с поездок**: 8-10% с каждой завершённой поездки
- **Премиум подписка**: расширенные фильтры, приоритет в поиске
- **Реклама**: таргетированная реклама автосервисов, заправок
- **Партнёрство**: интеграция с заправками, мойками, автосервисами

### Финансовая модель с учетом банковских комиссий (2024)

#### Анализ банковских тарифов
**Комиссии за прием платежей:**
- Тинькофф: 1,2-2,0% + 15-30 руб за транзакцию
- Сбербанк: 1,6-2,3% + 15-30 руб за транзакцию
- СБП (QR-коды): 0,2-0,7% (значительно дешевле)

**Комиссии за выплаты водителям:**
- Массовые выплаты: 30-50 руб + 0,5-1% от суммы
- Переводы на карты: до 3% для небольших сумм

#### Оптимальная структура комиссии 10%

```dart
// lib/models/commission_model.dart
class CommissionCalculator {
  // Структура комиссии платформы
  static const double PLATFORM_COMMISSION = 0.10; // 10%
  
  static CommissionBreakdown calculateCommission(double tripCost) {
    final platformFee = tripCost * PLATFORM_COMMISSION;
    final passengerTotal = tripCost + platformFee;
    
    // Банковские расходы
    final acquiringFee = passengerTotal * 0.023 + 20; // 2.3% + 20 руб
    final payoutFee = 40 + tripCost * 0.01; // 40 руб + 1%
    final totalBankFees = acquiringFee + payoutFee;
    
    // Операционные расходы (2%)
    final operationalCosts = tripCost * 0.02;
    
    // Чистая прибыль платформы
    final netProfit = platformFee - totalBankFees - operationalCosts;
    
    return CommissionBreakdown(
      tripCost: tripCost,
      platformFee: platformFee,
      passengerTotal: passengerTotal,
      driverPayout: tripCost,
      bankFees: totalBankFees,
      operationalCosts: operationalCosts,
      netProfit: netProfit,
      profitMargin: netProfit / passengerTotal,
    );
  }
}

class CommissionBreakdown {
  final double tripCost;
  final double platformFee;
  final double passengerTotal;
  final double driverPayout;
  final double bankFees;
  final double operationalCosts;
  final double netProfit;
  final double profitMargin;
  
  const CommissionBreakdown({
    required this.tripCost,
    required this.platformFee,
    required this.passengerTotal,
    required this.driverPayout,
    required this.bankFees,
    required this.operationalCosts,
    required this.netProfit,
    required this.profitMargin,
  });
  
  bool get isProfitable => netProfit > 0;
  
  String get profitabilityStatus {
    if (profitMargin > 0.03) return 'Высокая рентабельность';
    if (profitMargin > 0.01) return 'Средняя рентабельность';
    if (profitMargin > 0) return 'Низкая рентабельность';
    return 'Убыточно';
  }
}
```

#### Минимальная стоимость поездки
Для обеспечения рентабельности установить минимальный тариф:
- **Короткие поездки (до 30 км)**: от 600 руб + комиссия 12%
- **Средние поездки (30-100 км)**: комиссия 10%
- **Длинные поездки (100+ км)**: комиссия 8%

#### Интеграция платежных систем

```dart
// lib/services/payment_service.dart
abstract class PaymentProvider {
  Future<PaymentResult> processPayment(PaymentRequest request);
  Future<PayoutResult> processDriverPayout(PayoutRequest request);
  double getAcquiringRate();
  double getPayoutRate();
  String get providerName;
}

class YooKassaProvider implements PaymentProvider {
  @override
  double getAcquiringRate() => 0.029; // 2.9%
  
  @override
  double getPayoutRate() => 0.015; // 1.5%
  
  @override
  String get providerName => 'YooKassa';
}

class TinkoffProvider implements PaymentProvider {
  @override
  double getAcquiringRate() => 0.023; // 2.3%
  
  @override
  double getPayoutRate() => 0.01; // 1.0%
  
  @override
  String get providerName => 'Tinkoff';
}

class PaymentService {
  final List<PaymentProvider> _providers;
  
  PaymentService(this._providers);
  
  PaymentProvider _selectOptimalProvider(double amount) {
    // Логика выбора оптимального провайдера
    // в зависимости от суммы и типа операции
    return _providers.reduce((a, b) => 
      a.getAcquiringRate() < b.getAcquiringRate() ? a : b);
  }
  
  Future<PaymentResult> processPayment(PaymentRequest request) async {
    final provider = _selectOptimalProvider(request.amount);
    return provider.processPayment(request);
  }
}
```

#### Система отчетности по финансам

```dart
// lib/models/financial_report.dart
class DailyFinancialReport {
  final DateTime date;
  final int totalTrips;
  final double totalRevenue;
  final double totalCommissions;
  final double bankFees;
  final double operationalCosts;
  final double netProfit;
  final double averageTripCost;
  final double profitMargin;
  
  // Детализация по типам поездок
  final Map<TripType, TripTypeStats> tripTypeBreakdown;
  
  // Статистика по водителям
  final int activeDrivers;
  final double averageDriverEarnings;
  
  // Проблемные операции
  final List<FailedTransaction> failedTransactions;
  final List<DisputedTrip> disputes;
}

enum TripType { short, medium, long }

class TripTypeStats {
  final int count;
  final double revenue;
  final double averageCost;
  final double profitMargin;
}
```

---

## 🔧 ТЕХНИЧЕСКАЯ АРХИТЕКТУРА БЭКЕНДА

### 🦎 Dart Frog Server Architecture

#### Серверная часть на Dart Frog
```
backend/
├── routes/                  # API маршруты
│   ├── auth/               # Авторизация
│   │   ├── login.dart
│   │   ├── register.dart
│   │   └── refresh.dart
│   ├── users/              # Управление пользователями
│   │   ├── profile.dart
│   │   ├── rating.dart
│   │   └── location.dart
│   ├── rides/              # Управление поездками
│   │   ├── create.dart
│   │   ├── search.dart
│   │   ├── book.dart
│   │   └── cancel.dart
│   ├── maps/               # Картографические API
│   │   ├── geocoding.dart
│   │   ├── routing.dart
│   │   └── nearby.dart
│   └── chat/               # Чат система
│       ├── messages.dart
│       └── websocket.dart
├── lib/
│   ├── models/             # Модели данных
│   ├── services/           # Бизнес-логика
│   ├── repositories/       # Работа с БД
│   └── middleware/         # Middleware (auth, cors, etc.)
└── pubspec.yaml
```

#### База данных PostgreSQL
```sql
-- Пользователи
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Верификация
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_document_verified BOOLEAN DEFAULT FALSE,
    
    -- Настройки
    preferred_language VARCHAR(10) DEFAULT 'ru',
    notification_settings JSONB DEFAULT '{}',
    theme_settings JSONB DEFAULT '{}'
);

-- Профили водителей
CREATE TABLE driver_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    license_number VARCHAR(50),
    license_expiry DATE,
    car_model VARCHAR(100),
    car_color VARCHAR(50),
    car_plate VARCHAR(20),
    car_year INTEGER,
    driver_rating DECIMAL(3,2) DEFAULT 0,
    total_rides_as_driver INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Автомобили водителей
CREATE TABLE driver_cars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id),
    brand VARCHAR(100) NOT NULL,          -- Марка из API
    model VARCHAR(100) NOT NULL,          -- Модель из API
    year INTEGER NOT NULL,                -- Год выпуска
    color VARCHAR(50) NOT NULL,           -- Цвет
    plate_number VARCHAR(20) UNIQUE NOT NULL, -- Госномер
    is_verified BOOLEAN DEFAULT FALSE,    -- Прошёл модерацию
    verified_at TIMESTAMP,                -- Дата верификации
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Фотографии автомобилей
CREATE TABLE car_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    car_id UUID REFERENCES driver_cars(id) ON DELETE CASCADE,
    photo_type VARCHAR(20) NOT NULL,      -- front, back, left, right, interior_front, interior_back
    file_url TEXT NOT NULL,               -- Ссылка на фото
    file_size INTEGER,                    -- Размер файла в байтах
    is_approved BOOLEAN DEFAULT FALSE,    -- Прошло модерацию
    uploaded_at TIMESTAMP DEFAULT NOW(),
    approved_at TIMESTAMP,
    moderator_comment TEXT,               -- Комментарий модератора
    
    CONSTRAINT valid_photo_type CHECK (photo_type IN ('front', 'back', 'left', 'right', 'interior_front', 'interior_back'))
);

-- Информация о ОСАГО (через загрузку фото полиса)
CREATE TABLE osago_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    car_id UUID REFERENCES driver_cars(id) ON DELETE CASCADE,
    plate_number VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,          -- verified, pending, invalid, processing, rejected
    policy_number VARCHAR(50),            -- Номер полиса (распознан с фото)
    policy_series VARCHAR(10),            -- Серия полиса (распознана с фото)
    insurance_company VARCHAR(200),       -- Страховая компания (распознана с фото)
    valid_from DATE,                      -- Действует с (распознано с фото)
    valid_until DATE,                     -- Действует до (распознано с фото)
    photo_url TEXT,                       -- Ссылка на фото полиса ОСАГО
    photo_uploaded_at TIMESTAMP,          -- Когда была загружена фотография
    ocr_processed_at TIMESTAMP,           -- Когда были распознаны данные
    ocr_data JSONB,                       -- Сырые данные OCR для отладки
    error_message TEXT,                   -- Сообщение об ошибке OCR
    is_manually_verified BOOLEAN DEFAULT FALSE, -- Проверено администратором вручную
    admin_comment TEXT,                   -- Комментарий администратора
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT valid_osago_status CHECK (status IN ('verified', 'pending', 'invalid', 'processing', 'rejected'))
);

-- Справочник марок и моделей автомобилей
CREATE TABLE car_brands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,    -- Название марки
    logo_url TEXT,                        -- Логотип марки
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE car_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID REFERENCES car_brands(id),
    name VARCHAR(100) NOT NULL,           -- Название модели
    body_type VARCHAR(50),                -- Тип кузова (седан, хэтчбек, и т.д.)
    min_year INTEGER,                     -- Минимальный год выпуска
    max_year INTEGER,                     -- Максимальный год выпуска
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(brand_id, name)
);

-- Поездки
CREATE TABLE rides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES users(id),
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    from_lat DECIMAL(10,8) NOT NULL,
    from_lng DECIMAL(11,8) NOT NULL,
    to_lat DECIMAL(10,8) NOT NULL,
    to_lng DECIMAL(11,8) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    available_seats INTEGER NOT NULL,
    price_per_seat DECIMAL(10,2) NOT NULL,
    status ride_status DEFAULT 'planned',
    created_at TIMESTAMP DEFAULT NOW(),
    route_points JSONB DEFAULT '[]',
    preferences JSONB DEFAULT '{}',
    comment TEXT
);

-- Бронирования
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID REFERENCES rides(id),
    passenger_id UUID REFERENCES users(id),
    seats_count INTEGER NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status booking_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    pickup_point JSONB,
    dropoff_point JSONB
);

-- Рейтинги и отзывы
CREATE TABLE ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ride_id UUID REFERENCES rides(id),
    from_user_id UUID REFERENCES users(id),
    to_user_id UUID REFERENCES users(id),
    rated_as user_role NOT NULL, -- 'driver' or 'passenger'
    stars INTEGER CHECK (stars >= 1 AND stars <= 5),
    comment TEXT,
    criteria JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);
```

### 🌐 VPS Хостинг и Развёртывание

#### Требования к серверу
- **VPS**: минимум 2 CPU, 4GB RAM, 40GB SSD
- **OS**: Ubuntu 22.04 LTS
- **Dart**: версия 3.0+
- **PostgreSQL**: версия 14+
- **Nginx**: reverse proxy и SSL
- **Certbot**: автоматические SSL сертификаты

#### Docker-конфигурация
```dockerfile
# Dockerfile для Dart Frog сервера
FROM dart:3.0-sdk AS build

WORKDIR /app
COPY pubspec.yaml .
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/taxiapp
      - JWT_SECRET=your_jwt_secret
    depends_on:
      - db

  db:
    image: postgres:14
    environment:
      POSTGRES_DB: taxiapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```



#### Требования для OCR библиотек

**Для Flutter (клиентская сторона):**
```yaml
# pubspec.yaml
dependencies:
  google_mlkit_text_recognition: ^0.9.0  # Бесплатный OCR от Google
  image_picker: ^1.0.4                   # Камера и галерея
  image: ^4.0.17                          # Обработка изображений

dev_dependencies:
  # Альтернативные OCR решения:
  # tesseract_ocr: ^0.0.2                # Tesseract OCR
  # flutter_tesseract_ocr: ^0.4.23       # Более стабильная версия
```

**Дополнительные библиотеки для сервера:**
```yaml
# backend/pubspec.yaml
dependencies:
  tesseract_dart: ^1.0.0      # OCR на серверной стороне (опционально)
  image: ^4.0.17              # Обработка изображений
  postgres: ^2.6.2           # База данных
  shelf_multipart: ^1.0.0    # Загрузка файлов
```
```




## 🚀 ПЛАН РАЗРАБОТКИ

### 📅 ЭТАП 1: Основная функциональность (4-6 недель)

#### Неделя 1-2: Бэкенд и API
- [x] ~~Настройка VPS и развёртывание~~
- [ ] Разработка Dart Frog сервера
- [ ] Подключение PostgreSQL
- [ ] API авторизации (JWT)
- [ ] API пользователей и профилей

#### Неделя 3-4: Интеграция карт и поездки
- [ ] Интеграция Yandex MapKit (получение API ключа)
- [ ] Геолокация и карты в приложении
- [ ] API создания и поиска поездок
- [ ] Система бронирований

#### Неделя 5-6: Чаты и рейтинги
- [ ] WebSocket для real-time чатов
- [ ] Система рейтингов и отзывов
- [ ] Push-уведомления
- [ ] Тестирование и отладка

### 📅 ЭТАП 2: Расширенная функциональность (3-4 недели)

#### Неделя 7-8: UX/UI улучшения
- [ ] Анимации и микровзаимодействия
- [ ] Оптимизация производительности
- [ ] Адаптивность под разные размеры экранов
- [ ] Тёмная тема и настройки

#### Неделя 9-10: Дополнительные возможности
- [ ] Система скидок и промокодов
- [ ] Интеграция платёжных систем
- [ ] Система жалоб и поддержки
- [ ] Аналитика и метрики

### 📅 ЭТАП 3: Оптимизация и запуск (2-3 недели)

#### Неделя 11-12: Подготовка к релизу
- [ ] Нагрузочное тестирование
- [ ] Публикация в App Store и Google Play
- [ ] Настройка мониторинга и логирования
- [ ] Backup и disaster recovery

---

## 💰 ОЦЕНКА СТОИМОСТИ ПРОЕКТА

### 🛠️ Техническая разработка

#### Фронтенд (Flutter)
- **Базовая функциональность**: 120-150 часов
- **UI/UX дизайн и анимации**: 60-80 часов
- **Интеграция с картами**: 40-50 часов
- **Профиль автомобиля и фото**: 50-70 часов
- **Система ОСАГО и проверок**: 30-40 часов
- **Тестирование и отладка**: 50-60 часов
- **ИТОГО фронтенд**: ~350-450 часов

#### Бэкенд (Dart Frog + PostgreSQL)
- **API разработка**: 100-120 часов
- **База данных и миграции**: 40-50 часов
- **WebSocket для чатов**: 25-30 часов
- **Система авторизации**: 20-25 часов
- **API автомобилей и фото**: 40-50 часов
- **Интеграция с внешними API (ОСАГО, авто)**: 50-60 часов
- **Система модерации**: 30-40 часов
- **ИТОГО бэкенд**: ~305-375 часов

#### DevOps и инфраструктура
- **Настройка VPS**: 15-20 часов
- **CI/CD настройка**: 20-25 часов
- **Мониторинг и логирование**: 15-20 часов
- **Backup системы**: 10-15 часов
- **Файловое хранилище для фото**: 15-20 часов
- **ИТОГО DevOps**: ~75-100 часов

### 📊 Общая оценка времени: 730-925 часов

### 💵 Стоимость при разных ставках:
- **Middle разработчик** (₽2,000/час): ₽1,460,000 - ₽1,850,000


### 🖥️ Инфраструктурные расходы (ежемесячно)
- **VPS хостинг**: ₽5,000-8,000/мес (увеличен для хранения фото)
- **Файловое хранилище (S3)**: ₽3,000-10,000/мес (зависит от объёма фото)
- **CDN для фотографий**: ₽2,000-5,000/мес
- **Домен и SSL**: ₽1,000/год
- **Yandex MapKit API**: ₽10,000-30,000/мес (зависит от нагрузки)
- **НСИС API (проверка ОСАГО)**: ₽5,000-20,000/мес (тарифы уточняются)
- **Автокод API**: ₽3,000-8,000/мес
- **Push-уведомления**: ₽2,000-5,000/мес
- **Backup и мониторинг**: ₽3,000-5,000/мес

**Общие расходы на инфраструктуру**: ₽34,000-90,000/мес

**⚠️ Примечание**: Стоимость API НСИС пока неизвестна, так как требуется подписание соглашения. Оценка основана на аналогичных государственных API сервисах.

---

## 🎯 КОНКУРЕНТНЫЕ ПРЕИМУЩЕСТВА

### 🔥 Уникальные особенности
1. **Двойная роль пользователя** - один аккаунт для водителя и пассажира
2. **Предложение маршрутов** - пассажиры могут инициировать поездки
3. **Интерактивная карта** с real-time отображением всех участников
4. **Гибкая система тем** для персонализации
5. **Детальная система рейтингов** по критериям

### 📈 Потенциал монетизации
- **Комиссия с поездок**: 5-10% с каждой завершённой поездки
- **Премиум подписка**: расширенные фильтры, приоритет в поиске
- **Реклама**: таргетированная реклама автосервисов, заправок
- **Партнёрство**: интеграция с заправками, мойками, автосервисами

---

## 📞 ЗАКЛЮЧЕНИЕ

Приложение "Такси Попутчик" представляет собой **инновационное решение** в сфере совместных поездок, объединяющее функциональность такси-сервиса и поиска попутчиков. 

**Ключевые преимущества проекта:**
- ✅ **Готовая архитектура** и базовый функционал
- ✅ **Современные технологии** (Flutter + Dart Frog)
- ✅ **Масштабируемое решение** для роста аудитории
- ✅ **Уникальные фишки** отличающие от конкурентов

**Проект готов к активной разработке** и может быть запущен в продакшен через 2-3 месяца активной работы.

---

*Документ подготовлен для согласования технических требований и бюджета проекта*

**Контакты для обсуждения:**  
📧 Email: [ваш email]  
📱 Telegram: [ваш telegram]  
💼 GitHub: https://github.com/kirillpetrovrf/taxi_poputchik
