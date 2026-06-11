`default_nettype none
`timescale 1ns/1ps

module squareOscillator (
    input wire [31:0] phaseAccum,
    output wire squareHigh,
    output reg [7:0] rawSample,
    output reg signed [17:0] squareTarget
);

    localparam [7:0] SAMPLEHIGH = 8'hC0;
    localparam [7:0] SAMPLELOW = 8'h40;

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

endmodule
