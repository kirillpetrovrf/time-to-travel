#!/bin/bash

# 🔍 Захват HTTP ошибок в реальном времени
# Показывает все HTTP запросы и ошибки от Yandex Maps

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Мониторинг HTTP запросов Yandex Maps (Ctrl+C для выхода)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⏰ $(date '+%H:%M:%S') - Начало мониторинга..."
echo "📱 ОТКРОЙТЕ ЭКРАН 'СВОБОДНЫЙ МАРШРУТ' В ПРИЛОЖЕНИИ"
echo ""

# Захватываем все логи с HTTP, 403, tile, cache
adb logcat -v time | grep -E --line-buffered "HTTP|403|tile|Tile|cache|Cache|forbidden|Forbidden|yandex|Yandex|mapkit|MapKit" | grep -v "WifiService" | while read line; do
    # Подсветка ошибок
    if echo "$line" | grep -qi "403\|forbidden"; then
        echo "🔴 $line"
    elif echo "$line" | grep -qi "error\|fail"; then
        echo "⚠️  $line"
    elif echo "$line" | grep -qi "http\|request"; then
        echo "🌐 $line"
    else
        echo "ℹ️  $line"
    fi
done
