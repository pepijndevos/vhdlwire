library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    xtal_in : in std_logic;
    rst_n : in std_logic;
    key : in std_logic;
    rf_in : in std_logic;
    lcd_clk : out std_logic;
    lcd_hsync : out std_logic;
    lcd_vsync : out std_logic;
    lcd_den : out std_logic;
    lcd_r : out std_logic_vector(4 downto 0);
    lcd_g : out std_logic_vector(5 downto 0);
    lcd_b : out std_logic_vector(4 downto 0);
    led_r : out std_logic;
    led_g : out std_logic;
    led_b : out std_logic;
    rx : in std_logic;
    tx : out std_logic
  );
end top;

architecture behavior of top is
  signal clk_200 : std_logic;
  signal clk_33 : std_logic;
  signal packet_byte : std_logic_vector(7 downto 0);
  signal packet_byte_ready : std_logic;
  signal output : std_logic_vector(7 downto 0);
  signal output_ready : std_logic;
  signal new_frame : std_logic;
  signal rdaddress : std_logic_vector(10 downto 0);
  signal wraddress : std_logic_vector(10 downto 0);
  signal char : std_logic_vector(7 downto 0);
  signal pixel : std_logic;
  signal tx_busy : std_logic;

component Gowin_PLL
    port (
        clkout: out std_logic;
        clkoutd: out std_logic;
        clkin: in std_logic
    );
end component;

component bram
  port (
      clk : in std_logic;
      wren : in std_logic;
      oen : in std_logic;
      rdaddress : in std_logic_vector(10 downto 0);
      wraddress : in std_logic_vector(10 downto 0);
      data_in : in std_logic_vector(7 downto 0);
      data_out : out std_logic_vector(7 downto 0)
);
end component;


begin

mypll: Gowin_PLL port map (
        clkout => clk_200,
        clkoutd => clk_33,
        clkin => xtal_in
);

lcd_clk <= clk_33;

--led_r <= '1';
led_g <= not tx_busy;
led_b <= '1';

  serial: entity work.uart generic map (
    clk_freq => 33_300_000,
    baud_rate => 9600
  ) port map (
    clk => clk_33,
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

  disp: entity work.display port map (
    clk => clk_33,
    rst_n => rst_n,
    h_sync => lcd_hsync,
    v_sync => lcd_vsync,
    char => char,
    vramaddress => rdaddress,
    disp_ena => lcd_den,
    pixel => pixel
  );

  lcd_r <= (others => pixel);
  lcd_g <= (others => pixel);
  lcd_b <= (others => pixel);

  rcv: entity work.askrcv generic map (
    divider => 2081
  ) port map (
    clk => clk_33,
    rst_n => rst_n,
    input => rf_in,
    output => packet_byte,
    output_ready => packet_byte_ready,
    new_frame => new_frame
  );

  unpack: entity work.askunpack port map (
    clk => clk_33,
    rst_n => rst_n,
    input => packet_byte,
    input_ready => packet_byte_ready,
    new_frame => new_frame,
    output => output,
    output_ready => output_ready
  );

  mem: bram port map (
    clk => clk_33,
    wren => output_ready,
    oen => '1',
    rdaddress => rdaddress,
    wraddress => wraddress,
    data_in => output,
    data_out => char
  );

  process(clk_33, rst_n)
  begin
    if rising_edge(clk_33) then
      if rst_n = '0' or unsigned(wraddress) >= 1500 then
        wraddress <= (others => '0');
        led_r <= '1';
      elsif output_ready = '1' then
        wraddress <= std_logic_vector(unsigned(wraddress) + 1);
        led_r <= not led_r;
      end if;
    end if;
  end process;

end;
