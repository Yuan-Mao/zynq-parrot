
`timescale 1 ns / 1 ps

`include "bp_common_defines.svh"
`include "bsg_cache.vh"

module top_zynq
  import bp_common_pkg::*;
   import bp_be_pkg::*;
   import bp_me_pkg::*;
   import bsg_noc_pkg::*;
   #(
     parameter bp_params_e bp_params_p = e_bp_default_cfg
     `declare_bp_proc_params(bp_params_p)

     , localparam uce_mem_data_width_lp = `BSG_MAX(icache_fill_width_p, dcache_fill_width_p)
     `declare_bp_bedrock_mem_if_widths(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce)

     // NOTE these parameters are usually overridden by the parent module (top.v)
     // but we set them to make expectations consistent

     // Parameters of Axi Slave Bus Interface S00_AXI
     , parameter integer C_S00_AXI_DATA_WIDTH   = 32

     // needs to be updated to fit all addresses used
     // by bsg_zynq_pl_shell read_locs_lp (update in top.v as well)
     , parameter integer C_S00_AXI_ADDR_WIDTH   = 9
     , parameter integer C_S01_AXI_DATA_WIDTH   = 32
     // the ARM AXI S01 interface drops the top two bits
     , parameter integer C_S01_AXI_ADDR_WIDTH   = 30
     , parameter integer C_M00_AXI_DATA_WIDTH   = 64
     , parameter integer C_M00_AXI_ADDR_WIDTH   = 32
     )
   (
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire                                   s00_axi_aclk
    ,input wire                                  s00_axi_aresetn
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr
    ,input wire [2 : 0]                          s00_axi_awprot
    ,input wire                                  s00_axi_awvalid
    ,output wire                                 s00_axi_awready
    ,input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata
    ,input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb
    ,input wire                                  s00_axi_wvalid
    ,output wire                                 s00_axi_wready
    ,output wire [1 : 0]                         s00_axi_bresp
    ,output wire                                 s00_axi_bvalid
    ,input wire                                  s00_axi_bready
    ,input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr
    ,input wire [2 : 0]                          s00_axi_arprot
    ,input wire                                  s00_axi_arvalid
    ,output wire                                 s00_axi_arready
    ,output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata
    ,output wire [1 : 0]                         s00_axi_rresp
    ,output wire                                 s00_axi_rvalid
    ,input wire                                  s00_axi_rready

    ,input wire                                  s01_axi_aclk
    ,input wire                                  s01_axi_aresetn
    ,input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_awaddr
    ,input wire [2 : 0]                          s01_axi_awprot
    ,input wire                                  s01_axi_awvalid
    ,output wire                                 s01_axi_awready
    ,input wire [C_S01_AXI_DATA_WIDTH-1 : 0]     s01_axi_wdata
    ,input wire [(C_S01_AXI_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb
    ,input wire                                  s01_axi_wvalid
    ,output wire                                 s01_axi_wready
    ,output wire [1 : 0]                         s01_axi_bresp
    ,output wire                                 s01_axi_bvalid
    ,input wire                                  s01_axi_bready
    ,input wire [C_S01_AXI_ADDR_WIDTH-1 : 0]     s01_axi_araddr
    ,input wire [2 : 0]                          s01_axi_arprot
    ,input wire                                  s01_axi_arvalid
    ,output wire                                 s01_axi_arready
    ,output wire [C_S01_AXI_DATA_WIDTH-1 : 0]    s01_axi_rdata
    ,output wire [1 : 0]                         s01_axi_rresp
    ,output wire                                 s01_axi_rvalid
    ,input wire                                  s01_axi_rready

    ,input wire                                 m00_axi_aclk
    ,input wire                                 m00_axi_aresetn
    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]     m00_axi_awaddr
    ,output wire                                m00_axi_awvalid
    ,input wire                                 m00_axi_awready
    ,output wire [5:0]                          m00_axi_awid
    ,output wire [1:0]                          m00_axi_awlock
    ,output wire [3:0]                          m00_axi_awcache
    ,output wire [2:0]                          m00_axi_awprot
    ,output wire [3:0]                          m00_axi_awlen
    ,output wire [2:0]                          m00_axi_awsize
    ,output wire [1:0]                          m00_axi_awburst
    ,output wire [3:0]                          m00_axi_awqos

    ,output wire [C_M00_AXI_DATA_WIDTH-1:0]     m00_axi_wdata
    ,output wire                                m00_axi_wvalid
    ,input wire                                 m00_axi_wready
    ,output wire [5:0]                          m00_axi_wid
    ,output wire                                m00_axi_wlast
    ,output wire [(C_M00_AXI_DATA_WIDTH/8)-1:0] m00_axi_wstrb

    ,input wire                                 m00_axi_bvalid
    ,output wire                                m00_axi_bready
    ,input wire [5:0]                           m00_axi_bid
    ,input wire [1:0]                           m00_axi_bresp

    ,output wire [C_M00_AXI_ADDR_WIDTH-1:0]     m00_axi_araddr
    ,output wire                                m00_axi_arvalid
    ,input wire                                 m00_axi_arready
    ,output wire [5:0]                          m00_axi_arid
    ,output wire [1:0]                          m00_axi_arlock
    ,output wire [3:0]                          m00_axi_arcache
    ,output wire [2:0]                          m00_axi_arprot
    ,output wire [3:0]                          m00_axi_arlen
    ,output wire [2:0]                          m00_axi_arsize
    ,output wire [1:0]                          m00_axi_arburst
    ,output wire [3:0]                          m00_axi_arqos

    ,input wire [C_M00_AXI_DATA_WIDTH-1:0]      m00_axi_rdata
    ,input wire                                 m00_axi_rvalid
    ,output wire                                m00_axi_rready
    ,input wire [5:0]                           m00_axi_rid
    ,input wire                                 m00_axi_rlast
    ,input wire [1:0]                           m00_axi_rresp
    );

/*
   localparam counter_num_p = 22;
   logic [counter_num_p*64-1:0] counter_data;

   bp_event_counters
    #(.bp_params_p(bp_params_p)
     ,.width_p(64)
     )
     event_counters
     (.clk_i(s01_axi_aclk)
     ,.reset_i(bp_reset_li)
     ,.freeze_i(`COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze)

     ,.mhartid_i('0)

     ,.fe_stall_i(`COREPATH.fe.is_stall)
     ,.fe_queue_full_i(~`COREPATH.fe.fe_queue_ready_i)

     ,.icache_access_i(`COREPATH.fe.v_if2_r)
     ,.icache_rollback_i(`COREPATH.fe.icache_miss)
     ,.icache_miss_i(~`COREPATH.fe.icache.ready_o)

     ,.taken_i((`COREPATH.fe.pc_gen.is_br 
                & `COREPATH.fe.pc_gen.pred_if2_r.pred) 
                | `COREPATH.fe.pc_gen.is_jal)
     ,.ovr_taken_i(`COREPATH.fe.pc_gen.ovr_taken)
     ,.ret_i(`COREPATH.fe.pc_gen.is_ret)
     ,.ovr_ret_i(`COREPATH.fe.pc_gen.ovr_ret)

     ,.fe_cmd_nonattaboy_i(`COREPATH.be.director.fe_cmd_nonattaboy_v)

     ,.mispredict_i(`COREPATH.be.director.fe_cmd_v_li
                    & (`COREPATH.be.director.fe_cmd_li.opcode == 1)
                    & (`COREPATH.be.director.fe_cmd_pc_redirect_operands.subopcode == 2))
     ,.mispredict_reason_i(`COREPATH.be.director.fe_cmd_pc_redirect_operands.misprediction_reason)

     ,.dcache_access_i(`COREPATH.be.calculator.pipe_mem.dcache_pkt_v 
                       & ~`COREPATH.be.calculator.pipe_mem.flush_i)
     ,.dcache_rollback_i(`COREPATH.be.scheduler.commit_pkt_cast_i.rollback)
     ,.dcache_miss_i(~`COREPATH.be.calculator.pipe_mem.dcache.ready_o)

     ,.control_haz_i(`COREPATH.be.detector.control_haz_v)

     ,.data_haz_i(`COREPATH.be.detector.data_haz_v)
     ,.load_dep_i((`COREPATH.be.detector.dep_status_r[0].emem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[0].fmem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[1].fmem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[0].emem_fwb_v
                   | `COREPATH.be.detector.dep_status_r[0].fmem_fwb_v
                   | `COREPATH.be.detector.dep_status_r[1].fmem_fwb_v
                   ) & `COREPATH.be.detector.data_haz_v
                  )
     ,.mul_dep_i((`COREPATH.be.detector.dep_status_r[0].mul_iwb_v
                  | `COREPATH.be.detector.dep_status_r[1].mul_iwb_v
                  | `COREPATH.be.detector.dep_status_r[2].mul_iwb_v
                  ) & `COREPATH.be.detector.data_haz_v
                 )

     ,.struct_haz_i(`COREPATH.be.detector.struct_haz_v)

     ,.fe_stall_o             (counter_data[1*64-1 : 0*64])
     ,.fe_queue_full_o        (counter_data[2*64-1 : 1*64])
     ,.icache_access_o        (counter_data[3*64-1 : 2*64])
     ,.icache_rollback_o      (counter_data[4*64-1 : 3*64])
     ,.icache_miss_o          (counter_data[5*64-1 : 4*64])
     ,.taken_o                (counter_data[6*64-1 : 5*64])
     ,.ovr_taken_o            (counter_data[7*64-1 : 6*64])
     ,.ret_o                  (counter_data[8*64-1 : 7*64])
     ,.ovr_ret_o              (counter_data[9*64-1 : 8*64])
     ,.fe_cmd_nonattaboy_o    (counter_data[10*64-1 : 9*64])
     ,.mispredict_o           (counter_data[11*64-1 : 10*64])
     ,.mispredict_taken_o     (counter_data[12*64-1 : 11*64])
     ,.mispredict_ntaken_o    (counter_data[13*64-1 : 12*64])
     ,.mispredict_nonbr_o     (counter_data[14*64-1 : 13*64])
     ,.control_haz_o          (counter_data[15*64-1 : 14*64])
     ,.data_haz_o             (counter_data[16*64-1 : 15*64])
     ,.load_dep_o             (counter_data[17*64-1 : 16*64])
     ,.mul_dep_o              (counter_data[18*64-1 : 17*64])
     ,.struct_haz_o           (counter_data[19*64-1 : 18*64])
     ,.dcache_access_o        (counter_data[20*64-1 : 19*64])
     ,.dcache_rollback_o      (counter_data[21*64-1 : 20*64])
     ,.dcache_miss_o          (counter_data[22*64-1 : 21*64])
     );
*/

   `define COREPATH blackparrot.unicore.unicore_lite.core_minimal

   localparam counter_num_p = 33;
   logic [counter_num_p*64-1:0] counter_data;

   bp_stall_counters
    #(.bp_params_p(bp_params_p)
     ,.width_p(64)
     )
     stall_counters
     (.clk_i(s01_axi_aclk)
     ,.reset_i(bp_reset_li)
     ,.freeze_i(`COREPATH.be.calculator.pipe_sys.csr.cfg_bus_cast_i.freeze)

     ,.fe_wait_stall_i(`COREPATH.fe.is_wait)
     ,.fe_queue_stall_i(~`COREPATH.fe.fe_queue_ready_i)

     ,.icache_rollback_i(`COREPATH.fe.icache_miss)
     ,.icache_miss_i(~`COREPATH.fe.icache.ready_o)
     ,.icache_fence_i(`COREPATH.fe.icache.fencei_req)

     ,.taken_override_i(`COREPATH.fe.pc_gen.ovr_taken)
     ,.ret_override_i(`COREPATH.fe.pc_gen.ovr_ret)

     ,.fe_cmd_i(`COREPATH.fe.fe_cmd_yumi_o & ~`COREPATH.fe.attaboy_v)
     ,.fe_cmd_fence_i(`COREPATH.be.director.suppress_iss_o)

     ,.mispredict_i(`COREPATH.be.director.npc_mismatch_v)

     ,.dcache_rollback_i(`COREPATH.be.scheduler.commit_pkt_cast_i.rollback)
     ,.dcache_miss_i(~`COREPATH.be.calculator.pipe_mem.dcache.ready_o)

     ,.control_haz_i(`COREPATH.be.detector.control_haz_v)
     ,.long_haz_i(`COREPATH.be.detector.long_haz_v)

     ,.data_haz_i(`COREPATH.be.detector.data_haz_v)
     ,.aux_dep_i((`COREPATH.be.detector.dep_status_r[0].aux_iwb_v
                | `COREPATH.be.detector.dep_status_r[0].aux_fwb_v
                ) & `COREPATH.be.detector.data_haz_v
               )
     ,.load_dep_i((`COREPATH.be.detector.dep_status_r[0].emem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[0].fmem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[1].fmem_iwb_v
                   | `COREPATH.be.detector.dep_status_r[0].emem_fwb_v
                   | `COREPATH.be.detector.dep_status_r[0].fmem_fwb_v
                   | `COREPATH.be.detector.dep_status_r[1].fmem_fwb_v
                   ) & `COREPATH.be.detector.data_haz_v
                  )
     ,.mul_dep_i((`COREPATH.be.detector.dep_status_r[0].mul_iwb_v
                  | `COREPATH.be.detector.dep_status_r[1].mul_iwb_v
                  | `COREPATH.be.detector.dep_status_r[2].mul_iwb_v
                  ) & `COREPATH.be.detector.data_haz_v
                 )
     ,.fma_dep_i((`COREPATH.be.detector.dep_status_r[0].fma_fwb_v
                | `COREPATH.be.detector.dep_status_r[1].fma_fwb_v
                | `COREPATH.be.detector.dep_status_r[2].fma_fwb_v
                | `COREPATH.be.detector.dep_status_r[3].fma_fwb_v
                ) & `COREPATH.be.detector.data_haz_v
               )
     ,.sb_iraw_dep_i((`COREPATH.be.detector.irs1_sb_raw_haz_v
                    | `COREPATH.be.detector.irs2_sb_raw_haz_v
                    ) & `COREPATH.be.detector.data_haz_v
                   )
     ,.sb_fraw_dep_i((`COREPATH.be.detector.frs1_sb_raw_haz_v
                    | `COREPATH.be.detector.frs2_sb_raw_haz_v
                    | `COREPATH.be.detector.frs3_sb_raw_haz_v
                    ) & `COREPATH.be.detector.data_haz_v
                   )
     ,.sb_iwaw_dep_i(`COREPATH.be.detector.ird_sb_waw_haz_v & `COREPATH.be.detector.data_haz_v)
     ,.sb_fwaw_dep_i(`COREPATH.be.detector.frd_sb_waw_haz_v & `COREPATH.be.detector.data_haz_v)

     ,.struct_haz_i(`COREPATH.be.detector.struct_haz_v)
     ,.long_busy_i(~`COREPATH.be.detector.long_ready_i & `COREPATH.be.detector.isd_status_cast_i.long_v)
     ,.long_i_busy_i((~`COREPATH.be.calculator.pipe_long.idiv_ready_and_lo
                     | (`COREPATH.be.calculator.pipe_long.v_li & `COREPATH.be.calculator.pipe_long.decode.late_iwb_v)
                    ) & `COREPATH.be.detector.dispatch_pkt_cast_i.decode.late_iwb_v
                   )
     ,.long_f_busy_i((~`COREPATH.be.calculator.pipe_long.fdiv_ready_lo
                     | (`COREPATH.be.calculator.pipe_long.v_li & `COREPATH.be.calculator.pipe_long.decode.late_fwb_v)
                    ) & `COREPATH.be.detector.dispatch_pkt_cast_i.decode.late_fwb_v
                   )

     ,.commit_pkt_i(`COREPATH.be.calculator.commit_pkt_cast_o)

     ,.fe_wait_stall_o        (counter_data[1*64-1 : 0*64])
     ,.fe_queue_stall_o       (counter_data[2*64-1 : 1*64])
     ,.icache_rollback_o      (counter_data[3*64-1 : 2*64])
     ,.icache_miss_o          (counter_data[4*64-1 : 3*64])
     ,.icache_fence_o         (counter_data[5*64-1 : 4*64])
     ,.taken_override_o       (counter_data[6*64-1 : 5*64])
     ,.ret_override_o         (counter_data[7*64-1 : 6*64])
     ,.fe_cmd_o               (counter_data[8*64-1 : 7*64])
     ,.fe_cmd_fence_o         (counter_data[9*64-1 : 8*64])
     ,.mispredict_o           (counter_data[10*64-1 : 9*64])
     ,.control_haz_o          (counter_data[11*64-1 : 10*64])
     ,.long_haz_o             (counter_data[12*64-1 : 11*64])
     ,.data_haz_o             (counter_data[13*64-1 : 12*64])
     ,.aux_dep_o              (counter_data[14*64-1 : 13*64])
     ,.load_dep_o             (counter_data[15*64-1 : 14*64])
     ,.mul_dep_o              (counter_data[16*64-1 : 15*64])
     ,.fma_dep_o              (counter_data[17*64-1 : 16*64])
     ,.sb_iraw_dep_o          (counter_data[18*64-1 : 17*64])
     ,.sb_fraw_dep_o          (counter_data[19*64-1 : 18*64])
     ,.sb_iwaw_dep_o          (counter_data[20*64-1 : 19*64])
     ,.sb_fwaw_dep_o          (counter_data[21*64-1 : 20*64])
     ,.struct_haz_o           (counter_data[22*64-1 : 21*64])
     ,.long_i_busy_o          (counter_data[23*64-1 : 22*64])
     ,.long_f_busy_o          (counter_data[24*64-1 : 23*64])
     ,.long_if_busy_o         (counter_data[25*64-1 : 24*64])
     ,.dcache_rollback_o      (counter_data[26*64-1 : 25*64])
     ,.dcache_miss_o          (counter_data[27*64-1 : 26*64])
     ,.unknown_o              (counter_data[28*64-1 : 27*64])
     ,.mem_instr_o            (counter_data[29*64-1 : 28*64])
     ,.aux_instr_o            (counter_data[30*64-1 : 29*64])
     ,.fma_instr_o            (counter_data[31*64-1 : 30*64])
     ,.ilong_instr_o          (counter_data[32*64-1 : 31*64])
     ,.flong_instr_o          (counter_data[33*64-1 : 32*64])
     );

   logic [2:0][C_S00_AXI_DATA_WIDTH-1:0]        csr_data_lo;
   logic [C_S00_AXI_DATA_WIDTH-1:0]             pl_to_ps_fifo_data_li, ps_to_pl_fifo_data_lo;
   logic                                        pl_to_ps_fifo_v_li, pl_to_ps_fifo_ready_lo;
   logic                                        ps_to_pl_fifo_v_lo, ps_to_pl_fifo_yumi_li;

   localparam debug_lp = 0;
   localparam memory_upper_limit_lp = 241*1024*1024;

   // use this as a way of figuring out how much memory a RISC-V program is using
   // each bit corresponds to a region of memory
   logic [127:0] mem_profiler_r;

   // Connect Shell to AXI Bus Interface S00_AXI
   bsg_zynq_pl_shell #
     (
      .num_regs_ps_to_pl_p (3)
      // standard memory map for all blackparrot instances should be
      //
      // 0: reset for bp (low true); note: it is only legal to assert reset if you are
      //    finished with all AXI transactions (fixme: potential improvement to detect this)
      // 4: = 1 if the DRAM has been allocated for the device in the ARM PS Linux subsystem
      // 8: the base register for the allocated dram
      //

      // need to update C_S00_AXI_ADDR_WIDTH accordingly
      ,.num_fifo_ps_to_pl_p(1)
      ,.num_fifo_pl_to_ps_p(1)
      ,.num_regs_pl_to_ps_p(2+2+4+(2*counter_num_p))
      ,.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
      ,.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
      ) zps
       (
        .csr_data_o(csr_data_lo)

        // (MBT)
        // note: this ability to probe into the core is not supported in ASIC toolflows but
        // is supported in Verilator, VCS, and Vivado Synthesis.

        // it is very helpful for adding instrumentation to a pre-existing design that you are
        // prototyping in FPGA, where you don't necessarily want to put the support into the ASIC version
        // or don't know yet if you want to.

        // in additional to this approach of poking down into pre-existing registers, you can also
        // instantiate counters, and then pull control signals out of the DUT in order to figure out when
        // to increment the counters.
        //

        ,.csr_data_i({ counter_data
                       ,`COREPATH.be.calculator.pipe_sys.csr.mcycle_lo[63:32]
                       , `COREPATH.be.calculator.pipe_sys.csr.mcycle_lo[31:0]
                       , mem_profiler_r[127:96]
                       , mem_profiler_r[95:64]
                       , mem_profiler_r[63:32]
                       , mem_profiler_r[31:0]
                       , `COREPATH.be.calculator.pipe_sys.csr.minstret_lo[63:32]
                       , `COREPATH.be.calculator.pipe_sys.csr.minstret_lo[31:0]}
                     )

        ,.pl_to_ps_fifo_data_i (pl_to_ps_fifo_data_li)
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo)
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

        ,.S_AXI_ACLK   (s00_axi_aclk)
        ,.S_AXI_ARESETN(s00_axi_aresetn)
        ,.S_AXI_AWADDR (s00_axi_awaddr)
        ,.S_AXI_AWPROT (s00_axi_awprot)
        ,.S_AXI_AWVALID(s00_axi_awvalid)
        ,.S_AXI_AWREADY(s00_axi_awready)
        ,.S_AXI_WDATA  (s00_axi_wdata)
        ,.S_AXI_WSTRB  (s00_axi_wstrb)
        ,.S_AXI_WVALID (s00_axi_wvalid)
        ,.S_AXI_WREADY (s00_axi_wready)
        ,.S_AXI_BRESP  (s00_axi_bresp)
        ,.S_AXI_BVALID (s00_axi_bvalid)
        ,.S_AXI_BREADY (s00_axi_bready)
        ,.S_AXI_ARADDR (s00_axi_araddr)
        ,.S_AXI_ARPROT (s00_axi_arprot)
        ,.S_AXI_ARVALID(s00_axi_arvalid)
        ,.S_AXI_ARREADY(s00_axi_arready)
        ,.S_AXI_RDATA  (s00_axi_rdata)
        ,.S_AXI_RRESP  (s00_axi_rresp)
        ,.S_AXI_RVALID (s00_axi_rvalid)
        ,.S_AXI_RREADY (s00_axi_rready)
        );

   // Add user logic here

   `declare_bp_bedrock_mem_if(paddr_width_p, uce_mem_data_width_lp, lce_id_width_p, lce_assoc_p, uce);

   bp_bedrock_uce_mem_msg_s   io_cmd_lo, io_resp_li;
   logic                      io_cmd_v_lo, io_cmd_ready_and_li;
   logic                      io_resp_v_li, io_resp_yumi_lo;

   `declare_bsg_cache_dma_pkt_s(caddr_width_p);
   bsg_cache_dma_pkt_s         dma_pkt_lo;
   logic                       dma_pkt_v_lo, dma_pkt_yumi_li;
   logic [l2_fill_width_p-1:0] dma_data_lo;
   logic                       dma_data_v_lo, dma_data_yumi_li;
   logic [l2_fill_width_p-1:0] dma_data_li;
   logic                       dma_data_v_li, dma_data_ready_and_lo;

   localparam bp_axi_lite_addr_width_lp = 32;

   logic [bp_axi_lite_addr_width_lp-1:0] waddr_translated_lo, raddr_translated_lo;

   // Address Translation (MBT):
   //
   // The Zynq PS Physical address space looks like this:
   //
   // 0x0000_0000 - 0x0003_FFFF  +256 KB On-chip memory (optional), else DDR DRAM
   // 0x0004_0000 - 0x1FFF_FFFF  +512 MB DDR DRAM for Zynq P2 board
   // 0x2000_0000 - 0x3FFF_FFFF  Another 512 MB DDR DRAM, if the board had it, it does not
   // 0x4000_0000 - 0x7FFF_FFFF  1 GB Mapped to PL via M_AXI_GP0
   // 0x8000_0000 - 0xBFFF_FFFF  1 GB Mapped to PL via M_AXI_GP1
   // 0xFFFC_0000 - 0xFFFF_FFFF  Alternate location for OCM
   //
   // BlackParrot's Physical address space looks like this:
   //    (see github.com/black-parrot/black-parrot/blob/master/docs/platform_guide.md)
   //
   // 0x00_0000_0000 - 0x00_7FFF_FFFF local addresses; 2GB: < 9'b0, 7b tile, 4b device, 20b 1MB space>
   // 0x00_8000_0000 - 0x00_9FFF_FFFF cached dram (up to 512 MB, mapped to Zynq)
   // 0x00_A000_0000 - 0x00_FFFF_FFFF cached dram that does not exist on Zynq board (another 1.5 GB)
   // 0x01_0000_0000 - 0x0F_FFFF_FFFF cached dram that does not exist on Zynq board (another 60 GB)
   // 0x10_0000_0000 - 0x1F_FFFF_FFFF on-chip address space for streaming accelerators
   // 0x20_0000_0000 - 0xFF_FFFF_FFFF off-chip address space
   //
   // Currently, we allocate the Zynq M_AXI_GP0 address space to handle management of the shell
   // that interfaces Zynq to external "accelerators" like BP.
   //
   // So the M_AXI_GP1 address space remains to map BP. A straight-forward translation is to
   // map 0x8000_0000 - 0x8FFF_FFFF of Zynq Physical Address Space (PA) to the same addresses in BP
   //  providing 256 MB of DRAM, leaving 256 MB for the Zynq PS system.
   //
   // Then we can map 0xA000_0000-0xAFFF_FFFF of ARM PA to 0x00_0000_0000 - 0x00_0FFF_FFFF of BP,
   // handling up to tiles 0..15. (This is 256 MB of address space.)
   //
   // since these addresses are going to pop out of the M_AXI_GP1 port, they will already have
   // 0x8000_0000 subtracted, it will ironically have to be added back in by this module
   //
   // M_AXI_GP1: 0x0000_0000 - 0x1000_0000 -> add      0x8000_0000.
   //            0x2000_0000 - 0x3000_0000 -> subtract 0x2000_0000.

   // Life of an address (FPGA):
   //
   //                NBF Loader                 mmap                  Xilinx IPI Switch         This Module
   //  NBF (0x8000_0000) -> ARM VA (0x8000_0000) -> ARM PA (0x8000_0000) -> M_AXI_GP1 (0x0000_0000) -> BP (0x8000_0000)
   //  NBF (0x0000_0000) -> ARM VA (0xA000_0000) -> ARM PA (0xA000_0000) -> M_AXI_GP1 (0x2000_0000) -> BP (0x0000_0000)
   //
   // Life of an address (Verilator):
   //                  NBF Loader              bp_zynq_pl          Verilator Bit Truncation     This Module
   //  NBF (0x8000_0000) -> ARM VA (x8000_0000) ->  ARM PA (0x8000_0000) -> M_AXI_GP1 (0x0000_0000) -> BP (0x8000_0000)
   //  NBF (0x0000_0000) -> ARM VA (xA000_0000) ->  ARM PA (0xA000_0000) -> M_AXI_GP1 (0x2000_0000) -> BP (0x0000_0000)
   //
   //

   logic [31:0] waddr_offset, raddr_offset;

   always_comb
     begin
        // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
        // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF

        waddr_translated_lo = {~s01_axi_awaddr[29], 3'b0, s01_axi_awaddr[0+:28]};
     end

   always_comb
     begin
        // Zynq PA 0x8000_0000 .. 0x8FFF_FFFF -> AXI 0x0000_0000 .. 0x0FFF_FFFF -> BP 0x8000_0000 - 0x8FFF_FFFF
        // Zynq PA 0xA000_0000 .. 0xAFFF_FFFF -> AXI 0x2000_0000 .. 0x2FFF_FFFF -> BP 0x0000_0000 - 0x0FFF_FFFF

        raddr_translated_lo = {~s01_axi_araddr[29], 3'b0, s01_axi_araddr[0+:28]};
     end

   // synopsys translate_off

   always @(negedge s01_axi_aclk)
     if (s01_axi_awvalid & s01_axi_awready)
       if (debug_lp) $display("top_zynq: AXI Write Addr %x -> %x (BP)",s01_axi_awaddr,waddr_translated_lo);

   always @(negedge s01_axi_aclk)
     if (s01_axi_arvalid & s01_axi_arready)
       if (debug_lp) $display("top_zynq: AXI Read Addr %x -> %x (BP)",s01_axi_araddr,raddr_translated_lo);

   // synopsys translate_on


   bp_to_axi_decoder #
     (.bp_params_p(bp_params_p))
   bp_out_data
     (.clk_i   ( s01_axi_aclk)
      ,.reset_i(~s01_axi_aresetn)

      ,.io_cmd_i          (io_cmd_lo)
      ,.io_cmd_v_i        (io_cmd_v_lo)
      ,.io_cmd_ready_and_o(io_cmd_ready_and_li)

      ,.io_resp_o         (io_resp_li)
      ,.io_resp_v_o       (io_resp_v_li)
      ,.io_resp_yumi_i    (io_resp_yumi_lo)

      ,.data_o (pl_to_ps_fifo_data_li)
      ,.v_o    (pl_to_ps_fifo_v_li)
      ,.ready_i(pl_to_ps_fifo_ready_lo)
      );

   localparam axi_id_width_p = 6;
   localparam axi_data_width_p = 64;
   localparam axi_strb_width_p = axi_data_width_p >> 3;
   localparam axi_burst_len_p = 8;

   wire [caddr_width_p-1:0] axi_awaddr;
   wire [caddr_width_p-1:0] axi_araddr;

   // to translate from BP DRAM space to ARM PS DRAM space
   // we xor-subtract the BP DRAM base address (32'h8000_0000) and add the
   // ARM PS allocated memory space physical address.

   always @(negedge s01_axi_aclk)
     begin
        if (m00_axi_awvalid && ((axi_awaddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("top_zynq: unexpectedly high DRAM write: %x",axi_awaddr);
        if (m00_axi_arvalid && ((axi_araddr ^ 32'h8000_0000) >= memory_upper_limit_lp))
          $display("top_zynq: unexpectedly high DRAM read: %x",axi_araddr);
     end

   assign m00_axi_awaddr = (axi_awaddr ^ 32'h8000_0000) + csr_data_lo[2];
   assign m00_axi_araddr = (axi_araddr ^ 32'h8000_0000) + csr_data_lo[2];

   // synopsys translate_off

   always @(negedge m00_axi_aclk)
     if (m00_axi_awvalid & m00_axi_awready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_awaddr,m00_axi_awaddr);

   always @(negedge s01_axi_aclk)
     if (m00_axi_arvalid & m00_axi_arready)
       if (debug_lp) $display("top_zynq: (BP DRAM) AXI Write Addr %x -> %x (AXI HP0)",axi_araddr,m00_axi_araddr);

   // synopsys translate_on
   // BlackParrot reset signal is connected to a CSR (along with
   // the AXI interface reset) so that a regression can be launched
   // without having to reload the bitstream
   wire bp_reset_li = (~csr_data_lo[0][0]) || (~s01_axi_aresetn);


   bsg_dff_reset #(.width_p(128)) dff
     (.clk_i(s01_axi_aclk)
      ,.reset_i(bp_reset_li)
      ,.data_i(mem_profiler_r
               | m00_axi_awvalid << (axi_awaddr[29-:7])
               | m00_axi_arvalid << (axi_araddr[29-:7])
               )
      ,.data_o(mem_profiler_r)
      );

   bp_unicore_axi_sim #
     (.bp_params_p(bp_params_p)
      ,.axi_lite_addr_width_p(bp_axi_lite_addr_width_lp)
      )
   blackparrot
     (.clk_i(s01_axi_aclk)
      ,.reset_i(bp_reset_li)


      // these are I/O requests from BlackParrot that
      // are handled by a program running on the Zynq PS ARM core
      ,.io_cmd_o          (io_cmd_lo)
      ,.io_cmd_v_o        (io_cmd_v_lo)
      ,.io_cmd_ready_and_i(io_cmd_ready_and_li)

      ,.io_resp_i         (io_resp_li)
      ,.io_resp_v_i       (io_resp_v_li)
      ,.io_resp_yumi_o    (io_resp_yumi_lo)

      // these are reads/writes into BlackParrot
      // from the Zynq PS ARM core
      ,.s_axi_lite_awaddr_i (waddr_translated_lo)
      ,.s_axi_lite_awprot_i (s01_axi_awprot)
      ,.s_axi_lite_awvalid_i(s01_axi_awvalid)
      ,.s_axi_lite_awready_o(s01_axi_awready)

      ,.s_axi_lite_wdata_i  (s01_axi_wdata)
      ,.s_axi_lite_wstrb_i  (s01_axi_wstrb)
      ,.s_axi_lite_wvalid_i (s01_axi_wvalid)
      ,.s_axi_lite_wready_o (s01_axi_wready)

      ,.s_axi_lite_bresp_o  (s01_axi_bresp)
      ,.s_axi_lite_bvalid_o (s01_axi_bvalid)
      ,.s_axi_lite_bready_i (s01_axi_bready)

      ,.s_axi_lite_araddr_i (raddr_translated_lo)
      ,.s_axi_lite_arprot_i (s01_axi_arprot)
      ,.s_axi_lite_arvalid_i(s01_axi_arvalid)
      ,.s_axi_lite_arready_o(s01_axi_arready)

      ,.s_axi_lite_rdata_o  (s01_axi_rdata)
      ,.s_axi_lite_rresp_o  (s01_axi_rresp)
      ,.s_axi_lite_rvalid_o (s01_axi_rvalid)
      ,.s_axi_lite_rready_i (s01_axi_rready)


      // these are caches misses coming from BP L2
     ,.dma_pkt_o            (dma_pkt_lo)
      ,.dma_pkt_v_o         (dma_pkt_v_lo)
      ,.dma_pkt_yumi_i      (dma_pkt_yumi_li)

      ,.dma_data_i          (dma_data_li)
      ,.dma_data_v_i        (dma_data_v_li)
      ,.dma_data_ready_and_o(dma_data_ready_and_lo)

      ,.dma_data_o          (dma_data_lo)
      ,.dma_data_v_o        (dma_data_v_lo)
      ,.dma_data_yumi_i     (dma_data_yumi_li)
      );

   assign m00_axi_awqos = '0;
   assign m00_axi_arqos = '0;
   assign m00_axi_wid = m00_axi_awid;

   bsg_cache_to_axi #
     (.addr_width_p(caddr_width_p)
      ,.data_width_p(l2_fill_width_p)
      ,.block_size_in_words_p(l2_block_size_in_fill_p)
      ,.num_cache_p(1)
      ,.axi_id_width_p  (axi_id_width_p)
      ,.axi_data_width_p(axi_data_width_p)
      ,.axi_burst_len_p (axi_burst_len_p)
      )
   cache2axi
     (.clk_i   (m00_axi_aclk)
      ,.reset_i(~m00_axi_aresetn)

      ,.dma_pkt_i       (dma_pkt_lo)
      ,.dma_pkt_v_i     (dma_pkt_v_lo)
      ,.dma_pkt_yumi_o  (dma_pkt_yumi_li)

      ,.dma_data_o      (dma_data_li)
      ,.dma_data_v_o    (dma_data_v_li)
      ,.dma_data_ready_i(dma_data_ready_and_lo)

      ,.dma_data_i      (dma_data_lo)
      ,.dma_data_v_i    (dma_data_v_lo)
      ,.dma_data_yumi_o (dma_data_yumi_li)

      ,.axi_awid_o   (m00_axi_awid)
      ,.axi_awaddr_addr_o(axi_awaddr)
      ,.axi_awaddr_cache_id_o()
      ,.axi_awlen_o  (m00_axi_awlen) // this is an 8-bit output, connected to 4-bit output??
                                     // as long as the max burst length bits in 4-bits, we are okay
      ,.axi_awsize_o (m00_axi_awsize)
      ,.axi_awburst_o(m00_axi_awburst)
      ,.axi_awcache_o(m00_axi_awcache)
      ,.axi_awprot_o (m00_axi_awprot)
      ,.axi_awlock_o (m00_axi_awlock)
      ,.axi_awvalid_o(m00_axi_awvalid)
      ,.axi_awready_i(m00_axi_awready)

      ,.axi_wdata_o  (m00_axi_wdata)
      ,.axi_wstrb_o  (m00_axi_wstrb)
      ,.axi_wlast_o  (m00_axi_wlast)
      ,.axi_wvalid_o (m00_axi_wvalid)
      ,.axi_wready_i (m00_axi_wready)

      ,.axi_bid_i    (m00_axi_bid)
      ,.axi_bresp_i  (m00_axi_bresp)
      ,.axi_bvalid_i (m00_axi_bvalid)
      ,.axi_bready_o (m00_axi_bready)

      ,.axi_arid_o   (m00_axi_arid)
      ,.axi_araddr_addr_o(axi_araddr)
      ,.axi_araddr_cache_id_o()
      ,.axi_arlen_o  (m00_axi_arlen) // 8-bit output connect to 4-bit output?
      ,.axi_arsize_o (m00_axi_arsize)
      ,.axi_arburst_o(m00_axi_arburst)
      ,.axi_arcache_o(m00_axi_arcache)
      ,.axi_arprot_o (m00_axi_arprot)
      ,.axi_arlock_o (m00_axi_arlock)
      ,.axi_arvalid_o(m00_axi_arvalid)
      ,.axi_arready_i(m00_axi_arready)

      ,.axi_rid_i    (m00_axi_rid)
      ,.axi_rdata_i  (m00_axi_rdata)
      ,.axi_rresp_i  (m00_axi_rresp)
      ,.axi_rlast_i  (m00_axi_rlast)
      ,.axi_rvalid_i (m00_axi_rvalid)
      ,.axi_rready_o (m00_axi_rready)
      );
endmodule

