//
// this is an example of "host code" that can either run in cosim or on the PS
// we can use the same C host code and
// the API we provide abstracts away the
// communication plumbing differences.

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "bp_zynq_pl.h"

#define PACKET_SIZE 2048
static char tx_packet[PACKET_SIZE] __attribute__((aligned(8)));
static char rx_packet[PACKET_SIZE] __attribute__((aligned(8)));

int create_random_packet(void *buf, int *size);
int send_packet(void *buf, int size);
int read_packet(void *buf, int *size);

bp_zynq_pl *zpl;

#ifdef VERILATOR
int main(int argc, char **argv) {
#else
extern "C" void cosim_main(char *argstr) {
  int argc = get_argc(argstr);
  char *argv[argc];
  get_argv(argstr, argc, argv);
#endif
  zpl = new bp_zynq_pl(argc, argv);

  // the read memory map is essentially
  //
  // 0,4,8,C: registers
  // 10, 14: output fifo heads
  // 18, 1C: output fifo counts
  // 20,24,28,2C: input fifo counts
  // 30-44: unused input fifo counts
  // 48: last address of write
  // 4C: tx_ready_lo
  // 50: tx_status_lo
  // 54: sender_speed_lo
  // 58: rx_ready_lo
  // 5C: buffer_read_data_lo lower 32bit
  // 60: rx_packet_size_lo
  // 64: rx_status_lo
  // 68: receiver_speed_lo
  // 6C: |reset_clk250_late_lo

  // the write memory map is essentially
  //
  // 0,4,8,C: registers
  // 10,14,18,1C: input fifo
  // 20: send_li
  // 24: receiver clear_buffer_li
  // 28: tx_packet_size_li
  // 2C: buffer_write_addr_li
  // 30: buffer_write_data_li
  // 34: buffer_reda_addr_li

  int val1 = 0xDEADBEEF;
  int val2 = 0xCAFEBABE;
  int val3 = 0x0000CADE;
  int val4 = 0xC0DE0000;
  int mask1 = 0xf;
  int mask2 = 0xf;

  // write to two registers, checking our address snoop to see
  // actual address that was received over the AXI bus
  zpl->axil_write(0x0 + GP0_ADDR_BASE, val1, mask1);
  assert(zpl->axil_read(0x48 + GP0_ADDR_BASE) == 0x0);
  zpl->axil_write(0x4 + GP0_ADDR_BASE, val2, mask2);
  assert(zpl->axil_read(0x48 + GP0_ADDR_BASE) == 0x4);
  // 8,12

  // check output fifo counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == 0));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == 0));

  // check input fifo counters
  bsg_pr_dbg_ps("%x\n", zpl->axil_read(0x20 + GP0_ADDR_BASE));
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == 4));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == 4));
  assert((zpl->axil_read(0x28 + GP0_ADDR_BASE) == 4));
  assert((zpl->axil_read(0x2C + GP0_ADDR_BASE) == 4));

  // write to fifos
  zpl->axil_write(0x10 + GP0_ADDR_BASE, val3, mask1);

  // checker counters
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == (3)));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == (4)));

  // write to fifo
  zpl->axil_write(0x10 + GP0_ADDR_BASE, val1, mask1);
  // checker counters
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == (2)));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == (4)));

  zpl->axil_write(0x14 + GP0_ADDR_BASE, val4, mask2);
  zpl->axil_write(0x14 + GP0_ADDR_BASE, val2, mask2);

  // checker counters
  assert((zpl->axil_read(0x20 + GP0_ADDR_BASE) == (4)));
  assert((zpl->axil_read(0x24 + GP0_ADDR_BASE) == (4)));

  // check register writes
  assert((zpl->axil_read(0x0 + GP0_ADDR_BASE) == (val1)));
  assert((zpl->axil_read(0x4 + GP0_ADDR_BASE) == (val2)));

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (2)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (0)));

  // check that the output fifo has the sum of the input fifos
  assert((zpl->axil_read(0x10 + GP0_ADDR_BASE) == (val3 + val4)));
  assert((zpl->axil_read(0x10 + GP0_ADDR_BASE) == (val1 + val2)));

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (0)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (0)));

  // try a different set of input and output fifos
  zpl->axil_write(0x18 + GP0_ADDR_BASE, val1, mask1);
  zpl->axil_write(0x1C + GP0_ADDR_BASE, val2, mask2);

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (0)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (1)));

  // read value out of fifo
  assert((zpl->axil_read(0x14 + GP0_ADDR_BASE) == (val1 + val2)));

  // checker output counters
  assert((zpl->axil_read(0x18 + GP0_ADDR_BASE) == (0)));
  assert((zpl->axil_read(0x1C + GP0_ADDR_BASE) == (0)));

  // Checks for Ethernet
  // the read memory map:
  //
  // 4C: tx_ready_lo
  // 50: tx_status_lo
  // 54: sender_speed_lo
  // 58: rx_ready_lo
  // 5C: buffer_read_data_lo lower 32bit
  // 60: rx_packet_size_lo
  // 64: rx_status_lo
  // 68: receiver_speed_lo
  // 6C: |reset_clk250_late_lo

  // the write memory map is essentially
  //
  // 20: send_li
  // 24: receiver clear_buffer_li
  // 28: tx_packet_size_li
  // 2C: buffer_write_addr_li
  // 30: buffer_write_data_li
  // 34: buffer_reda_addr_li

  // 84 - 96
  int total_packets = 1024, tx_size, rx_size;
  int seed = 1634580569;
  if(seed == 0) {
      seed = time(NULL);
      printf("[debug] seed: %d\n", seed);
  }
  // init
  srand(seed);
  while(zpl->axil_read(0x6C + GP0_ADDR_BASE) == 1) // wait for all resets are de-asserted
    ;
  zpl->axil_write(0x24 + GP0_ADDR_BASE, 0, 0xf); // set clear_buffer_li to 0
 
  for(int i = 0;i < total_packets;i++) {
    printf("[debug] it: %d\n", i);
    create_random_packet(tx_packet, &tx_size);
//    printf("[debug] tx_size: %d\n", tx_size);
    send_packet(tx_packet, tx_size);
/*    if(i == 87) {
      for(int i = 0;i < 500;i++)
        zpl->axil_read(0x58 + GP0_ADDR_BASE);
      break;
    }*/
    read_packet(rx_packet, &rx_size);
//    printf("[debug] rx_size: %d\n", rx_size);
    if(tx_size < 60)
      assert(rx_size == 60);
    else
      assert(tx_size == rx_size);
    for(int i = 0;i < tx_size;i++) {
      if((i % 8) < 4)
        //printf("%d %d\n", tx_packet[i], rx_packet[i]);
        assert(tx_packet[i] == rx_packet[i]);
    }
  }

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}

// Note: buf should be at least (size + 7) / 8 * 8 bytes large
int create_random_packet(void *buf, int *size)
{
  int sz;
  if(((uint64_t)buf & 7UL) != 0) {
    // buf address should be 64-bit aligned
    return 1;
  }
  sz = (rand() % 127) + 2; // 2 ~ 128 bytes (cannot send 1-byte packet)
  for(int i = 0;i < (sz + 7) / 8;i++) {
    *(unsigned long *)(buf + i * 8) = (unsigned long)rand() * (unsigned long)rand();
  }
  *size = sz;
  return 0;
}

// Note: buf should be at least (size + 3) / 4 * 4 bytes large
int send_packet(void *buf, int size)
{
  if(((uint64_t)buf & 7UL) != 0) {
    // buf address should be 64-bit aligned
    return 1;
  }
  while(zpl->axil_read(0x4C + GP0_ADDR_BASE) == 0) // wait for tx is ready
    ;
  zpl->axil_write(0x28 + GP0_ADDR_BASE, size, 0xf); // specify tx packet size
  for(int i = 0;i < (size + 7) / 8;i++) {
    zpl->axil_write(0x2C + GP0_ADDR_BASE, i, 0xf); // specify write address (64 bit per unit)
    // currently only lower 32-bit data will be transmitted due to the AXI bus width:
    zpl->axil_write(0x30 + GP0_ADDR_BASE, *(unsigned *)(buf + i * 8), 0xf); // specify write data
  }
  zpl->axil_write(0x20 + GP0_ADDR_BASE, 1, 0xf); // send
  zpl->axil_write(0x20 + GP0_ADDR_BASE, 0, 0xf); // send
  return 0;
}

// Note: buf should be at least (size + 3) / 4 * 4 bytes large
int read_packet(void *buf, int *size)
{
  unsigned read_data;
  if(((uint64_t)buf & 7UL) != 0) {
    // buf address should be 64-bit aligned
    return 1;
  }
  while(zpl->axil_read(0x58 + GP0_ADDR_BASE) == 0) // wait for rx is ready
    ;
  // read packet
  *size = zpl->axil_read(0x60 + GP0_ADDR_BASE); // read rx packet size

  for(int i = 0;i < (*size + 7) / 8;i++) {
    zpl->axil_write(0x34 + GP0_ADDR_BASE, i, 0xf); // specify read address
    *(unsigned *)(buf + i * 8) = zpl->axil_read(0x5C + GP0_ADDR_BASE);
  }
  zpl->axil_write(0x24 + GP0_ADDR_BASE, 1, 0xf); // set clear_buffer_li to 1
  zpl->axil_write(0x24 + GP0_ADDR_BASE, 0, 0xf); // set clear_buffer_li to 0
  return 0;
}
