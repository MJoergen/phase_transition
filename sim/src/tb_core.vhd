library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity tb_core is
  generic (
    G_ACCURACY  : natural;
    G_ADDR_BITS : natural;
    G_GRID_SIZE : natural
  );
end entity tb_core;

architecture simulation of tb_core is

  signal running     : std_logic                                 := '1';
  signal clk         : std_logic                                 := '1';
  signal rst         : std_logic                                 := '1';
  signal temperature : std_logic_vector(G_ACCURACY - 1 downto 0) := x"8765";
  signal chem_pot    : std_logic_vector(G_ACCURACY - 1 downto 0) := x"1234";
  signal ram_addr    : std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
  signal ram_wr_data : std_logic;
  signal ram_rd_data : std_logic;
  signal ram_wr_en   : std_logic;

begin

  clk <= running and not clk after 5 ns;
  rst <= '1', '0' after 100 ns;

  core_inst : entity work.core
    generic map (
      G_ACCURACY  => G_ACCURACY,
      G_ADDR_BITS => G_ADDR_BITS,
      G_GRID_SIZE => G_GRID_SIZE
    )
    port map (
      clk_i         => clk,
      rst_i         => rst,
      step_i        => '1',
      temperature_i => temperature,
      chem_pot_i    => chem_pot,
      ram_addr_o    => ram_addr,
      ram_wr_data_o => ram_wr_data,
      ram_rd_data_i => ram_rd_data,
      ram_wr_en_o   => ram_wr_en
    ); -- core_inst : entity work.core

  tdp_ram_inst : entity work.tdp_ram
    generic map (
      G_ADDR_SIZE => 2 * G_ADDR_BITS,
      G_DATA_SIZE => 1
    )
    port map (
      a_clk_i        => clk,
      a_rst_i        => rst,
      a_addr_i       => ram_addr,
      a_wr_en_i      => ram_wr_en,
      a_wr_data_i(0) => ram_wr_data,
      a_rd_en_i      => '1',
      a_rd_data_o(0) => ram_rd_data,
      b_clk_i        => '0',
      b_rst_i        => '0',
      b_addr_i       => (others => '0'),
      b_wr_en_i      => '0',
      b_wr_data_i    => (others => '0'),
      b_rd_en_i      => '1',
      b_rd_data_o    => open
    ); -- tdp_ram_inst : entity work.tdp_ram

end architecture simulation;

