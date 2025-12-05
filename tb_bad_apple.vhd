library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_bad_apple is
end tb_bad_apple;

architecture behavior of tb_bad_apple is

    -- Component Declaration for the Unit Under Test (UUT)
    component logic_unit
    generic (
        H_TOTAL : integer := 800;
        V_TOTAL : integer := 525
    );
    port(
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
    end component;

    component image_rom
    generic (
        FILENAME : string;
        WORDS    : integer
    );
    port (
        clk         : in  std_logic;
        address     : in  std_logic_vector(21 downto 0);
        data_out    : out std_logic_vector(11 downto 0)
    );
    end component;
    
    signal clock            : std_logic := '0';
    signal reset            : std_logic := '0';
    signal mem_data_in      : std_logic_vector(11 downto 0) := (others => '0');
    signal mem_address_out  : std_logic_vector(21 downto 0);
    signal vga_r            : std_logic_vector(3 downto 0);
    signal vga_g            : std_logic_vector(3 downto 0);
    signal vga_b            : std_logic_vector(3 downto 0);
    signal vga_hs           : std_logic;
    signal vga_vs           : std_logic;

    constant clock_period   : time    := 20 ns;
    constant pixel_time     : time    := 40 ns; 
    constant H_RES          : integer := 640;
    constant V_RES          : integer := 480;
    constant H_BACK         : integer := 48;
    constant V_BACK         : integer := 33;
    constant MAX_FRAME      : integer := 1000;
    constant FILE_LOCATION  : string  := "C:/Users/Jesaya/Documents/PSd/image_data.hex"; -- Change to the appropriate file location
    constant ROM_WORDS : integer := (H_RES / 10) * (V_RES / 10) * MAX_FRAME; -- 640 * 480

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: logic_unit 
    PORT MAP (
        clock           => clock,
        reset           => reset,
        mem_address_out => mem_address_out,
        mem_data_in     => mem_data_in,
        vga_r           => vga_r,
        vga_g           => vga_g,
        vga_b           => vga_b,
        vga_hs          => vga_hs,
        vga_vs          => vga_vs,
        max_frame       => MAX_FRAME
    );

    -- Clock process definitions
    clock_process :process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    -- Memory Moving
    rom_inst: image_rom 
    generic map (
        FILENAME => FILE_LOCATION,
        WORDS    => ROM_WORDS
    )
    PORT MAP (
        clk         => clock,
        address     => mem_address_out,
        data_out    => mem_data_in
    );

    -- Capture Process
    capture: process
        file file_pointer : text;
        variable line_el : line;
        variable i, j : integer := 0;
        variable r_int, g_int, b_int : integer;
    begin       
        -- Hold Reset for 100 ns
        reset <= '0'; 
        wait for 100 ns;    
        reset <= '1'; 
        wait for 100 ns;

        report "Rendering 1000 Frames...";
        for k in 1 to MAX_FRAME loop
            wait until rising_edge(vga_vs);
            report "Finished Frame: " & integer'image(k);

            -- Open output
            file_open(file_pointer, "frame_" & integer'image(k) & ".ppm", write_mode);

            -- Write PPM Header
            write(line_el, string'("P3"));
            writeline(file_pointer, line_el);
            write(line_el, string'("640 480")); 
            writeline(file_pointer, line_el);
            write(line_el, string'("15")); 
            writeline(file_pointer, line_el);

            for i in 1 to V_BACK loop
                wait until rising_edge(vga_hs);
            end loop;

            -- Capture 480 Lines
            for y in 0 to V_RES - 1 loop
                
                -- Wait for HSYNC to end (Start of Back Porch)
                wait until rising_edge(vga_hs);
                -- Wait through the Horizontal Back Porch
                wait for H_BACK * pixel_time; 

                -- Capture 640 Pixels
                for x in 0 to H_RES - 1 loop
                    wait for pixel_time / 2;
                    
                    r_int := to_integer(unsigned(vga_r));
                    g_int := to_integer(unsigned(vga_g));
                    b_int := to_integer(unsigned(vga_b));
                    
                    write(line_el, integer'image(r_int) & " " & integer'image(g_int) & " " & integer'image(b_int) & "  ");
                    
                    wait for pixel_time / 2;
                end loop;
                
                writeline(file_pointer, line_el);
                
            end loop;

            -- Close file and stop simulation
            file_close(file_pointer);
            report "Image Generation Complete! Frame " & integer'image(k) & " captured.";
        end loop;
        
        wait;
        
    end process;

end behavior;
