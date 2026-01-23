#!/bin/bash

# 🔍 Скрипт для мониторинга логов приложения Time To Travel
# Использование: ./watch_app_logs.sh

# Добавляем путь к Android SDK
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

echo "🔍 ========== МОНИТОРИНГ ЛОГОВ TIME TO TRAVEL =========="
echo "📱 Приложение: com.timetotravel.app"
echo "⏰ Начало мониторинга: $(date '+%H:%M:%S')"
echo "📋 Показываем только логи Flutter (I/flutter)"
echo "==========================================================="
echo ""

# Очищаем старые логи и начинаем мониторинг
adb logcat -c  # Очистка старых логов
adb logcat -s flutter:I \
  | grep --line-buffered "I/flutter" \
  | while IFS= read -r line; do
      echo "[$(date '+%H:%M:%S')] $line"
    done
