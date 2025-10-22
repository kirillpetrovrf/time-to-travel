#!/bin/bash

# Скрипт для мониторинга Yandex Suggest API в реальном времени
# Использование: ./monitor_suggest_api.sh

echo "🔍 Мониторинг Yandex Suggest API"
echo "================================"
echo ""
echo "Ожидание логов от приложения..."
echo "Введите текст в поле адреса в приложении"
echo ""
echo "Нажмите Ctrl+C для остановки"
echo ""

# Очищаем предыдущие логи
adb logcat -c

# Показываем только Suggest API логи
adb logcat -v time | grep --line-buffered -E "(YANDEX SUGGEST|YANDEX MAPKIT|flutter)"
