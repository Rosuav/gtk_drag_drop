drag: drag.c
	gcc -g drag.c `pkg-config --cflags --libs gtk+-2.0` -o drag
