include ../Makefile.design

#############################
# Accelerator Software Settings
#############################
HOST_PROGRAM ?= $(abspath ../ps.cpp)
CFLAGS += -DZYNQ_PL_DEBUG
CFLAGS += -DZYNQ_PS_DEBUG
CFLAGS += -DGP0_ENABLE -DGP0_ADDR_BASE=0x43C00000 -DGP0_ADDR_WIDTH=4 -DGP0_DATA_WIDTH=32 -DGP0_HIER_BASE=TOP.top.axil0

# Enable backpressure, emulating context switches
#CFLAGS += -DSIM_BACKPRESSURE_ENABLE
#CFLAGS += -DSIM_BACKPRESSURE_SEED=1234
#CFLAGS += -DSIM_BACKPRESSURE_CHANCE=20
#CFLAGS += -DSIM_BACKPRESSURE_LENGTH=1000

#############################
# Modify base flist
#############################
BASE_FLIST ?= $(abspath ../flist.vcs)
FLIST      ?= $(abspath flist.vcs)
$(FLIST): $(BASE_FLIST)
	cat $< | envsubst > $@
	echo "$(COSIM_SRC_DIR)/bsg_nonsynth_dpi_to_axil.v" >> $@
	echo "$(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dpi_clock_gen.cpp" >> $@

include $(TOP)/cosim/mk/Makefile.verilator

