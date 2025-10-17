library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity tb_single is
  generic (
    G_ACCURACY  : natural;
    G_ADDR_BITS : natural;
    G_GRID_SIZE : natural
  );
end entity tb_single;

architecture simulation of tb_single is

  constant C_INITIAL_TEMPERATURE : real                         := 0.9;
  constant C_INITIAL_CHEM_POT    : real                         := -1.5;
  constant C_LN2_RECIP_REAL      : real                         := 1.442695041;
  constant C_LN2_RECIP           : ufixed(2 downto -G_ACCURACY) := to_ufixed(C_LN2_RECIP_REAL, 2, -G_ACCURACY);

  signal   running : std_logic                                  := '1';
  signal   clk     : std_logic                                  := '1';
  signal   rst     : std_logic                                  := '1';

  signal   single_coef_e : ufixed(3 downto -G_ACCURACY);  -- [0, 16[
  signal   single_coef_n : ufixed(3 downto -G_ACCURACY);  -- [0, 16[
  signal   single_ready  : std_logic;
  signal   single_valid  : std_logic;
  signal   single_pos_x  : unsigned(G_ADDR_BITS - 1 downto 0);
  signal   single_pos_y  : unsigned(G_ADDR_BITS - 1 downto 0);
  signal   single_random : ufixed(-1 downto -G_ACCURACY); -- [0, 1[

  signal   ram_addr    : std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
  signal   ram_wr_data : std_logic;
  signal   ram_rd_data : std_logic;
  signal   ram_wr_en   : std_logic;

  signal   tb_addr    : std_logic_vector(2 * G_ADDR_BITS - 1 downto 0);
  signal   tb_wr_data : std_logic;
  signal   tb_wr_en   : std_logic;
  signal   tb_rd_en   : std_logic;
  signal   tb_rd_data : std_logic;

  alias    tb_addr_x : std_logic_vector(G_ADDR_BITS - 1 downto 0) is tb_addr(2 * G_ADDR_BITS - 1 downto G_ADDR_BITS);
  alias    tb_addr_y : std_logic_vector(G_ADDR_BITS - 1 downto 0) is tb_addr(G_ADDR_BITS - 1 downto 0);

  pure function calc_hamil (
    neighbor_cnt_v : real;
    cell_v : real
  ) return real is
    variable energy_v : real;
    variable number_v : real;
  begin
    energy_v := -neighbor_cnt_v * cell_v;
    return energy_v - C_INITIAL_CHEM_POT * cell_v;
  end function calc_hamil;

  pure function calc_exp_prob (
    neighbor_cnt_v : natural;
    cell_v : natural
  ) return real is
    variable delta_hamil_v : real;
    variable q_v           : real;
  begin
    delta_hamil_v := calc_hamil(real(neighbor_cnt_v), real(1 - cell_v)) -
                     calc_hamil(real(neighbor_cnt_v), real(cell_v));
    q_v           := exp(-delta_hamil_v / C_INITIAL_TEMPERATURE);
    return q_v / (1.0 + q_v);
  end function calc_exp_prob;

begin

  clk           <= running and not clk after 5 ns;
  rst           <= '1', '0' after 100 ns;

  single_coef_e <= to_ufixed(C_LN2_RECIP_REAL / C_INITIAL_TEMPERATURE, single_coef_e);
  single_coef_n <= to_ufixed(-C_LN2_RECIP_REAL * C_INITIAL_CHEM_POT / C_INITIAL_TEMPERATURE, single_coef_n);

  test_proc : process
    --

    procedure verify (
      x : natural;
      y : natural;
      c : unsigned(4 downto 0);
      f : real;
      n : std_logic
    ) is
      variable neighbor_cnt_v : natural range 0 to 4;
      variable exp_prob_v   : real;
    begin
      --      report "Verify: x=" & to_string(x) &
      --             ", y=" & to_string(y) &
      --             ", c=" & to_string(c);
      neighbor_cnt_v := 0;
      for i in 1 to 4 loop
        if c(i) = '1' then
          neighbor_cnt_v := neighbor_cnt_v + 1;
        end if;
      end loop;

      exp_prob_v    := calc_exp_prob(neighbor_cnt_v, to_integer(c(0 downto 0)));
      --      report "neighbor_cnt_v=" & to_string(neighbor_cnt_v) &
      --             ", cell_v=" & to_string(c(0)) &
      --             " -> exp_prob_v = " & to_string(exp_prob_v);

      tb_addr_x     <= std_logic_vector(to_unsigned(x, G_ADDR_BITS));
      tb_addr_y     <= std_logic_vector(to_unsigned(y, G_ADDR_BITS));
      tb_wr_en      <= '1';
      tb_wr_data    <= c(0);
      wait until rising_edge(clk);
      tb_addr_x     <= std_logic_vector(to_unsigned((x+1) mod G_GRID_SIZE, G_ADDR_BITS));
      tb_addr_y     <= std_logic_vector(to_unsigned(y, G_ADDR_BITS));
      tb_wr_en      <= '1';
      tb_wr_data    <= c(1);
      wait until rising_edge(clk);
      tb_addr_x     <= std_logic_vector(to_unsigned((x-1) mod G_GRID_SIZE, G_ADDR_BITS));
      tb_addr_y     <= std_logic_vector(to_unsigned(y, G_ADDR_BITS));
      tb_wr_en      <= '1';
      tb_wr_data    <= c(2);
      wait until rising_edge(clk);
      tb_addr_x     <= std_logic_vector(to_unsigned(x, G_ADDR_BITS));
      tb_addr_y     <= std_logic_vector(to_unsigned((y+1) mod G_GRID_SIZE, G_ADDR_BITS));
      tb_wr_en      <= '1';
      tb_wr_data    <= c(3);
      wait until rising_edge(clk);
      tb_addr_x     <= std_logic_vector(to_unsigned(x, G_ADDR_BITS));
      tb_addr_y     <= std_logic_vector(to_unsigned((y-1) mod G_GRID_SIZE, G_ADDR_BITS));
      tb_wr_en      <= '1';
      tb_wr_data    <= c(4);
      wait until rising_edge(clk);

      tb_wr_en      <= '0';
      single_pos_x  <= to_unsigned(x, G_ADDR_BITS);
      single_pos_y  <= to_unsigned(y, G_ADDR_BITS);
      single_valid  <= '1';
      single_random <= to_ufixed(exp_prob_v * f, -1, -G_ACCURACY);
      wait until rising_edge(clk);
      while single_ready = '0' loop
        wait until rising_edge(clk);
      end loop;

      single_valid <= '0';
      wait until rising_edge(clk);

      assert single_ready = '0';
      while single_ready = '0' loop
        wait until rising_edge(clk);
      end loop;

      tb_addr_x <= std_logic_vector(to_unsigned(x, G_ADDR_BITS));
      tb_addr_y <= std_logic_vector(to_unsigned(y, G_ADDR_BITS));
      tb_rd_en  <= '1';
      wait until rising_edge(clk);
      tb_rd_en  <= '0';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      assert tb_rd_data = n;
    end procedure verify;

  begin
    tb_wr_en     <= '0';
    tb_rd_en     <= '0';
    single_valid <= '0';
    wait until rst = '0';
    wait for 100 ns;
    wait until rising_edge(clk);

    report "Test started";

    for i in 0 to 15 loop
      verify(0, 0, to_unsigned(i, 4) & "0", 1.05, '0');
      verify(0, G_GRID_SIZE - 1, to_unsigned(i, 4) & "0", 0.95, '1');
      verify(G_GRID_SIZE - 1, 0, to_unsigned(i, 4) & "1", 1.05, '1');
      verify(G_GRID_SIZE - 1, G_GRID_SIZE - 1, to_unsigned(i, 4) & "1", 0.95, '0');
    end loop;

    report "Test finished";
    wait until rising_edge(clk);

    running <= '0';
    wait;
  end process test_proc;

  single_inst : entity work.single
    generic map (
      G_ACCURACY  => G_ACCURACY,
      G_ADDR_BITS => G_ADDR_BITS,
      G_GRID_SIZE => G_GRID_SIZE
    )
    port map (
      clk_i         => clk,
      rst_i         => rst,
      coef_e_i      => single_coef_e,
      coef_n_i      => single_coef_n,
      ready_o       => single_ready,
      valid_i       => single_valid,
      pos_x_i       => single_pos_x,
      pos_y_i       => single_pos_y,
      random_i      => single_random,
      ram_addr_o    => ram_addr,
      ram_wr_data_o => ram_wr_data,
      ram_rd_data_i => ram_rd_data,
      ram_wr_en_o   => ram_wr_en
    ); -- single_inst : entity work.single

  tdp_ram_inst : entity work.tdp_ram
    generic map (
      G_A_LATENCY => 2,
      G_B_LATENCY => 2,
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
      b_clk_i        => clk,
      b_rst_i        => rst,
      b_addr_i       => tb_addr,
      b_wr_en_i      => tb_wr_en,
      b_wr_data_i(0) => tb_wr_data,
      b_rd_en_i      => tb_rd_en,
      b_rd_data_o(0) => tb_rd_data
    ); -- tdp_ram_inst : entity work.tdp_ram

end architecture simulation;

