# List of source files
SRC += $(SRC_DIR)/exp_rom.vhd
SRC += $(SRC_DIR)/exp.vhd
SRC += $(SRC_DIR)/calc_prob.vhd

# List of test specific simulation files
SRC += $(SIM_SRC_DIR)/tb_calc_prob.vhd

# Top level entity
DUT = calc_prob

# Test duration
STOP_TIME = 5000ns

# Test specific generics
GENERIC += -gG_ACCURACY=16

include ../Makefile.inc

