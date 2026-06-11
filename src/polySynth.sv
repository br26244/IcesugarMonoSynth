`default_nettype none
`timescale 1ns/1ps

module polySynth (
    input wire clk,
    input wire encoderTick,
    input wire sampleTick,
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
    input wire squareOn,
    input wire sawOn,
    input wire [5:0] octaveStep,
    input wire [3:0] attackStep,
    input wire [3:0] decayStep,
    input wire [3:0] sustainStep,
    input wire [3:0] releaseStep,
    output reg [7:0] mixedSample,
    output reg signed [17:0] mixedTarget
);

    wire [11:0] keyN;
    reg [11:0] keySyncA;
    reg [11:0] keySyncB;
    reg [11:0] keySyncC;
    reg [11:0] keyOn;
    reg [3:0] scanKey;

    reg voiceGate0;
    reg voiceGate1;
    reg voiceGate2;
    reg voiceGate3;
    reg voiceGate4;
    reg [3:0] voiceKey0;
    reg [3:0] voiceKey1;
    reg [3:0] voiceKey2;
    reg [3:0] voiceKey3;
    reg [3:0] voiceKey4;

    wire voiceActive0;
    wire voiceActive1;
    wire voiceActive2;
    wire voiceActive3;
    wire voiceActive4;
    wire signed [17:0] voiceTarget0;
    wire signed [17:0] voiceTarget1;
    wire signed [17:0] voiceTarget2;
    wire signed [17:0] voiceTarget3;
    wire signed [17:0] voiceTarget4;

    wire [5:0] noteStep0 = octaveStep + {2'b00, voiceKey0};
    wire [5:0] noteStep1 = octaveStep + {2'b00, voiceKey1};
    wire [5:0] noteStep2 = octaveStep + {2'b00, voiceKey2};
    wire [5:0] noteStep3 = octaveStep + {2'b00, voiceKey3};
    wire [5:0] noteStep4 = octaveStep + {2'b00, voiceKey4};

    wire keyAlreadyAssigned =
        (voiceGate0 && voiceKey0 == scanKey) ||
        (voiceGate1 && voiceKey1 == scanKey) ||
        (voiceGate2 && voiceKey2 == scanKey) ||
        (voiceGate3 && voiceKey3 == scanKey) ||
        (voiceGate4 && voiceKey4 == scanKey);

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

        if (scanKey == 4'd11) begin
            scanKey <= 4'd0;
        end else begin
            scanKey <= scanKey + 1'b1;
        end

        if (!keyOn[scanKey]) begin
            if (voiceGate0 && voiceKey0 == scanKey) begin
                voiceGate0 <= 1'b0;
            end
            if (voiceGate1 && voiceKey1 == scanKey) begin
                voiceGate1 <= 1'b0;
            end
            if (voiceGate2 && voiceKey2 == scanKey) begin
                voiceGate2 <= 1'b0;
            end
            if (voiceGate3 && voiceKey3 == scanKey) begin
                voiceGate3 <= 1'b0;
            end
            if (voiceGate4 && voiceKey4 == scanKey) begin
                voiceGate4 <= 1'b0;
            end
        end else if (!keyAlreadyAssigned) begin
            if (!voiceActive0) begin
                voiceGate0 <= 1'b1;
                voiceKey0 <= scanKey;
            end else if (!voiceActive1) begin
                voiceGate1 <= 1'b1;
                voiceKey1 <= scanKey;
            end else if (!voiceActive2) begin
                voiceGate2 <= 1'b1;
                voiceKey2 <= scanKey;
            end else if (!voiceActive3) begin
                voiceGate3 <= 1'b1;
                voiceKey3 <= scanKey;
            end else if (!voiceActive4) begin
                voiceGate4 <= 1'b1;
                voiceKey4 <= scanKey;
            end
        end
    end

    polyVoice voice0 (
        .clk(clk),
        .sampleTick(sampleTick),
        .keyOn(voiceGate0),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .noteStep(noteStep0),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .voiceActive(voiceActive0),
        .voiceTarget(voiceTarget0)
    );

    polyVoice voice1 (
        .clk(clk),
        .sampleTick(sampleTick),
        .keyOn(voiceGate1),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .noteStep(noteStep1),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .voiceActive(voiceActive1),
        .voiceTarget(voiceTarget1)
    );

    polyVoice voice2 (
        .clk(clk),
        .sampleTick(sampleTick),
        .keyOn(voiceGate2),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .noteStep(noteStep2),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .voiceActive(voiceActive2),
        .voiceTarget(voiceTarget2)
    );

    polyVoice voice3 (
        .clk(clk),
        .sampleTick(sampleTick),
        .keyOn(voiceGate3),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .noteStep(noteStep3),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .voiceActive(voiceActive3),
        .voiceTarget(voiceTarget3)
    );

    polyVoice voice4 (
        .clk(clk),
        .sampleTick(sampleTick),
        .keyOn(voiceGate4),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .noteStep(noteStep4),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .voiceActive(voiceActive4),
        .voiceTarget(voiceTarget4)
    );

    reg [2:0] activeCount;
    reg signed [21:0] voiceSum;
    reg signed [21:0] averageTarget;
    reg signed [21:0] unsignedTarget;

    always @(posedge clk) begin
        activeCount <= countActive5(
            voiceActive0,
            voiceActive1,
            voiceActive2,
            voiceActive3,
            voiceActive4
        );
        voiceSum <= sumActive5(
            voiceActive0, voiceTarget0,
            voiceActive1, voiceTarget1,
            voiceActive2, voiceTarget2,
            voiceActive3, voiceTarget3,
            voiceActive4, voiceTarget4
        );

        averageTarget <= scaleForActiveCount(voiceSum, activeCount);
        mixedTarget <= averageTarget[17:0];
        unsignedTarget <= averageTarget + 22'sd32768;
        mixedSample <= unsignedTarget[15:8];
    end

    function automatic [2:0] countActive5(
        input active0,
        input active1,
        input active2,
        input active3,
        input active4
    );
        begin
            countActive5 = 3'd0;

            if (active0) begin
                countActive5 = countActive5 + 1'b1;
            end
            if (active1) begin
                countActive5 = countActive5 + 1'b1;
            end
            if (active2) begin
                countActive5 = countActive5 + 1'b1;
            end
            if (active3) begin
                countActive5 = countActive5 + 1'b1;
            end
            if (active4) begin
                countActive5 = countActive5 + 1'b1;
            end
        end
    endfunction

    function automatic signed [21:0] sumActive5(
        input active0,
        input signed [17:0] target0,
        input active1,
        input signed [17:0] target1,
        input active2,
        input signed [17:0] target2,
        input active3,
        input signed [17:0] target3,
        input active4,
        input signed [17:0] target4
    );
        begin
            sumActive5 = 22'sd0;

            if (active0) begin
                sumActive5 = sumActive5 + target0;
            end
            if (active1) begin
                sumActive5 = sumActive5 + target1;
            end
            if (active2) begin
                sumActive5 = sumActive5 + target2;
            end
            if (active3) begin
                sumActive5 = sumActive5 + target3;
            end
            if (active4) begin
                sumActive5 = sumActive5 + target4;
            end
        end
    endfunction

    function automatic signed [21:0] scaleForActiveCount(
        input signed [21:0] sum,
        input [2:0] count
    );
        begin
            case (count)
                3'd0: scaleForActiveCount = 22'sd0;
                3'd1: scaleForActiveCount = sum;
                3'd2: scaleForActiveCount = sum >>> 1;
                3'd3: scaleForActiveCount = (sum >>> 2) + (sum >>> 4) + (sum >>> 6);
                3'd4: scaleForActiveCount = sum >>> 2;
                default: scaleForActiveCount = (sum >>> 3) + (sum >>> 4) + (sum >>> 7);
            endcase
        end
    endfunction

    initial begin
        keySyncA = 12'hFFF;
        keySyncB = 12'hFFF;
        keySyncC = 12'hFFF;
        keyOn = 12'd0;
        scanKey = 4'd0;
        voiceGate0 = 1'b0;
        voiceGate1 = 1'b0;
        voiceGate2 = 1'b0;
        voiceGate3 = 1'b0;
        voiceGate4 = 1'b0;
        voiceKey0 = 4'd0;
        voiceKey1 = 4'd0;
        voiceKey2 = 4'd0;
        voiceKey3 = 4'd0;
        voiceKey4 = 4'd0;
        activeCount = 3'd0;
        voiceSum = 22'sd0;
        averageTarget = 22'sd0;
        unsignedTarget = 22'sd32768;
        mixedTarget = 18'sd0;
        mixedSample = 8'd128;
    end

endmodule
