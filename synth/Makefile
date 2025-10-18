# List of source files
SRC += $(SRC_DIR)/calc_prob.vhd
SRC += $(SRC_DIR)/single.vhd
SRC += $(SRC_DIR)/core.vhd
SRC += $(SRC_DIR)/pow2_rom.vhd
SRC += $(SRC_DIR)/pow2.vhd
SRC += $(SRC_DIR)/lfsr.vhd
SRC += $(SRC_DIR)/random.vhd

# List of platform specific files
SRC += $(PLATFORM_SRC_DIR)/clk_rst.vhd
SRC += $(PLATFORM_SRC_DIR)/mega65/font.vhd
SRC += $(PLATFORM_SRC_DIR)/mega65/kb_matrix_ram.vhdl
SRC += $(PLATFORM_SRC_DIR)/mega65/m2m_keyb.vhd
SRC += $(PLATFORM_SRC_DIR)/mega65/matrix_to_keynum.vhdl
SRC += $(PLATFORM_SRC_DIR)/mega65/mega65kbd_to_matrix.vhdl
SRC += $(PLATFORM_SRC_DIR)/mega65/video_chars.vhd
SRC += $(PLATFORM_SRC_DIR)/mega65/video_modes_pkg.vhd
SRC += $(PLATFORM_SRC_DIR)/mega65/video_sync.vhd
SRC += $(PLATFORM_SRC_DIR)/mega65_wrapper.vhd
SRC += $(PLATFORM_SRC_DIR)/tdp_ram.vhd
SRC += $(PLATFORM_SRC_DIR)/top.vhd
SRC += $(PLATFORM_SRC_DIR)/controller.vhd

# Top level entity
TOP = top

# Test specific generics
GENERICS += G_GRID_SIZE=32
GENERICS += G_ADDR_BITS=6
GENERICS += G_SCALING_BITS=4
GENERICS += G_ACCURACY=10

include Makefile.inc

