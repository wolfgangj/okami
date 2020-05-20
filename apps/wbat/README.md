# wbat - Battery State Warning Tool

This program warns you when your OpenBSD laptop is running low on battery.

Usage examples:

```
wbat i3-nagbar -t warning -m 'battery low' &

wbat xmessage -center battery low &
```

You can pass an arbitrary command that will be executed when your battery level falls below 15% and 5%.
It's recommended to run `wbat` as a background process.
