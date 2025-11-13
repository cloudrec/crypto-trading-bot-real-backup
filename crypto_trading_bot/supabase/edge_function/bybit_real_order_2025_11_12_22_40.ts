import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, X-Client-Info, apikey, Content-Type, X-Application-Name',
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { exchange, symbol, side, leverage, amount, totalAmount, stopLoss, takeProfit, delayMs } = await req.json()

    console.log('🎯 Bybit Real Order Request:', {
      exchange,
      symbol,
      side,
      leverage,
      amount,
      totalAmount,
      stopLoss,
      takeProfit,
      delayMs
    })

    // Получаем API ключи Bybit из секретов
    const bybitApiKey = Deno.env.get('BYBIT_API_KEY')
    const bybitApiSecret = Deno.env.get('BYBIT_API_SECRET')
    
    if (!bybitApiKey || !bybitApiSecret) {
      throw new Error('Bybit API ключи не настроены в секретах')
    }

    // Подготавливаем параметры для Bybit API
    const timestamp = Date.now().toString()
    const orderParams = {
      category: 'linear',        // USDT Perpetual
      symbol: symbol,            // SUPERUSDT
      side: side,                // Buy/Sell
      orderType: 'Market',       // Рыночный ордер
      qty: totalAmount,          // Общая сумма с плечом
      timeInForce: 'IOC',        // Immediate or Cancel
      positionIdx: 0,            // One-way mode
      reduceOnly: false,         // Открываем позицию
      orderLinkId: `bybit_${timestamp}_${Math.random().toString(36).substr(2, 9)}`
    }

    // Добавляем Take Profit и Stop Loss если указаны
    if (takeProfit && parseFloat(takeProfit) > 0) {
      const currentPrice = 1.0 // Здесь нужно получить текущую цену
      const tpPrice = side === 'Buy' 
        ? (currentPrice * (1 + parseFloat(takeProfit) / 100)).toFixed(4)
        : (currentPrice * (1 - parseFloat(takeProfit) / 100)).toFixed(4)
      orderParams.takeProfit = tpPrice
      orderParams.tpOrderType = 'Market'
    }

    if (stopLoss && parseFloat(stopLoss) > 0) {
      const currentPrice = 1.0 // Здесь нужно получить текущую цену
      const slPrice = side === 'Buy'
        ? (currentPrice * (1 - parseFloat(stopLoss) / 100)).toFixed(4)
        : (currentPrice * (1 + parseFloat(stopLoss) / 100)).toFixed(4)
      orderParams.stopLoss = slPrice
      orderParams.slOrderType = 'Market'
    }

    console.log('📊 Bybit Order Params:', orderParams)

    // Создаем подпись для Bybit API
    const queryString = Object.keys(orderParams)
      .sort()
      .map(key => `${key}=${orderParams[key]}`)
      .join('&')
    
    const signPayload = timestamp + bybitApiKey + '5000' + queryString
    
    // Создаем HMAC SHA256 подпись
    const encoder = new TextEncoder()
    const keyData = encoder.encode(bybitApiSecret)
    const messageData = encoder.encode(signPayload)
    
    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    
    const signature = await crypto.subtle.sign('HMAC', cryptoKey, messageData)
    const signatureHex = Array.from(new Uint8Array(signature))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    // Отправляем запрос к Bybit API
    const bybitResponse = await fetch('https://api-testnet.bybit.com/v5/order/create', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-BAPI-API-KEY': bybitApiKey,
        'X-BAPI-SIGN': signatureHex,
        'X-BAPI-TIMESTAMP': timestamp,
        'X-BAPI-RECV-WINDOW': '5000'
      },
      body: JSON.stringify(orderParams)
    })

    const bybitResult = await bybitResponse.json()
    
    console.log('🚀 Bybit API Response:', bybitResult)

    if (bybitResult.retCode === 0) {
      // Успешный ордер
      const orderResult = {
        success: true,
        message: `🎯 Bybit ордер размещен: ${bybitResult.result.orderId}`,
        order: {
          orderId: bybitResult.result.orderId,
          orderLinkId: bybitResult.result.orderLinkId,
          symbol: symbol,
          side: side,
          leverage: leverage,
          amount: amount,
          totalAmount: totalAmount,
          stopLoss: stopLoss,
          takeProfit: takeProfit,
          status: 'Submitted',
          exchange: 'Bybit',
          timestamp: new Date().toISOString()
        }
      }

      console.log('✅ Bybit Order Success:', orderResult)
      
      return new Response(JSON.stringify(orderResult), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    } else {
      // Ошибка от Bybit API
      throw new Error(`Bybit API Error: ${bybitResult.retMsg} (Code: ${bybitResult.retCode})`)
    }

  } catch (error: any) {
    console.error('❌ Bybit Order Error:', error)
    
    return new Response(JSON.stringify({
      success: false,
      message: `Ошибка размещения ордера: ${error.message}`,
      error: error.message
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})