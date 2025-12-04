library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
    generic (
        H_TOTAL : integer := 800;
        V_TOTAL : integer := 525
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
end entity;

architecture behavior of VGA is
    constant H_VISIBLE : integer := 640;
    constant H_FRONT   : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BACK    : integer := 48;

    constant V_VISIBLE : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BACK    : integer := 33;

    -- H & V Count
    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;
begin

    -- COORDINATE GENERATOR
    process(clock_in, reset_n) 
    begin
            if (reset_n = '0') then              --reset asserted
                h_count <= 0;                    --reset horizontal counter
                v_count <= 0;                    --reset vertical counter
            elsif rising_edge(clock_in) then
                IF(h_count < H_TOTAL - 1) THEN      --horizontal counter (pixels)
                    h_count <= h_count + 1;
                ELSE
                    h_count <= 0;
                    IF(v_count < V_TOTAL - 1) THEN  --veritcal counter (rows)
                        v_count <= v_count + 1;
                    ELSE
                        v_count <= 0;
                    END IF;
                END IF;
            end if;
    end process;

    -- SYNC PULSE
    h_output <= '0' when (h_count >= (H_VISIBLE + H_FRONT)) and
                        (h_count < (H_VISIBLE + H_FRONT + H_SYNC)) else '1';
    
    v_output <= '0' when (v_count >= (V_VISIBLE + V_FRONT)) and
                        (v_count < (V_VISIBLE + V_FRONT + V_SYNC)) else '1';

    -- Coordinates
    x_out <= h_count;
    y_out <= v_count;

    -- VIDEO ON
    video_on <= '1' when (h_count < H_VISIBLE) and (v_count < V_VISIBLE) else '0';
    
end behavior;

