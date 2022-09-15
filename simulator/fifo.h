#ifndef _FIFO_H
#define _FIFO_H
#endif

#include <stdint.h>

typedef void* fifo_handle_t;

fifo_handle_t fifo_new(int size);

void fifo_free(fifo_handle_t fifo);

int fifo_get_length(fifo_handle_t fifo);

int fifo_read(fifo_handle_t fifo, uint8_t* dst, int dst_len);

int fifo_write(fifo_handle_t fifo, uint8_t* src, int src_len);
