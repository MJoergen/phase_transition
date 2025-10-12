-- Author:  Michael Jørgensen
-- License: Public domain; do with it what you like :-)
--
-- Description: This module performs a table lookup to calculate the
-- function 2^x.
--
-- The address represents a number in the range [0, 1[.
-- The data represents a number in the range [0, 1[.
--
-- The input is interpreted as a value between 0 and 1.
-- The output is a value between 0 and 1.
--
-- The actual function calculated is y = 2^x - 1.
--
-- Latency is 1 clock cycle.

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
  use ieee.math_real.all;

entity pow2_rom is
  generic (
    G_ADDR_SIZE : natural;
    G_DATA_SIZE : natural
  );
  port (
    clk_i  : in    std_logic;
    addr_i : in    std_logic_vector(G_ADDR_SIZE - 1 downto 0);
    data_o : out   std_logic_vector(G_DATA_SIZE - 1 downto 0)
  );
  attribute latency : natural;
  attribute latency of pow2_rom : entity is 1;
end entity pow2_rom;

architecture synthesis of pow2_rom is

  constant C_SCALE_X : natural := 2 ** G_ADDR_SIZE;
  constant C_SCALE_Y : natural := 2 ** G_DATA_SIZE;

  type     mem_type is array (0 to C_SCALE_X - 1) of std_logic_vector(G_DATA_SIZE - 1 downto 0);

  impure function initrom return mem_type is
    variable x_v   : real;
    variable y_v   : real;
    variable int_v : integer;
    variable rom_v : mem_type;
  begin
    --
    for i in 0 to C_SCALE_X - 1 loop
      x_v      := real(i) / real(C_SCALE_X);
      y_v      := exp(x_v * log(2.0)) - 1.0;
      int_v    := integer(floor(y_v * real(C_SCALE_Y))); -- Rounding is automatic.
      rom_v(i) := to_stdlogicvector(int_v, G_DATA_SIZE);
    end loop;

    return rom_v;
  end function initrom;

  signal   mem : mem_type      := initrom;

begin

  -- Read from ROM
  read_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      data_o <= mem(to_integer(addr_i));
    end if;
  end process read_proc;

end architecture synthesis;

