# btcbothy

This is bitcoin trade tools mainly based on  https://github.com/penta2019/btc_bot_framework .
This base code realizes bitcoin trade framework using websocket interface on python with ccxt. 
But they dont use asyncio.
This project try to (auto?) convert such exsiting tools to hy-lang with asyncio like https://github.com/ccxt/ccxt/issues/6441

# Demo

```sh
git clone https://github.com/niitsuma/btcbothy
pip3 install ccxt sortedcontainers --user
cd btcbothy
hy3 trade.hy
```

# Todo 
## bugs in py2hy ( https://github.com/niitsuma/py2hy )

- (setv x a y b) not good. But (setv x a) works.
- format-string fail translate
- (import ..foo.bar) :can not deal relative path in hy
- defn pass -> (do) :do with noting 
- dict -> assoc : setv and get is better 
- raise Exception not good translate.
- elif -> too redundunt translate
