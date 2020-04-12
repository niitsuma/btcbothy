
(import asyncio)
(import websockets)
(import time)

(import logging)
(import json)
(import traceback)
(import threading)
(import websocket)


(import botfw)

;; (setv bina (botfw.BinanceFuture.Trade "BTC/USDT") )
;; (dir bina)
;; (dir bina.ws)
;; bina.ws.ENDPOINT

(import [botfw.base.trade [TradeBase]])
(import [botfw.binance.websocket [BinanceWebsocket BinanceFutureWebsocket]])
(import [botfw.binance.api [BinanceApi]])


(setv symbol "BTC/USDT")
(setv market_id ((. (BinanceApi.ccxt_instance)   market_id)         symbol))
(print market_id)
(setv subscribe  (+ (market_id.lower) "@trade") )
(print subscribe)

(setv subscribedic {"method" "SUBSCRIBE" "params" ["btcusdt@trade"]  "id" 1})
(print (json.dumps subscribedic))


(import [botfw.base.websocket [WebsocketBase]])

(defclass WebsocketBaseAsync  [WebsocketBase]
  (defn __init__     [self &optional     [key None]     [secret None]]
    (setv self.log           (logging.getLogger self.__class__.__name__))
    (setv self.url self.ENDPOINT)
    (setv self.key key)
    (setv self.secret secret)
    (setv self.ws None)
    (setv self.running True)
    (setv self.is_open False)
    (setv self.is_auth None)
    (setv self._request_id 1)
    (setv self._request_table          {})
    (setv self._ch_cb          {})
    (setv self.__lock          (threading.Lock))
    (setv self.__after_open_cb          [])
    (setv self.__after_auth_cb          [])
    (when
      (and self.key self.secret)
      (self.add_after_open_callback self._authenticate))
    ;;(run_forever_nonblocking self.__worker self.log 3)
    )
  
  (defn/a testws [self]
    (with/a [websocket (websockets.connect self.url)]
      (print "start socket")

;;(botfw.test_trade (botfw.BinanceFuture.Trade "BTC/USDT"))
      ;; (setv symbol "BTC/USDT")
      ;; (setv market_id ((. (BinanceApi.ccxt_instance)   market_id)         symbol))
      ;; (print market_id)
      ;; (setv subscribe  (+ (market_id.lower) "@trade") )
      ;;(print subscribe)
      ;(setv subscribe {"method" "SUBSCRIBE" "params" ["btcusdt@trade"]  "id" 1})

      (setv subscribe {"method" "SUBSCRIBE" "params" ["btcusdt@trade"]  "id" 1})
      ;(print (json.dumps subscribedic))
      ;;name = input("What's your name? ")
      (await (websocket.send  (json.dumps subscribe)))
      
      ;await websocket.send(name)
      ;;print(f"> {name}")
      (while True
        (setv greeting (await (websocket.recv)))
        (print greeting)
        )
      )
    )
  (defn dotestws [self]
    ( .run_until_complete (asyncio.get_event_loop) (self.testws))
    ( .run_forever (asyncio.get_event_loop) )

    )
  )



(defclass BinanceWebsocketAsync  [WebsocketBaseAsync]
  (setv ENDPOINT "wss://stream.binance.com:9443/ws")
  (defn command  [self op &optional [args None]  [cb None]]
    (setv msg  {"method" op  "id" self._request_id})
    (when args   (assoc msg "params" args))
    (assoc self._request_table  self._request_id   (, msg cb))
    (+= self._request_id 1)
    (self.send msg))
  (defn _subscribe  [self ch]
    (setv key           (ch.split "@"))
    (when      (<        (len key)        2)
      (raise         (Exception "Event type is not specified")))
    (setv symbol  ((.   (get key 0)   upper)))
    (setv event (if  (=   (get key 1)  "depth")  "depthUpdate"    (get key 1)))
    (assoc self._ch_cb    (, symbol event)    (get self._ch_cb ch))
    (self.command "SUBSCRIBE"   [ch]))
  (defn _authenticate  [self] )
  (defn _handle_message  [self msg]
    (setv s (msg.get "s"))
    (setv e (msg.get "e"))
    (if e ((get self._ch_cb (, s e) )  msg)
        (do
          (self.log.debug (+ "recv: " (hy-repr msg)))
          (if
            (in "id" msg) 
            (do
              (do  ;;;py2hy setv need to fix
                (setv _py2hy_anon_var_G￿26
                      (get self._request_table
                           (get msg "id")))
                (setv req
                      (get _py2hy_anon_var_G￿26 0))
                (setv cb
                      (get _py2hy_anon_var_G￿26 1)))
              (cond ;;;py2hy elif redundunt 
                [(in "result" msg)
                 (do
                   (setv res
                         (get msg "result"))
                   (self.log.info (+ (hy-repr req) " => " (hy-repr res))))]
                [(in "error" msg)
                 (do
                   (setv err
                         (get msg "error"))
                   (do
                     (setv _py2hy_anon_var_G￿30
                           (,
                             (err.get "code")
                             (err.get "message")))
                     (setv code
                           (get _py2hy_anon_var_G￿30 0))
                     (setv message
                           (get _py2hy_anon_var_G￿30 1)))
                   (self.log.error ( + req " => " code " , " message )))]
                )
              (when cb   (cb msg)))
            (do
              (self.log.warning (+ "Unknown message " msg))
                ) )))))

;; (defclass BinanceTradeAsync  [TradeBaseAsync]
;;   (setv Websocket BinanceWebsocketAsync)
;;   (defn __init__    [self symbol &optional  [ws None]]
;;     ((. (super)  __init__))
;;     (setv self.symbol symbol)
;;     (setv self.ws  (or ws  (self.Websocket)))
;;     (setv market_id ((. (BinanceApi.ccxt_instance)   market_id)           self.symbol))
;;     ;;(self.ws.subscribe  f"{ market_id.lower() }@trade" self.__on_message) ;;py2hy bug
;;     (self.ws.subscribe  (+ (market_id.lower) "@trade") self.__on_message) ;;hylang bug?
;;     )
;;   (defn __on_message  [self msg]
;;     (setv ts  (/  (get msg "E") 1000))
;;     (setv price (float (get msg "p")))
;;     (setv size  (float (get msg "q")))
;;     (when (get msg "m") (*= size  (- 1)))
;;     (setv self.ltp price)
;;     (self._trigger_callback ts price size)))


(setv bina (BinanceWebsocketAsync "BTC/USDT"))
(print (dir bina))

(bina.dotestws)
