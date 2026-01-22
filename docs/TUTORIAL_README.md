# Система обучения Time to Travel

## Описание

Встроенная система обучения помогает новым пользователям освоить основные функции приложения Time to Travel. Обучение реализовано с использованием библиотеки `showcaseview` и показывает пошаговые инструкции для каждого элемента интерфейса.

## Возможности

1. **Автоматический запуск** - обучение стартует при первом входе пользователя
2. **Интерактивные подсказки** - красивые всплывающие подсказки с описанием каждого элемента
3. **Пошаговое прохождение** - логическая последовательность изучения функций
4. **Отключение** - пользователь может пропустить или отключить обучение
5. **Повторный запуск** - возможность перезапустить обучение из настроек

## Архитектура

### Файлы системы обучения

- `lib/tutorial/tutorial_manager.dart` - главный менеджер обучения
- `lib/features/main_screen.dart` - интеграция в основной экран
- `lib/features/search/widgets/search_fields_panel.dart` - поля поиска с обучением

### Ключевые компоненты

#### TutorialManager
```dart
class TutorialManager {
  static void startTutorial(BuildContext context);
  static Future<void> resetTutorial();
  static Future<bool> shouldShowTutorial();
}
```

#### Showcase виджеты
Каждый элемент интерфейса обернут в `Showcase`:
- Поле "Откуда" 
- Поле "Куда"
- Кнопка "Заказать"
- Кнопка геолокации
- Карта

## Интеграция

### 1. Добавлена зависимость
```yaml
dependencies:
  showcaseview: ^3.0.0
```

### 2. Инициализация в главном экране

```dart
// Обертка в ShowCaseWidget
ShowCaseWidget(
  builder: (context) => Scaffold(...)
)

// Автостарт в initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    TutorialManager.startTutorial(context);
  });
}
```

### 3. Showcase для элементов UI

```dart
Showcase(
  key: tutorialKeys.fromFieldKey,
  description: 'Введите адрес откуда начинается поездка',
  child: AddressAutocompleteField(...)
)
```

## Последовательность обучения

1. **Поле "Откуда"** - Объяснение ввода начальной точки
2. **Поле "Куда"** - Объяснение ввода конечной точки  
3. **Кнопка "Заказать"** - Создание заказа после ввода маршрута
4. **Кнопка геолокации** - Автоопределение текущего местоположения
5. **Карта** - Выбор точек непосредственно на карте

## Управление обучением

### Проверка необходимости показа
```dart
Future<bool> shouldShowTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return !prefs.getBool('tutorial_completed') ?? true;
}
```

### Сброс обучения (для разработчиков)
```dart
Future<void> resetTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tutorial_completed', false);
}
```

### Завершение обучения
```dart
Future<void> _completeTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tutorial_completed', true);
}
```

## Настройка и кастомизация

### Изменение текста подсказок

В `TutorialManager.startTutorial()` измените значения:

```dart
final tutorials = [
  ShowcaseModel(
    key: tutorialKeys.fromFieldKey,
    title: 'Поле "Откуда"',
    description: 'Ваш новый текст подсказки',
  ),
  // ...
];
```

### Добавление новых элементов

1. Создайте новый GlobalKey в TutorialManager
2. Оберните элемент в Showcase виджет
3. Добавьте в последовательность tutorials

### Изменение стиля

Модифицируйте параметры в `ShowCaseWidget.builder`:

```dart
ShowCaseWidget(
  builder: (context) => YourContent(),
  blurValue: 1,
  autoPlayDelay: Duration(seconds: 3),
  autoPlay: false,
)
```

## Отладка

### Сброс состояния для тестирования

Добавьте в debug меню:
```dart
onPressed: () async {
  await TutorialManager.resetTutorial();
  // Перезапуск экрана
}
```

### Принудительный запуск
```dart
TutorialManager.startTutorial(context); // Запустить всегда
```

### Логирование
В TutorialManager есть debug print'ы для отслеживания состояния:
- Проверка необходимости показа
- Начало обучения  
- Завершение каждого шага

## Производительность

- Обучение запускается только при первом входе
- Состояние сохраняется в SharedPreferences  
- Минимальное влияние на загрузку приложения
- Ленивая инициализация виджетов

## Совместимость

- Flutter 3.x
- iOS 12+
- Android API 21+
- Поддержка dark/light темы
- Адаптивная верстка для разных экранов

## Известные ограничения

1. Обучение работает только на главном экране
2. При смене языка нужно обновлять тексты
3. Showcase может конфликтовать с некоторыми анимациями

## Развитие

### Планируемые улучшения
- Локализация текстов обучения
- Обучение для других экранов
- Адаптивные подсказки по контексту
- Аналитика прохождения обучения

### Интеграция аналитики
```dart
// В onFinish каждого Showcase
onFinish: () {
  analytics.track('tutorial_step_completed', {
    'step': 'from_field'
  });
}
```

## Поддержка

При возникновении проблем:
1. Проверьте логи в debug консоли
2. Сбросьте состояние обучения  
3. Убедитесь что все ключи уникальны
4. Проверьте наличие showcaseview в pubspec.yaml

## Автор

Система обучения разработана для проекта Time to Travel.
Версия: 1.0.0