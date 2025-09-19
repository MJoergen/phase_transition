###############################################################################
# Location Constraints.
###############################################################################

# Main input clock
set_property PACKAGE_PIN V13  [get_ports sys_clk_i              ];            # CLOCK_FPGA_MRCC

# Reset input
set_property PACKAGE_PIN J19  [get_ports sys_rst_i              ];            # RESET

# MEGA65 Keyboard
set_property PACKAGE_PIN A14  [get_ports kb_io0_o               ];            # KB_IO1
set_property PACKAGE_PIN A13  [get_ports kb_io1_o               ];            # KB_IO2
set_property PACKAGE_PIN C13  [get_ports kb_io2_i               ];            # KB_IO3

# VGA via VDAC. U3 = ADV7125BCPZ170
set_property PACKAGE_PIN W11  [get_ports vdac_blank_n_o         ];            # VDAC_BLANK_N
set_property PACKAGE_PIN AA9  [get_ports vdac_clk_o             ];            # VDAC_CLK
set_property PACKAGE_PIN W16  [get_ports vdac_psave_n_o         ];            # VDAC_PSAVE_N
set_property PACKAGE_PIN V10  [get_ports vdac_sync_n_o          ];            # VDAC_SYNC_N
set_property PACKAGE_PIN W10  [get_ports vga_blue_o[0]          ];            # B0
set_property PACKAGE_PIN Y12  [get_ports vga_blue_o[1]          ];            # B1
set_property PACKAGE_PIN AB12 [get_ports vga_blue_o[2]          ];            # B2
set_property PACKAGE_PIN AA11 [get_ports vga_blue_o[3]          ];            # B3
set_property PACKAGE_PIN AB11 [get_ports vga_blue_o[4]          ];            # B4
set_property PACKAGE_PIN Y11  [get_ports vga_blue_o[5]          ];            # B5
set_property PACKAGE_PIN AB10 [get_ports vga_blue_o[6]          ];            # B6
set_property PACKAGE_PIN AA10 [get_ports vga_blue_o[7]          ];            # B7
set_property PACKAGE_PIN Y14  [get_ports vga_green_o[0]         ];            # G0
set_property PACKAGE_PIN W14  [get_ports vga_green_o[1]         ];            # G1
set_property PACKAGE_PIN AA15 [get_ports vga_green_o[2]         ];            # G2
set_property PACKAGE_PIN AB15 [get_ports vga_green_o[3]         ];            # G3
set_property PACKAGE_PIN Y13  [get_ports vga_green_o[4]         ];            # G4
set_property PACKAGE_PIN AA14 [get_ports vga_green_o[5]         ];            # G5
set_property PACKAGE_PIN AA13 [get_ports vga_green_o[6]         ];            # G6
set_property PACKAGE_PIN AB13 [get_ports vga_green_o[7]         ];            # G7
set_property PACKAGE_PIN W12  [get_ports vga_hs_o               ];            # HSYNC
set_property PACKAGE_PIN U15  [get_ports vga_red_o[0]           ];            # R0
set_property PACKAGE_PIN V15  [get_ports vga_red_o[1]           ];            # R1
set_property PACKAGE_PIN T14  [get_ports vga_red_o[2]           ];            # R2
set_property PACKAGE_PIN Y17  [get_ports vga_red_o[3]           ];            # R3
set_property PACKAGE_PIN Y16  [get_ports vga_red_o[4]           ];            # R4
set_property PACKAGE_PIN AB17 [get_ports vga_red_o[5]           ];            # R5
set_property PACKAGE_PIN AA16 [get_ports vga_red_o[6]           ];            # R6
set_property PACKAGE_PIN AB16 [get_ports vga_red_o[7]           ];            # R7
set_property PACKAGE_PIN V14  [get_ports vga_vs_o               ];            # VSYNC


###############################################################################
# I/O Standards
###############################################################################

set_property -dict {IOSTANDARD LVCMOS33          }  [get_ports sys_clk_i           ];
set_property -dict {IOSTANDARD LVCMOS33          }  [get_ports sys_rst_i           ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports kb_io0_o            ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports kb_io1_o            ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports kb_io2_i            ];

set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vdac_clk_o          ];
set_property -dict {IOSTANDARD LVCMOS33          }  [get_ports vdac_blank_n_o      ];
set_property -dict {IOSTANDARD LVCMOS33          }  [get_ports vdac_psave_n_o      ];
set_property -dict {IOSTANDARD LVCMOS33          }  [get_ports vdac_sync_n_o       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[0]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[1]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[2]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[3]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[4]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[5]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[6]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_blue_o[7]       ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[0]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[1]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[2]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[3]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[4]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[5]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[6]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_green_o[7]      ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_hs_o            ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[0]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[1]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[2]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[3]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[4]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[5]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[6]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_red_o[7]        ];
set_property -dict {IOSTANDARD LVCMOS33  IOB TRUE}  [get_ports vga_vs_o            ];


###############################################################################
# Clocks
###############################################################################

create_clock           -name clk   -period 10 [get_ports sys_clk_i];
create_generated_clock -name core_clk         [get_pins  clk_rst_inst/mmcme2_base_inst/CLKOUT0];
create_generated_clock -name vga_clk          [get_pins  clk_rst_inst/mmcme2_base_inst/CLKOUT1];


###############################################################################
# Timing Exceptions
###############################################################################

set_false_path -from                     [get_ports sys_rst_i];                         # Asynchronous reset


###############################################################################
# Configuration
###############################################################################

set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property CONFIG_VOLTAGE                  3.3   [current_design]

