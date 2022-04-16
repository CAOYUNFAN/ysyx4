.PHONY:sim clear

STUID := ysyx_220066_
CSRC_DIR := ./csrc
CSRC_FILES := $(shell find $(CSRC_DIR) -name "*.cpp")
VSRC_DIR := ./vsrc
VSRC_FILES := $(shell find $(VSRC_DIR) -name "*.v")
EMU_DIR := ./emu
EMU_TOP_MODULE :=$(STUID)top
EMU_TARGET := emu

$(EMU_DIR)/$(EMU_TARGET).mk: $(VSRC_FILES) $(CSRC_FILES)
	@echo "Verilator $(VSRC_FILES) > $(EMU_DIR)"
	@verilator --cc --debug -CFLAGS -g\
		-Mdir $(@D)\
		--top-module $(EMU_TOP_MODULE)\
		--prefix $(EMU_TARGET)\
		--exe $(CSRC_FILES)\
		$(VSRC_FILES)
	@make -C $(EMU_DIR) -f $(EMU_TARGET).mk 

sim: $(EMU_DIR)/$(EMU_TARGET).mk
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(EMU_DIR)/$(EMU_TARGET) ../am-kernels/tests/cpu-tests/build/dummy-riscv64-nemu.bin

clear:
	rm -rf $(EMU_DIR)


include ../Makefile
