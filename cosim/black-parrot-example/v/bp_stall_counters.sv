`include "bp_common_defines.svh"
`include "bp_top_defines.svh"
`include "bp_be_defines.svh"

module bp_stall_counters
  import bp_common_pkg::*;
  import bp_be_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)
    , parameter width_p = 32

    , localparam commit_pkt_width_lp = `bp_be_commit_pkt_width(vaddr_width_p, paddr_width_p)
    )
   (input clk_i
    , input reset_i
    , input freeze_i

    // IF1 events
    , input fe_queue_stall_i

    // IF2 events
    , input icache_rollback_i
    , input icache_miss_i
    , input icache_fence_i
    
    , input taken_override_i
    , input ret_override_i

    // Backwards ISS events
    , input fe_cmd_i
    , input fe_cmd_fence_i

    // ISD events
    , input mispredict_i

    , input control_haz_i
    , input long_haz_i

    , input data_haz_i
    , input aux_dep_i
    , input load_dep_i
    , input mul_dep_i
    , input fma_dep_i
    , input sb_iraw_dep_i
    , input sb_fraw_dep_i
    , input sb_iwaw_dep_i
    , input sb_fwaw_dep_i

    , input struct_haz_i

    // ALU events

    // MUL events

    // MEM events
    , input dcache_rollback_i
    , input dcache_miss_i

    // Trap packet
    , input [commit_pkt_width_lp-1:0] commit_pkt_i

    // output counters
    , output [width_p-1:0] fe_queue_stall_o

    , output [width_p-1:0] icache_rollback_o
    , output [width_p-1:0] icache_miss_o
    , output [width_p-1:0] icache_fence_o

    , output [width_p-1:0] taken_override_o
    , output [width_p-1:0] ret_override_o

    , output [width_p-1:0] fe_cmd_o
    , output [width_p-1:0] fe_cmd_fence_o

    , output [width_p-1:0] mispredict_o

    , output [width_p-1:0] control_haz_o
    , output [width_p-1:0] long_haz_o

    , output [width_p-1:0] data_haz_o
    , output [width_p-1:0] aux_dep_o
    , output [width_p-1:0] load_dep_o
    , output [width_p-1:0] mul_dep_o
    , output [width_p-1:0] fma_dep_o
    , output [width_p-1:0] sb_iraw_dep_o
    , output [width_p-1:0] sb_fraw_dep_o
    , output [width_p-1:0] sb_iwaw_dep_o
    , output [width_p-1:0] sb_fwaw_dep_o

    , output [width_p-1:0] struct_haz_o

    , output [width_p-1:0] dcache_rollback_o
    , output [width_p-1:0] dcache_miss_o

    , output [width_p-1:0] unknown_o
    );


   bp_nonsynth_core_profiler
    #(.bp_params_p(bp_params_p))
    prof
    (.clk_i          (clk_i)
    ,.reset_i        (reset_i)
    ,.freeze_i       (freeze_i)
    ,.mhartid_i      ('0)
    ,.fe_wait_stall  ('0)
    ,.fe_queue_stall (fe_queue_stall_i)
    ,.itlb_miss      ('0)
    ,.icache_miss    (icache_miss_i)
    ,.icache_rollback(icache_rollback_i)
    ,.icache_fence   (icache_fence_i)
    ,.branch_override(taken_override_i)
    ,.ret_override   (ret_override_i)
    ,.fe_cmd         (fe_cmd_i)
    ,.fe_cmd_fence   (fe_cmd_fence_i)
    ,.mispredict     (mispredict_i)
    ,.control_haz    (control_haz_i)
    ,.long_haz       (long_haz_i)
    ,.data_haz       (data_haz_i)
    ,.aux_dep        (aux_dep_i)
    ,.load_dep       (load_dep_i)
    ,.mul_dep        (mul_dep_i)
    ,.fma_dep        (fma_dep_i)
    ,.sb_iraw_dep    (sb_iraw_dep_i)
    ,.sb_fraw_dep    (sb_fraw_dep_i)
    ,.sb_iwaw_dep    (sb_iwaw_dep_i)
    ,.sb_fwaw_dep    (sb_fwaw_dep_i)
    ,.struct_haz     (struct_haz_i)
    ,.dtlb_miss      ('0)
    ,.dcache_miss    (dcache_miss_i)
    ,.dcache_rollback(dcache_rollback_i)
    ,.eret           ('0)
    ,.exception      ('0)
    ,._interrupt     ('0)
    ,.reservation    ('0)
    ,.commit_pkt     (commit_pkt_i)
    );

   wire stall_v = ~prof.commit_pkt_r.instret;

   bsg_counter_clear_up 
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    fe_queue_stall_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == fe_queue_stall))
    ,.count_o(fe_queue_stall_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    icache_rollback_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == icache_rollback))
    ,.count_o(icache_rollback_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    icache_miss_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == icache_miss))
    ,.count_o(icache_miss_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    icache_fence_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == icache_fence))
    ,.count_o(icache_fence_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    taken_override_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == branch_override))
    ,.count_o(taken_override_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    ret_override_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == ret_override))
    ,.count_o(ret_override_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    fe_cmd_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == fe_cmd))
    ,.count_o(fe_cmd_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    fe_cmd_fence_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == fe_cmd_fence))
    ,.count_o(fe_cmd_fence_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    mispredict_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == mispredict))
    ,.count_o(mispredict_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    dcache_rollback_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == dcache_rollback))
    ,.count_o(dcache_rollback_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    dcache_miss_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == dcache_miss))
    ,.count_o(dcache_miss_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    control_haz_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == control_haz))
    ,.count_o(control_haz_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    long_haz_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == long_haz))
    ,.count_o(long_haz_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    data_haz_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == data_haz))
    ,.count_o(data_haz_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    aux_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == aux_dep))
    ,.count_o(aux_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    load_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == load_dep))
    ,.count_o(load_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    mul_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == mul_dep))
    ,.count_o(mul_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    fma_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == fma_dep))
    ,.count_o(fma_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    sb_iraw_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == sb_iraw_dep))
    ,.count_o(sb_iraw_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    sb_fraw_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == sb_fraw_dep))
    ,.count_o(sb_fraw_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    sb_iwaw_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == sb_iwaw_dep))
    ,.count_o(sb_iwaw_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    sb_fwaw_dep_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == sb_fwaw_dep))
    ,.count_o(sb_fwaw_dep_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    struct_haz_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == struct_haz))
    ,.count_o(struct_haz_o)
    );

   bsg_counter_clear_up
    #(.max_val_p((width_p+1)'(2**width_p-1)), .init_val_p(0))
    unknown_cnt
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(freeze_i)
    ,.up_i(stall_v & (prof.stall_reason_enum == unknown))
    ,.count_o(unknown_o)
    );

endmodule
