`default_nettype none
`timescale 1ns/1ps

module adsrEnvelope (
    input wire clk,
    input wire sampleTick,
    input wire gate,
    input wire [3:0] attackStep,
    input wire [3:0] decayStep,
    input wire [3:0] sustainStep,
    input wire [3:0] releaseStep,
    input wire [7:0] rawSample,
    output reg [7:0] outputSample,
    output reg signed [17:0] outputTarget,
    output reg active
);

    localparam [2:0] STATEIDLE = 3'd0;
    localparam [2:0] STATEATTACK = 3'd1;
    localparam [2:0] STATEDECAY = 3'd2;
    localparam [2:0] STATESUSTAIN = 3'd3;
    localparam [2:0] STATERELEASE = 3'd4;

    reg [2:0] state;
    reg [15:0] envLevel;

    wire signed [8:0] centeredSample = $signed({1'b0, rawSample}) - 9'sd128;
    wire signed [17:0] centeredTarget = centeredSample <<< 8;
    wire signed [17:0] envelopeTarget = scaleByLevel(centeredTarget, envLevel[15:12]);
    wire [7:0] envelopeSample = envelopeTarget[15:8] + 8'd128;

    reg [15:0] sustainLevel;
    reg [15:0] attackAmount;
    reg [15:0] decayAmount;
    reg [15:0] releaseAmount;

    always @* begin
        sustainLevel = {sustainStep, sustainStep, sustainStep, sustainStep};
        attackAmount = rateForStep(attackStep);
        decayAmount = rateForStep(decayStep);
        releaseAmount = rateForStep(releaseStep);
        outputSample = envelopeSample;
        outputTarget = envelopeTarget;

        if (envLevel == 16'd0) begin
            active = 1'b0;
        end else begin
            active = 1'b1;
        end
    end

    function automatic [15:0] rateForStep(input [3:0] step);
        begin
            case (step)
                4'd0: rateForStep = 16'd65535;
                4'd1: rateForStep = 16'd4096;
                4'd2: rateForStep = 16'd3072;
                4'd3: rateForStep = 16'd2048;
                4'd4: rateForStep = 16'd1536;
                4'd5: rateForStep = 16'd1024;
                4'd6: rateForStep = 16'd768;
                4'd7: rateForStep = 16'd512;
                4'd8: rateForStep = 16'd384;
                4'd9: rateForStep = 16'd256;
                4'd10: rateForStep = 16'd192;
                4'd11: rateForStep = 16'd128;
                4'd12: rateForStep = 16'd96;
                4'd13: rateForStep = 16'd64;
                4'd14: rateForStep = 16'd48;
                default: rateForStep = 16'd32;
            endcase
        end
    endfunction

    function automatic signed [17:0] scaleByLevel(
        input signed [17:0] sample,
        input [3:0] level
    );
        begin
            case (level)
                4'd0: scaleByLevel = 18'sd0;
                4'd1: scaleByLevel = sample >>> 4;
                4'd2: scaleByLevel = sample >>> 3;
                4'd3: scaleByLevel = (sample >>> 3) + (sample >>> 4);
                4'd4: scaleByLevel = sample >>> 2;
                4'd5: scaleByLevel = (sample >>> 2) + (sample >>> 4);
                4'd6: scaleByLevel = (sample >>> 2) + (sample >>> 3);
                4'd7: scaleByLevel = (sample >>> 2) + (sample >>> 3) + (sample >>> 4);
                4'd8: scaleByLevel = sample >>> 1;
                4'd9: scaleByLevel = (sample >>> 1) + (sample >>> 4);
                4'd10: scaleByLevel = (sample >>> 1) + (sample >>> 3);
                4'd11: scaleByLevel = (sample >>> 1) + (sample >>> 3) + (sample >>> 4);
                4'd12: scaleByLevel = (sample >>> 1) + (sample >>> 2);
                4'd13: scaleByLevel = (sample >>> 1) + (sample >>> 2) + (sample >>> 4);
                4'd14: scaleByLevel = (sample >>> 1) + (sample >>> 2) + (sample >>> 3);
                default: scaleByLevel = sample;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (sampleTick) begin
            if (!gate) begin
                if (envLevel == 16'd0) begin
                    state <= STATEIDLE;
                end else begin
                    state <= STATERELEASE;
                end
            end else if (state == STATEIDLE || state == STATERELEASE) begin
                state <= STATEATTACK;
            end

            if (state == STATEIDLE) begin
                envLevel <= 16'd0;
            end else if (state == STATEATTACK) begin
                if (attackAmount >= 16'hFFFF - envLevel) begin
                    envLevel <= 16'hFFFF;
                    state <= STATEDECAY;
                end else begin
                    envLevel <= envLevel + attackAmount;
                end
            end else if (state == STATEDECAY) begin
                if (envLevel <= sustainLevel) begin
                    envLevel <= sustainLevel;
                    state <= STATESUSTAIN;
                end else if (decayAmount >= envLevel - sustainLevel) begin
                    envLevel <= sustainLevel;
                    state <= STATESUSTAIN;
                end else begin
                    envLevel <= envLevel - decayAmount;
                end
            end else if (state == STATESUSTAIN) begin
                envLevel <= sustainLevel;
            end else if (state == STATERELEASE) begin
                if (releaseAmount >= envLevel) begin
                    envLevel <= 16'd0;
                    state <= STATEIDLE;
                end else begin
                    envLevel <= envLevel - releaseAmount;
                end
            end else begin
                state <= STATEIDLE;
                envLevel <= 16'd0;
            end
        end
    end

    initial begin
        state = STATEIDLE;
        envLevel = 16'd0;
    end

endmodule
