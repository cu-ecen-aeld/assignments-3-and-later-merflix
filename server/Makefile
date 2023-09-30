DEF_CC = gcc 
CC = $(DEF_CC)
CFLAGS = -Wall -Werror

ifdef CROSS_COMPILE
	CC = $(CROSS_COMPILE)$(DEF_CC)
endif

SRCS = aesdsocket.c
OBJS = $(SRCS:.c=.o)

TARGET = aesdsocket

all: $(TARGET)
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

clean:
	rm -f $(OBJS) $(TARGET)

