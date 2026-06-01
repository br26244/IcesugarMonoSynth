`default_nettype none
`timescale 1ns/1ps

module rotarySet (
    input wire clk,
    input wire sampleTick,
    input wire encSw,
    input wire encDt,
    input wire encClk,
    output reg stepUp,
    output reg stepDown,
    output reg pressed
);

    reg [2:0] clkSync;
    reg [2:0] dtSync;
    reg [2:0] swSync;
    reg clkFiltered;
    reg swFiltered;

    always @(posedge clk) begin
        stepUp <= 1'b0;
        stepDown <= 1'b0;
        pressed <= 1'b0;

        clkSync <= {clkSync[1:0], encClk};
        dtSync <= {dtSync[1:0], encDt};
        swSync <= {swSync[1:0], encSw};

        if (sampleTick) begin
            if (clkFiltered && !clkSync[2]) begin
                if (dtSync[2]) begin
                    stepUp <= 1'b1;
                end else begin
                    stepDown <= 1'b1;
                end
            end

            if (swFiltered && !swSync[2]) begin
                pressed <= 1'b1;
            end

            clkFiltered <= clkSync[2];
            swFiltered <= swSync[2];
        end
    end

    initial begin
        stepUp = 1'b0;
        stepDown = 1'b0;
        pressed = 1'b0;
        clkSync = 3'b111;
        dtSync = 3'b111;
        swSync = 3'b111;
        clkFiltered = 1'b1;
        swFiltered = 1'b1;
    end

endmodule
