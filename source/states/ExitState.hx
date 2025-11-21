package states;
import archipelago.APGameState;
import flixel.FlxState;
import flixel.text.FlxText;
import haxe.ds.StringMap;

class ExitState extends FlxState
{
	public static var cleanupFunctions:Array<Void->Void> = [];
	public static var returnFunctions:Array<Void->Dynamic> = [];
	public static var returnResults:Map<Int, Dynamic> = new Map();

	override public function create():Void
	{
		super.create();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Closing the Game", null);
		#end

		// Display "Exiting Game..." text
		var exitText:FlxText = new FlxText(0, 0, 0, "Exiting Game...", 32);
		exitText.screenCenter();
		add(exitText);

		// Perform cleanup
		performCleanup();
	}

	public static function addExitCallback(func:Void->Void):Void
	{
		cleanupFunctions.push(func);
	}

	public static function addReturnCallback(func:Void->Dynamic):Void
	{
		returnFunctions.push(func);
	}

	private function performCleanup():Void
	{
		// Flush all queued traces before exit to ensure nothing is lost
		backend.modules.TraceManager.flushAllQueuedTraces();

		// Clean up crash tracking (remove lock file for normal exit)
		yutautil.CrashReporter.cleanupOnExit();

		// Clean up temporary Archipelago weeks before exit
		APGameState.forceCleanupTemporaryWeeks();

		// Clean up High Quality Trap temporary files on engine exit
		#if ARCHIPELAGO_ALLOWED
		archipelago.HighQualityTrapManager.onEngineExit();
		#end

		// Execute cleanup functions
		for (cleanupFunc in cleanupFunctions)
		{
			if (cleanupFunc != null)
			{
				try
				{
					cleanupFunc();
				}
				catch (e:Dynamic)
				{
					trace("Error executing cleanup function: " + e);
				}
			}
		}

		// Execute return functions and store results
		for (returnFunc in returnFunctions)
		{
			var index = returnFunctions.indexOf(returnFunc);
			if (returnFunc != null)
			{
				try
				{
					returnResults.set(index, returnFunc());
				}
				catch (e:Dynamic)
				{
					trace("Error executing return function: " + e);
				}
			}
		}

		trace("Returns: " + returnResults);
		Main.closeGame();
	}
}
