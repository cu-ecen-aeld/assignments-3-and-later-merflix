.PHONY: clean

CROSS_COMPILE := aarch64-none-linux-gnu-gcc
# CXX :=gcc
MY_FLAGS := -c -g -Wall
objs := writer.o

all: writer

writer: $(objs)
	$(CROSS_COMPILE) -o $@ $^

%.o: %.c
	$(CROSS_COMPILE) $(MY_FLAGS) $<

clean:
	rm -f $(objs)

