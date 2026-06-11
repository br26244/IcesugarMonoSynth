`default_nettype none
`timescale 1ns/1ps

module onePoleHighpass (
    input wire clk,
    input wire sampleTick,
    input wire [3:0] filterStep,
    input wire [7:0] rawSample,
    output reg [7:0] outputSample
);

    reg signed [17:0] lowState;

    wire signed [8:0] centeredSample = $signed({1'b0, rawSample}) - 9'sd128;
    wire signed [17:0] centeredTarget = centeredSample <<< 8;
    wire signed [17:0] lowDelta = centeredTarget - lowState;
    wire signed [17:0] lowNext =
        lowState + (lowDelta >>> filterShiftForStep(filterStep));
    wire signed [17:0] highTarget = centeredTarget - lowNext;
    wire [7:0] highSample = highTarget[15:8] + 8'd128;

    always @* begin
        if (filterStep == 4'd0) begin
            outputSample = rawSample;
        end else begin
            outputSample = highSample;
        end
    end

    function automatic [3:0] filterShiftForStep(input [3:0] step);
        begin
            case (step)
                4'd0: filterShiftForStep = 4'd0;
                4'd1: filterShiftForStep = 4'd15;
                4'd2: filterShiftForStep = 4'd14;
                4'd3: filterShiftForStep = 4'd13;
                4'd4: filterShiftForStep = 4'd12;
                4'd5: filterShiftForStep = 4'd11;
                4'd6: filterShiftForStep = 4'd10;
                4'd7: filterShiftForStep = 4'd9;
                4'd8: filterShiftForStep = 4'd8;
                4'd9: filterShiftForStep = 4'd7;
                4'd10: filterShiftForStep = 4'd6;
                4'd11: filterShiftForStep = 4'd5;
                4'd12: filterShiftForStep = 4'd4;
                4'd13: filterShiftForStep = 4'd3;
                4'd14: filterShiftForStep = 4'd2;
                default: filterShiftForStep = 4'd1;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (sampleTick) begin
            if (filterStep == 4'd0) begin
                lowState <= centeredTarget;
            end else begin
                lowState <= lowNext;
            end
        end
    end

    initial begin
        lowState = 18'sd0;
    end

endmodule
