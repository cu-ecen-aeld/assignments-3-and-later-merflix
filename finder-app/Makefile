
SRC := writer.c 
TARGET = writer
OBJS := $(SRC:.c=.o)

CROSS_COMPILE:= aarch64-none-linux-gnu-gcc
CC:= $(CROSS_COMPILE)


all: $(TARGET)

$(TARGET) : $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) $(OBJS) -o $(TARGET) $(LDFLAGS)

clean:
	-rm -f *.o $(TARGET) *.elf *.map

