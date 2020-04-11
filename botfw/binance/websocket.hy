(import [hy.contrib.hy-repr [hy-repr]])
(import [botfw.base.websocket [WebsocketBase]])
(defclass BinanceWebsocket  [WebsocketBase]
  (setv ENDPOINT "wss://stream.binance.com:9443/ws")
  (defn command  [self op &optional     [args None]     [cb None]]
    (setv msg  {"method" op  "id" self._request_id})
    (when args   (assoc msg "params" args))
    (assoc self._request_table self._request_id            (, msg cb))
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
(defclass BinanceFutureWebsocket  [BinanceWebsocket]  (setv ENDPOINT "wss://fstream.binance.com/ws"))
(defclass BinanceWebsocketPrivate  [WebsocketBase]
  (setv ENDPOINT "wss://stream.binance.com:9443/ws")
  (defn __init__  [self api]
    (setv self.__api api)
    (setv self.__cb       [])
    ((.       (super)       __init__)      None))
  (defn keep_alive  [self]    (self.__api.websocket_key "PUT"))
  (defn add_callback [self cb]    (self.__cb.append cb))
  (defn _on_init [self]
    (setv res          (self.__api.websocket_key))
    (setv key          (get res "listenKey"))
    (setv self.url (+ self.ENDPOINT "/" key )           ))
  (defn _on_open     [self]
    ((.  (super)   _on_open))
    (self._set_auth_result True))
  (defn _handle_message   [self msg]     (self._run_callbacks self.__cb msg)))
(defclass BinanceFutureWebsocketPrivate [BinanceWebsocketPrivate] (setv ENDPOINT "wss://fstream.binance.com/ws"))
