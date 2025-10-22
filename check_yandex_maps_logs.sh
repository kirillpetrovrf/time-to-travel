#!/bin/bash

# Скрипт для мониторинга логов Yandex Maps и диагностики проблем с тайлами

echo "🔍 ========== МОНИТОРИНГ YANDEX MAPS ЛОГОВ =========="
echo ""
echo "⏳ Запуск мониторинга... Нажмите Ctrl+C для остановки"
echo ""

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Счётчики
CACHE_ERRORS=0
HTTP_ERRORS=0
SSL_ERRORS=0
NETWORK_ERRORS=0

# Запускаем фильтрацию логов
adb logcat -v time | while IFS= read -r line; do
    # Проверяем критические ошибки кеша Yandex Maps
    if echo "$line" | grep -q "No available cache for request"; then
        ((CACHE_ERRORS++))
        echo -e "${RED}❌ [CACHE ERROR #$CACHE_ERRORS] Тайлы не загружаются!${NC}"
        echo "$line"
        echo ""
        echo -e "${YELLOW}💡 РЕШЕНИЕ:${NC}"
        echo "   1. Проверьте интернет-соединение на устройстве"
        echo "   2. Убедитесь, что API-ключ Yandex Maps корректен"
        echo "   3. Проверьте network_security_config.xml"
        echo "   4. Убедитесь, что android:usesCleartextTraffic=\"true\""
        echo ""
    fi
    
    # Проверяем HTTP ошибки
    if echo "$line" | grep -qE "(HTTP|http).*error|failed"; then
        ((HTTP_ERRORS++))
        echo -e "${RED}❌ [HTTP ERROR #$HTTP_ERRORS]${NC}"
        echo "$line"
        echo ""
    fi
    
    # Проверяем SSL/TLS ошибки
    if echo "$line" | grep -qE "SSL|TLS|certificate"; then
        ((SSL_ERRORS++))
        echo -e "${YELLOW}⚠️  [SSL WARNING #$SSL_ERRORS]${NC}"
        echo "$line"
        echo ""
    fi
    
    # Проверяем сетевые ошибки
    if echo "$line" | grep -qE "Connection.*failed|Network.*error|timeout"; then
        ((NETWORK_ERRORS++))
        echo -e "${RED}🌐 [NETWORK ERROR #$NETWORK_ERRORS]${NC}"
        echo "$line"
        echo ""
    fi
    
    # Показываем важные логи карты
    if echo "$line" | grep -q "\[MAP\]"; then
        echo -e "${BLUE}🗺️  $line${NC}"
    fi
    
    # Показываем логи MapKit
    if echo "$line" | grep -q "yandex.maps"; then
        echo -e "${YELLOW}📍 $line${NC}"
    fi
    
    # Показываем успешные события
    if echo "$line" | grep -qE "✅|успешно|success"; then
        echo -e "${GREEN}$line${NC}"
    fi
done

echo ""
echo "========== СТАТИСТИКА =========="
echo "Ошибки кеша: $CACHE_ERRORS"
echo "HTTP ошибки: $HTTP_ERRORS"
echo "SSL предупреждения: $SSL_ERRORS"
echo "Сетевые ошибки: $NETWORK_ERRORS"
