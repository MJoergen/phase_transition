library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity tb_calc_prob is
  generic (
    G_ACCURACY : natural
  );
end entity tb_calc_prob;

architecture simulation of tb_calc_prob is

  signal running : std_logic := '1';
  signal clk     : std_logic := '1';
  signal rst     : std_logic := '1';

  signal coef_e           : ufixed(-1 downto -G_ACCURACY);
  signal coef_n           : ufixed(1 downto -G_ACCURACY);
  signal neighbor_cnt     : natural range 0 to 4;
  signal cell             : std_logic;
  signal valid            : std_logic;
  signal prob_numerator   : ufixed(3 downto -G_ACCURACY);
  signal prob_denominator : ufixed(3 downto -G_ACCURACY);

begin

  clk <= running and not clk after 5 ns;
  rst <= '1', '0' after 100 ns;

  test_proc : process
  begin
    coef_e       <= to_ufixed(0, coef_e);
    coef_n       <= to_ufixed(0, coef_n);
    neighbor_cnt <= 0;
    cell         <= '0';
    valid        <= '0';
    wait until rst = '0';
    wait until rising_edge(clk);

    report "Test started";

    valid        <= '1';
    wait until rising_edge(clk);
    valid        <= '0';

    for i in 1 to work.calc_prob'latency loop
      wait until rising_edge(clk);
    end loop;

    report "Test finished";

    running <= '0';
    wait;
  end process test_proc;

  calc_prob_inst : entity work.calc_prob
    generic map (
      G_ACCURACY => G_ACCURACY
    )
    port map (
      clk_i              => clk,
      rst_i              => rst,
      coef_e_i           => coef_e,
      coef_n_i           => coef_n,
      neighbor_cnt_i     => neighbor_cnt,
      cell_i             => cell,
      valid_i            => valid,
      prob_numerator_o   => prob_numerator,
      prob_denominator_o => prob_denominator
    ); -- calc_prob_inst : entity work.calc_prob

end architecture simulation;

