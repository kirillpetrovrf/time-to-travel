#!/bin/bash

# Скрипт для отслеживания логов карты в реальном времени

echo "🔍 Отслеживание логов карты Yandex MapKit..."
echo "📱 Устройство: SM S901B (R5CT122DTYA)"
echo ""
echo "Фильтруем логи по ключевым словам:"
echo "  - MAP (инициализация карты)"
echo "  - SUGGEST (автодополнение)"
echo "  - yandex.maps (внутренние логи MapKit)"
echo "  - MapKit (общие логи)"
echo ""
echo "Нажмите Ctrl+C для выхода"
echo "----------------------------------------"
echo ""

# Отслеживаем логи через adb logcat
adb -s R5CT122DTYA logcat -v time | grep -E "(MAP|SUGGEST|yandex.maps|MapKit|flutter|DartVM)" | grep -v "BackgroundMode"
