import cv2
import os
import glob

def make_video():
    # 1. Configuration
    image_folder = '.' # Current directory
    video_name = 'simulated_video.mp4'
    fps = 60 # Match your VGA refresh rate
    
    # 2. Find all PPM files
    # We sort them by the number in the filename so frame_2 comes after frame_1
    images = [img for img in os.listdir(image_folder) if img.endswith(".ppm")]
    
    # Sort files numerically (frame_1, frame_2, ... frame_10)
    # Otherwise frame_10 comes before frame_2 in standard sorting
    images.sort(key=lambda f: int(''.join(filter(str.isdigit, f))))

    if not images:
        print("No PPM files found!")
        return

    # 3. Read the first image to get dimensions
    frame = cv2.imread(os.path.join(image_folder, images[0]))
    height, width, layers = frame.shape

    # 4. Initialize Video Writer
    # 'mp4v' is a standard codec for MP4
    fourcc = cv2.VideoWriter_fourcc(*'mp4v') 
    video = cv2.VideoWriter(video_name, fourcc, fps, (width, height))

    print(f"Found {len(images)} frames. Stitching video...")

    # 5. Loop through images and add to video
    for image in images:
        img_path = os.path.join(image_folder, image)
        frame = cv2.imread(img_path)
        video.write(frame)

    # 6. Save and Release
    video.release()
    cv2.destroyAllWindows()
    print(f"Done! Saved as {video_name}")

if __name__ == "__main__":
    make_video()