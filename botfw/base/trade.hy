;;(require [hy015removed.core [*]])
(import logging)
(defclass Py2HyReturnException [Exception] (defn __init__ [self retvalue] (setv self.retvalue retvalue)))
(import time)
(import websocket)
(import [botfw.etc.util [setup_logger]])
(defn test_trade  [t &optional   [trace False]   [log_level logging.INFO]]
  (try
    (do
      (websocket.enableTrace trace)
      (setup_logger log_level)
      (try
        (do
          (t.add_callback      (fn [ts p s]  (print ts p s)       ))
          (while True            (time.sleep 1)))
        (except   [e Py2HyReturnException]          (raise e))
        (except  [KeyboardInterrupt]  (do))))
    (except      [e Py2HyReturnException]      e.retvalue)))
(defclass TradeBase   []
  (defn __init__    [self]
    (setv self.log (logging.getLogger self.__class__.__name__))
    (setv self.ltp None)
    (setv self.cb  []))
  (defn wait_initialized    [self &optional     [timeout 60]]
    (try
      (do
        (setv ts              (time.time))
        (setv count 0)
        (while True
          (if  (not self.ltp)
            (do
              (if (>  (-  (time.time) ts)  timeout)
                  (self.log.error (+"timeout(" timeout "s)") )
                (do
                  (+= count 1)
                  (when   (=    (% count 5)  0)
                    (self.log.info "waiting to be initialized")))))
            (do              (raise          (Py2HyReturnException None))))
          (time.sleep 1)))
      (except        [e Py2HyReturnException]        e.retvalue)))
  (defn add_callback    [self cb]    (self.cb.append cb))
  (defn remove_callback    [self cb]    (self.cb.remove cb))
  (defn _trigger_callback    [self ts price size]
    (for      [cb self.cb]      (cb ts price size))))
