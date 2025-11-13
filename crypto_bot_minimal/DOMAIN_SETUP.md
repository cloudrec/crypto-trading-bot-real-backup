# Настройка собственного домена для торгового бота

## 🌐 Варианты настройки домена

### 1. **Через Cloudflare (Рекомендуется)**

#### Шаг 1: Настройка DNS записей
Добавьте в Cloudflare следующие DNS записи:

```
Тип: CNAME
Имя: bot (или любое другое поддомен)
Значение: 4m8zhr5ev9.skywork.website
Proxy: Включен (оранжевое облако)
```

#### Шаг 2: Настройка Page Rules (опционально)
Создайте Page Rule для редиректа:
```
URL: yourdomain.com/bot*
Настройка: Forwarding URL (301 - Permanent Redirect)
Destination: https://4m8zhr5ev9.skywork.website/$1
```

### 2. **Через обычный DNS провайдер**

#### Добавьте CNAME запись:
```
Тип: CNAME
Имя: bot
Значение: 2zbd2hytuu.skywork.website
TTL: 300 (или автоматически)
```

### 3. **Через Nginx Proxy (для VPS)**

#### Конфигурация Nginx:
```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name bot.yourdomain.com;

    # SSL сертификаты (если используете HTTPS)
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;

    location / {
        proxy_pass https://4m8zhr5ev9.skywork.website;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Для WebSocket поддержки (если нужно)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### 4. **Через Apache (для VPS)**

#### Конфигурация Apache:
```apache
<VirtualHost *:80>
    ServerName bot.yourdomain.com
    
    ProxyPreserveHost On
    ProxyPass / https://4m8zhr5ev9.skywork.website/
    ProxyPassReverse / https://4m8zhr5ev9.skywork.website/
    
    # Для HTTPS
    ProxyPassMatch ^/(.*) https://4m8zhr5ev9.skywork.website/$1
</VirtualHost>

<VirtualHost *:443>
    ServerName bot.yourdomain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/your/certificate.crt
    SSLCertificateKeyFile /path/to/your/private.key
    
    ProxyPreserveHost On
    ProxyPass / https://4m8zhr5ev9.skywork.website/
    ProxyPassReverse / https://4m8zhr5ev9.skywork.website/
</VirtualHost>
```

## 🚀 Быстрый способ (Cloudflare)

1. **Войдите в Cloudflare Dashboard**
2. **Выберите ваш домен**
3. **Перейдите в DNS → Records**
4. **Добавьте CNAME запись:**
   - Name: `bot` (или любое имя)
   - Target: `4m8zhr5ev9.skywork.website`
   - Proxy status: Proxied (🟠)
5. **Сохраните изменения**

После этого ваш бот будет доступен по адресу: `https://bot.yourdomain.com`

## 🔧 Альтернативные решения

### Использование поддомена
Если у вас есть домен `example.com`, вы можете настроить:
- `trading.example.com`
- `bot.example.com` 
- `crypto.example.com`

### Использование пути
Настройте редирект с `yourdomain.com/trading` на торгового бота.

## 📝 Примечания

- **Время распространения DNS**: 5-48 часов
- **SSL сертификаты**: Cloudflare предоставляет бесплатные SSL
- **Кэширование**: Настройте правила кэширования для лучшей производительности

## 🆘 Поддержка

Если нужна помощь с настройкой конкретного провайдера DNS, предоставьте информацию о вашем домене и DNS провайдере.