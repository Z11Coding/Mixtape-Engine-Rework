import flixel.FlxState;
import flixel.text.FlxText;
import haxe.ds.StringMap;

class ExitState extends FlxState {
    public static var cleanupFunctions:Array<Void->Void> = [];
    public static var returnFunctions:Array<Void->Dynamic> = [];
    public static var returnResults:Map<Int, Dynamic> = new Map();

    override public function create():Void {
        super.create();

        // Display "Exiting Game..." text
        var exitText:FlxText = new FlxText(0, 0, 0, "Exiting Game...", 32);
        exitText.screenCenter();
        add(exitText);

        // Perform cleanup
        performCleanup();
    }

    private function performCleanup():Void {
        // Execute cleanup functions
        for (cleanupFunc in cleanupFunctions) {
            if (cleanupFunc != null) {
            try {
                cleanupFunc();
            } catch (e:Dynamic) {
                trace("Error executing cleanup function: " + e);
            }
            }
        }

        // Execute return functions and store results
        for (returnFunc in returnFunctions) {
            var index = returnFunctions.indexOf(returnFunc);
            if (returnFunc != null) {
            try {
                returnResults.set(index, returnFunc());
                }
                 catch (e:Dynamic) {
                trace("Error executing return function: " + e);
            }
        }
    }

        // Exit the game after cleanup
        Main.closeGame();
    }
    }