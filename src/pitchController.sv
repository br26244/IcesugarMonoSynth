`default_nettype none
`timescale 1ns/1ps

module pitchController #(
    parameter MINSTEP = 0,
    parameter MAXSTEP = 48,
    parameter RESETSTEP = 12
) (
    input wire clk,
    input wire selectSaw,
    input wire pitchPressed,
    input wire pitchStepUp,
    input wire pitchStepDown,
    output reg [5:0] squarePitchStep,
    output reg [5:0] sawPitchStep
);

    always @(posedge clk) begin
        if (pitchPressed) begin
            if (selectSaw) begin
                sawPitchStep <= RESETSTEP[5:0];
            end else begin
                squarePitchStep <= RESETSTEP[5:0];
            end
        end else if (pitchStepUp) begin
            if (selectSaw) begin
                if (sawPitchStep != MAXSTEP[5:0]) begin
                    sawPitchStep <= sawPitchStep + 1'b1;
                end
            end else if (squarePitchStep != MAXSTEP[5:0]) begin
                squarePitchStep <= squarePitchStep + 1'b1;
            end
        end else if (pitchStepDown) begin
            if (selectSaw) begin
                if (sawPitchStep != MINSTEP[5:0]) begin
                    sawPitchStep <= sawPitchStep - 1'b1;
                end
            end else if (squarePitchStep != MINSTEP[5:0]) begin
                squarePitchStep <= squarePitchStep - 1'b1;
            end
        end
    end

    initial begin
        squarePitchStep = RESETSTEP[5:0];
        sawPitchStep    = RESETSTEP[5:0];
    end

endmodule
