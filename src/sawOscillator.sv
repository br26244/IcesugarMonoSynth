`default_nettype none
`timescale 1ns/1ps

module sawOscillator (
    input wire [31:0] phaseAccum,
    output wire [7:0] rawSample,
    output wire signed [17:0] sawTarget
);

    wire signed [8:0] centeredSample = $signed({1'b0, rawSample}) - 9'sd128;

    assign rawSample = phaseAccum[31:24];
    assign sawTarget = centeredSample <<< 8;

endmodule
