# Pulsing Darkness Shader Effect

This is a custom shader effect that creates a pulsing darkness around the screen while keeping a specific focus area bright. Perfect for dramatic moments, boss battles, or atmospheric effects in your Friday Night Funkin' mods.

## Features

- **Pulsing darkness effect** with customizable intensity and speed
- **Dynamic focus point** that can follow objects or be set to specific coordinates
- **Rim lighting** around the focus area for dramatic effect
- **Subtle distortion** near the focus point for organic feel
- **HScript integration** for easy mod implementation without source code changes
- **Event system** support for chart-based control
- **Smooth animations** and transitions between states

## Installation

### For Source Code Integration:
1. Copy `pulsingDarkness.frag` to `assets/shared/shaders/`
2. Copy `PulsingDarknessShader.hx` to `source/shaders/`

### For Mod Integration (HScript):
1. Copy `pulsingDarkness.frag` to your mod's `shaders/` folder
2. Copy `PulsingDarknessEffect.hx` to your mod's `scripts/` folder

## Usage Examples

### Basic Usage (HScript)
```haxe
// Enable the effect
callScript('scripts/PulsingDarknessEffect', 'enablePulsingDarkness');

// Set focus on boyfriend
callScript('scripts/PulsingDarknessEffect', 'setFocusTarget', [game.boyfriend]);

// Disable the effect
callScript('scripts/PulsingDarknessEffect', 'disablePulsingDarkness');
```

### Advanced Usage (HScript)
```haxe
// Create a dramatic pulse effect
callScript('scripts/PulsingDarknessEffect', 'dramaticPulse', [2.0, 3.0]);

// Animate focus to center screen
callScript('scripts/PulsingDarknessEffect', 'animateFocusTo', [0.5, 0.5, 1.5]);

// Adjust shader properties
callScript('scripts/PulsingDarknessEffect', 'setShaderProperty', ["intensity", 1.2, 1.0]);
```

### Chart Events
You can control the effect using the "Pulsing Darkness" event in your chart:

- `enable` - Enable the effect
- `disable` - Disable the effect
- `focus_bf` - Focus on boyfriend
- `focus_dad` - Focus on opponent
- `focus_gf` - Focus on girlfriend
- `dramatic` - Trigger dramatic pulse (value2 = intensity)
- `reset` - Reset to default values (value2 = duration)
- Property names (e.g., `intensity`, `speed`, `radius`) - Set specific values

### Source Code Usage
```haxe
import shaders.PulsingDarknessShader;
import openfl.filters.ShaderFilter;

var pulsingShader = new PulsingDarknessShader();
var pulsingFilter = new ShaderFilter(pulsingShader);

// Add to camera
FlxG.camera.filters = [pulsingFilter];

// Set focus on an object
pulsingShader.setFocusToObject(boyfriend);

// Adjust properties
pulsingShader.pulseIntensity = 1.2;
pulsingShader.pulseSpeed = 3.0;
pulsingShader.focusRadius = 0.25;
```

## Configuration

### Shader Properties:
- **pulseIntensity** (0.0-2.0): How intense the darkness effect is
- **pulseSpeed** (0.1-10.0): Speed of the pulsing animation
- **focusX/focusY** (0.0-1.0): Focus point in UV coordinates
- **focusRadius** (0.1-1.0): Size of the focus area
- **darknessPower** (0.5-3.0): Falloff curve of the darkness
- **rimIntensity** (0.0-1.0): Intensity of rim lighting around focus
- **distortStrength** (0.0-1.0): Strength of distortion effect

### Default Values:
```haxe
pulseIntensity: 0.8
pulseSpeed: 2.0
focusRadius: 0.3
darknessPower: 1.5
rimIntensity: 0.5
distortStrength: 0.2
```

## Performance Notes

- The shader is optimized for real-time use
- Minimal performance impact on modern GPUs
- Automatically updates time for animation
- Uses efficient distance calculations and smoothstep functions

## Compatibility

- Works with Mixtape Engine and Psych Engine
- Compatible with other shader effects when layered properly
- HScript version works without source code modification
- Supports both individual object targeting and manual positioning

## Tips for Best Results

1. **Boss Battles**: Use high intensity with focus on the boss character
2. **Dramatic Moments**: Combine with `dramaticPulse()` function
3. **Atmospheric Scenes**: Use lower intensity for subtle mood lighting
4. **Dynamic Scenes**: Use `followObject()` to track moving characters
5. **Transitions**: Use property tweening for smooth effect changes

## Troubleshooting

- **Effect not visible**: Check if HSCRIPT_ALLOWED flag is enabled
- **Performance issues**: Reduce distortStrength or pulseIntensity
- **Focus not following**: Ensure target object is valid and visible
- **Shader compilation errors**: Verify fragment shader file location

This effect is designed to be both powerful and easy to use, whether you're integrating it directly into source code or using it as a mod through HScript!
