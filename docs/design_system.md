# Система дизайна приложения Time to Travel

## Обзор

Приложение использует Cupertino (iOS-style) дизайн с кастомной темой и фирменными цветами компании Time to Travel. Дизайн адаптирован для работы как на iOS, так и на Android.

---

## 🎨 Цветовая схема

### Фирменные цвета

#### Основной красный (Primary Red)
```dart
Color(0xFFE53E3E) // #E53E3E - Ярко-красный
```
- **Использование**: 
  - NavigationBar экрана профиля
  - Акцентные элементы (кнопки, иконки)
  - Цены и важная информация
  - Активные состояния

#### Вариации красного
```dart
Color(0xFFC53030) // #C53030 - Тёмно-красный (primaryDark)
Color(0xFFFC8181) // #FC8181 - Светло-красный (primaryLight)
```

### Системные цвета

#### Тёмная тема (основная)

**Фоны:**
```dart
systemBackground: Color(0xFF1A1A1A)              // #1A1A1A - Основной фон
secondarySystemBackground: Color(0xFF2D2D2D)     // #2D2D2D - NavigationBar, карточки
tertiarySystemBackground: Color(0xFF404040)      // #404040 - Третичные элементы
```

**Текст:**
```dart
label: Color(0xFFFFFFFF)                         // Основной текст (белый)
secondaryLabel: Color(0x99FFFFFF)                // Вторичный текст (60% opacity)
tertiaryLabel: Color(0x4DFFFFFF)                 // Третичный текст (30% opacity)
```

**Границы и разделители:**
```dart
separator: Color(0xFF555555)                     // #555555 - Границы элементов
```

#### Светлая тема

**Фоны:**
```dart
systemBackground: Color(0xFFFFFFFF)              // Белый основной фон
secondarySystemBackground: Color(0xFFF2F2F7)     // Светло-серый
tertiarySystemBackground: Color(0xFFFFFFFF)      // Белый
```

**Текст:**
```dart
label: Color(0xFF000000)                         // Чёрный
secondaryLabel: Color(0x99000000)                // 60% чёрного
tertiaryLabel: Color(0x4D000000)                 // 30% чёрного
```

### Служебные цвета

```dart
success: Color(0xFF38A169)     // Зелёный - успешные операции
warning: Color(0xFFED8936)     // Оранжевый - предупреждения
danger: Color(0xFFE53E3E)      // Красный - ошибки, опасные действия
accent: Color(0xFFED8936)      // Оранжевый акцент
```

---

## 📱 NavigationBar (Шапки экранов)

### Принцип работы

**Проблема:** Стандартный `CupertinoNavigationBar` **игнорирует** параметр `backgroundColor` на Android.

**Решение:** Используем кастомный виджет `CustomNavigationBar` который работает на всех платформах.

### Цветовая схема NavigationBar

#### 🟥 Красная шапка (Профиль)
```dart
CustomNavigationBar(
  title: 'Профиль',
  backgroundColor: theme.primary, // #E53E3E - Красный
  textColor: CupertinoColors.white,
)
```
**Где используется:**
- Экран профиля (`profile_screen.dart`)

#### ⬛ Серая шапка (Все остальные экраны)
```dart
CustomNavigationBar(
  title: 'Название экрана',
  // backgroundColor по умолчанию = theme.secondarySystemBackground (#2D2D2D)
)
```
**Где используется:**
- Экран бронирования (`booking_screen.dart`)
- Мои заказы (`orders_screen.dart`)
- Отслеживание (`tracking_screen.dart`)
- Выбор маршрута (`route_selection_screen.dart`)
- Все другие экраны приложения

### Структура CustomNavigationBar

```dart
CustomNavigationBar(
  title: 'Заголовок',                    // Обязательно
  backgroundColor: theme.primary,        // Опционально (по умолчанию серый)
  textColor: CupertinoColors.white,      // Опционально (по умолчанию theme.label)
  leading: Widget,                       // Опционально (кнопка "Назад" и т.д.)
  trailing: Widget,                      // Опционально (кнопки справа)
)
```

**Пример с кнопками:**
```dart
CustomNavigationBar(
  title: 'Мои заказы',
  trailing: CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: _loadData,
    child: Icon(CupertinoIcons.refresh, color: theme.primary),
  ),
)
```

---

## 🎭 Компоненты интерфейса

### TabBar (Нижняя навигация)

**Цвет фона:** `theme.secondarySystemBackground` (#2D2D2D) - совпадает с цветом NavigationBar

```dart
CupertinoTabBar(
  backgroundColor: theme.secondarySystemBackground,
  activeColor: theme.primary,           // Активная вкладка - красная
  inactiveColor: theme.secondaryLabel,  // Неактивная - серая
)
```

### Кнопки

#### Основная кнопка (Primary)
```dart
CupertinoButton(
  color: theme.primary,               // Красный фон
  child: Text(
    'Текст кнопки',
    style: TextStyle(
      color: CupertinoColors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

#### Вторичная кнопка
```dart
CupertinoButton(
  color: theme.secondarySystemBackground,
  child: Text(
    'Текст кнопки',
    style: TextStyle(color: theme.label),
  ),
)
```

#### Опасная кнопка (Destructive)
```dart
CupertinoButton(
  color: CupertinoColors.systemRed,
  child: Text('Выйти из аккаунта'),
)
```

### Карточки (Cards)

**Стандартная карточка:**
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: theme.secondarySystemBackground,     // Серый фон
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: theme.separator.withOpacity(0.2),  // Тонкая граница
    ),
  ),
  child: // содержимое
)
```

**Активная/выбранная карточка:**
```dart
border: Border.all(
  color: theme.primary,    // Красная граница
  width: 2,                // Толще
)
```

### Поля ввода

```dart
CupertinoTextField(
  placeholder: 'Подсказка',
  style: TextStyle(color: theme.label),
  placeholderStyle: TextStyle(
    color: theme.secondaryLabel.withOpacity(0.5),
  ),
  decoration: BoxDecoration(
    color: theme.secondarySystemBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: theme.separator.withOpacity(0.2)),
  ),
)
```

---

## 📐 Размеры и отступы

### Стандартные значения

**Радиусы скругления:**
- Карточки: `12px`
- Кнопки: `8-12px`
- Маленькие элементы: `6-8px`

**Отступы (padding):**
- Контейнеры: `16px`
- Карточки: `16-20px`
- Списки: `16px` по горизонтали

**Промежутки (spacing):**
- Между секциями: `24-32px`
- Между элементами: `12-16px`
- Маленькие промежутки: `8px`

**Высоты:**
- NavigationBar: `44px`
- Кнопки: `44-50px`
- TabBar: `50px`

---

## 🔤 Типографика

### Размеры шрифтов

```dart
// Заголовки
fontSize: 24, fontWeight: FontWeight.bold      // H1 - Главные заголовки
fontSize: 20, fontWeight: FontWeight.w600      // H2 - Подзаголовки
fontSize: 18, fontWeight: FontWeight.w600      // H3 - Названия секций

// Основной текст
fontSize: 17, fontWeight: FontWeight.w600      // NavigationBar
fontSize: 16, fontWeight: FontWeight.normal    // Основной текст
fontSize: 14, fontWeight: FontWeight.normal    // Вторичный текст

// Мелкий текст
fontSize: 12, fontWeight: FontWeight.normal    // Подписи, метки
```

### Цвета текста

```dart
TextStyle(color: theme.label)              // Основной текст
TextStyle(color: theme.secondaryLabel)     // Вторичный текст
TextStyle(color: theme.tertiaryLabel)      // Третичный/слабый текст
TextStyle(color: theme.primary)            // Акцентный текст (красный)
```

---

## 🎯 Иконки

### Основные иконки (Cupertino)

```dart
CupertinoIcons.car_fill              // Машина/транспорт
CupertinoIcons.person_fill           // Профиль
CupertinoIcons.list_bullet           // Список заказов
CupertinoIcons.location_fill         // Локация/отслеживание
CupertinoIcons.calendar              // Календарь/дата
CupertinoIcons.clock                 // Время
CupertinoIcons.bag                   // Багаж
CupertinoIcons.paw                   // Животные
CupertinoIcons.refresh               // Обновить
CupertinoIcons.settings              // Настройки
CupertinoIcons.back                  // Назад
CupertinoIcons.chevron_right         // Стрелка вправо
```

### Цвета иконок

```dart
Icon(icon, color: theme.primary)           // Акцентные иконки (красные)
Icon(icon, color: theme.label)             // Основные иконки
Icon(icon, color: theme.secondaryLabel)    // Вторичные иконки
```

---

## 📋 Статусы заказов

### Цветовая индикация

```dart
BookingStatus.pending:      CupertinoColors.systemOrange  // Ожидает
BookingStatus.confirmed:    CupertinoColors.systemBlue    // Подтверждён
BookingStatus.inProgress:   CupertinoColors.systemGreen   // В пути
BookingStatus.completed:    CupertinoColors.systemGreen   // Завершён
BookingStatus.cancelled:    CupertinoColors.systemRed     // Отменён
```

---

## 🛠 Как использовать тему в коде

### Получение темы

```dart
@override
Widget build(BuildContext context) {
  final themeManager = context.themeManager;
  final theme = themeManager.currentTheme;
  
  return Container(
    color: theme.systemBackground,
    child: Text(
      'Текст',
      style: TextStyle(color: theme.label),
    ),
  );
}
```

### Доступ к цветам

```dart
theme.primary                    // Красный фирменный
theme.systemBackground           // Основной фон
theme.secondarySystemBackground  // Вторичный фон (NavigationBar, карточки)
theme.label                      // Цвет основного текста
theme.secondaryLabel             // Цвет вторичного текста
theme.separator                  // Цвет границ/разделителей
theme.systemRed                  // Системный красный (ошибки)
```

---

## 📁 Файлы темы

### Основные файлы

1. **`lib/theme/colors.dart`** - Определения всех цветов
2. **`lib/theme/app_theme.dart`** - Класс `CustomTheme` и конфигурация тем
3. **`lib/theme/theme_manager.dart`** - Управление темами (светлая/тёмная)
4. **`lib/widgets/custom_navigation_bar.dart`** - Кастомный NavigationBar

### Структура CustomTheme

```dart
class CustomTheme {
  final bool isDark;
  
  // Основные цвета
  final Color primary;
  final Color systemBackground;
  final Color secondarySystemBackground;
  final Color tertiarySystemBackground;
  
  // Текст
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  
  // Границы
  final Color separator;
  
  // Системные
  final Color systemRed;
  final Color systemBlue;
  final Color systemGreen;
  // ... и другие
}
```

---

## ✨ Лучшие практики

### NavigationBar

✅ **ПРАВИЛЬНО:**
```dart
// Использовать CustomNavigationBar для всех экранов
CustomNavigationBar(
  title: 'Экран',
  backgroundColor: theme.primary, // Только для профиля
)
```

❌ **НЕПРАВИЛЬНО:**
```dart
// НЕ использовать CupertinoNavigationBar с backgroundColor
CupertinoNavigationBar(
  backgroundColor: theme.primary, // Не работает на Android!
  middle: Text('Экран'),
)
```

### Цвета

✅ **ПРАВИЛЬНО:**
```dart
// Использовать цвета из темы
Container(color: theme.secondarySystemBackground)
Text('Текст', style: TextStyle(color: theme.label))
```

❌ **НЕПРАВИЛЬНО:**
```dart
// НЕ использовать хардкод цветов
Container(color: Color(0xFF2D2D2D))
Text('Текст', style: TextStyle(color: Colors.white))
```

### Консистентность

1. **Все NavigationBar серые**, кроме профиля (красный)
2. **TabBar серый** - тот же цвет что и NavigationBar
3. **Карточки** всегда на `secondarySystemBackground`
4. **Границы** всегда с `separator` цветом и opacity 0.2
5. **Скругления** карточек - 12px

---

## 🎨 Визуальная иерархия

### Уровни важности

**Уровень 1 (Самый важный):**
- Цвет: `theme.primary` (красный)
- Использование: Основные кнопки, цены, активные элементы

**Уровень 2 (Важный):**
- Цвет: `theme.label` (белый/чёрный)
- Использование: Заголовки, основной текст

**Уровень 3 (Средний):**
- Цвет: `theme.secondaryLabel` (60% opacity)
- Использование: Вторичный текст, подписи

**Уровень 4 (Низкий):**
- Цвет: `theme.tertiaryLabel` (30% opacity)
- Использование: Плейсхолдеры, неактивные элементы

---

## 📱 Примеры экранов

### Профиль
- NavigationBar: 🟥 Красный (#E53E3E)
- Фон: Тёмно-серый (#1A1A1A)
- Карточки: Серые (#2D2D2D)

### Мои заказы
- NavigationBar: ⬛ Тёмно-серый (#2D2D2D)
- Фон: Тёмно-серый (#1A1A1A)
- Карточки: Серые (#2D2D2D)

### Бронирование
- NavigationBar: ⬛ Тёмно-серый (#2D2D2D)
- Фон: Тёмно-серый (#1A1A1A)
- Кнопки типов поездки: Карточки (#2D2D2D)
- Основная кнопка: Красная (#E53E3E)

---

## 🔄 Обновление дизайна

### Изменение цвета NavigationBar

1. Открыть нужный экран (например, `orders_screen.dart`)
2. Найти `CustomNavigationBar`
3. Добавить/изменить параметр `backgroundColor`:

```dart
CustomNavigationBar(
  title: 'Заголовок',
  backgroundColor: theme.primary, // Красный
  textColor: CupertinoColors.white,
)
```

### Добавление нового цвета

1. Открыть `lib/theme/colors.dart`
2. Добавить константу:
```dart
static const Color newColor = Color(0xFFHEXCODE);
```

3. Добавить в `CustomTheme` в `app_theme.dart`:
```dart
final Color newColor;
```

4. Инициализировать в конструкторе темы

---

## 📝 Changelog

**01.10.2025:**
- Внедрён `CustomNavigationBar` для всех экранов
- Все NavigationBar теперь серые (#2D2D2D), кроме профиля
- Профиль имеет красный NavigationBar (#E53E3E)
- Решена проблема с игнорированием backgroundColor на Android
- **ИСПРАВЛЕНО**: Заменены все `ListTile` на кастомные Cupertino-виджеты (багаж, животные, транспорт)
  - `ListTile` вызывал ошибку "No Material widget found" на экранах индивидуального и группового бронирования
  - Теперь используются `CupertinoButton` с Row/Column для совместимости

---

## 📞 Контакты

При возникновении вопросов по дизайн-системе обращайтесь к этому документу.

Файл обновлён: **01 октября 2025 г.**

## ⚠️ Важные замечания

### ListTile НЕ совместим с Cupertino

**Проблема:** `ListTile` - это Material Design виджет, который **требует** родительский `Material` widget. В Cupertino приложении это вызывает ошибку:
```
No Material widget found.
ListTile widgets require a Material widget ancestor
```

**Решение:** Использовать кастомные Cupertino-стиль виджеты вместо `ListTile`.

❌ **НЕПРАВИЛЬНО:**
```dart
ListTile(
  leading: Icon(CupertinoIcons.bag),
  title: Text('Заголовок'),
  subtitle: Text('Подзаголовок'),
  trailing: Icon(CupertinoIcons.chevron_right),
  onTap: () => {},
)
```

✅ **ПРАВИЛЬНО:**
```dart
CupertinoButton(
  padding: EdgeInsets.zero,
  onPressed: () => {},
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Icon(CupertinoIcons.bag, color: theme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заголовок',
                style: TextStyle(color: theme.label, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                'Подзаголовок',
                style: TextStyle(color: theme.secondaryLabel, fontSize: 14),
              ),
            ],
          ),
        ),
        Icon(
          CupertinoIcons.chevron_right,
          color: theme.secondaryLabel,
          size: 20,
        ),
      ],
    ),
  ),
)
```

---
