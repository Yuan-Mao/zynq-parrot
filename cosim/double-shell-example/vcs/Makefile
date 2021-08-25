include $(PWD)/bsg_cadenv/cadenv.mk

ZYNQ_PARROT_DIR=$(shell git rev-parse --show-toplevel)

VERILATOR ?= verilator

VPATH=../ .

TRACE=--trace-fst

# You need to configure these parameters for your particular accelerator!
#BASEJUMP_STL_DIR = ../../import/black-parrot/external/basejump_stl
BASEJUMP_STL_DIR = $(ZYNQ_PARROT_DIR)/cosim/import/black-parrot/external/basejump_stl

CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=5 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=top.axil0
CFLAGS += -DGP1_ENABLE -DGP1_ADDR_BASE=0x80000000 -DGP1_ADDR_WIDTH=5 -DGP1_DATA_WIDTH=32 -DGP1_HIER_BASE=top.axil1
CFLAGS += -I$(BASEJUMP_STL_DIR)/bsg_test
CFLAGS += -I$(ZYNQ_PARROT_DIR)/cosim/include/vcs
CFLAGS += -std=c++11
CFLAGS += -DTOP_NAME=top
CFLAGS += -DVCS

CSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp
CSOURCES += $(ZYNQ_PARROT_DIR)/cosim/double-shell-example/ps.cpp
CSOURCES += $(ZYNQ_PARROT_DIR)/cosim/include/vcs/bp_zynq_pl.cpp

VSOURCES += top.v
VSOURCES += $(ZYNQ_PARROT_DIR)/cosim/common/v/bsg_zynq_pl_shell.v
VSOURCES += $(ZYNQ_PARROT_DIR)/cosim/common/v/bsg_nonsynth_dpi_to_axil.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux_one_hot.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode_with_v.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_flow_counter.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_reset_en.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_counter_up_down.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_gpio.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v

VFLAGS += -top top
VFLAGS += -sverilog
VFLAGS += -assert svaext
VFLAGS += -full64
VFLAGS += -ntb_opts -tb_timescale=1ps/1ps
VFLAGS += -timescale=1ps/1ps
VFLAGS += -debug_pp
VFLAGS += +debug_all
VFLAGS += +vcs+vcdpluson
VFLAGS += +plusarg_save
VFLAGS += +vcs+vcdplusmemon
VFLAGS += +vcs+vcdcbk
VFLAGS += +memcbk
#VFLAGS += -Mcsrc=csrc
VFLAGS += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
VFLAGS += +incdir+$(BASEJUMP_STL_DIR)/bsg_dataflow
VFLAGS += +incdir+$(BASEJUMP_STL_DIR)/bsg_mem
VFLAGS += +incdir+$(BASEJUMP_STL_DIR)/bsg_test
VFLAGS += +incdir+../../common/v
VFLAGS += +define+VCS
VFLAGS += $(foreach cflag,$(CFLAGS),-CFLAGS $(cflag))

simv: $(VSOURCES) $(CSOURCES)
	$(VCS) $(VFLAGS) $^

dve:
	$(DVE) -full64 -vpd vcdplus.vpd

clean:
	-rm -rf simv csrc vcdplus.vpd vc_hdrs.h ucli.key simv.daidir/ DVEfiles
