TARGET  = top
LPF     = icesugar_pro.lpf
SRCS    = src/top.v

.PHONY: all prog clean

all: $(TARGET).bit

$(TARGET).json: $(SRCS)
	cd src && yosys -p "synth_ecp5 -top top -json ../$(TARGET).json" top.v

$(TARGET)_out.config: $(TARGET).json $(LPF)
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 \
		--json $(TARGET).json \
		--textcfg $(TARGET)_out.config \
		--lpf $(LPF) \
		--freq 65 \
		--timing-allow-fail \
		--ignore-loops \
		--lpf-allow-unconstrained \
		--force

$(TARGET).bit: $(TARGET)_out.config
	ecppack $(TARGET)_out.config $(TARGET).bit

prog: $(TARGET).bit
	icesprog -p $(TARGET).bit

clean:
	rm -f $(TARGET).json $(TARGET)_out.config $(TARGET).bit $(TARGET).svf
