package archipelago;

import haxe.DynamicAccess;
import states.FreeplayState;
import yutautil.MemoryHelper;
import flixel.FlxState;
import archipelago.Client;
import archipelago.PacketTypes;
import archipelago.APDisconnectSubstate;
import archipelago.APCategoryState;

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
    None; LogicalAdvancement; Important; Trap;
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

    private var _ap:Client;
    private var _seed:String;
    private var _disconnectSubstate:APDisconnectSubstate;
    private var _saveData:yutautil.save.MixSaveWrapper;
    public var connected(get, never):Bool;

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

        // var dataPackageHash = haxe.crypto.Sha1.make(_ap._dataPackage);
        _saveData = new yutautil.save.MixSaveWrapper(new yutautil.save.MixSave(), "save/"+ "ap_" + _ap.seed + ".json", true);

        _saveData.addItem("slotData", slotData);
        _saveData.addItem("seed", _seed);


        _disconnectSubstate = new APDisconnectSubstate(_ap);
        _disconnectSubstate.setSeed(_seed);
        _disconnectSubstate.onCancel.add(onCancel);
        _disconnectSubstate.onReconnect.add(onReconnect);

        _ap.onSocketDisconnected.add(onSocketDisconnected);
        _ap.onPrintJSON.add(sendMessage);
		_ap.onPrint.add(sendMessageSimple);
		_ap.onItemsReceived.add(addSongs);
        _ap.onBounced.add(bouncy);
        // _ap.onConnect.add(function() {
        //     _ap.clientStatus = ClientStatus.CONNECTED;
        // });

		// _ap.onRoomInfo.add(onRoomInfo);
		// _ap.onSlotRefused.add(onSlotRefused);
		_ap.onSlotConnected.add(onSlotConnected);
        APPlayState.deathByLink = false;


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
            APPlayState.deathByLink = true;}
        } }
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

    public static var isSync:Bool = false;
    function addSongs(song:Array<NetworkItem>)
    {
        for (songName in song)
        {
            var itemName = info().get_item_name(songName.item);

                        // Convert special keywords back to actual brackets
                        itemName = itemName.replace("<cOpen>", "{")
                        .replace("<cClose>", "}")
                        .replace("<sOpen>", "[")
                        .replace("<sClose>", "]");

                        
            // trace("Item Name: " + itemName);
            var modName = "";
            var firstParenIndex = itemName.indexOf("(");
            var endParenIndex = itemName.lastIndexOf(")");
            while (firstParenIndex != -1) {
                // endParenIndex = itemName.lastIndexOf(")", firstParenIndex);
                if (endParenIndex != -1) {
                    modName = itemName.substring(firstParenIndex + 1, endParenIndex);
                    // trace("Mod Name: " + modName);
                    if (isModName(modName)) {
                        itemName = itemName.substring(0, firstParenIndex).trim();
                        break;
                    } else {
                        firstParenIndex = itemName.indexOf("(", firstParenIndex + 1);
                    }
                } else {
                    break;
                }
            }
            if (firstParenIndex == -1 || !isModName(modName)) {
                modName = "";
                itemName = info().get_item_name(songName.item);
            }
            if (!states.FreeplayState.curUnlocked.exists(itemName))
            {
                // trace('Item Recieved: '+itemName);
                if (itemName != "Unknown")
                {
                    if (!isSync) ArchPopup.startPopupSong(itemName, 'archColor');
                    states.FreeplayState.curUnlocked.set(itemName, modName);
                    if (states.FreeplayState.instance != null) states.FreeplayState.instance.reloadSongs(true);
                    // trace("Unlocked: " + itemName);
                    // trace(states.FreeplayState.curUnlocked);
                    // trace(song);
                    for (song in states.FreeplayState.curUnlocked.keys())
                    {
                        var parts = song.split("||");
                        var key = parts[0];
                        var value = parts.length > 1 ? parts[1] : states.FreeplayState.curUnlocked.get(song);
                        states.FreeplayState.curUnlocked.set(key, value);
                        // trace("Unlocked: " + key);
                        // trace("Mod: " + value);
                        // trace("curUnlocked: " + states.FreeplayState.curUnlocked);
                    }
                }
            }
        }
        isSync = false;
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
        _ap.disconnect_socket(); 
        _ap.clientStatus = ClientStatus.UNKNOWN;
        // _ap.onRoomInfo.remove(onRoomInfo);
        // _ap.onSlotRefused.remove(onSlotRefused);
        _ap.onSocketDisconnected.remove(onSocketDisconnected);
        // _ap.onSlotConnected.remove(onSlotConnected);
        _ap = null;
        // MemoryHelper.clearClassObject(this);
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
