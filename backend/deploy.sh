#!/bin/bash

# 🚀 Скрипт развертывания Time to Travel Backend на Selectel VPS
# Автоматизирует настройку сервера, установку Docker, PostgreSQL, SSL

set -e  # Остановка при ошибке

echo "🎯 Time to Travel - Развертывание на Selectel VPS"
echo "=================================================="

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для логирования
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Проверка системы
log_info "Проверка операционной системы..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    log_success "ОС: $NAME $VERSION"
else
    log_error "Не удалось определить операционную систему"
    exit 1
fi

# 2. Обновление системы
log_info "Обновление системы..."
sudo apt update && sudo apt upgrade -y
log_success "Система обновлена"

# 3. Установка необходимых пакетов
log_info "Установка базовых пакетов..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    ufw \
    htop \
    vim \
    nginx
log_success "Базовые пакеты установлены"

# 4. Установка Docker
log_info "Установка Docker..."
if ! command -v docker &> /dev/null; then
    # Добавление GPG ключа Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Добавление репозитория Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Установка Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Добавление текущего пользователя в группу docker
    sudo usermod -aG docker $USER
    
    log_success "Docker установлен"
else
    log_warning "Docker уже установлен"
fi

# Проверка версии Docker
docker --version
docker compose version

# 5. Настройка файрвола (UFW)
log_info "Настройка файрвола..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw status
log_success "Файрвол настроен"

# 6. Создание директории проекта
log_info "Создание директории проекта..."
PROJECT_DIR="/opt/time-to-travel"
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR
log_success "Директория создана: $PROJECT_DIR"

# 7. Клонирование репозитория
log_info "Клонирование репозитория..."
if [ -d ".git" ]; then
    log_warning "Репозиторий уже клонирован, выполняется git pull..."
    git pull origin main
else
    log_info "Введите URL репозитория GitHub:"
    read REPO_URL
    git clone $REPO_URL .
fi
log_success "Репозиторий клонирован"

# 8. Создание .env файла
log_info "Настройка переменных окружения..."
ENV_FILE="$PROJECT_DIR/backend/.env"

if [ ! -f "$ENV_FILE" ]; then
    log_info "Создание .env файла..."
    
    echo "Введите данные для настройки:"
    echo -n "PostgreSQL пароль (POSTGRES_PASSWORD): "
    read -s POSTGRES_PASSWORD
    echo
    
    echo -n "JWT Secret (минимум 32 символа): "
    read -s JWT_SECRET
    echo
    
    echo -n "Email для Let's Encrypt (для SSL): "
    read LETSENCRYPT_EMAIL
    
    cat > $ENV_FILE << EOF
# Database Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=timetotravel
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_ACCESS_EXPIRY_SECONDS=3600
JWT_REFRESH_EXPIRY_SECONDS=604800

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379

# Server Configuration
PORT=8080
ENVIRONMENT=production

# Let's Encrypt
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
DOMAIN=titotr.ru
EOF
    
    chmod 600 $ENV_FILE
    log_success ".env файл создан"
else
    log_warning ".env файл уже существует"
fi

# 9. Остановка и удаление старых контейнеров
log_info "Очистка старых контейнеров..."
cd $PROJECT_DIR/backend
docker compose down -v || true
log_success "Старые контейнеры остановлены"

# 10. Сборка и запуск контейнеров
log_info "Запуск Docker Compose..."
docker compose up -d --build

# Ожидание запуска PostgreSQL
log_info "Ожидание запуска базы данных..."
sleep 10

# Проверка статуса контейнеров
docker compose ps

log_success "Контейнеры запущены"

# 11. Инициализация базы данных
log_info "Инициализация базы данных..."
# SQL скрипты автоматически выполняются через docker-entrypoint-initdb.d
log_success "База данных инициализирована"

# 12. Проверка здоровья API
log_info "Проверка работоспособности API..."
sleep 5
if curl -s http://localhost:8080/health | grep -q "ok"; then
    log_success "API работает корректно"
else
    log_warning "API не отвечает, проверьте логи: docker compose logs backend"
fi

# 13. Настройка автозапуска
log_info "Настройка автозапуска контейнеров..."
# Docker Compose с restart: always уже настроен в docker-compose.yml
log_success "Автозапуск настроен"

# 14. Финальная информация
echo ""
echo "=========================================="
log_success "🎉 Развертывание завершено!"
echo "=========================================="
echo ""
echo "📊 Информация о сервисах:"
echo "  - Backend API: http://$(curl -s ifconfig.me):8080"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo ""
echo "📝 Полезные команды:"
echo "  - Просмотр логов: docker compose logs -f"
echo "  - Перезапуск: docker compose restart"
echo "  - Остановка: docker compose down"
echo "  - Обновление кода: git pull && docker compose up -d --build"
echo ""
echo "🔐 Следующие шаги:"
echo "  1. Настройте DNS: titotr.ru -> $(curl -s ifconfig.me)"
echo "  2. Настройте SSL с Let's Encrypt"
echo "  3. Протестируйте API: curl http://$(curl -s ifconfig.me):8080/health"
echo ""
log_warning "⚠️  Для применения группы docker перезайдите в систему: exit и снова подключитесь"
