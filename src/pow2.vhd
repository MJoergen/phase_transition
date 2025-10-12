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

entity pow2 is
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
  attribute latency of pow2 : entity is 2;
end entity pow2;

architecture synthesis of pow2 is

  constant C_ADDR_SIZE : natural                      := G_ACCURACY;
  constant C_DATA_SIZE : natural                      := G_ACCURACY;

  signal   shift       : integer range -16 to 15;
  signal   shift_valid : std_logic;

  signal   addr : std_logic_vector(C_ADDR_SIZE - 1 downto 0);
  signal   data : std_logic_vector(C_DATA_SIZE - 1 downto 0);

begin

  ------------------------------------
  -- First cycle: Table lookup
  -- The address represents a number in the range [0. 1[.
  -- The data represents a number in the range [0, 1[.
  ------------------------------------

  addr    <= to_slv(arg_i(-1 downto -G_ACCURACY));

  pow2_rom_inst : entity work.pow2_rom
    generic map (
      G_ADDR_SIZE => C_ADDR_SIZE,
      G_DATA_SIZE => C_DATA_SIZE
    )
    port map (
      clk_i  => clk_i,
      addr_i => addr,
      data_o => data
    ); -- pow2_rom_inst : entity work.pow2_rom

  first_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      shift       <= to_integer(signed(arg_i(4 downto 0)));
      shift_valid <= valid_i;

      if rst_i = '1' then
        shift_valid <= '0';
      end if;
    end if;
  end process first_proc;


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

