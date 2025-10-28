// HScript for Pulsing Darkness Effect
// Place this in your mod's "scripts" folder as "PulsingDarknessEffect.hx"

import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;
import shaders.PulsingDarknessShader;

var pulsingShader:PulsingDarknessShader;
var pulsingFilter:ShaderFilter;
var targetObject:FlxObject;
var isActive:Bool = false;

// Configurable settings
var defaultIntensity:Float = 0.8;
var defaultSpeed:Float = 2.0;
var defaultRadius:Float = 0.3;
var defaultPower:Float = 1.5;
var defaultRim:Float = 0.5;
var defaultDistort:Float = 0.2;

function onCreate() {
    // Initialize the shader
    pulsingShader = new PulsingDarknessShader();
    pulsingFilter = new ShaderFilter(pulsingShader);

    trace("Pulsing Darkness Shader initialized!");
}

function onCreatePost() {
    // You can set a default target here if needed
    // For example, focus on the boyfriend by default
    if (game.boyfriend != null) {
        setFocusTarget(game.boyfriend);
    }
}

function onUpdate(elapsed:Float) {
    if (isActive && pulsingShader != null) {
        // Update shader time
        pulsingShader.update(elapsed);

        // Follow target object if set
        if (targetObject != null) {
            pulsingShader.followObject(targetObject, FlxG.camera, 0.05);
        }
    }
}

// HScript Functions for external control

/**
 * Enable the pulsing darkness effect
 * @param target Optional target object to focus on
 */
function enablePulsingDarkness(?target:FlxObject) {
    if (pulsingShader == null) return;

    // Add filter to camera
    if (FlxG.camera.filters == null) {
        FlxG.camera.filters = [];
    }
    FlxG.camera.filters.push(pulsingFilter);

    if (target != null) {
        setFocusTarget(target);
    }

    isActive = true;
    trace("Pulsing darkness effect enabled!");
}

/**
 * Disable the pulsing darkness effect
 */
function disablePulsingDarkness() {
    if (FlxG.camera.filters != null && pulsingFilter != null) {
        FlxG.camera.filters.remove(pulsingFilter);
    }
    isActive = false;
    trace("Pulsing darkness effect disabled!");
}

/**
 * Set the focus target object
 */
function setFocusTarget(object:FlxObject) {
    targetObject = object;
    if (pulsingShader != null && object != null) {
        pulsingShader.setFocusToObject(object);
    }
}

/**
 * Set focus to specific screen coordinates
 */
function setFocusPosition(x:Float, y:Float) {
    targetObject = null; // Clear target object
    if (pulsingShader != null) {
        pulsingShader.focusX = x;
        pulsingShader.focusY = y;
    }
}

/**
 * Animate focus to a new position
 */
function animateFocusTo(x:Float, y:Float, duration:Float = 1.0, ?ease) {
    if (pulsingShader == null) return;

    if (ease == null) ease = FlxEase.quadOut;

    targetObject = null; // Clear target object during animation

    FlxTween.tween(pulsingShader, {focusX: x, focusY: y}, duration, {ease: ease});
}

/**
 * Create a dramatic pulse effect
 */
function dramaticPulse(intensity:Float = 1.5, duration:Float = 2.0) {
    if (pulsingShader == null) return;

    var originalIntensity = pulsingShader.pulseIntensity;
    var originalSpeed = pulsingShader.pulseSpeed;

    // Quick intense pulse
    FlxTween.tween(pulsingShader, {
        pulseIntensity: intensity,
        pulseSpeed: pulsingShader.pulseSpeed * 2.5
    }, duration * 0.3, {
        ease: FlxEase.quartOut,
        onComplete: function(tween:FlxTween) {
            // Return to normal
            FlxTween.tween(pulsingShader, {
                pulseIntensity: originalIntensity,
                pulseSpeed: originalSpeed
            }, duration * 0.7, {ease: FlxEase.quartInOut});
        }
    });
}

/**
 * Set shader properties with optional tweening
 */
function setShaderProperty(property:String, value:Float, ?tweenDuration:Float = 0.0) {
    if (pulsingShader == null) return;

    switch(property.toLowerCase()) {
        case "intensity" | "pulseintensity":
            if (tweenDuration > 0) {
                FlxTween.tween(pulsingShader, {pulseIntensity: value}, tweenDuration);
            } else {
                pulsingShader.pulseIntensity = value;
            }
        case "speed" | "pulsespeed":
            if (tweenDuration > 0) {
                FlxTween.tween(pulsingShader, {pulseSpeed: value}, tweenDuration);
            } else {
                pulsingShader.pulseSpeed = value;
            }
        case "radius" | "focusradius":
            if (tweenDuration > 0) {
                FlxTween.tween(pulsingShader, {focusRadius: value}, tweenDuration);
            } else {
                pulsingShader.focusRadius = value;
            }
        case "power" | "darknesspower":
            if (tweenDuration > 0) {
                FlxTween.tween(pulsingShader, {darknessPower: value}, tweenDuration);
            } else {
                pulsingShader.darknessPower = value;
            }
        case "rim" | "rimintensity":
            if (tweenDuration > 0) {
                FlxTween.tween(pulsingShader, {rimIntensity: value}, tweenDuration);
            } else {
                pulsingShader.rimIntensity = value;
            }
        case "distort" | "distortstrength":
            if (tweenDuration > 0) {
                FlxTween.tween(pulsingShader, {distortStrength: value}, tweenDuration);
            } else {
                pulsingShader.distortStrength = value;
            }
        default:
            trace("Unknown shader property: " + property);
    }
}

/**
 * Reset shader to default values
 */
function resetShader(?tweenDuration:Float = 1.0) {
    if (pulsingShader == null) return;

    if (tweenDuration > 0) {
        FlxTween.tween(pulsingShader, {
            pulseIntensity: defaultIntensity,
            pulseSpeed: defaultSpeed,
            focusRadius: defaultRadius,
            darknessPower: defaultPower,
            rimIntensity: defaultRim,
            distortStrength: defaultDistort
        }, tweenDuration, {ease: FlxEase.quartInOut});
    } else {
        pulsingShader.pulseIntensity = defaultIntensity;
        pulsingShader.pulseSpeed = defaultSpeed;
        pulsingShader.focusRadius = defaultRadius;
        pulsingShader.darknessPower = defaultPower;
        pulsingShader.rimIntensity = defaultRim;
        pulsingShader.distortStrength = defaultDistort;
    }
}

// Event handlers for common song events

function onEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
    switch(eventName) {
        case "Pulsing Darkness":
            var action = value1.toLowerCase();
            switch(action) {
                case "enable" | "on":
                    enablePulsingDarkness();
                case "disable" | "off":
                    disablePulsingDarkness();
                case "focus_bf" | "boyfriend":
                    setFocusTarget(game.boyfriend);
                case "focus_dad" | "opponent":
                    setFocusTarget(game.dad);
                case "focus_gf" | "girlfriend":
                    if (game.gf != null) setFocusTarget(game.gf);
                case "dramatic":
                    var intensity = Std.parseFloat(value2);
                    if (Math.isNaN(intensity)) intensity = 1.5;
                    dramaticPulse(intensity);
                case "reset":
                    var duration = Std.parseFloat(value2);
                    if (Math.isNaN(duration)) duration = 1.0;
                    resetShader(duration);
                default:
                    // Try to parse as property setting
                    var propertyValue = Std.parseFloat(value2);
                    if (!Math.isNaN(propertyValue)) {
                        setShaderProperty(action, propertyValue, 0.5);
                    }
            }
    }
}

// Cleanup
function onDestroy() {
    if (isActive) {
        disablePulsingDarkness();
    }
}
