#!/bin/bash

# ============================================
# 🗄️ Автоматический бэкап PostgreSQL в GitHub
# ============================================

set -e

# Настройки
REPO_DIR="/root/time-to-travel"
BACKUP_DIR="${REPO_DIR}/backups"
DB_CONTAINER="timetotravel_postgres"
DB_NAME="timetotravel"
DB_USER="timetotravel_user"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="backup_${DATE}.sql"
DAYS_TO_KEEP=7

echo "🗄️  [BACKUP] Начинаем резервное копирование базы данных..."
echo "📅 Дата: ${DATE}"

# Создаём директорию для бэкапов, если её нет
mkdir -p ${BACKUP_DIR}
cd ${REPO_DIR}

# Проверяем, что мы в git репозитории
if [ ! -d ".git" ]; then
    echo "❌ [ERROR] Это не Git репозиторий! Клонируйте репозиторий сначала."
    exit 1
fi

# Создаём бэкап базы данных
echo "💾 [DUMP] Создаём дамп базы данных..."
docker exec ${DB_CONTAINER} pg_dump -U ${DB_USER} -d ${DB_NAME} --clean --if-exists > ${BACKUP_DIR}/${BACKUP_FILE}

# Проверяем размер файла
BACKUP_SIZE=$(du -h ${BACKUP_DIR}/${BACKUP_FILE} | cut -f1)
echo "✅ [DUMP] Бэкап создан: ${BACKUP_FILE} (${BACKUP_SIZE})"

# Сжимаем бэкап для экономии места
echo "📦 [COMPRESS] Сжимаем бэкап..."
gzip ${BACKUP_DIR}/${BACKUP_FILE}
BACKUP_FILE="${BACKUP_FILE}.gz"
COMPRESSED_SIZE=$(du -h ${BACKUP_DIR}/${BACKUP_FILE} | cut -f1)
echo "✅ [COMPRESS] Сжато: ${COMPRESSED_SIZE}"

# Удаляем старые бэкапы (старше 7 дней)
echo "🧹 [CLEANUP] Удаляем бэкапы старше ${DAYS_TO_KEEP} дней..."
find ${BACKUP_DIR} -name "backup_*.sql.gz" -type f -mtime +${DAYS_TO_KEEP} -delete
echo "✅ [CLEANUP] Очистка завершена"

# Создаём README в папке backups если его нет
if [ ! -f "${BACKUP_DIR}/README.md" ]; then
    cat > ${BACKUP_DIR}/README.md << 'EOF'
# 🗄️ Database Backups

Автоматические резервные копии PostgreSQL базы данных.

## Структура

- `backup_YYYY-MM-DD_HH-MM-SS.sql.gz` - Сжатые SQL дампы
- Автоматическое создание каждый день в 03:00 МСК
- Хранятся последние 7 дней на сервере
- Полная история в GitHub

## 🔄 Восстановление

```bash
# 1. Скачайте нужный бэкап
# 2. Распакуйте
gunzip backup_YYYY-MM-DD_HH-MM-SS.sql.gz

# 3. Восстановите на сервере
docker exec -i timetotravel_postgres psql -U timetotravel_user -d timetotravel < backup_YYYY-MM-DD_HH-MM-SS.sql
```
EOF
fi

# Обновляем информацию о последнем бэкапе
cat > ${BACKUP_DIR}/LAST_BACKUP.txt << EOF
Дата: ${DATE}
Файл: backups/${BACKUP_FILE}
Размер: ${COMPRESSED_SIZE}
EOF

# Коммитим изменения в Git
echo "📤 [GIT] Сохраняем в Git..."
git add backups/
git commit -m "🗄️ Database backup ${DATE} (${COMPRESSED_SIZE})" || echo "⚠️  Нет изменений для коммита"

# Пушим в GitHub
echo "☁️  [GITHUB] Отправляем в GitHub..."
git push origin main 2>/dev/null || git push origin master || echo "⚠️  Ошибка push"

echo ""
echo "✅ =========================================="
echo "✅ БЭКАП ЗАВЕРШЁН УСПЕШНО!"
echo "✅ =========================================="
echo "📁 Локальный файл: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "📦 Размер: ${COMPRESSED_SIZE}"
echo "☁️  GitHub: https://github.com/kirillpetrovrf/time-to-travel"
echo ""
