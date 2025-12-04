library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; -- Required for file writing

entity tb_bad_apple is
end tb_bad_apple;

architecture behavior of tb_bad_apple is

    -- Component Declaration for the Unit Under Test (UUT)
    component logic_unit
    port(
        clock : in std_logic;
        reset : in std_logic;
        vga_r : out std_logic_vector(3 downto 0);
        vga_g : out std_logic_vector(3 downto 0);
        vga_b : out std_logic_vector(3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic
    );
    end component;

    -- Inputs
    signal clock : std_logic := '0';
    signal reset : std_logic := '0';

    -- Outputs
    signal vga_r : std_logic_vector(3 downto 0);
    signal vga_g : std_logic_vector(3 downto 0);
    signal vga_b : std_logic_vector(3 downto 0);
    signal vga_hs : std_logic;
    signal vga_vs : std_logic;

    -- Clock period definitions (50 MHz System Clock)
    constant clock_period : time := 20 ns;
    
    -- Pixel Clock (Derived from logic, but we know it is 25 MHz = 40 ns)
    constant pixel_time : time := 40 ns; 

    -- Timing Constants (MUST MATCH YOUR VGA.VHD)
    constant H_BACK : integer := 48;
    constant V_BACK : integer := 33;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: logic_unit PORT MAP (
        clock => clock,
        reset => reset,
        vga_r => vga_r,
        vga_g => vga_g,
        vga_b => vga_b,
        vga_hs => vga_hs,
        vga_vs => vga_vs
    );

    -- Clock process definitions
    clock_process :process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    -- Stimulus and Image Capture Process
    -- Stimulus and Image Capture Process
    stim_proc: process
        file file_pointer : text;
        variable line_el : line;
        variable i, j : integer := 0;
        variable r_int, g_int, b_int : integer;
    begin       
        -- 1. Hold Reset for 100 ns
        reset <= '0'; 
        wait for 100 ns;    
        reset <= '1'; 
        wait for 100 ns;

        report "Rendering 200 Frames...";
        for k in 1 to 200 loop
            -- Wait for the frame to finish (Rising Edge of VSYNC)
            wait until rising_edge(vga_vs);
            report "Finished Frame: " & integer'image(k);
        
            -- Now we are at the start of Frame 91. 
            -- The signals will now contain white data.

            -- 2. Open the output file
            file_open(file_pointer, "frame_" & integer'image(k) & ".ppm", write_mode);

            -- 3. Write PPM Header
            write(line_el, string'("P3"));
            writeline(file_pointer, line_el);
            write(line_el, string'("640 480")); 
            writeline(file_pointer, line_el);
            write(line_el, string'("15")); 
            writeline(file_pointer, line_el);

            -- 4. Sync to the START of the current frame
            -- Since the loop above ended on a rising_edge (VSYNC End),
            -- we are already perfectly positioned at the start of the Back Porch.
            -- We can proceed directly to line skipping.

            -- 5. Skip the Vertical Back Porch lines
            for i in 1 to V_BACK loop
                wait until rising_edge(vga_hs);
            end loop;

            -- 6. Capture Visible Area (480 Lines)
            for y in 0 to 479 loop
                
                -- Wait for HSYNC to end (Start of Back Porch)
                wait until rising_edge(vga_hs);
                
                -- Wait through the Horizontal Back Porch
                wait for H_BACK * pixel_time; 

                -- Capture one line of pixels (640 Pixels)
                for x in 0 to 639 loop
                    -- Sample signals in the middle of the pixel
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