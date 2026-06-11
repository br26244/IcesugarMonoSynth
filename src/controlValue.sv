`default_nettype none
`timescale 1ns/1ps

module controlValue #(
    parameter integer WIDTH = 4,
    parameter integer MINVALUE = 0,
    parameter integer MAXVALUE = 15,
    parameter integer RESETVALUE = 0
) (
    input wire clk,
    input wire enable,
    input wire pressed,
    input wire stepUp,
    input wire stepDown,
    output reg [WIDTH-1:0] value
);

    always @(posedge clk) begin
        if (enable) begin
            if (pressed) begin
                value <= RESETVALUE[WIDTH-1:0];
            end else if (stepUp) begin
                if (value != MAXVALUE[WIDTH-1:0]) begin
                    value <= value + 1'b1;
                end
            end else if (stepDown) begin
                if (value != MINVALUE[WIDTH-1:0]) begin
                    value <= value - 1'b1;
                end
            end
        end
    end

    initial begin
        value = RESETVALUE[WIDTH-1:0];
    end

endmodule
