package shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import lime.utils.Assets;

class PulsingDarknessShader extends FlxRuntimeShader
{
    public var time(default, set):Float = 0.0;
    public var pulseIntensity(default, set):Float = 0.8;
    public var pulseSpeed(default, set):Float = 2.0;
    public var focusX(default, set):Float = 0.5;
    public var focusY(default, set):Float = 0.5;
    public var focusRadius(default, set):Float = 0.3;
    public var darknessPower(default, set):Float = 1.5;
    public var rimIntensity(default, set):Float = 0.5;
    public var distortStrength(default, set):Float = 0.2;

    public function new()
    {
        super(Assets.getText(Paths.shaderFragment('pulsingDarkness')));

        #if debug
        FlxG.debugger.addTrackerProfile(new TrackerProfile(PulsingDarknessShader, [
            'time', 'pulseIntensity', 'pulseSpeed', 'focusX', 'focusY',
            'focusRadius', 'darknessPower', 'rimIntensity', 'distortStrength'
        ]));
        #end

        // Set initial values
        this.time = 0.0;
        this.pulseIntensity = 0.8;
        this.pulseSpeed = 2.0;
        this.focusX = 0.5;
        this.focusY = 0.5;
        this.focusRadius = 0.3;
        this.darknessPower = 1.5;
        this.rimIntensity = 0.5;
        this.distortStrength = 0.2;
    }

    // override public function __update(elapsed:Float):Void
    // {
    //     super.__update(elapsed);
    //     this.time += elapsed;
    // }

    function set_time(value:Float):Float
    {
        this.setFloat('_time', value);
        return this.time = value;
    }

    function set_pulseIntensity(value:Float):Float
    {
        this.setFloat('_pulseIntensity', value);
        return this.pulseIntensity = value;
    }

    function set_pulseSpeed(value:Float):Float
    {
        this.setFloat('_pulseSpeed', value);
        return this.pulseSpeed = value;
    }

    function set_focusX(value:Float):Float
    {
        this.setFloat('_focusX', value);
        return this.focusX = value;
    }

    function set_focusY(value:Float):Float
    {
        this.setFloat('_focusY', value);
        return this.focusY = value;
    }

    function set_focusRadius(value:Float):Float
    {
        this.setFloat('_focusRadius', value);
        return this.focusRadius = value;
    }

    function set_darknessPower(value:Float):Float
    {
        this.setFloat('_darknessPower', value);
        return this.darknessPower = value;
    }

    function set_rimIntensity(value:Float):Float
    {
        this.setFloat('_rimIntensity', value);
        return this.rimIntensity = value;
    }

    function set_distortStrength(value:Float):Float
    {
        this.setFloat('_distortStrength', value);
        return this.distortStrength = value;
    }

    /**
     * Set the focus point to a specific sprite or object position
     * @param object The FlxSprite or object to focus on
     * @param camera Optional camera to use for coordinate conversion
     */
    public function setFocusToObject(object:flixel.FlxObject, ?camera:flixel.FlxCamera):Void
    {
        if (camera == null) camera = FlxG.camera;

        // Convert world coordinates to screen UV coordinates (0.0 to 1.0)
        var screenX = object.x + object.width * 0.5 - camera.scroll.x;
        var screenY = object.y + object.height * 0.5 - camera.scroll.y;

        this.focusX = screenX / camera.width;
        this.focusY = screenY / camera.height;
    }

    /**
     * Animate the focus point to follow an object smoothly
     */
    public function followObject(object:flixel.FlxObject, ?camera:flixel.FlxCamera, lerpSpeed:Float = 0.1):Void
    {
        if (camera == null) camera = FlxG.camera;

        var targetX = (object.x + object.width * 0.5 - camera.scroll.x) / camera.width;
        var targetY = (object.y + object.height * 0.5 - camera.scroll.y) / camera.height;

        this.focusX = flixel.math.FlxMath.lerp(this.focusX, targetX, lerpSpeed);
        this.focusY = flixel.math.FlxMath.lerp(this.focusY, targetY, lerpSpeed);
    }
}
