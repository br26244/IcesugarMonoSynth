`default_nettype none
`timescale 1ns/1ps

module sawOscillator (
    input wire clk,
    input wire sampleTick,
    input wire [31:0] phaseInc,
    output wire [7:0] rawSample,
    output wire signed [17:0] sawTarget
);

    reg [31:0] phaseAccum;

    wire signed [8:0] centeredSample = $signed({1'b0, rawSample}) - 9'sd128;

    assign rawSample = phaseAccum[31:24];
    assign sawTarget = centeredSample <<< 8;

    always @(posedge clk) begin
        if (sampleTick) begin
            phaseAccum <= phaseAccum + phaseInc;
        end
    end

    initial begin
        phaseAccum = 32'd0;
    end

endmodule
