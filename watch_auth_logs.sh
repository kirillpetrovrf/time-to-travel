#!/bin/bash

# 🔍 Расширенный скрипт для мониторинга логов с фокусом на авторизацию
# Использование: ./watch_auth_logs.sh

# Добавляем путь к Android SDK
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

echo "🔐 ========== МОНИТОРИНГ АВТОРИЗАЦИИ TIME TO TRAVEL =========="
echo "📱 Приложение: com.timetotravel.app"
echo "⏰ Начало: $(date '+%H:%M:%S')"
echo "🎯 Фильтры: STORAGE, AUTH_PROVIDER, AUTH_SPLASH, POLLING"
echo "================================================================"
echo ""

# Очищаем старые логи
adb logcat -c

# Мониторим логи с фильтрацией по ключевым словам авторизации
adb logcat | grep --line-buffered -E "(STORAGE|AUTH_PROVIDER|AUTH_SPLASH|POLLING|TG_LOGIN|AuthStorageService)" \
  | while IFS= read -r line; do
      # Добавляем временную метку
      timestamp=$(date '+%H:%M:%S')
      
      # Цветная подсветка важных событий (для терминалов с поддержкой ANSI)
      if echo "$line" | grep -q "✅"; then
          echo -e "\033[0;32m[$timestamp] $line\033[0m"  # Зеленый
      elif echo "$line" | grep -q "❌"; then
          echo -e "\033[0;31m[$timestamp] $line\033[0m"  # Красный
      elif echo "$line" | grep -q "⚠️"; then
          echo -e "\033[0;33m[$timestamp] $line\033[0m"  # Желтый
      elif echo "$line" | grep -q "🔍"; then
          echo -e "\033[0;36m[$timestamp] $line\033[0m"  # Голубой
      else
          echo "[$timestamp] $line"
      fi
    done
