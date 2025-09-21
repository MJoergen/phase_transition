library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

-- This implements the Boltzmann distribution from the Grand canonical ensemble.
-- P(X) = P_0 * exp(-1/T * E(X) + C/T * N(X)).
-- where P(X) is probability of state X, P_0 is some normalization constant,
-- T is temperatur, and C is chemical potential.
-- Furthermore, E(X) is energy and N(X) is particle count of the state.
-- N(x) = 1 for each pixel
-- E(x) = -1 for each pair of adjacent pixels.

-- Typical value T in [0, 1]
-- Typical value C in [-4, 0]

-- C = -T * dS/dN
-- C may be positive or negative.
-- T = 1/(dS/dE)
-- T is always positive.

-- Chosee one pixel at random
-- Decide whether to add or remove a molecule at that pixel.


-- Choose two pixels uniformly at random.
-- If exactly one has a pixel:
-- Possibly swap them.

-- Before swap: X
-- After swap: X'

-- P(X') / P(X) = exp(-c_e * Delta_E + c_n * Delta_N) = q.
-- where c_e = 1/T and c_n = C/T, and
-- Delta_E = E(X') - E(X) and Delta_N = N(X') - N(X).
-- P(X' | X or X') = q/(1+q).


entity calc_prob is
  generic (
    G_ACCURACY : natural
  );
  port (
    clk_i              : in    std_logic;
    rst_i              : in    std_logic;
    coef_e_i           : in    ufixed(-1 downto -G_ACCURACY);
    coef_n_i           : in    ufixed(1 downto -G_ACCURACY);
    neighbor_cnt_i     : in    natural range 0 to 4;
    cell_i             : in    std_logic;
    valid_i            : in    std_logic;
    prob_numerator_o   : out   std_logic_vector(G_ACCURACY - 1 downto 0);
    prob_denominator_o : out   std_logic_vector(G_ACCURACY - 1 downto 0)
  );
end entity calc_prob;

architecture synthesis of calc_prob is

  constant C_ADDR_SIZE : natural := G_ACCURACY;
  constant C_DATA_SIZE : natural := G_ACCURACY;

  pure function energy_gain (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic
  ) return integer is
  begin
    if cell = '0' then
      return -neighbor_cnt;
    else
      return neighbor_cnt;
    end if;
  end function energy_gain;

  pure function number_gain (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic
  ) return integer is
  begin
    if cell = '0' then
      return 1;
    else
      return -1;
    end if;
  end function number_gain;

  pure function calc_lnq (
    neighbor_cnt : natural range 0 to 4;
    cell         : std_logic;
    coef_e       : ufixed(-1 downto -G_ACCURACY);
    coef_n       : ufixed(1 downto -G_ACCURACY)
  ) return sfixed is
    variable energy_gain_v : integer range -4 to 4;
    variable number_gain_v : integer range -1 to 1;
    variable res_v         : sfixed(4 downto -G_ACCURACY);
    variable res2_v        : sfixed(5 downto -G_ACCURACY);
  begin
    energy_gain_v := energy_gain(neighbor_cnt, cell);
    number_gain_v := number_gain(neighbor_cnt, cell);

    res_v         := to_sfixed(energy_gain_v, 3, 0) * to_sfixed(coef_e);

    if number_gain_v = 1 then
      res2_v := res_v + to_sfixed(coef_n);
    else
      res2_v := res_v - to_sfixed(coef_n);
    end if;

    return res2_v;
  end function calc_lnq;

  signal   rom_addr : std_logic_vector(C_ADDR_SIZE - 1 downto 0);
  signal   rom_data : std_logic_vector(C_DATA_SIZE - 1 downto 0);

  signal   lnq : sfixed(5 downto -G_ACCURACY);

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
    end if;
  end process calc_proc;

  rom_addr <= to_stdlogicvector(lnq(4 downto 5 - C_ADDR_SIZE));

  exp_rom_inst : entity work.exp_rom
    generic map (
      G_ADDR_SIZE => C_ADDR_SIZE,
      G_DATA_SIZE => C_DATA_SIZE
    )
    port map (
      clk_i  => clk_i,
      addr_i => rom_addr,
      data_o => rom_data
    ); -- exp_rom_inst : entity work.exp_rom

  prob_numerator_o   <= rom_data;
  prob_denominator_o <= not rom_data;

end architecture synthesis;

