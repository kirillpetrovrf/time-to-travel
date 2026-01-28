#!/bin/bash

# 🔍 Скрипт для отслеживания ПОЛНОГО ПОТОКА авторизации через Telegram
# Использование: ./watch_telegram_auth_flow.sh

echo "🔍 ========== МОНИТОРИНГ TELEGRAM АВТОРИЗАЦИИ =========="
echo "📋 Отслеживаем:"
echo "   1️⃣ Webhook - получение /start от Telegram"
echo "   2️⃣ UPSERT - обновление пользователя"
echo "   3️⃣ SESSION - создание сессии авторизации (КЛЮЧЕВОЙ МОМЕНТ!)"
echo "   4️⃣ POLLING - проверка статуса авторизации"
echo "   5️⃣ TOKENS - выдача JWT токенов"
echo ""
echo "⏰ Начало мониторинга: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🛑 Для остановки нажмите Ctrl+C"
echo "=================================================="
echo ""

# Функция для красивого вывода с временными метками
log_line() {
    local timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] $1"
}

# Отслеживаем логи с сервера в реальном времени
ssh root@titotr.ru "docker logs -f backend 2>&1" | while read -r line; do
    # Фильтруем только важные строки
    if echo "$line" | grep -qE "(WEBHOOK|START|UPSERT|Сессия|SESSION|POLLING|AUTH_79504455444|setAuth|TOKEN|JWT|callback-code)"; then
        
        # Цветная подсветка ключевых событий
        if echo "$line" | grep -q "WEBHOOK.*ЗАПРОС"; then
            log_line "🌐 $line"
        
        elif echo "$line" | grep -q "Получено сообщение.*start"; then
            log_line "💬 $line"
        
        elif echo "$line" | grep -q "UPSERT.*ВЫЗОВ"; then
            log_line "🔧 $line"
        
        elif echo "$line" | grep -q "Сессия авторизации сохранена"; then
            log_line "✅ 🎯 КРИТИЧЕСКАЯ СТРОКА! $line"
            echo "    ^^^ ЭТА СТРОКА ДОЛЖНА ПОЯВИТЬСЯ ПОСЛЕ НАЖАТИЯ START!"
        
        elif echo "$line" | grep -q "setAuthSession"; then
            log_line "💾 $line"
        
        elif echo "$line" | grep -q "POLLING.*ЗАПРОС"; then
            log_line "🔄 $line"
        
        elif echo "$line" | grep -q "Сессия НЕ найдена"; then
            log_line "⏳ $line"
        
        elif echo "$line" | grep -q "Сессия найдена"; then
            log_line "✅ $line"
        
        elif echo "$line" | grep -q "Генерируем токены"; then
            log_line "🎟️ $line"
        
        elif echo "$line" | grep -q "Токены успешно"; then
            log_line "✅ ✅ ✅ УСПЕХ! $line"
        
        elif echo "$line" | grep -q "AUTH_79504455444"; then
            log_line "🔑 $line"
        
        else
            log_line "$line"
        fi
    fi
done
