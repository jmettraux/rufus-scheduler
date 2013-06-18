
# rufus-scheduler

[![Build Status](https://secure.travis-ci.org/jmettraux/rufus-scheduler.png)](http://travis-ci.org/jmettraux/rufus-scheduler)


## note about the 3.0 line

It's a complete rewrite of rufus-scheduler.

There is no EventMachine-based scheduler anymore.


## Notables changes:

* As said, no more EventMachine-based scheduler
* ```scheduler.every('100') {``` will schedule every 100 seconds (previously, it would have been 0.1s). This aligns rufus-scheduler on Ruby's ```sleep(100)```

## job options

### :blocking => true
### :overlap => false


## license

MIT, see LICENSE.txt

