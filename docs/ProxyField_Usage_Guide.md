# ProxyField Usage Guide

## Overview

ProxyField is a performance-optimized notefield implementation that mirrors the rendering of another NoteField without duplicating the expensive positioning calculations. This makes it ideal for visual effects that require multiple copies of the same notefield.

## How ProxyField Works

ProxyField operates by:
1. **Referencing** another NoteField's draw data only
2. **Copying** the draw queue from the proxied field without copying properties
3. **Maintaining complete independence** for all visual properties (alpha, color, position, etc.)
4. **Acting as a separate object** that can be modified, positioned, and styled independently

## Key Design Principle

**ProxyField only shares the DRAW DATA, not the properties.** This means:
- ✅ It gets the same notes/rendering geometry from the source field
- ✅ It can have completely different alpha, color, position, scale, rotation, etc.
- ✅ It can be on different cameras, have different scroll factors, etc.
- ✅ It can be modified independently without affecting the source
- ❌ It does NOT copy visual properties from the source field

## When to Use ProxyField

✅ **Good use cases:**
- Multiple visual copies of a notefield for effects
- Mirror/reflection effects
- Split-screen or multi-camera views
- Visual duplication without performance cost

❌ **Don't use for:**
- Independent notefields that need their own notes
- Fields that need different modifiers/timing
- Primary gameplay notefields

## Basic Usage

### 1. Create a ProxyField

```haxe
// Create a proxy of an existing notefield
var proxyField = new ProxyField(game.dadField.noteField);

// Add it to the rendering system
game.notefields.add(proxyField);

// Or add to display list for direct rendering
add(proxyField);
```

### 2. Configure Properties

```haxe
// ProxyField can have completely independent properties
proxyField.cameras = [game.camGame];  // Different camera
proxyField.scrollFactor.set(0.5, 0.8);  // Different scroll
proxyField.x = 100;  // Different position
proxyField.y = 200;
proxyField.alpha = 0.5;  // Different transparency
proxyField.color = FlxColor.RED;  // Different color
proxyField.scale.set(1.5, 1.5);  // Different scale
proxyField.angle = 45;  // Different rotation

// These are all INDEPENDENT of the source field
// The source field can have completely different values
```

### 3. Working Example

```haxe
function onCreatePost() {
    // The original notefield can remain visible and unchanged
    game.dadField.noteField.alpha = 1.0;  // Keep original visible

    // Create a proxy for visual effects that's completely independent
    var mirrorField = new ProxyField(game.dadField.noteField);
    mirrorField.cameras = [game.camGame];  // Different camera
    mirrorField.scrollFactor.set(0.5, 0.5);  // Different scroll behavior
    mirrorField.alpha = 0.3;  // More transparent
    mirrorField.color = FlxColor.CYAN;  // Different color
    mirrorField.scale.x = -1;  // Mirror horizontally
    mirrorField.x = FlxG.width - 400;  // Different position
    mirrorField.y = 100;

    // Both fields render the same notes but look completely different
    addBehindGF(mirrorField);
}
```

## Important Notes

### What ProxyField Shares
ProxyField ONLY shares the draw data (note positions, textures, etc.) from the source field.

### What ProxyField Does NOT Share
All visual and positioning properties are completely independent:
- Position (`x`, `y`, `z`)
- Scale (`scale.x`, `scale.y`)
- Rotation (`angle`)
- Colors (`color`, `glowColor`)
- Transparency (`alpha`)
- Visibility (`visible`, `exists`)
- Cameras (`cameras`)
- Scroll factors (`scrollFactor`)
- Z-index modifiers (`zIndexMod`)

### Performance Benefits
- **No note processing**: ProxyField doesn't iterate through notes or calculate positions
- **Shared geometry data**: Uses the same vertex/UV data as the source field
- **Independent rendering**: Can be styled/transformed without affecting source performance
- **Minimal memory overhead**: Only stores its own transform/visual properties

## Advanced Usage

### Multiple Proxies
```haxe
var proxies:Array<ProxyField> = [];
for (i in 0...5) {
    var proxy = new ProxyField(game.playerField.noteField);
    proxy.x = i * 150;  // Spread them out horizontally
    proxy.y = i * 50;   // Offset vertically
    proxy.alpha = 0.8 - (i * 0.15);  // Fade each one more
    proxy.color = FlxColor.fromHSB(i * 60, 1, 1);  // Different colors
    proxy.scale.set(1 - i * 0.1, 1 - i * 0.1);  // Scale down each one
    proxies.push(proxy);
    game.notefields.add(proxy);
}
```

### Dynamic Effects
```haxe
var proxy = new ProxyField(game.dadField.noteField);
proxy.cameras = [game.camGame];

function onUpdate(elapsed:Float) {
    // Oscillating transparency independent of source
    proxy.alpha = 0.5 + Math.sin(Conductor.songPosition * 0.002) * 0.3;

    // Circular motion independent of source
    var time = Conductor.songPosition * 0.001;
    proxy.x = FlxG.width/2 + Math.cos(time) * 200;
    proxy.y = FlxG.height/2 + Math.sin(time) * 150;

    // Color cycling independent of source
    proxy.color = FlxColor.fromHSB((time * 30) % 360, 0.8, 1);
}
```

## Troubleshooting

### ProxyField not rendering?
1. Ensure the source NoteField is being rendered
2. Check that ProxyField is added to `game.notefields` or display list
3. Verify `visible = true` and `alpha > 0`
4. Make sure cameras are set correctly

### Performance issues?
1. Limit the number of ProxyFields (each still has rendering overhead)
2. Use `visible = false` to disable unused proxies
3. Remove proxies when no longer needed with `destroy()`

### Synchronization problems?
1. ProxyField only shares draw data, not properties - this is intentional
2. If you need synchronized properties, you may want a regular NoteField instead
3. The source field must call `preDraw()` before the proxy's `draw()` is called

## Best Practices

1. **Create once, reuse**: Don't create new ProxyFields every frame
2. **Clean up**: Call `destroy()` when done with a ProxyField
3. **Use sparingly**: While optimized, multiple proxies still have rendering cost
4. **Test performance**: Profile with multiple proxies to ensure acceptable framerate
5. **Consider alternatives**: Sometimes shader effects or post-processing are more efficient

## Integration with NotefieldRenderer

ProxyField works seamlessly with the NotefieldRenderer system:

```haxe
// Both regular notefields and proxies can be added to the renderer
game.notefields.add(game.playerField.noteField);  // Regular field
game.notefields.add(new ProxyField(game.playerField.noteField)); // Proxy

// The renderer handles both types automatically
```

The renderer will:
- Call `preDraw()` on the source field first
- Call `draw()` on the proxy to copy the draw queue
- Render both with proper z-sorting
