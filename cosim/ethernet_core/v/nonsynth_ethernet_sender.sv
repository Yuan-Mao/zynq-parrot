
`include "bsg_defines.v"

module nonsynth_ethernet_sender #
(
      parameter  buf_size_p     = 2048 // byte
    , parameter  send_width_p   = 8 // byte
    , parameter  gap_delay_p    = 24 // clock cycle
    , localparam ifg_delay_width_lp = `BSG_SAFE_CLOG2(gap_delay_p)
    , localparam packet_size_width_lp = $clog2(buf_size_p) + 1
    , localparam addr_width_lp = $clog2(buf_size_p / send_width_p)
)
(
      input  logic                              clk_i
    , input  logic                              reset_i
    , input  logic                              send_i // valid_i
    , output logic                              ready_o

    , input  logic                              packet_size_v_i
    , input  logic [packet_size_width_lp - 1:0] packet_size_i

    , input  logic [addr_width_lp - 1:0]        buffer_write_addr_i

    , input  logic [send_width_p * 8 -1:0]      buffer_write_data_i
    , input  logic                              buffer_write_data_v_i

    , output logic [send_width_p * 8- 1:0]      tx_axis_tdata_o
    , output logic [send_width_p - 1:0]         tx_axis_tkeep_o
    , output logic                              tx_axis_tvalid_o
    , output logic                              tx_axis_tlast_o
    , input  logic                              tx_axis_tready_i
    , output logic                              tx_axis_tuser_o
);
    localparam send_ptr_width_lp = `BSG_SAFE_CLOG2(buf_size_p / send_width_p);
    localparam send_ptr_offset_width_lp = `BSG_SAFE_CLOG2(send_width_p);

    logic [buf_size_p / send_width_p - 1:0][send_width_p * 8 - 1:0] buffer_r;

    logic [send_ptr_width_lp - 1:0] send_ptr_r;
    logic [packet_size_width_lp - 1:0] packet_size_r;

    logic [send_ptr_width_lp - 1:0] send_ptr_end;
    logic [send_ptr_offset_width_lp - 1 :0] send_remaining;
    logic last_send_f;

    typedef enum logic [1:0] {
        GAP,
        IDLE,
        SEND
    } state_e;

    state_e state_r, state_n;
    logic   packet_size_ready_lo;
    logic   buffer_write_data_ready_lo;
    logic [ifg_delay_width_lp-1:0] ifg_counter_r, ifg_counter_n;

    assign ready_o = (state_r == IDLE);
    assign packet_size_ready_lo = ready_o;
    assign buffer_write_data_ready_lo = ready_o;

    assign send_ptr_end = (packet_size_r - 1) >> $clog2(send_width_p);
    assign send_remaining = packet_size_r[`BSG_SAFE_CLOG2(send_width_p) - 1:0];
    assign last_send_f = (send_ptr_r == send_ptr_end);

    assign tx_axis_tdata_o = buffer_r[send_ptr_r];
    assign tx_axis_tvalid_o = (state_r == SEND);
    assign tx_axis_tlast_o = last_send_f;
    assign tx_axis_tuser_o = 1'b0;

    always_ff @(posedge clk_i) begin
        assert(send_width_p == 8) else $error("sender now only supports width == 8");
    end

    always_comb begin
        if(!last_send_f)
            tx_axis_tkeep_o = '1;
        else
            case(send_remaining)
                3'd0:
                    tx_axis_tkeep_o = 8'b1111_1111;
                3'd1:
                    tx_axis_tkeep_o = 8'b0000_0001;
                3'd2:
                    tx_axis_tkeep_o = 8'b0000_0011;
                3'd3:
                    tx_axis_tkeep_o = 8'b0000_0111;
                3'd4:
                    tx_axis_tkeep_o = 8'b0000_1111;
                3'd5:
                    tx_axis_tkeep_o = 8'b0001_1111;
                3'd6:
                    tx_axis_tkeep_o = 8'b0011_1111;
                3'd7:
                    tx_axis_tkeep_o = 8'b0111_1111;
                default:
                    tx_axis_tkeep_o = 'x;
            endcase
    end

    always_ff @(posedge clk_i) begin
        if(reset_i)
            ifg_counter_r <= '0;
        else
            ifg_counter_r <= ifg_counter_n;
    end

    always_ff @(posedge clk_i) begin
        if(reset_i)
            state_r <= IDLE;
        else
            state_r <= state_n;
    end


    always_comb begin
        state_n = state_r;
        ifg_counter_n = ifg_counter_r;
        case(state_r)
            IDLE: begin
                if(send_i) begin
                    state_n = SEND;
                end
            end
            SEND: begin
                if(last_send_f && tx_axis_tready_i) begin
                    ifg_counter_n = gap_delay_p - 1;
                    state_n = GAP;
                end
            end
            GAP: begin
                if(ifg_counter_r != '0)
                    ifg_counter_n = ifg_counter_r - ifg_delay_width_lp'(1'b1);
                else
                    state_n = IDLE;
            end

        endcase
    end

    always_ff @(posedge clk_i) begin
        if(reset_i) begin
            send_ptr_r <= '0;
        end
        else begin
            case(state_r)
                IDLE: begin
                    send_ptr_r <= '0;
                end
                SEND:
                    if(tx_axis_tready_i)
                        send_ptr_r <= send_ptr_r + send_ptr_width_lp'(1'b1);
            endcase
        end
    end

    always_ff @(posedge clk_i) begin
        if(reset_i)
            packet_size_r <= buf_size_p;
        else begin
            if(packet_size_v_i & packet_size_ready_lo) begin
                packet_size_r <= packet_size_i;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if(buffer_write_data_v_i & buffer_write_data_ready_lo)
            buffer_r[buffer_write_addr_i] <= buffer_write_data_i;
    end


    initial begin
        if(gap_delay_p == 0) begin
            $error("ethernet_sender: gap_delay_p cannot be 0");
            $finish;
        end
    end
endmodule
