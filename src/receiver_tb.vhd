library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end tb;

architecture behavior of tb is
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal input : std_logic := '0';

  procedure write (
    i_data_in       : in  std_logic_vector(11 downto 0);
    signal o_serial : out std_logic) is
  begin
    for ii in 0 to 11 loop
      for jj in 0 to 7 loop
        o_serial <= i_data_in(ii);
        wait for 40 ns;
      end loop; -- jj
    end loop;  -- ii
  end write;

begin
  clk <= not clk after 20 ns;
  rst_n <= '1' after 40 ns;

  dut: entity work.askrcv port map (
    clk => clk,
    rst_n => rst_n,
    input => input
  );

  process is
  begin
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    write(x"aaa", input);
    write(x"b38", input);
    write("010101001101", input);
    write("001110001101", input);
    write("010011001101", input);
    write("010101001101", input);
    write(x"aaa", input);
    write(x"b38", input);
    write("010110001101", input);
    write("001110001101", input);
    write("010011001101", input);
    write("010101001101", input);
    write("110100110100", input);
    write(x"aaa", input);
    assert false report "Tests Complete" severity failure;
  end process;

end;
