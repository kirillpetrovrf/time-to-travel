#!/bin/bash

# Скрипт для отлова ВСЕХ ошибок Yandex MapKit
# Использование: ./capture_yandex_errors.sh

echo "🔍 Запуск мониторинга Yandex MapKit ошибок..."
echo "📱 Убедитесь, что приложение запущено (flutter run)"
echo "🗺️ Откройте экран 'Свободный маршрут' в приложении"
echo ""
echo "⏰ Логи будут сохранены в: yandex_mapkit_errors.log"
echo "🛑 Нажмите Ctrl+C для остановки"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Очищаем предыдущий лог
> yandex_mapkit_errors.log

# Запускаем отлов логов с фильтрами для Yandex
adb logcat -c  # Очищаем старые логи

adb logcat \
  YandexMapsPlugin:V \
  YandexRuntime:V \
  YandexMapKit:V \
  Yandex:V \
  MapKit:V \
  chromium:E \
  *:E \
  | tee yandex_mapkit_errors.log \
  | grep --color=always -E "Error|error|ERROR|Exception|exception|EXCEPTION|Failed|failed|FAILED|denied|DENIED|timeout|TIMEOUT|Connection|CONNECTION|SSL|HTTP|404|500|403|401"

echo ""
echo "✅ Логи сохранены в yandex_mapkit_errors.log"
