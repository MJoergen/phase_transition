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
    clk_i : in    std_logic;
    arg_i : in    sfixed(2 downto -G_ACCURACY);
    res_o : out   ufixed(3 downto -G_ACCURACY)
  );
end entity exp;

architecture synthesis of exp is

  constant C_ADDR_SIZE : natural := G_ACCURACY;
  constant C_DATA_SIZE : natural := G_ACCURACY;

  signal   shift : integer range -4 to 3;

  signal   addr : std_logic_vector(C_ADDR_SIZE - 1 downto 0);
  signal   data : std_logic_vector(C_DATA_SIZE - 1 downto 0);

begin

  ------------------------------------
  -- First cycle: Table lookup
  -- The address represents a number in the range [0. 1[.
  -- The data represents a number in the range [0, 1[.
  ------------------------------------

  addr <= to_slv(arg_i(-1 downto -G_ACCURACY));

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
      shift <= to_integer(signed(arg_i(2 downto 0)));
    end if;
  end process first_proc;


  ------------------------------------
  -- Second cycle: Shift
  ------------------------------------

  second_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then

      case shift is

        when -4 =>
          res_o <= to_ufixed("00000001" & data(C_DATA_SIZE-1 downto 4), res_o);

        when -3 =>
          res_o <= to_ufixed("0000001" & data(C_DATA_SIZE-1 downto 3), res_o);

        when -2 =>
          res_o <= to_ufixed("000001" & data(C_DATA_SIZE-1 downto 2), res_o);

        when -1 =>
          res_o <= to_ufixed("00001" & data(C_DATA_SIZE-1 downto 1), res_o);

        when 0 =>
          res_o <= to_ufixed("0001" & data, res_o);

        when 1 =>
          res_o <= to_ufixed("001" & data & "0", res_o);

        when 2 =>
          res_o <= to_ufixed("01" & data & "00", res_o);

        when 3 =>
          res_o <= to_ufixed("1" & data & "000", res_o);

        when others =>
          assert false;

      end case;

    end if;
  end process second_proc;

end architecture synthesis;

