`default_nettype none
`timescale 1ns/1ps

module monoKeyboard (
    input wire clk,
    input wire encoderTick,
    input wire keyC,
    input wire keyCs,
    input wire keyD,
    input wire keyDs,
    input wire keyE,
    input wire keyF,
    input wire keyFs,
    input wire keyG,
    input wire keyGs,
    input wire keyA,
    input wire keyAs,
    input wire keyB,
    input wire [5:0] octaveStep,
    output reg gate,
    output reg [5:0] noteStep
);

    reg [11:0] keySyncA;
    reg [11:0] keySyncB;
    reg [11:0] keySyncC;
    reg [11:0] keyOn;
    reg [3:0] selectedKey;
    wire [11:0] keyN;

    assign keyN = {
        keyB,
        keyAs,
        keyA,
        keyGs,
        keyG,
        keyFs,
        keyF,
        keyE,
        keyDs,
        keyD,
        keyCs,
        keyC
    };

    always @(posedge clk) begin
        keySyncA <= keyN;
        keySyncB <= keySyncA;
        keySyncC <= keySyncB;

        if (encoderTick) begin
            keyOn <= ~keySyncC;
        end
    end

    always @* begin
        gate = 1'b1;
        selectedKey = 4'd0;

        if (keyOn[0]) begin
            selectedKey = 4'd0;
        end else if (keyOn[1]) begin
            selectedKey = 4'd1;
        end else if (keyOn[2]) begin
            selectedKey = 4'd2;
        end else if (keyOn[3]) begin
            selectedKey = 4'd3;
        end else if (keyOn[4]) begin
            selectedKey = 4'd4;
        end else if (keyOn[5]) begin
            selectedKey = 4'd5;
        end else if (keyOn[6]) begin
            selectedKey = 4'd6;
        end else if (keyOn[7]) begin
            selectedKey = 4'd7;
        end else if (keyOn[8]) begin
            selectedKey = 4'd8;
        end else if (keyOn[9]) begin
            selectedKey = 4'd9;
        end else if (keyOn[10]) begin
            selectedKey = 4'd10;
        end else if (keyOn[11]) begin
            selectedKey = 4'd11;
        end else begin
            gate = 1'b0;
            selectedKey = 4'd0;
        end

        case (selectedKey)
            4'd0: noteStep = octaveStep;
            4'd1: noteStep = octaveStep + 6'd1;
            4'd2: noteStep = octaveStep + 6'd2;
            4'd3: noteStep = octaveStep + 6'd3;
            4'd4: noteStep = octaveStep + 6'd4;
            4'd5: noteStep = octaveStep + 6'd5;
            4'd6: noteStep = octaveStep + 6'd6;
            4'd7: noteStep = octaveStep + 6'd7;
            4'd8: noteStep = octaveStep + 6'd8;
            4'd9: noteStep = octaveStep + 6'd9;
            4'd10: noteStep = octaveStep + 6'd10;
            default: noteStep = octaveStep + 6'd11;
        endcase
    end

    initial begin
        keySyncA = 12'hFFF;
        keySyncB = 12'hFFF;
        keySyncC = 12'hFFF;
        keyOn = 12'd0;
    end

endmodule
