-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
--
-- Description: This module calculates the function 2^x in two clock cycles.
-- * First cycle is a table lookup.
-- * Second cycle is a shift.
-- Both 'arg' and 'res' are in fixed point notation:
-- * 'arg' ranges from [-4; 4[.
-- * 'res' ranges from [0; 16[.
--
-- 'arg' is split into an integer part 'i' and a fractional part 'f', so that 'arg' = 'i' + 'f'.
-- Then 2^arg = 2^i * 2^f. Here multiplying by 2^i is a simple binary shift operation, and 2^f is
-- achieved by a table lookup.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.fixed_float_types.all;
  use ieee.fixed_pkg.all;

entity exp is
  generic (
    G_ACCURACY : natural
  );
  port (
    clk_i   : in    std_logic;
    rst_i   : in    std_logic;
    valid_i : in    std_logic;
    arg_i   : in    sfixed(4 downto -G_ACCURACY);
    valid_o : out   std_logic;
    res_o   : out   ufixed(7 downto -G_ACCURACY)
  );
  attribute latency : natural;
  attribute latency of exp : entity is 3;
end entity exp;

architecture synthesis of exp is

  constant C_LN2_RECIP_REAL : real                    := 1.442695041;

  constant C_LN2_RECIP : sfixed(2 downto -G_ACCURACY) := to_sfixed(C_LN2_RECIP_REAL, 2, -G_ACCURACY);

  signal   ln2_arg       : sfixed(4 downto -G_ACCURACY);
  signal   ln2_arg_valid : std_logic;

  constant C_ADDR_SIZE : natural                      := G_ACCURACY;
  constant C_DATA_SIZE : natural                      := G_ACCURACY;

  signal   shift       : integer range -16 to 15;
  signal   shift_valid : std_logic;

  signal   addr : std_logic_vector(C_ADDR_SIZE - 1 downto 0);
  signal   data : std_logic_vector(C_DATA_SIZE - 1 downto 0);

  subtype  R_MULT_RANGE is natural range sfixed_high(C_LN2_RECIP, '*', arg_i) downto sfixed_low(C_LN2_RECIP, '*', arg_i);

  signal   mult : sfixed(R_MULT_RANGE);

begin

  stage0_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      mult          <= C_LN2_RECIP * arg_i;
      ln2_arg_valid <= valid_i;
    end if;
  end process stage0_proc;

  ln2_arg <= resize(mult, ln2_arg);

  ------------------------------------
  -- First cycle: Table lookup
  -- The address represents a number in the range [0. 1[.
  -- The data represents a number in the range [0, 1[.
  ------------------------------------

  addr    <= to_slv(ln2_arg(-1 downto -G_ACCURACY));

  exp_rom_inst : entity work.exp_rom
    generic map (
      G_ADDR_SIZE => C_ADDR_SIZE,
      G_DATA_SIZE => C_DATA_SIZE
    )
    port map (
      clk_i  => clk_i,
      addr_i => addr,
      data_o => data
    ); -- exp_rom_inst : entity work.exp_rom

  first_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      shift       <= to_integer(signed(ln2_arg(4 downto 0)));
      shift_valid <= ln2_arg_valid;

      if rst_i = '1' then
        shift_valid <= '0';
      end if;
    end if;
  end process first_proc;


  --  report_proc : process (clk_i)
  --  begin
  --    if rising_edge(clk_i) then
  --      if valid_i = '1' then
  --        report "exp: arg=" & to_string(to_real(arg_i)) &
  --               ", ln2_arg=" & to_string(to_real(ln2_arg));
  --      end if;
  --      if valid_o = '1' then
  --        report "exp: res=" & to_string(to_real(res_o));
  --      end if;
  --    end if;
  --  end process report_proc;


  ------------------------------------
  -- Second cycle: Shift
  ------------------------------------

  second_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if shift_valid = '1' then

        case shift is

          when -16 to -9 =>
            res_o <= to_ufixed(0, res_o);

          when -8 =>
            res_o <= to_ufixed("0000000000000001" & data(C_DATA_SIZE - 1 downto 8), res_o);

          when -7 =>
            res_o <= to_ufixed("000000000000001" & data(C_DATA_SIZE - 1 downto 7), res_o);

          when -6 =>
            res_o <= to_ufixed("00000000000001" & data(C_DATA_SIZE - 1 downto 6), res_o);

          when -5 =>
            res_o <= to_ufixed("0000000000001" & data(C_DATA_SIZE - 1 downto 5), res_o);

          when -4 =>
            res_o <= to_ufixed("000000000001" & data(C_DATA_SIZE - 1 downto 4), res_o);

          when -3 =>
            res_o <= to_ufixed("00000000001" & data(C_DATA_SIZE - 1 downto 3), res_o);

          when -2 =>
            res_o <= to_ufixed("0000000001" & data(C_DATA_SIZE - 1 downto 2), res_o);

          when -1 =>
            res_o <= to_ufixed("000000001" & data(C_DATA_SIZE - 1 downto 1), res_o);

          when 0 =>
            res_o <= to_ufixed("00000001" & data, res_o);

          when 1 =>
            res_o <= to_ufixed("0000001" & data & "0", res_o);

          when 2 =>
            res_o <= to_ufixed("000001" & data & "00", res_o);

          when 3 =>
            res_o <= to_ufixed("00001" & data & "000", res_o);

          when 4 =>
            res_o <= to_ufixed("0001" & data & "0000", res_o);

          when 5 =>
            res_o <= to_ufixed("001" & data & "00000", res_o);

          when 6 =>
            res_o <= to_ufixed("01" & data & "000000", res_o);

          when 7 =>
            res_o <= to_ufixed("1" & data & "0000000", res_o);

          when 8 to 15 =>
            res_o <= (others => '1');

          when others =>
            assert false;

        end case;

      end if;
      valid_o <= shift_valid;

      if rst_i = '1' then
        valid_o <= '0';
      end if;
    end if;
  end process second_proc;

end architecture synthesis;

