# 🔑 Настройка автоматического бэкапа БД в GitHub

## Шаг 1: Создайте приватный репозиторий на GitHub ✅

1. Откройте https://github.com/new
2. Заполните:
   - **Repository name:** `time-to-travel-db-backups`
   - **Description:** `Автоматические резервные копии PostgreSQL базы данных`
   - **Visibility:** ✅ **Private** (приватный)
3. **НЕ** добавляйте README, .gitignore или лицензию (скрипт сам всё создаст)
4. Нажмите **Create repository**

## Шаг 2: Добавьте SSH ключ в GitHub 🔐

1. Скопируйте этот SSH ключ:

```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCMS0hPFArTyOgdQPB3WaMy+qQZC/OvxfV69SO+1GnDXbp4cCW6ZcF2GcXNwDtUHwIXCSZcjD8ZAs4GJx6Xu+k9M+LIJVCjnoPek8w/U9nf6zWV5nwEW66pPtkzZdJlom4Ua+Bq9gYpVAQtPK+wv+DIjghU5XebBzRURP7H9FvrRAADBu2KvV2NwLzOcmTp/w2aCmuWFeL8znZT8PvufK0Elq+MUTVZehxNpiHLmTf39CpdY5KiQ/p2QAKCJ7cK4HfoVEPdEklNsp4B/f3AAxb9qzGKTloFotksl1sJc5KS972JieNAEG+5abjvUa61T36/8H/oGgcYN5cDlhxW8K79NrjhET2HnwPLJp/TJxQMXT/x4PwO/RWm2c2mZ11yeKni4nCQdsLbk3W8mhODbjOhBuxY/Z0vDONXIHeTabCZbLmxoAzYhJeyRwMm7FY7E9SxxFGN71ZQJh2iZL+1cEU7EaNmz6YnWE4OxfCn++FD3ULlOsHpsZtiSMKQzcvDEPOdDXcWpGJdVXd+sT29BSrk73RZFGymnjopG62R0ly71X4taYvLDNWieFGfH4TfIDiP1jr7tmfONEL+5jRBsHN+md75k8b+OzoltWwLlPFRusD3P8Ng417wkTywsqmKCfFZRbyOXmuq/4jFv9ndp3K2yWNybBzwD4C2ERxfr1Yaew== backup@timetotravel
```

2. Откройте https://github.com/settings/ssh/new
3. Заполните:
   - **Title:** `TimeToTravel Server Backup`
   - **Key:** Вставьте скопированный ключ
4. Нажмите **Add SSH key**

## Шаг 3: Готово! 🎉

После этого скажите мне "готово" и я:
- Запущу первый тестовый бэкап
- Настрою автоматическое выполнение каждый день в 03:00
- Покажу как восстановить базу из бэкапа

---

## 📊 Что будет происходить автоматически:

```
Каждый день в 03:00 МСК:
1. 💾 Создаётся SQL дамп базы данных
2. 📦 Сжимается (gzip)
3. 📤 Отправляется в GitHub
4. 🧹 Удаляются бэкапы старше 7 дней на сервере
5. ✅ В GitHub остаётся ПОЛНАЯ история навсегда
```

## 🔍 Где смотреть бэкапы:

- **GitHub:** https://github.com/kirillpetrovrf/time-to-travel-db-backups
- **На сервере:** `/root/db_backups/` (последние 7 дней)

---

**❗️ ВАЖНО:** Репозиторий ОБЯЗАТЕЛЬНО должен быть **Private** (приватным)!
