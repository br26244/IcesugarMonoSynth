`default_nettype none
`timescale 1ns/1ps

module spiByte #(
    parameter integer HALFPERIOD = 25
) (
    input wire clk,
    input wire start,
    input wire [7:0] data,
    output reg busy,
    output reg sck,
    output reg mosi,
    output reg csn
);

    reg [7:0] shift;
    reg [2:0] bitIndex;
    reg [5:0] divCount;

    always @(posedge clk) begin
        if (start && !busy) begin
            busy <= 1'b1;
            csn  <= 1'b0;
            sck  <= 1'b0;
            shift <= data;
            mosi  <= data[7];
            bitIndex <= 3'd0;
            divCount <= 6'd0;
        end else if (busy) begin
            if (divCount == HALFPERIOD - 1) begin
                divCount <= 6'd0;
                sck <= ~sck;

                if (sck) begin
                    if (bitIndex == 3'd7) begin
                        busy <= 1'b0;
                        csn <= 1'b1;
                        sck <= 1'b0;
                        mosi <= 1'b0;
                    end else begin
                        bitIndex <= bitIndex + 1'b1;
                        shift <= {shift[6:0], 1'b0};
                        mosi <= shift[6];
                    end
                end
            end else begin
                divCount <= divCount + 1'b1;
            end
        end
    end

    initial begin
        busy = 1'b0;
        sck = 1'b0;
        mosi = 1'b0;
        csn = 1'b1;
        shift = 8'd0;
        bitIndex = 3'd0;
        divCount = 6'd0;
    end

endmodule
