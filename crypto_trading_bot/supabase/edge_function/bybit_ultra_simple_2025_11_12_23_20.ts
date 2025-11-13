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
    console.log('🎯 Edge Function Started')
    
    const body = await req.json()
    console.log('📊 Request Body:', body)

    const { exchange, symbol, side, leverage, amount, stopLoss, takeProfit } = body

    console.log('📋 Parameters:', { exchange, symbol, side, leverage, amount, stopLoss, takeProfit })

    // Простой расчет
    const totalAmount = (parseFloat(amount || '100') * parseFloat(leverage || '10')).toFixed(2)
    
    // Генерируем ID
    const orderId = `bybit_simple_${Date.now()}`
    
    console.log('💰 Total Amount:', totalAmount)
    console.log('🆔 Order ID:', orderId)

    // Простой мок-ответ
    const mockOrder = {
      orderId: orderId,
      symbol: symbol || 'SUPERUSDT',
      side: side || 'Buy',
      leverage: leverage || '10',
      amount: amount || '100',
      totalAmount: totalAmount,
      stopLoss: stopLoss || '2%',
      takeProfit: takeProfit || '5%',
      status: 'Mock Success',
      exchange: 'Bybit (Simple Test)',
      timestamp: new Date().toISOString()
    }

    console.log('✅ Mock Order:', mockOrder)

    const result = {
      success: true,
      message: `🎯 Простой тестовый ордер: ${orderId}`,
      order: mockOrder
    }

    console.log('🚀 Final Result:', result)

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('❌ Error in Edge Function:', error)
    
    return new Response(JSON.stringify({
      success: false,
      message: `Error: ${error.message}`,
      error: error.toString()
    }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})