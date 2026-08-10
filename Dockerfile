# ==========================================
# Mount Castle Laravel Backend
# PHP 8.3 + Apache + MySQL/TiDB Cloud SSL
# ==========================================


# ==========================================
# Stage 1: Composer dependencies
# ==========================================
FROM composer:2 AS composer

WORKDIR /app

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts


# ==========================================
# Stage 2: Laravel + PHP + Apache
# ==========================================
FROM php:8.3-apache

WORKDIR /var/www/html


# ==========================================
# Install required packages
# ==========================================
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    git \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        opcache \
    && a2enmod rewrite \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ==========================================
# Copy Composer dependencies
# ==========================================
COPY --from=composer /app/vendor ./vendor


# ==========================================
# Copy Laravel application
# ==========================================
COPY . .


# ==========================================
# Verify TiDB SSL certificate exists
# ==========================================
RUN test -f /var/www/html/certs/isrgrootx1.pem


# ==========================================
# Configure Apache
# Laravel public directory
# ==========================================
RUN sed -ri \
    -e 's!/var/www/html!/var/www/html/public!g' \
    /etc/apache2/sites-available/000-default.conf


# ==========================================
# Laravel permissions
# ==========================================
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data \
        storage \
        bootstrap/cache \
    && chmod -R 775 \
        storage \
        bootstrap/cache


# ==========================================
# Apache port
# ==========================================
EXPOSE 80


# ==========================================
# Start Apache
# ==========================================
CMD ["apache2-foreground"]