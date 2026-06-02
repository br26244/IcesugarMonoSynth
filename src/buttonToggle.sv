`default_nettype none
`timescale 1ns/1ps

module buttonToggle #(
    parameter RESETON = 0
) (
    input wire clk,
    input wire sampleTick,
    input wire buttonN,
    output reg state
);

    reg [2:0] buttonSync;
    reg buttonFiltered;

    always @(posedge clk) begin
        buttonSync <= {buttonSync[1:0], buttonN};

        if (sampleTick) begin
            if (buttonFiltered && !buttonSync[2]) begin
                state <= ~state;
            end

            buttonFiltered <= buttonSync[2];
        end
    end

    initial begin
        state = RESETON[0];
        buttonSync = 3'b111;
        buttonFiltered = 1'b1;
    end

endmodule
