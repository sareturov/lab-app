# --- этап сборки ---
FROM php:8.1-cli AS builder
WORKDIR /app

# установим зависимости системы и Composer
RUN apt-get update \
    && apt-get install -y unzip git libzip-dev \
    && docker-php-ext-install zip pdo_mysql \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# копируем файлы и ставим PHP-зависимости
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

COPY . .

# генерируем ключ приложения
RUN php artisan key:generate --ansi

# --- финальный образ ---
FROM php:8.1-cli
WORKDIR /app

# копируем всё из билдера
COPY --from=builder /app /app

# создаём файл sqlite, если нужен
# RUN touch database/database.sqlite

EXPOSE 8000

# стартовая команда
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
