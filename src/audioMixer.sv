`default_nettype none
`timescale 1ns/1ps

module audioMixer (
    input wire squareOn,
    input wire sawOn,
    input wire [7:0] squareSample,
    input wire [7:0] sawSample,
    input wire signed [17:0] squareTarget,
    input wire signed [17:0] sawTarget,
    output reg [7:0] mixedSample,
    output reg signed [17:0] mixedTarget
);
    
    wire signed [9:0] squareCentered = $signed({1'b0, squareSample}) - 10'sd128;
    wire signed [9:0] sawCentered = $signed({1'b0, sawSample}) - 10'sd128;
    reg signed [10:0] centeredSum; 
    reg signed [10:0] centeredMix;
    reg signed [10:0] unsignedMixed;

    always @* begin
        centeredSum = 11'sd0;

        if (squareOn) begin
            centeredSum = centeredSum + squareCentered;
        end

        if (sawOn) begin
            centeredSum = centeredSum + sawCentered;
        end

        if (squareOn && sawOn) begin
            centeredMix = centeredSum >>> 1;
        end else begin
            centeredMix = centeredSum;
        end

        unsignedMixed = centeredMix + 11'sd128;
        mixedSample = unsignedMixed[7:0];

        if (squareOn && sawOn) begin
            mixedTarget = (squareTarget + sawTarget) >>> 1;
        end else if (squareOn) begin
            mixedTarget = squareTarget;
        end else if (sawOn) begin
            mixedTarget = sawTarget;
        end else begin
            mixedTarget = 18'sd0;
        end
    end

endmodule
