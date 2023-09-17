CROSS_COMPILE = aarch64-none-linux-gnu-gcc
NATIVE = gcc
TARGET = writer
SRC = writer.c

all: 
	$(CROSS_COMPILE) $(SRC) -o $(OBJECTS) $(TARGET)

x86-64: 
	$(NATIVE) $(SRC) -o $(OBJECTS) $(TARGET)

arm:
	$(CROSS_COMPILE) $(SRC) -o $(OBJECTS) $(TARGET)

clean:
	rm -rf $(OBJECTS) $(TARGET)
