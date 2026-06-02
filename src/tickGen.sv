`default_nettype none
`timescale 1ns/1ps

module tickGen #(
    parameter SAMPLEDIV = 3125,
    parameter ENCODERDIV = 25000
) (
    input wire clk,
    output reg sampleTick,
    output reg encoderTick
);

    reg [31:0] sampleDivCount;
    reg [31:0] encoderDivCount;

    always @(posedge clk) begin
        if (sampleDivCount == SAMPLEDIV - 1) begin
            sampleDivCount <= 32'd0;
            sampleTick <= 1'b1;
        end else begin
            sampleDivCount <= sampleDivCount + 1'b1;
            sampleTick <= 1'b0;
        end

        if (encoderDivCount == ENCODERDIV - 1) begin
            encoderDivCount <= 32'd0;
            encoderTick <= 1'b1;
        end else begin
            encoderDivCount <= encoderDivCount + 1'b1;
            encoderTick <= 1'b0;
        end
    end

    initial begin
        sampleDivCount = 32'd0;
        encoderDivCount = 32'd0;
        sampleTick = 1'b0;
        encoderTick = 1'b0;
    end

endmodule
