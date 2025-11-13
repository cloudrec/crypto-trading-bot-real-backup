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
    console.log('🎯 Edge Function Called')
    
    const body = await req.json()
    console.log('📊 Request Body:', body)

    const { exchange, symbol, side, leverage, amount } = body

    console.log('📋 Parsed Parameters:', { exchange, symbol, side, leverage, amount })

    // Простейший расчет
    const totalAmount = parseFloat(amount || '100') * parseFloat(leverage || '10')
    
    // Генерируем ID
    const orderId = `test_${Date.now()}`
    
    console.log('💰 Calculated Total:', totalAmount)
    console.log('🆔 Order ID:', orderId)

    const result = {
      success: true,
      message: `Тестовый ордер создан: ${orderId}`,
      order: {
        orderId: orderId,
        symbol: symbol || 'SUPERUSDT',
        side: side || 'Buy',
        leverage: leverage || '10',
        amount: amount || '100',
        totalAmount: totalAmount.toString(),
        status: 'Test Success',
        exchange: 'Bybit Test'
      }
    }

    console.log('✅ Result:', result)

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('❌ Error:', error)
    
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