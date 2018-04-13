okami: okami.s
	arm-linux-gnueabihf-as okami.s -o okami.o
	arm-linux-gnueabihf-ld okami.o -o okami

tiny: okami
	strip okami

test: okami
	rlwrap ./okami lib/core.ok tests/core.ok

repl: okami
	rlwrap ./okami lib/core.ok

server: okami
	rlwrap ./okami lib/core.ok lib/syscalls/errno.ok lib/syscalls/socket.ok app/server.ok
