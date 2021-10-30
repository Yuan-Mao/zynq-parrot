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
#define AXIS_WIDTH 4
char tx_packet[PACKET_SIZE] __attribute__((aligned(AXIS_WIDTH)));
char rx_packet[PACKET_SIZE] __attribute__((aligned(AXIS_WIDTH)));


int create_random_packet(void *buf, int *size);
void create_dummy_packet(void *buf, int *size);
int send_packet(void *buf, int size);
int read_packet(void *buf, int *size);

void send_trigger();
void set_continuous_send_trigger();
void unset_continuous_send_trigger();

void clear_trigger();
void set_continuous_clear_trigger();
void unset_continuous_clear_trigger();

void testbench_init();
void testbench1();
void testbench2();

bp_zynq_pl *zpl;

void testbench_init()
{
  int seed = 0;
  if(seed == 0) {
      seed = time(NULL);
      printf("[debug] seed: %d\n", seed);
  }
  // init
  srand(seed);
  // dummy reads: wait for all resets are de-asserted
  for(int i = 0;i < 10;i++)
    zpl->axil_read(0x74 + GP0_ADDR_BASE);
}
void testbench1()
{
  int total_packets = 1024, tx_size, rx_size;
 
  for(int i = 0;i < total_packets;i++) {
    create_random_packet(tx_packet, &tx_size);
    send_packet(tx_packet, tx_size);
    read_packet(rx_packet, &rx_size);
    // receiver will add padding to 60 bytes
    if(tx_size < 60)
      assert(rx_size == 60);
    else
      assert(tx_size == rx_size);
    for(int i = 0;i < tx_size;i++) {
      assert(tx_packet[i] == rx_packet[i]);
    }
  }
}

void testbench2()
{
  int cnt = 1024, tx_size, rx_size;
//  create_random_packet(tx_packet, &tx_size);
  create_dummy_packet(tx_packet, &tx_size);
  send_packet(tx_packet, tx_size);
  set_continuous_send_trigger();
//  set_continuous_clear_trigger();
  // keep ticking the clock
  for(int i = 0;i < cnt;i++) {
    zpl->axil_read(0x60 + GP0_ADDR_BASE);
  }
}

void create_dummy_packet(void *buf, int *size)
{
    memcpy(buf, "\xEB\xCD\xF3\xE5\xC3\x90", 6);
    memcpy(buf + 6, "\xFF\xFF\xFF\xFF\xFF\xFF", 6);
    memcpy(buf + 8, "\x08\x00", 2);
    *size = 14;
}

void send_trigger()
{
  static int send_trigger_state = 0;
  send_trigger_state = ~send_trigger_state;
  zpl->axil_write(0x20 + GP0_ADDR_BASE, send_trigger_state, 0xf);
}

void set_continuous_send_trigger()
{
  zpl->axil_write(0x38 + GP0_ADDR_BASE, 1, 0xf);
}

void unset_continuous_send_trigger()
{
  zpl->axil_write(0x38 + GP0_ADDR_BASE, 0, 0xf);
}

void clear_trigger()
{
  static int clear_trigger_state = 0;
  clear_trigger_state = ~clear_trigger_state;
  zpl->axil_write(0x24 + GP0_ADDR_BASE, clear_trigger_state, 0xf);
}

void set_continuous_clear_trigger()
{
  zpl->axil_write(0x3C + GP0_ADDR_BASE, 1, 0xf);
}

void unset_continuous_clear_trigger()
{
  zpl->axil_write(0x3C + GP0_ADDR_BASE, 0, 0xf);
}


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
  // 30-4C: unused input fifo counts
  // 50: last address of write
  // 54: tx_ready_lo
  // 58: tx_status_lo
  // 5C: sender_speed_lo
  // 60: rx_ready_lo
  // 64: buffer_read_data_lo lower 32bit
  // 68: rx_packet_size_lo
  // 6C: rx_status_lo
  // 70: receiver_speed_lo
  // 74: |reset_clk250_late_lo

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
  // 38: continuous_send_li
  // 3C: continuous_clear_li

  int val1 = 0xDEADBEEF;
  int val2 = 0xCAFEBABE;
  int val3 = 0x0000CADE;
  int val4 = 0xC0DE0000;
  int mask1 = 0xf;
  int mask2 = 0xf;

  // write to two registers, checking our address snoop to see
  // actual address that was received over the AXI bus
  zpl->axil_write(0x0 + GP0_ADDR_BASE, val1, mask1);
  assert(zpl->axil_read(0x50 + GP0_ADDR_BASE) == 0x0);
  zpl->axil_write(0x4 + GP0_ADDR_BASE, val2, mask2);
  assert(zpl->axil_read(0x50 + GP0_ADDR_BASE) == 0x4);
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

  testbench_init();
  testbench2();

  zpl->done();

  delete zpl;
  exit(EXIT_SUCCESS);
}

// Note: buf should be at least ceil(size, AXIS_WIDTH) bytes large
int create_random_packet(void *buf, int *size)
{
  int sz;
  if(((uint64_t)buf & (AXIS_WIDTH - 1)) != 0) {
    // buf address should be 64-bit aligned
    return 1;
  }
  sz = (rand() % 127) + 2; // 2 ~ 128 bytes (cannot send 1-byte packet)
  for(int i = 0;i < (sz + AXIS_WIDTH - 1) / AXIS_WIDTH;i++) {
    *(unsigned long *)(buf + i * AXIS_WIDTH) = (unsigned long)rand() * (unsigned long)rand();
  }
  *size = sz;
  return 0;
}

// Note: buf should be at least ceil(size, AXIS_WIDTH) bytes large
int send_packet(void *buf, int size)
{
  if(((uint64_t)buf & (AXIS_WIDTH - 1)) != 0) {
    // buf address should be 64-bit aligned
    return 1;
  }
  while(zpl->axil_read(0x54 + GP0_ADDR_BASE) == 0) // wait for tx is ready
    ;
  zpl->axil_write(0x28 + GP0_ADDR_BASE, size, 0xf); // specify tx packet size
  for(int i = 0;i < (size + AXIS_WIDTH - 1) / AXIS_WIDTH;i++) {
    zpl->axil_write(0x2C + GP0_ADDR_BASE, i, 0xf); // specify write address (64 bit per unit)
    // currently only lower 32-bit data will be transmitted due to the AXI bus width:
    zpl->axil_write(0x30 + GP0_ADDR_BASE, *(unsigned *)(buf + i * AXIS_WIDTH), 0xf); // specify write data
  }
  send_trigger();
  return 0;
}

// Note: buf should be at least (size + 3) / 4 * 4 bytes large
int read_packet(void *buf, int *size)
{
  unsigned read_data;
  if(((uint64_t)buf & (AXIS_WIDTH - 1)) != 0) {
    // buf address should be 64-bit aligned
    return 1;
  }
  while(zpl->axil_read(0x60 + GP0_ADDR_BASE) == 0) // wait for rx is ready
    ;
  // read packet
  *size = zpl->axil_read(0x68 + GP0_ADDR_BASE); // read rx packet size

  for(int i = 0;i < (*size + AXIS_WIDTH - 1) / AXIS_WIDTH;i++) {
    zpl->axil_write(0x34 + GP0_ADDR_BASE, i, 0xf); // specify read address
    *(unsigned *)(buf + i * AXIS_WIDTH) = zpl->axil_read(0x64 + GP0_ADDR_BASE);
  }
  clear_trigger();
  return 0;
}
