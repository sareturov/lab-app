# --- этап сборки ---
FROM php:8.1-cli AS builder
WORKDIR /app

# 1) задаём лимит памяти Composer и разрешаем запускать от root
ENV COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_ALLOW_SUPERUSER=1

# 2) устанавливаем системные зависимости и необходимые dev-пакеты
RUN apt-get update \
    && apt-get install -y \
         unzip \
         git \
         libzip-dev \
         libxml2-dev \
         zlib1g-dev \
         libpng-dev \
         libonig-dev \
    && docker-php-ext-install \
         zip \
         pdo_mysql \
         mbstring \
         xml \
         bcmath \
    && rm -rf /var/lib/apt/lists/*

# 3) ставим Composer
RUN php -r "copy('https://getcomposer.org/installer','composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

# 4) копируем манифест и ставим зависимости без dev
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# 5) копируем весь код и генерируем ключ
COPY . .
RUN php artisan key:generate --ansi

# --- финальный образ ---
FROM php:8.1-cli
WORKDIR /app
COPY --from=builder /app /app

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
