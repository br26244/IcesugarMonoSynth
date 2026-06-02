`default_nettype none
`timescale 1ns/1ps

module squareOscillator (
    input wire clk,
    input wire sampleTick,
    input wire [31:0] phaseInc,
    output wire squareHigh,
    output reg [7:0] rawSample,
    output reg signed [17:0] squareTarget
);

    localparam [7:0] SAMPLEHIGH = 8'hC0;
    localparam [7:0] SAMPLELOW = 8'h40;

    reg [31:0] phaseAccum;

    assign squareHigh = phaseAccum[31];

    always @* begin
        if (squareHigh) begin
            rawSample = SAMPLEHIGH;
            squareTarget = 18'sd16_384;
        end else begin
            rawSample = SAMPLELOW;
            squareTarget = -18'sd16_384;
        end
    end

    always @(posedge clk) begin
        if (sampleTick) begin
            phaseAccum <= phaseAccum + phaseInc;
        end
    end

    initial begin
        phaseAccum = 32'd0;
    end

endmodule
