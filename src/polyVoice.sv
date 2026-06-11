`default_nettype none
`timescale 1ns/1ps

module polyVoice (
    input wire clk,
    input wire sampleTick,
    input wire keyOn,
    input wire squareOn,
    input wire sawOn,
    input wire [5:0] noteStep,
    input wire [3:0] attackStep,
    input wire [3:0] decayStep,
    input wire [3:0] sustainStep,
    input wire [3:0] releaseStep,
    output wire voiceActive,
    output wire signed [17:0] voiceTarget
);

    wire [31:0] phaseInc;
    wire [31:0] phaseAccum;
    wire [7:0] squareSample;
    wire [7:0] sawSample;
    wire [7:0] mixedSample;
    wire [7:0] envelopeSample;
    wire signed [17:0] squareTarget;
    wire signed [17:0] sawTarget;
    wire signed [17:0] mixedTarget;

    pitchLookup pitchTable (
        .pitchStep(noteStep),
        .phaseInc(phaseInc)
    );

    phaseAccumulator phase (
        .clk(clk),
        .sampleTick(sampleTick),
        .phaseInc(phaseInc),
        .phaseAccum(phaseAccum)
    );

    squareOscillator squareOsc (
        .phaseAccum(phaseAccum),
        .squareHigh(),
        .rawSample(squareSample),
        .squareTarget(squareTarget)
    );

    sawOscillator sawOsc (
        .phaseAccum(phaseAccum),
        .rawSample(sawSample),
        .sawTarget(sawTarget)
    );

    audioMixer voiceMixer (
        .squareOn(squareOn),
        .sawOn(sawOn),
        .squareSample(squareSample),
        .sawSample(sawSample),
        .squareTarget(squareTarget),
        .sawTarget(sawTarget),
        .mixedSample(mixedSample),
        .mixedTarget(mixedTarget)
    );

    adsrEnvelope envelope (
        .clk(clk),
        .sampleTick(sampleTick),
        .gate(keyOn),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .rawSample(mixedSample),
        .outputSample(envelopeSample),
        .outputTarget(voiceTarget),
        .active(voiceActive)
    );

endmodule
