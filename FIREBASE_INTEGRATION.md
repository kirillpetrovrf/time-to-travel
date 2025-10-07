# 🔥 Инструкция по интеграции Firebase

## ⚠️ ТЕКУЩИЙ СТАТУС
Приложение работает **полностью в оффлайн режиме** без Firebase:
- Все данные хранятся локально (SQLite + SharedPreferences)
- Firebase зависимости закомментированы
- Нет обращений к удаленным серверам

---

## 📋 Шаги для подключения реального Firebase

### 1. Создание Firebase проекта

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Создайте новый проект или выберите существующий
3. Добавьте приложения для нужных платформ:
   - **Android**: укажите `package name` из `android/app/build.gradle`
   - **iOS**: укажите `bundle ID` из `ios/Runner/Info.plist`
   - **Web** (опционально): укажите домен

### 2. Загрузка конфигурационных файлов

#### Android:
- Скачайте `google-services.json`
- Поместите в `android/app/google-services.json`

#### iOS:
- Скачайте `GoogleService-Info.plist`
- Поместите в `ios/Runner/GoogleService-Info.plist`

#### Web (опционально):
- Скопируйте Firebase config (apiKey, authDomain и т.д.)
- Обновите `web/index.html`

### 3. Генерация Firebase Options

Запустите команду для генерации `firebase_options.dart`:

```bash
flutterfire configure
```

Это создаст/обновит файл `lib/firebase_options.dart` с реальными credentials.

### 4. Включение Firebase в коде

#### Раскомментируйте в `main.dart`:

```dart
// БЫЛО (закомментировано):
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// СТАНЕТ:
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

---

## 📁 Список сервисов для интеграции

Найдите комментарии `TODO: Интеграция с Firebase` в следующих файлах:

### 1. `lib/services/baggage_pricing_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<Map<String, double>> getExtraBaggagePrices() async {
  // Раскомментировать Firebase запросы
  // final doc = await _firestore.collection('pricing').doc('baggage').get();
  // ...
}
```

### 2. `lib/services/booking_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<Booking?> createBooking(...) async {
  // Добавить условие проверки online/offline режима
  // if (await _isOnlineMode()) {
  //   return _createFirebaseBooking(...);
  // }
  return _createOfflineBooking(...);
}
```

### 3. `lib/services/content_management_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<PageContent> getPageContent(String pageId) async {
  // Раскомментировать Firestore запросы
  // final doc = await _firestore.collection('pages').doc(pageId).get();
  // ...
}
```

### 4. `lib/services/free_route_pricing_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<FreeRoutePricing> getPricingSettings() async {
  // Раскомментировать Firebase запросы
  // final doc = await _firestore.collection('settings').doc('pricing').get();
  // ...
}
```

### 5. `lib/services/pet_agreement_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<String> getCatAgreementText() async {
  // Раскомментировать Firebase запросы
  // final doc = await _firestore.collection('agreements').doc('cat').get();
  // ...
}
```

### 6. `lib/services/trip_settings_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<TripSettings> getTripSettings() async {
  // Раскомментировать Firebase запросы
  // final doc = await _firestore.collection('settings').doc('trips').get();
  // ...
}
```

### 7. `lib/services/user_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<User> createUser(User user) async {
  // Добавить синхронизацию с Firestore
  // await _firestore.collection('users').doc(user.id).set(user.toJson());
  // ...
}
```

### 8. `lib/services/vehicle_service.dart`
```dart
// TODO: Интеграция с Firebase
Stream<List<Vehicle>> getDriverVehicles(String driverId) {
  // Раскомментировать Firebase запросы
  // return _firestore
  //   .collection('vehicles')
  //   .where('driverId', isEqualTo: driverId)
  //   .snapshots()
  //   .map((snapshot) => ...);
}
```

### 9. `lib/services/vk_service.dart`
```dart
// TODO: Интеграция с Firebase
Future<double> getVkDiscount() async {
  // Раскомментировать Firebase проверку скидок
  // final doc = await _firestore.collection('promotions').doc('vk').get();
  // ...
}
```

---

## 🔄 Стратегия гибридного режима (рекомендуется)

После подключения Firebase реализуйте **online/offline синхронизацию**:

### Пример для `booking_service.dart`:

```dart
Future<Booking?> createBooking(...) async {
  try {
    // Проверяем подключение к интернету
    final hasConnection = await _checkInternetConnection();
    
    if (hasConnection) {
      // 1. Создаем в Firebase
      final firebaseBooking = await _createFirebaseBooking(...);
      
      // 2. Сохраняем локально как кеш
      await _saveToLocalCache(firebaseBooking);
      
      return firebaseBooking;
    } else {
      // Создаем локально с флагом "needs_sync"
      final offlineBooking = await _createOfflineBooking(...);
      await _markForSync(offlineBooking.id);
      
      return offlineBooking;
    }
  } catch (e) {
    debugPrint('⚠️ Ошибка создания бронирования: $e');
    // Fallback на локальное сохранение
    return _createOfflineBooking(...);
  }
}

// Фоновая синхронизация
Future<void> syncPendingData() async {
  final pendingBookings = await _getBookingsMarkedForSync();
  
  for (final booking in pendingBookings) {
    try {
      await _firestore.collection('bookings').doc(booking.id).set(booking.toJson());
      await _removeSyncFlag(booking.id);
    } catch (e) {
      debugPrint('⚠️ Не удалось синхронизировать ${booking.id}: $e');
    }
  }
}
```

---

## 🗄️ Структура Firestore коллекций

Рекомендуемая структура базы данных:

```
firestore
├── users/
│   └── {userId}/
│       ├── id: string
│       ├── firstName: string
│       ├── lastName: string
│       ├── phone: string
│       └── createdAt: timestamp
│
├── bookings/
│   └── {bookingId}/
│       ├── id: string
│       ├── userId: string
│       ├── route: map
│       ├── status: string
│       ├── createdAt: timestamp
│       └── price: number
│
├── settings/
│   ├── trips/
│   │   ├── maxPassengers: number
│   │   ├── maxChildSeats: number
│   │   └── basePricePerKm: number
│   │
│   └── pricing/
│       ├── basePricePerKm: number
│       ├── pricePerMinute: number
│       └── minPrice: number
│
├── pricing/
│   └── baggage/
│       ├── small: number
│       ├── medium: number
│       └── large: number
│
├── agreements/
│   ├── cat/
│   │   └── text: string
│   └── dog/
│       └── text: string
│
├── pages/
│   └── {pageId}/
│       ├── id: string
│       ├── title: string
│       ├── content: string
│       └── updatedAt: timestamp
│
└── vehicles/
    └── {vehicleId}/
        ├── id: string
        ├── driverId: string
        ├── model: string
        ├── plateNumber: string
        └── capacity: number
```

---

## 🔐 Настройка Firebase Security Rules

### Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Пользователи могут читать/изменять только свои данные
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Бронирования доступны только владельцам
    match /bookings/{bookingId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == resource.data.userId || 
                      request.auth.uid == resource.data.driverId);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                               request.auth.uid == resource.data.userId;
    }
    
    // Настройки и цены - только чтение для всех
    match /settings/{document=**} {
      allow read: if true;
      allow write: if false; // Только через админ панель
    }
    
    match /pricing/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    match /agreements/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    match /pages/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // Транспорт - только для водителей
    match /vehicles/{vehicleId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.driverId;
    }
  }
}
```

---

## 📦 Необходимые зависимости

Убедитесь, что в `pubspec.yaml` есть все Firebase пакеты:

```yaml
dependencies:
  # Firebase Core (обязательно)
  firebase_core: ^2.24.2
  
  # Firebase Services
  cloud_firestore: ^4.14.0
  firebase_auth: ^4.16.0
  firebase_storage: ^11.6.0  # Если нужно хранение файлов
  firebase_messaging: ^14.7.10  # Для push-уведомлений
  
  # Аналитика (опционально)
  firebase_analytics: ^10.8.0
  firebase_crashlytics: ^3.4.9
```

---

## ✅ Чек-лист перед запуском с Firebase

- [ ] Firebase проект создан
- [ ] `google-services.json` добавлен (Android)
- [ ] `GoogleService-Info.plist` добавлен (iOS)
- [ ] `flutterfire configure` выполнена
- [ ] `firebase_options.dart` сгенерирован
- [ ] Импорты Firebase раскомментированы в `main.dart`
- [ ] Firebase инициализация раскомментирована в `main.dart`
- [ ] Firebase запросы раскомментированы в сервисах
- [ ] Firestore Security Rules настроены
- [ ] Начальные данные загружены в Firestore (settings, pricing и т.д.)
- [ ] Протестировано создание/чтение данных

---

## 🚨 Важные примечания

1. **Сейчас приложение работает БЕЗ Firebase** - все данные локальные
2. При подключении Firebase рекомендуется **сохранить оффлайн режим** как fallback
3. Используйте **Firestore offline persistence** для автоматического кеширования:
   ```dart
   FirebaseFirestore.instance.settings = const Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```
4. Реализуйте **background sync** для отправки данных созданных оффлайн

---

## 📞 Контакты для помощи

Если возникнут вопросы при интеграции Firebase:
- Firebase Documentation: https://firebase.google.com/docs/flutter/setup
- FlutterFire: https://firebase.flutter.dev/
