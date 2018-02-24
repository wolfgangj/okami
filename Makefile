okami: okami.s
	arm-linux-gnueabihf-as okami.s -o okami.o
	arm-linux-gnueabihf-ld okami.o -o okami

tiny: okami
	strip okami
