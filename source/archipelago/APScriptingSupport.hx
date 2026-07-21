package archipelago;

import archipelago.APGameState;
import archipelago.APItem;
import archipelago.APEntryState;
import archipelago.APInfo;
import psychlua.FunkinLua;
import psychlua.HScript;
import backend.ClientPrefs;

/**
 * Archipelago Scripting Support
 * Provides callback system for items received/sent for both Lua and HScript
 */
class APScriptingSupport
{
    // Callback storage
    private static var itemReceivedCallbacks:Array<String->Void> = [];
    private static var itemSentCallbacks:Array<String->Void> = [];
    private static var customItemReceivedCallbacks:Array<String->Void> = [];
    private static var locationSentCallbacks:Array<String->Int->Void> = [];

    // Variables available to scripts - removed currentSlotData since it's always accessed through APInfo

    /**
     * Initialize Archipelago scripting support
     */
    public static function initialize():Void
    {
        if (!APInfo.inArchipelagoMode) return;

        trace("Initializing Archipelago scripting support");

        // Clear existing callbacks
        itemReceivedCallbacks = [];
        itemSentCallbacks = [];
        customItemReceivedCallbacks = [];
        locationSentCallbacks = [];
    }

    /**
     * Called when Archipelago mode is enabled
     */
    public static function enableArchipelagoMode():Void
    {
        // Mode is controlled by APInfo.inArchipelagoMode
        initialize();
    }

    /**
     * Called when Archipelago mode is disabled
     */
    public static function disableArchipelagoMode():Void
    {
        // Mode is controlled by APInfo.inArchipelagoMode
        itemReceivedCallbacks = [];
        itemSentCallbacks = [];
        customItemReceivedCallbacks = [];
        locationSentCallbacks = [];
    }

    /**
     * Called when an item is received from Archipelago
     */
    public static function onItemReceived(itemName:String, isCustomItem:Bool = false):Void
    {
        if (!APInfo.inArchipelagoMode) return;

        trace('AP Script Support: Item received - $itemName (custom: $isCustomItem)');

        // Validate item against slot data (only for non-custom items)
        if (!isCustomItem && !validateItem(itemName))
        {
            trace('Warning: Received item "${itemName}" is not in slot data');
        }

        // Call general item received callbacks
        for (callback in itemReceivedCallbacks)
        {
            try
            {
                callback(itemName);
            }
            catch (e:Dynamic)
            {
                trace('Error in item received callback: $e');
            }
        }

        // Call custom item callbacks if this is a custom item
        if (isCustomItem)
        {
            for (callback in customItemReceivedCallbacks)
            {
                try
                {
                    callback(itemName);
                }
                catch (e:Dynamic)
                {
                    trace('Error in custom item received callback: $e');
                }
            }
        }

        // Call the appropriate functions in running scripts
        if (states.PlayState.instance != null)
        {
            var playState = states.PlayState.instance;

            #if LUA_ALLOWED
            // Call Lua scripts
            for (script in playState.luaArray)
            {
                if (script != null && !script.closed)
                {
                    // Try to call onItemReceived callback
                    script.call('onItemReceived', [itemName, isCustomItem]);

                    // If it's a custom item, also call onCustomItemReceived
                    if (isCustomItem)
                    {
                        script.call('onCustomItemReceived', [itemName]);
                    }
                }
            }
            #end

            #if HSCRIPT_ALLOWED
            // Call HScript scripts
            for (script in playState.hscriptArray)
            {
                if (script != null)
                {
                    // Try to call onItemReceived callback
                    if (script.exists('onItemReceived'))
                    {
                        script.call('onItemReceived', [itemName, isCustomItem]);
                    }

                    // If it's a custom item, also call onCustomItemReceived
                    if (isCustomItem && script.exists('onCustomItemReceived'))
                    {
                        script.call('onCustomItemReceived', [itemName]);
                    }
                }
            }
            #end
        }
    }

    /**
     * Called when an item is sent to Archipelago
     */
    public static function onItemSent(itemName:String):Void
    {
        if (!APInfo.inArchipelagoMode) return;

        trace('AP Script Support: Item sent - $itemName');

        for (callback in itemSentCallbacks)
        {
            try
            {
                callback(itemName);
            }
            catch (e:Dynamic)
            {
                trace('Error in item sent callback: $e');
            }
        }

        // Call the appropriate functions in running scripts
        if (states.PlayState.instance != null)
        {
            var playState = states.PlayState.instance;

            #if LUA_ALLOWED
            // Call Lua scripts
            for (script in playState.luaArray)
            {
                if (script != null && !script.closed)
                {
                    script.call('onItemSent', [itemName]);
                }
            }
            #end

            #if HSCRIPT_ALLOWED
            // Call HScript scripts
            for (script in playState.hscriptArray)
            {
                if (script != null && script.exists('onItemSent'))
                {
                    script.call('onItemSent', [itemName]);
                }
            }
            #end
        }
    }

    /**
     * Called when a location is sent to Archipelago
     */
    public static function onLocationSent(locationName:String, locationId:Int):Void
    {
        if (!APInfo.inArchipelagoMode) return;

        trace('AP Script Support: Location sent - $locationName (ID: $locationId)');

        for (callback in locationSentCallbacks)
        {
            try
            {
                callback(locationName, locationId);
            }
            catch (e:Dynamic)
            {
                trace('Error in location sent callback: $e');
            }
        }

        // Call the appropriate functions in running scripts
        if (states.PlayState.instance != null)
        {
            var playState = states.PlayState.instance;

            #if LUA_ALLOWED
            // Call Lua scripts
            for (script in playState.luaArray)
            {
                if (script != null && !script.closed)
                {
                    script.call('onLocationSent', [locationName, locationId]);
                }
            }
            #end

            #if HSCRIPT_ALLOWED
            // Call HScript scripts
            for (script in playState.hscriptArray)
            {
                if (script != null && script.exists('onLocationSent'))
                {
                    script.call('onLocationSent', [locationName, locationId]);
                }
            }
            #end
        }
    }

    /**
     * Register an item received callback
     */
    public static function registerItemReceivedCallback(callback:String->Void):Void
    {
        if (!itemReceivedCallbacks.contains(callback))
        {
            itemReceivedCallbacks.push(callback);
        }
    }

    /**
     * Register an item sent callback
     */
    public static function registerItemSentCallback(callback:String->Void):Void
    {
        if (!itemSentCallbacks.contains(callback))
        {
            itemSentCallbacks.push(callback);
        }
    }

    /**
     * Register a custom item received callback
     */
    public static function registerCustomItemReceivedCallback(callback:String->Void):Void
    {
        if (!customItemReceivedCallbacks.contains(callback))
        {
            customItemReceivedCallbacks.push(callback);
        }
    }

    /**
     * Register a location sent callback
     */
    public static function registerLocationSentCallback(callback:String->Int->Void):Void
    {
        if (!locationSentCallbacks.contains(callback))
        {
            locationSentCallbacks.push(callback);
        }
    }

    /**
     * Send a location to Archipelago (for use by scripts)
     * Uses songData from slot data to find the location ID
     */
    public static function sendLocation(locationName:String):Bool
    {
        if (!APInfo.inArchipelagoMode)
        {
            trace('Cannot send location: Archipelago mode not enabled');
            return false;
        }

        // Validate location name
        if (locationName == null || locationName.trim() == "")
        {
            var errorMsg = 'Invalid location name: Location name cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Check if APGameState and connection are available
        if (APGameState.instance == null)
        {
            trace('Cannot send location: APGameState instance not available');
            return false;
        }

        if (APGameState.instance.info() == null)
        {
            trace('Cannot send location: Not connected to Archipelago');
            return false;
        }

        // Get slot data from APInfo
        var slotData = APInfo.slotData;
        if (slotData == null)
        {
            var errorMsg = 'Cannot send location: Slot data not available from APInfo';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Look for location in songData
        var locationId:Int = -1;

        // Check if location exists directly in songData (key-based lookup)
        if (slotData.songData.exists(locationName))
        {
            var songData = slotData.songData.get(locationName);
            locationId = songData.id;
        }
        else
        {
            // Try to find location by searching through all songData entries by songName
            for (songKey in slotData.songData.keys())
            {
                var songData = slotData.songData.get(songKey);
                if (songData.songName == locationName)
                {
                    locationId = songData.id;
                    break;
                }
            }
        }

        if (locationId == -1)
        {
            var errorMsg = 'Location "${locationName}" not found in slot data songData. Available songs: ${[for (key in slotData.songData.keys()) key].join(", ")}';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Validate location ID
        if (locationId <= 0)
        {
            var errorMsg = 'Invalid location ID for location "${locationName}": ${locationId}';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        // Send to Archipelago via APGameState
        try
        {
            var locations:Array<Int> = [locationId];
            APGameState.instance.info().LocationChecks(locations);
            onLocationSent(locationName, locationId);
            trace('Successfully sent location "${locationName}" with ID ${locationId}');
            return true;
        }
        catch (e:Dynamic)
        {
            var errorMsg = 'Failed to send location "${locationName}" (ID: ${locationId}): ${e}';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }
    }

    /**
     * Check if a specific item has been received
     */
    public static function hasItem(itemName:String):Bool
    {
        if (!APInfo.inArchipelagoMode || APGameState.instance == null) return false;

        return APGameState.instance.APItems.exists(itemName);
    }

    /**
     * Get item count
     */
    public static function getItemCount(itemName:String):Int
    {
        if (!APInfo.inArchipelagoMode || APGameState.instance == null) return 0;

        return APGameState.instance.APItems.exists(itemName) ? APGameState.instance.APItems.get(itemName) : 0;
    }

    /**
     * Check if connected to Archipelago
     */
    public static function isConnected():Bool
    {
        return APInfo.inArchipelagoMode && APGameState.instance != null && APGameState.instance.info() != null;
    }

    /**
     * Get current player name
     */
    public static function getPlayerName():String
    {
        if (!APInfo.inArchipelagoMode || APGameState.instance == null || APGameState.instance.info() == null) return "";

        return APGameState.instance.info().slot;
    }

    /**
     * Validate that an origin song exists and is valid for location creation
     */
    public static function validateOriginSong(originSong:String, locationName:String = ""):Void
    {
        if (originSong == null || originSong.trim() == "")
        {
            var errorMsg = 'Invalid origin song for location "${locationName}": Origin song cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        if (!APInfo.inArchipelagoMode) return;

        var slotData = APInfo.slotData;
        if (slotData == null)
        {
            trace('Cannot validate origin song: Slot data not available from APInfo');
            return;
        }

        // Check if origin song exists in selectedSongs
        for (songName in slotData.selectedSongs)
        {
            if (songName == originSong)
            {
                return; // Valid origin song
            }
        }

        // Check if origin song exists in songData
        if (slotData.songData.exists(originSong))
        {
            return; // Valid origin song
        }

        // Check if origin song exists by searching songData values
        for (songData in slotData.songData)
        {
            if (songData.songName == originSong)
            {
                return; // Valid origin song
            }
        }

        // Check against base game songs (these are always valid)
        var allBaseSongs = APInfo.baseGame.concat(APInfo.baseErect).concat(APInfo.basePico).concat(APInfo.secrets);
        for (baseSong in allBaseSongs)
        {
            if (baseSong.toLowerCase() == originSong.toLowerCase())
            {
                return; // Valid base game song
            }
        }

        var errorMsg = 'Invalid origin song for location "${locationName}": Origin song "${originSong}" not found in slot data or base game songs';
        trace(errorMsg);
        throw new haxe.Exception(errorMsg);
    }

    /**
     * Check if a song is available in the current Archipelago slot data
     * @param songName The song name to check
     * @return true if the song is available, false otherwise
     */
    public static function isSongAvailable(songName:String):Bool
    {
        if (songName == null || songName.trim() == "")
        {
            return false;
        }

        if (!APInfo.inArchipelagoMode)
        {
            return true; // All songs available when not in AP mode
        }

        var slotData = APInfo.slotData;
        if (slotData == null)
        {
            return false; // Can't determine availability without slot data
        }

        // Check if song exists in selectedSongs
        for (selectedSong in slotData.selectedSongs)
        {
            if (selectedSong == songName)
            {
                return true;
            }
        }

        // Check if song exists in songData
        if (slotData.songData.exists(songName))
        {
            return true;
        }

        // Check if song exists by searching songData values
        for (songData in slotData.songData)
        {
            if (songData.songName == songName)
            {
                return true;
            }
        }

        // Check against base game songs (these are always available)
        var allBaseSongs = APInfo.baseGame.concat(APInfo.baseErect).concat(APInfo.basePico).concat(APInfo.secrets);
        for (baseSong in allBaseSongs)
        {
            if (baseSong.toLowerCase() == songName.toLowerCase())
            {
                return true;
            }
        }

        return false; // Song not found
    }

    /**
     * Validate that an item exists in the slot data before processing
     */
    public static function validateItem(itemName:String):Bool
    {
        if (!APInfo.inArchipelagoMode) return false;

        if (itemName == null || itemName.trim() == "")
        {
            var errorMsg = 'Invalid item name: Item name cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }

        var slotData = APInfo.slotData;
        if (slotData == null)
        {
            trace('Cannot validate item: Slot data not available from APInfo');
            return false;
        }

        // Check if item exists in selectedSongs
        for (songName in slotData.selectedSongs)
        {
            if (songName == itemName)
            {
                return true;
            }
        }

        // Check if item exists in songData
        if (slotData.songData.exists(itemName))
        {
            return true;
        }

        // Check if item exists by searching songData values
        for (songData in slotData.songData)
        {
            if (songData.songName == itemName)
            {
                return true;
            }
        }

        trace('Item "${itemName}" not found in slot data');
        return false;
    }

    /**
     * Get available songs from slot data (for scripts)
     */
    public static function getAvailableSongs():Array<String>
    {
        if (!APInfo.inArchipelagoMode) return [];

        var slotData = APInfo.slotData;
        if (slotData == null) return [];

        return slotData.selectedSongs.copy();
    }

    /**
     * Get song data for a specific song (for scripts)
     */
    public static function getSongData(songName:String):Dynamic
    {
        if (!APInfo.inArchipelagoMode) return null;

        var slotData = APInfo.slotData;
        if (slotData == null) return null;

        if (slotData.songData.exists(songName))
        {
            var songData = slotData.songData.get(songName);
            return {
                id: songData.id,
                modded: songData.modded,
                playerOwner: songData.playerOwner,
                sharedWith: songData.sharedWith.copy(),
                songName: songData.songName
            };
        }

        return null;
    }

    /**
     * Get slot data field from APInfo
     */
    public static function getSlotDataField(fieldName:String):Dynamic
    {
        if (!APInfo.inArchipelagoMode) return null;

        var slotData = APInfo.slotData;
        if (slotData == null) return null;

        return slotData.get(fieldName);
    }

    /**
     * Validate song name for Archipelago locations
     * Throws an exception if the song name is invalid
     */
    public static function validateSongName(songName:String, ?context:String = ""):Void
    {
        if (songName == null || songName.trim() == "")
        {
            var errorMsg = 'Invalid song name${context != "" ? " for " + context : ""}: Song name cannot be null or empty';
            trace(errorMsg);
            throw new haxe.Exception(errorMsg);
        }
    }

}
