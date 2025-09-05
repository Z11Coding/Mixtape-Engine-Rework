package options.legacylua;

import backend.Mods;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

enum LegacyLuaSetting {
    PLAYER_CHOICE; // Use the player's choice from GameplaySettingsSubstate
    FORCE_ON;      // Always use Legacy Lua for this mod/song
    FORCE_OFF;     // Never use Legacy Lua for this mod/song
}

typedef ModLegacySettings = {
    var modSetting:LegacyLuaSetting;
    var songSettings:Map<String, LegacyLuaSetting>;
}

/**
 * Manages Legacy Lua settings for individual mods and songs.
 * Song settings take priority over mod settings and player choice.
 * Each mod has its own settings file stored in its directory.
 *
 * Priority order (highest to lowest):
 * 1. Song Setting (per song within mod)
 * 2. Mod Setting (per mod)
 * 3. Player Choice (from GameplaySettingsSubstate)
 */
class LegacyLuaSettingsManager {
    private static var instance:LegacyLuaSettingsManager;

    private var loadedModSettings:Map<String, ModLegacySettings> = new Map<String, ModLegacySettings>();

    private static final SETTINGS_FILE:String = "legacyLuaSettings.json";

    public static function getInstance():LegacyLuaSettingsManager {
        if (instance == null) {
            instance = new LegacyLuaSettingsManager();
        }
        return instance;
    }

    private function new() {}

    /**
     * Determines whether Legacy Lua should be used for a specific song/mod combination
     * @param songName The name of the song
     * @param modName The name of the mod (empty string for base game)
     * @return True if Legacy Lua should be used
     */
    public function shouldUseLegacyLua(songName:String, modName:String = ""):Bool {
        // For base game, always use player choice
        if (modName == null || modName.length == 0) {
            return ClientPrefs.getGameplaySetting('legacyMode', false);
        }

        var modSettings = getModSettings(modName);
        if (modSettings == null) {
            return ClientPrefs.getGameplaySetting('legacyMode', false);
        }

        // Priority 1: Check song setting
        var songKey = songName.toLowerCase();
        if (modSettings.songSettings.exists(songKey)) {
            var setting = modSettings.songSettings.get(songKey);
            return switch (setting) {
                case FORCE_ON: true;
                case FORCE_OFF: false;
                case PLAYER_CHOICE: ClientPrefs.getGameplaySetting('legacyMode', false);
            }
        }

        // Priority 2: Check mod setting
        return switch (modSettings.modSetting) {
            case FORCE_ON: true;
            case FORCE_OFF: false;
            case PLAYER_CHOICE: ClientPrefs.getGameplaySetting('legacyMode', false);
        }
    }

    /**
     * Sets the Legacy Lua setting for a specific mod
     * @param modName The mod name
     * @param setting The Legacy Lua setting
     */
    public function setModSetting(modName:String, setting:LegacyLuaSetting):Void {
        var modSettings = getOrCreateModSettings(modName);
        modSettings.modSetting = setting;
        saveModSettings(modName, modSettings);
    }

    /**
     * Sets the Legacy Lua setting for a specific song
     * @param songName The song name
     * @param modName The mod name
     * @param setting The Legacy Lua setting
     */
    public function setSongSetting(songName:String, modName:String, setting:LegacyLuaSetting):Void {
        var modSettings = getOrCreateModSettings(modName);
        var songKey = songName.toLowerCase();

        if (setting == PLAYER_CHOICE && modSettings.songSettings.exists(songKey)) {
            modSettings.songSettings.remove(songKey);
        } else {
            modSettings.songSettings.set(songKey, setting);
        }

        saveModSettings(modName, modSettings);
    }

    /**
     * Gets the Legacy Lua setting for a mod
     * @param modName The mod name
     * @return The setting, or null if no setting exists
     */
    public function getModSetting(modName:String):Null<LegacyLuaSetting> {
        var modSettings = getModSettings(modName);
        return modSettings != null ? modSettings.modSetting : null;
    }

    /**
     * Gets the Legacy Lua setting for a song
     * @param songName The song name
     * @param modName The mod name
     * @return The setting, or null if no setting exists
     */
    public function getSongSetting(songName:String, modName:String):Null<LegacyLuaSetting> {
        var modSettings = getModSettings(modName);
        if (modSettings == null) return null;

        var songKey = songName.toLowerCase();
        return modSettings.songSettings.exists(songKey) ? modSettings.songSettings.get(songKey) : null;
    }

    /**
     * Gets all available mods
     * @return Array of mod names
     */
    public function getAllMods():Array<String> {
        var modsList = Mods.parseList();
        return modsList.all.copy();
    }

    /**
     * Gets all Legacy Lua settings for a specific mod
     * @param modName The mod name
     * @return The mod's Legacy Lua settings, or null if not found
     */
    public function getModSettings(modName:String):Null<ModLegacySettings> {
        if (loadedModSettings.exists(modName)) {
            return loadedModSettings.get(modName);
        }

        // Try to load from file
        var settings = loadModSettings(modName);
        if (settings != null) {
            loadedModSettings.set(modName, settings);
        }

        return settings;
    }

    /**
     * Gets or creates mod settings
     */
    private function getOrCreateModSettings(modName:String):ModLegacySettings {
        var settings = getModSettings(modName);
        if (settings == null) {
            settings = {
                modSetting: PLAYER_CHOICE,
                songSettings: new Map<String, LegacyLuaSetting>()
            };
            loadedModSettings.set(modName, settings);
        }
        return settings;
    }

    /**
     * Clears all settings for a mod
     */
    public function clearModSettings(modName:String):Void {
        if (loadedModSettings.exists(modName)) {
            loadedModSettings.remove(modName);
        }

        var settingsPath = getModSettingsPath(modName);
        if (FileSystem.exists(settingsPath)) {
            try {
                FileSystem.deleteFile(settingsPath);
            } catch (e:Dynamic) {
                trace("Error deleting mod settings file: " + e);
            }
        }
    }

    /**
     * Gets the path to a mod's settings file
     */
    private function getModSettingsPath(modName:String):String {
        return Paths.mods(modName + "/" + SETTINGS_FILE);
    }

    /**
     * Saves settings for a specific mod to its file
     */
    private function saveModSettings(modName:String, settings:ModLegacySettings):Void {
        try {
            var modPath = Paths.mods(modName);
            if (!FileSystem.exists(modPath)) {
                FileSystem.createDirectory(modPath);
            }

            var data = {
                modSetting: settingToString(settings.modSetting),
                songSettings: {}
            };

            // Convert song settings map to object
            for (songKey => setting in settings.songSettings) {
                Reflect.setField(data.songSettings, songKey, settingToString(setting));
            }

            var json = Json.stringify(data, null, "  ");
            var filePath = getModSettingsPath(modName);
            File.saveContent(filePath, json);

            // Update cached settings
            loadedModSettings.set(modName, settings);
        } catch (e:Dynamic) {
            trace("Error saving Legacy Lua settings for mod '" + modName + "': " + e);
        }
    }

    /**
     * Loads settings for a specific mod from its file
     */
    private function loadModSettings(modName:String):Null<ModLegacySettings> {
        try {
            var filePath = getModSettingsPath(modName);
            if (!FileSystem.exists(filePath)) {
                return null; // No settings file exists
            }

            var content = File.getContent(filePath);
            var data:Dynamic = Json.parse(content);

            var settings:ModLegacySettings = {
                modSetting: stringToSetting(data.modSetting),
                songSettings: new Map<String, LegacyLuaSetting>()
            };

            // Load song settings
            if (data.songSettings != null) {
                for (field in Reflect.fields(data.songSettings)) {
                    var settingStr:String = Reflect.field(data.songSettings, field);
                    var setting = stringToSetting(settingStr);
                    if (setting != null) {
                        settings.songSettings.set(field, setting);
                    }
                }
            }

            return settings;
        } catch (e:Dynamic) {
            trace("Error loading Legacy Lua settings for mod '" + modName + "': " + e);
            return null;
        }
    }

    /**
     * Converts a LegacyLuaSetting to string for JSON storage
     */
    private function settingToString(setting:LegacyLuaSetting):String {
        return switch (setting) {
            case PLAYER_CHOICE: "player_choice";
            case FORCE_ON: "force_on";
            case FORCE_OFF: "force_off";
        }
    }

    /**
     * Converts a string to LegacyLuaSetting from JSON storage
     */
    private function stringToSetting(str:String):Null<LegacyLuaSetting> {
        return switch (str) {
            case "player_choice": PLAYER_CHOICE;
            case "force_on": FORCE_ON;
            case "force_off": FORCE_OFF;
            default: PLAYER_CHOICE; // Default fallback
        }
    }
}
