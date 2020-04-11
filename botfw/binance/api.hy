;;(require [hy015removed.core [*]])
(import ccxt)
(defclass Py2HyReturnException [Exception]  ;;;need fix py2hy
  (defn __init__ [self retvalue]
    (setv self.retvalue retvalue)))

(import [botfw.base.api [ApiBase]])  ;;;py2hy import path need fix
(defclass BinanceApi   [ApiBase ccxt.binance]
  (setv FUTURE False)
  (setv _ccxt_class ccxt.binance)
  (defn __init__  [self &optional     [ccxt_config      {}]]
    (when self.FUTURE
      (assoc        (ccxt_config.setdefault "options"   {})   "defaultType" "future"))
    (ApiBase.__init__ self)
    (ccxt.binance.__init__ self ccxt_config)
    (self.load_markets)
    (setv self.fapiPrivate_get_positionrisk   (getattr self "fapiPrivate_get_positionrisk")))
  (defn fetch_position  [self symbol]
    (try
      (do
        (setv market_id
              (self.market_id symbol))
        (setv positions
              (self.fapiPrivate_get_positionrisk))
        (for  [pos positions]
          (when
            (=
              (get pos "symbol")
              market_id)
            (raise
              (Py2HyReturnException
                (float
                  (get pos "positionAmt"))))))
        (raise
          (Exception "symbol not found")))
      (except
        [e Py2HyReturnException]
        e.retvalue)))
  (defn websocket_key    [self &optional   [method "POST"]]
    (try
      (if self.FUTURE
          (do
            (raise
              (Py2HyReturnException
                (self.request "listenKey" "fapiPrivate" method))))
          (do
            (raise
              (Py2HyReturnException
                (self.request "userDataStream" "v3" method)))))
      (except
        [e Py2HyReturnException]
        e.retvalue))))
(defclass BinanceFutureApi [BinanceApi] (setv FUTURE True))
