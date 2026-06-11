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
    input wire hpSw,
    input wire hpDt,
    input wire hpClk,
    input wire envSw,
    input wire envDt,
    input wire envClk,
    input wire squareBtn,
    input wire sawBtn,
    input wire selectBtn,
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

    wire [3:0] lowpassStep;
    wire [3:0] highpassStep;
    wire [3:0] attackStep;
    wire [3:0] decayStep;
    wire [3:0] sustainStep;
    wire [3:0] releaseStep;
    wire [5:0] pitchStep;
    wire pitchStepUp;
    wire pitchStepDown;
    wire pitchPressed;
    wire lowpassStepUp;
    wire lowpassStepDown;
    wire lowpassPressed;
    wire highpassStepUp;
    wire highpassStepDown;
    wire highpassPressed;
    wire releaseStepUp;
    wire releaseStepDown;
    wire releasePressed;
    wire squareOn;
    wire sawOn;
    wire adsrMode;
    wire normalMode;
    wire [7:0] mixedSample;
    wire [7:0] lowpassSample;
    wire [7:0] outputSample;
    wire signed [17:0] mixedTarget;
    wire spiStart;
    wire [7:0] spiData;
    wire spiBusy;

    assign normalMode = !adsrMode;

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

    rotarySet lowpassEncoder (
        .clk(clk),
        .sampleTick(encoderTick),
        .encSw(lpSw),
        .encDt(lpDt),
        .encClk(lpClk),
        .stepUp(lowpassStepUp),
        .stepDown(lowpassStepDown),
        .pressed(lowpassPressed)
    );

    rotarySet highpassEncoder (
        .clk(clk),
        .sampleTick(encoderTick),
        .encSw(hpSw),
        .encDt(hpDt),
        .encClk(hpClk),
        .stepUp(highpassStepUp),
        .stepDown(highpassStepDown),
        .pressed(highpassPressed)
    );

    rotarySet releaseEncoder (
        .clk(clk),
        .sampleTick(encoderTick),
        .encSw(envSw),
        .encDt(envDt),
        .encClk(envClk),
        .stepUp(releaseStepUp),
        .stepDown(releaseStepDown),
        .pressed(releasePressed)
    );

    controlValue #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(0)
    ) lowpassControl (
        .clk(clk),
        .enable(normalMode),
        .pressed(lowpassPressed),
        .stepUp(lowpassStepUp),
        .stepDown(lowpassStepDown),
        .value(lowpassStep)
    );

    controlValue #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(0)
    ) highpassControl (
        .clk(clk),
        .enable(normalMode),
        .pressed(highpassPressed),
        .stepUp(highpassStepUp),
        .stepDown(highpassStepDown),
        .value(highpassStep)
    );

    controlValue #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(0)
    ) attackControl (
        .clk(clk),
        .enable(adsrMode),
        .pressed(pitchPressed),
        .stepUp(pitchStepUp),
        .stepDown(pitchStepDown),
        .value(attackStep)
    );

    controlValue #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(0)
    ) decayControl (
        .clk(clk),
        .enable(adsrMode),
        .pressed(lowpassPressed),
        .stepUp(lowpassStepUp),
        .stepDown(lowpassStepDown),
        .value(decayStep)
    );

    controlValue #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(15)
    ) sustainControl (
        .clk(clk),
        .enable(adsrMode),
        .pressed(highpassPressed),
        .stepUp(highpassStepUp),
        .stepDown(highpassStepDown),
        .value(sustainStep)
    );

    controlValue #(
        .WIDTH(4),
        .MINVALUE(0),
        .MAXVALUE(15),
        .RESETVALUE(0)
    ) releaseControl (
        .clk(clk),
        .enable(adsrMode),
        .pressed(releasePressed),
        .stepUp(releaseStepUp),
        .stepDown(releaseStepDown),
        .value(releaseStep)
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

    buttonToggle adsrToggle (
        .clk(clk),
        .sampleTick(encoderTick),
        .buttonN(selectBtn),
        .state(adsrMode)
    );

    pitchController #(
        .MINSTEP(0),
        .MAXSTEP(36),
        .RESETSTEP(12),
        .STEPSIZE(12)
    ) pitchControl (
        .clk(clk),
        .enable(normalMode),
        .pitchPressed(pitchPressed),
        .pitchStepUp(pitchStepUp),
        .pitchStepDown(pitchStepDown),
        .pitchStep(pitchStep)
    );

    polySynth synth (
        .clk(clk),
        .encoderTick(encoderTick),
        .sampleTick(sampleTick),
        .keyC(keyC),
        .keyCs(keyCs),
        .keyD(keyD),
        .keyDs(keyDs),
        .keyE(keyE),
        .keyF(keyF),
        .keyFs(keyFs),
        .keyG(keyG),
        .keyGs(keyGs),
        .keyA(keyA),
        .keyAs(keyAs),
        .keyB(keyB),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .octaveStep(pitchStep),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .mixedSample(mixedSample),
        .mixedTarget(mixedTarget)
    );

    onePoleLowpass lowpass (
        .clk(clk),
        .sampleTick(sampleTick),
        .filterStep(lowpassStep),
        .rawSample(mixedSample),
        .target(mixedTarget),
        .outputSample(lowpassSample)
    );

    onePoleHighpass highpass (
        .clk(clk),
        .sampleTick(sampleTick),
        .filterStep(highpassStep),
        .rawSample(lowpassSample),
        .outputSample(outputSample)
    );

    parameterPacket #(
        .STATUSDIV(1024)
    ) statusPacket (
        .clk(clk),
        .sampleTick(sampleTick),
        .spiBusy(spiBusy),
        .audioSample(outputSample),
        .pitchStep(pitchStep),
        .lowpassStep(lowpassStep),
        .highpassStep(highpassStep),
        .attackStep(attackStep),
        .decayStep(decayStep),
        .sustainStep(sustainStep),
        .releaseStep(releaseStep),
        .squareOn(squareOn),
        .sawOn(sawOn),
        .spiStart(spiStart),
        .spiData(spiData)
    );

    spiByte #(
        .HALFPERIOD(SPIHALFPERIOD)
    ) spiTx (
        .clk(clk),
        .start(spiStart),
        .data(spiData),
        .busy(spiBusy),
        .sck(spiSck),
        .mosi(spiMosi),
        .csn(spiCsn)
    );

endmodule
