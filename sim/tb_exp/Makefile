# List of source files
SRC += $(SRC_DIR)/exp_rom.vhd
SRC += $(SRC_DIR)/exp.vhd

# List of test specific simulation files
SRC += $(SIM_SRC_DIR)/tb_exp.vhd

# Top level entity
DUT = exp

# Test duration
STOP_TIME = 5000ns

# Test specific generics
GENERIC += -gG_ACCURACY=4

include ../Makefile.inc

