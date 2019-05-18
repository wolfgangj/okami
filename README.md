![Wok](logo.png)

> The Joy of Systems Programming

# Welcome to Wolfgang's Open Kompiler

This might one day become a compiler for a statically typed concatenative language.

Preview:

```
def half   (int :: int) [2 /]
def square (int :: int) [this *]

rec point (xpos:int ypos:int)
rec line (start:point end:point)

the bottom: line
the player: point
the [10] enemies: point

def point0 (@point :: @point)
  [0 that.xpos !  0 that.ypos !]

def x=? (@point @point :: @point @point bool)
  [them .xpos@ x .xpos@ =]
def y=? (@point @point :: @point @point bool)
  [them .ypos@ x .ypos@ =]

def point= (@point @point :: bool)
  [x=? if:[dropem yes stop]
   y=? if:[dropem yes stop]
   dropem no]
```
