
  typedef struct packed
  {
    logic fe_queue_stall;
    logic fe_wait_stall;
    logic itlb_miss;
    logic icache_miss;
    logic icache_rollback;
    logic icache_fence;
    logic branch_override;
    logic ret_override;
    logic fe_cmd;
    logic fe_cmd_fence;
    logic mispredict;
    logic control_haz;
    logic long_haz;
    logic data_haz;
    logic aux_dep;
    logic load_dep;
    logic mul_dep;
    logic fma_dep;
    logic sb_iraw_dep;
    logic sb_fraw_dep;
    logic sb_iwaw_dep;
    logic sb_fwaw_dep;
    logic struct_haz;
    logic long_i_busy;
    logic long_f_busy;
    logic long_if_busy;
    logic dtlb_miss;
    logic dcache_miss;
    logic dcache_rollback;
    logic eret;
    logic exception;
    logic _interrupt;
    logic unknown;
  }  bp_stall_reason_s;

  typedef enum logic [5:0]
  {
    fe_queue_stall       = 6'd32
    ,fe_wait_stall       = 6'd31
    ,itlb_miss           = 6'd30
    ,icache_miss         = 6'd29
    ,icache_rollback     = 6'd28
    ,icache_fence        = 6'd27
    ,branch_override     = 6'd26
    ,ret_override        = 6'd25
    ,fe_cmd              = 6'd24
    ,fe_cmd_fence        = 6'd23
    ,mispredict          = 6'd22
    ,control_haz         = 6'd21
    ,long_haz            = 6'd20
    ,data_haz            = 6'd19
    ,aux_dep             = 6'd18
    ,load_dep            = 6'd17
    ,mul_dep             = 6'd16
    ,fma_dep             = 6'd15
    ,sb_iraw_dep         = 6'd14
    ,sb_fraw_dep         = 6'd13
    ,sb_iwaw_dep         = 6'd12
    ,sb_fwaw_dep         = 6'd11
    ,struct_haz          = 6'd10
    ,long_i_busy         = 6'd9
    ,long_f_busy         = 6'd8
    ,long_if_busy        = 6'd7
    ,dtlb_miss           = 6'd6
    ,dcache_miss         = 6'd5
    ,dcache_rollback     = 6'd4
    ,eret                = 6'd3
    ,exception           = 6'd2
    ,_interrupt          = 6'd1
    ,unknown             = 6'd0
  } bp_stall_reason_e;

// The BlackParrot core pipeline is a mostly non-stalling pipeline, decoupled between the front-end
// and back-end.
`include "bp_common_defines.svh"
`include "bp_top_defines.svh"
`include "bp_be_defines.svh"

module bp_nonsynth_core_profiler
  import bp_common_pkg::*;
  import bp_be_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)

    , parameter stall_trace_file_p = "stall"

    , localparam dispatch_pkt_width_lp = `bp_be_dispatch_pkt_width(vaddr_width_p)
    , localparam commit_pkt_width_lp = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    )
   (input clk_i
    , input reset_i
    , input freeze_i

    , input [`BSG_SAFE_CLOG2(num_core_p)-1:0] mhartid_i

    // IF1 events
    , input fe_wait_stall
    , input fe_queue_stall

    // IF2 events
    , input itlb_miss
    , input icache_miss
    , input icache_rollback
    , input icache_fence
    , input branch_override
    , input ret_override

    // Backwards ISS events
    // TODO: Differentiate between different FE cmds
    , input fe_cmd
    , input fe_cmd_fence

    // ISD events
    , input mispredict

    , input long_haz
    , input control_haz
    , input data_haz
    , input aux_dep
    , input load_dep
    , input mul_dep
    , input fma_dep
    , input sb_iraw_dep
    , input sb_fraw_dep
    , input sb_iwaw_dep
    , input sb_fwaw_dep
    , input struct_haz
    , input long_i_busy
    , input long_f_busy
    , input long_if_busy

    // ALU events

    // MUL events

    // MEM events
    , input dtlb_miss
    , input dcache_miss
    , input dcache_rollback
    , input eret
    , input exception
    , input _interrupt

    // Reservation packet
    , input [dispatch_pkt_width_lp-1:0] reservation

    // Trap packet
    , input [commit_pkt_width_lp-1:0] commit_pkt
    );

  `declare_bp_be_internal_if_structs(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);

  localparam num_stages_p = 7;
  bp_stall_reason_s [num_stages_p-1:0] stall_stage_n, stall_stage_r;
  bsg_dff_reset
   #(.width_p($bits(bp_stall_reason_s)*num_stages_p))
   stall_pipe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(stall_stage_n)
     ,.data_o(stall_stage_r)
     );

  bp_be_dispatch_pkt_s reservation_r;
  bsg_dff_chain
   #(.width_p($bits(bp_be_dispatch_pkt_s))
     ,.num_stages_p(4)
     )
   reservation_pipe
    (.clk_i(clk_i)
     ,.data_i(reservation)
     ,.data_o(reservation_r)
     );

  bp_be_commit_pkt_s commit_pkt_r;
  bsg_dff_reset
   #(.width_p($bits(bp_be_commit_pkt_s)))
   trap_pipe
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(commit_pkt)
     ,.data_o(commit_pkt_r)
     );

  logic [29:0] cycle_cnt;
  bsg_counter_clear_up
   #(.max_val_p(2**30-1), .init_val_p(0))
   cycle_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.clear_i(1'b0)
     ,.up_i(1'b1)
     ,.count_o(cycle_cnt)
     );

  always_comb
    begin
      // By default, move down the pipe
      for (integer i = 0; i < num_stages_p; i++)
        stall_stage_n[i] = (i == '0) ? '0 : stall_stage_r[i-1];

      // IF1
      stall_stage_n[0].fe_wait_stall     |= fe_wait_stall;
      stall_stage_n[0].fe_queue_stall    |= fe_queue_stall;
      stall_stage_n[0].itlb_miss         |= itlb_miss;
      stall_stage_n[0].icache_rollback   |= icache_rollback;
      stall_stage_n[0].icache_miss       |= icache_miss;
      stall_stage_n[0].icache_fence      |= icache_fence;
      stall_stage_n[0].fe_cmd            |= fe_cmd;
      stall_stage_n[0].exception         |= exception;
      stall_stage_n[0].eret              |= eret;
      stall_stage_n[0]._interrupt        |= _interrupt;

      // IF2
      stall_stage_n[1].fe_queue_stall    |= fe_queue_stall;
      stall_stage_n[1].itlb_miss         |= itlb_miss;
      stall_stage_n[1].icache_rollback   |= icache_rollback;
      stall_stage_n[1].icache_fence      |= icache_fence;
      stall_stage_n[1].fe_cmd            |= fe_cmd;
      stall_stage_n[1].branch_override   |= branch_override;
      stall_stage_n[1].ret_override      |= ret_override;
      stall_stage_n[1].exception         |= exception;
      stall_stage_n[1].eret              |= eret;
      stall_stage_n[1]._interrupt        |= _interrupt;

      // ISD
      stall_stage_n[2].itlb_miss         |= itlb_miss;
      stall_stage_n[2].icache_rollback   |= icache_rollback;
      stall_stage_n[2].icache_fence      |= icache_fence;
      stall_stage_n[2].fe_cmd            |= fe_cmd;
      stall_stage_n[2].dcache_rollback   |= dcache_rollback;
      stall_stage_n[2].exception         |= exception;
      stall_stage_n[2].eret              |= eret;
      stall_stage_n[2]._interrupt        |= _interrupt;

      // EX1
      stall_stage_n[3].fe_cmd_fence      |= fe_cmd_fence;
      stall_stage_n[3].mispredict        |= mispredict;
      stall_stage_n[3].dcache_miss       |= dcache_miss;
      stall_stage_n[3].data_haz          |= data_haz;
      stall_stage_n[3].aux_dep           |= aux_dep;
      stall_stage_n[3].load_dep          |= load_dep;
      stall_stage_n[3].mul_dep           |= mul_dep;
      stall_stage_n[3].fma_dep           |= fma_dep;
      stall_stage_n[3].sb_iraw_dep       |= sb_iraw_dep;
      stall_stage_n[3].sb_fraw_dep       |= sb_fraw_dep;
      stall_stage_n[3].sb_iwaw_dep       |= sb_iwaw_dep;
      stall_stage_n[3].sb_fwaw_dep       |= sb_fwaw_dep;
      stall_stage_n[3].struct_haz        |= struct_haz;
      stall_stage_n[3].long_i_busy       |= long_i_busy;
      stall_stage_n[3].long_f_busy       |= long_f_busy;
      stall_stage_n[3].long_if_busy      |= long_if_busy;
      stall_stage_n[3].control_haz       |= control_haz;
      stall_stage_n[3].long_haz          |= long_haz;
      stall_stage_n[3].dcache_rollback   |= dcache_rollback;
      stall_stage_n[3].exception         |= exception;
      stall_stage_n[3].eret              |= eret;
      stall_stage_n[3]._interrupt        |= _interrupt;

      // EX2
      stall_stage_n[4].dcache_rollback   |= dcache_rollback;
      stall_stage_n[4].exception         |= exception;
      stall_stage_n[4].eret              |= eret;
      stall_stage_n[4]._interrupt        |= _interrupt;

      // EX3
      stall_stage_n[5].dcache_rollback   |= dcache_rollback;
      stall_stage_n[5].exception         |= exception;
      stall_stage_n[5].eret              |= eret;
      stall_stage_n[5]._interrupt        |= _interrupt;

      stall_stage_n[6].dcache_rollback   |= dcache_rollback;
      stall_stage_n[6].exception         |= exception;
      stall_stage_n[6].eret              |= eret;
      stall_stage_n[6]._interrupt        |= _interrupt;
    end

  bp_stall_reason_s stall_reason_dec;
  assign stall_reason_dec = stall_stage_r[num_stages_p-1];
  logic [$bits(bp_stall_reason_e)-1:0] stall_reason_lo;
  bp_stall_reason_e stall_reason_enum;
  logic stall_reason_v;
  bsg_priority_encode
   #(.width_p($bits(bp_stall_reason_s)), .lo_to_hi_p(1))
   stall_encode
    (.i(stall_reason_dec)
     ,.addr_o(stall_reason_lo)
     ,.v_o(stall_reason_v)
     );
  assign stall_reason_enum = bp_stall_reason_e'(stall_reason_lo);

  // synopsys translate_off
  int stall_hist [bp_stall_reason_e];
  always_ff @(posedge clk_i)
    if (~reset_i & ~freeze_i & ~commit_pkt_r.instret)
      stall_hist[stall_reason_enum] <= stall_hist[stall_reason_enum] + 1'b1;

  integer file;
  string file_name;
  wire reset_li = reset_i | freeze_i;
  always_ff @(negedge reset_li)
    begin
      file_name = $sformatf("%s_%x.trace", stall_trace_file_p, mhartid_i);
      file      = $fopen(file_name, "w");
      $fwrite(file, "%s,%s,%s,%s,%s\n", "cycle", "x", "y", "pc", "operation");
    end

  wire x_cord_li = '0;
  wire y_cord_li = '0;

  always_ff @(negedge clk_i)
    begin
      if (~reset_i & ~freeze_i & commit_pkt_r.instret)
        $fwrite(file, "%0d,%x,%x,%x,%s", cycle_cnt, x_cord_li, y_cord_li, commit_pkt_r.pc, "instr");
      else if (~reset_i & ~freeze_i)
        $fwrite(file, "%0d,%x,%x,%x,%s", cycle_cnt, x_cord_li, y_cord_li, commit_pkt_r.pc, stall_reason_enum.name());

      if (~reset_i & ~freeze_i)
        $fwrite(file, "\n");
    end

  `ifndef VERILATOR
  final
    begin
      $fwrite(file, "=============================\n");
      $fwrite(file, "Total Stalls:\n");
      foreach (stall_hist[i])
        $fwrite(file, "%s: %0d\n", i.name(), stall_hist[i]);
    end
  `endif
  // synopsys translate_on

endmodule

