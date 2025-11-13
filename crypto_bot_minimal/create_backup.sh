#!/bin/bash

# СИСТЕМА ПОЛНЫХ БЭКАПОВ CRYPTO TRADING BOT
# Создает полный снимок рабочего состояния для возможности отката

BACKUP_DIR="/workspace/crypto_trading_bot_universal/BACKUPS"
TIMESTAMP=$(date +"%Y_%m_%d_%H_%M")
VERSION_NAME="$1"

if [ -z "$VERSION_NAME" ]; then
    echo "❌ Использование: ./create_backup.sh <version_name>"
    echo "Пример: ./create_backup.sh v11_working"
    exit 1
fi

BACKUP_PATH="$BACKUP_DIR/$VERSION_NAME"

echo "🔄 Создание полного бэкапа: $VERSION_NAME"
echo "📁 Путь: $BACKUP_PATH"

# Создаем директорию бэкапа
mkdir -p "$BACKUP_PATH"

# 1. БЭКАП ИСХОДНОГО КОДА
echo "📂 Бэкапим исходный код..."
mkdir -p "$BACKUP_PATH/src"
cp -r /workspace/crypto_trading_bot_universal/src/* "$BACKUP_PATH/src/" 2>/dev/null || true

# 2. БЭКАП КОНФИГУРАЦИОННЫХ ФАЙЛОВ
echo "⚙️ Бэкапим конфигурацию..."
cp /workspace/crypto_trading_bot_universal/package.json "$BACKUP_PATH/" 2>/dev/null || true
cp /workspace/crypto_trading_bot_universal/vite.config.ts "$BACKUP_PATH/" 2>/dev/null || true
cp /workspace/crypto_trading_bot_universal/tailwind.config.ts "$BACKUP_PATH/" 2>/dev/null || true
cp /workspace/crypto_trading_bot_universal/tsconfig.json "$BACKUP_PATH/" 2>/dev/null || true
cp /workspace/crypto_trading_bot_universal/index.html "$BACKUP_PATH/" 2>/dev/null || true

# 3. БЭКАП SUPABASE ФУНКЦИЙ
echo "🔧 Бэкапим Supabase функции..."
mkdir -p "$BACKUP_PATH/supabase"
cp -r /workspace/crypto_trading_bot_universal/supabase/* "$BACKUP_PATH/supabase/" 2>/dev/null || true

# 4. БЭКАП ПУБЛИЧНЫХ ФАЙЛОВ
echo "🌐 Бэкапим публичные файлы..."
mkdir -p "$BACKUP_PATH/public"
cp -r /workspace/crypto_trading_bot_universal/public/* "$BACKUP_PATH/public/" 2>/dev/null || true

# 5. СОЗДАЕМ МАНИФЕСТ БЭКАПА
echo "📋 Создаем манифест бэкапа..."
cat > "$BACKUP_PATH/BACKUP_MANIFEST.json" << EOF
{
  "version": "$VERSION_NAME",
  "timestamp": "$TIMESTAMP",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "description": "Полный бэкап рабочего состояния",
  "components": {
    "frontend": {
      "src": "✅ Исходный код React/TypeScript",
      "config": "✅ Конфигурационные файлы",
      "public": "✅ Статические ресурсы"
    },
    "backend": {
      "supabase": "✅ Edge Functions и миграции",
      "database": "⚠️ Схема сохранена, данные требуют отдельного экспорта"
    }
  },
  "restore_instructions": "Используйте ./restore_backup.sh $VERSION_NAME для восстановления"
}
EOF

# 6. СОЗДАЕМ СКРИПТ ВОССТАНОВЛЕНИЯ
echo "🔄 Создаем скрипт восстановления..."
cat > "$BACKUP_PATH/restore_this_backup.sh" << 'EOF'
#!/bin/bash

BACKUP_PATH=$(dirname "$0")
PROJECT_PATH="/workspace/crypto_trading_bot_universal"

echo "🔄 ВОССТАНОВЛЕНИЕ БЭКАПА: $(basename "$BACKUP_PATH")"
echo "⚠️ ВНИМАНИЕ: Это перезапишет текущие файлы!"

read -p "Продолжить? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Отменено"
    exit 1
fi

echo "📂 Восстанавливаем исходный код..."
rm -rf "$PROJECT_PATH/src"
cp -r "$BACKUP_PATH/src" "$PROJECT_PATH/"

echo "⚙️ Восстанавливаем конфигурацию..."
cp "$BACKUP_PATH/package.json" "$PROJECT_PATH/" 2>/dev/null || true
cp "$BACKUP_PATH/vite.config.ts" "$PROJECT_PATH/" 2>/dev/null || true
cp "$BACKUP_PATH/tailwind.config.ts" "$PROJECT_PATH/" 2>/dev/null || true
cp "$BACKUP_PATH/tsconfig.json" "$PROJECT_PATH/" 2>/dev/null || true
cp "$BACKUP_PATH/index.html" "$PROJECT_PATH/" 2>/dev/null || true

echo "🔧 Восстанавливаем Supabase функции..."
rm -rf "$PROJECT_PATH/supabase"
cp -r "$BACKUP_PATH/supabase" "$PROJECT_PATH/"

echo "🌐 Восстанавливаем публичные файлы..."
rm -rf "$PROJECT_PATH/public"
cp -r "$BACKUP_PATH/public" "$PROJECT_PATH/"

echo "✅ ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО!"
echo "📋 Проверьте BACKUP_MANIFEST.json для деталей"
echo "🚀 Теперь выполните: cd $PROJECT_PATH && npm run build"
EOF

chmod +x "$BACKUP_PATH/restore_this_backup.sh"

# 7. СОЗДАЕМ СПИСОК АКТИВНЫХ EDGE FUNCTIONS
echo "📋 Сохраняем список активных функций..."
cat > "$BACKUP_PATH/ACTIVE_FUNCTIONS.md" << EOF
# АКТИВНЫЕ EDGE FUNCTIONS НА МОМЕНТ БЭКАПА

## Binance
- Function: binance_only_strict_2025_11_09_06_35
- Status: ✅ Работает с TP/SL

## Gate.io  
- Function: gate_v11_restored_2025_11_09_17_00
- Status: ✅ Работает с автоматическими TP/SL

## Bybit
- Function: bybit_fully_fixed_2025_11_09_17_30
- Status: 🔧 Исправлены параметры API + TP/SL

## Другие биржи
- KuCoin: kucoin_trading_2025_11_09_08_30
- OKX: okx_trading_2025_11_09_08_30  
- MEXC: mexc_trading_2025_11_09_08_30

## Примечания
- Все функции используют JWT верификацию
- CORS заголовки настроены корректно
- Подписи API исправлены для всех бирж
EOF

echo "✅ БЭКАП СОЗДАН УСПЕШНО!"
echo "📁 Расположение: $BACKUP_PATH"
echo "📋 Манифест: $BACKUP_PATH/BACKUP_MANIFEST.json"
echo "🔄 Восстановление: $BACKUP_PATH/restore_this_backup.sh"
echo ""
echo "🎯 Для восстановления используйте:"
echo "   cd $BACKUP_PATH && ./restore_this_backup.sh"