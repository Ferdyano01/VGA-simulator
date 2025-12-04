import cv2
import sys

# ================= CONFIGURATION =================
# Input video filename
VIDEO_FILE = 'bad_apple.mp4' 

# Output COE filename
OUTPUT_FILE = 'video_memory.coe'

# Target Resolution (Must be small to fit in FPGA Block RAM!)
RESIZE_WIDTH = 64
RESIZE_HEIGHT = 48

# Threshold for Black/White (0-255). 
# Pixels brighter than this become 1, darker become 0.
THRESHOLD_VAL = 127

# Limit frames to prevent file from getting too huge
# Set to None to process the whole video
MAX_FRAMES = 200 
# =================================================

def generate_coe():
    # 1. Open the video file
    cap = cv2.VideoCapture(VIDEO_FILE)
    
    if not cap.isOpened():
        print(f"Error: Could not open video file {VIDEO_FILE}")
        sys.exit()

    # Calculate total expected memory depth
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    if MAX_FRAMES is not None and total_frames > MAX_FRAMES:
        total_frames = MAX_FRAMES
        
    depth = total_frames * RESIZE_WIDTH * RESIZE_HEIGHT
    
    print(f"Processing Video...")
    print(f"Target Resolution: {RESIZE_WIDTH}x{RESIZE_HEIGHT}")
    print(f"Total Frames to process: {total_frames}")
    print(f"Total Bits (Depth): {depth}")

    try:
        with open(OUTPUT_FILE, 'w') as f:
            # 2. Write the COE Header
            # radix=2 means the data is in Binary (0s and 1s)
            f.write("memory_initialization_radix=2;\n")
            f.write("memory_initialization_vector=\n")

            frame_count = 0
            pixels_written = 0

            while True:
                ret, frame = cap.read()
                
                # Stop if video ends or we hit the frame limit
                if not ret or (MAX_FRAMES is not None and frame_count >= MAX_FRAMES):
                    break

                # 3. Process the Frame
                # Resize to target resolution
                frame_resized = cv2.resize(frame, (RESIZE_WIDTH, RESIZE_HEIGHT))
                
                # Convert to Grayscale
                gray = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2GRAY)
                
                # Apply Binary Threshold (Black and White only)
                _, binary = cv2.threshold(gray, THRESHOLD_VAL, 255, cv2.THRESH_BINARY)

                # Optional: Show preview window
                cv2.imshow('FPGA Preview', binary)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

                # 4. Write data to file
                for y in range(RESIZE_HEIGHT):
                    for x in range(RESIZE_WIDTH):
                        # Get pixel value
                        pixel_val = binary[y, x]
                        
                        # Convert to 1-bit
                        bit_val = 1 if pixel_val > 128 else 0
                        
                        pixels_written += 1

                        # COE Logic: Use comma for all items except the very last one
                        if pixels_written < depth:
                            f.write(f"{bit_val},\n")
                        else:
                            f.write(f"{bit_val};\n") # End with semicolon

                frame_count += 1
                if frame_count % 50 == 0:
                    print(f"Processed {frame_count} frames...")

            print(f"Done! Saved to {OUTPUT_FILE}")
            print(f"Total Pixels Written: {pixels_written}")

    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cap.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    generate_coe()