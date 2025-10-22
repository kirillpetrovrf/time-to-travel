#!/bin/bash

# 🔔 Мониторинг уведомлений Time to Travel
# Использование: ./monitor_notifications.sh

echo "🔔 ========================================"
echo "🔔 МОНИТОРИНГ УВЕДОМЛЕНИЙ"
echo "🔔 Приложение: Time to Travel"
echo "🔔 Ожидаемое время: 19:50"
echo "🔔 Текущее время: $(date '+%H:%M:%S')"
echo "🔔 ========================================"
echo ""

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Фильтруем логи Flutter...${NC}"
echo ""

# Мониторинг Flutter логов с уведомлениями
adb logcat -s flutter:I | while read line; do
    # Проверяем, содержит ли строка эмодзи уведомлений
    if echo "$line" | grep -q "🔔"; then
        echo -e "${GREEN}${line}${NC}"
    # Проверяем на ошибки
    elif echo "$line" | grep -q "❌"; then
        echo -e "${RED}${line}${NC}"
    # Проверяем на успешные операции
    elif echo "$line" | grep -q "✅"; then
        echo -e "${GREEN}${line}${NC}"
    # Проверяем на планирование
    elif echo "$line" | grep -q "ПЛАНИРОВАНИЕ\|zonedSchedule"; then
        echo -e "${YELLOW}${line}${NC}"
    # Остальные строки с уведомлениями
    elif echo "$line" | grep -q "notification\|Notification\|Reminder\|УВЕДОМЛЕНИЕ"; then
        echo -e "${BLUE}${line}${NC}"
    fi
done
