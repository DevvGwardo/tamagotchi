# Sprite Asset Pipeline

> For OpenClaw integration docs, see [OPENCLAW.md](./OPENCLAW.md).

## Overview

The Tamagotchi watchOS app supports two rendering modes:
1. **Sprite Assets** — PNG frame sequences (preferred for itch.io assets)
2. **Canvas Fallback** — Programmatic pixel art (works without assets)

## Asset Structure

```
ios/watch/Tamagotchi/Resources/
├── Sprites/                    # Source PNG frames (not in Xcode project)
│   ├── idle/
│   │   ├── cat_idle_1.png
│   │   ├── cat_idle_2.png
│   │   └── ...
│   ├── happy/
│   ├── eating/
│   ├── sleeping/
│   ├── sad/
│   └── dead/
└── Assets.xcassets/            # Generated image sets
    ├── cat_idle_1.imageset/
    ├── cat_idle_2.imageset/
    └── ...
```

## Frame Specifications

| Property | Recommendation |
|----------|----------------|
| Size | 48×48 pixels |
| Format | PNG with transparency |
| Color Profile | sRGB |
| Scale | 1x (watch uses 1x assets) |

## Animation States

Each state has a specific frame count and timing:

| State | Frames | FPS | Loops |
|-------|--------|-----|-------|
| idle | 4 | 3 | ✅ |
| happy | 4 | 6 | ✅ |
| eating | 5 | 8 | ❌ |
| sleeping | 2 | 1.25 | ✅ |
| sad | 3 | 2 | ✅ |
| dead | 1 | — | ❌ |
| bounce | 5 | 12 | ❌ |

## Naming Convention

Files must follow: `{character}_{state}_{frame}.png`

Examples:
- `cat_idle_1.png`
- `cat_idle_2.png`
- `cat_happy_1.png`
- `cat_dead_1.png`

## From Itch.io to Xcode

### 1. Download/Export Sprites

From Aseprite:
1. File → Export Sprite Sheet
2. Select "By Rows" or "By Columns"
3. Set frame size to 48×48
4. Export as individual PNGs

From Photoshop:
1. File → Export → Layers to Files
2. Select PNG-24 with transparency
3. Rename files to match convention

### 2. Organize Files

```bash
cd ios/watch/Tamagotchi/Resources/Sprites
mkdir idle happy eating sleeping sad dead
mv ~/Downloads/cat_idle_* ./idle/
mv ~/Downloads/cat_happy_* ./happy/
# ... etc
```

### 3. Generate Asset Catalog

```bash
cd ~/Projects/tamagotchi
python3 ios/scripts/generate-atlas.py
```

This script:
- Validates all required frames exist
- Generates Assets.xcassets structure
- Creates Contents.json for each image set
- Moves files into Xcode asset catalog

### 4. Build and Test

```bash
cd ios
xcodegen generate
xcodebuild -target Tamagotchi-Watch -sdk watchsimulator26.2 build
```

## Creating Custom Characters

1. Design 48×48 pixel character
2. Create animation frames for each state
3. Follow naming convention: `mycharacter_idle_1.png`
4. Update `SpriteAnimation` definitions to use your prefix

## Troubleshooting

**Assets not showing:**
- Check filename spelling (case-sensitive)
- Verify PNG format (not JPG)
- Ensure transparency exists
- Run generate-atlas.py after adding files

**Animation glitches:**
- Verify all frames same dimensions
- Check frame counts match SpriteAnimation definitions
- Ensure no duplicate frame numbers

**Memory issues:**
- Reduce frame count for complex animations
- Use simpler color palettes
- Consider using sprite atlases (single image)
