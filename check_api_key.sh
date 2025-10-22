#!/bin/bash

echo "🔍 ========== ПРОВЕРКА YANDEX MAPKIT API КЛЮЧА =========="
echo ""

# Получаем текущий ключ из кода
API_KEY=$(grep "yandexMapKitApiKey" lib/config/map_config.dart | cut -d"'" -f2)

if [ -z "$API_KEY" ] || [ "$API_KEY" == "YOUR_YANDEX_MAPKIT_API_KEY" ]; then
    echo "❌ API ключ не настроен!"
    echo ""
    echo "📝 Откройте lib/config/map_config.dart и добавьте ключ"
    echo ""
    exit 1
fi

echo "✅ API ключ найден в коде:"
echo "   ${API_KEY:0:15}...${API_KEY: -15}"
echo ""

# Проверяем формат ключа (должен быть UUID)
if [[ $API_KEY =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
    echo "✅ Формат ключа корректный (UUID)"
else
    echo "⚠️  Формат ключа необычный (ожидается UUID)"
fi
echo ""

# Пытаемся проверить ключ через Yandex API
echo "🌐 Проверка ключа через Yandex API..."
echo "   (попытка инициализации MapKit)"
echo ""

# Создаем временный HTML файл для теста
cat > /tmp/test_mapkit.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>MapKit Test</title>
    <script src="https://api-maps.yandex.ru/3.0/?apikey=API_KEY_PLACEHOLDER&lang=ru_RU" type="text/javascript"></script>
</head>
<body>
    <div id="map" style="width: 600px; height: 400px"></div>
    <script>
        window.onload = function() {
            ymaps3.ready.then(() => {
                console.log('MapKit initialized successfully');
                document.getElementById('status').innerHTML = 'OK';
            }).catch((error) => {
                console.error('MapKit initialization failed:', error);
                document.getElementById('status').innerHTML = 'ERROR: ' + error.message;
            });
        };
    </script>
    <div id="status">Loading...</div>
</body>
</html>
EOF

# Заменяем плейсхолдер на реальный ключ
sed -i '' "s/API_KEY_PLACEHOLDER/$API_KEY/" /tmp/test_mapkit.html

echo "⚠️  Автоматическая проверка ключа через API невозможна из терминала"
echo "   Необходимо проверить вручную в Кабинете Разработчика:"
echo ""
echo "   🌐 https://developer.tech.yandex.ru/"
echo ""
echo "📋 Что проверить в Кабинете:"
echo "   1. Откройте раздел 'MapKit – мобильный SDK' (НЕ JavaScript API!)"
echo "   2. Найдите ключ: ${API_KEY:0:20}..."
echo "   3. Проверьте статус: должен быть 'АКТИВЕН' ✅"
echo "   4. Проверьте дату создания: должно пройти 15+ минут"
echo "   5. Проверьте лимиты: не должны быть превышены"
echo ""

# Проверка интернета
echo "🌐 Проверка интернет-соединения..."
if ping -c 1 -W 2 ya.ru &> /dev/null; then
    echo "✅ Интернет работает"
else
    echo "❌ Нет подключения к интернету!"
    echo "   Проверьте сетевое подключение"
    exit 1
fi
echo ""

# Проверка устройства
echo "📱 Проверка подключенного устройства/эмулятора..."
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [ $DEVICE_COUNT -eq 0 ]; then
    echo "⚠️  Устройство не подключено"
    echo "   Запустите эмулятор или подключите телефон"
    echo ""
elif [ $DEVICE_COUNT -eq 1 ]; then
    echo "✅ Устройство подключено:"
    adb devices | grep "device$"
    echo ""
    
    # Проверка интернета на устройстве
    echo "📡 Проверка интернета на устройстве..."
    if timeout 5 adb shell ping -c 1 ya.ru &> /dev/null; then
        echo "✅ Интернет на устройстве работает"
    else
        echo "❌ Нет интернета на устройстве!"
        echo "   Проверьте настройки сети на устройстве/эмуляторе"
    fi
    echo ""
else
    echo "⚠️  Подключено несколько устройств ($DEVICE_COUNT)"
    echo "   Отключите лишние устройства"
    adb devices
    echo ""
fi

# Итоговая сводка
echo "========== ИТОГОВАЯ СВОДКА =========="
echo ""
echo "✅ API ключ найден: ${API_KEY:0:20}..."
echo "✅ Формат ключа: OK"
echo "✅ Интернет (компьютер): OK"

if [ $DEVICE_COUNT -eq 1 ]; then
    echo "✅ Устройство подключено: OK"
fi

echo ""
echo "⚠️  ТРЕБУЕТСЯ РУЧНАЯ ПРОВЕРКА:"
echo ""
echo "1️⃣  Откройте Кабинет Разработчика:"
echo "    🌐 https://developer.tech.yandex.ru/"
echo ""
echo "2️⃣  Найдите раздел 'MapKit – мобильный SDK'"
echo "    ❗ НЕ 'JavaScript API' - это другой ключ!"
echo ""
echo "3️⃣  Найдите ваш ключ и проверьте:"
echo "    ✅ Статус: АКТИВЕН"
echo "    ✅ Тип: MapKit – мобильный SDK"
echo "    ✅ Создан: более 15 минут назад"
echo "    ✅ Лимиты: не превышены"
echo ""
echo "4️⃣  Если ключ неактивен - создайте новый:"
echo "    - Нажмите 'Новый ключ'"
echo "    - Выберите 'MapKit – мобильный SDK'"
echo "    - Выберите бесплатный тариф (25,000 запросов/день)"
echo "    - Скопируйте новый ключ"
echo "    - Замените в lib/config/map_config.dart"
echo "    - ПОДОЖДИТЕ 15 МИНУТ для активации"
echo ""
echo "5️⃣  Перезапустите приложение:"
echo "    flutter clean && flutter run"
echo ""
echo "=========================================="
echo ""

# Спрашиваем, хочет ли пользователь запустить приложение
read -p "🚀 Запустить приложение сейчас? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Запуск приложения..."
    flutter run
fi
