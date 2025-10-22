#!/bin/bash

# 🔧 Скрипт для проверки работоспособности Yandex MapKit API ключа
# Использование: ./test_api_key.sh [API_KEY]

set -e  # Прерывать при ошибках

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Заголовок
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Yandex MapKit API Key Tester                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Получение API ключа
if [ -z "$1" ]; then
    echo -e "${YELLOW}⚠️  API ключ не передан в параметрах${NC}"
    echo -e "${YELLOW}📄 Попытка извлечь из map_config.dart...${NC}"
    
    # Извлечение ключа из конфигурации
    API_KEY=$(grep "yandexMapKitApiKey = '" lib/config/map_config.dart | sed "s/.*'\(.*\)'.*/\1/")
    
    if [ -z "$API_KEY" ]; then
        echo -e "${RED}❌ Не удалось извлечь API ключ из map_config.dart${NC}"
        echo -e "${YELLOW}💡 Использование: ./test_api_key.sh YOUR_API_KEY${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Ключ извлечен: ${API_KEY:0:8}...${API_KEY: -8}${NC}"
else
    API_KEY="$1"
    echo -e "${GREEN}✅ Ключ передан: ${API_KEY:0:8}...${API_KEY: -8}${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Тест 1: Проверка интернет-соединения${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

if ping -c 2 ya.ru > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Интернет работает${NC}"
else
    echo -e "${RED}❌ Нет подключения к интернету${NC}"
    echo -e "${YELLOW}💡 Проверьте сетевое подключение${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Тест 2: Доступность Yandex Maps API${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api-maps.yandex.ru/)
if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo -e "${GREEN}✅ Yandex Maps API доступен (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}❌ Yandex Maps API недоступен (HTTP $HTTP_CODE)${NC}"
    echo -e "${YELLOW}💡 Возможно, проблемы с доступом к Яндексу${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Тест 3: Suggest API (автодополнение)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

SUGGEST_URL="https://suggest-maps.yandex.ru/v1/suggest?apikey=${API_KEY}&text=Пермь&lang=ru_RU"

echo -e "${YELLOW}📡 Отправка запроса к Suggest API...${NC}"
SUGGEST_RESPONSE=$(curl -s -w "\n%{http_code}" "$SUGGEST_URL")
SUGGEST_HTTP_CODE=$(echo "$SUGGEST_RESPONSE" | tail -n1)
SUGGEST_BODY=$(echo "$SUGGEST_RESPONSE" | sed '$d')

if [ "$SUGGEST_HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Suggest API работает (HTTP 200)${NC}"
    
    # Проверка наличия результатов
    RESULTS_COUNT=$(echo "$SUGGEST_BODY" | grep -o '"results":\[' | wc -l)
    if [ "$RESULTS_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Найдены результаты автодополнения${NC}"
        echo -e "${BLUE}📍 Пример результата:${NC}"
        echo "$SUGGEST_BODY" | head -n 5
    else
        echo -e "${YELLOW}⚠️  Запрос успешен, но результатов нет${NC}"
    fi
elif [ "$SUGGEST_HTTP_CODE" -eq 403 ]; then
    echo -e "${RED}❌ Доступ запрещен (HTTP 403)${NC}"
    echo -e "${YELLOW}💡 API ключ недействителен или не имеет прав на Suggest API${NC}"
    echo -e "${YELLOW}🔗 Проверьте ключ: https://developer.tech.yandex.ru/${NC}"
elif [ "$SUGGEST_HTTP_CODE" -eq 429 ]; then
    echo -e "${RED}❌ Превышен лимит запросов (HTTP 429)${NC}"
    echo -e "${YELLOW}💡 Подождите или обновите тарифный план${NC}"
else
    echo -e "${RED}❌ Ошибка Suggest API (HTTP $SUGGEST_HTTP_CODE)${NC}"
    echo -e "${YELLOW}Ответ сервера:${NC}"
    echo "$SUGGEST_BODY"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Тест 4: Search API (поиск)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

SEARCH_URL="https://search-maps.yandex.ru/v1/?apikey=${API_KEY}&text=кафе&lang=ru_RU&ll=37.618423,55.751244&spn=0.552069,0.400552"

echo -e "${YELLOW}📡 Отправка запроса к Search API...${NC}"
SEARCH_RESPONSE=$(curl -s -w "\n%{http_code}" "$SEARCH_URL")
SEARCH_HTTP_CODE=$(echo "$SEARCH_RESPONSE" | tail -n1)
SEARCH_BODY=$(echo "$SEARCH_RESPONSE" | sed '$d')

if [ "$SEARCH_HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Search API работает (HTTP 200)${NC}"
    
    # Проверка наличия результатов
    FEATURES_COUNT=$(echo "$SEARCH_BODY" | grep -o '"features":\[' | wc -l)
    if [ "$FEATURES_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Найдены результаты поиска${NC}"
    else
        echo -e "${YELLOW}⚠️  Запрос успешен, но результатов нет${NC}"
    fi
elif [ "$SEARCH_HTTP_CODE" -eq 403 ]; then
    echo -e "${RED}❌ Доступ запрещен (HTTP 403)${NC}"
    echo -e "${YELLOW}💡 API ключ не имеет прав на Search API${NC}"
elif [ "$SEARCH_HTTP_CODE" -eq 429 ]; then
    echo -e "${RED}❌ Превышен лимит запросов (HTTP 429)${NC}"
else
    echo -e "${RED}❌ Ошибка Search API (HTTP $SEARCH_HTTP_CODE)${NC}"
    echo -e "${YELLOW}Ответ сервера:${NC}"
    echo "$SEARCH_BODY" | head -n 10
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Тест 5: Geocoder API (геокодирование)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

GEOCODE_URL="https://geocode-maps.yandex.ru/1.x/?apikey=${API_KEY}&geocode=Москва&format=json"

echo -e "${YELLOW}📡 Отправка запроса к Geocoder API...${NC}"
GEOCODE_RESPONSE=$(curl -s -w "\n%{http_code}" "$GEOCODE_URL")
GEOCODE_HTTP_CODE=$(echo "$GEOCODE_RESPONSE" | tail -n1)
GEOCODE_BODY=$(echo "$GEOCODE_RESPONSE" | sed '$d')

if [ "$GEOCODE_HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✅ Geocoder API работает (HTTP 200)${NC}"
    
    # Проверка наличия результатов
    FOUND_COUNT=$(echo "$GEOCODE_BODY" | grep -o '"found":[0-9]*' | sed 's/[^0-9]//g')
    if [ -n "$FOUND_COUNT" ] && [ "$FOUND_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Найдено результатов геокодирования: $FOUND_COUNT${NC}"
    else
        echo -e "${YELLOW}⚠️  Запрос успешен, но результатов нет${NC}"
    fi
elif [ "$GEOCODE_HTTP_CODE" -eq 403 ]; then
    echo -e "${RED}❌ Доступ запрещен (HTTP 403)${NC}"
    echo -e "${YELLOW}💡 API ключ не имеет прав на Geocoder API${NC}"
elif [ "$GEOCODE_HTTP_CODE" -eq 429 ]; then
    echo -e "${RED}❌ Превышен лимит запросов (HTTP 429)${NC}"
else
    echo -e "${RED}❌ Ошибка Geocoder API (HTTP $GEOCODE_HTTP_CODE)${NC}"
fi

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ИТОГИ ТЕСТИРОВАНИЯ                                 ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Подсчет успешных тестов
SUCCESS_COUNT=0
TOTAL_TESTS=4

[ "$SUGGEST_HTTP_CODE" -eq 200 ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$SEARCH_HTTP_CODE" -eq 200 ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$GEOCODE_HTTP_CODE" -eq 200 ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

echo -e "${BLUE}Успешно пройдено тестов: ${SUCCESS_COUNT}/${TOTAL_TESTS}${NC}"
echo ""

if [ "$SUCCESS_COUNT" -eq "$TOTAL_TESTS" ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ! API КЛЮЧ РАБОТАЕТ!         ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}🚀 Можно запускать приложение:${NC}"
    echo -e "${YELLOW}   flutter run${NC}"
    exit 0
elif [ "$SUCCESS_COUNT" -ge 2 ]; then
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   ⚠️  ЧАСТИЧНАЯ РАБОТОСПОСОБНОСТЬ                   ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}💡 Некоторые API работают, но не все${NC}"
    echo -e "${YELLOW}🔗 Проверьте права ключа: https://developer.tech.yandex.ru/${NC}"
    exit 1
else
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ❌ API КЛЮЧ НЕ РАБОТАЕТ!                          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}🔴 Критические проблемы с API ключом${NC}"
    echo ""
    echo -e "${YELLOW}Возможные причины:${NC}"
    echo -e "  1. Ключ не активирован (подождите 15-30 минут после создания)"
    echo -e "  2. Ключ недействителен или истек"
    echo -e "  3. Ключ не имеет необходимых прав"
    echo -e "  4. Превышен лимит запросов"
    echo ""
    echo -e "${YELLOW}Что делать:${NC}"
    echo -e "  1. Откройте: ${BLUE}https://developer.tech.yandex.ru/${NC}"
    echo -e "  2. Проверьте статус ключа"
    echo -e "  3. Создайте новый ключ (если нужно)"
    echo -e "  4. Обновите ключ в: ${BLUE}lib/config/map_config.dart${NC}"
    echo -e "  5. Выполните: ${BLUE}flutter clean && flutter pub get && flutter run${NC}"
    echo ""
    echo -e "${YELLOW}📄 Подробная инструкция: API_KEY_FIX_GUIDE.md${NC}"
    exit 1
fi
