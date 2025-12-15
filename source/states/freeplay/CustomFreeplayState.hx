package states.freeplay;

import archipelago.APEntryState;
import backend.ClientPrefs;
import backend.Difficulty;
import backend.GameplayOptionsLoader;
import backend.Highscore;
import backend.Mods;
import backend.Paths;
import backend.Song;
import backend.WeekData;
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import hscript.Interp;
import hscript.Parser;
import managers.FreeplayManager;
import objects.Alphabet;
import options.GameplayChangersSubstate;
import states.CategoryState;
import states.PlayState;
import sys.io.File;

#if ARCHIPELAGO_ALLOWED
import archipelago.APInfo;
import managers.APFreeplayManager;
#end

class CustomFreeplayState extends MusicBeatState {
    public var scriptInterp:psychlua.HScript.CustomInterp;
    public var scriptEnv:Dynamic;
    public var scriptPath:String;
    public var themeName:String;
    public var fpManager:FreeplayManager;
    public static var instance:CustomFreeplayState = null;

    // Script overridable functions
    public var onBackPressed:Dynamic = null;
    public var onCtrlPressed:Dynamic = null;
    public var customGameplayChangers:Dynamic = null;
    public var onError:Dynamic = null;
    public var onSongAccessDenied:Dynamic = null;
    public var onSongSelected:Dynamic = null;
    public var onDifficultyChanged:Dynamic = null;
    public var onFreeplayReload:Dynamic = null;

    public function new(scriptPath:String) {
        super();
        this.scriptPath = Paths.getPath('custom_freeplays/$scriptPath.hx');
        this.themeName = (scriptPath != null) ? scriptPath.split('/').pop().split('.').shift() : "debug-fallback";
    }



    override public function create():Void {
        super.create();

        // Initialize FreeplayManager (auto-detects AP mode)
        fpManager = FreeplayManager.loadFPManager(true);

        if (themeName.replace('.hx', '') == 'FreeplayTemplate')
            scriptPath = Paths.getSharedPath('custom_freeplays/FreeplayTemplate.hx');

        trace("[CustomFreeplayState] Initializing Freeplay State with theme: " + themeName);
        trace("[CustomFreeplayState] Script path: " + scriptPath);


        trace("[CustomFreeplayState] Freeplay Manager instance: " + Std.string(fpManager.songList.length) + " songs");


        try {
            // Prepare script content
            var scriptCode = File.getContent(scriptPath);

            // Create Iris interpreter
            var iris = new Iris(scriptCode, new IrisConfig(null, false, false));

            // Create custom interpreter
            var customInterp:psychlua.HScript.CustomInterp = new psychlua.HScript.CustomInterp();
            customInterp.parentInstance = FlxG.state;
            customInterp.showPosOnLog = true; // Enable position logging for better error tracking
            this.scriptInterp = customInterp;

            // Set up script environment variables
            setupScriptEnvironment(iris);

            // Parse and execute the script with enhanced error handling
            trace("[CustomFreeplayState] Parsing and executing script...");
            try {
                iris.parse(true);
                scriptEnv = iris.execute();
                trace("[CustomFreeplayState] Script executed, result: " + (scriptEnv != null ? "success" : "null"));
            } catch (e:Dynamic) {
                var errorMessage = 'Script parsing/execution failed: $e';

                // Try to extract position information from the error
                var errorString = Std.string(e);
                if (errorString.contains("line ") || errorString.contains("Line ")) {
                    errorMessage += ' (Position info may be included in error message)';
                }

                handleError('script_parse_execute', e, errorMessage);

                // Set scriptEnv to null to indicate failure
                scriptEnv = null;
            }

            // Check for script overridable functions
            if (scriptEnv != null) {
                if (Reflect.hasField(scriptEnv, "onBackPressed")) {
                    onBackPressed = Reflect.field(scriptEnv, "onBackPressed");
                }
                if (Reflect.hasField(scriptEnv, "onCtrlPressed")) {
                    onCtrlPressed = Reflect.field(scriptEnv, "onCtrlPressed");
                }
                if (Reflect.hasField(scriptEnv, "customGameplayChangers")) {
                    customGameplayChangers = Reflect.field(scriptEnv, "customGameplayChangers");
                }
                if (Reflect.hasField(scriptEnv, "onError")) {
                    onError = Reflect.field(scriptEnv, "onError");
                }
                if (Reflect.hasField(scriptEnv, "onSongAccessDenied")) {
                    onSongAccessDenied = Reflect.field(scriptEnv, "onSongAccessDenied");
                }
                if (Reflect.hasField(scriptEnv, "onSongSelected")) {
                    onSongSelected = Reflect.field(scriptEnv, "onSongSelected");
                }
                if (Reflect.hasField(scriptEnv, "onDifficultyChanged")) {
                    onDifficultyChanged = Reflect.field(scriptEnv, "onDifficultyChanged");
                }
                if (Reflect.hasField(scriptEnv, "onFreeplayReload")) {
                    onFreeplayReload = Reflect.field(scriptEnv, "onFreeplayReload");
                }

                // Call script's create if it exists
                if (Reflect.hasField(scriptEnv, "create")) {
                    trace("[CustomFreeplayState] Calling script create() function...");
                    try {
                        Reflect.callMethod(scriptEnv, Reflect.field(scriptEnv, "create"), []);
                        trace("[CustomFreeplayState] Script create() completed");
                    } catch (e:Dynamic) {
                        handleError('script_create', e, 'Error in script create() function');
                    }
                }
            }
        } catch (e:Dynamic) {
            handleError('create', e, 'Exception occurred during create()');
        }
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // Handle BACK control
        if (controls.BACK) {
            handleBackPressed();
            return;
        }

        // Handle CTRL for Gameplay Changers
        if (FlxG.keys.justPressed.CONTROL) {
            handleCtrlPressed();
            return;
        }

        try {
            if (scriptEnv != null && Reflect.hasField(scriptEnv, "update")) {
                Reflect.callMethod(scriptEnv, Reflect.field(scriptEnv, "update"), [elapsed]);
            }
        } catch (e:Dynamic) {
            handleError('update', e, 'Exception in script update');
        }
    }

    override public function destroy():Void {
        try {
            if (scriptEnv != null && Reflect.hasField(scriptEnv, "destroy")) {
                Reflect.callMethod(scriptEnv, Reflect.field(scriptEnv, "destroy"), []);
            }

            // Clean up references
            scriptEnv = null;
            scriptInterp = null;
            fpManager = null;
            onBackPressed = null;
            onCtrlPressed = null;
            customGameplayChangers = null;
            onError = null;
            onSongAccessDenied = null;
            onSongSelected = null;
            onDifficultyChanged = null;
            onFreeplayReload = null;

        } catch (e:Dynamic) {
            handleError('destroy', e, 'Exception during script destroy');
        }

        super.destroy();
    }

    // Helper functions
    private function setupScriptEnvironment(iris:Iris):Void {
        // Core classes
        iris.set('FreeplayManager', FreeplayManager);
        iris.set('FlxG', FlxG);
        iris.set('FlxState', FlxState);
        iris.set('FlxSprite', flixel.FlxSprite);
        iris.set('FlxText', flixel.text.FlxText);
        iris.set('PlayState', PlayState);

        // State reference
        var stateClassName = Type.getClassName(Type.getClass(FlxG.state));
        iris.set('$stateClassName', this);
        iris.set('state', this);

        // FreeplayManager instance
        iris.set('fpManager', fpManager);

        // Archipelago support
        #if ARCHIPELAGO_ALLOWED
        iris.set('APEntryState', APEntryState);
        iris.set('inArchipelagoMode', APEntryState.inArchipelagoMode);
        #end

        // Additional classes for fallback script
        iris.set('Alphabet', objects.Alphabet);
        iris.set('FlxTween', flixel.tweens.FlxTween);
        iris.set('FlxEase', flixel.tweens.FlxEase);
        iris.set('Paths', Paths);
        iris.set('Math', Math);

        // Essential Haxe standard library classes
        iris.set('Std', Std);
        iris.set('Type', Type);
        iris.set('Reflect', Reflect);
        iris.set('StringTools', StringTools);
        iris.set('Lambda', Lambda);
        iris.set('Date', Date);
        iris.set('DateTools', DateTools);
        iris.set('EReg', EReg);
        iris.set('Sys', Sys);

        // Additional utility classes commonly used in scripts
        iris.set('Array', Array);
        iris.set('IntMap', haxe.ds.IntMap);
        iris.set('StringMap', haxe.ds.StringMap);
        iris.set('ObjectMap', haxe.ds.ObjectMap);
        iris.set('EnumValueMap', haxe.ds.EnumValueMap);
        iris.set('Map', haxe.Constraints.IMap);

        // Utility functions for scripts
        iris.set('loadSong', loadSong);
        iris.set('loadMod', loadMod);
        iris.set('loadFolder', loadMod); // Alias for loadMod
        iris.set('loadModDirectory', loadMod); // Alias for loadMod
        iris.set('isArchipelagoMode', isArchipelagoMode);
        iris.set('goToCategoryState', goToCategoryState);
        iris.set('getDifficultyName', getDifficultyName);
        iris.set('getDifficultyImagePath', getDifficultyImagePath);
        iris.set('getDifficultyCount', getDifficultyCount);
        iris.set('getAllDifficultyNames', getAllDifficultyNames);
        iris.set('getAllDifficultyImagePaths', getAllDifficultyImagePaths);
        iris.set('findDifficultyIndex', findDifficultyIndex);
        iris.set('createDifficultySprite', createDifficultySprite);
        iris.set('updateDifficultyListBySong', updateDifficultyListBySong);
        iris.set('isSongAccessible', isSongAccessible);
        iris.set('getSongAccessStatus', getSongAccessStatus);
        iris.set('playSong', playSong);
        iris.set('handleSongAccessDenied', handleSongAccessDenied);
        iris.set('handleSongSelected', handleSongSelected);
        iris.set('handleDifficultyChanged', handleDifficultyChanged);
        iris.set('handleFreeplayReload', handleFreeplayReload);
    }

    private function handleBackPressed():Void {
        if (onBackPressed != null) {
            try {
                var result = Reflect.callMethod(scriptEnv, onBackPressed, []);
                // If script returns true, don't perform default action
                if (result == true) return;
            } catch (e:Dynamic) {
                handleError('onBackPressed', e, 'Error calling onBackPressed');
            }
        }

        // Default behavior: go to CategoryState
        goToCategoryState();
    }

    private function handleCtrlPressed():Void {
        if (onCtrlPressed != null) {
            try {
                var gameplayChangerData = createGameplayChangerData();
                var result = Reflect.callMethod(scriptEnv, onCtrlPressed, [gameplayChangerData]);
                // If script returns true, don't perform default action
                if (result == true) return;
            } catch (e:Dynamic) {
                handleError('onCtrlPressed', e, 'Error calling onCtrlPressed');
            }
        }

        // Default behavior: open GameplayChangersSubstate
        openSubState(new GameplayChangersSubstate());
    }

    public function loadSong(songIndex:Int, ?difficultyId:Int):Bool {
        try {
            // Get the appropriate FreeplayManager (regular or AP)
            var manager = FreeplayManager.loadFPManager();
            if (manager == null || manager.songList == null || songIndex >= manager.songList.length || songIndex < 0) {
                trace('[CustomFreeplayState] Invalid song index: $songIndex');
                return false;
            }

            var songData = manager.songList[songIndex];

            // Check song access (locked status, missing items, etc.)
            var accessStatus = getSongAccessStatus(songData.songName, songData.folder);
            if (!accessStatus.accessible) {
                trace('[CustomFreeplayState] Song access denied: ${accessStatus.reason}');
                handleSongAccessDenied(accessStatus);
                return false;
            }

            var difficultyIndex = (difficultyId != null && difficultyId >= 0 && difficultyId < Difficulty.list.length) ?
                difficultyId : 0; // Default to first difficulty (usually "normal" or "easy")

            var poop = Highscore.formatSong(songData.songName, difficultyIndex);
            PlayState.SONG = Song.loadFromJson(poop, songData.songName);
            PlayState.storyDifficulty = difficultyIndex;
            PlayState.isStoryMode = false;

            // Set mod directory if song has one
            if (songData.folder != null && songData.folder != "") {
                Mods.currentModDirectory = songData.folder;
            }

            return true;
        } catch (e:Dynamic) {
            handleError('loadSong', e, 'Failed to load song at index $songIndex');
            return false;
        }
    }

    /**
     * Load mod directory for a song by index without loading the song itself
     * This allows custom freeplay states to load the correct assets before song selection
     * @param songIndex Index of the song in the song list
     * @return Dynamic object containing mod info: {success: Bool, modDirectory: String, songName: String, accessible: Bool}
     */
    public function loadMod(songIndex:Int):Dynamic {
        var result = {
            success: false,
            modDirectory: "",
            songName: "",
            accessible: false,
            reason: null
        };

        try {
            // Get the appropriate FreeplayManager (regular or AP)
            var manager = FreeplayManager.loadFPManager();
            if (manager == null || manager.songList == null || songIndex >= manager.songList.length || songIndex < 0) {
                trace('[CustomFreeplayState] loadMod: Invalid song index: $songIndex');
                result.reason = "invalid_index";
                return result;
            }

            var songData = manager.songList[songIndex];
            result.songName = songData.songName;

            // Check song access (locked status, missing items, etc.)
            var accessStatus = getSongAccessStatus(songData.songName, songData.folder);
            result.accessible = accessStatus.accessible;

            if (!accessStatus.accessible) {
                trace('[CustomFreeplayState] loadMod: Song access denied for ${songData.songName}: ${accessStatus.reason}');
                result.reason = accessStatus.reason;
                // Still set mod directory even for inaccessible songs for UI purposes
            }

            // Set mod directory if song has one
            var modFolder = (songData.folder != null && songData.folder != "") ? songData.folder : "";
            result.modDirectory = modFolder;

            if (modFolder != "") {
                trace('[CustomFreeplayState] loadMod: Setting mod directory to: $modFolder for song: ${songData.songName}');
                Mods.currentModDirectory = modFolder;
            } else {
                trace('[CustomFreeplayState] loadMod: Using base game assets for song: ${songData.songName}');
                Mods.currentModDirectory = "";
            }

            result.success = true;
            return result;
        } catch (e:Dynamic) {
            handleError('loadMod', e, 'Failed to load mod for song index $songIndex');
            result.reason = "exception";
            return result;
        }
    }

    /**
     * Load and immediately play a song (combines loadSong + state switching)
     * @param songIndex Index of the song in the song list
     * @param difficultyId Difficulty index (optional, defaults to 0)
     * @return True if song was loaded and PlayState was opened, false otherwise
     */
    public function playSong(songIndex:Int, ?difficultyId:Int):Bool {
        try {
            // First, try to load the song
            if (loadSong(songIndex, difficultyId)) {
                // If loading succeeded, play confirmation sound and switch to PlayState
                FlxG.sound.play(Paths.sound("confirmMenu"));
                FlxG.switchState(new PlayState());
                return true;
            } else {
                // If loading failed, play cancel sound
                FlxG.sound.play(Paths.sound("cancelMenu"));
                return false;
            }
        } catch (e:Dynamic) {
            handleError('playSong', e, 'Failed to play song at index $songIndex');
            FlxG.sound.play(Paths.sound("cancelMenu"));
            return false;
        }
    }

    public function isArchipelagoMode():Bool {
        #if ARCHIPELAGO_ALLOWED
        return APEntryState.inArchipelagoMode;
        #else
        return false;
        #end
    }

    public function goToCategoryState():Void {
        #if ARCHIPELAGO_ALLOWED
        if (APEntryState.inArchipelagoMode) {
            FlxG.switchState(new archipelago.APCategoryState(APEntryState.apGame, APEntryState.ap));
        } else {
            FlxG.switchState(new CategoryState());
        }
        #else
        FlxG.switchState(new CategoryState());
        #end
    }

    private function createGameplayChangerData():Dynamic {
        var optionsLoader = new GameplayOptionsLoader();
        var data:Dynamic = {};

        // Get all options from all categories
        var allCategories = [
            GameplayOptionsLoader.ASSIST_CATEGORY,
            GameplayOptionsLoader.MODIFIERS_CATEGORY,
            GameplayOptionsLoader.ADVANCED_CATEGORY
        ];

        for (category in allCategories) {
            var options = optionsLoader.getOptionsForCategory(category);
            for (option in options) {
                var varName = option.getVariable();
                var value = option.getValue();
                Reflect.setField(data, varName, value);
            }
        }

        return data;
    }

    /**
     * Get difficulty name by index
     * @param difficultyIndex Index of the difficulty (0-based)
     * @return The difficulty name, or null if index is invalid
     */
    public function getDifficultyName(difficultyIndex:Int):String {
        if (difficultyIndex < 0 || difficultyIndex >= Difficulty.list.length) {
            trace('[CustomFreeplayState] Invalid difficulty index: $difficultyIndex');
            return null;
        }
        return Difficulty.getString(difficultyIndex);
    }

    /**
     * Get difficulty image path by index
     * @param difficultyIndex Index of the difficulty (0-based)
     * @return The path to the difficulty image, or null if index is invalid
     */
    public function getDifficultyImagePath(difficultyIndex:Int):String {
        if (difficultyIndex < 0 || difficultyIndex >= Difficulty.list.length) {
            trace('[CustomFreeplayState] Invalid difficulty index: $difficultyIndex');
            return null;
        }
        var diffName = Difficulty.list[difficultyIndex].toLowerCase();
        return 'menudifficulties/$diffName';
    }

    /**
     * Get the total number of available difficulties
     * @return Number of difficulties
     */
    public function getDifficultyCount():Int {
        return Difficulty.list.length;
    }

    /**
     * Get all difficulty names as an array
     * @return Array of difficulty names
     */
    public function getAllDifficultyNames():Array<String> {
        var names:Array<String> = [];
        for (i in 0...Difficulty.list.length) {
            names.push(Difficulty.getString(i));
        }
        return names;
    }

    /**
     * Get all difficulty image paths as an array
     * @return Array of difficulty image paths
     */
    public function getAllDifficultyImagePaths():Array<String> {
        var paths:Array<String> = [];
        for (i in 0...Difficulty.list.length) {
            var diffName = Difficulty.list[i].toLowerCase();
            paths.push('menudifficulties/$diffName');
        }
        return paths;
    }

    /**
     * Find difficulty index by name (case-insensitive)
     * @param difficultyName Name of the difficulty to find
     * @return Index of the difficulty, or -1 if not found
     */
    public function findDifficultyIndex(difficultyName:String):Int {
        if (difficultyName == null) return -1;
        var lowerName = difficultyName.toLowerCase();

        for (i in 0...Difficulty.list.length) {
            if (Difficulty.list[i].toLowerCase() == lowerName) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Create a difficulty sprite by index
     * @param difficultyIndex Index of the difficulty (0-based)
     * @param x X position for the sprite (optional)
     * @param y Y position for the sprite (optional)
     * @return FlxSprite with difficulty image loaded, or null if invalid index
     */
    public function createDifficultySprite(difficultyIndex:Int, ?x:Float = 0, ?y:Float = 0):flixel.FlxSprite {
        var imagePath = getDifficultyImagePath(difficultyIndex);
        if (imagePath == null) return null;

        var sprite = new flixel.FlxSprite(x, y);
        try {
            sprite.loadGraphic(Paths.image(imagePath));
            return sprite;
        } catch (e:Dynamic) {
            handleError('createDifficultySprite', e, 'Failed to load difficulty sprite for index $difficultyIndex');
            sprite.destroy();
            return null;
        }
    }

    /**
     * Update the global difficulty list based on a song's available difficulties using WeekData
     * @param songIndex Index of the song in the song list
     * @return Dynamic object with update info: {success: Bool, songName: String, difficulties: Array<String>, originalDifficulties: Array<String>, reason: String}
     */
    public function updateDifficultyListBySong(songIndex:Int):Dynamic {
        var result = {
            success: false,
            songName: "",
            difficulties: [],
            originalDifficulties: Difficulty.list.copy(),
            reason: null
        };

        try {
            // Get the appropriate FreeplayManager (regular or AP)
            var manager = FreeplayManager.loadFPManager();
            if (manager == null || manager.songList == null || songIndex >= manager.songList.length || songIndex < 0) {
                trace('[CustomFreeplayState] updateDifficultyListBySong: Invalid song index: $songIndex');
                result.reason = "invalid_index";
                return result;
            }

            var songData = manager.songList[songIndex];
            result.songName = songData.songName;

            // Set the proper week and mod directory like other Freeplay states do
            var previousModDir = Mods.currentModDirectory;

            // Set mod directory and week data
            Mods.currentModDirectory = songData.folder;
            PlayState.storyWeek = songData.week;

            // Use WeekData to properly set directory and load difficulties
            WeekData.setDirectoryFromWeek();

            try {
                // Load difficulties from the week data (the proper way)
                Difficulty.loadFromWeek();

                result.difficulties = Difficulty.list.copy();

                trace('[CustomFreeplayState] updateDifficultyListBySong: Updated difficulty list for "${songData.songName}" using WeekData: ${result.difficulties}');
                result.success = true;

            } catch (e:Dynamic) {
                trace('[CustomFreeplayState] updateDifficultyListBySong: Failed to load from week, falling back to default difficulties');

                // Fallback: Reset to default and use current week's difficulties if available
                Difficulty.resetList();

                try {
                    var currentWeek = WeekData.getCurrentWeek();
                    if (currentWeek != null && currentWeek.difficulties != null && currentWeek.difficulties.trim() != "") {
                        var weekDiffs = currentWeek.difficulties.trim().split(',');
                        var cleanDiffs:Array<String> = [];
                        for (diff in weekDiffs) {
                            var cleanDiff = diff.trim();
                            if (cleanDiff.length > 0) {
                                cleanDiffs.push(cleanDiff);
                            }
                        }
                        if (cleanDiffs.length > 0) {
                            Difficulty.list = cleanDiffs;
                            result.difficulties = cleanDiffs.copy();
                            result.reason = "used_week_difficulties";
                        } else {
                            result.difficulties = Difficulty.list.copy();
                            result.reason = "used_default_difficulties";
                        }
                    } else {
                        result.difficulties = Difficulty.list.copy();
                        result.reason = "used_default_difficulties";
                    }
                    result.success = true;
                } catch (weekError:Dynamic) {
                    result.difficulties = Difficulty.list.copy();
                    result.reason = "fallback_to_default";
                    result.success = true;
                }
            }

            // Restore previous mod directory
            Mods.currentModDirectory = previousModDir;
            return result;

        } catch (e:Dynamic) {
            handleError('updateDifficultyListBySong', e, 'Failed to update difficulty list for song index $songIndex');
            result.reason = "exception";

            // Restore original difficulties on error
            Difficulty.list = result.originalDifficulties;
            return result;
        }
    }

    /**
     * Handle errors with custom error handler support
     * @param context Context where the error occurred
     * @param error The error object
     * @param message Optional custom message
     */
    private function handleError(context:String, error:Dynamic, ?message:String):Void {
        var errorInfo = {
            context: context,
            error: error,
            message: message != null ? message : 'An error occurred',
            stackTrace: haxe.CallStack.toString(haxe.CallStack.exceptionStack())
        };

        // Try to extract script position from error or interpreter
        var scriptPosition:String = null;
        var scriptLine:Int = -1;
        var scriptOrigin:String = null;

        // First, check if the error is an HScript Error type with position info
        try {
            if (Reflect.hasField(error, "line") && Reflect.hasField(error, "origin")) {
                // This is likely an HScript Error
                scriptLine = Reflect.field(error, "line");
                scriptOrigin = Reflect.field(error, "origin");
                if (scriptOrigin != null && scriptLine > 0) {
                    scriptPosition = '$scriptOrigin:$scriptLine';
                }
            }
        } catch (e:Dynamic) {
            // Ignore errors from reflection
        }

        // Fallback to interpreter position if no error position found
        if (scriptPosition == null && scriptInterp != null) {
            try {
                // Attempt to get current position from interpreter
                var interpPos = Std.string(scriptInterp);
                if (interpPos != null && interpPos.contains("line:")) {
                    scriptPosition = interpPos;
                } else if (scriptInterp.showPosOnLog) {
                    scriptPosition = "Script execution context (position logging enabled)";
                }
            } catch (e:Dynamic) {
                // Ignore errors from trying to get position
            }
        }

        // Enhanced error info with script position
        var enhancedErrorInfo = {
            context: context,
            error: error,
            message: message != null ? message : 'An error occurred',
            stackTrace: errorInfo.stackTrace,
            scriptPosition: scriptPosition
        };

        if (onError != null) {
            try {
                var result = Reflect.callMethod(scriptEnv, onError, [enhancedErrorInfo]);
                // If script returns true, don't perform default error handling
                if (result == true) return;
            } catch (e:Dynamic) {
                trace('[CustomFreeplayState] Error in custom error handler: $e');
            }
        }

        // Default error handling - trace, modify stack trace, and throw
        trace('[CustomFreeplayState.$context] ERROR: ${enhancedErrorInfo.message}: ${enhancedErrorInfo.error}');

        // Create modified stack trace with script position at the top
        var modifiedStackTrace = errorInfo.stackTrace;
        if (scriptPosition != null) {
            // Format script position in typical stack trace fashion
            var scriptStackEntry:String;
            if (scriptOrigin != null && scriptLine > 0) {
                // Use proper file path and line format like "CustomFreeplayState.hx:line 42"
                var fileName = scriptOrigin.indexOf('/') >= 0 ? scriptOrigin.split('/').pop() :
                              (scriptOrigin.indexOf('\\') >= 0 ? scriptOrigin.split('\\').pop() : scriptOrigin);
                scriptStackEntry = 'Called from $fileName line $scriptLine';
            } else {
                // Fallback format
                scriptStackEntry = 'Called from CustomFreeplayState script ($scriptPosition)';
            }
            modifiedStackTrace = scriptStackEntry + '\n' + modifiedStackTrace;
        }

        // Create a new error with the modified stack trace
        var enhancedError = {
            original: error,
            context: context,
            message: enhancedErrorInfo.message,
            scriptPosition: scriptPosition,
            toString: function() {
                return enhancedErrorInfo.message + ': ' + Std.string(error);
            }
        };

        // Trace the modified stack trace
        trace('[CustomFreeplayState.$context] Stack trace with script position:');
        trace(modifiedStackTrace);

        // Throw the enhanced error to preserve the call stack behavior
        throw enhancedError;
    }

    /**
     * Check if a song is accessible in current mode (considers AP locks, victory conditions, etc.)
     * @param songName Name of the song
     * @param modName Mod folder (can be null/empty for base game)
     * @return True if song can be played, false otherwise
     */
    public function isSongAccessible(songName:String, ?modName:String):Bool {
        return getSongAccessStatus(songName, modName).accessible;
    }

    /**
     * Get detailed access status for a song
     * @param songName Name of the song
     * @param modName Mod folder (can be null/empty for base game)
     * @return Object with accessibility info, reason, hints, etc.
     */
    public function getSongAccessStatus(songName:String, ?modName:String):Dynamic {
        if (modName == null) modName = "";

        var result = {
            accessible: true,
            reason: null,
            hints: [],
            isVictorySong: false,
            isUnlocked: true,
            hasMissingItems: false
        };

        #if ARCHIPELAGO_ALLOWED
        if (APEntryState.inArchipelagoMode) {
            // Check if this is a victory song
            result.isVictorySong = APFreeplayManager.isVictorySong(songName, modName);

            if (result.isVictorySong) {
                var hasRequiredTickets = APInfo.ticketCount >= APInfo.ticketWinCount;
                if (!hasRequiredTickets) {
                    result.accessible = false;
                    result.reason = "victory_insufficient_tickets";
                    result.hints = APFreeplayManager.getHintsForSong(songName, modName);
                    return result;
                }
            }

            // Check if song is in curUnlocked list
            var isUnlocked = false;
            for (songObj in APFreeplayManager.curUnlocked) {
                if (songObj.song.trim().toLowerCase().replace('-', ' ') == songName.trim().toLowerCase().replace('-', ' ') &&
                    songObj.mod == modName) {
                    isUnlocked = true;
                    break;
                }
            }

            result.isUnlocked = isUnlocked;
            if (!isUnlocked) {
                result.accessible = false;
                result.reason = "locked";
                result.hints = APFreeplayManager.getHintsForSong(songName, modName);
                return result;
            }

            // Check if missing required sanity items (characters, stages, etc.)
            var hasMissingItems = false;

            try {
                // Load the song data to check for required sanity items
                var songLowercase = Paths.formatToSongPath(songName);
                var difficultyIndex = 0; // Use first difficulty for sanity check
                var poop = Highscore.formatSong(songLowercase, difficultyIndex);
                var songData = Song.loadFromJson(poop, songLowercase);

                if (songData != null) {
                    // Check for missing sanity items (characters, stages, etc.)
                    var missingSanityItems = APEntryState.apGame.checkSongCharactersAndStageUnlocked(songData);
                    hasMissingItems = (missingSanityItems != null && missingSanityItems.length > 0);
                }
            } catch (e:Dynamic) {
                trace('[CustomFreeplayState] Error checking sanity items for $songName: $e');
                // On error, assume no missing items to avoid blocking access
                hasMissingItems = false;
            }

            // Also check trueMissing array (but not if it's in unplayedList) for backward compatibility
            if (!hasMissingItems) {
                for (missingInfo in APFreeplayManager.trueMissing) {
                    if (missingInfo.song == songName && missingInfo.mod == modName) {
                        // Check if it's also in unplayedList (which would make it playable)
                        var inUnplayedList = false;
                        for (unplayedInfo in APFreeplayManager.unplayedList) {
                            if (unplayedInfo.song == songName && unplayedInfo.mod == modName) {
                                inUnplayedList = true;
                                break;
                            }
                        }
                        if (!inUnplayedList) {
                            hasMissingItems = true;
                            break;
                        }
                    }
                }
            }

            result.hasMissingItems = hasMissingItems;
            if (hasMissingItems) {
                result.accessible = false;
                result.reason = "missing_items";
                result.hints = APFreeplayManager.getHintsForSong(songName, modName);
                return result;
            }
        }
        #end

        return result;
    }

    /**
     * Handle when song access is denied (can show hints, error messages, etc.)
     * @param accessStatus The access status object from getSongAccessStatus
     */
    public function handleSongAccessDenied(accessStatus:Dynamic):Void {
        if (onSongAccessDenied != null) {
            try {
                var result = Reflect.callMethod(scriptEnv, onSongAccessDenied, [accessStatus]);
                // If script returns true, don't perform default action
                if (result == true) return;
            } catch (e:Dynamic) {
                handleError('onSongAccessDenied', e, 'Error calling onSongAccessDenied');
            }
        }

        // Default behavior: play cancel sound
        FlxG.sound.play(Paths.sound("cancelMenu"));

        // You could add more sophisticated UI feedback here:
        // - Show hint panels like in OsuFreeplayState
        // - Display lock icons
        // - Show progress bars for victory songs
        // - etc.
    }

    /**
     * Handle when a song is selected (for navigation feedback, sound effects, etc.)
     * @param songIndex Index of the selected song
     * @param songData Song data object (optional)
     */
    public function handleSongSelected(songIndex:Int, ?songData:Dynamic):Void {
        if (onSongSelected != null) {
            try {
                var result = Reflect.callMethod(scriptEnv, onSongSelected, [songIndex, songData]);
                // If script returns true, don't perform default action
                if (result == true) return;
            } catch (e:Dynamic) {
                handleError('onSongSelected', e, 'Error calling onSongSelected');
            }
        }

        // Default behavior: play scroll sound
        FlxG.sound.play(Paths.sound("scrollMenu"));
    }

    /**
     * Handle when difficulty is changed (for UI updates, sound effects, etc.)
     * @param difficultyIndex Index of the new difficulty
     * @param difficultyName Name of the new difficulty (optional)
     */
    public function handleDifficultyChanged(difficultyIndex:Int, ?difficultyName:String):Void {
        if (onDifficultyChanged != null) {
            try {
                var result = Reflect.callMethod(scriptEnv, onDifficultyChanged, [difficultyIndex, difficultyName]);
                // If script returns true, don't perform default action
                if (result == true) return;
            } catch (e:Dynamic) {
                handleError('onDifficultyChanged', e, 'Error calling onDifficultyChanged');
            }
        }

        // Default behavior: play scroll sound
        FlxG.sound.play(Paths.sound("scrollMenu"));
    }

    /**
     * Handle when freeplay manager requests a reload (for AP updates, song list changes, etc.)
     */
    public function handleFreeplayReload(refresh:Bool, searchText:String):Void {
        if (onFreeplayReload != null) {
            try {
                var result = Reflect.callMethod(scriptEnv, onFreeplayReload, [refresh, searchText]);
                // If script returns true, don't perform default action
                if (result == true) return;
            } catch (e:Dynamic) {
                handleError('onFreeplayReload', e, 'Error calling onFreeplayReload');
            }
        }

        // Default behavior: reload the entire state
        FlxG.resetState();
    }
}
