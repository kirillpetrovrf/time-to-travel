#!/bin/bash

# 🗺️ Автоматическая диагностика 403 ошибки Yandex Maps
# Автор: GitHub Copilot
# Дата: 20 октября 2025 г.

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Диагностика проблемы с загрузкой тайлов Yandex Maps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Проверка подключения устройства
echo "📱 1. Проверка устройства..."
DEVICE=$(adb devices | grep -w "device" | head -1 | awk '{print $1}')
if [ -z "$DEVICE" ]; then
    echo "❌ Устройство не подключено!"
    echo "   Запустите эмулятор или подключите устройство"
    exit 1
fi
echo "✅ Устройство подключено: $DEVICE"
echo ""

# Проверка API ключа в манифесте
echo "🔑 2. Проверка API ключа..."
API_KEY=$(grep "com.yandex.mapkit" android/app/src/main/AndroidManifest.xml | grep -o 'value="[^"]*"' | cut -d'"' -f2)
if [ -z "$API_KEY" ]; then
    echo "❌ API ключ не найден в AndroidManifest.xml!"
    exit 1
fi
echo "✅ API ключ найден: ${API_KEY:0:20}...${API_KEY: -10}"
echo ""

# Проверка прав на интернет
echo "🌐 3. Проверка прав на интернет..."
if grep -q "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml; then
    echo "✅ Права INTERNET присутствуют"
else
    echo "❌ Права INTERNET отсутствуют!"
    exit 1
fi
echo ""

# Проверка версии MapKit
echo "📦 4. Проверка версии Yandex MapKit..."
MAPKIT_VERSION=$(grep "yandex_mapkit" pubspec.yaml | head -1 | awk '{print $2}')
echo "✅ Версия MapKit: $MAPKIT_VERSION"
echo ""

# Проверка package name
echo "📋 5. Проверка package name..."
PACKAGE_NAME=$(grep "package=" android/app/src/main/AndroidManifest.xml | head -1 | grep -o 'package="[^"]*"' | cut -d'"' -f2)
echo "✅ Package name: $PACKAGE_NAME"
echo "   ⚠️  Убедитесь, что этот bundle ID добавлен в консоли Yandex!"
echo ""

# Очистка старых логов
echo "🧹 6. Очистка старых логов..."
adb logcat -c
echo "✅ Логи очищены"
echo ""

# Инструкция пользователю
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 ДЕЙСТВИЯ ПОЛЬЗОВАТЕЛЯ:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Откройте приложение Time to Travel на устройстве"
echo "2. Перейдите в раздел 'Свободный маршрут'"
echo "3. Подождите 10 секунд пока карта попытается загрузить тайлы"
echo "4. Нажмите Enter в этом терминале когда закончите"
echo ""
echo -n "Нажмите Enter после того как открыли карту... "
read

# Захват логов после действий пользователя
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 АНАЛИЗ ЛОГОВ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Сохранение полных логов
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="map_diagnosis_${TIMESTAMP}.log"
adb logcat -d > "$LOG_FILE"
echo "✅ Полные логи сохранены: $LOG_FILE"
echo ""

# Поиск 403 ошибок
echo "🔍 Поиск HTTP 403 ошибок..."
ERRORS_403=$(grep -i "403\|forbidden" "$LOG_FILE" | grep -v "WifiService")
if [ ! -z "$ERRORS_403" ]; then
    echo "❌ НАЙДЕНЫ 403 ОШИБКИ:"
    echo "$ERRORS_403"
    echo ""
    echo "403_errors.log" > "403_errors_${TIMESTAMP}.log"
    echo "$ERRORS_403" >> "403_errors_${TIMESTAMP}.log"
    echo "📝 Ошибки сохранены: 403_errors_${TIMESTAMP}.log"
else
    echo "✅ HTTP 403 ошибки не найдены"
fi
echo ""

# Поиск ошибок MapKit
echo "🔍 Поиск ошибок Yandex MapKit..."
MAPKIT_ERRORS=$(grep -i "yandex\|mapkit\|ymk" "$LOG_FILE" | grep -i "error\|exception\|fail")
if [ ! -z "$MAPKIT_ERRORS" ]; then
    echo "❌ НАЙДЕНЫ ОШИБКИ MAPKIT:"
    echo "$MAPKIT_ERRORS"
    echo ""
    echo "$MAPKIT_ERRORS" > "mapkit_errors_${TIMESTAMP}.log"
    echo "📝 Ошибки сохранены: mapkit_errors_${TIMESTAMP}.log"
else
    echo "✅ Ошибки MapKit не найдены"
fi
echo ""

# Поиск проблем с кешем
echo "🔍 Поиск проблем с кешем тайлов..."
CACHE_ERRORS=$(grep -i "cache.*request\|tile.*fail\|tile.*error" "$LOG_FILE")
if [ ! -z "$CACHE_ERRORS" ]; then
    echo "⚠️  НАЙДЕНЫ ПРОБЛЕМЫ С КЕШЕМ:"
    echo "$CACHE_ERRORS"
    echo ""
else
    echo "✅ Проблемы с кешем не найдены"
fi
echo ""

# Поиск SSL/сертификатов
echo "🔍 Поиск проблем с SSL/сертификатами..."
SSL_ERRORS=$(grep -i "ssl\|certificate\|handshake" "$LOG_FILE" | grep -i "error\|fail")
if [ ! -z "$SSL_ERRORS" ]; then
    echo "⚠️  НАЙДЕНЫ ПРОБЛЕМЫ С SSL:"
    echo "$SSL_ERRORS"
    echo ""
else
    echo "✅ Проблемы с SSL не найдены"
fi
echo ""

# Итоговый отчёт
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 ИТОГОВЫЙ ОТЧЁТ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Устройство: $DEVICE"
echo "📦 Package: $PACKAGE_NAME"
echo "🔑 API ключ: ${API_KEY:0:20}...${API_KEY: -10}"
echo "📚 MapKit: $MAPKIT_VERSION"
echo "📝 Лог файл: $LOG_FILE"
echo ""

if [ ! -z "$ERRORS_403" ]; then
    echo "❌ ПРОБЛЕМА: Найдены HTTP 403 ошибки"
    echo ""
    echo "🔧 РЕШЕНИЕ:"
    echo "   1. Войдите в консоль Yandex: https://console.cloud.yandex.ru/"
    echo "   2. Проверьте статус API ключа"
    echo "   3. Убедитесь, что bundle ID '$PACKAGE_NAME' добавлен"
    echo "   4. Проверьте лимиты (25,000 запросов/месяц на бесплатном тарифе)"
    echo "   5. Если нужно - активируйте биллинг или создайте новый ключ"
elif [ ! -z "$MAPKIT_ERRORS" ]; then
    echo "⚠️  ПРОБЛЕМА: Найдены ошибки MapKit"
    echo ""
    echo "🔧 РЕШЕНИЕ:"
    echo "   1. Проверьте содержимое: mapkit_errors_${TIMESTAMP}.log"
    echo "   2. Возможно, версия MapKit несовместима с ключом"
    echo "   3. Попробуйте обновить: flutter pub upgrade yandex_mapkit_full"
else
    echo "✅ КРИТИЧЕСКИХ ОШИБОК НЕ НАЙДЕНО"
    echo ""
    echo "🔧 РЕКОМЕНДАЦИИ:"
    echo "   1. Проверьте визуально - загружаются ли тайлы на карте?"
    echo "   2. Если нет - проверьте интернет соединение устройства"
    echo "   3. Проверьте консоль Yandex на наличие ограничений ключа"
    echo "   4. Откройте $LOG_FILE и поищите другие ошибки"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Полная инструкция: MAP_TILES_403_DEBUG_GUIDE.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
