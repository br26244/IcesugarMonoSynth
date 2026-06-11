`default_nettype none
`timescale 1ns/1ps

module parameterPacket #(
    parameter integer STATUSDIV = 1024
) (
    input wire clk,
    input wire sampleTick,
    input wire spiBusy,
    input wire [7:0] audioSample,
    input wire [5:0] pitchStep,
    input wire [3:0] lowpassStep,
    input wire [3:0] highpassStep,
    input wire [3:0] attackStep,
    input wire [3:0] decayStep,
    input wire [3:0] sustainStep,
    input wire [3:0] releaseStep,
    input wire squareOn,
    input wire sawOn,
    output reg spiStart,
    output reg [7:0] spiData
);

    localparam [3:0] PACKETLAST = 4'd10;

    reg sendingPacket;
    reg [3:0] packetIndex;
    reg [15:0] statusCount;

    function automatic [7:0] packetByte(input [3:0] index);
        begin
            case (index)
                4'd0: packetByte = 8'hFF;
                4'd1: packetByte = 8'h55;
                4'd2: packetByte = 8'hAA;
                4'd3: packetByte = {2'b00, pitchStep};
                4'd4: packetByte = {4'b0000, lowpassStep};
                4'd5: packetByte = {4'b0000, highpassStep};
                4'd6: packetByte = {4'b0000, attackStep};
                4'd7: packetByte = {4'b0000, decayStep};
                4'd8: packetByte = {4'b0000, sustainStep};
                4'd9: packetByte = {4'b0000, releaseStep};
                default: packetByte = {6'b000000, sawOn, squareOn};
            endcase
        end
    endfunction

    always @(posedge clk) begin
        spiStart <= 1'b0;

        if (sampleTick && !spiBusy) begin
            spiStart <= 1'b1;

            if (sendingPacket) begin
                spiData <= packetByte(packetIndex);

                if (packetIndex == PACKETLAST) begin
                    sendingPacket <= 1'b0;
                    packetIndex <= 4'd0;
                    statusCount <= 16'd0;
                end else begin
                    packetIndex <= packetIndex + 1'b1;
                end
            end else if (statusCount == STATUSDIV - 1) begin
                sendingPacket <= 1'b1;
                packetIndex <= 4'd1;
                spiData <= packetByte(4'd0);
            end else begin
                statusCount <= statusCount + 1'b1;
                spiData <= audioSample;
            end
        end
    end

    initial begin
        sendingPacket = 1'b0;
        packetIndex = 4'd0;
        statusCount = 16'd0;
        spiStart = 1'b0;
        spiData = 8'd128;
    end

endmodule
