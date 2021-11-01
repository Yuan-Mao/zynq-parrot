`include "bsg_defines.v"

module status_stat #(parameter `BSG_INV_PARAM(els_p)
                   , parameter `BSG_INV_PARAM(total_stat_p)
                   )
(
    input  logic                      clk_i
  , input  logic                      reset_i
  , input  logic [total_stat_p - 1:0] v_i
  , input  logic [total_stat_p - 1:0] ready_i
  , input  logic [total_stat_p - 1:0] yumi_i
  , output logic [total_stat_p - 1:0][`BSG_WIDTH(els_p) - 1:0] count_o
);

genvar i;
generate
    for(i = 0;i < total_stat_p;i = i + 1) begin
        bsg_flow_counter #(.els_p(els_p)) stat_counter_inst (
            .clk_i(clk_i)
           ,.reset_i(reset_i)
           ,.v_i(v_i[i])
           ,.ready_i(ready_i[i])
           ,.yumi_i(yumi_i[i])
           ,.count_o(count_o[i])
        );
    end
endgenerate


endmodule
