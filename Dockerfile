# --- этап сборки ---
FROM php:8.1-cli AS builder
WORKDIR /app

# 1) Снимаем лимиты Composer и разрешаем запуск от root
ENV COMPOSER_MEMORY_LIMIT=-1 \
    COMPOSER_ALLOW_SUPERUSER=1

# 2) Устанавливаем все нужные библиотеки и PHP-расширения
RUN apt-get update \
    && apt-get install -y \
         git \
         unzip \
         libzip-dev \
         zlib1g-dev \
         libxml2-dev \
         libpng-dev \
         libjpeg-dev \
         libfreetype6-dev \
         libicu-dev \
         libonig-dev \
         libcurl4-openssl-dev \
         pkg-config \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install \
         zip \
         pdo_mysql \
         mbstring \
         xml \
         bcmath \
         gd \
         curl \
         intl \
    && rm -rf /var/lib/apt/lists/*

# 3) Ставим Composer
RUN php -r "copy('https://getcomposer.org/installer','composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

# 4) Копируем только манифесты и ставим зависимости без dev
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# 5) Копируем код и генерируем ключ
COPY . .
RUN php artisan key:generate --ansi

# --- финальный образ ---
FROM php:8.1-cli
WORKDIR /app
COPY --from=builder /app /app

EXPOSE 8000
CMD ["php","artisan","serve","--host=0.0.0.0","--port=8000"]
