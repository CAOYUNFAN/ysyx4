.PHONY:sim clear

STUID := ysyx_220066_
CSRC_DIR := ./csrc
CSRC_FILES := $(shell find $(SRC_DIR) -name "*.cpp")
VSRC_DIR := ./vsrc
VSRC_FILES := $(shell find $(VSRC_DIR) -name "*.v")
EMU_DIR := ./emu
EMU_TOP_MODULE :=$(STUID)top
EMU_TARGET := emu

$(EMU_DIR)/$(EMU_TARGET).mk: $(VSRC_FILES) $(CSRC_FILES)
	@echo "Verilator $(VSRC_FILES) > $(EMU_DIR)"
	@verilator --cc \
		-Mdir $(@D)\
		--top-module $(EMU_TOP_MODULE)\
		--prefix $(EMU_TARGET)\
		--exe $(CSRC_FILES)\
		$(VSRC_FILES)

$(EMU_DIR)/$(EMU_TARGET):$(EMU_DIR)/$(EMU_TARGET).mk
	@make -C $(EMU_DIR) -f $(EMU_TARGET).mk 

sim: $(EMU_DIR)/$(EMU_TARGET)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(EMU_DIR)/$(EMU_TARGET)

clear:
	rm -rf $(EMU_DIR)


include ../Makefile
