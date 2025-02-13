package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxState;

/**
 * Handles initialization of variables when first opening the game.
**/
class InitState extends FlxState {
	public static var gameInitialized = false;
    override function create():Void {
		utils.window.Priority.setPriority(0);
        super.create();

		// -- MIXTAPE STUFF -- //
		utils.WindowUtil.initWindowEvents();
		utils.WindowUtil.disableCrashHandler();
		FlxSprite.defaultAntialiasing = true;

        // -- FLIXEL STUFF -- //

        FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

        FlxTransitionableState.skipNextTransIn = true;

        // -- SETTINGS -- //

		FlxG.save.bind('mixtape', CoolUtil.getSavePath());

		#if (flixel >= "5.0.0")
		trace('save status: ${FlxG.save.status}');
		#end

		FlxG.fixedTimestep = false;

        // ClientPrefs.loadDefaultKeys();
		ClientPrefs.loadPrefs();
		ClientPrefs.reloadVolumeKeys();

		Language.reloadPhrases();

        /*
        #if ACHIEVEMNTS_ALLOWED
        Achievements.init();
        #end
        */

        // -- MODS -- //

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		Mods.loadTopMod();

        // -- -- -- //
        
        MemoryUtil.init();
		utils.window.WindowUtils.init();
        utils.window.CppAPI._setWindowLayered();
		utils.window.CppAPI.darkMode();
		utils.window.CppAPI.allowHighDPI();
		utils.window.CppAPI.setOld();

        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

        final state:Class<FlxState> = (ClientPrefs.data.disableSplash) ? TitleState : StartupState;

        FlxG.switchState(Type.createInstance(state, []));
    }
}