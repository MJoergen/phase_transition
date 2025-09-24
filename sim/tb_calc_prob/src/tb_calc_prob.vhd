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
  signal prob_valid       : std_logic;

  -- This calculates the Hamiltonian contribution from a single cell
  -- H = E - C N

  pure function calc_hamil (
    coef_e_v : real; -- 1/T
    coef_n_v : real; -- -C/T
    neighbor_cnt_v : real;
    cell_v : real
  ) return real is
    variable energy_v : real;
    variable number_v : real;
    variable res_v    : real;
  begin
    energy_v := -neighbor_cnt_v * cell_v;
    number_v := cell_v;
    res_v    := -coef_e_v * energy_v - coef_n_v * number_v;
    report "coef_e=" & to_string(coef_e_v) &
           ", coef_n=" & to_string(coef_n_v) &
           ", neighbor_cnt=" & to_string(neighbor_cnt_v) &
           ", cell=" & to_string(cell_v) &
           " -> " & to_string(res_v);
    return res_v;
  end function calc_hamil;

begin

  clk <= running and not clk after 5 ns;
  rst <= '1', '0' after 100 ns;

  test_proc : process
    --

    procedure verify (
      neighbor_cnt_v : natural;
      cell_v         : natural
    ) is
      variable delta_hamil_v : real;
    begin
      neighbor_cnt <= neighbor_cnt_v;
      cell         <= '0' when cell_v = 0 else '1';
      valid        <= '1';
      wait until rising_edge(clk);
      valid        <= '0';

      for i in 1 to work.calc_prob'latency loop
        assert prob_valid = '0';
        wait until rising_edge(clk);
      end loop;

      delta_hamil_v := calc_hamil(to_real(coef_e), to_real(coef_n), real(neighbor_cnt_v), real(1 - cell_v)) -
                       calc_hamil(to_real(coef_e), to_real(coef_n), real(neighbor_cnt_v), real(cell_v));

      assert prob_valid = '1';

      assert prob_denominator = prob_numerator + 1;

      report to_string(to_real(prob_numerator)) & ", " & to_string(to_real(prob_denominator));
    --
    end procedure verify;

  --
  begin
    coef_e       <= to_ufixed(0, coef_e);
    coef_n       <= to_ufixed(0, coef_n);
    neighbor_cnt <= 0;
    cell         <= '0';
    valid        <= '0';
    wait until rst = '0';
    wait until rising_edge(clk);

    assert prob_valid = '0';

    report "Test started";

    verify(0, 0);

    report "Test finished";

    wait until rising_edge(clk);
    running      <= '0';
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
      prob_denominator_o => prob_denominator,
      valid_o            => prob_valid
    ); -- calc_prob_inst : entity work.calc_prob

end architecture simulation;

