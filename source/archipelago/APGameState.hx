package archipelago;

import yutautil.AprilFools;
import haxe.DynamicAccess;
import states.FreeplayState;
import yutautil.MemoryHelper;
import flixel.FlxState;
import archipelago.Client;
import archipelago.PacketTypes;
import archipelago.APDisconnectSubstate;
import archipelago.APCategoryState;
import backend.WeekData;
import haxe.ds.Option;

// Enums
enum PrintJsonType {
    ItemSend; ItemCheat; Hint; Join; Part; Chat; ServerChat; Tutorial; TagsChanged; CommandResult; AdminCommandResult; Goal; Release; Collect; Countdown;
}

// enum ClientStatus {
//     CLIENT_UNKNOWN; CLIENT_CONNECTED; CLIENT_READY; CLIENT_PLAYING; CLIENT_GOAL;
// }

enum PacketProblemType {
    cmd; arguments;
}

enum SetReplyPacketType {
    key; value; original_value;
}

enum ItemFlag {
    None; // Nothing special about this item
    LogicalAdvancement; // Indicates the item can unlock logical advancement
    Important; // Indicates the item is especially useful
    Trap; // Indicates the item is a trap
}

enum DataStorageOperationType {
    replace; _default; add; mul; pow; mod; floor; ceil; max; min; and; or; xor; left_shift; right_shift; remove; pop; update;
}

enum ClientState {
    spectator; player; group;
}

// enum Permission {
//     disabled; enabled; goal; auto; auto_enabled;
// }

// Types
// typedef NetworkVersion = { major: Int, minor: Int, build: Int };
// typedef NetworkPlayer = { team: Int, slot: Int, alias: String, name: String };
// typedef NetworkItem = { item: Int, location: Int, player: Int, flags: Int };
// typedef JSONMessagePart = { type: Option<String>, text: Option<String>, color: Option<String>, flags: Option<Int>, player: Option<Int> };
// typedef Hint = { receiving_player: Int, finding_player: Int, location: Int, item: Int, found: Bool, entrance: String, item_flags: Int };
// typedef GameData = { item_name_to_id: Map<String, Int>, location_name_to_id: Map<String, Int>, version: Int, checksum: String };
// typedef NetworkSlot = { name: String, game: String, type: ClientState, group_members: Array<Int> };

// Packet Structures
typedef RoomInfoPacket = {
    version: NetworkVersion,
    generator_version: NetworkVersion,
    tags: Array<String>,
    password: Bool,
    permissions: Map<String, Permission>,
    hint_cost: Int,
    location_check_points: Int,
    games: Array<String>,
    datapackage_versions: Map<String, Int>,
    datapackage_checksums: Map<String, String>,
    seed_name: String,
    time: Float
};

typedef ConnectionRefusedPacket = { errors: Option<Array<String>> };
typedef ConnectedPacket = { team: Int, slot: Int, players: Array<NetworkPlayer>, missing_locations: Array<Int>, checked_locations: Array<Int>, slot_data: Map<String, Dynamic>, slot_info: Map<Int, NetworkSlot>, hint_points: Int };
typedef ReceivedItemsPacket = { index: Int, items: Array<NetworkItem> };
typedef LocationInfoPacket = { locations: Array<NetworkItem> };
typedef RoomUpdatePacket = { players: Array<NetworkPlayer>, checked_locations: Array<Int>, missing_locations: Array<Int> };
typedef PrintJSONPacket = { data: Array<JSONMessagePart>, type: Option<PrintJsonType>, receiving: Option<Int>, item: Option<NetworkItem>, found: Option<Bool>, team: Option<Int>, slot: Option<Int>, message: Option<String>, tags: Option<Array<String>>, countdown: Option<Int> };
typedef DataPackagePacket = { data: Dynamic };
typedef BouncedPacket = { games: Option<Array<String>>, slots: Option<Array<Int>>, tags: Option<Array<String>>, data: Option<Dynamic> };
typedef RetrievedPacket = { keys: Map<String, Dynamic> };
typedef SetReplyPacket = { key: String, value: Dynamic, original_value: Option<Dynamic> };
typedef ConnectPacket = { password: String, game: String, name: String, uuid: String, version: NetworkVersion, items_handling: Int, tags: Array<String>, slot_data: Option<Bool> };
typedef ConnectUpdatePacket = { items_handling: Int, tags: Array<String> };
typedef SyncPacket = {};
typedef LocationChecksPacket = { locations: Array<Int> };
typedef LocationScoutsPacket = { locations: Array<Int>, create_as_hint: Int };
typedef StatusUpdatePacket = { status: ClientStatus };
typedef SayPacket = { text: String };
typedef GetDataPackagePacket = { games: Option<Array<String>> };
typedef BouncePacket = { games: Option<Array<String>>, slots: Option<Array<Int>>, tags: Option<Array<String>>, data: Option<Dynamic> };
typedef GetPacket = { keys: Array<String> };
typedef SetPacket = { key: String, _default: Dynamic, want_reply: Bool, operations: Array<DataStorageOperation> };
typedef SetNotifyPacket = { keys: Array<String> };


class APGameState {

    public static var instance:APGameState;

    private var _ap:Client;
    private var _seed:String;
    private var _disconnectSubstate:APDisconnectSubstate;
    private var _saveData:yutautil.save.MixSaveWrapper;
    public var connected(get, never):Bool;

    public var APLocations:Array<Int> = [];
    public var APItems:Map<String, Int> = new Map<String, Int>();
    public var ItemIndex:Int = -1;

    public function locationData(songName:String):Array<Int> {
        try {
            if (!APInfo.hasSongChecks) {
                return [];
            }
            // trace("Starting locationData function with songName: " + songName);
            var matchingLocations:Array<Int> = [];
            var exactMatch:Int = -1;
            var hasDashNumber:Bool = false;
            var reg = new EReg("^" + EReg.escape(songName) + "(?:-\\d+)?$", "");
            var apInfo = info();

            for (location in APLocations) {
                var locationName = apInfo.get_location_name(location);

                if (locationName == songName) {
                    exactMatch = location;
                    break;
                } else if (reg.match(locationName)) {
                    matchingLocations.push(location);
                    hasDashNumber = true;
                }
            }

            if (!hasDashNumber && exactMatch != -1) {
                return [exactMatch];
            }

            // trace("Matching locations: " + matchingLocations);

            return matchingLocations;
        } catch (e:Dynamic) {
            var errorMessage = "Error in locationData function for song: " + songName + ". Reason: " + Std.string(e);
            trace(errorMessage);
            archipelago.APItem.popup(errorMessage, "Error: Locations", true);
            return [];
        }
    }

    public function noteData(songName:String, modName:String, ?week:String):Array<Int> {
        try {
            if (!APInfo.hasNoteChecks) {
                return [];
            }
            // trace("Starting noteData function with songName: " + songName + " and modName: " + modName);
            var matchingNotes:Array<Int> = [];
            var reg = new EReg("^Note \\d+: " + EReg.escape(songName + (modName != "" ? " (" + modName + ")" : "")) + "$", "");
            var apInfo = info();
        
            for (location in APLocations) {
                var locationName = apInfo.get_location_name(location);
                if (reg.match(locationName)) {
                    matchingNotes.push(location);
                }
            }
        
            if (matchingNotes.length == 0) {
                for (song in WeekData.getCurrentWeek().songs) {
                    if ((cast song[0] : String).toLowerCase().trim() == songName.toLowerCase().trim() ||
                        (cast song[0] : String).toLowerCase().trim().replace(" ", "-") == songName.toLowerCase().trim().replace(" ", "-")) {
                        var fallbackReg = new EReg("^Note \\d+: " + EReg.escape(song[0] + (modName != "" ? " (" + modName + ")" : "")) + "$", "");
                        for (location in APLocations) {
                            var locationName = apInfo.get_location_name(location);
                            if (fallbackReg.match(locationName)) {
                                trace("Fallback match found: " + locationName);
                                matchingNotes.push(location);
                            }
                        }
                        break;
                    }
                }
            }
        
            if (matchingNotes.length == 0) {
                for (song in WeekData.getCurrentWeek().songs) {
                    var songPath = modName.trim() != ""
                        ? "mods/" + modName + "/data/" + song[0] + "/" + song[0] + "-" + Difficulty.getString(PlayState.storyDifficulty) + ".json"
                        : "assets/shared/data/" + (song[0] + Difficulty.getFilePath());
        
                    var songJson:backend.Song.SwagSong = null;
                    var jsonStuff:Array<String> = modName.trim() != "" 
                        ? Paths.crawlDirectory("mods/" + modName + "/data", ".json") 
                        : Paths.crawlDirectory("assets/shared/data", ".json");
        
                    for (json in jsonStuff) {
                        if (json.trim().toLowerCase().replace(" ", "-") == songPath.trim().toLowerCase().replace(" ", "-")) {
                            songJson = backend.Song.parseJSON(File.getContent(json));
                            if (songJson != null) {
                                if (songJson.song.trim().toLowerCase().replace(" ", "-") == songName.toLowerCase().trim().replace(" ", "-")) {
                                    var fallbackReg = new EReg("^Note \\d+: " + EReg.escape(song[0] + (modName != "" ? " (" + modName + ")" : "")) + "$", "");
                                    for (location in APLocations) {
                                        var locationName = apInfo.get_location_name(location);
                                        if (fallbackReg.match(locationName)) {
                                            trace("Secondary fallback match found: " + locationName);
                                            matchingNotes.push(location);
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        
            return matchingNotes;
        } catch (e:Dynamic) {
            var errorMessage = "Error in noteData function for song: " + songName + " and mod: " + modName + ". Reason: " + Std.string(e);
            trace(errorMessage);
            archipelago.APItem.popup(errorMessage, "Error: Note Checks", true);
            return [];
        }
    }

    public function getSongLocations(songName:String, modName:String):Array<Int> {
        return locationData(songName + (modName != "" ? " (" + modName + ")" : "")).concat(noteData(songName, modName));
    }

    public function checkGoal(songName:String, modName:String):Bool {
        var info = info();
        var locations = locationData(songName + (modName != "" ? " (" + modName + ")" : "")).concat(noteData(songName, modName));
        for (location in locations) {
            if (info.missingLocations.contains(location)) {
                return false;
            }
        }
        if (states.FreeplayState.isVictorySong(songName, modName)) {
            setGoal();
            return true;
        }
        return false;
    }

    public function setGoal():Void {
        info().set_goal();
    }

    public function excludeCheckedLocations(locations:Array<Int>):Array<Int> {
        var checkedLocations:Array<Int> = info().checkedLocations;
        var uncheckedLocations:Array<Int> = [];

        for (location in locations) {
            if (!checkedLocations.contains(location)) {
                uncheckedLocations.push(location);
            }
        }

        return uncheckedLocations;
    }

    public static var currentPackages:DynamicAccess<GameData> = new DynamicAccess<GameData>();

    public var itemManager(get, set):Dynamic;    
    function get_itemManager():Dynamic {
        return null;
    }
    
    function set_itemManager(itemManager:Dynamic):Dynamic {
        return null;
    }
    
    function get_connected():Bool {
       return _ap.clientStatus == ClientStatus.PLAYING || _ap.clientStatus == ClientStatus.CONNECTED || _ap.clientStatus == ClientStatus.GOAL || _ap.clientStatus == ClientStatus.READY;
    }

    public function new(ap:Client, slotData:Dynamic)
    {
        _ap = ap;

        _seed = _ap.seed;

        archipelago.APPlayState.apGame = this;
        archipelago.APInfo.apGame = this;
        archipelago.APInfo.ap = _ap;
        instance = this;

        _disconnectSubstate = new APDisconnectSubstate(_ap);
        _disconnectSubstate.setSeed(_seed);
        _disconnectSubstate.onCancel.add(onCancel);
        _disconnectSubstate.onReconnect.add(onReconnect);

        _ap.onSocketDisconnected.add(onSocketDisconnected);
        _ap.onPrintJSON.add(sendMessage);
		_ap.onPrint.add(sendMessageSimple);
		_ap.onItemsReceived.add(addSongs);
        _ap.onBounced.add(bouncy);
        _ap.onCountdown.add(function(countdown:Int) {
            if (CountdownPopup.instance == null) {
            var popup = new archipelago.CountdownPopup("AP Countdown", "The AP is about to begin!", countdown);
            popup.onFinish = function() {
                // Start the AP!
            };
        } else {
            CountdownPopup.instance.updateCountdown(countdown);
        }
        });

        _ap.toggleDeathLink(ClientPrefs.data.deathlink);

        _ap.onRetrieved.add(function(retrievedPacket:haxe.DynamicAccess<Dynamic>) {
            trace("Retrieved packet: " + retrievedPacket);
            for (key in retrievedPacket.keys()) {
                var value = retrievedPacket.get(key);
                if (key.indexOf("_read_hints_") != -1) {
                    var hint:Hint = cast value;
                        if (!hint.found) {
                            // Grab the location and remove the -# from it.
                            var location = hint.location;
                            var locationName = _ap.get_location_name(location);
                            var dashIndex = locationName.indexOf("-");
                            if (dashIndex != -1) {
                                locationName = locationName.substring(0, dashIndex);
                            }

                            var findingPlayerName = _ap.get_player_alias(hint.finding_player);
                            var receivingPlayerName = _ap.get_player_alias(hint.receiving_player);
                            var itemName = _ap.get_item_name(hint.item, _ap.get_player_game(hint.finding_player));


                            var message:String;
                            if (hint.receiving_player == _ap.slotnr) {
                                message = "This song is found in " + findingPlayerName + "'s World at " + locationName;
                            } else if (hint.finding_player == _ap.slotnr) {
                                message = "This song has " + receivingPlayerName + "'s item: " + itemName;
                            } else {
                                message = "Hint: " + receivingPlayerName + " will find " + itemName + " in " + findingPlayerName + "'s World at " + locationName;
                            }

                            if (FreeplayState.hintTable.exists(locationName)) {
                                FreeplayState.hintTable.set(locationName, FreeplayState.hintTable.get(locationName) + "\n" + message);
                            } else {
                                FreeplayState.hintTable.set(locationName, message);
                            }
                        }
                }
            }
            for (hint in FreeplayState.hintTable.keys()) {
                var message = FreeplayState.hintTable.get(hint);
                trace("Hint: " + hint + " - " + message);
                var hintSong = getSongAndMod(hint);
                FreeplayState.curHinted.set(hintSong.song, hintSong.mod);
            }
        });

        // _ap.onConnect.add(function() {
        //     _ap.clientStatus = ClientStatus.CONNECTED;
        // });

		// _ap.onRoomInfo.add(onRoomInfo);
		// _ap.onSlotRefused.add(onSlotRefused);
		_ap.onSlotConnected.add(onSlotConnected);
        APPlayState.deathByLink = false;
    }

    public function initSaveData():Void {
        var combinedChecksum = haxe.crypto.Sha1.encode(haxe.Json.stringify(currentPackages));
        var saveFileName = "save/ap_" + _ap.slot + "_" + _ap.seed + "_" + combinedChecksum + ".json";
        _saveData = new yutautil.save.MixSaveWrapper(new yutautil.save.MixSave(), saveFileName, true);

        _saveData.addItem("slot", _ap.slot);
        _saveData.fancyFormat = true;
        _saveData.addItem("seed", _seed);
        if (_saveData.hasItem("checksum")) {
            var savedChecksum = _saveData.getItem("checksum");
            if (savedChecksum == combinedChecksum) {
            trace("Checksum matches the current combined checksum.");
            } else {
            trace("Checksum does not match the current combined checksum.");
            }
            
        } else {
            _saveData.addItem("checksum", combinedChecksum);
        }
        if (_saveData.hasItem("itemIndex")) {
            ItemIndex = _saveData.getItem("itemIndex");
        }
        if (_saveData.hasItem("activeItem")) {
            var activeItem = _saveData.getItem("activeItem");
            APItem.activeItem = (activeItem != null && activeItem != "null") ? archipelago.APItem.createItemByName(activeItem) : null;
        }
        if (_saveData.hasItem("waitingItems")) {
            var waitingItems:Array<String> = _saveData.getItem("waitingItems");
            var reg = new EReg("^Chart Modifier Trap \\((.+)\\)$", "");
            for (itemName in waitingItems) {
            if (reg.match(itemName)) {
                var modifier = reg.matched(1);
                archipelago.APItem.APChartModifier.restoreFromSave(modifier);
            } else {
                archipelago.APItem.createItemByName(itemName);
            }
            }
        }
        if (_saveData.hasItem("tickets")) {
            APInfo.ticketCount = _saveData.getItem("tickets");
        }
        if (_saveData.hasItem("shields")) {
            APItem.shields = _saveData.getItem("shields");
        }
        if (_saveData.hasItem("MaxHP")) {
            APItem.maxHPUp = _saveData.getItem("MaxHP");
        }
        _saveData.save();
    }

    public function updateSaveData():Void {
        if (_saveData == null) {
            trace("Save data is not ready yet...");
            return;
        }
        _saveData.addItem("itemIndex", ItemIndex);
        _saveData.addItem("activeItem", APItem.activeItem?.name);
        _saveData.addItem("waitingItems", APItem.getItems().map(item -> item.name).concat([if (APPlayState.ghostChat) "Ghost Chat" else null]).filter(item -> item != null));
        _saveData.addItem("tickets", APInfo.ticketCount);
        _saveData.addItem("shields", APItem.shields);
        _saveData.addItem("MaxHP", APItem.maxHPUp);
        _saveData.save();
        trace("Save data updated!");
    }

    public function info()
    {
        return _ap;
    }

    function bouncy(data:Dynamic)
    {
        if ((Reflect.hasField(data, "cause") && Reflect.hasField(data, "source") && Reflect.hasField(data, "time")) && !APPlayState.deathByLink)
        {
            if (info().slot != data.source) {
                var dl:Dynamic = data;
                if (!APPlayState.deathByLink){
                    APPlayState.deathLinkPacket = dl;
                    APPlayState.deathByLink = true;
                }
            }
        } 
        // trace(data);
    }

    function onSlotConnected(slotData:Dynamic)
    {
        if (APEntryState.deathLink)
            _ap.tags.push("DeathLink");
    }

    function sendMessage(data:Array<JSONMessagePart>, item:Dynamic, receiving:Dynamic)
	{
		var theMessageFM:String = "";
		for (message in data)
		{
			switch (message.type)
			{
				case "player_id":
					theMessageFM += _ap.get_player_alias(Std.parseInt(message.text));
				case "item_id":
					theMessageFM += _ap.get_item_name(Std.parseInt(message.text), _ap.get_player_game(message.player));
				case "location_id":
					theMessageFM += _ap.get_location_name(Std.parseInt(message.text), _ap.get_player_game(message.player));
				default:
					theMessageFM += message.text;
			}
		}
		archipelago.console.MainTab.addMessage(theMessageFM);
	}

	function sendMessageSimple(text:Dynamic)
        archipelago.console.MainTab.addMessage(text);

    public function disconnectAP()
    {
        _ap.disconnect_socket();
        _ap = null;
        if (APEntryState.ap != null)
        {
            APEntryState.ap = null;
        }
    }

    public function getSongAndMod(songName:String):{ song:String, ?mod:String }
    {
        var input = songName;
        var modName = "";
        var firstParenIndex = songName.indexOf("(");
        var endParenIndex = songName.lastIndexOf(")");
        while (firstParenIndex != -1) {
            if (endParenIndex != -1) {
                modName = songName.substring(firstParenIndex + 1, endParenIndex);
                if (isModName(modName)) {
                    songName = songName.substring(0, firstParenIndex).trim();
                    break;
                } else {
                    firstParenIndex = songName.indexOf("(", firstParenIndex + 1);
                }
            } else {
                break;
            }
        }
        if (firstParenIndex == -1 || !isModName(modName)) {
            modName = "";
            songName = input;
        }
        return modName != null && modName != "" ? { song: songName, mod: modName } : { song: songName };
    }

    public function findSpecialItems():Map<String, Int> {
        var specialItems:Map<String, Int> = new Map<String, Int>();
        var apInfo = info();

        // trace("FNF Package: " + currentPackages["Friday Night Funkin"]);
        // trace("Item Name to ID: " + currentPackages["Friday Night Funkin"].item_name_to_id);

        for (item in currentPackages["Friday Night Funkin"].item_name_to_id.keys()) {
            var itemName = item.replace("<cOpen>", "{")
                .replace("<cClose>", "}")
                .replace("<sOpen>", "[")
                .replace("<sClose>", "]");


                var data = getSongAndMod(itemName); // I'm a fuckin' idiot.


            //var itemsWhitelist:
            var isSpecialItem = locationData(itemName).concat(APEntryState.apGame.noteData(data.song, data.mod)).isEmpty();
            if (isSpecialItem) {
                specialItems.set(itemName, currentPackages["Friday Night Funkin"].item_name_to_id.get(item));
            }
        }
        trace("Special Items: " + specialItems);

        return specialItems;
    }

    public static var isSync:Bool = false;
    public static var haventranyet:Bool = true;
    // var tickets:Int = 0;
    function addSongs(song:Array<NetworkItem>)
    { var tickets = 0;
        var nonSongs:Map<String, Int> = [];
        var nonSongsNames:Array<String> = [];
        states.FreeplayState.curMissing.clear();


        for (songName in song)
        {
            var itemName = info().get_item_name(songName.item);

            if (APItems.exists(itemName) && APItems.get(itemName) == songName.item)
            {
            nonSongs.set(itemName, songName.index);
            nonSongsNames.push(itemName);
            continue;
            }

            // Convert special keywords back to actual brackets
            itemName = itemName.replace("<cOpen>", "{")
            .replace("<cClose>", "}")
            .replace("<sOpen>", "[")
            .replace("<sClose>", "]");

            var data = getSongAndMod(itemName);
            trace("Data: " + data.song + " - " + data.mod);

            if (!states.FreeplayState.curUnlocked.exists(data.song))
            {
            if (data.song != "Unknown")
            {
                if (!isSync) ArchPopup.startPopupSong(data.song, 'archColor');
                states.FreeplayState.curUnlocked.set(data.song, data.mod);
                for (song in states.FreeplayState.curUnlocked.keys())
                {
                var parts = song.split("||");
                var key = parts[0];
                var value = parts.length > 1 ? parts[1] : states.FreeplayState.curUnlocked.get(song);
                states.FreeplayState.curUnlocked.set(key, value);
                }
            }
            }
        }

        // nonSongsNames.sort(function(a:String, b:String):Int {
        //     a = a.toUpperCase();
        //     b = b.toUpperCase();
            
        //     if (a < b) {
        //         return 1;
        //     }
        //     else if (a > b) {
        //         return -1;
        //     } else {
        //         return 0;
        //     }
        // });


        for (item in nonSongsNames) {
            if (item == "Ticket") {
                tickets++;
                archipelago.APItem.createItemByName(item);
            }
        }

        if (info().casualSync)
        if (APInfo.ticketCount != tickets) {
            APInfo.ticketCount = tickets;
        }

        for (items in nonSongsNames)
        {
            if (items == 'Ticket') continue;
            
            if (nonSongs.get(items) <= ItemIndex)
            {
                continue;
            }
            else
            {
                trace('triggering $items');
                ItemIndex = nonSongs.get(items);
                archipelago.APItem.createItemByName(items);
            }
            archipelago.APItem.doCheck();

            trace("AP State Saving...");
            updateSaveData();
        }
        isSync = false;
        info().casualSync = false;
        try {
            if (states.FreeplayState.instance != null) states.FreeplayState.instance.reloadSongs(true);
        } catch (e:Dynamic) {
            archipelago.APItem.popup("Error", "You need to wait for all of the data to load, silly!", true);
        }


        // if (AprilFools.allowAF && FlxG.random.bool(50))
            // new APItem.APrilFools(); // Not working as intended, for some reason. 


    }

    // A bandage fix till we have enough brainpower to fix this properly
    var trapList:Array<String> = [
        "Blue Balls Curse",
        "Fake Transition",
        "SvC Effect",
        "Ghost Chat",
        "Tutorial Trap"
    ];

    public function isLocationMissing(location:String):Bool
    {
        for (missing in info().missingLocations)
        {
            if (info().get_location_name(missing) == location)
            {
                return true;
            }
        }
        return false; 
    }

    public function areLocationsMissing(locations:Array<Int>):Bool
    {
        for (location in locations)
        {
            if (isLocationMissing(info().get_location_name(location)))
            {
                return true;
            }
        }
        return false; 
    }

    function isModName(name:String):Bool {
        var mods = Mods.parseList().enabled;
        // trace("Checking: " + mod);

        if (mods != null && mods.length > 0) {
            for (mod in mods) {
                // trace("Looking for: " + name);
                if (mod == name) {
                    // trace("Found: " + mod);
                    return true;
                }
            }
        }
        // trace("Not Found: " + name);
        return false;
    }

    function validateModSong(song:String, mod:String):Bool {
        // Iterate through the weeks in WeekData
        for (i in 0...WeekData.weeksList.length) {
            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            
            // Check if the week folder matches the specified mod
            if (leWeek.folder == mod) {
                // Iterate through the songs in the week
                for (songData in leWeek.songs) {
                    var songName = (cast songData[0] : String).toLowerCase().replace(" ", "-");
                    // Check if the song name matches the specified song
                    if (songName == song.toLowerCase().replace(" ", "-")) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function checkIfLocked(song:String, mod:String):Bool {
        return !(states.FreeplayState.curUnlocked.exists(song) && states.FreeplayState.curUnlocked.get(song) == mod);
    }

    function validateMods()
    {
        var mods = Mods.parseList().enabled;
        var APItems = [];
        var validatedMods = [];
        for (item in currentPackages["Friday Night Funkin"].item_name_to_id.keys())
        {
            if (item.indexOf("(") != -1)
            {
                var modName = item.substring(item.indexOf("((") + 1, item.indexOf("))"));
                if (mods.contains(modName))
                {
                    APItems.push(item);
                    validatedMods.push(modName);
                }
            }
        }
        if (mods != validatedMods)
        {
            throw "There seems to be missing mods. You can't access an APWorld without the mods that were used to generate it.";
        }
    }

    // public function onRoomInfo(roomInfo:RoomInfoPacket)
    // {
    //     _ap.clientStatus = ClientStatus.CONNECTED;
    // }

    // public function onSlotConnected(connectedPacket:ConnectedPacket)
    // {
    //     _ap.clientStatus = ClientStatus.PLAYING;
    // }

    // public function onSlotRefused(refusedPacket:ConnectionRefusedPacket)
    // {
    //     _ap.clientStatus = ClientStatus.UNKNOWN;
    // }

    private function onSocketDisconnected():Void {
        FlxG.switchState(_disconnectSubstate);
    }

    private function onCancel():Void {
        _ap.clientStatus = ClientStatus.UNKNOWN;
        _ap.onSocketDisconnected.remove(onSocketDisconnected);
        _ap = null;
        APEntryState.ap = null;
        APEntryState.apGame = null;
        APEntryState.inArchipelagoMode = false;
        MusicBeatState.switchState(new APEntryState());
    }


    private function onReconnect():Void {
        MusicBeatState.switchState(new archipelago.APCategoryState(this, APEntryState.ap));
    }

    // public function onRoomUpdate(roomUpdatePacket:RoomUpdatePacket)
    // {
    //     _ap.clientStatus = ClientStatus.PLAYING;
    // }
}
