#!/usr/bin/env python3
"""
Sprite Atlas Generator for Tamagotchi watchOS

Generates Xcode Asset Catalog structure from PNG frame files.
"""

import json
import shutil
import sys
from pathlib import Path

# Animation states and expected frame counts
ANIMATION_STATES = {
    "idle": 4,
    "happy": 4,
    "eating": 5,
    "sleeping": 2,
    "sad": 3,
    "dead": 1,
    "bounce": 5,
}

CHARACTER_NAME = "cat"
SPRITES_DIR = Path("ios/watch/Tamagotchi/Resources/Sprites")
ASSETS_DIR = Path("ios/watch/Tamagotchi/Resources/Assets.xcassets")


def validate_sprites():
    """Check all required frames exist."""
    missing = []
    
    for state, count in ANIMATION_STATES.items():
        state_dir = SPRITES_DIR / state
        if not state_dir.exists():
            missing.append(f"Directory missing: {state_dir}")
            continue
            
        for i in range(1, count + 1):
            filename = f"{CHARACTER_NAME}_{state}_{i}.png"
            filepath = state_dir / filename
            if not filepath.exists():
                missing.append(f"Frame missing: {filepath}")
    
    if missing:
        print("❌ Validation failed:")
        for m in missing:
            print(f"  - {m}")
        return False
    
    print(f"✅ All {sum(ANIMATION_STATES.values())} frames validated")
    return True


def generate_image_set(frame_path: Path, output_dir: Path):
    """Create an image set for a single frame."""
    image_name = frame_path.stem
    image_set_dir = output_dir / f"{image_name}.imageset"
    image_set_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy PNG file
    shutil.copy2(frame_path, image_set_dir / frame_path.name)
    
    # Create Contents.json
    contents = {
        "images": [
            {
                "filename": frame_path.name,
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    with open(image_set_dir / "Contents.json", "w") as f:
        json.dump(contents, f, indent=2)


def generate_atlas():
    """Generate complete asset catalog from sprite folders."""
    print("🎨 Generating sprite atlas...\n")
    
    if not validate_sprites():
        sys.exit(1)
    
    # Create/ensure Assets.xcassets exists
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Process each animation state
    total_frames = 0
    for state, count in ANIMATION_STATES.items():
        state_dir = SPRITES_DIR / state
        if not state_dir.exists():
            continue
            
        print(f"📁 Processing {state}/ ({count} frames)")
        
        for i in range(1, count + 1):
            filename = f"{CHARACTER_NAME}_{state}_{i}.png"
            frame_path = state_dir / filename
            
            if frame_path.exists():
                generate_image_set(frame_path, ASSETS_DIR)
                total_frames += 1
    
    print(f"\n✅ Generated {total_frames} image sets in {ASSETS_DIR}")
    print("\nNext steps:")
    print("  1. Open ios/Tamagotchi.xcodeproj")
    print("  2. Build and run on watchOS simulator")


def create_placeholder_frames():
    """Create simple placeholder frames using PIL."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("❌ PIL not installed. Run: pip3 install Pillow")
        sys.exit(1)
    
    print("🎨 Creating placeholder frames...\n")
    
    for state, count in ANIMATION_STATES.items():
        state_dir = SPRITES_DIR / state
        state_dir.mkdir(parents=True, exist_ok=True)
        
        for i in range(1, count + 1):
            # Create simple colored square with text
            img = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
            draw = ImageDraw.Draw(img)
            
            # Different colors for different states
            colors = {
                "idle": (255, 200, 100),
                "happy": (255, 255, 100),
                "eating": (255, 150, 100),
                "sleeping": (150, 150, 255),
                "sad": (150, 150, 150),
                "dead": (100, 100, 100),
                "bounce": (255, 200, 100),
            }
            color = colors.get(state, (200, 200, 200))
            
            # Draw simple shape
            offset = (i - 1) * 4
            draw.rectangle([8 + offset, 16, 40 + offset, 40], fill=color + (255,))
            
            # Save
            filename = f"{CHARACTER_NAME}_{state}_{i}.png"
            filepath = state_dir / filename
            img.save(filepath)
    
    print(f"✅ Created placeholder frames in {SPRITES_DIR}")
    print("   Replace these with your actual pixel art sprites!")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Sprite atlas generator")
    parser.add_argument("--placeholders", action="store_true", 
                        help="Create placeholder frames")
    
    args = parser.parse_args()
    
    if args.placeholders:
        create_placeholder_frames()
    
    generate_atlas()
