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

  signal   running : std_logic                                    := '1';
  signal   clk     : std_logic                                    := '1';
  signal   rst     : std_logic                                    := '1';

  constant C_TEMPERATURE  : ufixed(G_ACCURACY downto -G_ACCURACY) := to_ufixed(0.3, G_ACCURACY, -G_ACCURACY);
  constant C_NEG_CHEM_POT : ufixed(G_ACCURACY downto -G_ACCURACY) := to_ufixed(1.5, G_ACCURACY, -G_ACCURACY);

  constant C_LN2_RECIP_REAL : real                                := 1.442695041;
  constant C_LN2_RECIP      : ufixed(2 downto -G_ACCURACY)        := to_ufixed(C_LN2_RECIP_REAL, 2, -G_ACCURACY);

  signal   coef_e           : ufixed(3 downto -G_ACCURACY);
  signal   coef_n           : ufixed(3 downto -G_ACCURACY);
  signal   neighbor_cnt     : natural range 0 to 4;
  signal   cell             : std_logic;
  signal   valid            : std_logic;
  signal   prob_numerator   : ufixed(7 downto -G_ACCURACY);
  signal   prob_denominator : ufixed(7 downto -G_ACCURACY);
  signal   prob_valid       : std_logic;

  -- This calculates the Hamiltonian contribution from a single cell
  -- H = E - C N

  pure function calc_hamil (
    neighbor_cnt_v : real;
    cell_v : real
  ) return real is
    variable energy_v : real;
    variable number_v : real;
    variable res_v    : real;
  begin
    energy_v := -neighbor_cnt_v * cell_v;
    number_v := cell_v;
    res_v    := energy_v + to_real(C_NEG_CHEM_POT) * number_v;
    --    report "neighbor_cnt=" & to_string(neighbor_cnt_v) &
    --           ", cell=" & to_string(cell_v) &
    --           " -> " & to_string(res_v);
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
      variable q_v           : real;
      variable exp_prob_v    : real;
      variable prob_v        : real;
      variable abs_diff_v    : real;
      variable rel_diff_v    : real;
    begin
      neighbor_cnt <= neighbor_cnt_v;
      cell         <= '0' when cell_v = 0 else '1';
      valid        <= '1';
      wait until rising_edge(clk);
      neighbor_cnt <= 0;
      cell         <= '0';
      valid        <= '0';

      for i in 1 to work.calc_prob'latency loop
        assert prob_valid = '0';
        wait until rising_edge(clk);
      end loop;

      assert prob_valid = '1';

      assert prob_denominator = resize(prob_numerator + 1, prob_denominator);

      delta_hamil_v := calc_hamil(real(neighbor_cnt_v), real(1 - cell_v)) -
                       calc_hamil(real(neighbor_cnt_v), real(cell_v));

      q_v           := exp(-delta_hamil_v / to_real(C_TEMPERATURE));
      -- report "q_expected=" & to_string(q_v);

      exp_prob_v    := q_v / (1.0 + q_v);
      prob_v        := to_real(prob_numerator) / to_real(prob_denominator);

      abs_diff_v    := abs(prob_v - exp_prob_v);
      rel_diff_v    := abs_diff_v / exp_prob_v;

      assert abs_diff_v < 1.0e-2 or rel_diff_v < 1.0e-2
        report "abs_diff_v=" & to_string(abs_diff_v) & " , " &
               "rel_diff_v=" & to_string(rel_diff_v);

    --
    end procedure verify;

  --
  begin
    report "Temperature=" & to_string(to_real(C_TEMPERATURE));
    report "Chemical Potential=" & to_string(-to_real(C_NEG_CHEM_POT));

    coef_e       <= resize(C_LN2_RECIP / C_TEMPERATURE, coef_e);
    coef_n       <= resize(C_LN2_RECIP * C_NEG_CHEM_POT / C_TEMPERATURE, coef_n);

    neighbor_cnt <= 0;
    cell         <= '0';
    valid        <= '0';
    wait until rst = '0';
    wait until rising_edge(clk);

    --    report "coef_e=" & to_string(to_real(coef_e));
    --    report "coef_n=" & to_string(to_real(coef_n));

    assert prob_valid = '0';

    report "Test started";

    for n in 0 to 4 loop
      --
      for c in 0 to 1 loop
        verify(n, c);
      end loop;

    --
    end loop;

    wait until rising_edge(clk);

    report "Test finished";

    wait until rising_edge(clk);
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
      prob_denominator_o => prob_denominator,
      valid_o            => prob_valid
    ); -- calc_prob_inst : entity work.calc_prob

end architecture simulation;

