# wbat - Battery State Warning Tool

This program warns you when your OpenBSD laptop is running low on battery.

Usage examples:

```
wbat $(which i3-nagbar) -t warning -m 'battery low' &

wbat $(which xmessage) -center battery low &
```

You can pass an arbitrary command that will be executed when your battery level falls below 15% and 5%.
The first argument needs to be the full path of the program that should be started, no lookup in `$PATH` is done!
It's recommended to run `wbat` as a background process.
