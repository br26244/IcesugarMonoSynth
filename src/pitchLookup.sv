`default_nettype none
`timescale 1ns/1ps

module pitchLookup (
    input wire [5:0] pitchStep,
    output reg [31:0] phaseInc
);

    always @* begin
        case (pitchStep)
            6'd0: phaseInc = 32'd35_114_789;  // C2
            6'd1: phaseInc = 32'd37_202_823;
            6'd2: phaseInc = 32'd39_415_018;
            6'd3: phaseInc = 32'd41_758_757;
            6'd4: phaseInc = 32'd44_241_862;
            6'd5: phaseInc = 32'd46_872_620;
            6'd6: phaseInc = 32'd49_659_811;
            6'd7: phaseInc = 32'd52_612_737;
            6'd8: phaseInc = 32'd55_741_253;
            6'd9: phaseInc = 32'd59_055_800;
            6'd10: phaseInc = 32'd62_567_441;
            6'd11: phaseInc = 32'd66_287_895;
            6'd12: phaseInc = 32'd70_229_578;  // C3
            6'd13: phaseInc = 32'd74_405_646;
            6'd14: phaseInc = 32'd78_830_036;
            6'd15: phaseInc = 32'd83_517_514;
            6'd16: phaseInc = 32'd88_483_724;
            6'd17: phaseInc = 32'd93_745_240;
            6'd18: phaseInc = 32'd99_319_622;
            6'd19: phaseInc = 32'd105_225_474;
            6'd20: phaseInc = 32'd111_482_506;
            6'd21: phaseInc = 32'd118_111_601;
            6'd22: phaseInc = 32'd125_134_882;
            6'd23: phaseInc = 32'd132_575_789;
            6'd24: phaseInc = 32'd140_459_156; // C4
            6'd25: phaseInc = 32'd148_811_292;
            6'd26: phaseInc = 32'd157_660_072;
            6'd27: phaseInc = 32'd167_035_028;
            6'd28: phaseInc = 32'd176_967_447;
            6'd29: phaseInc = 32'd187_490_479;
            6'd30: phaseInc = 32'd198_639_243;
            6'd31: phaseInc = 32'd210_450_947;
            6'd32: phaseInc = 32'd222_965_012;
            6'd33: phaseInc = 32'd236_223_201;
            6'd34: phaseInc = 32'd250_269_764;
            6'd35: phaseInc = 32'd265_151_578;
            6'd36: phaseInc = 32'd280_918_312; // C5
            6'd37: phaseInc = 32'd297_622_584;
            6'd38: phaseInc = 32'd315_320_144;
            6'd39: phaseInc = 32'd334_070_055;
            6'd40: phaseInc = 32'd353_934_894;
            6'd41: phaseInc = 32'd374_980_958;
            6'd42: phaseInc = 32'd397_278_486;
            6'd43: phaseInc = 32'd420_901_894;
            6'd44: phaseInc = 32'd445_930_024;
            6'd45: phaseInc = 32'd472_446_403;
            6'd46: phaseInc = 32'd500_539_528;
            6'd47: phaseInc = 32'd530_303_157;
            default: phaseInc = 32'd561_836_623; // C6
        endcase
    end

endmodule
