# -------------------------------------------------
# Makefile for writer.c                  21.08.2023
# -------------------------------------------------
CROSS_COMPILE= #aarch64-none-linux-gnu- 

# default
CC=gcc -I/usr/local/include -L/usr/local/lib 

# compilation for ARM
ifdef CROSS_COMPILE
CC=aarch64-none-linux-gnu-gcc
endif

CFLAGS= -O0 -g -Wall

TARGET= writer

LIBS= 
HFILES= 
CFILES= writer.c 

SRCS= ${HFILES} ${CFILES}
OBJS= ${CFILES:.c=.o}

all:	${TARGET}

clean:
	-rm -f *.o
	-rm -f ${TARGET}

${TARGET}:	${OBJS}
	$(CC) $(CFLAGS) -o $@ $(OBJS) $(LIBS)

depend:

.c.o:
	$(CC) $(CFLAGS) -c $<

