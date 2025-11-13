# 🗂️ ПОЛНЫЙ СИСТЕМНЫЙ БЭКАП v21 - CRYPTO TRADING BOT UNIVERSAL
**Дата создания:** 2025-11-09 18:00 UTC  
**Версия:** v21 - Критические исправления Bybit + Gate.io  
**Статус:** ✅ РАБОЧАЯ ВЕРСИЯ  

---

## 🌐 **ТЕКУЩИЙ РАБОЧИЙ САЙТ**
**URL:** https://8xy9zgdgie.skywork.website  
**Описание:** Исправлены критические проблемы Bybit баланса и Gate.io TP/SL  

---

## 📊 **АКТИВНЫЕ EDGE FUNCTIONS (v21)**

### **🔥 ОСНОВНЫЕ БИРЖИ:**
| Биржа | Function Name | Статус | Особенности |
|-------|---------------|--------|-------------|
| **Binance** | `binance_only_strict_2025_11_09_06_35` | ✅ Работает | TP/SL, символы, точность |
| **Gate.io** | `gate_fixed_tpsl_close_2025_11_09_17_50` | ✅ Исправлено | Реальные TP/SL, правильное закрытие |
| **Bybit** | `bybit_balance_fixed_2025_11_09_17_45` | ✅ Исправлено | Баланс USDT, встроенные TP/SL |

### **🟩 ДОПОЛНИТЕЛЬНЫЕ БИРЖИ:**
| Биржа | Function Name | Статус |
|-------|---------------|--------|
| **KuCoin** | `kucoin_trading_2025_11_09_08_30` | ✅ Базовая |
| **OKX** | `okx_trading_2025_11_09_08_30` | ✅ Базовая |
| **MEXC** | `mexc_trading_2025_11_09_08_30` | ✅ Базовая |

---

## 🗃️ **БАЗА ДАННЫХ SUPABASE**

### **📋 Таблицы:**
```sql
-- Пользователи и подписки
CREATE TABLE user_subscriptions_dev (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- API ключи бирж
CREATE TABLE api_keys_dev (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  exchange TEXT NOT NULL,
  api_key TEXT NOT NULL,
  api_secret TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Настройки торговли
CREATE TABLE trading_settings_dev (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  exchange TEXT DEFAULT 'binance',
  base_asset TEXT DEFAULT 'SUPER',
  order_amount_usd NUMERIC DEFAULT 10,
  long_tp NUMERIC DEFAULT 0.02,
  long_sl NUMERIC DEFAULT 0.02,
  short_tp NUMERIC DEFAULT 0.02,
  short_sl NUMERIC DEFAULT 0.02,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **🔐 RLS Политики:**
```sql
-- Пользователи видят только свои данные
CREATE POLICY "Users can view own subscriptions" ON user_subscriptions_dev
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own api keys" ON api_keys_dev
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own settings" ON trading_settings_dev
  FOR ALL USING (auth.uid() = user_id);
```

---

## 📁 **СТРУКТУРА ПРОЕКТА**

### **🎯 Основные файлы:**
```
/workspace/crypto_trading_bot_universal/
├── src/
│   ├── components/
│   │   ├── TradingDashboard.tsx     # Главный интерфейс торговли
│   │   ├── Auth.tsx                 # Аутентификация
│   │   ├── PaymentForm.tsx          # Форма оплаты
│   │   └── ui/                      # UI компоненты
│   ├── integrations/
│   │   └── supabase/
│   │       └── client.ts            # Клиент Supabase
│   └── lib/
│       └── utils.ts                 # Утилиты
├── supabase/
│   ├── migrations/                  # Миграции БД
│   └── edge_function/              # Edge Functions
├── public/                         # Статические файлы
├── BACKUPS/                        # Система бэкапов
│   ├── v11_working_with_fixed_bybit/
│   └── v20_critical_fixes_bybit_gate/
└── package.json                    # Зависимости
```

---

## 🔧 **КРИТИЧЕСКИЕ ИСПРАВЛЕНИЯ v21**

### **🟠 BYBIT ИСПРАВЛЕНИЯ:**
- ✅ **Баланс USDT:** Правильное чтение `walletBalance`
- ✅ **API параметры:** `settleCoin=USDT` добавлен везде
- ✅ **Встроенные TP/SL:** +5%/-5% в основном ордере
- ✅ **Проверка позиции:** Через 3 секунды после ордера

### **🔵 GATE.IO ИСПРАВЛЕНИЯ:**
- ✅ **Реальные TP/SL:** Расчет на основе `entry_price` из позиции
- ✅ **Отдельные ордера:** TP/SL как лимитные с `reduce_only`
- ✅ **Правильное закрытие:** Противоположный размер (-30 для закрытия +30)
- ✅ **Отмена ордеров:** Сначала отменяем все TP/SL

---

## 🚀 **СИСТЕМА БЭКАПОВ**

### **📋 Доступные бэкапы:**
```bash
# Просмотр всех бэкапов
ls -la /workspace/crypto_trading_bot_universal/BACKUPS/

# Восстановление любого бэкапа
cd /workspace/crypto_trading_bot_universal
./restore_backup.sh
```

### **🔄 Создание нового бэкапа:**
```bash
cd /workspace/crypto_trading_bot_universal
./create_backup.sh название_версии
```

---

## 🔑 **СЕКРЕТЫ SUPABASE**

### **📋 Настроенные секреты:**
- `STRIPE_SECRET_KEY` - Платежи Stripe
- `RESEND_API_KEY` - Email уведомления
- `RESEND_DOMAIN` - Домен для email

### **🔐 Доступ к секретам:**
```typescript
// В Edge Functions
const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
const resendKey = Deno.env.get('RESEND_API_KEY');
```

---

## 📊 **СТАТИСТИКА ПРОЕКТА**

### **📈 Функциональность:**
- ✅ **6 бирж:** Binance, Gate.io, Bybit, KuCoin, OKX, MEXC
- ✅ **Автоматические TP/SL:** На всех основных биржах
- ✅ **Управление позициями:** Открытие, закрытие, отмена
- ✅ **Система подписок:** Stripe интеграция
- ✅ **Безопасность:** JWT, RLS политики

### **🔧 Технологии:**
- **Frontend:** React + TypeScript + Tailwind CSS
- **Backend:** Supabase + Edge Functions
- **База данных:** PostgreSQL с RLS
- **Платежи:** Stripe
- **Email:** Resend
- **Деплой:** Skywork CDN

---

## 🛠️ **КОМАНДЫ ВОССТАНОВЛЕНИЯ**

### **🔄 Полное восстановление проекта:**
```bash
# 1. Восстановить код
cd /workspace/crypto_trading_bot_universal
./restore_backup.sh

# 2. Пересобрать проект
npm run build

# 3. Опубликовать
# Используйте publish_website tool
```

### **🗃️ Восстановление базы данных:**
```sql
-- Выполнить все миграции из supabase/migrations/
-- Настроить RLS политики
-- Проверить Edge Functions
```

---

## 📞 **КОНТАКТЫ И ПОДДЕРЖКА**

### **🎯 Для восстановления:**
1. **Код:** Используйте `./restore_backup.sh`
2. **База данных:** Проверьте миграции в `supabase/migrations/`
3. **Edge Functions:** Файлы в `supabase/edge_function/`
4. **Секреты:** Настройте в Supabase Dashboard

### **🚨 Критические файлы:**
- `src/components/TradingDashboard.tsx` - Основная логика
- `supabase/edge_function/` - Все торговые функции
- `src/integrations/supabase/client.ts` - Подключение к Supabase

---

## ✅ **ПРОВЕРОЧНЫЙ СПИСОК**

### **🔍 После восстановления проверить:**
- [ ] Сайт загружается
- [ ] Аутентификация работает
- [ ] Подключение к биржам
- [ ] Размещение ордеров
- [ ] TP/SL устанавливаются
- [ ] Закрытие позиций
- [ ] Система платежей

---

**📋 ЭТОТ БЭКАП СОДЕРЖИТ ВСЕ НЕОБХОДИМОЕ ДЛЯ ПОЛНОГО ВОССТАНОВЛЕНИЯ ПРОЕКТА**

**🚀 Версия v21 - Стабильная и протестированная**