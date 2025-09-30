# ПЛАН ДОРАБОТОК ПОД ТЗ v3.0
## Детальное руководство по обновлению приложения

### 📋 ОБЩИЙ ОБЗОР ИЗМЕНЕНИЙ

После получения обновленного технического задания v3.0 от клиента выявлены критические изменения, требующие переработки существующих систем и добавления новой функциональности.

---

## 🔴 КРИТИЧЕСКИЕ ИЗМЕНЕНИЯ (PRIORITY 1)

### 1. 🧳 СИСТЕМА БАГАЖА - ПОЛНАЯ ПЕРЕРАБОТКА

#### Текущее состояние:
- 4 размера (S/M/L/Custom) с разными ценами
- Система оплаты за каждый размер

#### Новые требования:
- **1 багажное место БЕСПЛАТНО** (любой размер)
- **Количество**: 1-10 сумок с кнопкой + 
- **Дополнительный багаж**: Цены настраиваются диспетчером через API

#### План доработки:
```dart
// ФАЙЛЫ К ИЗМЕНЕНИЮ:
// 1. /lib/models/baggage.dart
class BaggageItem {
  final BaggageSize size;
  final int quantity; // Изменить: теперь 1-10
  final double pricePerExtraItem; // Новое: цена за доп. багаж
  
  // Новая логика расчета
  double calculateCost() {
    if (quantity <= 1) return 0; // Первое место бесплатно
    return (quantity - 1) * pricePerExtraItem;
  }
}

// 2. /lib/features/booking/screens/baggage_selection_screen.dart
// - Изменить UI: показать "БЕСПЛАТНО" для первого места
// - Добавить кнопку + для увеличения количества до 10
// - Добавить загрузку цен с сервера

// 3. /lib/services/baggage_pricing_service.dart (НОВЫЙ)
class BaggagePricingService {
  Future<Map<BaggageSize, double>> getExtraBaggagePrices() async {
    // Загрузка цен от диспетчера
  }
}
```

#### Этапы выполнения:
1. **День 1**: Обновить модель BaggageItem
2. **День 2**: Переделать BaggageSelectionScreen UI
3. **День 3**: Создать BaggagePricingService
4. **День 4**: Интегрировать в booking flow
5. **День 5**: Тестирование

---

### 2. 🐕 СИСТЕМА ЖИВОТНЫХ - ОБНОВЛЕНИЕ

#### Текущее состояние:
- 4 размера (XS/S/M/L)
- Простые цены

#### Новые требования:
- **Убрать размер XS**
- **Добавить систему согласий** с галочкой
- **Тексты согласий** редактируются диспетчером через API

#### План доработки:
```dart
// ФАЙЛЫ К ИЗМЕНЕНИЮ:
// 1. /lib/models/pet_info.dart
enum PetSize { s, m, l } // Убрать XS

// 2. /lib/services/pet_agreement_service.dart (НОВЫЙ)
class PetAgreementService {
  Future<String> getPetAgreementText(PetSize size) async {
    // Загрузка текстов согласий с сервера
  }
}

// 3. /lib/features/booking/screens/pet_selection_screen.dart
// - Убрать XS размер
// - Добавить чекбокс с согласием для M/L
// - Загружать тексты согласий с сервера
class PetSelectionWidget {
  Widget _buildAgreementSection() {
    return CheckboxListTile(
      title: Text(agreementText), // Загружается с сервера
      value: _agreementAccepted,
      onChanged: (value) => setState(() => _agreementAccepted = value!),
    );
  }
}
```

#### Этапы выполнения:
1. **День 1**: Убрать XS из enum и UI
2. **День 2**: Создать PetAgreementService
3. **День 3**: Добавить систему согласий в UI
4. **День 4**: Интегрировать в booking flow
5. **День 5**: Тестирование

---

### 3. 🔐 VK СКИДКА - ИЗМЕНЕНИЕ ЛОГИКИ

#### Текущее состояние:
- Постоянная скидка 30₽ для всех заказов

#### Новые требования:
- **Разовая скидка 300₽** только на первый заказ

#### План доработки:
```dart
// ФАЙЛЫ К ИЗМЕНЕНИЮ:
// 1. /lib/models/user.dart
class User {
  final bool isVKVerified;
  final bool hasUsedVKDiscount; // НОВОЕ поле
  
  bool get canUseVKDiscount => isVKVerified && !hasUsedVKDiscount;
}

// 2. /lib/services/vk_discount_service.dart (НОВЫЙ)
class VKDiscountService {
  Future<bool> canUseVKDiscount(String userId) async {
    // Проверка возможности использования скидки
  }
  
  Future<void> markVKDiscountAsUsed(String userId) async {
    // Отметить скидку как использованную
  }
}

// 3. Обновить все места где используется VK скидка
// - PriceCalculator
// - BookingScreen UI
// - VKVerificationScreen
```

#### Этапы выполнения:
1. **День 1**: Добавить поле hasUsedVKDiscount в User
2. **День 2**: Создать VKDiscountService
3. **День 3**: Обновить PriceCalculator
4. **День 4**: Обновить UI компоненты
5. **День 5**: Миграция существующих пользователей

---

### 4. 🚗 ВЫБОР АВТОМОБИЛЯ - НОВАЯ ФУНКЦИЯ

#### Новые требования:
- **Только для индивидуальных поездок**
- **Типы**: седан, универсал, минивэн, микроавтобус
- **Групповые поездки**: автомобиль назначается диспетчером

#### План доработки:
```dart
// ФАЙЛЫ К СОЗДАНИЮ:
// 1. /lib/models/vehicle_type.dart (НОВЫЙ)
enum VehicleType {
  sedan('Седан'),
  wagon('Универсал'),
  minivan('Минивэн'),
  microbus('Микроавтобус');
  
  const VehicleType(this.displayName);
  final String displayName;
}

// 2. /lib/features/booking/screens/vehicle_selection_screen.dart (НОВЫЙ)
class VehicleSelectionScreen extends StatefulWidget {
  // UI для выбора типа автомобиля
}

// 3. Обновить IndividualBookingScreen
// - Добавить шаг выбора автомобиля
// - Сохранять выбор в booking
```

#### Этапы выполнения:
1. **День 1**: Создать модель VehicleType
2. **День 2**: Создать VehicleSelectionScreen
3. **День 3**: Интегрировать в IndividualBookingScreen
4. **День 4**: Обновить модель Booking
5. **День 5**: Тестирование

---

## 🟡 ВАЖНЫЕ ДОПОЛНЕНИЯ (PRIORITY 2)

### 5. 🔑 СЕКРЕТНЫЙ ВХОД ДИСПЕТЧЕРА

#### Новые требования:
- **7 нажатий** в правый верхний угол
- **Отдельная авторизация** для диспетчера

#### План доработки:
```dart
// ФАЙЛЫ К ИЗМЕНЕНИЮ:
// 1. /lib/features/home/screens/home_screen.dart
class SecretDispatcherAccess {
  int _tapCount = 0;
  
  void handleTap() {
    _tapCount++;
    if (_tapCount >= 7) {
      _showDispatcherLogin();
      _tapCount = 0;
    }
    
    Timer(Duration(seconds: 5), () => _tapCount = 0);
  }
}

// 2. /lib/features/admin/screens/dispatcher_login_screen.dart (НОВЫЙ)
class DispatcherLoginScreen extends StatefulWidget {
  // Отдельная форма входа для диспетчера
}
```

#### Этапы выполнения:
1. **День 1**: Добавить логику 7 нажатий
2. **День 2**: Создать DispatcherLoginScreen
3. **День 3**: Интегрировать в home screen
4. **День 4**: Тестирование

---

### 6. ⏰ УПРАВЛЕНИЕ РАСПИСАНИЕМ

#### Новые требования:
- **Диспетчер настраивает время** для каждой остановки
- **Переключатели включения/выключения** остановок
- **API для обновления** в реальном времени

#### План доработки:
```dart
// ФАЙЛЫ К СОЗДАНИЮ:
// 1. /lib/services/schedule_service.dart (НОВЫЙ)
class ScheduleService {
  Future<void> updateStopSchedule(String stopId, Duration newTime) async {}
  Future<void> toggleStopActive(String stopId, bool isActive) async {}
}

// 2. /lib/features/admin/screens/schedule_management_screen.dart (НОВЫЙ)
class ScheduleManagementScreen extends StatefulWidget {
  // UI для управления расписанием остановок
}
```

#### Этапы выполнения:
1. **День 1-2**: Создать ScheduleService
2. **День 3-4**: Создать ScheduleManagementScreen
3. **День 5**: Интегрировать в админ-панель

---

### 7. 💰 УПРАВЛЕНИЕ ЦЕНАМИ

#### Новые требования:
- **Диспетчер настраивает формулы** свободных маршрутов
- **Округление цен**: минимум 1000₽, округление вверх до тысяч

#### План доработки:
```dart
// ФАЙЛЫ К ИЗМЕНЕНИЮ:
// 1. /lib/services/pricing_service.dart
class PricingService {
  Future<void> updateFreeRouteFormula({
    required double basePrice,
    required double pricePerKm,
    required double cityFee,
  }) async {}
}

// 2. /lib/services/free_route_calculator.dart
class FreeRouteCalculator {
  static double calculatePrice(double distanceKm, PricingSettings settings) {
    double price = settings.basePrice + (distanceKm * settings.pricePerKm) + settings.cityFee;
    
    // Минимальная цена 1,000₽
    if (price < 1000) price = 1000;
    
    // Округление вверх до тысяч
    return (price / 1000).ceil() * 1000.0;
  }
}
```

#### Этапы выполнения:
1. **День 1**: Обновить FreeRouteCalculator
2. **День 2**: Создать PricingService
3. **День 3**: Создать UI управления ценами
4. **День 4**: Интегрировать в админ-панель
5. **День 5**: Тестирование

---

### 8. 👤 РАСШИРЕННЫЙ ПРОФИЛЬ

#### Новые требования:
- **Пол**: Обязательное поле (переключатель)
- **Доверенное лицо**: Телефон для экстренных случаев

#### План доработки:
```dart
// ФАЙЛЫ К ИЗМЕНЕНИЮ:
// 1. /lib/models/user.dart
class User {
  final Gender gender; // НОВОЕ обязательное поле
  final String emergencyContact; // НОВОЕ поле
}

enum Gender { male, female }

// 2. /lib/features/profile/screens/profile_screen.dart
// - Добавить поле выбора пола (переключатель)
// - Добавить поле ввода телефона доверенного лица
```

#### Этапы выполнения:
1. **День 1**: Обновить модель User
2. **День 2**: Обновить ProfileScreen
3. **День 3**: Обновить регистрацию
4. **День 4**: Миграция данных
5. **День 5**: Тестирование

---

## 🔮 ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ (PRIORITY 3)

### 9. 💳 SBP ОПЛАТА

#### Новые требования:
- **Подготовить интеграцию** с возможностью настройки диспетчером
- **Возможность отключения** через админ-панель

#### План доработки:
```dart
// ФАЙЛЫ К СОЗДАНИЮ:
// 1. /lib/services/payment_service.dart (НОВЫЙ)
class PaymentService {
  Future<String?> getSBPPaymentUrl(double amount, String orderId) async {
    // Генерация ссылки для SBP оплаты
  }
}

// 2. /lib/features/admin/screens/payment_settings_screen.dart (НОВЫЙ)
class PaymentSettingsScreen extends StatefulWidget {
  // UI для настройки SBP оплаты
}
```

---

## 📅 КАЛЕНДАРНЫЙ ПЛАН ВЫПОЛНЕНИЯ

### НЕДЕЛЯ 1 (1-7 октября): Критические изменения
- **День 1-2**: Система багажа (новые правила)
- **День 3-4**: Система животных (убрать XS, согласия)
- **День 5-6**: VK скидка (разовая логика)
- **День 7**: Выбор автомобиля (базовая реализация)

### НЕДЕЛЯ 2 (8-14 октября): Важные дополнения  
- **День 1-2**: Секретный вход диспетчера
- **День 3-4**: Управление расписанием
- **День 5-6**: Управление ценами
- **День 7**: Расширенный профиль

### НЕДЕЛЯ 3 (15-21 октября): Финализация
- **День 1-2**: SBP оплата (подготовка)
- **День 3-4**: Тестирование всех изменений
- **День 5-6**: Исправление багов
- **День 7**: Обновление документации

---

## 🧪 ПЛАН ТЕСТИРОВАНИЯ

### Этапы тестирования:
1. **Unit тесты**: Новые методы расчета цен, логика скидок
2. **Integration тесты**: API интеграции, Firebase обновления
3. **UI тесты**: Новые экраны, обновленные flow
4. **End-to-end тесты**: Полный цикл бронирования с новой логикой

### Чек-лист для каждой функции:
- [ ] Код написан и прошел review
- [ ] Unit тесты покрывают основную логику
- [ ] UI тестирование на разных устройствах
- [ ] Интеграция с существующим кодом работает
- [ ] Backward compatibility сохранена
- [ ] Документация обновлена

---

## 🎯 КРИТЕРИИ ГОТОВНОСТИ

### Система считается готовой когда:
1. ✅ Все критические изменения реализованы
2. ✅ Новая логика работает корректно
3. ✅ Существующие функции не сломаны
4. ✅ Приложение компилируется без ошибок
5. ✅ End-to-end тесты проходят
6. ✅ Документация обновлена

### Метрики качества:
- **Code coverage**: >80% для новых модулей
- **Performance**: Время загрузки экранов <2 сек
- **Stability**: Отсутствие критических багов
- **UX**: Интуитивность новых интерфейсов

---

## 📞 КОММУНИКАЦИЯ С КЛИЕНТОМ

### Еженедельные отчеты:
- **Понедельник**: План на неделю
- **Среда**: Промежуточный прогресс  
- **Пятница**: Итоги недели, демо готовых функций

### Демонстрации:
- **Еженедельно**: Готовые функции
- **По запросу**: Промежуточные результаты
- **Финальная**: Полная система перед релизом

---

**ГОТОВНОСТЬ К СТАРТУ**: ✅ План утвержден, техническое задание обновлено, можно начинать реализацию!
