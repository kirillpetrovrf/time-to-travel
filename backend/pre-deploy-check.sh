#!/bin/bash
# pre-deploy-check.sh
# Скрипт проверки готовности к деплою

# НЕ используем set -e, чтобы продолжить проверку даже при ошибках

echo "🔍 Проверка готовности к деплою Time to Travel Backend"
echo "======================================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Счётчики
ERRORS=0
WARNINGS=0
SUCCESS=0

# Функция проверки
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        ((SUCCESS++))
    else
        echo -e "${RED}❌ $1${NC}"
        ((ERRORS++))
    fi
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

info() {
    echo -e "ℹ️  $1"
}

echo ""
echo "1️⃣  Проверка локального окружения"
echo "-----------------------------------"

# Проверка Dart SDK
if command -v dart &> /dev/null; then
    DART_VERSION=$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check "Dart SDK установлен (версия $DART_VERSION)"
else
    check "Dart SDK установлен"
fi

# Проверка Dart Frog CLI
if command -v dart_frog &> /dev/null; then
    FROG_VERSION=$(dart_frog --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo -e "${GREEN}✅ Dart Frog CLI установлен (версия $FROG_VERSION)${NC}"
    ((SUCCESS++))
else
    echo -e "${YELLOW}⚠️  Dart Frog CLI не установлен (опционально)${NC}"
    ((WARNINGS++))
fi

# Проверка файлов проекта
echo ""
echo "2️⃣  Проверка файлов проекта"
echo "----------------------------"

[ -f "pubspec.yaml" ] && check "pubspec.yaml существует" || check "pubspec.yaml существует"
[ -f "docker-compose.yml" ] && check "docker-compose.yml существует" || check "docker-compose.yml существует"
[ -f "Dockerfile" ] && check "Dockerfile существует" || check "Dockerfile существует"
[ -f ".env.example" ] && check ".env.example существует" || check ".env.example существует"
[ -f "deploy.sh" ] && check "deploy.sh существует" || check "deploy.sh существует"
[ -f "setup-ssl.sh" ] && check "setup-ssl.sh существует" || check "setup-ssl.sh существует"

# Проверка SQL миграций
[ -f "database/init/01-schema.sql" ] && check "Schema SQL существует" || check "Schema SQL существует"
[ -f "database/init/02-seed.sql" ] && check "Seed SQL существует" || check "Seed SQL существует"

# Проверка документации
echo ""
echo "3️⃣  Проверка документации"
echo "--------------------------"

[ -f "README.md" ] && check "README.md существует" || check "README.md существует"
[ -f "DEPLOYMENT_CHECKLIST.md" ] && check "DEPLOYMENT_CHECKLIST.md существует" || check "DEPLOYMENT_CHECKLIST.md существует"
[ -f "DEPLOYMENT_GUIDE.md" ] && check "DEPLOYMENT_GUIDE.md существует" || check "DEPLOYMENT_GUIDE.md существует"
[ -f "FLUTTER_INTEGRATION.md" ] && check "FLUTTER_INTEGRATION.md существует" || check "FLUTTER_INTEGRATION.md существует"
[ -f "API_ENDPOINTS.md" ] && check "API_ENDPOINTS.md существует" || check "API_ENDPOINTS.md существует"

# Проверка структуры routes
echo ""
echo "4️⃣  Проверка endpoints"
echo "-----------------------"

ROUTES_COUNT=$(find routes -name "*.dart" -type f | wc -l | xargs)
info "Найдено $ROUTES_COUNT endpoint файлов"

[ -f "routes/health.dart" ] && check "Health endpoint существует" || check "Health endpoint существует"
[ -f "routes/auth/register.dart" ] && check "Register endpoint существует" || check "Register endpoint существует"
[ -f "routes/auth/login.dart" ] && check "Login endpoint существует" || check "Login endpoint существует"
[ -f "routes/auth/refresh.dart" ] && check "Refresh endpoint существует" || check "Refresh endpoint существует"
[ -f "routes/routes/search.dart" ] && check "Route search endpoint существует" || check "Route search endpoint существует"
[ -f "routes/orders/index.dart" ] && check "Orders endpoint существует" || check "Orders endpoint существует"

# Проверка моделей
echo ""
echo "5️⃣  Проверка моделей"
echo "---------------------"

[ -f "lib/models/user.dart" ] && check "User model существует" || check "User model существует"
[ -f "lib/models/route.dart" ] && check "Route model существует" || check "Route model существует"
[ -f "lib/models/order.dart" ] && check "Order model существует" || check "Order model существует"

# Проверка репозиториев
echo ""
echo "6️⃣  Проверка репозиториев"
echo "--------------------------"

[ -f "lib/repositories/user_repository.dart" ] && check "UserRepository существует" || check "UserRepository существует"
[ -f "lib/repositories/route_repository.dart" ] && check "RouteRepository существует" || check "RouteRepository существует"
[ -f "lib/repositories/order_repository.dart" ] && check "OrderRepository существует" || check "OrderRepository существует"

# Проверка сервисов
echo ""
echo "7️⃣  Проверка сервисов"
echo "----------------------"

[ -f "lib/services/database_service.dart" ] && check "DatabaseService существует" || check "DatabaseService существует"
[ -f "lib/services/jwt_helper.dart" ] && check "JwtHelper существует" || check "JwtHelper существует"

# Проверка middleware
echo ""
echo "8️⃣  Проверка middleware"
echo "------------------------"

[ -f "lib/middleware/auth_middleware.dart" ] && check "Auth middleware существует" || check "Auth middleware существует"

# Проверка зависимостей
echo ""
echo "9️⃣  Проверка зависимостей Dart"
echo "--------------------------------"

if [ -d ".dart_tool" ]; then
    check "Dart зависимости установлены"
else
    check "Dart зависимости установлены"
    warn "Выполните: dart pub get"
fi

# Проверка синтаксиса Dart
echo ""
echo "🔟 Проверка синтаксиса Dart"
echo "---------------------------"

if dart analyze > /dev/null 2>&1; then
    check "Dart код без ошибок компиляции"
else
    check "Dart код без ошибок компиляции"
    warn "Выполните: dart analyze для деталей"
fi

# Проверка переменных окружения
echo ""
echo "1️⃣1️⃣  Проверка переменных окружения"
echo "-------------------------------------"

if [ -f ".env" ]; then
    warn ".env файл существует (не коммитьте его в git!)"
    
    # Проверка обязательных переменных
    if grep -q "DATABASE_URL=" .env; then
        check "DATABASE_URL определён"
    else
        check "DATABASE_URL определён"
    fi
    
    if grep -q "JWT_SECRET=" .env; then
        JWT_SECRET=$(grep "JWT_SECRET=" .env | cut -d'=' -f2)
        if [ "$JWT_SECRET" = "YOUR_GENERATED_SECRET_HERE" ] || [ -z "$JWT_SECRET" ]; then
            check "JWT_SECRET сгенерирован"
            warn "Сгенерируйте JWT_SECRET: openssl rand -base64 32"
        else
            check "JWT_SECRET сгенерирован"
        fi
    else
        check "JWT_SECRET определён"
    fi
else
    warn ".env файл отсутствует (создайте из .env.example)"
fi

# Проверка Docker
echo ""
echo "1️⃣2️⃣  Проверка Docker"
echo "----------------------"

if command -v docker &> /dev/null; then
    check "Docker установлен"
    
    if docker info > /dev/null 2>&1; then
        check "Docker daemon запущен"
    else
        check "Docker daemon запущен"
        warn "Запустите Docker Desktop"
    fi
else
    check "Docker установлен"
    warn "Docker необходим для локальной разработки"
fi

# Проверка прав на выполнение скриптов
echo ""
echo "1️⃣3️⃣  Проверка прав на выполнение"
echo "-----------------------------------"

[ -x "deploy.sh" ] && check "deploy.sh исполняемый" || check "deploy.sh исполняемый"
[ -x "setup-ssl.sh" ] && check "setup-ssl.sh исполняемый" || check "setup-ssl.sh исполняемый"

# Проверка синтаксиса bash скриптов
if command -v bash &> /dev/null; then
    if bash -n deploy.sh > /dev/null 2>&1; then
        check "deploy.sh синтаксически корректен"
    else
        check "deploy.sh синтаксически корректен"
    fi
    
    if bash -n setup-ssl.sh > /dev/null 2>&1; then
        check "setup-ssl.sh синтаксически корректен"
    else
        check "setup-ssl.sh синтаксически корректен"
    fi
fi

# Итоговый отчёт
echo ""
echo "📊 Итоговый отчёт"
echo "================="
echo -e "${GREEN}✅ Успешно: $SUCCESS${NC}"
echo -e "${YELLOW}⚠️  Предупреждений: $WARNINGS${NC}"
echo -e "${RED}❌ Ошибок: $ERRORS${NC}"

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 Проект готов к деплою!${NC}"
    echo ""
    echo "Следующие шаги:"
    echo "1. Арендовать VPS на Selectel (Ubuntu 22.04, 2GB RAM)"
    echo "2. Настроить DNS для titotr.ru"
    echo "3. Загрузить скрипты: scp deploy.sh setup-ssl.sh root@titotr.ru:/root/"
    echo "4. Запустить деплой: ssh root@titotr.ru 'sudo bash deploy.sh'"
    echo ""
    echo "Документация:"
    echo "- DEPLOYMENT_CHECKLIST.md - чек-лист для деплоя"
    echo "- DEPLOYMENT_GUIDE.md - подробная инструкция"
    echo "- FLUTTER_INTEGRATION.md - интеграция с Flutter"
    exit 0
else
    echo -e "${RED}❌ Есть критические ошибки. Исправьте их перед деплоем.${NC}"
    echo ""
    echo "Рекомендации:"
    [ $ERRORS -gt 0 ] && echo "- Проверьте все файлы отмеченные ❌"
    [ $WARNINGS -gt 0 ] && echo "- Обратите внимание на предупреждения ⚠️"
    exit 1
fi
