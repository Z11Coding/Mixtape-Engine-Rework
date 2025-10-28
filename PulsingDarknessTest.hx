// Simple test script for Pulsing Darkness Effect
// Place this in your mod's "scripts" folder to test the effect
// Press SPACE during gameplay to toggle the effect

import flixel.FlxG;
import openfl.filters.ShaderFilter;
import shaders.PulsingDarknessShader;

var pulsingShader:PulsingDarknessShader;
var pulsingFilter:ShaderFilter;
var isEnabled:Bool = false;
var testPhase:Int = 0;

function onCreate() {
    pulsingShader = new PulsingDarknessShader();
    pulsingFilter = new ShaderFilter(pulsingShader);

    trace("Pulsing Darkness Test: Press SPACE to cycle through effects!");
}

function onUpdate(elapsed:Float) {
    // Update shader
    if (isEnabled && pulsingShader != null) {
        pulsingShader.update(elapsed);
    }

    // Test controls
    if (FlxG.keys.justPressed.SPACE) {
        cycleEffect();
    }

    if (FlxG.keys.justPressed.R) {
        resetEffect();
    }

    if (FlxG.keys.justPressed.ESCAPE) {
        disableEffect();
    }
}

function cycleEffect() {
    testPhase++;

    switch(testPhase) {
        case 1:
            // Basic effect on boyfriend
            enableEffect();
            pulsingShader.setFocusToObject(game.boyfriend);
            trace("Test 1: Basic effect on boyfriend");

        case 2:
            // Intense effect on opponent
            pulsingShader.setFocusToObject(game.dad);
            pulsingShader.pulseIntensity = 1.2;
            pulsingShader.pulseSpeed = 3.0;
            trace("Test 2: Intense effect on opponent");

        case 3:
            // Center screen with distortion
            pulsingShader.focusX = 0.5;
            pulsingShader.focusY = 0.5;
            pulsingShader.distortStrength = 0.5;
            pulsingShader.rimIntensity = 0.8;
            trace("Test 3: Center focus with distortion");

        case 4:
            // Subtle atmospheric effect
            pulsingShader.pulseIntensity = 0.4;
            pulsingShader.pulseSpeed = 1.0;
            pulsingShader.focusRadius = 0.6;
            pulsingShader.darknessPower = 2.0;
            trace("Test 4: Subtle atmospheric effect");

        case 5:
            // Dramatic pulse
            dramaticPulse();
            trace("Test 5: Dramatic pulse effect");

        default:
            disableEffect();
            testPhase = 0;
            trace("Effect disabled - Press SPACE to start again");
    }
}

function enableEffect() {
    if (FlxG.camera.filters == null) {
        FlxG.camera.filters = [];
    }

    if (FlxG.camera.filters.indexOf(pulsingFilter) == -1) {
        FlxG.camera.filters.push(pulsingFilter);
    }

    isEnabled = true;
}

function disableEffect() {
    if (FlxG.camera.filters != null) {
        FlxG.camera.filters.remove(pulsingFilter);
    }
    isEnabled = false;
}

function resetEffect() {
    if (pulsingShader != null) {
        pulsingShader.pulseIntensity = 0.8;
        pulsingShader.pulseSpeed = 2.0;
        pulsingShader.focusRadius = 0.3;
        pulsingShader.darknessPower = 1.5;
        pulsingShader.rimIntensity = 0.5;
        pulsingShader.distortStrength = 0.2;
        pulsingShader.focusX = 0.5;
        pulsingShader.focusY = 0.5;
    }
    trace("Effect reset to defaults");
}

function dramaticPulse() {
    if (pulsingShader == null) return;

    var originalIntensity = pulsingShader.pulseIntensity;
    var originalSpeed = pulsingShader.pulseSpeed;

    // Create dramatic effect
    pulsingShader.pulseIntensity = 2.0;
    pulsingShader.pulseSpeed = 5.0;
    pulsingShader.rimIntensity = 1.0;

    // Schedule return to normal (simplified without FlxTween for compatibility)
    new flixel.util.FlxTimer().start(2.0, function(timer:flixel.util.FlxTimer) {
        pulsingShader.pulseIntensity = originalIntensity;
        pulsingShader.pulseSpeed = originalSpeed;
        pulsingShader.rimIntensity = 0.5;
    });
}

function onDestroy() {
    disableEffect();
}
