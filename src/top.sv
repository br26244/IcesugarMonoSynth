`default_nettype none
`timescale 1ns/1ps

module top (
    input wire clk,
    input wire encSw,
    input wire encDt,
    input wire encClk,
    input wire lpSw,
    input wire lpDt,
    input wire lpClk,
    input wire squareBtn,
    input wire sawBtn,
    input wire selectBtn,
    output wire spiSck,
    output wire spiMosi,
    output wire spiCsn
);

    localparam integer CLKHZ = 25_000_000;
    localparam integer SAMPLERATE = 8_000;
    localparam integer SAMPLEDIV = CLKHZ / SAMPLERATE; // 3125 clocks/sample
    localparam integer SPIHALFPERIOD = 25;             // 500 kHz SPI clock
    localparam integer ENCODERSAMPLEDIV = 25_000;      // 1 kHz debounce sample

    wire sampleTick;
    wire encoderTick;

    wire [3:0] filterStep;
    wire [5:0] squarePitchStep;
    wire [5:0] sawPitchStep;
    wire [31:0] squarePhaseInc;
    wire [31:0] sawPhaseInc;
    wire pitchStepUp;
    wire pitchStepDown;
    wire pitchPressed;
    wire squareOn;
    wire sawOn;
    wire selectSaw;
    wire [7:0] squareSample;
    wire [7:0] sawSample;
    wire [7:0] mixedSample;
    wire [7:0] outputSample;
    wire signed [17:0] squareTarget;
    wire signed [17:0] sawTarget;
    wire signed [17:0] mixedTarget;
    wire spiBusy;

    tickGen #(
        .SAMPLEDIV(SAMPLEDIV),
        .ENCODERDIV(ENCODERSAMPLEDIV)
    ) ticks (
        .clk(clk),
        .sampleTick(sampleTick),
        .encoderTick(encoderTick)
    );

    rotarySet pitchEncoder (
        .clk(clk),
        .sampleTick(encoderTick),
        .encSw(encSw),
        .encDt(encDt),
        .encClk(encClk),
        .stepUp(pitchStepUp),
        .stepDown(pitchStepDown),
        .pressed(pitchPressed)
    );

    rotaryEncoder #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(0)
    ) lowpassEncoder (
        .clk(clk),
        .sampleTick(encoderTick),
        .encSw(lpSw),
        .encDt(lpDt),
        .encClk(lpClk),
        .value(filterStep)
    );

    buttonToggle squareToggle (
        .clk(clk),
        .sampleTick(encoderTick),
        .buttonN(squareBtn),
        .state(squareOn)
    );

    buttonToggle sawToggle (
        .clk(clk),
        .sampleTick(encoderTick),
        .buttonN(sawBtn),
        .state(sawOn)
    );

    buttonToggle selectToggle (
        .clk(clk),
        .sampleTick(encoderTick),
        .buttonN(selectBtn),
        .state(selectSaw)
    );

    pitchController #(
        .MINSTEP(0),
        .MAXSTEP(48),
        .RESETSTEP(12)
    ) pitchControl (
        .clk(clk),
        .selectSaw(selectSaw),
        .pitchPressed(pitchPressed),
        .pitchStepUp(pitchStepUp),
        .pitchStepDown(pitchStepDown),
        .squarePitchStep(squarePitchStep),
        .sawPitchStep(sawPitchStep)
    );

    pitchLookup squarePitchTable (
        .pitchStep(squarePitchStep),
        .phaseInc(squarePhaseInc)
    );

    pitchLookup sawPitchTable (
        .pitchStep(sawPitchStep),
        .phaseInc(sawPhaseInc)
    );

    squareOscillator squareOsc (
        .clk(clk),
        .sampleTick(sampleTick),
        .phaseInc(squarePhaseInc),
        .squareHigh(),
        .rawSample(squareSample),
        .squareTarget(squareTarget)
    );

    sawOscillator sawOsc (
        .clk(clk),
        .sampleTick(sampleTick),
        .phaseInc(sawPhaseInc),
        .rawSample(sawSample),
        .sawTarget(sawTarget)
    );

    audioMixer mixer (
        .squareOn(squareOn),
        .sawOn(sawOn),
        .squareSample(squareSample),
        .sawSample(sawSample),
        .squareTarget(squareTarget),
        .sawTarget(sawTarget),
        .mixedSample(mixedSample),
        .mixedTarget(mixedTarget)
    );

    onePoleLowpass lowpass (
        .clk(clk),
        .sampleTick(sampleTick),
        .filterStep(filterStep),
        .rawSample(mixedSample),
        .target(mixedTarget),
        .outputSample(outputSample)
    );

    spiByte #(
        .HALFPERIOD(SPIHALFPERIOD)
    ) spiTx (
        .clk(clk),
        .start(sampleTick && !spiBusy),
        .data(outputSample),
        .busy(spiBusy),
        .sck(spiSck),
        .mosi(spiMosi),
        .csn(spiCsn)
    );

endmodule
