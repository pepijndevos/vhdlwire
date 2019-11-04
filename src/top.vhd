library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    sys_clk : in std_logic;
    rst_n : in std_logic;
    rx : in std_logic;
    tx : out std_logic;
    rf_in : in std_logic;
    ledr_n : out std_logic;
    ledg_n : out std_logic
  );
end top;

architecture behavior of top is
  signal output : std_logic_vector(7 downto 0);
  signal output_ready : std_logic;
  signal dbgw : std_logic_vector(7 downto 0);
  signal tx_busy : std_logic;
begin

  LEDG_N <= not rf_in;
  LEDR_N <= not output_ready;

  serial: entity work.uart generic map (
    clk_freq => 12_000_000,
    baud_rate => 9600
  ) port map (
    clk => sys_clk,
    reset_n => rst_n,
		tx_ena => output_ready,
		tx_data => output,
		rx => rx,
		rx_busy => open,
		rx_error => open,
		rx_data => open,
		tx_busy => tx_busy,
		tx => tx
  );

  rcv: entity work.askrcv generic map (
    divider => 750
  ) port map (
    clk => sys_clk,
    rst_n => rst_n,
    input => rf_in,
    output => output,
    output_ready => output_ready,
    new_frame => open
  );

end;
