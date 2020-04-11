;;(require [hy015removed.core [*]])
(import [hy.contrib.hy-repr [hy-repr]])
(import time)
(import time)
(defclass Py2HyReturnException [Exception] (defn __init__ [self retvalue] (setv self.retvalue retvalue)))
(import logging)
(import json)
(import traceback)
(import threading)
(import websocket)
(import [botfw.etc.util [run_forever_nonblocking StopRunForever]])
(defclass WebsocketBase  []
  (setv ENDPOINT None)
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
    (run_forever_nonblocking self.__worker self.log 3))
  (defn stop    [self]
    (setv self.running False)
    (self.ws.close))
  (defn add_after_open_callback    [self cb]
    (with
      [self.__lock]
      (self.__after_open_cb.append cb)
      (when self.is_open        (cb))))
  (defn add_after_auth_callback    [self cb]
    (with   [self.__lock]
      (self.__after_auth_cb.append cb)
      (when self.is_auth        (cb))))
  (defn wait_open    [self &optional     [timeout 10]]
    (try
      (do
        (setv ts              (time.time))
        (while True
          (if (not self.is_open)
              (when (> (- (time.time)  ts) timeout)         (raise   (Exception "Waiting open timeout")))
              (raise  (Py2HyReturnException None)))
          (time.sleep 0.1)))
      (except        [e Py2HyReturnException]        e.retvalue)))
  (defn wait_auth    [self &optional     [timeout 10]]
    (try
      (do
        (setv ts  (time.time))
        (while True
          (cond
            [(is self.is_auth None)
             (when (>  (-  (time.time)  ts)  timeout)   (raise  (Exception "Waiting auth timeout")))]
            [self.is_auth             (raise               (Py2HyReturnException None))]
            [True             (raise               (Exception "Auth failed"))])
          (time.sleep 0.1)))
      (except        [e Py2HyReturnException]        e.retvalue)))
  (defn send    [self msg]
    (self.ws.send      (json.dumps msg))
    (self.log.debug    (+ "send: " (hy-repr  msg))    ))
  (defn subscribe    [self ch cb &optional     [auth False]]
    (assoc self._ch_cb ch cb)
    (if auth
        (self.add_after_auth_callback  (fn [] (self._subscribe ch)))
        (self.add_after_open_callback  (fn [] (self._subscribe ch)))))
  (defn _set_auth_result    [self success]
    (if success
        (do
          (self.log.info "authentication succeeded")
          (with
            [self.__lock]
            (setv self.is_auth True)
            (self._run_callbacks self.__after_auth_cb)))
        (do
          (self.log.error "authentication failed")
          (setv self.is_auth False)
          (self.ws.close))))
  (defn _run_callbacks    [self cbs &rest args]
    (try
      (for [cb cbs]
        (try
          (cb   (unpack_iterable args))
          (except  [e Py2HyReturnException]  (raise e))
          (except  [Exception]   (self.log.error  (traceback.format_exc)))))
      (except  [e Py2HyReturnException]  e.retvalue)))
  (defn _subscribe    [self ch]    (assert False))
  (defn _authenticate    [self]    (assert False))
  (defn _handle_message    [self msg]    (assert False))
  (defn _on_init    [self] )
  (defn _on_open    [self]
    (self.log.info "open websocket")
    (setv self._next_id 1)
    (setv self._request_table          {})
    (with [self.__lock]
      (setv self.is_open True)
      (self._run_callbacks self.__after_open_cb)))
  (defn _on_close    [self]
    (setv self.is_open False)
    (setv self.is_auth None)
    (self.log.info "close websocket"))
  (defn _on_message    [self msg]
    (try
      (try
        (do
          (setv msg (json.loads msg))
          (self._handle_message msg))
        (except  [e Py2HyReturnException]  (raise e))
        (except  [Exception]   (self.log.error  (traceback.format_exc))))
      (except   [e Py2HyReturnException]   e.retvalue)))
  (defn _on_error   [self err]    (self.log.error (+ "recv: " err)      ))
  (defn __worker    [self]
    (self._on_init)
    (self.log.debug (+ "create websocket: url=" self.url) )
    (setv self.ws
          (websocket.WebSocketApp self.url :on_open self._on_open :on_close self._on_close :on_message self._on_message :on_error self._on_error))
    (self.ws.run_forever :ping_interval 60)
    (when      (not self.running)      (raise StopRunForever))))
