package states.freeplay;

import flixel.FlxState;
import flixel.FlxG;
import hscript.Parser;
import hscript.Interp;
import sys.io.File;
import managers.FreeplayManager;

    import crowplexus.iris.Iris;
    import crowplexus.iris.IrisConfig;

class CustomFreeplayState extends MusicBeatState {
    public var scriptInterp:psychlua.HScript.CustomInterp;
    public var scriptEnv:Dynamic;
    public var scriptPath:String;
    public var themeName:String;

    public function new(scriptPath:String) {
        super();
        this.scriptPath = scriptPath;
        this.themeName = scriptPath.split('/').pop().split('.').shift(); // Extract theme name from script path
    }


    // ...existing code...
    
    override public function create():Void {
        super.create();
    
        // Prepare Iris interpreter
        var scriptCode = File.getContent(scriptPath);
        var iris = new Iris(scriptCode, new IrisConfig(null, false, false));
        var customInterp:psychlua.HScript.CustomInterp = new psychlua.HScript.CustomInterp();
		customInterp.parentInstance = FlxG.state;
		customInterp.showPosOnLog = false;
		this.scriptInterp = customInterp;

        // Only expose Freeplay-relevant variables
        iris.set('FreeplayManager', FreeplayManager);
        iris.set('FlxG', FlxG);
        iris.set('FlxState', FlxState);
        iris.set('FlxSprite', flixel.FlxSprite);
        iris.set('${Type.getClassName(Type.getClass(FlxG.state))}', this);
        iris.set('state', this);
    
        // Parse and execute the script, expecting it to return an object with lifecycle methods
        iris.parse(true);
        scriptEnv = iris.funcAndReturn(iris.execute);
    
        // Call script's create if it exists
        if (scriptEnv != null && Reflect.hasField(scriptEnv, "create")) {
            Reflect.callMethod(scriptEnv, Reflect.field(scriptEnv, "create"), []);
        }
        //this.scriptInterp = iris;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (scriptEnv != null && Reflect.hasField(scriptEnv, "update")) {
            Reflect.callMethod(scriptEnv, Reflect.field(scriptEnv, "update"), [elapsed]);
        }
    }

    override public function destroy():Void {
        if (scriptEnv != null && Reflect.hasField(scriptEnv, "destroy")) {
            Reflect.callMethod(scriptEnv, Reflect.field(scriptEnv, "destroy"), []);
        }
        super.destroy();
    }
}