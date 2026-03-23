# Watercolor Sky Backgrounds Guide

## Required PNG Files

Place these files in `resources/` folder:

### Sky Backgrounds (8 times of day)
```
resources/
├── sky-dawn.png          # Deep blue with purple hints
├── sky-sunrise.png       # Orange, pink, yellow (with lens flare)
├── sky-morning.png       # Bright blue, white clouds
├── sky-midday.png        # Bright clear sky (with lens flare)
├── sky-afternoon.png     # Softer blue, golden tones
├── sky-sunset.png        # Orange, red, purple (with lens flare)
├── sky-dusk.png          # Deep purple, pink
└── sky-night.png         # Dark blue, stars
```

### Path (ground under house)
```
resources/
└── path-watercolor-brown.png  # Pale brown watercolor texture
```

### Optional: Lens Flare Overlays (for more realistic effects)
```
resources/
├── lens-flare-sunrise.png
├── lens-flare-midday.png
└── lens-flare-sunset.png
```

## Update pubspec.yaml

Add all assets:

```yaml
flutter:
  assets:
    - .env
    - resources/home-art-bg.png
    # Sky backgrounds
    - resources/sky-dawn.png
    - resources/sky-sunrise.png
    - resources/sky-morning.png
    - resources/sky-midday.png
    - resources/sky-afternoon.png
    - resources/sky-sunset.png
    - resources/sky-dusk.png
    - resources/sky-night.png
    # Path
    - resources/path-watercolor-brown.png
    # Optional lens flares
    # - resources/lens-flare-sunrise.png
    # - resources/lens-flare-midday.png
    # - resources/lens-flare-sunset.png
```

## Creating Watercolor Sky PNGs

### Recommended Tools

1. **Procreate (iPad)** - Best for watercolor
   - Use watercolor brushes
   - Layer wet-on-wet effects
   - Export as PNG (2048x2048)

2. **Photoshop**
   - Filter → Artistic → Watercolor
   - Use gradient maps for sky colors
   - Add texture overlays

3. **Figma** (Quick mockups)
   - Gradient backgrounds
   - Export as PNG

4. **Free Online Tools**
   - Canva: Watercolor textures
   - Remove.bg: Transparent backgrounds
   - TinyPNG: Compress files

### Sky Color Palettes by Time

#### Dawn (5-6am)
```
Top:    #1e3a5f (deep blue)
Middle: #6a4c93 (purple)
Bottom: #ffa69e (soft pink)
```

#### Sunrise (6-7am) ⭐ WITH LENS FLARE
```
Top:    #ffd5a2 (peach)
Middle: #ffb88c (orange)
Bottom: #ff9a76 (red-orange)
Light source: Lower left
```

#### Morning (7-10am)
```
Top:    #87CEEB (sky blue)
Middle: #ADD8E6 (light blue)
Bottom: #F0F8FF (alice blue)
```

#### Midday (10-2pm) ⭐ WITH LENS FLARE
```
Top:    #4A90E2 (bright blue)
Middle: #7CB3E9 (light blue)
Bottom: #B8E6F5 (pale blue)
Light source: Top center (strong)
```

#### Afternoon (2-5pm)
```
Top:    #6BB6FF (soft blue)
Middle: #9FCFFF (light blue)
Bottom: #FFE5B4 (peach)
```

#### Sunset (5-7pm) ⭐ WITH LENS FLARE
```
Top:    #FF6B6B (coral red)
Middle: #FF9E80 (orange)
Bottom: #FFD4A3 (peach)
Light source: Lower right
```

#### Dusk (7-8pm)
```
Top:    #4A2C71 (deep purple)
Middle: #7B4397 (purple)
Bottom: #DC2430 (pink-red)
```

#### Night (8pm+)
```
Top:    #0F2027 (dark blue)
Middle: #203A43 (blue-gray)
Bottom: #2C5364 (steel blue)
Add: White dots for stars
```

### Path (Pale Brown Watercolor)

#### Color Palette
```
Top:    #D2B48C with 30% opacity (light tan - blends with sky)
Middle: #C8A882 with 60% opacity (pale brown)
Bottom: #B8936B with 80% opacity (brown)
```

#### Design Tips
- Soft top edge (blends naturally with sky)
- Watercolor texture (irregular, organic edges)
- Slight gradient from light to dark (top to bottom)
- Should cover bottom 30% of screen

## Lens Flare Creation

### Option 1: Custom Painter (Already Implemented)
The widget includes a CustomPainter that draws lens flare programmatically.
No PNG needed - it's automatic!

### Option 2: PNG Overlays (More Realistic)

Create semi-transparent PNGs with:
- **Main glow**: Radial gradient from bright center
- **Hexagonal artifacts**: Small lens hexagons
- **Light streaks**: Subtle rays
- **Color**: Match time of day (orange for sunrise, yellow for midday, red for sunset)

Export as PNG with transparency, use BlendMode.screen when overlaying.

## Quick Start (Without PNGs)

If you don't have watercolor PNGs yet, the widget includes fallback gradients!

Just use:
```dart
GradientSkyBackground(
  timeOfDay: SkyTimeOfDay.sunrise,
  pathHeight: 0.3,
)
```

This gives you solid gradient skies while you create proper watercolor PNGs.

## Workflow

1. **Create 8 sky PNGs** (one for each time of day)
2. **Create 1 path PNG** (pale brown watercolor texture)
3. **Add to resources/ folder**
4. **Update pubspec.yaml**
5. **Run `flutter pub get`**
6. **Hot reload app** - random sky selected each time!

## Image Specifications

- **Resolution**: 1920x1080 or higher (landscape)
- **Format**: PNG with transparency where needed
- **File size**: < 500KB each (use TinyPNG to compress)
- **Aspect ratio**: Match device screen or use BoxFit.cover

## Random Selection

Each time the app loads:
- One sky is randomly chosen from the 8 options
- Lens flare automatically added if sunrise/midday/sunset
- Path always visible at bottom
- House sits on top of path

## Testing Different Skies

To test a specific sky during development:
```dart
// In random_sky_background.dart, line 23:
selectedSky = SkyTimeOfDay.sunset; // Force specific sky
```

## Example Procreate Workflow

1. Create 2048x2048 canvas
2. Fill with base gradient (use color palette above)
3. Add watercolor layer with soft brush
4. Use wet-on-wet technique for blending
5. Add texture overlay (paper grain)
6. Export as PNG
7. Compress with TinyPNG
8. Add to resources/

---

**Need help?** The widget works with gradient fallbacks if PNGs aren't ready yet! 🎨
