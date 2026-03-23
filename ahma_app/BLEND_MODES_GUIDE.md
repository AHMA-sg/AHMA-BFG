# Background PNG Blending Guide

## How to Blend Multiple Background PNGs

### Quick Start

1. **Add your PNGs to resources folder:**
   ```
   resources/
   ├── bg-watercolor-base.png
   ├── bg-watercolor-teal.png
   └── bg-watercolor-accent.png
   ```

2. **Update pubspec.yaml:**
   ```yaml
   assets:
     - resources/bg-watercolor-base.png
     - resources/bg-watercolor-teal.png
     - resources/bg-watercolor-accent.png
   ```

3. **Replace WatercolorBackground in home_screen.dart:**
   ```dart
   // Replace this:
   const WatercolorBackground(...)

   // With this:
   const BlendedBackground(
     backgroundColor: Color(0xFFFFF4E6), // Base color
     layers: [
       BackgroundLayer(
         imagePath: 'resources/bg-watercolor-base.png',
         opacity: 1.0,
         blendMode: BlendMode.srcOver,
       ),
       BackgroundLayer(
         imagePath: 'resources/bg-watercolor-teal.png',
         opacity: 0.5,
         blendMode: BlendMode.multiply,
       ),
     ],
   )
   ```

## Blend Modes Explained

### For Watercolor Effects:

| Blend Mode | Effect | Best Use |
|------------|--------|----------|
| **BlendMode.srcOver** | Normal (default) | Base layer |
| **BlendMode.multiply** | Darkens colors, like layering watercolors | Middle layers, adding depth |
| **BlendMode.screen** | Lightens colors, creates glow | Highlights, light effects |
| **BlendMode.overlay** | Combines multiply & screen | Rich, vibrant colors |
| **BlendMode.softLight** | Subtle color enhancement | Gentle tints, atmospheric |
| **BlendMode.hardLight** | Strong color enhancement | Bold effects |
| **BlendMode.colorDodge** | Brightens with color | Light leaks, sun rays |
| **BlendMode.colorBurn** | Increases saturation | Rich, deep colors |

### Recommended Watercolor Stack:

```dart
BlendedBackground(
  backgroundColor: const Color(0xFFFFF4E6), // Soft cream base
  layers: [
    // Layer 1: Base texture (full opacity)
    BackgroundLayer(
      imagePath: 'resources/paper-texture.png',
      opacity: 1.0,
      blendMode: BlendMode.srcOver,
    ),

    // Layer 2: Main watercolor (multiply for depth)
    BackgroundLayer(
      imagePath: 'resources/watercolor-main.png',
      opacity: 0.6,
      blendMode: BlendMode.multiply,
    ),

    // Layer 3: Accent colors (soft light for subtlety)
    BackgroundLayer(
      imagePath: 'resources/watercolor-accent.png',
      opacity: 0.4,
      blendMode: BlendMode.softLight,
    ),

    // Layer 4: Highlights (screen for glow)
    BackgroundLayer(
      imagePath: 'resources/watercolor-highlights.png',
      opacity: 0.3,
      blendMode: BlendMode.screen,
    ),
  ],
)
```

## Advanced Techniques

### 1. Tinted Layers
Add color tints to grayscale images:

```dart
TintedLayer(
  imagePath: 'resources/texture-grayscale.png',
  tintColor: Colors.teal.withOpacity(0.3),
  opacity: 0.5,
  blendMode: BlendMode.multiply,
)
```

### 2. Animated Transitions
Fade layers in sequentially:

```dart
AnimatedBlendedBackground(
  animationDuration: Duration(seconds: 4),
  layers: [...],
)
```

### 3. Color Filters
Apply custom color transformations:

```dart
BackgroundLayer(
  imagePath: 'resources/bg.png',
  colorFilter: ColorFilter.mode(
    Colors.teal.withOpacity(0.2),
    BlendMode.modulate,
  ),
)
```

## Creating Your Watercolor PNGs

### Recommended Tools:
- **Procreate** (iPad): Watercolor brushes, export as PNG
- **Photoshop**: Layer styles, watercolor filters
- **GIMP** (free): Artistic filters → Watercolor
- **Figma**: Vector shapes with gradients, export PNG

### Tips:
1. **Transparent backgrounds**: Export as PNG with transparency
2. **Large resolution**: 2048x2048 or higher for crisp display
3. **Soft edges**: Use gaussian blur for organic watercolor feel
4. **Multiple layers**: Create separate PNGs for each color/effect
5. **Test combinations**: Try different blend modes to find best look

## Example Workflow

1. **Create base texture** (paper grain, cream color)
2. **Add main watercolor shape** (teal blob with soft edges)
3. **Add accent colors** (pink/yellow splashes)
4. **Add highlights** (white/light areas)
5. **Export each as separate PNG**
6. **Stack in BlendedBackground** with appropriate blend modes

## Performance Tips

- Keep total layers under 5 for smooth performance
- Optimize PNG file sizes (compress with TinyPNG)
- Use BoxFit.cover to avoid repeated texture loading
- Consider caching images with `precacheImage()`

## Complete Example

See `home_screen_example_blended.dart` for full implementation!
