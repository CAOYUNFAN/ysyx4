.PHONY:sim clear sim_gdb find_display

STUID := ysyx_220066_
CSRC_DIR := $(NPC_HOME)/csrc/src/
CSRC_FILES := $(shell find $(CSRC_DIR) -name "*.cpp")
CSRC_INCLUDE_DIR := $(NPC_HOME)/csrc/include/
CSRC_INCLUDE := $(shell find $(CSRC_INCLUDE) -name "*.h")
VSRC_DIR := $(NPC_HOME)/vsrc
VSRC_FILES := $(shell find $(VSRC_DIR) -name "*.v")
EMU_DIR := $(NPC_HOME)/emu
EMU_TOP_MODULE :=$(STUID)top
EMU_TARGET := emu
INSTR = #-DINSTR -DR_W -Dfully_info
CFLAGS_NPC = -I$(CSRC_INCLUDE_DIR) -g -O2 $(INSTR) #-DMTRACE
VFLAGS = $(INSTR) -DEMU_MUTLI -O3
LDFLAGS =-lSDL2 

DIFF = #--diff=$(NEMU_HOME)/build/riscv64-nemu-interpreter-so
IMG ?= 
ARGS ?= --log=$(NPC_HOME)/emu/log.txt

$(EMU_DIR)/$(EMU_TARGET): $(VSRC_FILES) $(CSRC_FILES) $(CSRC_INCLUDE)
	@echo "Verilator VSRC_FILES > EMU_DIR"
	@verilator --cc $(addprefix -CFLAGS , $(CFLAGS_NPC)) $(addprefix -LDFLAGS , $(LDFLAGS))\
		-Mdir $(@D)\
		--top-module $(EMU_TOP_MODULE)\
		--prefix $(EMU_TARGET)\
		--exe $(CSRC_FILES)\
		$(VFLAGS)\
		$(VSRC_FILES)
	@make -C $(EMU_DIR) -f $(EMU_TARGET).mk -j4

sim: $(EMU_DIR)/$(EMU_TARGET)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$< $(ARGS) $(DIFF) $(IMG)

sim_gdb: $(EMU_DIR)/$(EMU_TARGET)
	$(call git_commit, "sim_gdb RTL")
	gdb -s $< --args $< $(ARGS) $(DIFF) $(IMG)

clear:
	rm -rf $(EMU_DIR)

find_display:
	grep -nIR -n1 "display" vsrc/

include ../Makefile
