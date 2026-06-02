`default_nettype none
`timescale 1ns/1ps

module onePoleLowpass (
    input  wire clk,
    input  wire sampleTick,
    input  wire [3:0] filterStep,
    input  wire [7:0] rawSample,
    input  wire signed [17:0] target,
    output reg [7:0] outputSample
);

    reg signed [17:0] filterState;

    wire signed [17:0] filterDelta = target - filterState;
    wire signed [17:0] filterNext =
        filterState + (filterDelta >>> filterShiftForStep(filterStep));
    wire [7:0] filteredSample = filterNext[15:8] + 8'd128;

    always @* begin
        if (filterStep == 4'd0) begin
            outputSample = rawSample;
        end else begin
            outputSample = filteredSample;
        end
    end

    function automatic [3:0] filterShiftForStep(input [3:0] step);
        begin
            case (step)
                4'd0: filterShiftForStep = 4'd0;
                4'd1: filterShiftForStep = 4'd1;
                4'd2: filterShiftForStep = 4'd2;
                4'd3: filterShiftForStep = 4'd3;
                4'd4: filterShiftForStep = 4'd4;
                4'd5: filterShiftForStep = 4'd5;
                4'd6: filterShiftForStep = 4'd6;
                4'd7: filterShiftForStep = 4'd7;
                4'd8: filterShiftForStep = 4'd8;
                4'd9: filterShiftForStep = 4'd9;
                4'd10: filterShiftForStep = 4'd10;
                4'd11: filterShiftForStep = 4'd11;
                4'd12: filterShiftForStep = 4'd12;
                4'd13: filterShiftForStep = 4'd13;
                4'd14: filterShiftForStep = 4'd14;
                default: filterShiftForStep = 4'd15;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (sampleTick) begin
            if (filterStep == 4'd0) begin
                filterState <= target;
            end else begin
                filterState <= filterNext;
            end
        end
    end

    initial begin
        filterState = 18'sd0;
    end

endmodule
