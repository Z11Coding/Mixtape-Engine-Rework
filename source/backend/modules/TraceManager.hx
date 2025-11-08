package backend.modules;

/**
 * Static trace management class to handle in-game trace display
 */
class TraceManager
{
    private static var traces:Array<String> = [];
    private static var viewerGroup:flixel.group.FlxGroup;
    public static var isShowing:Bool = false;
    private static var traceText:flixel.text.FlxText;
    private static var background:flixel.FlxSprite;
    private static var maxTraces:Int = 100;

    public static function addTrace(message:String, ?posInfo:haxe.PosInfos):Void
    {
        updateMaxTraces(); // Update from settings

        var timestamp = Date.now().toString().substr(11, 8);
        var source = posInfo != null ? '${posInfo.fileName}:${posInfo.lineNumber}' : 'Unknown';
        var entry = '[$timestamp] $source: $message';

        traces.push(entry);

        // Keep only recent traces
        while (traces.length > maxTraces)
        {
            traces.shift();
        }

        updateDisplay();
    }

    private static function updateMaxTraces():Void
    {
        maxTraces = backend.ClientPrefs.data.maxInGameTraces;
    }

    public static function toggleViewer():Void
    {
        if (isShowing)
            hideViewer();
        else
            showViewer();
    }

    public static function showViewer():Void
    {
        if (isShowing) return;

        createViewer();
        flixel.FlxG.state.add(viewerGroup);
        isShowing = true;
        updateDisplay();
    }

    public static function hideViewer():Void
    {
        if (!isShowing) return;

        if (viewerGroup != null)
        {
            flixel.FlxG.state.remove(viewerGroup);
        }
        isShowing = false;
    }

    private static function createViewer():Void
    {
        if (viewerGroup != null) return;

        viewerGroup = new flixel.group.FlxGroup();

        // Background
        background = new flixel.FlxSprite(10, 10);
        background.makeGraphic(800, 400, flixel.util.FlxColor.BLACK);
        background.alpha = 0.8;
        background.scrollFactor.set(0, 0);

        // Text display
        traceText = new flixel.text.FlxText(20, 20, 760, "Trace Viewer - F3: Toggle | ESC: Close");
        traceText.setFormat(null, 12, flixel.util.FlxColor.WHITE, flixel.text.FlxText.FlxTextAlign.LEFT);
        traceText.scrollFactor.set(0, 0);

        viewerGroup.add(background);
        viewerGroup.add(traceText);
    }

    private static function updateDisplay():Void
    {
        if (!isShowing || traceText == null) return;

        var displayText = "Trace Viewer - F3: Toggle | ESC: Close\n\n";

        // Show last 20 traces
        var startIndex = Std.int(Math.max(0, traces.length - 20));
        for (i in startIndex...traces.length)
        {
            displayText += traces[i] + "\n";
        }

        traceText.text = displayText;
    }
}
