(import [botfw.base.trade [TradeBase]])
(import [botfw.binance.websocket [BinanceWebsocket BinanceFutureWebsocket]])
(import [botfw.binance.api [BinanceApi]])
(defclass BinanceTrade  [TradeBase]
  (setv Websocket BinanceWebsocket)
  (defn __init__    [self symbol &optional  [ws None]]
    ((. (super)  __init__))
    (setv self.symbol symbol)
    (setv self.ws  (or ws  (self.Websocket)))
    (setv market_id ((. (BinanceApi.ccxt_instance)   market_id)           self.symbol))
    ;;(self.ws.subscribe  f"{ market_id.lower() }@trade" self.__on_message) ;;py2hy bug
    (self.ws.subscribe  (+ (market_id.lower) "@trade") self.__on_message) ;;hylang bug?
    )
  (defn __on_message  [self msg]
    (setv ts  (/  (get msg "E") 1000))
    (setv price (float (get msg "p")))
    (setv size  (float (get msg "q")))
    (when (get msg "m") (*= size  (- 1)))
    (setv self.ltp price)
    (self._trigger_callback ts price size)))
(defclass BinanceFutureTrade [BinanceTrade] (setv Websocket BinanceFutureWebsocket))
