`default_nettype none
`timescale 1ns/1ps

module phaseAccumulator (
    input wire clk,
    input wire sampleTick,
    input wire [31:0] phaseInc,
    output reg [31:0] phaseAccum
);

    always @(posedge clk) begin
        if (sampleTick) begin
            phaseAccum <= phaseAccum + phaseInc;
        end
    end

    initial begin
        phaseAccum = 32'd0;
    end

endmodule
