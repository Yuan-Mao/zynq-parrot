
module ethernet_wrapper #
(
      parameter  buf_size_p     = 2048 // byte
    , parameter  send_width_p   = 8 // byte
    , parameter  recv_width_p   = 8 // byte
    , parameter  gap_delay_p    = 12 // clock cycle
    , localparam packet_size_width_lp = $clog2(buf_size_p) + 1
    , localparam addr_width_lp = $clog2(buf_size_p / send_width_p)
)
(
      input  logic        clk_i
    , input  logic        reset_i
    , input  logic        clk250_i
    , input  logic        reset_clk250_i
    , output logic        reset_clk250_late_o

    , input  logic        send_i
    , output logic        tx_ready_o
    , input  logic        clear_buffer_i
    , output  logic       rx_ready_o


    , input  logic                              tx_packet_size_v_i
    , input  logic [packet_size_width_lp - 1:0] tx_packet_size_i

    , input  logic [addr_width_lp - 1:0]        buffer_write_addr_i

    , input  logic [send_width_p * 8 -1:0]      buffer_write_data_i
    , input  logic                              buffer_write_data_v_i

    , input  logic [addr_width_lp - 1:0]        buffer_read_addr_i
    , output logic [recv_width_p * 8 - 1:0]     buffer_read_data_o
    , output logic [15:0]                       rx_packet_size_o

    , input  logic        rgmii_rx_clk_i
    , input  logic [3:0]  rgmii_rxd_i
    , input  logic        rgmii_rx_ctl_i
    , output logic        rgmii_tx_clk_o
    , output logic [3:0]  rgmii_txd_o
    , output logic        rgmii_tx_ctl_o

    /* Status */

    , output logic        tx_error_underflow_o
    , output logic        tx_fifo_overflow_o
    , output logic        tx_fifo_bad_frame_o
    , output logic        tx_fifo_good_frame_o
    , output logic        rx_error_bad_frame_o
    , output logic        rx_error_bad_fcs_o
    , output logic        rx_fifo_overflow_o
    , output logic        rx_fifo_bad_frame_o
    , output logic        rx_fifo_good_frame_o

    , output logic [1:0]  speed_o
);

                                            
    logic [63:0] tx_axis_tdata_lo;
    logic  [7:0] tx_axis_tkeep_lo;
    logic        tx_axis_tvalid_lo;
    logic        tx_axis_tlast_lo;
    logic        tx_axis_tready_li;
    logic        tx_axis_tuser_lo;

    logic [63:0] rx_axis_tdata_li;
    logic  [7:0] rx_axis_tkeep_li;
    logic        rx_axis_tvalid_li;
    logic        rx_axis_tready_lo;
    logic        rx_axis_tlast_li;
    logic        rx_axis_tuser_li;


    nonsynth_ethernet_sender #(
        .buf_size_p(buf_size_p)
        ,.send_width_p(send_width_p)
        ,.gap_delay_p(gap_delay_p)
    )
    sender (
         .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.send_i(send_i)
        ,.ready_o(tx_ready_o)

        ,.packet_size_v_i(tx_packet_size_v_i)
        ,.packet_size_i(tx_packet_size_i)
                                  
        ,.buffer_write_addr_i(buffer_write_addr_i)
                                  
        ,.buffer_write_data_i(buffer_write_data_i)
        ,.buffer_write_data_v_i(buffer_write_data_v_i)
                      
        ,.tx_axis_tdata_o(tx_axis_tdata_lo)
        ,.tx_axis_tkeep_o(tx_axis_tkeep_lo)
        ,.tx_axis_tvalid_o(tx_axis_tvalid_lo)
        ,.tx_axis_tlast_o(tx_axis_tlast_lo)
        ,.tx_axis_tready_i(tx_axis_tready_li)
        ,.tx_axis_tuser_o(tx_axis_tuser_lo)
    );

    nonsynth_ethernet_receiver receiver (
        .clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.clear_buffer_i(clear_buffer_i)
       ,.ready_r_o(rx_ready_o)

       ,.buffer_read_addr_i(buffer_read_addr_i)
       ,.buffer_read_data_o(buffer_read_data_o)
       ,.rx_packet_size_r_o(rx_packet_size_o)
                        
       ,.rx_axis_tdata_i(rx_axis_tdata_li)
       ,.rx_axis_tkeep_i(rx_axis_tkeep_li)
       ,.rx_axis_tvalid_i(rx_axis_tvalid_li)
       ,.rx_axis_tready_o(rx_axis_tready_lo)
       ,.rx_axis_tlast_i(rx_axis_tlast_li)
       ,.rx_axis_tuser_i(rx_axis_tuser_li)
    );

    eth_mac_1g_rgmii_fifo #(.AXIS_DATA_WIDTH(64)) mac (
        .gtx_clk250(clk250_i)
       ,.gtx_rst(reset_clk250_i)
       ,.gtx_rst_late(reset_clk250_late_o)
       ,.logic_clk(clk_i)
       ,.logic_rst(reset_i)

       ,.tx_axis_tdata(tx_axis_tdata_lo)
       ,.tx_axis_tkeep(tx_axis_tkeep_lo)
       ,.tx_axis_tvalid(tx_axis_tvalid_lo)
       ,.tx_axis_tready(tx_axis_tready_li)
       ,.tx_axis_tlast(tx_axis_tlast_lo)
       ,.tx_axis_tuser(tx_axis_tuser_lo)

       ,.rx_axis_tdata(rx_axis_tdata_li)
       ,.rx_axis_tkeep(rx_axis_tkeep_li)
       ,.rx_axis_tvalid(rx_axis_tvalid_li)
       ,.rx_axis_tready(rx_axis_tready_lo)
       ,.rx_axis_tlast(rx_axis_tlast_li)
       ,.rx_axis_tuser(rx_axis_tuser_li)

       ,.rgmii_rx_clk(rgmii_rx_clk_i)
       ,.rgmii_rxd(rgmii_rxd_i)
       ,.rgmii_rx_ctl(rgmii_rx_ctl_i)
       ,.rgmii_tx_clk(rgmii_tx_clk_o)
       ,.rgmii_txd(rgmii_txd_o)
       ,.rgmii_tx_ctl(rgmii_tx_ctl_o)

       ,.tx_error_underflow(tx_error_underflow_o)
       ,.tx_fifo_overflow(tx_fifo_overflow_o)
       ,.tx_fifo_bad_frame(tx_fifo_bad_frame_o)
       ,.tx_fifo_good_frame(tx_fifo_good_frame_o)
       ,.rx_error_bad_frame(rx_error_bad_frame_o)
       ,.rx_error_bad_fcs(rx_error_bad_fcs_o)
       ,.rx_fifo_overflow(rx_fifo_overflow_o)
       ,.rx_fifo_bad_frame(rx_fifo_bad_frame_o)
       ,.rx_fifo_good_frame(rx_fifo_good_frame_o)
       ,.speed(speed_o)

       ,.ifg_delay(8'd24)
    );
	
endmodule
