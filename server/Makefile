CROSS_COMPILE = aarch64-none-linux-gnu-gcc
NATIVE = gcc
TARGET = aesdsocket
SRC = aesdsocket.c

all: 
	$(NATIVE) $(SRC) -o $(OBJECTS) $(TARGET)

arm:
	$(CROSS_COMPILE) $(SRC) -o $(OBJECTS) $(TARGET)

clean:
	rm -rf $(OBJECTS) $(TARGET)

