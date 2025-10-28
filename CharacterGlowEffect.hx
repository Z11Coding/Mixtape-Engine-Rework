// Character Glow with Darkness Effect - Pure HScript Implementation
// Creates a darkness overlay with character highlighting using only sprites

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BlendMode;

// Effect components
var darknessOverlay:FlxSprite;
var glowSprite:FlxSprite;
var targetCharacter:FlxObject;
var effectGroup:FlxGroup;
var isActive:Bool = false;

// Glow effect variables
var glowRadius:Float = 150;
var glowIntensity:Float = 0.8;
var darknessAlpha:Float = 0.6;
var pulseTime:Float = 0.0;
var pulseSpeed:Float = 2.0;
var followSpeed:Float = 0.08;
var glowColor:FlxColor = FlxColor.fromRGB(255, 255, 180); // Warm white

// Animation variables
var currentGlowX:Float = 0;
var currentGlowY:Float = 0;

function onCreate() {
    // Create effect group to manage layering
    effectGroup = new FlxGroup();

    // Create darkness overlay - full screen black sprite
    darknessOverlay = new FlxSprite(0, 0);
    darknessOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    darknessOverlay.alpha = darknessAlpha;
    darknessOverlay.scrollFactor.set(0, 0); // Stay fixed to camera
    darknessOverlay.cameras = [FlxG.camera];

    // Create glow sprite
    createGlowSprite();

    // Add to effect group
    effectGroup.add(darknessOverlay);
    effectGroup.add(glowSprite);

    trace("Character Glow Effect initialized!");
}

function createGlowSprite() {
    var glowSize = Std.int(glowRadius * 2);
    glowSprite = new FlxSprite(0, 0);
    glowSprite.makeGraphic(glowSize, glowSize, FlxColor.TRANSPARENT);

    // Create radial gradient glow effect by drawing circles
    var centerX = glowSize / 2;
    var centerY = glowSize / 2;
    var maxRadius = glowRadius * 0.8;

    // Draw multiple circles with decreasing alpha for smooth gradient
    var steps = 20;
    for (i in 0...steps) {
        var radius = maxRadius * (steps - i) / steps;
        var alpha = 1.0 * i / steps;
        var color = FlxColor.fromRGBFloat(
            glowColor.redFloat,
            glowColor.greenFloat,
            glowColor.blueFloat,
            alpha * glowIntensity
        );

        // Simple circle drawing using rectangles (HScript compatible)
        var circleRadius = Std.int(radius);
        for (x in -circleRadius...circleRadius) {
            for (y in -circleRadius...circleRadius) {
                var dist = Math.sqrt(x * x + y * y);
                if (dist <= radius && dist > radius - 3) {
                    var pixelX = Std.int(centerX + x);
                    var pixelY = Std.int(centerY + y);
                    if (pixelX >= 0 && pixelX < glowSize && pixelY >= 0 && pixelY < glowSize) {
                        // This creates the glow effect
                        glowSprite.pixels.setPixel32(pixelX, pixelY, color);
                    }
                }
            }
        }
    }

    // Set blend mode for additive glow effect
    glowSprite.blend = BlendMode.ADD;
    glowSprite.scrollFactor.set(0, 0);
    glowSprite.cameras = [FlxG.camera];
}

function onCreatePost() {
    // Set default target to boyfriend
    if (game.boyfriend != null) {
        setGlowTarget(game.boyfriend);
    }
}

function onUpdate(elapsed:Float) {
    if (!isActive) return;

    // Update pulse animation
    pulseTime += elapsed * pulseSpeed;
    var pulseValue = Math.sin(pulseTime) * 0.3 + 0.7; // Pulse between 0.4 and 1.0

    // Update glow intensity based on pulse
    glowSprite.alpha = glowIntensity * pulseValue;

    // Follow target character smoothly
    if (targetCharacter != null) {
        var targetX = targetCharacter.x + targetCharacter.width * 0.5 - glowRadius;
        var targetY = targetCharacter.y + targetCharacter.height * 0.5 - glowRadius;

        // Convert world coordinates to screen coordinates
        targetX -= FlxG.camera.scroll.x;
        targetY -= FlxG.camera.scroll.y;

        // Smooth following
        currentGlowX = FlxMath.lerp(currentGlowX, targetX, followSpeed);
        currentGlowY = FlxMath.lerp(currentGlowY, targetY, followSpeed);

        glowSprite.x = currentGlowX;
        glowSprite.y = currentGlowY;
    }

    // Update darkness overlay to punch hole where glow is
    updateDarknessWithHole();
}

function updateDarknessWithHole() {
    if (darknessOverlay == null || glowSprite == null) return;

    // Recreate darkness overlay with hole
    darknessOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

    // Create a "hole" in the darkness where the glow is
    var holeRadius = glowRadius * 0.7;
    var centerX = glowSprite.x + glowRadius;
    var centerY = glowSprite.y + glowRadius;

    // Make pixels transparent in a circular area around the glow
    for (x in 0...FlxG.width) {
        for (y in 0...FlxG.height) {
            var dist = Math.sqrt((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY));
            if (dist < holeRadius) {
                // Create smooth falloff
                var transparency = 1.0 - (dist / holeRadius);
                transparency = Math.pow(transparency, 1.5); // Smoother curve
                var alpha = darknessAlpha * (1.0 - transparency);

                var color = FlxColor.fromRGBFloat(0, 0, 0, alpha);
                darknessOverlay.pixels.setPixel32(x, y, color);
            }
        }
    }

    // Apply changes
    darknessOverlay.dirty = true;
}

// Public functions for controlling the effect

function enableGlowEffect(?target:FlxObject) {
    if (isActive) return;

    // Add effects to the game
    game.add(effectGroup);

    if (target != null) {
        setGlowTarget(target);
    }

    // Fade in effect
    darknessOverlay.alpha = 0;
    glowSprite.alpha = 0;

    FlxTween.tween(darknessOverlay, {alpha: darknessAlpha}, 0.5, {ease: FlxEase.quadOut});
    FlxTween.tween(glowSprite, {alpha: glowIntensity}, 0.5, {ease: FlxEase.quadOut});

    isActive = true;
    trace("Character glow effect enabled!");
}

function disableGlowEffect() {
    if (!isActive) return;

    // Fade out effect
    FlxTween.tween(darknessOverlay, {alpha: 0}, 0.5, {
        ease: FlxEase.quadIn,
        onComplete: function(tween:FlxTween) {
            game.remove(effectGroup);
        }
    });
    FlxTween.tween(glowSprite, {alpha: 0}, 0.5, {ease: FlxEase.quadIn});

    isActive = false;
    trace("Character glow effect disabled!");
}

function setGlowTarget(character:FlxObject) {
    targetCharacter = character;
    if (character != null) {
        // Immediately position glow on target
        currentGlowX = character.x + character.width * 0.5 - glowRadius - FlxG.camera.scroll.x;
        currentGlowY = character.y + character.height * 0.5 - glowRadius - FlxG.camera.scroll.y;

        if (glowSprite != null) {
            glowSprite.x = currentGlowX;
            glowSprite.y = currentGlowY;
        }

        trace("Glow target set to character");
    }
}

function setGlowColor(color:FlxColor) {
    glowColor = color;
    createGlowSprite(); // Recreate with new color

    // Update in effect group
    effectGroup.remove(effectGroup.members[1]); // Remove old glow
    effectGroup.add(glowSprite); // Add new glow
}

function setGlowIntensity(intensity:Float, ?tweenDuration:Float = 0.0) {
    glowIntensity = intensity;
    if (tweenDuration > 0 && glowSprite != null) {
        FlxTween.tween(glowSprite, {alpha: intensity}, tweenDuration);
    }
}

function setDarknessLevel(alpha:Float, ?tweenDuration:Float = 0.0) {
    darknessAlpha = alpha;
    if (tweenDuration > 0 && darknessOverlay != null) {
        FlxTween.tween(darknessOverlay, {alpha: alpha}, tweenDuration);
    } else if (darknessOverlay != null) {
        darknessOverlay.alpha = alpha;
    }
}

function setGlowSize(radius:Float) {
    glowRadius = radius;
    createGlowSprite(); // Recreate with new size

    // Update in effect group
    effectGroup.remove(effectGroup.members[1]); // Remove old glow
    effectGroup.add(glowSprite); // Add new glow
}

function setPulseSpeed(speed:Float) {
    pulseSpeed = speed;
}

function dramaticFlash(flashIntensity:Float = 2.0, duration:Float = 1.0) {
    if (!isActive || glowSprite == null) return;

    var originalIntensity = glowIntensity;
    var originalSize = glowRadius;

    // Flash effect
    FlxTween.tween(glowSprite, {alpha: flashIntensity}, duration * 0.2, {
        ease: FlxEase.quadOut,
        onComplete: function(tween:FlxTween) {
            FlxTween.tween(glowSprite, {alpha: originalIntensity}, duration * 0.8, {
                ease: FlxEase.quadInOut
            });
        }
    });

    // Size pulse
    var targetSize = originalSize * 1.5;
    setGlowSize(targetSize);
    FlxTween.tween(this, {glowRadius: originalSize}, duration, {
        ease: FlxEase.elasticOut,
        onUpdate: function(tween:FlxTween) {
            setGlowSize(glowRadius);
        }
    });
}

// Event system integration
function onEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
    switch(eventName) {
        case "Character Glow" | "Glow Effect":
            var action = value1.toLowerCase();
            switch(action) {
                case "enable" | "on":
                    enableGlowEffect();
                case "disable" | "off":
                    disableGlowEffect();
                case "bf" | "boyfriend":
                    setGlowTarget(game.boyfriend);
                case "dad" | "opponent":
                    setGlowTarget(game.dad);
                case "gf" | "girlfriend":
                    if (game.gf != null) setGlowTarget(game.gf);
                case "flash" | "dramatic":
                    var intensity = Std.parseFloat(value2);
                    if (Math.isNaN(intensity)) intensity = 2.0;
                    dramaticFlash(intensity);
                case "intensity":
                    var value = Std.parseFloat(value2);
                    if (!Math.isNaN(value)) setGlowIntensity(value, 0.5);
                case "darkness":
                    var value = Std.parseFloat(value2);
                    if (!Math.isNaN(value)) setDarknessLevel(value, 0.5);
                case "size":
                    var value = Std.parseFloat(value2);
                    if (!Math.isNaN(value)) setGlowSize(value);
                case "speed":
                    var value = Std.parseFloat(value2);
                    if (!Math.isNaN(value)) setPulseSpeed(value);
                case "blue":
                    setGlowColor(FlxColor.fromRGB(100, 150, 255));
                case "red":
                    setGlowColor(FlxColor.fromRGB(255, 100, 100));
                case "green":
                    setGlowColor(FlxColor.fromRGB(100, 255, 150));
                case "purple":
                    setGlowColor(FlxColor.fromRGB(200, 100, 255));
                case "white":
                    setGlowColor(FlxColor.WHITE);
            }
    }
}

// Keyboard controls for testing
function onUpdatePost(elapsed:Float) {
    // Test controls (remove in production)
    if (FlxG.keys.justPressed.G) {
        if (isActive) {
            disableGlowEffect();
        } else {
            enableGlowEffect(game.boyfriend);
        }
    }

    if (FlxG.keys.justPressed.ONE && isActive) {
        setGlowTarget(game.boyfriend);
    }

    if (FlxG.keys.justPressed.TWO && isActive) {
        setGlowTarget(game.dad);
    }

    if (FlxG.keys.justPressed.THREE && isActive) {
        dramaticFlash();
    }
}

// Cleanup
function onDestroy() {
    if (isActive) {
        disableGlowEffect();
    }

    if (effectGroup != null) {
        effectGroup.destroy();
    }
}
