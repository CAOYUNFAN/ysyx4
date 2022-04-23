.PHONY:sim clear sim_gdb

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
CFLAGS_NPC = -I$(CSRC_INCLUDE_DIR) -g
CFLAGS_NPC_2 = $(addprefix -CFLAGS , $(CFLAGS_NPC))

DIFF = --diff=$(NEMU_HOME)/build/riscv64-nemu-interpreter-so
ARGS += $(DIFF)
IMG ?= 

$(EMU_DIR)/$(EMU_TARGET): $(VSRC_FILES) $(CSRC_FILES) $(CSRC_INCLUDE)
	@echo "Verilator VSRC_FILES > EMU_DIR"
	@verilator --cc $(CFLAGS_NPC_2)\
		-Mdir $(@D)\
		--top-module $(EMU_TOP_MODULE)\
		--prefix $(EMU_TARGET)\
		--exe $(CSRC_FILES)\
		$(VSRC_FILES)
	@make -C $(EMU_DIR) -f $(EMU_TARGET).mk 

sim: $(EMU_DIR)/$(EMU_TARGET)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$< $(ARGS) $(IMG)

sim_gdb: $(EMU_DIR)/$(EMU_TARGET)
	$(call git_commit, "sim_gdb RTL")
	gdb -s $< --args $< $(ARGS) $(IMG)

clear:
	rm -rf $(EMU_DIR)


include ../Makefile
