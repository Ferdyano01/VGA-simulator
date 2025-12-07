import cv2
import sys

# ================= CONFIGURATION =================
INPUT_VIDEO = 'bad-apple.mp4'  # Can be ANY video file
OUTPUT_FILE = 'image_data.hex' 
WIDTH       = 64               # Locked to 64 to match VHDL 10x upscaler
HEIGHT      = 48               # Locked to 48 to match VHDL 10x upscaler

# FLEXIBILITY SETTINGS
START_FRAME = 0                # Skip intro if needed (e.g., 200)
MAX_FRAMES  = 1000              # Set to None to capture WHOLE video
# =================================================

def main():
    cap = cv2.VideoCapture(INPUT_VIDEO)
    
    if not cap.isOpened():
        print(f"Error: Could not open {INPUT_VIDEO}")
        return

    # 1. Total available frames in video
    total_video_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    # 2. Determine how many frames we actually want to process
    if MAX_FRAMES is None:
        frames_to_process = total_video_frames - START_FRAME
    else:
        frames_to_process = min(MAX_FRAMES, total_video_frames - START_FRAME)

    print(f"Video Length: {total_video_frames} frames")
    print(f"Processing:   {frames_to_process} frames (starting at {START_FRAME})")
    print(f"Target Res:   {WIDTH}x{HEIGHT}")
    print(f"Output:       12-bit RGB (RRR GGG BBB)")
    
    # Move to start frame
    cap.set(cv2.CAP_PROP_POS_FRAMES, START_FRAME)
    
    with open(OUTPUT_FILE, 'w') as f:
        count = 0
        while count < frames_to_process:
            ret, frame = cap.read()
            if not ret:
                break
            
            # 1. RESIZE: Scale down to the FPGA's native grid (64x48)
            frame_resized = cv2.resize(frame, (WIDTH, HEIGHT))
            
            # 2. COLOR CORRECTION: Convert BGR (OpenCV default) to RGB
            frame_rgb = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2RGB)
            
            # 3. WRITE HEX DATA
            for y in range(HEIGHT):
                for x in range(WIDTH):
                    # Get the 8-bit color values (0-255)
                    r, g, b = frame_rgb[y, x]
                    
                    # Downsample to 4-bit (0-15) by shifting right 4 times
                    r_4bit = r >> 4
                    g_4bit = g >> 4
                    b_4bit = b >> 4
                    
                    # Pack into 12-bit integer: RRRR GGGG BBBB
                    hex_12bit_color = f"{r_4bit:X}{g_4bit:X}{b_4bit:X}"
                    
                    # Write as 3-digit Hex (e.g., F0A)
                    f.write(f"{hex_12bit_color}\n")
            
            count += 1
            if count % 100 == 0:
                print(f"Processed {count}/{frames_to_process} frames...")

    cap.release()
    print("------------------------------------------------")
    print(f"Done! {OUTPUT_FILE} created.")
    print(f"Total Lines: {count * WIDTH * HEIGHT}")
    print("------------------------------------------------")

if __name__ == "__main__":
    main()