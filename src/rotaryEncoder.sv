`default_nettype none
`timescale 1ns/1ps

module rotaryEncoder #(
    parameter integer WIDTH = 4,
    parameter integer MINVALUE = 0,
    parameter integer MAXVALUE = 15, 
    parameter integer RESETVALUE = 0
) (
    input wire clk,
    input wire sampleTick,
    input wire encSw,
    input wire encDt,
    input wire encClk,
    output reg [WIDTH-1:0] value
);

    reg [2:0] clkSync;
    reg [2:0] dtSync;
    reg [2:0] swSync;
    reg clkFiltered;
    reg swFiltered;

    always @(posedge clk) begin
        clkSync <= {clkSync[1:0], encClk};
        dtSync <= {dtSync[1:0], encDt};
        swSync <= {swSync[1:0], encSw};

        if (sampleTick) begin
            if (clkFiltered && !clkSync[2]) begin
                if (dtSync[2]) begin
                    if (value != MAXVALUE[WIDTH-1:0]) begin
                        value <= value + 1'b1;
                    end
                end else if (value != MINVALUE[WIDTH-1:0]) begin
                    value <= value - 1'b1;
                end
            end

            if (swFiltered && !swSync[2]) begin
                value <= RESETVALUE[WIDTH-1:0];
            end

            clkFiltered <= clkSync[2];
            swFiltered <= swSync[2];
        end
    end

    initial begin
        value = RESETVALUE[WIDTH-1:0];
        clkSync = 3'b111;
        dtSync = 3'b111;
        swSync = 3'b111;
        clkFiltered = 1'b1;
        swFiltered = 1'b1;
    end

endmodule
