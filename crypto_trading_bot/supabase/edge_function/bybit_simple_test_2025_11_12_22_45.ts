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
    const { exchange, symbol, side, leverage, amount, totalAmount, stopLoss, takeProfit, delayMs } = await req.json()

    console.log('🎯 Bybit Test Order Request:', {
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

    // Проверяем что все параметры переданы
    if (!symbol || !side || !leverage || !amount) {
      throw new Error('Отсутствуют обязательные параметры: symbol, side, leverage, amount')
    }

    // Симулируем задержку как в реальном API
    if (delayMs && parseInt(delayMs) > 0) {
      await new Promise(resolve => setTimeout(resolve, parseInt(delayMs)))
    }

    // Рассчитываем итоговую сумму
    const calculatedTotal = (parseFloat(amount) * parseFloat(leverage)).toFixed(2)
    
    // Генерируем уникальный ID ордера
    const orderId = `bybit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    const orderLinkId = `test_${Date.now()}`

    // Симулируем успешный ответ Bybit API
    const mockOrder = {
      orderId: orderId,
      orderLinkId: orderLinkId,
      symbol: symbol,
      side: side,
      leverage: leverage,
      amount: amount,
      totalAmount: calculatedTotal,
      stopLoss: stopLoss || 'не установлен',
      takeProfit: takeProfit || 'не установлен',
      status: 'Filled',
      exchange: 'Bybit (Test)',
      fee: '0.1%',
      timestamp: new Date().toISOString(),
      price: side === 'Buy' ? '1.0000' : '0.9999'
    }

    console.log('✅ Bybit Mock Order Created:', mockOrder)

    const result = {
      success: true,
      message: `🎯 Bybit тестовый ордер размещен: ${orderId}`,
      order: mockOrder
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error: any) {
    console.error('❌ Bybit Test Order Error:', error)
    
    const errorResult = {
      success: false,
      message: `Ошибка размещения тестового ордера: ${error.message}`,
      error: error.message
    }

    return new Response(JSON.stringify(errorResult), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})