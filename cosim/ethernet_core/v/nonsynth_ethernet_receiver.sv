module nonsynth_ethernet_receiver
#(
  parameter recv_width_p = 8, // byte
  parameter buf_size_p = ((1556 - 1) / recv_width_p + 1) * recv_width_p, // byte
  parameter addr_width_lp = $clog2(buf_size_p / recv_width_p)
)
(
    input logic                          clk_i
  , input logic                          reset_i
  , input logic                          clear_buffer_i
  , output logic                         ready_r_o

  , input logic [addr_width_lp - 1:0]    buffer_read_addr_i
  , output logic [recv_width_p * 8 - 1:0]buffer_read_data_o
  , output logic [15:0]                  rx_packet_size_r_o

  , input logic [recv_width_p * 8 - 1:0] rx_axis_tdata_i
  , input logic [recv_width_p - 1:0]     rx_axis_tkeep_i
  , input logic                          rx_axis_tvalid_i
  , output logic                         rx_axis_tready_o
  , input logic                          rx_axis_tlast_i
  , input logic                          rx_axis_tuser_i
);

  localparam recv_ptr_width_lp = $clog2(buf_size_p / recv_width_p);
//  localparam recv_ptr_offset_width_lp = $clog2(recv_width_p);

  logic [buf_size_p / recv_width_p - 1:0][recv_width_p * 8 - 1:0] buffer_r ;
  logic [15:0] packet_size_r;
  logic [15:0] packet_size_remaining;

  logic [recv_ptr_width_lp - 1:0] recv_ptr_r, recv_ptr_n;
  logic receiving;
  logic bad_frame;

  assign rx_packet_size_r_o = packet_size_r;

  assign bad_frame = rx_axis_tuser_i && rx_axis_tvalid_i && rx_axis_tlast_i;
  assign receiving = rx_axis_tready_o && rx_axis_tvalid_i && !bad_frame;

  assign buffer_read_data_o = buffer_r[buffer_read_addr_i];

  always_ff @(posedge clk_i) begin
    assert(recv_width_p == 8) else $error("receiver now only supports width == 8");
  end

  always_ff @(posedge clk_i) begin
    if(reset_i)
      recv_ptr_r <= '0;
    else begin
      if(receiving)
        recv_ptr_r <= recv_ptr_r + recv_ptr_width_lp'(1'b1);
      else if(bad_frame || clear_buffer_i)
        recv_ptr_r <= '0;
    end
  end

  always_ff @(posedge clk_i) begin
    if(receiving) begin
      buffer_r[recv_ptr_r] <= rx_axis_tdata_i;
    end
  end

  always_comb begin
    case(rx_axis_tkeep_i)
      8'b1111_1111:
        packet_size_remaining = 16'd8;
      8'b0111_1111:
        packet_size_remaining = 16'd7;
      8'b0011_1111:
        packet_size_remaining = 16'd6;
      8'b0001_1111:
        packet_size_remaining = 16'd5;
      8'b0000_1111:
        packet_size_remaining = 16'd4;
      8'b0000_0111:
        packet_size_remaining = 16'd3;
      8'b0000_0011:
        packet_size_remaining = 16'd2;
      8'b0000_0001:
        packet_size_remaining = 16'd1;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      packet_size_r <= '0;
      ready_r_o <= 1'b0;
    end
    else begin
      if(receiving && rx_axis_tlast_i) begin
        packet_size_r <= (recv_ptr_r * 8) + packet_size_remaining;
        ready_r_o <= 1'b1;
      end
      else if(clear_buffer_i) begin
        packet_size_r <= '0;
        ready_r_o <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk_i) begin
    if(reset_i)
      rx_axis_tready_o <= 1'b1;
    else begin
      if(clear_buffer_i)
        rx_axis_tready_o <= 1'b1;
      else if(!bad_frame && rx_axis_tlast_i)
        rx_axis_tready_o <= 1'b0;
    end
  end


endmodule
