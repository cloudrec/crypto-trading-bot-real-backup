#!/bin/bash

# СКРИПТ ВОССТАНОВЛЕНИЯ БЭКАПОВ
# Позволяет быстро откатиться к любой рабочей версии

BACKUP_DIR="/workspace/crypto_trading_bot_universal/BACKUPS"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Директория бэкапов не найдена: $BACKUP_DIR"
    exit 1
fi

echo "🔄 СИСТЕМА ВОССТАНОВЛЕНИЯ БЭКАПОВ"
echo "=================================="

# Показываем доступные бэкапы
echo "📋 Доступные бэкапы:"
echo ""

counter=1
declare -a backups

for backup in "$BACKUP_DIR"/*; do
    if [ -d "$backup" ]; then
        backup_name=$(basename "$backup")
        manifest="$backup/BACKUP_MANIFEST.json"
        
        if [ -f "$manifest" ]; then
            timestamp=$(grep '"timestamp"' "$manifest" | cut -d'"' -f4)
            description=$(grep '"description"' "$manifest" | cut -d'"' -f4)
            echo "[$counter] $backup_name"
            echo "    📅 Создан: $timestamp"
            echo "    📝 $description"
            echo ""
            backups[$counter]="$backup"
            ((counter++))
        fi
    fi
done

if [ ${#backups[@]} -eq 0 ]; then
    echo "❌ Бэкапы не найдены"
    exit 1
fi

# Выбор бэкапа
echo "🎯 Выберите номер бэкапа для восстановления (1-$((counter-1))):"
read -p "Номер: " choice

if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$counter" ]; then
    echo "❌ Неверный выбор"
    exit 1
fi

selected_backup="${backups[$choice]}"
backup_name=$(basename "$selected_backup")

echo ""
echo "🎯 ВЫБРАН БЭКАП: $backup_name"
echo "📁 Путь: $selected_backup"

# Показываем информацию о бэкапе
manifest="$selected_backup/BACKUP_MANIFEST.json"
if [ -f "$manifest" ]; then
    echo ""
    echo "📋 ИНФОРМАЦИЯ О БЭКАПЕ:"
    cat "$manifest" | grep -E '"version"|"timestamp"|"description"' | sed 's/^  //'
fi

echo ""
echo "⚠️ ВНИМАНИЕ: Это действие перезапишет все текущие файлы!"
echo "🔄 Будут восстановлены:"
echo "   - Исходный код (src/)"
echo "   - Конфигурация (package.json, vite.config.ts, etc.)"
echo "   - Supabase функции (supabase/)"
echo "   - Публичные файлы (public/)"

echo ""
read -p "❓ Продолжить восстановление? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Восстановление отменено"
    exit 1
fi

# Выполняем восстановление
echo ""
echo "🔄 НАЧИНАЕМ ВОССТАНОВЛЕНИЕ..."

restore_script="$selected_backup/restore_this_backup.sh"
if [ -f "$restore_script" ]; then
    # Запускаем скрипт восстановления с автоматическим подтверждением
    echo "y" | bash "$restore_script"
else
    echo "❌ Скрипт восстановления не найден: $restore_script"
    exit 1
fi

echo ""
echo "✅ ВОССТАНОВЛЕНИЕ ЗАВЕРШЕНО!"
echo ""
echo "🚀 СЛЕДУЮЩИЕ ШАГИ:"
echo "1. cd /workspace/crypto_trading_bot_universal"
echo "2. npm run build"
echo "3. Опубликовать сайт"
echo ""
echo "📋 Проверьте ACTIVE_FUNCTIONS.md для списка функций"