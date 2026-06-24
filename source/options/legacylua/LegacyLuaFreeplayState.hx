package options.legacylua;

import backend.Highscore;
import backend.Mods;
import backend.MusicBeatState;
import backend.Paths;
import backend.Song;
import flixel.FlxG;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import managers.FreeplayManager;
import objects.Alphabet.DynamicColoredAlphabet;
import objects.Alphabet;
import options.legacylua.LegacyLuaSettingsManager.LegacyLuaSetting;
import options.legacylua.LegacyLuaSettingsManager;
import states.LoadingState;
import states.PlayState;
import states.freeplay.FreeplayState;
#if ARCHIPELAGO
import archipelago.APEntryState;
#end

/**
 * Extended FreeplayState for managing Legacy Lua settings per song
 */
class LegacyLuaFreeplayState extends FreeplayState {
    private var settingsManager:LegacyLuaSettingsManager;
    private var instructText:FlxText;
    private var isTestMode:Bool = false;

    // Flag to track if we're in Legacy Lua settings mode (prevent returning to normal freeplay)
    public static var inLegacyLuaMode:Bool = false;

    override function create():Void {
        settingsManager = LegacyLuaSettingsManager.getInstance();
        inLegacyLuaMode = true; // Set flag to indicate we're in Legacy Lua settings mode
        super.create();

        // Replace the bottom text with our own instructions
        if (bottomText != null) {
            remove(bottomText);
        }

        var leText:String = "Legacy Lua Song Settings - MOD SONGS ONLY\n" +
            "UP/DOWN: Navigate songs | ENTER: Configure setting | R: Reset to Player Choice\n" +
            "SPACE: Test song (preview) | SHIFT+SPACE: Test with current Legacy Lua setting\n" +
            "BACK: Return to mod selection\n\n" +
            "Setting Colors: White = Player/Mod Choice | Green = Force Legacy Lua ON | Red = Force Legacy Lua OFF";
        bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, 14);
        bottomText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
        bottomText.scrollFactor.set();
        add(bottomText);

        updateSongColors();
    }

    override function update(elapsed:Float):Void {
        // Custom back handling
        if (controls.BACK) {
            handleOverrideBack();
            return;
        }

        // Handle reset setting
        if (controls.RESET && !isTestMode) {
            resetCurrentSongSetting();
            return;
        }
        // Handle test with current Legacy Lua setting
        else if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.SPACE && !isTestMode) {
            testSongWithCurrentSetting();
            return;
        }
        // Override normal ACCEPT behavior when not in search mode
        else if (controls.ACCEPT && !player.playingMusic && !isTestMode) {
            handleSettingsAccept();
            return;
        }

        super.update(elapsed);
    }

    // Override changeSelection to update colors when selection changes
    override function changeSelection(change:Int = 0, playSound:Bool = true):Void {
        super.changeSelection(change, playSound);
        // Update colors when selection changes
        updateSongColors();
    }

    private function resetCurrentSongSetting():Void {
        if (!isValidModSong()) return;

        var song = fpManager.songList[getCurrentSelected()];
        settingsManager.setSongSetting(song.songName, song.folder, PLAYER_CHOICE);
        updateSongColors();
        FlxG.sound.play(Paths.sound('cancelMenu'));
    }

    private function isValidModSong():Bool {
        return fpManager != null &&
               fpManager.songList != null &&
               fpManager.songList.length > 0 &&
               getCurrentSelected() >= 0 &&
               getCurrentSelected() < fpManager.songList.length &&
               fpManager.songList[getCurrentSelected()].folder != null &&
               fpManager.songList[getCurrentSelected()].folder.length > 0;
    }

    private function handleOverrideBack():Void {
        // Go back to LegacyLuaCategoryState instead of regular CategoryState
        if (player.playingMusic) {
            // Handle music stopping
            FlxG.sound.music.stop();
            fpManager.destroyFreeplayVocals();
            FlxG.sound.music.volume = 0;
            instPlaying = -1;

            player.playingMusic = false;
            player.switchPlayMusic();

            MusicManager.playMenuMusic(0);
            FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
            switchVisualizer();
        } else {
            persistentUpdate = false;
            if (colorTween != null) {
                colorTween.cancel();
            }
            FlxG.sound.play(Paths.sound('cancelMenu'));

            // Set up for song settings mode
            states.CategoryState.legacyLuaMode = options.legacylua.LegacyLuaCategoryState.LegacyLuaSettingsMode.SONG_SETTINGS;
            MusicBeatState.switchState(new options.legacylua.LegacyLuaCategoryState());
        }
    }

    // Override reloadSongs to ensure colors are updated and filter mod songs only
    override public function reloadSongs(?refresh:Bool = false):Void {
        super.reloadSongs(refresh);

        // Filter out songs that aren't from mods (base game songs)
        if (fpManager != null && fpManager.songList != null) {
            var modSongsOnly = fpManager.songList.filter(function(song) {
                return song.folder != null && song.folder.length > 0;
            });

            // If no mod songs exist, show a message
            if (modSongsOnly.length == 0) {
                // Show message that no mod songs are available
                if (bottomText != null) {
                    bottomText.text = "NO MOD SONGS AVAILABLE\n" +
                        "Legacy Lua settings only apply to modded songs.\n" +
                        "Please install some mods with songs first.\n\n" +
                        "BACK: Return to mod selection";
                }
            } else {
                // Reset instructions to normal
                var leText:String = "Legacy Lua Song Settings - MOD SONGS ONLY\n" +
                    "UP/DOWN: Navigate songs | ENTER: Configure setting | R: Reset to Player Choice\n" +
                    "SPACE: Test song (preview) | SHIFT+SPACE: Test with current Legacy Lua setting\n" +
                    "BACK: Return to mod selection\n\n" +
                    "Setting Colors: White = Player/Mod Choice | Green = Force Legacy Lua ON | Red = Force Legacy Lua OFF";
                if (bottomText != null) {
                    bottomText.text = leText;
                }
            }
        }

        updateSongColors();
    }

    private function handleSettingsAccept():Void {
        if (!isValidModSong()) return;

        var song = fpManager.songList[getCurrentSelected()];
        var currentSetting = settingsManager.getSongSetting(song.songName, song.folder);

        openSubState(new options.legacylua.LegacyLuaSettingsSubState(song.folder, song.songName, currentSetting, function(newSetting:LegacyLuaSetting) {
            settingsManager.setSongSetting(song.songName, song.folder, newSetting);
            updateSongColors();
        }));
    }

    private function testSongWithCurrentSetting():Void {
        if (!isValidModSong()) return;

        var song = fpManager.songList[getCurrentSelected()];

        // Test the song directly with the current Legacy Lua setting
        isTestMode = true;

        // Show a quick notification about what we're testing
        var shouldUseLegacy = settingsManager.shouldUseLegacyLua(song.songName, song.folder);
        var statusText = shouldUseLegacy ? "Testing with LEGACY LUA" : "Testing with HSCRIPT";

        var notification = new FlxText(0, 100, FlxG.width, statusText, 24);
        notification.setFormat(Paths.font("vcr.ttf"), 24, shouldUseLegacy ? FlxColor.GREEN : FlxColor.CYAN, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        notification.scrollFactor.set();
        add(notification);

        FlxTween.tween(notification, {alpha: 0}, 2, {
            ease: FlxEase.quadOut,
            onComplete: function(twn:FlxTween) {
                remove(notification);
            }
        });

        // Trigger the normal song selection logic from the parent class
        // This simulates pressing ACCEPT to start the song
        startSelectedSong();
    }

    /**
     * Starts the currently selected song (mimics parent class ACCEPT behavior)
     */
    private function startSelectedSong():Void {
        // Set up for song loading just like the parent class does
        searchBar.hasFocus = false;
        var songLowercase:String = Paths.formatToSongPath(fpManager.songList[getCurrentSelected()].songName);
        var poop:String = Highscore.formatSong(songLowercase, getCurDifficulty());

        setSelected(true);

        try {
            Song.loadFromJson(poop, songLowercase);
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = getCurDifficulty();
            Mods.currentModDirectory = fpManager.songList[getCurrentSelected()].folder;

            // Set flag to indicate we're testing from Legacy Lua settings
            ScriptManager.isLegacyLuaTest = isTestMode;

            if (!getAlreadyClicked()) {
                setAlreadyClicked(true);
                MusicBeatState.reopen = false;
                LoadingState.prepareToSong();

                // When testing, always use regular PlayState, never APPlayState
                if (isTestMode) {
                    LoadingState.loadAndSwitchState(new states.PlayState());
                } else {
                    #if ARCHIPELAGO
                    LoadingState.loadAndSwitchState(APEntryState.inArchipelagoMode ? new archipelago.APPlayState() : new states.PlayState());
                    #else
                    LoadingState.loadAndSwitchState(new states.PlayState());
                    #end
                }
            }
            #if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
            setStopMusicPlay(true);
        } catch(e:Dynamic) {
            trace('ERROR loading song: $e');
            isTestMode = false; // Reset test mode on error
            // Show error notification
            var errorText = new FlxText(0, 200, FlxG.width, "Error loading song: " + e.toString(), 16);
            errorText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            errorText.scrollFactor.set();
            add(errorText);

            FlxTween.tween(errorText, {alpha: 0}, 3, {
                ease: FlxEase.quadOut,
                onComplete: function(twn:FlxTween) {
                    remove(errorText);
                }
            });
        }
    }

    private function updateSongColors():Void {
        var grpSongs = getGrpSongs();
        if (grpSongs == null || fpManager.songList == null) return;

        for (i in 0...grpSongs.members.length) {
            var songText = grpSongs.members[i];
            if (songText == null || i >= fpManager.songList.length) continue;

            var song = fpManager.songList[i];
            var songSetting = settingsManager.getSongSetting(song.songName, song.folder);
            var modSetting = settingsManager.getModSetting(song.folder);

            // Determine the effective setting
            var effectiveSetting:LegacyLuaSetting = PLAYER_CHOICE;
            if (songSetting != null) {
                effectiveSetting = songSetting;
            } else if (modSetting != null) {
                effectiveSetting = modSetting;
            }

            var color:FlxColor = switch (effectiveSetting) {
                case PLAYER_CHOICE: FlxColor.WHITE;
                case FORCE_ON: FlxColor.GREEN;
                case FORCE_OFF: FlxColor.RED;
            }

            songText.color = color;
        }
    }
}
