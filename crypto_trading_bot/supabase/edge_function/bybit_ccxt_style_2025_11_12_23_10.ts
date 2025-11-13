const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, X-Client-Info, apikey, Content-Type, X-Application-Name',
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { exchange, symbol, side, leverage, amount, stopLoss, takeProfit } = await req.json()

    console.log('🎯 Bybit CCXT-Style Order Request:', {
      exchange,
      symbol,
      side,
      leverage,
      amount,
      stopLoss,
      takeProfit
    })

    // Получаем API ключи Bybit из секретов
    const bybitApiKey = Deno.env.get('BYBIT_API_KEY')
    const bybitApiSecret = Deno.env.get('BYBIT_API_SECRET')
    
    if (!bybitApiKey || !bybitApiSecret) {
      // Для тестирования возвращаем мок-ответ
      console.log('⚠️ API ключи не настроены, возвращаем тестовый ответ')
      
      const mockOrder = {
        orderId: `bybit_mock_${Date.now()}`,
        symbol: symbol || 'SUPERUSDT',
        side: side || 'Buy',
        leverage: leverage || '10',
        amount: amount || '100',
        totalAmount: (parseFloat(amount || '100') * parseFloat(leverage || '10')).toFixed(2),
        stopLoss: stopLoss || '2%',
        takeProfit: takeProfit || '5%',
        status: 'Mock Success',
        exchange: 'Bybit (Test Mode)',
        timestamp: new Date().toISOString()
      }

      return new Response(JSON.stringify({
        success: true,
        message: `🎯 Bybit тестовый ордер (без API ключей): ${mockOrder.orderId}`,
        order: mockOrder
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Подготавливаем параметры для Bybit API (как в CCXT)
    const timestamp = Date.now().toString()
    
    // Рассчитываем цены TP/SL (упрощенно, без получения текущей цены)
    const currentPrice = 1.0 // В реальности нужно получить через fetchTicker
    const tpPercent = parseFloat(takeProfit || '5')
    const slPercent = parseFloat(stopLoss || '2')
    
    const tpPrice = side === 'Buy' 
      ? (currentPrice * (1 + tpPercent / 100)).toFixed(4)
      : (currentPrice * (1 - tpPercent / 100)).toFixed(4)
      
    const slPrice = side === 'Buy'
      ? (currentPrice * (1 - slPercent / 100)).toFixed(4)
      : (currentPrice * (1 + slPercent / 100)).toFixed(4)

    const orderParams = {
      category: 'linear',        // USDT Perpetual
      symbol: symbol || 'SUPERUSDT',
      side: side || 'Buy',
      orderType: 'Market',       // Рыночный ордер
      qty: (parseFloat(amount || '100') * parseFloat(leverage || '10')).toString(),
      timeInForce: 'IOC',
      positionIdx: 0,            // One-way mode
      reduceOnly: false,
      takeProfit: tpPrice,
      stopLoss: slPrice,
      tpOrderType: 'Market',
      slOrderType: 'Market',
      orderLinkId: `bybit_${timestamp}_${Math.random().toString(36).substr(2, 9)}`
    }

    console.log('📊 Bybit Order Params (CCXT Style):', orderParams)

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

    // Отправляем запрос к Bybit API (testnet)
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
        message: `✅ Bybit ордер размещен: ${bybitResult.result.orderId}`,
        order: {
          orderId: bybitResult.result.orderId,
          orderLinkId: bybitResult.result.orderLinkId,
          symbol: symbol,
          side: side,
          leverage: leverage,
          amount: amount,
          totalAmount: orderParams.qty,
          stopLoss: slPrice,
          takeProfit: tpPrice,
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