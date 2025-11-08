package backend.modules;

import flixel.FlxBasic;
import flixel.FlxG;

/**
 * Simple trace viewer plugin that handles input for the trace viewer
 */
class TraceViewerPlugin extends FlxBasic
{
    public static var instance:TraceViewerPlugin;

    public function new()
    {
        super();
        instance = this;
    }

    public static function initialize():Void
    {
        if (instance == null)
            FlxG.plugins.addPlugin(new TraceViewerPlugin());
    }

    public override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (Controls.instance?.justPressed('traceviewer'))
        {
            TraceManager.toggleViewer();
        }

        // Close viewer with ESC key
        if (TraceManager.isShowing && FlxG.keys.justPressed.ESCAPE)
        {
            TraceManager.hideViewer();
        }
    }

    public override function destroy():Void
    {
        if (instance == this)
            instance = null;

        super.destroy();
    }
}
