
`include "bsg_defines.v"
`include "bp_zynq_pl.vh"

module ethernet_controller_wrapper
  import bp_common_pkg::*;
#(
     // AXI CHANNEL PARAMS
      parameter axil_data_width_p = 32
    , parameter axil_addr_width_p = 32
)
(
      input  logic                         clk_i
    , input  logic                         reset_i
    , input  logic                         clk250_i
    // zynq-7000 specific: 200 MHZ for IDELAY tap value
    , input  logic                         iodelay_ref_clk_i

    //====================== AXI-4 LITE =========================
    // WRITE ADDRESS CHANNEL SIGNALS
    , input [axil_addr_width_p-1:0]        s_axil_awaddr_i
    , input [2:0]                          s_axil_awprot_i
    , input                                s_axil_awvalid_i
    , output logic                         s_axil_awready_o
 
    // WRITE DATA CHANNEL SIGNALS
    , input [axil_data_width_p-1:0]        s_axil_wdata_i
    , input [(axil_data_width_p>>3)-1:0]   s_axil_wstrb_i
    , input                                s_axil_wvalid_i
    , output logic                         s_axil_wready_o
 
    // WRITE RESPONSE CHANNEL SIGNALS
    , output logic [1:0]                   s_axil_bresp_o
    , output logic                         s_axil_bvalid_o
    , input                                s_axil_bready_i
 
    // READ ADDRESS CHANNEL SIGNALS
    , input [axil_addr_width_p-1:0]        s_axil_araddr_i
    , input [2:0]                          s_axil_arprot_i
    , input                                s_axil_arvalid_i
    , output logic                         s_axil_arready_o
 
    // READ DATA CHANNEL SIGNALS
    , output logic [axil_data_width_p-1:0] s_axil_rdata_o
    , output logic [1:0]                   s_axil_rresp_o
    , output logic                         s_axil_rvalid_o
    , input                                s_axil_rready_i

    //====================== Ethernet RGMII =========================
    , input  logic                         rgmii_rx_clk_i
    , input  logic [3:0]                   rgmii_rxd_i
    , input  logic                         rgmii_rx_ctl_i
    , output logic                         rgmii_tx_clk_o
    , output logic [3:0]                   rgmii_txd_o
    , output logic                         rgmii_tx_ctl_o

    //====================== Ethernet IRQ =========================
    , output logic                         irq_o
);

    // target ("SIM", "GENERIC", "XILINX", "ALTERA")
`ifdef FPGA
    localparam TARGET                = "XILINX";
`else
    localparam TARGET                = "GENERIC";
`endif
    // IODDR style ("IODDR", "IODDR2")
    // Use IODDR for Virtex-4, Virtex-5, Virtex-6, 7 Series, Ultrascale
    // Use IODDR2 for Spartan-6
    localparam IODDR_STYLE           = "IODDR";
    // Clock input style ("BUFG", "BUFR", "BUFIO", "BUFIO2")
    // Use BUFR for Virtex-6, 7-series
    // Use BUFG for Virtex-5, Spartan-6, Ultrascale
    localparam  CLOCK_INPUT_STYLE    = "BUFR";

    localparam buf_size_lp           = 2048; // byte
    localparam packet_size_width_lp = $clog2(buf_size_lp) + 1;
    localparam size_width_lp = `BSG_WIDTH(`BSG_SAFE_CLOG2(axil_data_width_p/8));

    logic                         v_lo;
    logic                         ready_and_li;
    logic [axil_addr_width_p-1:0] addr_lo;
    logic                         wr_en_lo;
    logic [1:0]                   data_size_lo;
    logic [axil_data_width_p-1:0] wdata_lo;
    logic                         ready_and_lo;

    logic [axil_data_width_p-1:0] resp_fifo_li;
    logic                         resp_fifo_v_li;
    logic                         resp_fifo_ready_lo;
    logic                         resp_fifo_v_lo;
    logic [axil_data_width_p-1:0] resp_fifo_lo;
    logic                         resp_fifo_ready_and_li;
    logic                         resp_fifo_yumi_li;
    logic                         disable_r;

    logic                         rx_interrupt_pending_lo;
    logic                         tx_interrupt_pending_lo;

    wire write_en_li = v_lo & wr_en_lo;
    wire read_en_li = v_lo & ~wr_en_lo;
    logic read_en_lo;

    logic reset_r_lo;
    bsg_dff #(.width_p(1))
      reset_reg (
        .clk_i(clk_i)
        ,.data_i(reset_i)
        ,.data_o(reset_r_lo)
        );

    // I/O delay control for zynq-7000
    iodelay_control iodelay_control (
      .clk_i(clk_i)
     ,.reset_r_i(reset_r_lo)
     ,.iodelay_ref_clk_i(iodelay_ref_clk_i)
    );

`ifdef FPGA
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    logic [3:0] reset_clk250_sync_r;
`else
    logic [3:0] reset_clk250_sync_r;
`endif


    // reset sync logic for clk250
    logic reset_clk250_late_o; // UNUSED
    always @(posedge clk250_i or posedge reset_r_lo) begin
        if(reset_r_lo)
            reset_clk250_sync_r <= '1;
        else
            reset_clk250_sync_r <= {1'b0, reset_clk250_sync_r[3:1]};
    end
    wire reset_clk250_li  = reset_clk250_sync_r[0];

    // Allow only 1 outstanding request
    bsg_dff_reset_set_clear #(
      .width_p(1)
      ,.clear_over_set_p(0)
    ) disable_reg (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.set_i(v_lo & ready_and_li)
      ,.clear_i(resp_fifo_yumi_li)
      ,.data_o(disable_r)
    );
    assign resp_fifo_yumi_li = resp_fifo_v_lo & resp_fifo_ready_and_li;
    assign ready_and_li = ~disable_r;
    assign resp_fifo_v_li = read_en_lo | write_en_li;

    logic [1:0] data_size_r;;
    // align with read data
    bsg_dff_reset
     #(.width_p(2))
      data_size_buf (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.data_i(data_size_lo)
        ,.data_o(data_size_r)
      );

    logic [axil_data_width_p-1:0] resp_fifo_packed_li;
    bsg_bus_pack
     #(.in_width_p(axil_data_width_p), .out_width_p(axil_data_width_p))
      bus_pack
       (.data_i(resp_fifo_li)
        ,.sel_i('b0)
        ,.size_i(data_size_r)
        ,.data_o(resp_fifo_packed_li)
        );

    // this tracks both read and write
    bsg_fifo_1r1w_small #(
       .width_p(axil_data_width_p)
      ,.els_p(2)
    ) resp_fifo (
       .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(resp_fifo_v_li)
      ,.ready_o(resp_fifo_ready_lo)
      ,.data_i(resp_fifo_packed_li)
      ,.v_o(resp_fifo_v_lo)
      ,.data_o(resp_fifo_lo)
      ,.yumi_i(resp_fifo_yumi_li)
    );

    //synopsys translate_off
    always_ff @(posedge clk_i) begin
      if(~reset_i & (resp_fifo_v_li & ~resp_fifo_ready_lo))
        $display("ethernet_controller_wrapper.sv: read data dropped");
    end
    //synopsys translate_on

    axil_client_adaptor #(
       .axil_data_width_p(axil_data_width_p)
      ,.axil_addr_width_p(axil_addr_width_p)
    ) axil_client_adaptor (
       .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_o(v_lo)
      ,.ready_and_i(ready_and_li)
      ,.addr_o(addr_lo)
      ,.wr_en_o(wr_en_lo)
      ,.data_size_o(data_size_lo)
      ,.wdata_o(wdata_lo)

      ,.v_i(resp_fifo_v_lo)
      ,.ready_and_o(resp_fifo_ready_and_li)
      ,.rdata_i(resp_fifo_lo)

      ,.s_axil_awaddr_i
      ,.s_axil_awprot_i
      ,.s_axil_awvalid_i
      ,.s_axil_awready_o

      ,.s_axil_wdata_i
      ,.s_axil_wstrb_i
      ,.s_axil_wvalid_i
      ,.s_axil_wready_o

      ,.s_axil_bresp_o
      ,.s_axil_bvalid_o
      ,.s_axil_bready_i

      ,.s_axil_araddr_i
      ,.s_axil_arprot_i
      ,.s_axil_arvalid_i
      ,.s_axil_arready_o

      ,.s_axil_rdata_o
      ,.s_axil_rresp_o
      ,.s_axil_rvalid_o
      ,.s_axil_rready_i
    );

    ethernet_controller_core #(
        .TARGET(TARGET)
       ,.IODDR_STYLE(IODDR_STYLE)
       ,.CLOCK_INPUT_STYLE(CLOCK_INPUT_STYLE)
       ,.buf_size_p(buf_size_lp)
       ,.axis_width_p(axil_data_width_p)
    ) eth (
        .clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.clk250_i(clk250_i)
       ,.reset_clk250_i(reset_clk250_li)
       ,.reset_clk250_late_o(/* UNUSED */)

       ,.addr_i(addr_lo)
       ,.write_en_i(write_en_li)
       ,.read_en_i(read_en_li)
       ,.op_size_i(data_size_lo)
       ,.write_data_i(wdata_lo)
       ,.read_data_o(resp_fifo_li) // sync read
       ,.read_data_v_o(read_en_lo)

       ,.rx_interrupt_pending_o(rx_interrupt_pending_lo)
       ,.tx_interrupt_pending_o(tx_interrupt_pending_lo)

       ,.rgmii_rx_clk_i(rgmii_rx_clk_i)
       ,.rgmii_rxd_i(rgmii_rxd_i)
       ,.rgmii_rx_ctl_i(rgmii_rx_ctl_i)
       ,.rgmii_tx_clk_o(rgmii_tx_clk_o)
       ,.rgmii_txd_o(rgmii_txd_o)
       ,.rgmii_tx_ctl_o(rgmii_tx_ctl_o)
    );

    assign irq_o = rx_interrupt_pending_lo | tx_interrupt_pending_lo;
endmodule
