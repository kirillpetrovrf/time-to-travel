# 🚗 Time to Travel v2.0

Мобильное приложение для бронирования междугородних перевозок Донецк ↔ Ростов-на-Дону с системой детальных остановок, багажа и животных.

---

## 📱 ОПИСАНИЕ ПРОЕКТА

**Time to Travel** - это современное Flutter приложение для организации пассажирских перевозок с расширенной функциональностью:

### ✨ КЛЮЧЕВЫЕ ОСОБЕННОСТИ

#### 🎯 **Двухуровневая система бронирования**
- **Популярные маршруты**: Донецк ↔ Ростов с 11 промежуточными остановками
- **Свободные маршруты**: Калькулятор для произвольных адресов (Yandex Maps)

#### 🛣️ **Детальная система остановок**
```
Донецк → Макеевка → Харцызск → Иловайск → Кутейниково → 
Амвросиевка → КПП УСПЕНКА → Матвеев-Курган → Покровское → 
Таганрог → Ростов-на-Дону
```

#### 🧳 **Система багажа (4 категории)**
- **S** (30×40×20 см): Бесплатно
- **M** (50×60×25 см): +100₽
- **L** (70×80×30 см): +200₽ 
- **CUSTOM**: Индивидуальные габариты

#### 🐕 **Транспортировка животных (4 размера)**
- **XS** (до 3 кг): +100₽ - На коленях
- **S** (до 8 кг): +200₽ - В салоне
- **M** (до 25 кг): +400₽ - В багажнике
- **L** (25+ кг): +800₽ - Только индивидуальная поездка

#### 🔐 **VK верификация**
- OAuth авторизация через VKontakte
- Автоматическая скидка 30₽ для верифицированных пользователей

#### 📱 **Telegram + Push интеграция**
- Мгновенные уведомления диспетчеру в Telegram
- Push-напоминания за 24ч и 1ч до поездки

---

## 👥 ФУНКЦИОНАЛЬНОСТЬ

### 👤 **Для пассажиров:**
- 🎫 **Групповые поездки** - ожидание формирования группы (от 1500₽)
- 🚙 **Индивидуальные поездки** - немедленное бронирование (+50% к цене)
- 📍 **iOS-style picker** - выбор остановок в стиле Apple
- 💼 **Управление багажом** - точная калькуляция стоимости
- 🐾 **Перевозка животных** - с учетом размера и комфорта
- ✅ **VK верификация** - дополнительные скидки
- 📊 **История поездок** - детальная статистика
- 🔔 **Уведомления** - никогда не пропустите поездку

### ⚙️ **Для диспетчеров:**
- 📱 **Telegram бот** - мгновенные уведомления о заказах
- 🗺️ **Управление маршрутами** - редактирование описаний и цен
- 👥 **Группировка пассажиров** - оптимизация загрузки авто
- 📋 **Обработка заказов** - подтверждение/отклонение
- 📊 **Аналитика** - статистика и отчеты

---

## 🛠️ ТЕХНОЛОГИЧЕСКИЙ СТЕК

- **Flutter** - кроссплатформенная разработка
- **Firebase** - аутентификация и база данных
**Frontend:**
- **Flutter 3.16+** - кроссплатформенная разработка (iOS/Android)
- **Dart 3.2+** - язык программирования
- **Cupertino Design System** - iOS-стиль интерфейса

**Backend & Services:**
- **Firebase Authentication** - аутентификация по номеру телефона
- **Cloud Firestore** - NoSQL база данных в реальном времени
- **Firebase Cloud Messaging** - push-уведомления
- **Firebase Analytics** - аналитика пользователей

**External APIs:**
- **VKontakte API** - OAuth верификация пользователей
- **Telegram Bot API** - уведомления диспетчеру
- **Yandex Maps API** - геокодинг и маршрутизация (планируется)

**Key Dependencies:**
```yaml
dependencies:
  flutter: ^3.16.0
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.10
  geolocator: ^10.1.0
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.6
  http: ^1.1.2
```

---

## 🎨 ДИЗАЙН И БРЕНДИНГ

### 🌈 **Цветовая схема**
- **Primary Red**: `#E53E3E` - кнопки и активные элементы
- **Dark Background**: `#1A1A1A` - основной фон
- **Secondary Dark**: `#2D2D2D` - карточки и контейнеры
- **White Text**: `#FFFFFF` - основной текст
- **System Colors**: Используются системные цвета iOS для консистентности

### 📱 **UI Принципы**
- **Dark Theme Only** - единая темная тема для всех пользователей
- **iOS Design Language** - Cupertino стиль для всех элементов
- **Минимализм** - чистый интерфейс без лишних элементов
- **Accessibility** - поддержка увеличенного шрифта и контрастности

---

## 🚀 УСТАНОВКА И ЗАПУСК

### 📋 **Системные требования**
- **Flutter SDK**: 3.16.0+
- **Dart**: 3.2.0+
- **iOS**: 12.0+ / **Android**: API 21+ (Android 5.0)
- **Xcode**: 15.0+ (для iOS разработки)
- **Android Studio**: 2023.1+ (для Android разработки)

### ⚡ **Быстрый старт**

```bash
# 1. Клонирование репозитория
git clone https://github.com/yourusername/time-to-travel.git
cd time-to-travel

# 2. Установка зависимостей
flutter pub get

# 3. Настройка Firebase (см. docs/firebase_setup.md)
# Поместите google-services.json в android/app/
# Поместите GoogleService-Info.plist в ios/Runner/

# 4. Запуск приложения
flutter run
```

### 🔧 **Настройка внешних сервисов**

#### Firebase Setup
1. Создайте проект на [Firebase Console](https://console.firebase.google.com/)
2. Включите Authentication (Phone Number)
3. Настройте Cloud Firestore
4. Добавьте конфигурационные файлы в проект

#### VK API Setup (опционально)
1. Создайте приложение на [VK Developers](https://dev.vk.com/)
2. Получите App ID и Secret
3. Обновите `lib/services/vk_service.dart`

#### Telegram Bot Setup (опционально)
1. Создайте бота через [@BotFather](https://t.me/botfather)
2. Получите Bot Token
3. Обновите `lib/services/telegram_service.dart`

---

## 📊 СТАТУС РАЗРАБОТКИ

### ✅ **ГОТОВО (75%)**
- Аутентификация по номеру телефона
- Двухуровневая система бронирования
- Система багажа и животных
- VK верификация с скидками
- Telegram интеграция
- Push-уведомления
- iOS-style интерфейс

### 🔄 **В РАЗРАБОТКЕ**
- Интеграция экранов багажа/животных с booking flow
- Yandex Maps для свободных маршрутов
- Продакшн настройки API ключей

### ⏳ **ПЛАНИРУЕТСЯ**
- Платежная система
- Админ-панель для диспетчеров
- Расширенная аналитика

---

## 📁 АРХИТЕКТУРА ПРОЕКТА

```
lib/
├── main.dart                          # Entry point + Theme setup
├── config/
│   ├── firebase_config.dart           # Firebase configuration
│   └── app_config.dart                # App-wide settings
├── models/                            # Data models
│   ├── user.dart                      # User model
│   ├── route_stop.dart                # Route stops data
│   ├── baggage.dart                   # Baggage system
│   └── pet_info.dart                  # Pet transportation
├── services/                          # Business logic services
│   ├── auth_service.dart              # Authentication
│   ├── route_service.dart             # Route management
│   ├── vk_service.dart                # VK integration
│   ├── telegram_service.dart          # Telegram notifications
│   └── notification_service.dart      # Push notifications
├── features/                          # Feature-based modules
│   ├── auth/screens/                  # Authentication screens
│   ├── splash/                        # Splash screen
│   ├── home/screens/                  # Home & navigation
│   ├── booking/screens/               # Booking flow
│   ├── profile/screens/               # User profile
│   └── history/screens/               # Trip history
└── theme/                             # Design system
    ├── colors.dart                    # Color palette
    ├── app_theme.dart                 # Theme definitions
    └── theme_manager.dart             # Theme management
```

---

## 🚀 КЛЮЧЕВЫЕ ФУНКЦИИ

### 🎯 **Реализованные возможности**

#### 🔐 **Аутентификация**
- Phone Number Authentication через Firebase
- Автоматическая регистрация новых пользователей
- Сохранение сессии пользователя

#### 🛣️ **Система маршрутов**
- **Популярные маршруты**: Донецк ↔ Ростов с детальными остановками
- **iOS-style picker**: Элегантный выбор точек отправления/назначения
- **Групповые поездки**: Ожидание формирования группы (экономия)
- **Индивидуальные поездки**: Мгновенное бронирование (комфорт)

#### 🧳 **Управление багажом**
- 4 размера: S (бесплатно), M (+100₽), L (+200₽), Custom (расчет по объему)
- Визуальные карточки с примерами предметов
- Автоматический расчет дополнительной стоимости

#### 🐕 **Транспортировка животных**
- 4 категории: XS (на коленях), S (в салоне), M (в багажнике), L (индивидуальная поездка)
- Автоматические рекомендации по типу поездки
- Учет особенностей перевозки каждого размера

#### ✅ **VK Интеграция**
- OAuth авторизация через VKontakte API
- Автоматическая скидка 30₽ для верифицированных пользователей
- Синхронизация профиля с VK данными

#### 📱 **Уведомления**
- **Telegram**: Мгновенные уведомления диспетчеру о новых заказах
- **Push**: Напоминания за 24ч и 1ч до поездки
- **In-App**: Уведомления о статусе заказа в реальном времени

### 🔄 **В активной разработке**

#### 🗺️ **Yandex Maps**
- Калькулятор свободных маршрутов
- Геокодинг произвольных адресов
- Динамическое ценообразование по расстоянию

#### 💳 **Платежная система**
- Интеграция банковского эквайринга
- Поддержка СБП (QR-коды)
- Система возвратов и компенсаций

#### 🎛️ **Админ-панель**
- Веб-интерфейс для диспетчеров
- Управление маршрутами и ценами
- Расширенная аналитика и отчетность

---

## 🎨 ПОЛЬЗОВАТЕЛЬСКИЙ ОПЫТ

### 📱 **Интерфейс**
- **Single Dark Theme**: Фирменная красно-черно-белая цветовая схема
- **iOS Design Language**: Cupertino стиль для всех элементов
- **Responsive Design**: Адаптация под все размеры экранов
- **Accessibility**: Поддержка увеличенного шрифта и контрастности

### 🔥 **Производительность**
- **Lazy Loading**: Оптимизированная загрузка данных
- **Offline Support**: Кеширование критически важной информации
- **Real-time Updates**: Мгновенное обновление статуса заказов
- **Memory Optimization**: Эффективное управление ресурсами

---

## 📋 БИЗНЕС-ЛОГИКА

### 💰 **Ценообразование**
```
Базовая стоимость (Донецк-Ростов): 1,500₽

Модификаторы:
├── Индивидуальная поездка: +50%
├── Багаж M: +100₽
├── Багаж L: +200₽
├── Custom багаж: объем(л) × 5₽
├── Животные XS: +100₽
├── Животные S: +200₽
├── Животные M: +400₽
├── Животные L: +800₽ + принудительная индивидуальная
└── VK скидка: -30₽

Итого = Базовая + Модификаторы - Скидки
```

### 📊 **Жизненный цикл заказа**
```
CREATED → PENDING → CONFIRMED → IN_PROGRESS → COMPLETED
    ↓         ↓         ↓           ↓
 CANCELLED ← CANCELLED ← CANCELLED ← CANCELLED
```

---

## 🛠️ ТЕХНИЧЕСКАЯ ДОКУМЕНТАЦИЯ

### 📖 **Документы проекта**
- [`📋 Техническое задание v2.0`](docs/technical_specification.md) - Детальные требования
- [`📊 Статус проекта`](PROJECT_COMPLETION_STATUS.md) - Текущий прогресс разработки
- [`🎯 План действий`](NEXT_STEPS_PLAN.md) - Ближайшие задачи
- [`🔧 Firebase Setup`](docs/firebase_setup.md) - Настройка Firebase (планируется)
- [`🗺️ Yandex Maps Setup`](docs/yandex_maps_setup.md) - Настройка карт (планируется)

### 🧪 **Тестирование**
```bash
# Unit тесты
flutter test

# Integration тесты
flutter test integration_test/

# Анализ кода
flutter analyze

# Форматирование
flutter format lib/
```

### 🚀 **Сборка релиза**
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🌟 ОСОБЕННОСТИ ПРОЕКТА

### ⚡ **Производительность**
- Время запуска приложения: < 2 сек
- Время загрузки экранов: < 500ms
- Оффлайн-работа основных функций
- Оптимизированный размер APK/IPA

### 🔒 **Безопасность**
- Firebase Security Rules для защиты данных
- Валидация всех пользовательских вводов
- Шифрование чувствительной информации
- Аудит доступа к данным

### 🌍 **Масштабируемость**
- Модульная архитектура
- Готовность к добавлению новых маршрутов
- Легкое расширение функциональности
- Поддержка многоязычности (планируется)

---

## 🤝 УЧАСТИЕ В ПРОЕКТЕ

### 📋 **Как внести вклад**
1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Создайте Pull Request

### 🐛 **Сообщение об ошибках**
Используйте [GitHub Issues](https://github.com/yourusername/time-to-travel/issues) для:
- Сообщений об ошибках
- Запросов новых функций
- Вопросов по использованию

### 📝 **Стандарты кодирования**
- Следуйте [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Используйте [Flutter Best Practices](https://flutter.dev/docs/development/ui/widgets/animation)
- Покрывайте новый код тестами
- Документируйте публичные API

---

## 📞 КОНТАКТЫ И ПОДДЕРЖКА

### 👨‍💻 **Команда разработки**
- **Lead Developer**: Кирилл Петров
- **UI/UX Design**: В поиске талантов
- **Backend**: Firebase + Cloud Functions

### 📬 **Связь с нами**
- **Email**: dev@timetotravel.app
- **Telegram**: [@timetotravelbot](https://t.me/timetotravelbot)
- **GitHub Issues**: [Создать issue](https://github.com/yourusername/time-to-travel/issues/new)

### 💼 **Бизнес-вопросы**
- **Партнерство**: partners@timetotravel.app
- **Лицензирование**: license@timetotravel.app

---

## 📄 ЛИЦЕНЗИЯ

Этот проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для деталей.

---

## 🙏 БЛАГОДАРНОСТИ

### 🏆 **Особая благодарность**
- **Flutter Team** за превосходный фреймворк
- **Firebase Team** за надежную backend-платформу
- **VKontakte** за API для социальной интеграции
- **Yandex** за Maps SDK
- **Community** за постоянную поддержку и feedback

### 🎨 **Дизайн и UX**
- **Apple Human Interface Guidelines** за вдохновение
- **Material Design** за базовые принципы
- **iOS Design Community** за лучшие практики

---

<div align="center">

### ⭐ Поставьте звезду, если проект оказался полезным!

**Time to Travel v2.0** - Современные перевозки с заботой о пассажирах

[🚀 Скачать APK](https://github.com/yourusername/time-to-travel/releases) • 
[📱 App Store](https://apps.apple.com) • 
[🤖 Google Play](https://play.google.com) • 
[📋 Документация](docs/)

---

Made with ❤️ and ☕ by Time to Travel Team

</div>
