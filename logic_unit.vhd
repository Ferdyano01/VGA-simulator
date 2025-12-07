library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity logic_unit is
    generic (
        H_TOTAL : integer := 800;
        V_TOTAL : integer := 525
    );
    port (
        clock           : in std_logic;
        reset           : in std_logic;

        mem_address_out : out std_logic_vector(21 downto 0);
        mem_data_in     : in std_logic_vector(11 downto 0);

        vga_r           : out std_logic_vector(3 downto 0);
        vga_g           : out std_logic_vector(3 downto 0);
        vga_b           : out std_logic_vector(3 downto 0);
        vga_hs          : out std_logic;
        vga_vs          : out std_logic;
        max_frame       : in integer
    );
end entity;

architecture Behavioral of logic_unit is

    signal pixel_clk : std_logic := '0';
    signal x_pos    : integer range 0 to H_TOTAL - 1;
    signal y_pos    : integer range 0 to V_TOTAL - 1;
    signal video_on : std_logic;
    signal v_sync   : std_logic;
    signal rgb_data : std_logic_vector(11 downto 0);

    signal current_frame : integer := 0;

    component VGA is 
    generic (
        H_TOTAL : integer := H_TOTAL;
        V_TOTAL : integer := V_TOTAL
    );
        port (
            clock_in : in std_logic;
            reset_n  : in std_logic;
            h_output : out std_logic;
            v_output : out std_logic;
            x_out    : out integer range 0 to H_TOTAL - 1;
            y_out    : out integer range 0 to V_TOTAL - 1;
            video_on : out std_logic
        );
    end component;

    component Video_Controller is
        port (
            pixel_clk       : in std_logic;
            reset           : in std_logic;
            x_pos           : in integer;
            y_pos           : in integer;
            video_on        : in std_logic;
            current_frame   : in integer;
            mem_address_out : out std_logic_vector(21 downto 0);
            mem_data_in     : in  std_logic_vector(11 downto 0);
            rgb_out         : out std_logic_vector(11 downto 0)
        );
    end component;

begin

    -- Clock Divider
    process(clock)
    begin
        if rising_edge(clock) then
            pixel_clk <= not pixel_clk;
        end if;
    end process;

    -- VGA
    vga_inst : VGA
    port map (
        clock_in => pixel_clk,
        reset_n  => reset,
        h_output => VGA_HS,
        v_output => v_sync,
        x_out    => x_pos, 
        y_out    => y_pos,
        video_on => video_on
    );

    vga_vs <= v_sync;

    -- Video Controller
    video_controller_inst : Video_Controller
    port map (
        pixel_clk       => pixel_clk,
        reset           => reset,
        x_pos           => x_pos,
        y_pos           => y_pos,
        video_on        => video_on,
        current_frame   => current_frame,
        mem_address_out => mem_address_out,
        mem_data_in     => mem_data_in,
        rgb_out         => rgb_data
    );

    vga_r <= rgb_data(11 downto 8);
    vga_g <= rgb_data(7 downto 4);
    vga_b <= rgb_data(3 downto 0);

    -- Frame Counter
    process(v_sync, reset)
    begin
        if reset = '0' then
            current_frame <= 0;
        elsif rising_edge(v_sync) then
            if current_frame < MAX_FRAME - 1 then
                current_frame <= current_frame + 1;
            else
                current_frame <= 0;
            end if;
        end if;
    end process;

end Behavioral;