CFLAGS?=-g -O0
override CFLAGS+=-MMD -MP
LDFLAGS?=
override LDFLAGS+=-lpthread
SRC=main.c fifo.c

.PHONY:all
all:sim

%.o:%.c
	$(CC) $(CFLAGS) -c $<

sim:$(patsubst %.c,%.o,$(SRC))
	$(CC) -o $@ $^ $(LDFLAGS)

-include $(TEST_SRC:.c=.d)

.PHONY:clean
clean:
	rm -rf *.o *.d sim