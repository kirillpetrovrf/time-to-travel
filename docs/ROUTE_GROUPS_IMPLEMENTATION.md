# 🚀 Реализация системы групп маршрутов

## 📋 Оглавление
1. [Обзор системы](#обзор-системы)
2. [Структура данных](#структура-данных)
3. [Файлы для создания/изменения](#файлы-для-созданияизменения)
4. [Этапы реализации](#этапы-реализации)
5. [Логика работы](#логика-работы)
6. [Интерфейс админ-панели](#интерфейс-админ-панели)
7. [Миграция существующих данных](#миграция-существующих-данных)

---

## 🎯 Обзор системы

### Цель
Создать систему управления маршрутами через **группы**, позволяющую:
- ✅ Изменять цены для группы маршрутов одной кнопкой
- ✅ Изменять цены для отдельных маршрутов индивидуально
- ✅ Автоматически создавать обратные маршруты
- ✅ Видеть, какие маршруты используют групповую цену, а какие - индивидуальную

### Два режима работы

#### Режим 1: Групповое изменение
```
Диспетчер меняет цену группы "Ростовская область": 8000₽ → 9000₽

→ Автоматически обновляются ВСЕ маршруты с флагом useGroupPrice=true:
  • Донецк → Ростов: 8000₽ → 9000₽
  • Ростов → Донецк: 8000₽ → 9000₽
  • Харцызск → Ростов: 8000₽ → 9000₽
  • ... и т.д.
  
→ Маршруты с customPrice=true НЕ изменяются
```

#### Режим 2: Индивидуальное изменение
```
Диспетчер меняет цену конкретного маршрута:
Енакиево → Ростов: 12000₽ → 11000₽

→ Обновляется ТОЛЬКО этот маршрут
→ Устанавливается флаг customPrice=true
→ При следующем групповом изменении этот маршрут НЕ трогается
```

---

## 📊 Структура данных

### 1. Модель RouteGroup (новая)

**Файл:** `lib/models/route_group.dart`

```dart
class RouteGroup {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final List<String> destinationCities; // Города назначения
  final List<String> originCities;      // Города отправления
  final bool autoGenerateReverse;       // Автоматически создавать обратные маршруты
  final DateTime createdAt;
  final DateTime updatedAt;

  RouteGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.destinationCities,
    required this.originCities,
    required this.autoGenerateReverse,
    required this.createdAt,
    required this.updatedAt,
  });

  // Конвертация в/из Firestore
  Map<String, dynamic> toFirestore() { ... }
  factory RouteGroup.fromFirestore(Map<String, dynamic> data, String id) { ... }
}
```

**Firebase коллекция:** `route_groups`

**Пример документа:**
```json
{
  "id": "rostov_region",
  "name": "Ростовская область",
  "description": "Все маршруты в Ростовскую область",
  "basePrice": 8000,
  "destinationCities": ["Ростов", "Таганрог", "Батайск", "Аксай"],
  "originCities": ["Донецк", "Макеевка", "Харцызск", "Енакиево"],
  "autoGenerateReverse": true,
  "createdAt": "2025-12-05T10:00:00Z",
  "updatedAt": "2025-12-05T10:00:00Z"
}
```

---

### 2. Обновленная модель PredefinedRoute

**Файл:** `lib/models/predefined_route.dart` (модифицировать)

**Добавить новые поля:**
```dart
class PredefinedRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 🆕 НОВЫЕ ПОЛЯ:
  final String? groupId;        // ID группы (может быть null для старых маршрутов)
  final bool useGroupPrice;     // Использовать цену из группы
  final bool customPrice;       // Цена переопределена вручную
  final bool isReverse;         // Обратный маршрут (автогенерированный)

  PredefinedRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.groupId,
    this.useGroupPrice = true,
    this.customPrice = false,
    this.isReverse = false,
  });
}
```

**Firebase коллекция:** `predefined_routes` (существующая)

**Пример документа С ГРУППОВОЙ ЦЕНОЙ:**
```json
{
  "fromCity": "Донецк",
  "toCity": "Ростов",
  "price": 8000,
  "groupId": "rostov_region",
  "useGroupPrice": true,
  "customPrice": false,
  "isReverse": false,
  "createdAt": "2025-12-05T10:00:00Z",
  "updatedAt": "2025-12-05T10:00:00Z"
}
```

**Пример документа С ИНДИВИДУАЛЬНОЙ ЦЕНОЙ:**
```json
{
  "fromCity": "Енакиево",
  "toCity": "Ростов",
  "price": 12000,
  "groupId": "rostov_region",
  "useGroupPrice": false,
  "customPrice": true,
  "isReverse": false,
  "createdAt": "2025-12-05T10:00:00Z",
  "updatedAt": "2025-12-05T10:00:00Z"
}
```

---

## 🗂️ Файлы для создания/изменения

### Создать новые файлы:

#### 1. `lib/models/route_group.dart`
- Модель группы маршрутов
- Методы toFirestore/fromFirestore

#### 2. `lib/services/route_group_service.dart`
- CRUD операции для групп
- Получение всех групп
- Обновление цены группы
- Удаление группы

#### 3. `lib/data/route_groups_initializer.dart`
- Начальные данные для групп
- 9 предустановленных групп

#### 4. `lib/features/admin/screens/route_groups_admin_screen.dart`
- Главный экран управления группами
- Список всех групп
- Кнопки добавления/удаления

#### 5. `lib/features/admin/screens/route_group_details_screen.dart`
- Экран детализации группы
- Изменение базовой цены группы
- Список маршрутов в группе
- Индивидуальное изменение маршрутов

#### 6. `lib/features/admin/widgets/route_group_card.dart`
- Виджет карточки группы
- Отображение названия, цены, количества маршрутов

#### 7. `lib/features/admin/widgets/route_in_group_item.dart`
- Виджет маршрута внутри группы
- Отображение цены (групповая/индивидуальная)
- Кнопки управления

---

### Модифицировать существующие файлы:

#### 1. `lib/models/predefined_route.dart`
- Добавить поля: groupId, useGroupPrice, customPrice, isReverse
- Обновить toFirestore/fromFirestore

#### 2. `lib/services/route_management_service.dart`
- Добавить метод updateRoutePrice() - для индивидуального изменения
- Добавить метод updateGroupRoutes() - для группового изменения
- Добавить метод getRoutesByGroup() - получение маршрутов группы
- Добавить метод resetRouteToGroupPrice() - возврат к групповой цене

#### 3. `lib/data/route_initializer.dart`
- Переделать список маршрутов с привязкой к группам
- Убрать дублирующие маршруты
- Добавить groupId к каждому маршруту

#### 4. `lib/features/admin/screens/admin_routes_screen.dart`
- Добавить переключатель "Группы" / "Все маршруты"
- Интеграция с route_groups_admin_screen

---

## 🛠️ Этапы реализации

### Этап 1: Создание моделей и сервисов (1-2 часа)

#### Шаг 1.1: Создать модель RouteGroup
```dart
// lib/models/route_group.dart
class RouteGroup {
  // ... (см. выше)
}
```

#### Шаг 1.2: Обновить модель PredefinedRoute
```dart
// lib/models/predefined_route.dart
// Добавить новые поля
```

#### Шаг 1.3: Создать RouteGroupService
```dart
// lib/services/route_group_service.dart
class RouteGroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Получить все группы
  Future<List<RouteGroup>> getAllGroups();
  
  // Создать группу
  Future<void> createGroup(RouteGroup group);
  
  // Обновить базовую цену группы
  Future<void> updateGroupPrice(String groupId, double newPrice);
  
  // Удалить группу
  Future<void> deleteGroup(String groupId);
  
  // Получить группу по ID
  Future<RouteGroup?> getGroupById(String groupId);
}
```

---

### Этап 2: Определение групп (30 минут)

#### Создать файл `lib/data/route_groups_initializer.dart`

```dart
class RouteGroupsInitializer {
  static List<RouteGroup> get initialGroups {
    final now = DateTime.now();
    
    return [
      // Группа 1: Ростовская область
      RouteGroup(
        id: 'rostov_region',
        name: 'Ростовская область',
        description: 'Маршруты в города Ростовской области',
        basePrice: 8000,
        destinationCities: ['Ростов', 'Таганрог', 'Батайск', 'Аксай'],
        originCities: ['Донецк', 'Макеевка', 'Харцызск', 'Амвросиевка', 
                       'Зугрэс', 'Шахтёрск', 'Торез', 'Иловайский', 
                       'Старобешево', 'Новый свет'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 2: Крымский полуостров
      RouteGroup(
        id: 'crimea',
        name: 'Крымский полуостров',
        description: 'Все маршруты на Крымский полуостров',
        basePrice: 45000,
        destinationCities: [
          'Республика Крым', 'Симферополь', 'Ялта', 'Севастополь',
          'Евпатория', 'Феодосия', 'Керчь', 'Алушта', 'Судак',
          'Балаклава', 'Белогорск', 'Саки', 'Джанкой', 'Красноперекопск'
        ],
        originCities: ['Донецк', 'Макеевка'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 3: Приазовье
      RouteGroup(
        id: 'azov_sea',
        name: 'Приазовье',
        description: 'Маршруты к Азовскому морю',
        basePrice: 7500,
        destinationCities: [
          'Новоазовск', 'Седово', 'Мариуполь', 'Мелекино', 
          'Юрьевка', 'урзуф', 'Бердянск'
        ],
        originCities: ['Донецк'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 4: Черноморское побережье (Краснодарский край)
      RouteGroup(
        id: 'black_sea_coast',
        name: 'Черноморское побережье',
        description: 'Курорты Краснодарского края',
        basePrice: 40000,
        destinationCities: [
          'Анапа', 'Геленджик', 'дивномрское'
        ],
        originCities: ['Донецк', 'Макеевка', 'Харцызск'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 5: Сочи (отдельная группа из-за высокой цены)
      RouteGroup(
        id: 'sochi',
        name: 'Сочи',
        description: 'Маршруты в Сочи и аэропорт',
        basePrice: 50000,
        destinationCities: ['Сочи', 'Сочи аэропорт'],
        originCities: ['Донецк'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 6: Краснодар
      RouteGroup(
        id: 'krasnodar',
        name: 'Краснодар',
        description: 'Маршруты в Краснодар',
        basePrice: 30000,
        destinationCities: ['Краснодар'],
        originCities: [
          'Донецк', 'Макеевка', 'Харцызск', 'Иловайск', 
          'Амвросиевка', 'Пункт пропуска Авило-Успенка'
        ],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 7: Волгоград и Минеральные Воды
      RouteGroup(
        id: 'volgograd_minvody',
        name: 'Волгоград и Минводы',
        description: 'Маршруты в Волгоград и Минеральные Воды',
        basePrice: 40000,
        destinationCities: ['Волгоград', 'минводы'],
        originCities: ['Донецк', 'Харцызск', 'Макеевка'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 8: Ейск
      RouteGroup(
        id: 'yeisk',
        name: 'Ейск',
        description: 'Маршруты в Ейск',
        basePrice: 22000,
        destinationCities: ['Ейск'],
        originCities: ['Донецк', 'Макеевка', 'Енакиево'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
      
      // Группа 9: Дальние города России
      RouteGroup(
        id: 'distant_russia',
        name: 'Дальние города России',
        description: 'Москва, Воронеж и другие дальние города',
        basePrice: 50000,
        destinationCities: ['Москва', 'Воронеж'],
        originCities: ['Донецк'],
        autoGenerateReverse: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
  
  /// Инициализация групп в Firebase
  static Future<void> initializeGroups() async {
    final service = RouteGroupService();
    
    for (final group in initialGroups) {
      await service.createGroup(group);
    }
    
    print('✅ Инициализировано ${initialGroups.length} групп');
  }
}
```

---

### Этап 3: Переделка route_initializer.dart (1 час)

#### Обновить `lib/data/route_initializer.dart`

**Новая структура с группами:**

```dart
class RouteInitializer {
  static List<PredefinedRoute> get initialRoutes {
    final now = DateTime.now();
    
    return [
      // ========================================
      // ГРУППА: Ростовская область (8000₽)
      // ========================================
      
      // Стандартные маршруты (используют групповую цену)
      _createRoute('Донецк', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Харцызск', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Амвросиевка', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Зугрэс', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Шахтёрск', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Торез', 'Ростov', 8000, 'rostov_region', now),
      _createRoute('Иловайский', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Старобешево', 'Ростов', 8000, 'rostov_region', now),
      _createRoute('Новый свет', 'Ростов', 8000, 'rostov_region', now),
      
      // Исключения (индивидуальные цены)
      _createRouteWithCustomPrice('Еленовка', 'Ростов', 10000, 'rostov_region', now),
      _createRouteWithCustomPrice('Мариуполь', 'Ростов', 10000, 'rostov_region', now),
      _createRouteWithCustomPrice('Енакиево', 'Ростов', 12000, 'rostov_region', now),
      _createRouteWithCustomPrice('Докучаевск', 'Ростов', 12000, 'rostov_region', now),
      _createRouteWithCustomPrice('Ясиноватая', 'Ростов', 12000, 'rostov_region', now),
      _createRouteWithCustomPrice('Волноваха', 'Ростов', 13000, 'rostov_region', now),
      
      // Пригороды Ростова
      _createRoute('Донецк', 'Батайск', 10000, 'rostov_region', now),
      _createRoute('Донецк', 'Аксай', 10000, 'rostov_region', now),
      
      // ========================================
      // ГРУППА: Крымский полуостров (45000₽)
      // ========================================
      
      _createRoute('Донецк', 'Республика Крым', 45000, 'crimea', now),
      _createRoute('Донецк', 'Симферополь', 45000, 'crimea', now),
      _createRoute('Донецк', 'Ялта', 45000, 'crimea', now),
      _createRoute('Донецк', 'Севастополь', 45000, 'crimea', now),
      _createRoute('Донецк', 'Евпатория', 45000, 'crimea', now),
      _createRoute('Донецк', 'Феодосия', 45000, 'crimea', now),
      _createRoute('Донецк', 'Керчь', 45000, 'crimea', now),
      _createRoute('Донецк', 'Алушта', 45000, 'crimea', now),
      _createRoute('Донецк', 'Судак', 45000, 'crimea', now),
      _createRoute('Донецк', 'Балаклава', 45000, 'crimea', now),
      _createRoute('Донецк', 'Белогорск', 45000, 'crimea', now),
      _createRoute('Донецк', 'Саки', 45000, 'crimea', now),
      _createRoute('Донецк', 'Джанкой', 45000, 'crimea', now),
      _createRoute('Донецк', 'Красноперекопск', 45000, 'crimea', now),
      
      // ========================================
      // ГРУППА: Приазовье (7500₽)
      // ========================================
      
      _createRoute('Донецк', 'Новоазовск', 7000, 'azov_sea', now),
      _createRoute('Донецк', 'Седово', 7000, 'azov_sea', now),
      _createRoute('Донецк', 'Мариуполь', 7000, 'azov_sea', now),
      _createRoute('Донецк', 'Мелекино', 8000, 'azov_sea', now),
      _createRoute('Донецк', 'Юрьевка', 8500, 'azov_sea', now),
      _createRoute('Донецк', 'урзуф', 8500, 'azov_sea', now),
      _createRouteWithCustomPrice('Донецк', 'Бердянск', 12000, 'azov_sea', now),
      
      // ========================================
      // ГРУППА: Черноморское побережье (40000₽)
      // ========================================
      
      _createRoute('Донецк', 'Анапа', 40000, 'black_sea_coast', now),
      _createRoute('Донецк', 'Геленджик', 40000, 'black_sea_coast', now),
      _createRoute('Донецк', 'дивномрское', 40000, 'black_sea_coast', now),
      
      // ========================================
      // ГРУППА: Сочи (50000₽)
      // ========================================
      
      _createRoute('Донецк', 'Сочи', 50000, 'sochi', now),
      _createRouteWithCustomPrice('Донецк', 'Сочи аэропорт', 55000, 'sochi', now),
      
      // ========================================
      // ГРУППА: Краснодар (30000₽)
      // ========================================
      
      _createRoute('Донецк', 'Краснодар', 30000, 'krasnodar', now),
      _createRoute('Макеевка', 'Краснодар', 30000, 'krasnodar', now),
      _createRoute('Харцызск', 'Краснодар', 30000, 'krasnodar', now),
      _createRoute('Иловайск', 'Краснодар', 30000, 'krasnodar', now),
      _createRoute('Амвросиевка', 'Краснодар', 30000, 'krasnodar', now),
      _createRoute('Пункт пропуска Авило-Успенка', 'Краснодар', 30000, 'krasnodar', now),
      
      // ========================================
      // ГРУППА: Волгоград и Минводы (40000₽)
      // ========================================
      
      _createRoute('Донецк', 'Волгоград', 40000, 'volgograd_minvody', now),
      _createRoute('Донецк', 'минводы', 40000, 'volgograd_minvody', now),
      _createRoute('Харцызск', 'Волгоград', 40000, 'volgograd_minvody', now),
      _createRoute('Харцызск', 'минводы', 40000, 'volgograd_minvody', now),
      _createRoute('Макеевка', 'Волгоград', 40000, 'volgograd_minvody', now),
      _createRoute('Макеевка', 'минводы', 40000, 'volgograd_minvody', now),
      
      // ========================================
      // ГРУППА: Ейск (22000₽)
      // ========================================
      
      _createRoute('Донецк', 'Ейск', 22000, 'yeisk', now),
      _createRoute('Макеевка', 'Ейск', 22000, 'yeisk', now),
      _createRouteWithCustomPrice('Енакиево', 'Ейск', 24000, 'yeisk', now),
      
      // ========================================
      // ГРУППА: Дальние города России (50000₽+)
      // ========================================
      
      _createRouteWithCustomPrice('Донецк', 'Москва', 77000, 'distant_russia', now),
      _createRoute('Донецк', 'Воронеж', 50000, 'distant_russia', now),
    ];
  }
  
  /// Создать маршрут с групповой ценой
  static PredefinedRoute _createRoute(
    String from,
    String to,
    double price,
    String groupId,
    DateTime now,
  ) {
    return PredefinedRoute(
      id: '',
      fromCity: from,
      toCity: to,
      price: price,
      groupId: groupId,
      useGroupPrice: true,      // Использует цену группы
      customPrice: false,        // НЕ переопределена
      isReverse: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Создать маршрут с индивидуальной ценой (исключение)
  static PredefinedRoute _createRouteWithCustomPrice(
    String from,
    String to,
    double price,
    String groupId,
    DateTime now,
  ) {
    return PredefinedRoute(
      id: '',
      fromCity: from,
      toCity: to,
      price: price,
      groupId: groupId,
      useGroupPrice: false,     // НЕ использует цену группы
      customPrice: true,         // Переопределена вручную
      isReverse: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // ... остальные методы
}
```

---

### Этап 4: Обновление RouteManagementService (1 час)

#### Добавить методы в `lib/services/route_management_service.dart`

```dart
class RouteManagementService {
  // Существующие методы...
  
  // ========================================
  // НОВЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С ГРУППАМИ
  // ========================================
  
  /// Получить все маршруты группы
  Future<List<PredefinedRoute>> getRoutesByGroup(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('groupId', isEqualTo: groupId)
          .get();
      
      return snapshot.docs
          .map((doc) => PredefinedRoute.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Ошибка получения маршрутов группы: $e');
      return [];
    }
  }
  
  /// Обновить цены всех маршрутов группы
  Future<void> updateGroupRoutes(String groupId, double newPrice) async {
    try {
      // Получаем все маршруты группы
      final routes = await getRoutesByGroup(groupId);
      
      // Обновляем только те, которые используют групповую цену
      final batch = _firestore.batch();
      int updatedCount = 0;
      
      for (final route in routes) {
        if (route.useGroupPrice && !route.customPrice) {
          final docRef = _firestore.collection(_collectionPath).doc(route.id);
          batch.update(docRef, {
            'price': newPrice,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updatedCount++;
        }
      }
      
      await batch.commit();
      print('✅ Обновлено $updatedCount маршрутов в группе $groupId');
      
    } catch (e) {
      print('❌ Ошибка обновления маршрутов группы: $e');
      rethrow;
    }
  }
  
  /// Изменить цену конкретного маршрута (индивидуально)
  Future<void> updateRoutePrice(String routeId, double newPrice) async {
    try {
      await _firestore.collection(_collectionPath).doc(routeId).update({
        'price': newPrice,
        'useGroupPrice': false,
        'customPrice': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Цена маршрута $routeId обновлена на $newPrice₽');
      
    } catch (e) {
      print('❌ Ошибка обновления цены маршрута: $e');
      rethrow;
    }
  }
  
  /// Вернуть маршрут к групповой цене
  Future<void> resetRouteToGroupPrice(String routeId, double groupPrice) async {
    try {
      await _firestore.collection(_collectionPath).doc(routeId).update({
        'price': groupPrice,
        'useGroupPrice': true,
        'customPrice': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Маршрут $routeId возвращён к групповой цене $groupPrice₽');
      
    } catch (e) {
      print('❌ Ошибка сброса цены маршрута: $e');
      rethrow;
    }
  }
  
  /// Создать обратный маршрут
  Future<void> createReverseRoute(PredefinedRoute originalRoute) async {
    try {
      final reverseRoute = PredefinedRoute(
        id: '',
        fromCity: originalRoute.toCity,
        toCity: originalRoute.fromCity,
        price: originalRoute.price,
        groupId: originalRoute.groupId,
        useGroupPrice: originalRoute.useGroupPrice,
        customPrice: originalRoute.customPrice,
        isReverse: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await addRoute(
        fromCity: reverseRoute.fromCity,
        toCity: reverseRoute.toCity,
        price: reverseRoute.price,
        groupId: reverseRoute.groupId,
        useGroupPrice: reverseRoute.useGroupPrice,
        customPrice: reverseRoute.customPrice,
        isReverse: true,
      );
      
      print('✅ Создан обратный маршрут: ${reverseRoute.fromCity} → ${reverseRoute.toCity}');
      
    } catch (e) {
      print('❌ Ошибка создания обратного маршрута: $e');
      rethrow;
    }
  }
}
```

---

### Этап 5: UI Админ-панели (2-3 часа)

#### 5.1. Главный экран групп

**Файл:** `lib/features/admin/screens/route_groups_admin_screen.dart`

```dart
class RouteGroupsAdminScreen extends StatefulWidget {
  @override
  State<RouteGroupsAdminScreen> createState() => _RouteGroupsAdminScreenState();
}

class _RouteGroupsAdminScreenState extends State<RouteGroupsAdminScreen> {
  final RouteGroupService _groupService = RouteGroupService();
  List<RouteGroup> _groups = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }
  
  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _groupService.getAllGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка загрузки групп: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Группы маршрутов'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.add),
          onPressed: _addGroup,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? Center(child: CupertinoActivityIndicator())
            : ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return RouteGroupCard(
                    group: group,
                    onTap: () => _openGroupDetails(group),
                    onDelete: () => _deleteGroup(group),
                  );
                },
              ),
      ),
    );
  }
  
  void _openGroupDetails(RouteGroup group) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => RouteGroupDetailsScreen(group: group),
      ),
    );
  }
  
  // Остальные методы...
}
```

#### 5.2. Экран детализации группы

**Файл:** `lib/features/admin/screens/route_group_details_screen.dart`

```dart
class RouteGroupDetailsScreen extends StatefulWidget {
  final RouteGroup group;
  
  const RouteGroupDetailsScreen({required this.group});
  
  @override
  State<RouteGroupDetailsScreen> createState() => _RouteGroupDetailsScreenState();
}

class _RouteGroupDetailsScreenState extends State<RouteGroupDetailsScreen> {
  final RouteManagementService _routeService = RouteManagementService.instance;
  final TextEditingController _priceController = TextEditingController();
  List<PredefinedRoute> _routes = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _priceController.text = widget.group.basePrice.toStringAsFixed(0);
    _loadRoutes();
  }
  
  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final routes = await _routeService.getRoutesByGroup(widget.group.id);
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка загрузки маршрутов: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.group.name),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Блок изменения базовой цены группы
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Базовая цена группы',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            placeholder: 'Цена в рублях',
                            suffix: Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Text('₽'),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        CupertinoButton.filled(
                          child: Text('Применить ко всем'),
                          onPressed: _applyGroupPrice,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Изменит цену у всех маршрутов с групповой ценой',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Заголовок списка маршрутов
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Маршруты в группе (${_routes.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Список маршрутов
            _isLoading
                ? SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final route = _routes[index];
                        return RouteInGroupItem(
                          route: route,
                          group: widget.group,
                          onPriceChanged: () => _loadRoutes(),
                        );
                      },
                      childCount: _routes.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _applyGroupPrice() async {
    final newPriceText = _priceController.text.trim();
    final newPrice = double.tryParse(newPriceText);
    
    if (newPrice == null || newPrice <= 0) {
      _showError('Введите корректную цену');
      return;
    }
    
    // Показываем подтверждение
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Изменить цены?'),
        content: Text(
          'Это изменит цену у всех маршрутов с групповой ценой.\n\n'
          'Маршруты с индивидуальной ценой не изменятся.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Применить'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _routeService.updateGroupRoutes(widget.group.id, newPrice);
        _showSuccess('Цены обновлены!');
        _loadRoutes();
      } catch (e) {
        _showError('Ошибка: $e');
      }
    }
  }
  
  // Остальные методы...
}
```

#### 5.3. Виджет маршрута в группе

**Файл:** `lib/features/admin/widgets/route_in_group_item.dart`

```dart
class RouteInGroupItem extends StatelessWidget {
  final PredefinedRoute route;
  final RouteGroup group;
  final VoidCallback onPriceChanged;
  
  const RouteInGroupItem({
    required this.route,
    required this.group,
    required this.onPriceChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final hasCustomPrice = route.customPrice;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasCustomPrice 
              ? CupertinoColors.systemOrange 
              : CupertinoColors.systemGrey5,
        ),
      ),
      child: Row(
        children: [
          // Иконка
          Icon(
            hasCustomPrice 
                ? CupertinoIcons.exclamationmark_circle 
                : CupertinoIcons.checkmark_circle,
            color: hasCustomPrice 
                ? CupertinoColors.systemOrange 
                : CupertinoColors.systemGreen,
            size: 20,
          ),
          SizedBox(width: 12),
          
          // Название маршрута
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${route.fromCity} → ${route.toCity}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  hasCustomPrice 
                      ? 'Индивидуальная цена' 
                      : 'Цена из группы',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasCustomPrice 
                        ? CupertinoColors.systemOrange 
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          
          // Цена
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${route.price.toInt()} ₽',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Меню действий
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.ellipsis_vertical),
            onPressed: () => _showActionSheet(context),
          ),
        ],
      ),
    );
  }
  
  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('${route.fromCity} → ${route.toCity}'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Изменить цену'),
            onPressed: () {
              Navigator.pop(context);
              _showEditPriceDialog(context);
            },
          ),
          if (route.customPrice)
            CupertinoActionSheetAction(
              child: Text('Вернуть цену группы (${group.basePrice.toInt()}₽)'),
              onPressed: () {
                Navigator.pop(context);
                _resetToGroupPrice(context);
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: Text('Отмена'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
  
  void _showEditPriceDialog(BuildContext context) {
    final controller = TextEditingController(
      text: route.price.toStringAsFixed(0),
    );
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Изменить цену'),
        content: Column(
          children: [
            SizedBox(height: 12),
            Text('${route.fromCity} → ${route.toCity}'),
            SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              placeholder: 'Цена в рублях',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Сохранить'),
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                try {
                  await RouteManagementService.instance
                      .updateRoutePrice(route.id, newPrice);
                  Navigator.pop(context);
                  onPriceChanged();
                } catch (e) {
                  // Показать ошибку
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _resetToGroupPrice(BuildContext context) async {
    try {
      await RouteManagementService.instance
          .resetRouteToGroupPrice(route.id, group.basePrice);
      onPriceChanged();
    } catch (e) {
      // Показать ошибку
    }
  }
}
```

---

## 🔄 Миграция существующих данных

### Стратегия миграции:

#### Вариант 1: Автоматическая миграция (рекомендуется)

```dart
class RouteMigrationService {
  /// Мигрировать все существующие маршруты в группы
  static Future<void> migrateToGroups() async {
    print('🔄 Начало миграции маршрутов в группы...');
    
    final routeService = RouteManagementService.instance;
    final routes = await routeService.getAllRoutes();
    
    int migrated = 0;
    
    for (final route in routes) {
      // Пропускаем уже мигрированные
      if (route.groupId != null) continue;
      
      // Определяем группу по городу назначения
      final groupId = _determineGroupId(route.toCity);
      
      if (groupId != null) {
        // Обновляем маршрут
        await _updateRouteWithGroup(route, groupId);
        migrated++;
      }
    }
    
    print('✅ Мигрировано $migrated маршрутов');
  }
  
  static String? _determineGroupId(String cityName) {
    final city = cityName.toLowerCase();
    
    // Ростовская область
    if (city.contains('ростов') || city == 'таганрог' || 
        city == 'батайск' || city == 'аксай') {
      return 'rostov_region';
    }
    
    // Крым
    if (city.contains('крым') || city == 'симферополь' || 
        city == 'ялта' || city == 'севастополь' || 
        city == 'евпатория' || city == 'феодосия' ||
        city == 'керчь' || city == 'алушта' || city == 'судак') {
      return 'crimea';
    }
    
    // Приазовье
    if (city == 'новоазовск' || city == 'седово' || 
        city == 'мариуполь' || city == 'мелекино' ||
        city == 'юрьевка' || city == 'урзуф' || city == 'бердянск') {
      return 'azov_sea';
    }
    
    // Краснодар
    if (city == 'краснодар') {
      return 'krasnodar';
    }
    
    // Сочи
    if (city.contains('сочи')) {
      return 'sochi';
    }
    
    // Черноморское побережье
    if (city == 'анапа' || city == 'геленджик' || city == 'дивномрское') {
      return 'black_sea_coast';
    }
    
    // Волгоград и Минводы
    if (city == 'волгоград' || city == 'минводы') {
      return 'volgograd_minvody';
    }
    
    // Ейск
    if (city == 'ейск') {
      return 'yeisk';
    }
    
    // Дальние города
    if (city == 'москва' || city == 'воронеж') {
      return 'distant_russia';
    }
    
    return null;
  }
  
  static Future<void> _updateRouteWithGroup(
    PredefinedRoute route, 
    String groupId,
  ) async {
    // Обновляем в Firebase
    await FirebaseFirestore.instance
        .collection('predefined_routes')
        .doc(route.id)
        .update({
      'groupId': groupId,
      'useGroupPrice': true,
      'customPrice': false,
      'isReverse': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
```

---

## 📝 Чек-лист реализации

### Этап 1: Модели и сервисы
- [ ] Создать `lib/models/route_group.dart`
- [ ] Обновить `lib/models/predefined_route.dart`
- [ ] Создать `lib/services/route_group_service.dart`
- [ ] Обновить `lib/services/route_management_service.dart`

### Этап 2: Данные
- [ ] Создать `lib/data/route_groups_initializer.dart`
- [ ] Обновить `lib/data/route_initializer.dart`
- [ ] Создать скрипт миграции

### Этап 3: UI
- [ ] Создать `lib/features/admin/screens/route_groups_admin_screen.dart`
- [ ] Создать `lib/features/admin/screens/route_group_details_screen.dart`
- [ ] Создать `lib/features/admin/widgets/route_group_card.dart`
- [ ] Создать `lib/features/admin/widgets/route_in_group_item.dart`
- [ ] Обновить `lib/features/admin/screens/admin_routes_screen.dart`

### Этап 4: Тестирование
- [ ] Инициализация групп в Firebase
- [ ] Миграция существующих маршрутов
- [ ] Тестирование группового изменения цен
- [ ] Тестирование индивидуального изменения цен
- [ ] Тестирование возврата к групповой цене
- [ ] Тестирование создания обратных маршрутов

---

## 🎯 Итоговый результат

После реализации диспетчер сможет:

1. **Видеть группы маршрутов** с базовой ценой
2. **Изменять цену группы** одной кнопкой → обновляются все маршруты
3. **Изменять цену отдельного маршрута** → маршрут помечается как исключение
4. **Видеть статус маршрутов**:
   - 🟢 Используют групповую цену
   - 🟠 Имеют индивидуальную цену
5. **Возвращать маршрут к групповой цене** одной кнопкой
6. **Автоматически создавать обратные маршруты**

---

## ⏱️ Оценка времени реализации

| Этап | Время |
|------|-------|
| Модели и сервисы | 1-2 часа |
| Определение групп | 30 минут |
| Переделка route_initializer | 1 час |
| Обновление RouteManagementService | 1 час |
| UI админ-панели | 2-3 часа |
| Миграция данных | 1 час |
| Тестирование | 1-2 часа |
| **ИТОГО** | **7-10 часов** |

---

## 📞 Следующие шаги

1. **Утверждение структуры групп** ✅
2. **Согласование UI** ✅
3. **Начало реализации** ⏳
4. **Поэтапное тестирование** ⏳
5. **Деплой и миграция** ⏳
