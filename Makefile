LIBOPTS = -shared
CFLAGS = -fPIC -std=gnu99 -O3 -Wall -Werror -funroll-loops -ffast-math
CC = gcc

waffle/libwaffle.so : waffle/speedups.c
	$(CC) $< $(LIBOPTS) $(CFLAGS) -o $@

clean :
	rm waffle/libwaffle.so