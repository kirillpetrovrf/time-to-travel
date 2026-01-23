# 🚀 Telegram Auth - Следующие шаги

## ✅ Что уже готово:

1. ✅ Telegram бот создан: @timetotravelauth_bot
2. ✅ Webhook настроен: https://titotr.ru/api/telegram/webhook  
3. ✅ PostgreSQL база готова (таблица `users` с `telegram_id`)
4. ✅ Диспетчер добавлен (+79895342496, @nepeBo34uk)
5. ✅ TelegramBotService создан (lib/services/telegram_bot_service.dart)

## 📋 Что нужно сделать:

### 1. **Создать endpoint для webhook** (backend)

Файл: `backend/routes/telegram/webhook.dart`

```dart
import 'package:dart_frog/dart_frog.dart';
import 'dart:convert';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final body = await context.request.body();
  final update = jsonDecode(body);
  
  // Обработка /start команды
  if (update['message'] != null) {
    final message = update['message'];
    final text = message['text'] as String?;
    final from = message['from'];
    
    if (text != null && text.startsWith('/start')) {
      // Здесь логика регистрации
      final telegramId = from['id'] as int;
      final firstName = from['first_name'] as String?;
      final lastName = from['last_name'] as String?;
      final username = from['username'] as String?;
      
      // TODO: Сохранить в БД или обработать deep link
    }
  }

  return Response(statusCode: 200);
}
```

### 2. **Создать auth endpoints** (backend)

- `POST /auth/telegram/init` - начать процесс входа
- `GET /auth/telegram/status` - проверить статус
- `POST /auth/refresh` - обновить токен
- `GET /auth/me` - получить текущего пользователя

### 3. **Экран входа** (Flutter)

```dart
class LoginScreen extends StatelessWidget {
  final phoneController = TextEditingController();

  Future<void> loginWithTelegram() async {
    final phone = phoneController.text;
    
    // 1. Запрос deep link
    final response = await http.post(
      Uri.parse('https://titotr.ru/api/auth/telegram/init'),
      body: {'phone': phone},
    );
    
    final deepLink = json.decode(response.body)['deepLink'];
    
    // 2. Открыть Telegram
    await launchUrl(Uri.parse(deepLink));
    
    // 3. Ждать подтверждения (polling или push)
    await checkAuthStatus();
  }
}
```

## 🔧 Быстрый запуск:

```bash
# Запустить деплой (когда backend routes готовы)
./deploy_telegram_auth.sh

# Протестировать бота вручную
https://t.me/timetotravelauth_bot
```

## 📱 Для Евгения (диспетчера):

1. Открыть: https://t.me/timetotravelauth_bot
2. Нажать `/start`  
3. Его `telegram_id` будет обновлён в базе

## ⏭️ Следующий шаг:

**Выберите:**

**A) Я создаю минимальный рабочий прототип** (2 часа)
   - Webhook endpoint
   - Auth API
   - Простой экран входа Flutter
   - Можно сразу тестировать

**B) Вы хотите сначала посмотреть структуру** 
   - Покажу детальную схему
   - Обсудим детали
   - Потом реализуем

Что выбираете? 🤔
