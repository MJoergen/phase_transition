library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

-- This calculates the value:
-- q = exp(Coef_e*E_loss + Coef_n*N_loss)
-- where
-- E_loss = E_cur - E_new
-- N_loss = N_cur - N_new
-- coef_e is in range [0, 15[
-- coef_n is in range [0, 15[

entity calc_prob is
  generic (
    G_ACCURACY : natural
  );
  port (
    clk_i              : in    std_logic;
    rst_i              : in    std_logic;
    coef_e_i           : in    ufixed(3 downto -G_ACCURACY);
    coef_n_i           : in    ufixed(3 downto -G_ACCURACY);
    neighbor_cnt_i     : in    natural range 0 to 4;
    cell_i             : in    std_logic;
    valid_i            : in    std_logic;
    prob_numerator_o   : out   ufixed(7 downto -G_ACCURACY);
    prob_denominator_o : out   ufixed(7 downto -G_ACCURACY);
    valid_o            : out   std_logic
  );

  attribute latency : natural;
  attribute latency of calc_prob : entity is 4;
end entity calc_prob;

architecture synthesis of calc_prob is

  constant C_ADDR_SIZE : natural                    := G_ACCURACY;
  constant C_DATA_SIZE : natural                    := G_ACCURACY;

  pure function energy_loss (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic
  ) return integer is
  begin
    if cell = '1' then
      return -neighbor_cnt;
    else
      return neighbor_cnt;
    end if;
  end function energy_loss;

  pure function number_loss (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic
  ) return integer is
  begin
    if cell = '1' then
      return 1;
    else
      return -1;
    end if;
  end function number_loss;

  -- This calculates:
  -- ln(q) = coef_e * E_loss + coef_n * N_loss.
  -- where E_loss and N_loss is calculated for the swap: cell -> not cell.

  pure function calc_lnq (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic;
    coef_e       : ufixed(3 downto -G_ACCURACY);
    coef_n       : ufixed(3 downto -G_ACCURACY)
  ) return sfixed is
    variable energy_loss_v : integer range -4 to 4;
    variable number_loss_v : integer range -1 to 1;
    variable res_v         : sfixed(8 downto -G_ACCURACY);
    variable res2_v        : sfixed(9 downto -G_ACCURACY);
  begin
    energy_loss_v := energy_loss(neighbor_cnt, cell);
    number_loss_v := number_loss(neighbor_cnt, cell);

    res_v         := to_sfixed(energy_loss_v, 3, 0) * to_sfixed(coef_e);

    if number_loss_v = 1 then
      res2_v := res_v + to_sfixed(coef_n);
    else
      res2_v := res_v - to_sfixed(coef_n);
    end if;

    report "neighbor_cnt=" & to_string(neighbor_cnt) & ", cell=" & to_string(cell) &
           ", energy_loss_v=" & to_string(energy_loss_v) & ", number_loss_v=" & to_string(number_loss_v) &
           " -> " & to_string(to_real(res2_v));

    return res2_v;
  end function calc_lnq;

  signal   lnq       : sfixed(9 downto -G_ACCURACY) := (others => '0');
  signal   lnq_valid : std_logic;

  signal   exp_arg : sfixed(4 downto -G_ACCURACY);
  signal   exp_res : ufixed(7 downto -G_ACCURACY);

begin

  calc_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if valid_i = '1' then
        lnq <= calc_lnq(neighbor_cnt_i,
                        cell_i,
                        coef_e_i,
                        coef_n_i);
      end if;
      lnq_valid <= valid_i;

      if rst_i = '1' then
        lnq_valid <= '0';
      end if;
    end if;
  end process calc_proc;

  exp_arg <= resize(lnq, 4, -G_ACCURACY);

  exp_inst : entity work.exp
    generic map (
      G_ACCURACY => G_ACCURACY
    )
    port map (
      clk_i   => clk_i,
      rst_i   => rst_i,
      valid_i => lnq_valid,
      arg_i   => exp_arg,
      valid_o => valid_o,
      res_o   => exp_res
    ); -- exp_inst : entity work.exp

  prob_numerator_o   <= resize(exp_res, prob_numerator_o);
  prob_denominator_o <= resize(prob_numerator_o + 1, prob_denominator_o);

end architecture synthesis;

