
`timescale 1 ns / 1 ps

`include "bp_zynq_pl.vh"

module top #
  (
   // Users to add parameters here

   // User parameters ends
   // Do not modify the parameters beyond this line


   // Parameters of Axi Slave Bus Interface S00_AXI
   parameter integer C_S00_AXI_DATA_WIDTH = 32,
   parameter integer C_S00_AXI_ADDR_WIDTH = 7 // should be the same as -DGP0_ADDR_WIDTH in Makefile
   )
   (
    // Users to add ports here
    // User ports ends
    // Do not modify the ports beyond this line

`ifdef FPGA 
    // Ports of Axi Slave Bus Interface S00_AXI
    input wire                                  s00_axi_aclk,
    input wire                                  clk250_i,
    input wire                                  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_awaddr,
    input wire [2 : 0]                          s00_axi_awprot,
    input wire                                  s00_axi_awvalid,
    output wire                                 s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0]     s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire                                  s00_axi_wvalid,
    output wire                                 s00_axi_wready,
    output wire [1 : 0]                         s00_axi_bresp,
    output wire                                 s00_axi_bvalid,
    input wire                                  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0]     s00_axi_araddr,
    input wire [2 : 0]                          s00_axi_arprot,
    input wire                                  s00_axi_arvalid,
    output wire                                 s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0]    s00_axi_rdata,
    output wire [1 : 0]                         s00_axi_rresp,
    output wire                                 s00_axi_rvalid,
    input wire                                  s00_axi_rready
    );
`else
    );
    logic clk250_i;
    logic s00_axi_aclk, s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [2:0] s00_axi_awprot;
    logic s00_axi_awvalid, s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic s00_axi_wvalid, s00_axi_wready;
    logic [1:0] s00_axi_bresp;
    logic s00_axi_bvalid, s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [2:0] s00_axi_arprot;
    logic s00_axi_arvalid, s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    logic [1:0] s00_axi_rresp;
    logic s00_axi_rvalid, s00_axi_rready;
    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S00_AXI_ADDR_WIDTH), .data_width_p(C_S00_AXI_DATA_WIDTH))
     axil0
      (.aclk_o(s00_axi_aclk)
       ,.aresetn_o(s00_axi_aresetn)

       ,.awaddr_o(s00_axi_awaddr)
       ,.awprot_o(s00_axi_awprot)
       ,.awvalid_o(s00_axi_awvalid)
       ,.awready_i(s00_axi_awready)
       ,.wdata_o(s00_axi_wdata)
       ,.wstrb_o(s00_axi_wstrb)
       ,.wvalid_o(s00_axi_wvalid)
       ,.wready_i(s00_axi_wready)
       ,.bresp_i(s00_axi_bresp)
       ,.bvalid_i(s00_axi_bvalid)
       ,.bready_o(s00_axi_bready)

       ,.araddr_o(s00_axi_araddr)
       ,.arprot_o(s00_axi_arprot)
       ,.arvalid_o(s00_axi_arvalid)
       ,.arready_i(s00_axi_arready)
       ,.rdata_i(s00_axi_rdata)
       ,.rresp_i(s00_axi_rresp)
       ,.rvalid_i(s00_axi_rvalid)
       ,.rready_o(s00_axi_rready)
       );
    assign clk250_i = s00_axi_aclk;
`endif

   localparam num_regs_ps_to_pl_lp = 4;
   localparam num_fifo_ps_to_pl_lp = 4 + 6;
   localparam num_fifo_pl_to_ps_lp = 2;
   localparam num_regs_pl_to_ps_lp = 1 + 9;

   wire [num_fifo_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] pl_to_ps_fifo_data_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_v_li;
   wire [num_fifo_pl_to_ps_lp-1:0]                           pl_to_ps_fifo_ready_lo;

   wire [num_fifo_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] ps_to_pl_fifo_data_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_v_lo;
   wire [num_fifo_ps_to_pl_lp-1:0]                           ps_to_pl_fifo_yumi_li;

   wire [num_regs_ps_to_pl_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_lo;
   wire [num_regs_pl_to_ps_lp-1:0][C_S00_AXI_DATA_WIDTH-1:0] csr_data_li;

   bsg_zynq_pl_shell
     #(
       .num_regs_ps_to_pl_p (num_regs_ps_to_pl_lp)
       ,.num_fifo_ps_to_pl_p(num_fifo_ps_to_pl_lp)
       ,.num_fifo_pl_to_ps_p(num_fifo_pl_to_ps_lp)
       ,.num_regs_pl_to_ps_p(num_regs_pl_to_ps_lp)
       ,.C_S_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH)
       ,.C_S_AXI_ADDR_WIDTH (C_S00_AXI_ADDR_WIDTH)
       ) bzps
       (
        .pl_to_ps_fifo_data_i  (pl_to_ps_fifo_data_li) // to user program
        ,.pl_to_ps_fifo_v_i    (pl_to_ps_fifo_v_li)
        ,.pl_to_ps_fifo_ready_o(pl_to_ps_fifo_ready_lo)

        ,.ps_to_pl_fifo_data_o (ps_to_pl_fifo_data_lo) // from user program
        ,.ps_to_pl_fifo_v_o    (ps_to_pl_fifo_v_lo)
        ,.ps_to_pl_fifo_yumi_i (ps_to_pl_fifo_yumi_li)

        ,.csr_data_o(csr_data_lo)
        ,.csr_data_i(csr_data_li) // 
        ,.S_AXI_ACLK   (s00_axi_aclk   )
        ,.S_AXI_ARESETN(s00_axi_aresetn)
        ,.S_AXI_AWADDR (s00_axi_awaddr )
        ,.S_AXI_AWPROT (s00_axi_awprot )
        ,.S_AXI_AWVALID(s00_axi_awvalid)
        ,.S_AXI_AWREADY(s00_axi_awready)
        ,.S_AXI_WDATA  (s00_axi_wdata  )
        ,.S_AXI_WSTRB  (s00_axi_wstrb  )
        ,.S_AXI_WVALID (s00_axi_wvalid )
        ,.S_AXI_WREADY (s00_axi_wready )
        ,.S_AXI_BRESP  (s00_axi_bresp  )
        ,.S_AXI_BVALID (s00_axi_bvalid )
        ,.S_AXI_BREADY (s00_axi_bready )
        ,.S_AXI_ARADDR (s00_axi_araddr )
        ,.S_AXI_ARPROT (s00_axi_arprot )
        ,.S_AXI_ARVALID(s00_axi_arvalid)
        ,.S_AXI_ARREADY(s00_axi_arready)
        ,.S_AXI_RDATA  (s00_axi_rdata  )
        ,.S_AXI_RRESP  (s00_axi_rresp  )
        ,.S_AXI_RVALID (s00_axi_rvalid )
        ,.S_AXI_RREADY (s00_axi_rready )
        );


   //--------------------------------------------------------------------------------
   // USER MODIFY -- Configure your accelerator interface by wiring these signals to
   //                your accelerator.
   //--------------------------------------------------------------------------------
   //
   // BEGIN logic is replaced with connections to the accelerator core
   // as a stand-in, we loopback the ps to pl fifos to the pl to ps fifos,
   // adding the outputs of a pair of ps to pl fifos to generate the value
   // inserted into a pl to ps fifo.



   for (genvar k = 0; k < num_fifo_pl_to_ps_lp; k++)
     begin: rof4
        assign pl_to_ps_fifo_data_li [k] = ps_to_pl_fifo_data_lo[k*2] + ps_to_pl_fifo_data_lo [k*2+1];
        assign pl_to_ps_fifo_v_li    [k] = ps_to_pl_fifo_v_lo   [k*2] & ps_to_pl_fifo_v_lo    [k*2+1];

        assign ps_to_pl_fifo_yumi_li[k*2]   = pl_to_ps_fifo_v_li[k] & pl_to_ps_fifo_ready_lo[k];
        assign ps_to_pl_fifo_yumi_li[k*2+1] = pl_to_ps_fifo_v_li[k] & pl_to_ps_fifo_ready_lo[k];
     end

        // Add user logic here
        //

    parameter  buf_size_p     = 2048; // byte
    parameter  send_width_p   = 8; // byte
    parameter  recv_width_p   = 8; // byte
    parameter  gap_delay_p    = 12; // clock cycle
    localparam packet_size_width_lp = $clog2(buf_size_p) + 1;
    localparam addr_width_lp = $clog2(buf_size_p / send_width_p);

    logic        reset_li;
    logic        reset_clk250_li;

    logic [1:0]       send_li;
    logic [1:0]       tx_ready_lo;
    logic [1:0]       clear_buffer_li;
    logic [1:0]       rx_ready_lo;

    logic [1:0]                             tx_packet_size_v_li;
    logic [1:0]                             tx_packet_size_v_r;
    logic [1:0][packet_size_width_lp - 1:0] tx_packet_size_li;

    logic [1:0][addr_width_lp - 1:0]        buffer_write_addr_li;

    logic [1:0][send_width_p * 8 -1:0]      buffer_write_data_li;
    logic [1:0]                             buffer_write_data_v_li;
    logic [1:0]                             buffer_write_data_v_r;

    logic [1:0][addr_width_lp - 1:0]        buffer_read_addr_li;
    logic [1:0][recv_width_p * 8 - 1:0]     buffer_read_data_lo;
    logic [1:0][15:0]                       rx_packet_size_lo;


    logic [1:0]       rgmii_rx_clk_li;
    logic [1:0][3:0]  rgmii_rxd_li;
    logic [1:0]       rgmii_rx_ctl_li;
    logic [1:0]       rgmii_tx_clk_lo;
    logic [1:0][3:0]  rgmii_txd_lo;
    logic [1:0]       rgmii_tx_ctl_lo;

    logic [1:0][1:0]  speed_lo;

    logic [3:0] tx_status_lo;
    logic [4:0] rx_status_lo;
    logic [1:0] reset_clk250_late_lo;

    logic [3:0] reset_clk250_sync_reg;

    always @(posedge clk250_i or negedge s00_axi_aresetn) begin
        if(~s00_axi_aresetn)
            reset_clk250_sync_reg <= 4'h0;
        else
            reset_clk250_sync_reg <= {1'b1, reset_clk250_sync_reg[3:1]};
    end

    assign reset_li = ~s00_axi_aresetn;
    assign reset_clk250_li = ~reset_clk250_sync_reg[0];

    ethernet_wrapper # (
        .buf_size_p(buf_size_p)
       ,.send_width_p(send_width_p)
       ,.gap_delay_p(gap_delay_p)
    ) eth0 (
       .clk_i(s00_axi_aclk)
      ,.reset_i(reset_li)
      ,.clk250_i(clk250_i)
      ,.reset_clk250_i(reset_clk250_li)
      ,.reset_clk250_late_o(reset_clk250_late_lo[0])

      ,.send_i(send_li[0]) //
      ,.tx_ready_o(tx_ready_lo[0]) //$$
      ,.clear_buffer_i(1'b1)
      ,.rx_ready_o(/* UNUSED */)

      ,.tx_packet_size_v_i(tx_packet_size_v_li[0])
      ,.tx_packet_size_i(tx_packet_size_li[0]) //

      ,.buffer_write_addr_i(buffer_write_addr_li[0]) //

      ,.buffer_write_data_i(buffer_write_data_li[0]) //
      ,.buffer_write_data_v_i(buffer_write_data_v_li[0])

      ,.buffer_read_addr_i('0)
      ,.buffer_read_data_o(/* UNUSED */)
      ,.rx_packet_size_o(/* UNUSED */)

      ,.rgmii_rx_clk_i(rgmii_rx_clk_li[0])
      ,.rgmii_rxd_i(rgmii_rxd_li[0])
      ,.rgmii_rx_ctl_i(rgmii_rx_ctl_li[0])
      ,.rgmii_tx_clk_o(rgmii_tx_clk_lo[0])
      ,.rgmii_txd_o(rgmii_txd_lo[0])
      ,.rgmii_tx_ctl_o(rgmii_tx_ctl_lo[0])

      ,.tx_error_underflow_o(tx_status_lo[0])//$$
      ,.tx_fifo_overflow_o(tx_status_lo[1])
      ,.tx_fifo_bad_frame_o(tx_status_lo[2])
      ,.tx_fifo_good_frame_o(tx_status_lo[3])
      ,.rx_error_bad_frame_o(/* UNUSED */)
      ,.rx_error_bad_fcs_o(/* UNUSED */)
      ,.rx_fifo_overflow_o(/* UNUSED */)
      ,.rx_fifo_bad_frame_o(/* UNUSED */)
      ,.rx_fifo_good_frame_o(/* UNUSED */)

      ,.speed_o(speed_lo[0])//$$
    );

    ethernet_wrapper #(
        .buf_size_p(buf_size_p)
       ,.send_width_p(send_width_p)
       ,.gap_delay_p(gap_delay_p)
    ) eth1 (
       .clk_i(s00_axi_aclk)
      ,.reset_i(reset_li)
      ,.clk250_i(clk250_i)
      ,.reset_clk250_i(reset_clk250_li)
      ,.reset_clk250_late_o(reset_clk250_late_lo[1])

      ,.send_i(1'b0)
      ,.tx_ready_o(/* UNUSED */)
      ,.clear_buffer_i(clear_buffer_li[1]) //
      ,.rx_ready_o(rx_ready_lo[1])//$$

      ,.tx_packet_size_v_i(1'b0)
      ,.tx_packet_size_i('0)

      ,.buffer_write_addr_i('0)

      ,.buffer_write_data_i('0)
      ,.buffer_write_data_v_i(1'b0)

      ,.buffer_read_addr_i(buffer_read_addr_li[1]) //
      ,.buffer_read_data_o(buffer_read_data_lo[1])//$$
      ,.rx_packet_size_o(rx_packet_size_lo[1])//$$

      ,.rgmii_rx_clk_i(rgmii_rx_clk_li[1])
      ,.rgmii_rxd_i(rgmii_rxd_li[1])
      ,.rgmii_rx_ctl_i(rgmii_rx_ctl_li[1])
      ,.rgmii_tx_clk_o(rgmii_tx_clk_lo[1])
      ,.rgmii_txd_o(rgmii_txd_lo[1])
      ,.rgmii_tx_ctl_o(rgmii_tx_ctl_lo[1])

      ,.tx_error_underflow_o(/* UNUSED */)
      ,.tx_fifo_overflow_o(/* UNUSED */)
      ,.tx_fifo_bad_frame_o(/* UNUSED */)
      ,.tx_fifo_good_frame_o(/* UNUSED */)
      ,.rx_error_bad_frame_o(rx_status_lo[0])//$$
      ,.rx_error_bad_fcs_o(rx_status_lo[1])
      ,.rx_fifo_overflow_o(rx_status_lo[2])
      ,.rx_fifo_bad_frame_o(rx_status_lo[3])
      ,.rx_fifo_good_frame_o(rx_status_lo[4])

      ,.speed_o(speed_lo[1])//$$
    );

    assign rgmii_rx_clk_li[1] = rgmii_tx_clk_lo[0];
    assign rgmii_rxd_li[1]    = rgmii_txd_lo[0];
    assign rgmii_rx_ctl_li[1] = rgmii_tx_ctl_lo[0];

    assign rgmii_rx_clk_li[0] = rgmii_tx_clk_lo[1];
    assign rgmii_rxd_li[0]    = rgmii_txd_lo[1];
    assign rgmii_rx_ctl_li[0] = rgmii_tx_ctl_lo[1];



    assign ps_to_pl_fifo_yumi_li[9:4] = ps_to_pl_fifo_v_lo[9:4];
    always_ff @(posedge s00_axi_aclk) begin
        if(reset_li) begin
            send_li[0]              <= 1'b0;
            clear_buffer_li[1]      <= 1'b1;
            tx_packet_size_li[0]    <= buf_size_p;
            buffer_write_addr_li[0] <= '0;
            buffer_write_data_li[0] <= '0;
            buffer_read_addr_li[1]  <= '0;
            tx_packet_size_v_r[0]   <= 1'b0;
            buffer_write_data_v_r[0] = 1'b0;
        end
        else begin
            if(ps_to_pl_fifo_v_lo[4] & ps_to_pl_fifo_yumi_li[4])
                send_li[0]              <= ps_to_pl_fifo_data_lo[4][0];

            if(ps_to_pl_fifo_v_lo[5] & ps_to_pl_fifo_yumi_li[5])
                clear_buffer_li[1]      <= ps_to_pl_fifo_data_lo[5][0];

            if(ps_to_pl_fifo_v_lo[6] & ps_to_pl_fifo_yumi_li[6]) begin
                tx_packet_size_li[0]    <= ps_to_pl_fifo_data_lo[6][packet_size_width_lp - 1 :0];
                tx_packet_size_v_r[0]   <= ps_to_pl_fifo_yumi_li[6];
            end

            if(ps_to_pl_fifo_v_lo[7] & ps_to_pl_fifo_yumi_li[7])
                buffer_write_addr_li[0] <= ps_to_pl_fifo_data_lo[7][addr_width_lp - 1:0];

            if(ps_to_pl_fifo_v_lo[8] & ps_to_pl_fifo_yumi_li[8]) begin
                buffer_write_data_li[0] <= {32'b0, ps_to_pl_fifo_data_lo[8][31:0]}; // For now, only lower 32 bits are working
                buffer_write_data_v_r[0] = ps_to_pl_fifo_yumi_li[8];
            end

            if(ps_to_pl_fifo_v_lo[9] & ps_to_pl_fifo_yumi_li[9])
                buffer_read_addr_li[1]  <= ps_to_pl_fifo_data_lo[9][addr_width_lp - 1:0];
        end
    end

    assign tx_packet_size_v_li[0]    = tx_packet_size_v_r[0];
    assign buffer_write_data_v_li[0] = buffer_write_data_v_r[0];


        logic [C_S00_AXI_ADDR_WIDTH-1:0] last_write_addr_r;

        always @(posedge s00_axi_aclk)
          if (~s00_axi_aresetn)
            last_write_addr_r <= '0;
          else
            if (s00_axi_awvalid & s00_axi_awready)
              last_write_addr_r <= s00_axi_awaddr;
        assign csr_data_li[0] = last_write_addr_r;

        assign csr_data_li[1] = tx_ready_lo[0];
        assign csr_data_li[2] = tx_status_lo;
        assign csr_data_li[3] = speed_lo[0];
        assign csr_data_li[4] = rx_ready_lo[1];
        assign csr_data_li[5] = buffer_read_data_lo[1][31:0];
        assign csr_data_li[6] = rx_packet_size_lo[1];
        assign csr_data_li[7] = rx_status_lo;
        assign csr_data_li[8] = speed_lo[1];
        assign csr_data_li[9] = |reset_clk250_late_lo;
        // User logic ends

`ifdef VERILATOR
   initial
     begin
//       if ($test$plusargs("bsg_trace") != 0)
//         begin
//           $display("[%0t] Tracing to trace.fst...\n", $time);
//           $dumpfile("trace.fst");
//           $dumpvars();
//         end
     end
`elsif VCS
   import "DPI-C" context task cosim_main(string c_args);
   string c_args;
   initial
     begin
       if ($test$plusargs("bsg_trace") != 0)
         begin
           $display("[%0t] Tracing to vcdplus.vpd...\n", $time);
           $dumpfile("vcdplus.vpd");
           $dumpvars();
         end
       if ($test$plusargs("c_args") != 0)
         begin
           $value$plusargs("c_args=%s", c_args);
         end
       cosim_main(c_args);
     end

   // Evaluate the simulation, until the next clk_i positive edge.
   //
   // Call bsg_dpi_next in simulators where the C testbench does not
   // control the progression of time (i.e. NOT Verilator).
   //
   // The #1 statement guarantees that the positive edge has been
   // evaluated, which is necessary for ordering in all of the DPI
   // functions.
   export "DPI-C" task bsg_dpi_next;
   task bsg_dpi_next();
     @(posedge s00_axi_aclk);
     #1;
   endtask
`endif

 endmodule
