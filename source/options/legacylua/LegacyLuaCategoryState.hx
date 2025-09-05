package options.legacylua;

import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxG;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.Alphabet.DynamicColoredAlphabet;
import options.CategoriesSubstate;
import options.legacylua.LegacyLuaSettingsManager.LegacyLuaSetting;
import options.legacylua.LegacyLuaSettingsManager;
import states.CategoryState;

enum LegacyLuaSettingsMode {
    MOD_SETTINGS;
    SONG_SETTINGS;
}

/**
 * Extended CategoryState for managing Legacy Lua settings per mod
 */
class LegacyLuaCategoryState extends CategoryState {
    private var settingsManager:LegacyLuaSettingsManager;
    public static var legacyLuaMode:LegacyLuaSettingsMode = MOD_SETTINGS;

    private var instructText:FlxText;

    public function new(?categories:Dynamic, ?showmods:Bool = true, ?showsecrets:Bool = true, ?showall:Bool = true, ?h:Bool = true, ?softCoded:Bool = true) {
        // Force category mode when in mod selection mode
        rightOption = null;
        if (legacyLuaMode == MOD_SETTINGS) {
            // For mod settings: Force show mods as categories, disable show all
            super(categories, true, showsecrets, false, true, softCoded); // Force showmods=true, showall=false
            // Force catMode to "Mods" to enable mod categorization logic
            catMode = "Mods";
        } else {
            // For song settings: Allow normal behavior
            super(categories, showmods, showsecrets, showall, h, softCoded);
        }
    }

    override function create():Void {
        settingsManager = LegacyLuaSettingsManager.getInstance();
        super.create();

        // Add instruction text
        var modeText = (legacyLuaMode == MOD_SETTINGS ? "Mod" : "Song Category");
        var itemText = (legacyLuaMode == MOD_SETTINGS ? "mod" : "category");
        var actionText = (legacyLuaMode == MOD_SETTINGS ? "mod in normal freeplay" : "songs in Legacy Lua freeplay");
        var controlText = (legacyLuaMode == MOD_SETTINGS ? "" : " | CTRL: Category settings");

        instructText = new FlxText(50, 50, FlxG.width - 100,
            "Legacy Lua " + modeText + " Settings\n\n" +
            "UP/DOWN: Navigate " + itemText + "s | ENTER: Configure setting | R: Reset to Player Choice\n" +
            "SPACE: Test " + actionText + " | BACK: Return to main settings menu" + controlText + "\n\n" +
            "Setting Colors: White = Player Choice | Green = Force Legacy Lua ON | Red = Force Legacy Lua OFF", 14);
        instructText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        instructText.scrollFactor.set();
        add(instructText);

        updateMenuItemColors();
    }

    override function update(elapsed:Float):Void {
        // Handle Legacy Lua settings mode switching first
        if (!options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode) {
            // If we're no longer in Legacy Lua settings mode, exit
            MusicBeatState.switchState(new states.CategoryState());
            return;
        }

        // Handle CONTROL key before calling super.update to prevent parent from handling it
        if (FlxG.keys.justPressed.CONTROL && !inDialogue) {
            if (legacyLuaMode == SONG_SETTINGS) {
                // Allow categories menu only in song settings mode
                FlxG.sound.play(Paths.sound('confirmMenu'));
                openSubState(new options.CategoriesSubstate());
            } else {
                // In mod settings mode, ignore CONTROL (no categories menu)
                FlxG.sound.play(Paths.sound('cancelMenu')); // Play error sound
            }
            return;
        }

        if (controls.RESET && !inDialogue) {
            // Reset setting for current selection
            if (CategoryState.curSelected < menuItems.length) {
                var selectedMod = menuItems[CategoryState.curSelected];
                if (legacyLuaMode == MOD_SETTINGS) {
                    settingsManager.setModSetting(selectedMod, PLAYER_CHOICE);
                    updateMenuItemColors();
                }
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
        } else if (FlxG.keys.justPressed.SPACE && !inDialogue) {
            // Test the selected mod/category
            if (legacyLuaMode == SONG_SETTINGS) {
                // Go to LegacyLuaFreeplayState for testing songs
                var selectedCategory = menuItems[CategoryState.curSelected];
                CategoryState.loadWeekForce = selectedCategory.toLowerCase();
                MusicBeatState.switchState(new options.legacylua.LegacyLuaFreeplayState());
            } else {
                // For mod settings, we can test by going to regular freeplay
                var selectedMod = menuItems[CategoryState.curSelected];
                CategoryState.loadWeekForce = selectedMod.toLowerCase();
                states.CategoryState.legacyLuaMode = null; // Clear settings mode for testing
                MusicBeatState.switchState(new states.freeplay.FreeplayState());
            }
            return;
        } else if (controls.ACCEPT && !menuLocks[CategoryState.curSelected] && !inDialogue) {
            // Handle Legacy Lua settings mode
            FlxG.sound.play(Paths.sound('confirmMenu'));

            if (legacyLuaMode == MOD_SETTINGS) {
                openModSettingsMenu();
            } else {
                openSongSettingsMenu();
            }
            return;
        } else if (controls.BACK && !inDialogue) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new options.legacylua.LegacyLuaSettingsState());
            return;
        }

        // Call super.update but skip the CONTROL key handling since we handled it above
        // Need to be careful not to call super's CONTROL handling
        super.update(elapsed);
    }

    private function openModSettingsMenu():Void {
        var selectedMod = menuItems[CategoryState.curSelected];
        var currentSetting = settingsManager.getModSetting(selectedMod);

        persistentUpdate = false;
        openSubState(new options.legacylua.LegacyLuaSettingsSubState(selectedMod, null, currentSetting, function(newSetting:LegacyLuaSetting) {
            settingsManager.setModSetting(selectedMod, newSetting);
            updateMenuItemColors();
        }));
    }

    private function openSongSettingsMenu():Void {
        // Go to LegacyLuaFreeplayState for song selection
        var selectedCategory = menuItems[CategoryState.curSelected];
        CategoryState.loadWeekForce = selectedCategory.toLowerCase();
        MusicBeatState.switchState(new options.legacylua.LegacyLuaFreeplayState());
    }

    private function updateMenuItemColors():Void {
        if (legacyLuaMode != MOD_SETTINGS) return;

        // Update colors based on settings
        for (i in 0...grpMenuShit.members.length) {
            var item = grpMenuShit.members[i];
            if (i >= menuItems.length) continue;

            var modName = menuItems[i];
            var setting = settingsManager.getModSetting(modName);

            var color:FlxColor = switch (setting) {
                case null | PLAYER_CHOICE: FlxColor.WHITE;
                case FORCE_ON: FlxColor.GREEN;
                case FORCE_OFF: FlxColor.RED;
            }

            // Update the alphabet color
            if (item != null) {
                item.color = color;
            }
        }
    }

    override function closeSubState():Void {
        super.closeSubState();
        updateMenuItemColors();
    }

    override function destroy():Void {
        // Don't reset the legacyLuaMode here since we might be transitioning between Legacy Lua states
        // It should be reset when exiting the entire Legacy Lua settings system
        super.destroy();
    }
}
