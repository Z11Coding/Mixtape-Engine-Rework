package;

import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;
import debug.FPSCounter;
import lime.app.Application;
import backend.SSPlugin as ScreenShotPlugin;
import backend.ClientPrefs;
import backend.DiscordClient;
import haxe.ui.Toolkit;

#if linux
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite {
	final game = {
		width: 1280,
		height: 720,
		initialState: states.InitState.new,
		zoom: -1.0,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;
	public static var closing:Bool = false;

	public static var cmdArgs:Array<String> = Sys.args();
	public static var noTerminalColor:Bool = false;
	public static var playTest:Bool = false;
	public static var forceGPUOnlyBitmapsOff:Bool = #if windows false #else true #end;

	public static inline function closeGame():Void
	{
		// if (Main.commandPrompt != null)
		// 	commandPrompt.remove();
		if (!closing) {
			trace("Closing game...");
			closing = true;
			pressedOnce = true;
			trace("Disabling command prompt hook...");
		}
		utils.window.WindowUtils.preventClosing = false; 

		Lib.application.window.close();

		closeGame();
	}

	public static var pressedOnce:Bool = false;
	public static function currentState(?asStateClass:Bool):Dynamic {
		return asStateClass == true ? Type.getClass(FlxG.state) : Type.getClassName(Type.getClass(FlxG.state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(FlxG.state)).split(".")) - 1];
	}
	public static final superDangerMode:Bool = Sys.args().contains("-troll");

    public static final __superCoolErrorMessagesArray:Array<String> = [
        "A fatal error has occ- wait what?",
        "missigno.",
        "oopsie daisies!! you did a fucky wucky!!",
        "i think you fogot a semicolon",
        "null balls reference",
        "get friday night funkd'",
        "engine skipped a heartbeat",
        "Impossible...",
        "Patience is key for success... Don't give up.",
        "It's no longer in its early stages... is it?",
        "It took me half a day to code that in",
        "You should make an issue... NOW!!",
        "You should make an issue... Please?",
        "> Crash Handler written by: yoshicrafter29",
        "broken ch-... wait what are we talking about",
        "could not access variable you.dad",
        "What have you done...",
        "THERE ARENT COUGARS IN SCRIPTING!!! I HEARD IT!!",
        "no, thats not from system.windows.forms",
        "you better link a screenshot if you make an issue, or at least the crash.txt",
        "stack trace more like dunno I dont have any jokes",
        "oh the misery. everybody wants to be my enemy",
        "have you heard of soulles dx",
        "I thought it was invincible",
        "did you deleted coconut.png",
        "have you heard of missing json's cousin null function reference",
        "sad that linux users wont see this banger of a crash handler",
        "woopsie",
        "oopsie",
        "woops",
        "silly me",
        "my bad",
        "first time, huh?",
        "did somebody say yoga",
        "we forget a thousand things everyday... make sure this is one of them.",
        "SAY GOODBYE TO YOUR KNEECAPS, CHUCKLEHEAD",
        "motherfucking ordinal 344 (TaskDialog) forcing me to create a even fancier window",
        "Died due to missing a sawblade. (Press Space to dodge!)",
        "yes rico, kaboom.",
        "hey, while in freeplay, press shift while pressing space",
        "goofy ahh engine",
        "pssst, try typing debug7 in the options menu",
        "this crash handler is sponsored by rai-",
        "",
        "did you know a jiffy is an actual measurement of time",
        "how many hurt notes did you put",
        "FPS: 0",
        "\r\ni am a secret message",
        "this is garnet",
        "Error: Sorry I already have a girlfriend",
        "did you know theres a total of 51 silly messages",
        "whoopsies looks like I forgot to fix this",
        "Game used Crash. It's super effective!",
		"What in the fucking shit fuck dick!",
		"The engine got constipated. Sad.",
		"shit.",
		"NULL",
		"Five big booms. BOOM, BOOM, BOOM, BOOM, BOOM!!!!!!!!!!",
		"uhhhhhhhhhhhhhhhh... i dont think this is normal...",
		"lobotomy moment",
		"ARK: Survival Evolved"
    ];

	@:dox(hide)
	public static var audioDisconnected:Bool = false;
	public static var changeID:Int = 0;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void {
		Lib.current.addChild(new Main());
		//Stolen from Psych Online. Thanks for making the next hour of my life not hell.
		//Lib.current.addChild(new archipelago.console.SideUI());
	}

	public function new() {
		super();
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end

		#if windows //DPI AWARENESS BABY
		@:functionCode('
		#include <Windows.h>
		SetProcessDPIAware()
		')
		#end
		backend.CrashHandler.init();
		setupGame();
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init();
		#end
	}

	public static var askedToUpdate:Bool = false;

	private function setupGame():Void {
		Toolkit.init();
		Toolkit.theme = 'dark'; // don't be cringe
		backend.Cursor.registerHaxeUICursors();

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0) {
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		};

		// #if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		ClientPrefs.loadDefaultStuff();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		fpsVar = new FPSCounter(3, 3, 0x00FFFFFF);
		addChild(fpsVar);

		if (fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}

		#if (!web && flixel < "5.5.0")
		FlxG.plugins.add(new ScreenShotPlugin());
		#elseif (flixel >= "5.6.0")
		FlxG.plugins.addIfUniqueType(new ScreenShotPlugin());
		#end

		FlxG.autoPause = false;

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if DISCORD_ALLOWED DiscordClient.prepare(); #end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null) {
			  	for (cam in FlxG.cameras.list) {
			   		if (cam != null && cam.filters != null)
				   		resetSpriteCache(cam.flashSprite);
			  	}
		   	}

		   if (FlxG.game != null) resetSpriteCache(FlxG.game);
	   });
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		    sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static function changeFPSColor(color:FlxColor) {
		fpsVar.textColor = color;
	}
}
