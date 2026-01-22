# ============================================
# Stage 1: Build
# ============================================
FROM dart:3.9-sdk AS build

WORKDIR /app

# Копируем pubspec для кеширования зависимостей
COPY pubspec.* ./

# Устанавливаем зависимости
RUN dart pub get

# Копируем весь код
COPY . .

# Компилируем Dart Frog приложение
RUN dart pub global activate dart_frog_cli && \
    dart pub global run dart_frog_cli:dart_frog build

# ============================================
# Stage 2: Runtime
# ============================================
FROM dart:3.9-sdk AS runtime

# Устанавливаем curl для healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем скомпилированное приложение
COPY --from=build /app/build /app

# Копируем зависимости (dart_frog build включает pubspec, но нужны пакеты)
COPY --from=build /root/.pub-cache /root/.pub-cache

# Открываем порт
EXPOSE 8080

# Запускаем сервер
CMD ["dart", "run", "bin/server.dart"]
