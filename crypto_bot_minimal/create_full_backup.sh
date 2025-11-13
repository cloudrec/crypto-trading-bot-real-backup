#!/bin/bash

# 🗄️ Скрипт для создания полного бэкапа (код + база данных)
# Использование: ./create_full_backup.sh [название_бэкапа]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗄️ Создание полного бэкапа (код + база данных)${NC}"

# Получаем название бэкапа
BACKUP_NAME=${1:-"crypto_trading_bot_dev_full_backup_$(date +%Y%m%d_%H%M%S)"}
BACKUP_DIR="/workspace/${BACKUP_NAME}"

echo -e "${YELLOW}📁 Название бэкапа: ${BACKUP_NAME}${NC}"

# Проверяем, что мы в правильной директории
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Ошибка: Запустите скрипт из корневой директории проекта${NC}"
    exit 1
fi

# Создаем директорию для бэкапа
echo -e "${BLUE}📁 Создаем директорию бэкапа...${NC}"
mkdir -p "${BACKUP_DIR}"

# 1. Копируем все файлы проекта
echo -e "${BLUE}📂 Копируем файлы проекта...${NC}"
cp -r . "${BACKUP_DIR}/"

# Удаляем ненужные файлы из бэкапа
rm -rf "${BACKUP_DIR}/node_modules" 2>/dev/null || true
rm -rf "${BACKUP_DIR}/dist" 2>/dev/null || true
rm -rf "${BACKUP_DIR}/.git" 2>/dev/null || true

# 2. Экспортируем базу данных
echo -e "${BLUE}🗄️ Экспортируем базу данных...${NC}"

# Получаем URL и ключи Supabase из .env или переменных окружения
if [ -f ".env" ]; then
    source .env
fi

SUPABASE_URL=${VITE_SUPABASE_URL:-$SUPABASE_URL}
SUPABASE_ANON_KEY=${VITE_SUPABASE_ANON_KEY:-$SUPABASE_ANON_KEY}

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo -e "${RED}❌ Ошибка: Не найдены переменные SUPABASE_URL или SUPABASE_ANON_KEY${NC}"
    echo -e "${YELLOW}💡 Убедитесь, что файл .env содержит эти переменные${NC}"
    exit 1
fi

# Вызываем Edge Function для экспорта базы данных
echo -e "${BLUE}📊 Вызываем функцию экспорта базы данных...${NC}"

DB_EXPORT_RESPONSE=$(curl -s -X POST \
    "${SUPABASE_URL}/functions/v1/database_backup_export_2025_11_08_08_00" \
    -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"action": "export_database"}')

# Проверяем успешность экспорта
if echo "$DB_EXPORT_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ База данных успешно экспортирована${NC}"
    
    # Извлекаем SQL дамп из ответа
    SQL_DUMP=$(echo "$DB_EXPORT_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data['sql_dump'])
except:
    print('ERROR: Could not parse JSON response')
    ")
    
    if [ "$SQL_DUMP" != "ERROR: Could not parse JSON response" ]; then
        # Сохраняем SQL дамп в файл
        echo "$SQL_DUMP" > "${BACKUP_DIR}/database_backup.sql"
        echo -e "${GREEN}💾 SQL дамп сохранен в ${BACKUP_NAME}/database_backup.sql${NC}"
    else
        echo -e "${RED}❌ Ошибка: Не удалось извлечь SQL дамп из ответа${NC}"
        echo -e "${YELLOW}📄 Ответ сервера: ${DB_EXPORT_RESPONSE}${NC}"
    fi
else
    echo -e "${RED}❌ Ошибка экспорта базы данных${NC}"
    echo -e "${YELLOW}📄 Ответ сервера: ${DB_EXPORT_RESPONSE}${NC}"
    echo -e "${YELLOW}⚠️ Продолжаем создание бэкапа только с файлами...${NC}"
fi

# 3. Создаем информационный файл о бэкапе
echo -e "${BLUE}📋 Создаем информационный файл...${NC}"
cat > "${BACKUP_DIR}/BACKUP_INFO.txt" << EOF
🗄️ ПОЛНЫЙ БЭКАП ПРОЕКТА crypto_trading_bot_dev
================================================

📅 Дата создания: $(date)
📁 Название бэкапа: ${BACKUP_NAME}
🔧 Тип бэкапа: Полный (код + база данных)

📂 Содержимое бэкапа:
- Все файлы проекта (src, public, supabase, etc.)
- База данных (database_backup.sql)
- Конфигурационные файлы (.env, package.json, etc.)
- Edge Functions (supabase/edge_function/)

🔄 Для восстановления используйте:
./restore_full_backup.sh ${BACKUP_NAME}

📊 Статистика:
- Размер бэкапа: $(du -sh "${BACKUP_DIR}" | cut -f1)
- Количество файлов: $(find "${BACKUP_DIR}" -type f | wc -l)

⚠️ ВАЖНО: Этот бэкап содержит полную копию проекта и базы данных
на момент создания. При восстановлении текущие данные будут заменены!
EOF

# 4. Показываем итоговую информацию
echo -e "${GREEN}🎉 Полный бэкап успешно создан!${NC}"
echo -e "${BLUE}📁 Расположение: ${BACKUP_DIR}${NC}"
echo -e "${BLUE}📊 Размер: $(du -sh "${BACKUP_DIR}" | cut -f1)${NC}"
echo -e "${BLUE}📄 Файлов: $(find "${BACKUP_DIR}" -type f | wc -l)${NC}"

echo -e "\n${YELLOW}📋 Содержимое бэкапа:${NC}"
ls -la "${BACKUP_DIR}/" | head -10

if [ -f "${BACKUP_DIR}/database_backup.sql" ]; then
    echo -e "\n${GREEN}✅ База данных включена в бэкап${NC}"
    echo -e "${BLUE}📊 Размер SQL дампа: $(du -sh "${BACKUP_DIR}/database_backup.sql" | cut -f1)${NC}"
else
    echo -e "\n${YELLOW}⚠️ База данных НЕ включена в бэкап${NC}"
fi

echo -e "\n${BLUE}🔄 Для восстановления используйте:${NC}"
echo -e "${GREEN}./restore_full_backup.sh ${BACKUP_NAME}${NC}"