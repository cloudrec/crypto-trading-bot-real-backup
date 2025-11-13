#!/bin/bash

# 🤖 Автоматическое обновление CNAME для fundbot.win
# Скрипт обновляет DNS запись после каждой публикации проекта

# ⚙️ КОНФИГУРАЦИЯ - ЗАМЕНИТЕ НА ВАШИ ЗНАЧЕНИЯ:
DOMAIN="fundbot.win"
CLOUDFLARE_EMAIL="cloudkroter@gmail.com"
CLOUDFLARE_API_TOKEN="YJ54fCoHt0b56vKwVtm68pqVMMreXb9ZDCP8npy9"
ZONE_ID="cb49e8c58cb40928b6b4a9ee9c0928f9"

# 🎯 Текущий адрес проекта (обновляется автоматически)
CURRENT_URL="cs4nhdvhtx.skywork.website"

echo "🚀 Автоматическое обновление домена fundbot.win"
echo "📍 Текущий адрес: $CURRENT_URL"
echo "🔄 Обновляем CNAME запись..."

# Проверяем наличие необходимых инструментов
if ! command -v curl &> /dev/null; then
    echo "❌ curl не установлен"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️ jq не установлен, устанавливаем..."
    # Для Ubuntu/Debian
    sudo apt-get update && sudo apt-get install -y jq
    # Для macOS
    # brew install jq
fi

# Проверяем конфигурацию
if [[ "$CLOUDFLARE_API_TOKEN" == "ВСТАВЬТЕ_ВАШ_API_TOKEN_СЮДА" ]]; then
    echo "❌ Не настроен API Token!"
    echo "📋 Получите API Token: https://dash.cloudflare.com/profile/api-tokens"
    exit 1
fi

if [[ "$ZONE_ID" == "ВСТАВЬТЕ_ВАШ_ZONE_ID_СЮДА" ]]; then
    echo "❌ Не настроен Zone ID!"
    echo "📋 Найдите Zone ID в Cloudflare Dashboard для домена fundbot.win"
    exit 1
fi

# Получаем ID записи CNAME
echo "🔍 Ищем CNAME запись для $DOMAIN..."
RECORD_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=CNAME&name=$DOMAIN" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

# Проверяем успешность запроса
SUCCESS=$(echo $RECORD_RESPONSE | jq -r '.success')
if [ "$SUCCESS" != "true" ]; then
    echo "❌ Ошибка получения DNS записей:"
    echo $RECORD_RESPONSE | jq -r '.errors[0].message'
    exit 1
fi

RECORD_ID=$(echo $RECORD_RESPONSE | jq -r '.result[0].id')
CURRENT_TARGET=$(echo $RECORD_RESPONSE | jq -r '.result[0].content')

if [ "$RECORD_ID" = "null" ]; then
    echo "❌ CNAME запись для $DOMAIN не найдена"
    echo "📋 Создайте CNAME запись в Cloudflare Dashboard:"
    echo "   Name: @ (или $DOMAIN)"
    echo "   Target: $CURRENT_URL"
    echo "   Proxy: ON"
    exit 1
fi

echo "✅ Найдена CNAME запись: $DOMAIN → $CURRENT_TARGET"

# Проверяем, нужно ли обновление
if [ "$CURRENT_TARGET" = "$CURRENT_URL" ]; then
    echo "✅ CNAME запись уже актуальна!"
    echo "🌐 $DOMAIN уже указывает на $CURRENT_URL"
    exit 0
fi

# Обновляем CNAME запись
echo "🔄 Обновляем CNAME: $CURRENT_TARGET → $CURRENT_URL"
UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"CNAME\",\"name\":\"$DOMAIN\",\"content\":\"$CURRENT_URL\",\"proxied\":true}")

# Проверяем результат обновления
UPDATE_SUCCESS=$(echo $UPDATE_RESPONSE | jq -r '.success')

if [ "$UPDATE_SUCCESS" = "true" ]; then
    echo "🎉 CNAME запись успешно обновлена!"
    echo "🌐 $DOMAIN теперь указывает на $CURRENT_URL"
    echo "⏱️ Изменения вступят в силу через 5-15 минут"
    echo "🔗 Проверьте: https://$DOMAIN"
else
    echo "❌ Ошибка обновления CNAME:"
    echo $UPDATE_RESPONSE | jq -r '.errors[0].message'
    exit 1
fi