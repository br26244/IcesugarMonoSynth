`include "async_fifo.v"
`include "lcd_fb.v"
`include "lcd_timing.v"
`include "pll_clocks.v"
`include "sdram_controller.v"

module top (
    input  wire        clk_25m,
    output wire        sdram_clk,
    output wire        sdram_cke,
    output wire        sdram_cs_n,
    output wire        sdram_ras_n,
    output wire        sdram_cas_n,
    output wire        sdram_we_n,
    output wire [1:0]  sdram_ba,
    output wire [12:0] sdram_a,
    output wire [1:0]  sdram_dqm,
    inout  wire [15:0] sdram_dq,
    output wire        lcd_clk,
    output wire        lcd_hsync,
    output wire        lcd_vsync,
    output wire        lcd_de,
    output wire [7:0]  lcd_r,
    output wire [7:0]  lcd_g,
    output wire [7:0]  lcd_b,
    input wire         sclk,
    input wire         pico,
    input wire         cs_n,
    input wire         data_cmd
);

    wire locked;
    wire clk_100m;
    wire reset = ~locked;

    wire [4:0] r5;
    wire [5:0] g6;
    wire [4:0] b5;

    reg        wr_en   = 0;
    wire       wr_ack;
    reg [23:0] wr_addr = 0;
    reg [15:0] wr_data = 0;

    icesugar_pro_lcd_fb fb_inst (
        .clk_25m    (clk_25m),
        .sdram_clk  (sdram_clk),
        .sdram_cke  (sdram_cke),
        .sdram_cs_n (sdram_cs_n),
        .sdram_ras_n(sdram_ras_n),
        .sdram_cas_n(sdram_cas_n),
        .sdram_we_n (sdram_we_n),
        .sdram_ba   (sdram_ba),
        .sdram_a    (sdram_a),
        .sdram_dqm  (sdram_dqm),
        .sdram_dq   (sdram_dq),
        .lcd_clk    (lcd_clk),
        .lcd_hsync  (lcd_hsync),
        .lcd_vsync  (lcd_vsync),
        .lcd_de     (lcd_de),
        .lcd_r      (r5),
        .lcd_g      (g6),
        .lcd_b      (b5),
        .wr_en      (wr_en),
        .wr_addr    (wr_addr),
        .wr_data    (wr_data),
        .wr_ack     (wr_ack),
        .clk_100m   (clk_100m),
        .locked     (locked)
    );

    assign lcd_r = {r5, r5[4:2]};
    assign lcd_g = {g6, g6[5:4]};
    assign lcd_b = {b5, b5[4:2]};

    localparam [18:0] FB_SIZE = 19'd130560; /* 480 * 272 */

    // SPI sync
    reg [1:0] sck_sync, cs_sync;
    reg       mosi_sync;
    always @(posedge clk_100m) begin
        sck_sync  <= {sck_sync[0],  sclk};
        cs_sync   <= {cs_sync[0],   cs_n};
        mosi_sync <= pico;
    end
    wire sck_rising = (sck_sync == 2'b01);
    wire cs_active  = !cs_sync[1];

    // SPI byte receiver with one-byte handoff
    reg [7:0] spi_shift;
    reg [2:0] spi_bit;
    reg       spi_rdy;
    reg [7:0] spi_byte;

    reg       byte_valid;
    reg [7:0] byte_data;

    always @(posedge clk_100m) begin
        if (reset) begin
            spi_shift  <= 0;
            spi_bit    <= 3'd7;
            spi_rdy    <= 0;
            spi_byte   <= 0;
            byte_valid <= 0;
            byte_data  <= 0;
        end else begin
            spi_rdy <= 0;

            if (!cs_active) begin
                spi_bit    <= 3'd7;
                byte_valid <= 0;
            end else if (sck_rising) begin
                spi_shift <= {spi_shift[6:0], mosi_sync};
                if (spi_bit == 3'd0) begin
                    byte_data  <= {spi_shift[6:0], mosi_sync};
                    byte_valid <= 1;
                    spi_bit    <= 3'd7;
                end else
                    spi_bit <= spi_bit - 3'd1;
            end

            if (byte_valid && !spi_rdy) begin
                spi_byte   <= byte_data;
                spi_rdy    <= 1;
                byte_valid <= 0;
            end
        end
    end

    function [18:0] y_to_base;
        input [15:0] y;
        reg [18:0] r;
        begin
            r = {3'd0, y};
            y_to_base = (r<<8) + (r<<7) + (r<<6) + (r<<5);
        end
    endfunction

    localparam [3:0]
        S_IDLE   = 4'd0,
        S_FILL_C = 4'd1,
        S_FILL_E = 4'd2,
        S_FILL_W = 4'd3,
        S_PX_X   = 4'd4,
        S_PX_YL  = 4'd5,
        S_PX_YH  = 4'd6,
        S_PX_W   = 4'd7,
        S_PX_H   = 4'd8,
        S_PX_LO  = 4'd9,
        S_PX_HI  = 4'd10,
        S_PX_WR  = 4'd11;

    reg [3:0]  state;
    reg [15:0] fill_colour;
    reg [18:0] fill_addr;
    reg [7:0]  px_x0, px_w, px_h;
    reg [15:0] px_y0;
    reg [7:0]  px_y_lo;
    reg [7:0]  px_col, px_row;
    reg [7:0]  px_lo;
    reg [18:0] px_cur, px_base;
    reg [15:0] px_colour;

    always @(posedge clk_100m) begin
        if (reset) begin
            state       <= S_IDLE;
            wr_en       <= 0;
            wr_addr     <= 0;
            wr_data     <= 0;
            fill_addr   <= 0;
            fill_colour <= 0;
            px_cur      <= 0;
            px_base     <= 0;
            px_colour   <= 0;
        end else begin

            case (state)
                S_IDLE: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        if      (spi_byte == 8'hAA) state <= S_FILL_C;
                        else if (spi_byte == 8'hBB) state <= S_PX_X;
                    end
                end

                S_FILL_C: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        case (spi_byte)
                            8'h01: fill_colour <= 16'hF800;
                            8'h02: fill_colour <= 16'h07E0;
                            8'h03: fill_colour <= 16'h001F;
                            default: fill_colour <= 16'h0000;
                        endcase
                        state <= S_FILL_E;
                    end
                end
                S_FILL_E: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        if (spi_byte == 8'h55) begin
                            fill_addr <= 0; state <= S_FILL_W;
                        end else state <= S_IDLE;
                    end
                end
                S_FILL_W: begin
                    if (!wr_en) begin
                        wr_en   <= 1;
                        wr_addr <= {5'd0, fill_addr};
                        wr_data <= fill_colour;
                    end else if (wr_ack) begin
                        if (fill_addr == FB_SIZE-1) begin
                            wr_en <= 0; state <= S_IDLE;
                        end else begin
                            fill_addr <= fill_addr + 1'b1;
                            wr_addr   <= {5'd0, fill_addr + 1'b1};
                            wr_data   <= fill_colour;
                        end
                    end
                end

                S_PX_X: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        px_x0 <= spi_byte; px_col <= 0; state <= S_PX_YL;
                    end
                end
                S_PX_YL: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        px_y_lo <= spi_byte;
                        state   <= S_PX_YH;
                    end
                end
                S_PX_YH: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        px_y0   <= {spi_byte, px_y_lo};
                        px_row  <= 0;
                        px_base <= y_to_base({spi_byte, px_y_lo});
                        px_cur  <= y_to_base({spi_byte, px_y_lo}) + {11'd0, px_x0};
                        state   <= S_PX_W;
                    end
                end
                S_PX_W: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin px_w<=spi_byte; state<=S_PX_H; end
                end
                S_PX_H: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin px_h<=spi_byte; state<=S_PX_LO; end
                end
                S_PX_LO: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin px_lo<=spi_byte; state<=S_PX_HI; end
                end
                S_PX_HI: begin
                    if (wr_ack) wr_en <= 0;
                    if (spi_rdy) begin
                        px_colour <= {spi_byte, px_lo};
                        state     <= S_PX_WR;
                    end
                end
                S_PX_WR: begin
                    if (!wr_en) begin
                        wr_en   <= 1;
                        wr_addr <= {5'd0, px_cur};
                        wr_data <= px_colour;
                    end else if (wr_ack) begin
                        wr_en <= 0;
                        if (px_col == px_w - 8'd1) begin
                            px_col <= 0;
                            if (px_row == px_h - 8'd1)
                                state <= S_IDLE;
                            else begin
                                px_row  <= px_row + 8'd1;
                                px_base <= px_base + 19'd480;
                                px_cur  <= px_base + 19'd480 + {11'd0,px_x0};
                                state   <= S_PX_LO;
                            end
                        end else begin
                            px_col <= px_col + 8'd1;
                            px_cur <= px_cur + 1'b1;
                            state  <= S_PX_LO;
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
