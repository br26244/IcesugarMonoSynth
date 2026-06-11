`default_nettype none
`timescale 1ns/1ps

module pitchController #(
    parameter MINSTEP = 0,
    parameter MAXSTEP = 48,
    parameter RESETSTEP = 12,
    parameter STEPSIZE = 1
) (
    input wire clk,
    input wire enable,
    input wire pitchPressed,
    input wire pitchStepUp,
    input wire pitchStepDown,
    output reg [5:0] pitchStep
);

    always @(posedge clk) begin
        if (enable) begin
            if (pitchPressed) begin
                pitchStep <= RESETSTEP[5:0];
            end else if (pitchStepUp) begin
                if (pitchStep + STEPSIZE[5:0] <= MAXSTEP[5:0]) begin
                    pitchStep <= pitchStep + STEPSIZE[5:0];
                end else begin
                    pitchStep <= MAXSTEP[5:0];
                end
            end else if (pitchStepDown) begin
                if (pitchStep >= MINSTEP[5:0] + STEPSIZE[5:0]) begin
                    pitchStep <= pitchStep - STEPSIZE[5:0];
                end else begin
                    pitchStep <= MINSTEP[5:0];
                end
            end
        end
    end

    initial begin
        pitchStep = RESETSTEP[5:0];
    end

endmodule
