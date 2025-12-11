package archipelago;

/*
 * TEMPORARY CUSTOM WEEK SYSTEM FOR ARCHIPELAGO
 * ============================================
 *
 * This APGameState includes a system that creates temporary, in-memory week data
 * for mods that receive new songs through Archipelago's custom song management.
 *
 * KEY FEATURES:
 * - No permanent file creation - weeks exist only in memory during AP session
 * - Automatic cleanup on disconnect, exit, or manual disconnect
 * - Supports both explicit custom weeks and dynamically generated weeks from song additions
 * - Integrates seamlessly with existing WeekData system
 *
 * CLEANUP TRIGGERS:
 * - onSocketDisconnected(): Network disconnection
 * - onCancel(): User exits AP mode
 * - disconnectAP(): Manual disconnect
 * - APGameState.forceCleanupTemporaryWeeks(): Emergency cleanup
 */

import archipelago.APCategoryState;
import archipelago.APDisconnectSubstate;
import archipelago.APInfo;
import archipelago.Client;
import archipelago.PacketTypes;
import archipelago.substates.ConnectionSubstate;
import backend.Paths;
import backend.WeekData.WeekFile;
import backend.WeekData;
import flixel.FlxState;
import flixel.util.FlxSave;
import haxe.DynamicAccess;
import haxe.ds.Option;
import lime.app.Future;
import lime.app.Promise;
import openfl.text.TextFormat;
import yutautil.AprilFools;
import yutautil.GenericProgressSubstate;
import yutautil.MemoryHelper;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

// Enums
enum PrintJsonType
{
	ItemSend;
	ItemCheat;
	Hint;
	Join;
	Part;
	Chat;
	ServerChat;
	Tutorial;
	TagsChanged;
	CommandResult;
	AdminCommandResult;
	Goal;
	Release;
	Collect;
	Countdown;
}

// enum ClientStatus {
//     CLIENT_UNKNOWN; CLIENT_CONNECTED; CLIENT_READY; CLIENT_PLAYING; CLIENT_GOAL;
// }

enum PacketProblemType
{
	cmd;
	arguments;
}

enum SetReplyPacketType
{
	key;
	value;
	original_value;
}

enum ItemFlag
{
	None; // Nothing special about this item
	LogicalAdvancement; // Indicates the item can unlock logical advancement
	Important; // Indicates the item is especially useful
	Trap; // Indicates the item is a trap
}

enum DataStorageOperationType
{
	replace;
	_default;
	add;
	mul;
	pow;
	mod;
	floor;
	ceil;
	max;
	min;
	and;
	or;
	xor;
	left_shift;
	right_shift;
	remove;
	pop;
	update;
}

enum ClientState
{
	spectator;
	player;
	group;
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
typedef RoomInfoPacket =
{
	version:NetworkVersion,
	generator_version:NetworkVersion,
	tags:Array<String>,
	password:Bool,
	permissions:Map<String, Permission>,
	hint_cost:Int,
	location_check_points:Int,
	games:Array<String>,
	datapackage_versions:Map<String, Int>,
	datapackage_checksums:Map<String, String>,
	seed_name:String,
	time:Float
};

typedef ConnectionRefusedPacket =
{
	errors:Option<Array<String>>
};

typedef ConnectedPacket =
{
	team:Int,
	slot:Int,
	players:Array<NetworkPlayer>,
	missing_locations:Array<Int>,
	checked_locations:Array<Int>,
	slot_data:Map<String, Dynamic>,
	slot_info:Map<Int, NetworkSlot>,
	hint_points:Int
};

typedef ReceivedItemsPacket =
{
	index:Int,
	items:Array<NetworkItem>
};

typedef LocationInfoPacket =
{
	locations:Array<NetworkItem>
};

typedef RoomUpdatePacket =
{
	players:Array<NetworkPlayer>,
	checked_locations:Array<Int>,
	missing_locations:Array<Int>
};

typedef PrintJSONPacket =
{
	data:Array<JSONMessagePart>,
	type:Option<PrintJsonType>,
	receiving:Option<Int>,
	item:Option<NetworkItem>,
	found:Option<Bool>,
	team:Option<Int>,
	slot:Option<Int>,
	message:Option<String>,
	tags:Option<Array<String>>,
	countdown:Option<Int>
};

typedef DataPackagePacket =
{
	data:Dynamic
};

typedef BouncedPacket =
{
	games:Option<Array<String>>,
	slots:Option<Array<Int>>,
	tags:Option<Array<String>>,
	data:Option<Dynamic>
};

typedef RetrievedPacket =
{
	keys:Map<String, Dynamic>
};

typedef SetReplyPacket =
{
	key:String,
	value:Dynamic,
	original_value:Option<Dynamic>
};

typedef ConnectPacket =
{
	password:String,
	game:String,
	name:String,
	uuid:String,
	version:NetworkVersion,
	items_handling:Int,
	tags:Array<String>,
	slot_data:Option<Bool>
};

typedef ConnectUpdatePacket =
{
	items_handling:Int,
	tags:Array<String>
};

typedef SyncPacket =
{
};

typedef LocationChecksPacket =
{
	locations:Array<Int>
};

typedef LocationScoutsPacket =
{
	locations:Array<Int>,
	create_as_hint:Int
};

typedef StatusUpdatePacket =
{
	status:ClientStatus
};

typedef SayPacket =
{
	text:String
};

typedef GetDataPackagePacket =
{
	games:Option<Array<String>>
};

typedef BouncePacket =
{
	games:Option<Array<String>>,
	slots:Option<Array<Int>>,
	tags:Option<Array<String>>,
	data:Option<Dynamic>
};

typedef GetPacket =
{
	keys:Array<String>
};

typedef SetPacket =
{
	key:String,
	_default:Dynamic,
	want_reply:Bool,
	operations:Array<DataStorageOperation>
};

typedef SetNotifyPacket =
{
	keys:Array<String>
};

typedef ProcessedItemsResult =
{
	tickets:Int,
	nonSongs:haxe.DynamicAccess<Int>,
	nonSongsNames:Array<String>,
	unlockedSongs:Array<{song:String, mod:String}>,
	itemsToTrigger:Array<String>,
	sanityItems:Array<String>
};

class APGameState
{
	public static var instance:APGameState;

	private var _ap:Client;
	private var _seed:String;
	// APDisconnectSubstate removed - now using ConnectionSubstate for reconnection
	private var _saveData:yutautil.save.MixSaveWrapper;

	// Temporary weeks created for AP session - automatically cleaned up on disconnect/exit
	public static var temporaryWeeks:Array<WeekData> = [];
	public static var temporaryWeekNames:Array<String> = [];

	public var connected(get, never):Bool;

	public var APLocations:Array<Int> = [];
	public var APItems:Map<String, Int> = new Map<String, Int>();
	public var ItemIndex:Int = -1;

	// Sanity-related variables
	public var unlockedSanityItems:Map<String, SanityItemData> = new Map<String, SanityItemData>();
	public var sanitySettings:SanitySettings = {enable_sanity_locations: false, sanity_completion_type: "on_getting", sanity_types: []};
	public var sanityLocationIds:haxe.DynamicAccess<Int> = new haxe.DynamicAccess<Int>();

	public function locationData(songName:String, modName:String):Array<Int>
	{
		try
		{
			if (!APInfo.hasSongChecks)
			{
				return [];
			}

			if (modName != null && (modName != ""))
			{
				modName = modName.trim();
			}
			else
			{
				modName = "";
			}
			// trace("Starting locationData function with songName: " + songName + " and modName: " + modName);
			var matchingLocations:Array<Int> = [];
			var exactMatch:Int = -1;
			var hasDashNumber:Bool = false;
			var reg = new EReg("^" + EReg.escape(songName + (modName != "" ? " (" + modName + ")" : "")) + "(?:-\\d+)?$", "");
			var apInfo = info();

			for (location in APLocations)
			{
				var locationName = apInfo.get_location_name(location);

				if (locationName == songName + (modName != "" ? " (" + modName + ")" : ""))
				{
					exactMatch = location;
					break;
				}
				else if (reg.match(locationName))
				{
					matchingLocations.push(location);
					hasDashNumber = true;
				}
			}

			if (!hasDashNumber && exactMatch != -1)
			{
				return [exactMatch];
			}

			if (matchingLocations.length == 0)
			{
				for (song in WeekData.getCurrentWeek().songs)
				{
					if ((cast song[0] : String).toLowerCase().trim() == songName.toLowerCase().trim() || (cast song[0] : String).toLowerCase()
						.trim()
						.replace(" ", "-") == songName.toLowerCase()
						.trim()
						.replace(" ", "-"))
					{
						var fallbackReg = new EReg("^" + EReg.escape(song[0] + (modName != "" ? " (" + modName + ")" : "")) + "(?:-\\d+)?$", "");
						for (location in APLocations)
						{
							var locationName = apInfo.get_location_name(location);
							if (fallbackReg.match(locationName))
							{
								trace("Fallback match found: " + locationName);
								matchingLocations.push(location);
							}
						}
						break;
					}
				}
			}

			return matchingLocations;
		}
		catch (e:Dynamic)
		{
			var errorMessage = "Error in locationData function for song: " + songName + " and mod: " + modName + ". Reason: " + Std.string(e);
			// trace(errorMessage);
			// archipelago.APItem.popup(errorMessage, "Error: Locations", true);
			return [];
		}
	}

	public function noteData(songName:String, modName:String, ?week:String):Array<Int>
	{
		try
		{
			if (!APInfo.hasNoteChecks)
			{
				return [];
			}

			if (modName != null && modName != "")
			{
				modName = modName.trim();
			}
			else
			{
				modName = "";
			}
			// trace("Starting noteData function with songName: " + songName + " and modName: " + modName);
			var matchingNotes:Array<Int> = [];
			var reg = new EReg("^Note \\d+: " + EReg.escape(songName + (modName != "" ? " (" + modName + ")" : "")) + "$", "");
			var apInfo = info();

			for (location in APLocations)
			{
				var locationName = apInfo.get_location_name(location);
				if (reg.match(locationName))
				{
					matchingNotes.push(location);
				}
			}

			if (matchingNotes.length == 0)
			{
				for (song in WeekData.getCurrentWeek().songs)
				{
					if ((cast song[0] : String).toLowerCase().trim() == songName.toLowerCase().trim() || (cast song[0] : String).toLowerCase()
						.trim()
						.replace(" ", "-") == songName.toLowerCase()
						.trim()
						.replace(" ", "-"))
					{
						var fallbackReg = new EReg("^Note \\d+: " + EReg.escape(song[0] + (modName != "" ? " (" + modName + ")" : "")) + "$", "");
						for (location in APLocations)
						{
							var locationName = apInfo.get_location_name(location);
							if (fallbackReg.match(locationName))
							{
								trace("Fallback match found: " + locationName);
								matchingNotes.push(location);
							}
						}
						break;
					}
				}
			}

			if (matchingNotes.length == 0)
			{
				for (song in WeekData.getCurrentWeek().songs)
				{
					var songPath = modName.trim() != "" ? "mods/" + modName + "/data/" + song[0] + "/" + song[0] + "-"
						+ Difficulty.getString(PlayState.storyDifficulty) + ".json" : "assets/shared/data/"
						+ (song[0] + Difficulty.getFilePath());

					var songJson:backend.Song.SwagSong = null;
					var jsonStuff:Array<String> = modName.trim() != "" ? Paths.crawlDirectory("mods/" + modName + "/data",
						".json") : Paths.crawlDirectory("assets/shared/data", ".json");

					for (json in jsonStuff)
					{
						if (json.trim()
							.toLowerCase()
							.replace(" ", "-") == songPath.trim()
							.toLowerCase()
							.replace(" ", "-"))
						{
							songJson = backend.Song.parseJSON(File.getContent(json));
							if (songJson != null)
							{
								if (songJson.song.trim()
									.toLowerCase()
									.replace(" ", "-") == songName.toLowerCase()
									.trim()
									.replace(" ", "-"))
								{
									var fallbackReg = new EReg("^Note \\d+: " + EReg.escape(song[0] + (modName != "" ? " (" + modName + ")" : "")) + "$", "");
									for (location in APLocations)
									{
										var locationName = apInfo.get_location_name(location);
										if (fallbackReg.match(locationName))
										{
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
		}
		catch (e:Dynamic)
		{
			// var errorMessage = "Error in noteData function for song: " + songName + " and mod: " + modName + ". Reason: " + Std.string(e);
			// trace(errorMessage);
			// archipelago.APItem.popup(errorMessage, "Error: Note Checks", true);
			return [];
		}
	}

	public function getSongLocations(songName:String, ?modName:String):Array<Int>
	{
		return locationData(songName, modName).concat(noteData(songName, modName));
	}

	public function getSanityLocationsForSong(songName:String, ?modName:String):Array<Int>
	{
		var locations:Array<Int> = [];

		if (!sanitySettings.enable_sanity_locations)
			return locations;

		// Check for stage sanity items that use this song
		for (itemName => itemData in unlockedSanityItems)
		{
			if (itemData.type == "stage" || itemData.type == "character")
			{
				// Check if this sanity item's songs include the current song
				var formattedSongName = songName;
				if (modName != null && modName != "")
					formattedSongName = songName + " (" + modName + ")";

				// Check if any song in the array matches our song name
				var songMatches = false;
				for (songObj in itemData.songs)
				{
					if (songObj.song == songName || songObj.song == formattedSongName)
					{
						songMatches = true;
						break;
					}
				}

				if (songMatches)
				{
					var locationName = "Use " + itemName;
					var locationId = sanityLocationIds.get(locationName);
					if (locationId != null)
					{
						locations.push(locationId);
					}
				}
			}
		}

		return locations;
	}

	public function getSanityLocationData(itemType:String, itemName:String):Array<Int>
	{
		try
		{
			if (!sanitySettings.enable_sanity_locations)
				return [];

			var matchingLocations:Array<Int> = [];
			var apInfo = info();

			// First try slot data lookup
			if (_slotData != null && Reflect.hasField(_slotData, "sanityLocationData"))
			{
				var sanityLocationData:haxe.DynamicAccess<SanityLocationData> = Reflect.field(_slotData, "sanityLocationData");
				if (sanityLocationData != null)
				{
					var locationName = "Use " + itemType + ": " + itemName;
					var sanityLocationInfo = sanityLocationData.get(locationName);
					if (sanityLocationInfo != null)
					{
						return [sanityLocationInfo.id];
					}
				}
			}

			// Fallback to regex matching
			var reg = new EReg("^Use " + EReg.escape(itemType + ": " + itemName) + "$", "");

			for (location in APLocations)
			{
				var locationName = apInfo.get_location_name(location);
				if (reg.match(locationName))
				{
					matchingLocations.push(location);
				}
			}

			return matchingLocations;
		}
		catch (e:Dynamic)
		{
			trace("Error in getSanityLocationData for " + itemType + ": " + itemName + ". Reason: " + Std.string(e));
			return [];
		}
	}

	public function checkGoal(songName:String, ?modName:String):Bool
	{
		modName = (modName != null && modName != "") ? modName.trim() : "";
		var info = info();
		var locations = locationData(songName, modName).concat(noteData(songName, modName));

		if (info.missingLocations.length == 0 && info.checkedLocations.length == 0)
			{
			trace("AP is not ready yet - no locations checked or missing.");
				archipelago.APItem.popup("AP ERROR: Location data doesn't exist for song: " + songName + " with mod: " + modName, "Archipelago", true);
				archipelago.substates.InfoPanelSubstate.show("AP ERROR", "Location data doesn't exist for song: " + songName + " with mod: " + modName
					+ ". This usually means the Archipelago server is not ready yet. Please wait a moment and try again.", 0xFF0000, null);
			return false;
			}

		if (locations == null || locations.length == 0)
		{
			trace("No locations found for song: " + songName + " with mod: " + modName);
			archipelago.APItem.popup("No locations found for song: " + songName + " with mod: " + modName, "Archipelago", true);
			archipelago.substates.InfoPanelSubstate.show("Victory Song Missing", "No locations found for song: " + songName + " with mod: " + modName
				+ ".\n\nMake sure that the song is added to your game, or the mod for this song is enabled.\n\nIf it is installed correctly, this may be a false error. This is here to prevent auto-goaling from ending your run early.", 0xFF0000, null);
			return false;
		}
		for (location in locations)
		{
			if (info.missingLocations.contains(location))
			{
				return false;
			}
		}
		if (APFreeplayManager.isVictorySong(songName, modName))
		{
			setGoal();
			return true;
		}
		return false;
	}

	public function songInMultiworld(songName:String, ?modName:String):Bool
	{
		modName = (modName != null && modName != "") ? modName.trim() : "";
		return locationData(songName, modName).length > 0 || noteData(songName, modName).length > 0;
	}

	public function setGoal():Void
	{
		info().set_goal();
	}

	public function checkProperTags():Bool
	{
		// Check and sync DeathLink tag
		if (ClientPrefs.data.deathlink && !_ap.tagsManager.hasDeathLink())
		{
			trace('DeathLink enabled in settings but missing from client tags - adding DeathLink');
			_ap.tagsManager.enableDeathLink();
		}
		else if (!ClientPrefs.data.deathlink && _ap.tagsManager.hasDeathLink())
		{
			trace('DeathLink disabled in settings but present in client tags - removing DeathLink');
			_ap.tagsManager.disableDeathLink();
		}

		// Check and sync TrapLink tag (assuming similar pattern to DeathLink)
		// Note: Adjust if TrapLink has a different setting location
		if (ClientPrefs.data.traplink && !_ap.tagsManager.hasTrapLink())
		{
			trace('TrapLink enabled in settings but missing from client tags - adding TrapLink');
			_ap.tagsManager.enableTrapLink();
		}
		else if (!ClientPrefs.data.traplink && _ap.tagsManager.hasTrapLink())
		{
			trace('TrapLink disabled in settings but present in client tags - removing TrapLink');
			_ap.tagsManager.disableTrapLink();
		}

		// // Check required tags from slot data
		// for (tag in requiredTags)
		// {
		// 	if (!_ap.hasTag(tag))
		// 	{
		// 		return false;
		// 	}
		// }
		return true;
	}

	public function excludeCheckedLocations(locations:Array<Int>):Array<Int>
	{
		var checkedLocations:Array<Int> = info().checkedLocations;
		var uncheckedLocations:Array<Int> = [];

		for (location in locations)
		{
			if (!checkedLocations.contains(location))
			{
				uncheckedLocations.push(location);
			}
		}

		return uncheckedLocations;
	}

	public static var currentPackages:DynamicAccess<GameData> = new DynamicAccess<GameData>();

	public var itemManager(get, set):Dynamic;

	function get_itemManager():Dynamic
	{
		return null;
	}

	function set_itemManager(itemManager:Dynamic):Dynamic
	{
		return null;
	}

	function get_connected():Bool
	{
		return _ap.clientStatus == ClientStatus.PLAYING
			|| _ap.clientStatus == ClientStatus.CONNECTED
			|| _ap.clientStatus == ClientStatus.GOAL
			|| _ap.clientStatus == ClientStatus.READY;
	}

	public var _slotData:APInfo.APSlotData;

	public function new(ap:Client, slotData:Dynamic)
	{
		_ap = ap;
		_slotData = slotData;
		_seed = _ap.seed;

		archipelago.APPlayState.apGame = this;
		archipelago.APInfo.apGame = this;
		archipelago.APInfo.ap = _ap;
		instance = this;

		trace("APGameState initialized with seed: " + _seed);
		// trace("APGameState slot data: \n" + Std.string(slotData));


		// APDisconnectSubstate removed - now using ConnectionSubstate for reconnection

		_ap.onSocketDisconnected.add(onSocketDisconnected);
		_ap.onPrintJSON.add(sendMessage);
		_ap.onPrint.add(sendMessageSimple);
		_ap.onItemsReceived.add(addSongs);
		_ap.onBounced.add(bouncy);
		_ap.onCountdown.add(function(countdown:Int)
		{
			if (CountdownPopup.instance == null)
			{
				var popup = new archipelago.CountdownPopup("AP Countdown", "The AP is about to begin!", countdown);
				popup.onFinish = function()
				{
					// Start the AP!
				};
			}
			else
			{
				CountdownPopup.instance.updateCountdown(countdown);
			}
		});

		// Set the ClientPrefs deathlink setting first based on slot data
		var slotDeathLink:Bool = false;
		if (slotData != null && Reflect.hasField(slotData, "deathLink"))
		{
			// Handle both boolean and integer representations (0/1)
			var deathLinkValue = Reflect.field(slotData, "deathLink");
			if (Std.isOfType(deathLinkValue, Bool)) {
				slotDeathLink = deathLinkValue;
			} else if (Std.isOfType(deathLinkValue, Bool)) {
				slotDeathLink = deathLinkValue;
			} else {
				// Fallback to string conversion
				slotDeathLink = Std.string(deathLinkValue).toLowerCase() == "true";
			}
			trace('Death Link setting from slot data: $slotDeathLink (original value: $deathLinkValue)');
		}
		else
		{
			slotDeathLink = ClientPrefs.data.deathlink;
			trace('Death Link setting from ClientPrefs: $slotDeathLink');
		}

		// Update ClientPrefs with the final death link setting
		ClientPrefs.data.deathlink = slotDeathLink;
		ClientPrefs.saveSettings();

		// Now toggle the death link on the client with the correct setting
		_ap.toggleDeathLink(slotDeathLink);

		trace('Final Death Link state - ClientPrefs: ${ClientPrefs.data.deathlink}, Client triggerable: ${slotDeathLink}');

		_ap.onRetrieved.add(handleRetrievedPacket);

		// _ap.onConnect.add(function() {
		//     _ap.clientStatus = ClientStatus.CONNECTED;
		// });

		// _ap.onRoomInfo.add(onRoomInfo);
		// _ap.onSlotRefused.add(onSlotRefused);
		// _ap.onSlotConnected.add(onSlotConnected);
		APPlayState.deathByLink = false;

		// Initialize sanity data from slot data
		initializeSanityData();

		// Generate custom week files if they don't exist
		// This processes slot data that contains information about:
		// - Custom weeks defined in HScript files
		// - Song modifications (additions/exclusions) from mod processing
		generateCustomWeeks();
	}

	function initializeSanityData():Void
	{
		// Initialize sanity settings from slot data
		if (_slotData != null && Reflect.hasField(_slotData, "sanitySettings"))
		{
			sanitySettings = Reflect.field(_slotData, "sanitySettings");

			// Ensure sanity_types is always an array (for backward compatibility)
			if (sanitySettings.sanity_types == null) {
				sanitySettings.sanity_types = [];
			}

			trace("Loaded sanity settings from slot data: " + Std.string(sanitySettings));
		}
		else
		{
			trace("No sanity settings found in slot data, using defaults");
		}

		// Initialize sanity location IDs from slot data
		if (_slotData != null && Reflect.hasField(_slotData, "sanityLocationData"))
		{
			var sanityLocationData:haxe.DynamicAccess<SanityLocationData> = Reflect.field(_slotData, "sanityLocationData");
			if (sanityLocationData != null)
			{
				for (locationName => locationData in sanityLocationData)
				{
					sanityLocationIds.set(locationName, locationData.id);
				}
				trace("Loaded " + [for (key in sanityLocationIds.keys()) key].length + " sanity location IDs");
			}
		}

		// Initialize unlocked sanity items (empty at start - will be populated as items are received)
		unlockedSanityItems = new Map<String, SanityItemData>();
		trace("Sanity system initialized");
	}

	function handleRetrievedPacket(retrievedPacket:haxe.DynamicAccess<Dynamic>):Void
	{
		// trace("Retrieved packet: " + retrievedPacket);
		for (key in retrievedPacket.keys())
		{
			var value = retrievedPacket.get(key);
			if (key.indexOf("_read_hints_") != -1)
			{
				// Initialize hint storage with better structure
				APFreeplayManager.hintTable = new Map<String, Array<String>>();
				APFreeplayManager.curHinted = [];

				// value.mapToObject() contains multiple hints indexed by keys
				var hintsObj:Dynamic = value.mapToObject();
				for (hintKey in Reflect.fields(hintsObj))
				{
					var hintObj:Dynamic = Reflect.field(hintsObj, hintKey);
					var hint:Hint = {
						receiving_player: hintObj.receiving_player,
						finding_player: hintObj.finding_player,
						location: hintObj.location,
						item: hintObj.item,
						found: hintObj.found,
						entrance: hintObj.entrance,
						item_flags: hintObj.item_flags
					};
					trace("Hint: " + hint);
					var FNFHint = true;
					if (APItems.exists(_ap.get_item_name(hint.item, _ap.get_player_game(hint.receiving_player))))
					{
						trace("Hint is for an Item, or a song you don't have. Skipping.");
						FNFHint = false;
						continue;
					}

					function playerItemName(player:Int, item:Int):String
					{
						var playerName = _ap.get_player_alias(player);
						var itemName = _ap.get_item_name(item, _ap.get_player_game(player));
						@:privateAccess
						if (itemName == "Unknown")
						{
							var playerObj = null;
							for (p in _ap._players)
							{
								if (p.slot == player)
								{
									playerObj = p;
									break;
								}
							}
							var gameName = _ap.get_player_game(player);
							for (items in currentPackages[gameName].item_name_to_id.keys())
							{
								if (currentPackages[gameName].item_name_to_id.get(items) == item)
								{
									return items;
								}
							}
							return itemName;
						}
						else
						{
							return itemName;
						}
					}

					if (!hint.found)
					{
						var locationName = _ap.get_location_name(hint.location, _ap.get_player_game(hint.finding_player));
						var findingPlayerName = _ap.get_player_alias(hint.finding_player);
						var receivingPlayerName = _ap.get_player_alias(hint.receiving_player);
						var itemName = playerItemName(hint.receiving_player, hint.item);
						var songName = getSongAndModFromLocation(hint.location);

						trace(itemName + " found in " + locationName + " by " + findingPlayerName + " for " + receivingPlayerName);

						var message:String;
						if (hint.receiving_player == _ap.slotnr)
						{
							message = "This song is found in " + findingPlayerName + "'s World at " + locationName;
						}
						else if (hint.finding_player == _ap.slotnr)
						{
							message = "This song has " + receivingPlayerName + "'s item: " + itemName;
						}
						else
						{
							message = "Hint: " + receivingPlayerName + " will find " + itemName + " in " + findingPlayerName + "'s World at " + locationName;
						}

						var fullSongName = getFullNameFromSongAndMod(songName);

						// Store hints in an array for better organization
						if (!APFreeplayManager.hintTable.exists(fullSongName))
						{
							APFreeplayManager.hintTable.set(fullSongName, []);
						}
						APFreeplayManager.hintTable.get(fullSongName).push(message);

						// Add to hinted songs list if not already there
						var hintSong = {song: songName.song, mod: songName.mod != null ? songName.mod : ""};
						var isAlreadyHinted = false;
						for (hinted in APFreeplayManager.curHinted)
						{
							if (hinted.song == hintSong.song && hinted.mod == hintSong.mod)
							{
								isAlreadyHinted = true;
								break;
							}
						}
						if (!isAlreadyHinted)
						{
							APFreeplayManager.curHinted.push(hintSong);
						}
					}
					else
						(trace("Hint already found: "
							+ playerItemName(hint.receiving_player, hint.item)
							+ " in "
							+ _ap.get_location_name(hint.location, _ap.get_player_game(hint.finding_player))
							+ " by "
							+ _ap.get_player_alias(hint.finding_player)
							+ " for "
							+ _ap.get_player_alias(hint.receiving_player)));
				}
			}
		}

		// Debug output for stored hints
		for (songName in APFreeplayManager.hintTable.keys())
		{
			var hints = APFreeplayManager.hintTable.get(songName);
			trace("Song: " + songName + " has " + hints.length + " hints:");
			for (hint in hints)
			{
				trace("  - " + hint);
			}
		}
	}

	public function initSaveData():Void
	{
		var combinedChecksum = haxe.crypto.Sha1.encode(haxe.Json.stringify(currentPackages));
		var saveFileName = "save/ap_" + _ap.slot + "_" + _ap.seed + "_" + combinedChecksum + ".json";
		_saveData = new yutautil.save.MixSaveWrapper(new yutautil.save.MixSave(), saveFileName, true);

		_saveData.addItem("slot", _ap.slot);
		_saveData.fancyFormat = true;
		_saveData.addItem("seed", _seed);
		if (_saveData.hasItem("checksum"))
		{
			var savedChecksum = _saveData.getItem("checksum");
			if (savedChecksum == combinedChecksum)
			{
				trace("Checksum matches the current combined checksum.");
			}
			else
			{
				trace("Checksum does not match the current combined checksum.");
			}
		}
		else
		{
			_saveData.addItem("checksum", combinedChecksum);
		}
		if (_saveData.hasItem("itemIndex"))
		{
			ItemIndex = _saveData.getItem("itemIndex");
		}
		if (_saveData.hasItem("activeItem"))
		{
			var activeItem = _saveData.getItem("activeItem");
			if (activeItem != null && activeItem != "null")
			{
				var reg = new EReg("^Chart Modifier Trap \\((.+)\\)$", "");
				if (reg.match(activeItem))
				{
					var modifier = reg.matched(1);
					archipelago.APItem.APChartModifier.restoreFromSave(modifier);
				}
				else
				{
					archipelago.APItem.createItemByName(activeItem);
				}
			}
		}
		if (_saveData.hasItem("waitingItems"))
		{
			var waitingItems:Array<String> = _saveData.getItem("waitingItems");
			var reg = new EReg("^Chart Modifier Trap \\((.+)\\)$", "");
			for (itemName in waitingItems)
			{
				if (reg.match(itemName))
				{
					var modifier = reg.matched(1);
					archipelago.APItem.APChartModifier.restoreFromSave(modifier);
				}
				else
				{
					archipelago.APItem.createItemByName(itemName);
				}
			}
		}
		if (_saveData.hasItem("tickets"))
		{
			APInfo.ticketCount = _saveData.getItem("tickets");
		}
		if (_saveData.hasItem("shields"))
		{
			APItem.shields = _saveData.getItem("shields");
		}
		if (_saveData.hasItem("MaxHP"))
		{
			APItem.maxHPUp = _saveData.getItem("MaxHP");
		}
		if (_saveData.hasItem("Lives"))
		{
			APPlayState.livecount = _saveData.getItem("Lives");
		}
		if (_saveData.hasItem("hasPocketLens"))
		{
			APItem.hasPocketLens = _saveData.getItem("hasPocketLens");
			if (APItem.hasPocketLens)
			{
				archipelago.APItem.createItemByName("Pocket Lens");
			}
		}
		if (_saveData.hasItem("hasDashMechanic"))
		{
			APItem.hasDashMechanic = _saveData.getItem("hasDashMechanic");
		}
		if (_saveData.hasItem("unlockedUnoColors"))
		{
			var colors:Array<{name:String, color_code:String}> = _saveData.getItem("unlockedUnoColors");
			archipelago.APItem.unoColorsUnlocked = colors;
		}
		@:privateAccess
		if (_saveData.hasItem("confusionStacks"))
		{
			APItem.confusionStack = _saveData.getItem("confusionStacks");
		}

		// Load active effects - these will be restored after all items are loaded
		var savedActiveEffects:Array<String> = [];
		var savedActiveSongEffects:Array<String> = [];
		if (_saveData.hasItem("activeEffects"))
		{
			savedActiveEffects = _saveData.getItem("activeEffects");
		}
		if (_saveData.hasItem("activeSongEffects"))
		{
			savedActiveSongEffects = _saveData.getItem("activeSongEffects");
		}
		if (_saveData.hasItem("currentMinigame"))
		{
			var minigameValue:Int = _saveData.getItem("currentMinigame");
			switch (minigameValue) {
				case 0: APInfo.inMinigame = None;
				case 1: APInfo.inMinigame = Uno;
				case 2: APInfo.inMinigame = Pong;
				default: APInfo.inMinigame = None;
			}
		}

		// Load sanity data
		if (_saveData.hasItem("unlockedSanityItems"))
		{
			var sanityItemsArray:Array<{name:String, data:SanityItemData}> = _saveData.getItem("unlockedSanityItems");
			for (item in sanityItemsArray)
			{
				unlockedSanityItems.set(item.name, item.data);
			}
			trace("Loaded " + [for (key in unlockedSanityItems.keys()) key].length + " unlocked sanity items from save");

			// Validate loaded sanity items against slot data
			if (_slotData != null && Reflect.hasField(_slotData, "sanityData"))
			{
				var slotSanityData:haxe.DynamicAccess<SanityItemData> = Reflect.field(_slotData, "sanityData");
				if (slotSanityData != null)
				{
					var validatedCount = 0;
					var removedCount = 0;
					var sanityItemsToRemove:Array<String> = [];

					// Check each loaded sanity item against slot data
					for (itemName in unlockedSanityItems.keys())
					{
						if (slotSanityData.exists(itemName))
						{
							validatedCount++;
						}
						else
						{
							trace("Warning: Saved sanity item '" + itemName + "' not found in slot data, removing");
							sanityItemsToRemove.push(itemName);
							removedCount++;
						}
					}

					// Remove invalid sanity items
					for (itemName in sanityItemsToRemove)
					{
						unlockedSanityItems.remove(itemName);
					}

					trace("Validated sanity items: " + validatedCount + " valid, " + removedCount + " removed");
				}
			}
		}
		else
		{
			// No saved sanity items found - they will be populated as items are received during gameplay
			trace("No saved sanity items found - starting with empty sanity collection");
		}

		// Load shop
		if (_saveData.hasItem("apShopItems"))
		{
			var apShopItems:Array<shop.Item.MiniItem> = _saveData.getItem("apShopItems");
			for (item in apShopItems)
				ShopData.items.set(item.name, shop.Item.makeItemFromMini(item));

			trace("Loaded " + [for (key in unlockedSanityItems.keys()) key].length + " unlocked sanity items from save");
		}

		var antiTrapList:Array<String> = [];
		// Load anti perma traps
		if (_saveData.hasItem("activeAntiPermaTraps"))
		{
			var activeAntiPermaTraps:Array<String> = _saveData.getItem("activeAntiPermaTraps");
			for (trapName in activeAntiPermaTraps)
			{
				activeAntiPermaTraps.push(trapName);
				APItem.triggeredAntiPermaTraps.push(trapName);
			}
			trace("Loaded " + activeAntiPermaTraps.length + " active perma traps from save");
		}

		// Load perma traps
		if (_saveData.hasItem("activePermaTraps"))
		{
			var activePermaTraps:Array<String> = _saveData.getItem("activePermaTraps");
			for (trapName in activePermaTraps)
			{
				if (trapName == "Sore Throat Trap" && !antiTrapList.contains("Throat Medicine")
					|| trapName == "Vocal Inverter Trap" && !antiTrapList.contains("Voice Inverter")
					|| trapName == "Blindness Trap" && !antiTrapList.contains("Contact Lenses")
					|| trapName == "Mechanical Hell Trap" && !antiTrapList.contains("The Simplifier 3000")
					|| trapName == "Metronome Madness Trap" && !antiTrapList.contains("Metronome Stabilizer")) {
					archipelago.APItem.createItemByName(trapName);
					APItem.triggeredPermaTraps.push(trapName);
				}

			}
			trace("Loaded " + activePermaTraps.length + " active perma traps from save");
		}

		// Restore active effects after all items are loaded
		restoreActiveEffects(savedActiveEffects, savedActiveSongEffects);

		_saveData.save();
	}

	/**
	 * Restore active effects from save data
	 * This method creates active effect items first, then recreates the tracking maps
	 */
	private function restoreActiveEffects(savedActiveEffects:Array<String>, savedActiveSongEffects:Array<String>):Void
	{
		if (savedActiveEffects.length == 0 && savedActiveSongEffects.length == 0)
		{
			trace("No active effects to restore");
			return;
		}

		trace("Restoring active effects: " + savedActiveEffects.length + " regular, " + savedActiveSongEffects.length + " song effects");

		// Create active effect items first (like other save data checks)
		var allActiveEffectNames = savedActiveEffects.concat(savedActiveSongEffects);
		for (itemName in allActiveEffectNames)
		{
			var item = APItem.createItemByName(itemName);

			// Recreate the active tracking
			if (savedActiveEffects.contains(itemName))
			{
				APItem.activeEffects.set(itemName, item);
			}
			if (savedActiveSongEffects.contains(itemName))
			{
				APItem.activeSongEffects.push(item);
			}
		}

		trace("Active effects restored successfully - " + allActiveEffectNames.length + " active items created");
	}

		public function updateSaveData():Void
		{
			if (_saveData == null)
			{
				trace("Save data is not ready yet...");
				return;
			}
			_saveData.addItem("itemIndex", ItemIndex);
			_saveData.addItem("activeItem", APItem.activeItem?.name);
			_saveData.addItem("waitingItems",
				APItem.getItems()
					.map(item -> item.name)
					.concat([if (APPlayState.ghostChat) "Ghost Chat" else null])
					.filter(item -> item != null));
			_saveData.addItem("tickets", APInfo.ticketCount);
			_saveData.addItem("shields", APItem.shields);
			_saveData.addItem("MaxHP", APItem.maxHPUp);
			_saveData.addItem("Lives", APPlayState.livecount);
			_saveData.addItem("hasPocketLens", APItem.hasPocketLens);
			_saveData.addItem("hasDashMechanic", APItem.hasDashMechanic);
		_saveData.addItem("unlockedUnoColors", archipelago.APItem.unoColorsUnlocked);
		@:privateAccess
		_saveData.addItem("confusionStack", APItem.confusionStack);

		// Save active effects tracking
		_saveData.addItem("activeEffects", [for (name in APItem.activeEffects.keys()) name]);
		_saveData.addItem("activeSongEffects", APItem.activeSongEffects.map(item -> item.name));

		// Save current minigame state
			var minigameValue:Int = switch (APInfo.inMinigame) {
				case None: 0;
				case Uno: 1;
				case Pong: 2;
			};
			_saveData.addItem("currentMinigame", minigameValue);

			// Save sanity data
			_saveData.addItem("unlockedSanityItems", [for (name => data in unlockedSanityItems) {name: name, data: data}]);

			// put everything in the array to grab later
			var shopItems:Array<shop.Item.MiniItem> = [];
			for (item in ShopData.items.keys())
				shopItems.push(shop.Item.makeMiniItemFromItem(ShopData.items.get(item)));

			_saveData.addItem("apShopItems", shopItems);

			_saveData.addItem("activePermaTraps", APItem.triggeredPermaTraps);

			_saveData.addItem("activeAntiPermaTraps", APItem.triggeredAntiPermaTraps);

			_saveData.save();
			trace("Save data updated!");
		}

		/**
		 * Public method to force save sanity items immediately
		 * Returns true if successful, false if failed
		 */
		public function forceSaveSanityItems():Bool
		{
			if (_saveData == null)
			{
				trace("Save data not available for sanity item sync");
				return false;
			}

			try
			{
				_saveData.addItem("unlockedSanityItems", [for (name => data in unlockedSanityItems) {name: name, data: data}]);
				_saveData.save();
				trace("Successfully synced sanity items to save data");
				return true;
			}
			catch (e:Dynamic)
			{
				trace("Error syncing sanity items to save data: " + e);
				return false;
			}
		}	public function info()
	{
		return _ap;
	}

	function bouncy(data:Dynamic)
	{
		trace("Bounce packet received: " + haxe.Json.stringify(data));

		// info()?.tagsManager?.syncToClient();

		// Check for TrapLink packet first
		if (Reflect.hasField(data, "trap_name"))
		{
			trace("TrapLink packet detected: " + haxe.Json.stringify(data));
			doTrapLink(data);
			return;
		}

		if ((Reflect.hasField(data, "source") && Reflect.hasField(data, "time")) && !APPlayState.deathByLink)
		{
			if (!Reflect.hasField(data, "cause") || data.cause == null)
			{
				data.cause = data.source + " died like an idiot in " + info().get_player_game(data.source) + ".";
			}

			if (info().slot != data.source)
			{
				var dl:Dynamic = data;
				if (!APPlayState.deathByLink)
				{
					APPlayState.deathLinkPacket = dl;
					APPlayState.deathByLink = true;
				}
			}
		}
	}

	function doTrapLink(trapLink:Dynamic)
	{
		if (trapLink == null)
		{
			trace("No trap link to process.");
			return;
		}

		if (info().slot == trapLink.source)
		{
			trace("Trap link received from self, ignoring.");
			return;
		}

		var trapName = trapLink.trap_name;
		try
		{
			var reg = new EReg("^Chart Modifier Trap \\((.+)\\)$", "");
			if (reg.match(trapName))
			{
				var modifier = reg.matched(1);
				archipelago.APItem.APChartModifier.restoreFromSave(modifier, true).fromTrapLink = true;
			}
			else
			{
				archipelago.APItem.createItemByName(trapName, true);
			}
			trace("TrapLink processed: " + trapName);
		}
		catch (e:Dynamic)
		{
			// Not an FNF Item, so we shall try by cases.
			switch (trapName)
			{
				case "Screen Flip Trap":
					// This is a special case, we need to flip the screen.
					backend.MusicBeatState.APFlip = true;
					trace("Screen flipped due to Screen Flip Trap.");

					// Set a timer to revert after 4 minutes (240,000 ms)
					haxe.Timer.delay(function()
					{
						backend.MusicBeatState.APFlip = false;
						trace("Screen flip reverted after 4 minutes.");
					}, 240000);
				case "Trivia Trap":
					// Wait until PlayState.instance is not null and startedCountdown is true
					var waitForPlayState:Void -> Void = null;
					waitForPlayState = function()
					{
						if (PlayState.instance?.startedCountdown)
						{
							new streamervschat.SpellPrompt();
							trace("Trivia Trap activated, showing spell prompt.");
						}
						else
						{
							haxe.Timer.delay(waitForPlayState, 50);
						}
					};
					waitForPlayState();
				case "Instant Death Trap":
					archipelago.APItem.createItemByName("Blue Balls Curse", true);
					backend.COD.COD.COD = "Killed by Blue Balls Curse.\n(Instant Death TrapLink)";
				case "Ghost":
					archipelago.APItem.createItemByName("Ghost", true);
				case "My Turn! Trap":
					archipelago.APItem.createItemByName("My Turn! Trap", true);
				case "Paralyze Trap":
					archipelago.APItem.createItemByName("Paralyze Trap", true);
				case "Phone Trap" | "Literature Trap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Home Trap":
					archipelago.APItem.createItemByName("Tutorial Trap", true);
				case "Ice Trap":
					archipelago.APItem.createItemByName("Ice Trap", true);
				case "Freeze Trap" | "Frozen Trap" | "Bubble Trap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Army Trap" | "Police Trap" | "Buyon Trap" | "OmoTrap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Damage Trap":
					archipelago.APItem.createItemByName('Damage Trap', true);
				case "Chaos Control Trap":
					archipelago.APItem.createItemByName("Chaos Control Trap", true);
				case "Confuse Trap":
					archipelago.APItem.createItemByName("Confuse Trap", true);
				case "Eject Ability":
					archipelago.APItem.createItemByName("Eject Ability", true);
				case "Whoops! Trap":
					archipelago.APItem.createItemByName("Whoops! Trap", true);
				case "Zoom Trap":
					archipelago.APItem.createItemByName("Zoom Trap", true);
				case "Posession Trap":
					archipelago.APItem.createItemByName("Posession Trap", true);
				case "Poison Trap" | "Poison Mushroom":
					archipelago.APItem.createItemByName(trapName, true);
				case "Confound Trap":
					archipelago.APItem.createItemByName("Confound Trap", true);
				case "Fast Trap":
					archipelago.APItem.createItemByName("Fast Trap", true);
				case "Slow Trap" | "Slowness Trap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Deisometric Trap" | "Camera Rotate Trap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Push Trap":
					archipelago.APItem.createItemByName('Push Trap', true);
				case "Input Sequence Trap":
					archipelago.APItem.createItemByName('Input Sequence Trap', true);
				case "Pokemon Trivia Trap":
					archipelago.APItem.createItemByName('Pokemon Trivia Trap', true);
				case "Thwimp Trap":
					archipelago.APItem.createItemByName('Thwimp Trap', true);
				case "Tiny Trap":
					archipelago.APItem.createItemByName('Tiny Trap', true);
				case "Bonk Trap":
					archipelago.APItem.createItemByName('Bonk Trap', true);
				case "Bald Trap":
					archipelago.APItem.createItemByName('Bald Trap', true);
				case "Bomb" | "TNT Barrel Trap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Controller Drift Trap":
					archipelago.APItem.createItemByName("Controller Drift Trap", true);
				case "Timer Trap":
					archipelago.APItem.createItemByName("Timer Trap", true);
				case "Jump Trap" | "Spring Trap":
					archipelago.APItem.createItemByName(trapName, true);
				case "Animal Bonus Trap":
					archipelago.APItem.createItemByName("Animal Bonus Trap", true);
				case "Hiccup Trap":
					archipelago.APItem.createItemByName("Hiccup Trap", true);
				case "Gooey Bag":
					archipelago.APItem.createItemByName("Gooey Bag", true);
				case "Nut Trap":
					archipelago.APItem.createItemByName("Nut Trap", true);
				case "Pokemon Count Trap":
					archipelago.APItem.createItemByName("Pokemon Count Trap", true);
				case "Exposition Trap":
					archipelago.APItem.createItemByName("Exposition Trap", true);
				case "Double Damage":
					archipelago.APItem.createItemByName("Double Damage", true);
				case "Instant Crystal Trap" | "One Hit KO":
					archipelago.APItem.createItemByName(trapName, true);
				case "Mirror Trap":
					archipelago.APItem.createItemByName("Mirror Trap", true);
				case "Pixellation Trap":
					archipelago.APItem.createItemByName("Pixellation Trap", true);
				case "Swap Trap":
					archipelago.APItem.createItemByName("Swap Trap", true);
				case "Cutscene Trap":
					archipelago.APItem.createItemByName("Cutscene Trap", true);
				default:
					try {
						archipelago.APItem.createItemByName(trapName, true);
						trace("TrapLink processed by fallback: " + trapName);
					} catch (e:Dynamic) {
						// If it's not a known trap, we can just log it.
						trace("Unknown trap link received: " + trapName + ".");
					}
			}
		}
	}

	function onSlotConnected(slotData:Dynamic)
	{
		if (backend.ClientPrefs.data.deathlink)
			_ap.tags.push("DeathLink");

		trace("Slot Data Connected and Custom Songs Grabbed!");
	}

	function sendMessage(data:Array<JSONMessagePart>, item:Dynamic, receiving:Dynamic, ?type:String)
	{
		// if (type == "ItemSend")
		// {
		// 	trace("ItemSend message detected");
		// }
		// Check if this is an ItemSend message where this player is sending an item to someone else
		if (item != null && receiving != null)
		{
			var networkItem:NetworkItem = item;
			var receivingPlayer:Int = receiving;

			// If the item's player (sender) matches our slot, we are sending the item
			if (networkItem.player == _ap.slotnr)
			{
				var itemName = _ap.get_item_name(networkItem.item, _ap.get_player_game(receivingPlayer));
				var receivingPlayerName = _ap.get_player_alias(receivingPlayer);

				// If sending to self, show special message
				if (type == "ItemSend")
				{
					if (receivingPlayer == _ap.slotnr && (archipelago.APItem.hasPocketLens && !archipelago.APItem.unknownSongs))
					{
						archipelago.APItem.popup('Got yourself "$itemName"!', "Item Got!", false);
					}
					else
					{
						// Show popup notification that we sent an item
						archipelago.APItem.popup('Sent "$itemName" to $receivingPlayerName!', "Item Sent!", false);
					}
				}
				else if (type == "ItemCheat")
				{
					archipelago.APItem.popup('Cheated in "$itemName" for $receivingPlayerName!', "Item Cheated!", false);
				}
			}
		}

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
	{
		archipelago.console.MainTab.addMessage(text);
	}

	public function disconnectAP()
	{
		// Set flag to prevent automatic reconnection
		isPurposefullyDisconnected = true;

		// Clear any pending reconnection state
		pendingReconnection = false;
		reconnectionCallback = null;
		reconnectionTargetState = null;
		_tempOfflineQueue = null;

		// Clean up temporary weeks when manually disconnecting
		cleanupTemporaryWeeks();

		// Clean up High Quality Trap temporary files
		#if ARCHIPELAGO_ALLOWED
		archipelago.HighQualityTrapManager.onAPSessionEnd();
		#end

		// Clean up AP Items and related data
		archipelago.APItem.cleanupAllAPData();

		_ap.disconnect_socket();
		_ap = null;
		if (APEntryState.ap != null)
		{
			APEntryState.ap = null;
		}
	}
	public function getSongAndMod(songName:String):{song:String, ?mod:String}
		{
			var input = songName;
			var modName = "";
			var firstParenIndex = songName.indexOf("(");
			var endParenIndex = songName.lastIndexOf(")");
			while (firstParenIndex != -1)
			{
				if (endParenIndex != -1)
				{
					modName = songName.substring(firstParenIndex + 1, endParenIndex);
					if (isModName(modName))
					{
						songName = songName.substring(0, firstParenIndex).trim();
						break;
					}
					else
					{
						firstParenIndex = songName.indexOf("(", firstParenIndex + 1);
					}
				}
				else
				{
					break;
				}
			}
			if (firstParenIndex == -1 || !isModName(modName))
			{
				modName = "";
				songName = input;
			}
			return modName != null && modName != "" ? {song: songName, mod: modName} : {song: songName};
		}

		public function getSongAndModFromLocation(locationID:Int):{song:String, ?mod:String}
		{
			var locationName = info().get_location_name(locationID);
			var songAndMod:{song:String, ?mod:String};

			// Check if it's a note location
			var noteReg = new EReg("^Note \\d+: (.+)$", "");
			if (noteReg.match(locationName))
			{
				var noteName = noteReg.matched(1);
				songAndMod = getSongAndMod(noteName);
			}
			else
			{
				// Check if it's a song location with a dash number
				var songReg = new EReg("^(.+?)(?:-\\d+)?$", "");
				if (songReg.match(locationName))
				{
					var songName = songReg.matched(1);
					songAndMod = getSongAndMod(songName);
				}
				else
				{
					// Default fallback
					songAndMod = getSongAndMod(locationName);
				}
			}

			return songAndMod;
		}

		// Check for songs and mods from an array of song names
		public function getSongsAndModsFromArray(songNames:Array<String>):Array<{song:String, ?mod:String}>
		{
			var songsAndMods:Array<{song:String, ?mod:String}> = [];
			for (songName in songNames)
			{
				var songAndMod = getSongAndMod(songName);
				songsAndMods.push(songAndMod);
			}
			return songsAndMods;
		}

		public function getFullNameFromSongAndMod(snm:{song:String, ?mod:String}):String
		{
			if (snm.mod != null && snm.mod != "")
			{
				return snm.song + " (" + snm.mod + ")";
			}
			else
			{
				return snm.song;
			}
		}

		public function findSpecialItems():Map<String, Int>
		{
			var specialItems:Map<String, Int> = new Map<String, Int>();
			var apInfo = info();

			// Get selectedSongs from slotData
			var selectedSongs:Array<String> = [];
			if (_slotData != null && Reflect.hasField(_slotData, "selectedSongs"))
			{
				selectedSongs = Reflect.field(_slotData, "selectedSongs");
			}

			for (item in currentPackages["Friday Night Funkin"].item_name_to_id.keys())
			{
				var itemName = item.replace("<cOpen>", "{").replace("<cClose>", "}").replace("<sOpen>", "[").replace("<sClose>", "]");

				// Check if item is NOT in selectedSongs
				var isSpecialItem = !selectedSongs.contains(itemName);
				if (isSpecialItem)
				{
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
		{
			// Use Future system to process all items asynchronously
			var processingFuture = processItemsAsync(song);
			processingFuture.onComplete(function(result)
			{
				applyProcessedItems(result);
				if (haventranyet)
				haventranyet = false;
			});
			processingFuture.onError(function(error)
			{
				trace("Error processing items: " + error);
				archipelago.APItem.popup("Error", "Failed to process items: " + error, true);
			});
		}

		/**
		 * Alternative method with batch processing and progress feedback
		 * Usage example:
		 *
		 * addSongsWithBatching(songs, 5, function(processed, total) {
		 *     trace('Processing: ${processed}/${total}');
		 * }).onComplete(function(_) {
		 *     trace("All items processed successfully!");
		 * });
		 */
		// function addSongsAdvanced(songs:Array<NetworkItem>, ?batchSize:Int = 10, ?progressCallback:Int->Int->Void)
		// {
		// 	return addSongsWithBatching(songs, batchSize, progressCallback);
		// }

		function processItemsAsync(songs:Array<NetworkItem>):Future<ProcessedItemsResult>
		{
			var promise = new Promise<ProcessedItemsResult>();

			// Process items asynchronously
			haxe.Timer.delay(function()
			{
				try
				{
					var result = processItemsSync(songs);
					promise.complete(result);
				}
				catch (error:Dynamic)
				{
					promise.error(error);
				}
			}, 1);

			return promise.future;
		}

		function processItemsSync(songs:Array<NetworkItem>):ProcessedItemsResult
		{
			var tickets = 0;
			var nonSongs:haxe.DynamicAccess<Int> = new haxe.DynamicAccess<Int>();
			var nonSongsNames:Array<String> = [];
			var unlockedSongs:Array<{song:String, mod:String}> = [];
			var itemsToTrigger:Array<String> = [];
			var sanityItems:Array<String> = []; // Track sanity items received

			APFreeplayManager.curMissing = [];

			for (songName in songs)
			{
				var itemName = info().get_item_name(songName.item);

				// Use the realName function to convert special keywords back to actual brackets
				itemName = APInfo.realName(itemName);

				// Check if this is a sanity item FIRST before doing APItems check
				var isSanityItem = false;
				var sanityItemName = itemName; // Default to the original item name

				if (_slotData != null && Reflect.hasField(_slotData, "sanityData"))
				{
					var slotSanityData:haxe.DynamicAccess<SanityItemData> = Reflect.field(_slotData, "sanityData");
					if (slotSanityData != null)
					{
						// Check if the item ID exists in the sanity data
						for (slotSanityItemName in slotSanityData.keys())
						{
							var sanityItemData = slotSanityData.get(slotSanityItemName);
							if (sanityItemData != null && sanityItemData.id == songName.item)
							{
								isSanityItem = true;
								// Use the sanity item name from slot data for consistency
								sanityItemName = slotSanityItemName;
								trace("Found sanity item by ID match: " + songName.item + " -> " + slotSanityItemName);
								break;
							}
						}

						// Also check by name match as fallback
						if (!isSanityItem && slotSanityData.exists(itemName))
						{
							isSanityItem = true;
							sanityItemName = itemName;
							trace("Found sanity item by name match: " + itemName);
						}
					}
				}

				if (isSanityItem)
				{
					// This is a sanity item - add to sanity tracking
					sanityItems.push(sanityItemName);
					nonSongs.set(sanityItemName, songName.index);
					nonSongsNames.push(sanityItemName);
					// trace("Processing sanity item: " + sanityItemName + " (original: " + itemName + ")");
					continue;
				}

				// Check APItems for non-sanity items only (moved after sanity check)
				if (APItems.exists(itemName) && APItems.get(itemName) == songName.item)
				{
					// trace("Skipping non-sanity APItem: " + itemName);
					nonSongs.set(itemName, songName.index);
					nonSongsNames.push(itemName);
					continue;
				}

				var data = getSongAndMod(itemName);
				// trace("Data: " + data.song + " - " + data.mod);

				if (data.mod == null || data.mod == "")
				{
					data.mod = "";
				}

				var isUnlocked = false;
				for (unlocked in APFreeplayManager.curUnlocked)
				{
					if (unlocked.song == data.song && unlocked.mod == data.mod)
					{
						isUnlocked = true;
					}
				}

				if (!isUnlocked)
				{
					if (!(data.song == "Unknown" && data.mod == ""))
					{
						unlockedSongs.push({song: data.song, mod: data.mod});
					}
				}
			}

			// Process non-songs for items to trigger
			for (items in nonSongsNames)
			{
				if (items == 'Ticket')
				{
					tickets++;
					continue;
				}

				if (nonSongs.get(items) > ItemIndex)
				{
					itemsToTrigger.push(items);
					ItemIndex = nonSongs.get(items);
				}
			}

			return {
				tickets: tickets,
				nonSongs: nonSongs,
				nonSongsNames: nonSongsNames,
				unlockedSongs: unlockedSongs,
				itemsToTrigger: itemsToTrigger,
				sanityItems: sanityItems // Add sanity items to result
			};
		}

		function applyProcessedItems(result:ProcessedItemsResult)
		{
			var songCopy:Array<{song:String, mod:String}> = APFreeplayManager.curUnlocked.copy();

			// Handle sanity items FIRST to ensure they're available for other systems
			trace("Processing " + result.sanityItems.length + " sanity items first");
			for (sanityItemName in result.sanityItems)
			{
				handleSanityItemReceived(sanityItemName);
			}

			// Apply all unlocked songs
			for (song in result.unlockedSongs)
			{
				if (!isSync)
					ArchPopup.startPopupSong(song, 'archColor');
				APFreeplayManager.curUnlocked.push(song);
			}

			// Filter out special items
			APFreeplayManager.curUnlocked = APFreeplayManager.curUnlocked.filter(unlocked -> !(APItems.exists(unlocked.song) && unlocked.mod.trim() == ""));

			// Apply tickets
			for (i in 0...result.tickets)
			{
				archipelago.APItem.createItemByName("Ticket");
			}

			if (info().casualSync && APInfo.ticketCount != result.tickets)
			{
				APInfo.ticketCount = result.tickets;
			}

			// Apply items in order
			for (items in result.itemsToTrigger)
			{
				trace('triggering $items');
				archipelago.APItem.createItemByName(items);
			}

			// Do all checks at once
			archipelago.APItem.doCheck();

			isSync = false;
			info().casualSync = false;

			// Reload freeplay after all processing is complete
			try
			{
				if (APFreeplayManager.curUnlocked.length != songCopy.length)
					FreeplayManager.instance.reloadFreeplay(true);
			}
			catch (e:Dynamic)
			{
				archipelago.APItem.popup("Error", "You need to wait for all of the data to load, silly!", true);
			}

			// Save state after everything is applied
			trace("AP State Saving...");
			updateSaveData();
		}

		function handleSanityItemReceived(itemName:String):Void
		{
			trace("Received sanity item: " + itemName);

			// Get sanity item data from slot data
			if (_slotData != null && Reflect.hasField(_slotData, "sanityData"))
			{
				var sanityData:haxe.DynamicAccess<SanityItemData> = Reflect.field(_slotData, "sanityData");
				if (sanityData != null && sanityData.exists(itemName))
				{
					var sanityItemData = sanityData.get(itemName);

					// Check if we already have this sanity item to avoid duplicates
					if (unlockedSanityItems.exists(itemName))
					{
						trace("Sanity item '" + itemName + "' already exists in unlocked items, skipping");
					// If completion type is "on_getting", check if it has actually sent the check.
					if (sanitySettings.sanity_completion_type == "on_getting")
					{
						sendSanityLocationCheck(itemName);
					}
						return;
					}

					unlockedSanityItems.set(itemName, sanityItemData);

					trace("Added sanity item '" + itemName + "' to unlocked items");
					trace("Current unlocked sanity items count: " + [for (key in unlockedSanityItems.keys()) key].length);
					// Show if you got a sanity item
					archipelago.APItem.popup("You received an asset:\n" + itemName);

					// Immediately save the sanity item to prevent loss
					if (_saveData != null)
					{
						try
						{
							_saveData.addItem("unlockedSanityItems", [for (name => data in unlockedSanityItems) {name: name, data: data}]);
							_saveData.save();
							trace("Immediately saved sanity item '" + itemName + "' to save data");
						}
						catch (e:Dynamic)
						{
							trace("Error immediately saving sanity item to save data: " + e);
						}
					}

					// If completion type is "on_getting", immediately send the sanity location check
					if (sanitySettings.sanity_completion_type == "on_getting")
					{
						sendSanityLocationCheck(itemName);
					}

					// Show popup notification
					archipelago.APItem.popup("Sanity Item Unlocked", "Unlocked: " + itemName, false);
				}
				else
				{
					trace("Warning: Sanity item '" + itemName + "' not found in slot data");
					trace("Available sanity items in slot data: " + [for (key in sanityData.keys()) key]);
				}
			}
			else
			{
				trace("Warning: No sanity data found in slot data");
				if (_slotData != null)
				{
					trace("Available fields in slot data: " + [for (field in Reflect.fields(_slotData)) field]);
				}
			}
		}

		function sendSanityLocationCheck(itemName:String):Void
		{
			var locationName = "Use " + itemName;
			var locationId = sanityLocationIds.get(locationName);

			if (locationId != null)
			{
				trace("Sending sanity location check for: " + locationName + " (ID: " + locationId + ")");
				info().LocationChecks([locationId]);
			}
			else
			{
				trace("Warning: Could not find location ID for sanity location: " + locationName);
			}
		}

		/**
		 * Manual method to refresh sanity items from slot data
		 * Call this if you suspect sanity items aren't being properly loaded
		 */
		public function refreshSanityItems():Void
		{
			trace("Manually refreshing sanity items from slot data");

			if (_slotData == null || !Reflect.hasField(_slotData, "sanityData"))
			{
				trace("No slot data or sanity data available for refresh");
				return;
			}

			var sanityData:haxe.DynamicAccess<SanityItemData> = Reflect.field(_slotData, "sanityData");
			if (sanityData == null)
			{
				trace("Sanity data is null");
				return;
			}

			var refreshCount = 0;
			for (itemName in sanityData.keys())
			{
				var sanityItemData = sanityData.get(itemName);
				if (sanityItemData != null && !unlockedSanityItems.exists(itemName))
				{
					// Check if we received this item already by checking the AP items
					var itemReceived = false;
					if (APItems.exists(itemName))
					{
						itemReceived = true;
						unlockedSanityItems.set(itemName, sanityItemData);
						refreshCount++;
						trace("Refreshed missing sanity item: " + itemName);
					}
				}
			}

			if (refreshCount > 0)
			{
				trace("Refreshed " + refreshCount + " sanity items");
				// Save the refreshed data
				if (_saveData != null)
				{
					try
					{
						_saveData.addItem("unlockedSanityItems", [for (name => data in unlockedSanityItems) {name: name, data: data}]);
						_saveData.save();
						trace("Saved refreshed sanity items to save data");
					}
					catch (e:Dynamic)
					{
						trace("Error saving refreshed sanity items: " + e);
					}
				}
			}
			else
			{
				trace("No sanity items needed refreshing");
			}
		}

		/**
		 * Debug method to check current state of sanity items
		 */
		public function debugSanityItems():Void
		{
			trace("=== SANITY ITEM DEBUG INFO ===");
			trace("Sanity settings enabled: " + sanitySettings.enable_sanity_locations);
			trace("Sanity completion type: " + sanitySettings.sanity_completion_type);
			trace("Sanity types: " + sanitySettings.sanity_types);
			trace("Unlocked sanity items count: " + [for (key in unlockedSanityItems.keys()) key].length);

			if (unlockedSanityItems != null)
			{
				for (name => data in unlockedSanityItems)
				{
					trace("  - " + name + " (type: " + data.type + ", id: " + data.id + ")");
				}
			}

			trace("Sanity location IDs count: " + [for (key in sanityLocationIds.keys()) key].length);
			if (sanityLocationIds != null)
			{
				for (name => id in sanityLocationIds)
				{
					trace("  - " + name + " -> " + id);
				}
			}

			if (_slotData != null && Reflect.hasField(_slotData, "sanityData"))
			{
				var sanityData:haxe.DynamicAccess<SanityItemData> = Reflect.field(_slotData, "sanityData");
				if (sanityData != null)
				{
					trace("Available sanity items in slot data: " + [for (key in sanityData.keys()) key].length);
					for (name in sanityData.keys())
					{
						var data = sanityData.get(name);
						var isUnlocked = unlockedSanityItems.exists(name);
						trace("  - " + name + " (type: " + data.type + ", id: " + data.id + ") [" + (isUnlocked ? "UNLOCKED" : "LOCKED") + "]");
					}
				}
			}
			trace("==============================");
		}

		public function checkSanityLocationsOnPlaying(songName:String, ?modName:String):Void
		{
			if (!sanitySettings.enable_sanity_locations || sanitySettings.sanity_completion_type != "on_playing")
				return;

			trace("Checking sanity locations on playing: " + songName + (modName != null ? " (" + modName + ")" : ""));

			// Check all unlocked sanity items to see if any use this song
			for (itemName => itemData in unlockedSanityItems)
			{
				var formattedSongName = songName;
				if (modName != null && modName != "")
					formattedSongName = songName + " (" + modName + ")";

				// Check if any song in the array matches our song name
				var songMatches = false;
				for (songObj in itemData.songs)
				{
					if (songObj.song == songName || songObj.song == formattedSongName)
					{
						songMatches = true;
						break;
					}
				}

				if (songMatches)
				{
					sendSanityLocationCheck(itemName);
				}
			}
		}

		public function checkSanityLocationsOnBeating(songName:String, ?modName:String):Void
		{
			if (!sanitySettings.enable_sanity_locations || sanitySettings.sanity_completion_type != "on_beating")
				return;

			trace("Checking sanity locations on beating: " + songName + (modName != null ? " (" + modName + ")" : ""));

			// Check all unlocked sanity items to see if any use this song
			for (itemName => itemData in unlockedSanityItems)
			{
				var formattedSongName = songName;
				if (modName != null && modName != "")
					formattedSongName = songName + " (" + modName + ")";

				// Check if any song in the array matches our song name
				var songMatches = false;
				for (songObj in itemData.songs)
				{
					if (songObj.song == songName || songObj.song == formattedSongName)
					{
						songMatches = true;
						break;
					}
				}

				if (songMatches)
				{
					sendSanityLocationCheck(itemName);
				}
				{
					sendSanityLocationCheck(itemName);
				}
			}
		}

		public function isSanityItemUnlocked(itemType:String, itemName:String):Bool
		{
			// If no sanity system exists at all, everything is unlocked
			var unlockedSanityCount = [for (key in unlockedSanityItems.keys()) key].length;
			var sanityLocationCount = [for (key in sanityLocationIds.keys()) key].length;
			if (unlockedSanityCount == 0 && sanityLocationCount == 0) return true;



			var key = itemType + ": " + itemName;
			return unlockedSanityItems.exists(key);
		}

		public function checkSongCharactersAndStageUnlocked(song:backend.Song.SwagSong):Array<String>
		{
			// Check if sanity system exists at all (regardless of location settings)
			var unlockedSanityCount = [for (key in unlockedSanityItems.keys()) key].length;
			var sanityLocationCount = [for (key in sanityLocationIds.keys()) key].length;
			if (unlockedSanityCount == 0 && sanityLocationCount == 0) return [];

			var missingItems:Array<String> = [];

			// Check what types of sanity items we should look for
			var checkCharacters = sanitySettings.sanity_types.contains("characters");
			var checkStages = sanitySettings.sanity_types.contains("stages");

			// Check player1 character
			if (checkCharacters && song.player1 != null && !isSanityItemUnlocked("Character", song.player1)) {
				missingItems.push('Character: ${song.player1}');
			}

			// Check player2 character
			if (checkCharacters && song.player2 != null && !isSanityItemUnlocked("Character", song.player2)) {
				missingItems.push('Character: ${song.player2}');
			}

			// Check player4 character
			if (checkCharacters && song.player4 != null && !isSanityItemUnlocked("Character", song.player4)) {
				missingItems.push('Character: ${song.player4}');
			}

			// Check player5 character
			if (checkCharacters && song.player5 != null && !isSanityItemUnlocked("Character", song.player5)) {
				missingItems.push('Character: ${song.player5}');
			}

			// Check stage
			if (checkStages && song.stage != null && !isSanityItemUnlocked("Stage", song.stage)) {
				missingItems.push('Stage: ${song.stage}');
			}

			return missingItems;
		}

		// // Advanced processing with batch support and progress feedback
		// function addSongsWithBatching(songs:Array<NetworkItem>, ?batchSize:Int = 10, ?progressCallback:Int->Int->Void):Void
		// {
		// 	var promise = new Promise<() -> Void>();

		// 	if (progressCallback != null)
		// 		progressCallback(0, songs.length);

		// 	var batches = createBatches(songs, batchSize);
		// 	var processedResults:Array<ProcessedItemsResult> = [];

		// 	processBatchesRecursively(batches, 0, processedResults, progressCallback)
		// 		.onComplete(function(_) {
		// 			// Combine all results
		// 			var combinedResult = combineProcessedResults(processedResults);
		// 			applyProcessedItems(combinedResult);

		// 			if (progressCallback != null)
		// 				progressCallback(songs.length, songs.length);

		// 			promise.complete(() -> {
		// 				trace("All items processed successfully!");
		// 			});
		// 		})
		// 		.onError(function(error) {
		// 			promise.error(error);
		// 		});

		// 	return promise.future.result();
		// }

		// function createBatches<T>(items:Array<T>, batchSize:Int):Array<Array<T>>
		// {
		// 	var batches:Array<Array<T>> = [];
		// 	var currentBatch:Array<T> = [];

		// 	for (item in items)
		// 	{
		// 		currentBatch.push(item);
		// 		if (currentBatch.length >= batchSize)
		// 		{
		// 			batches.push(currentBatch);
		// 			currentBatch = [];
		// 		}
		// 	}

		// 	if (currentBatch.length > 0)
		// 		batches.push(currentBatch);

		// 	return batches;
		// }

		// function processBatchesRecursively(batches:Array<Array<NetworkItem>>, index:Int, results:Array<ProcessedItemsResult>, ?progressCallback:Int->Int->Void):Future<Void>
		// {
		// 	var promise = new Promise<Void>();

		// 	if (index >= batches.length)
		// 	{
		// 		promise.complete();
		// 		return promise.future;
		// 	}

		// 	// Process current batch
		// 	var batchFuture = processItemsAsync(batches[index]);
		// 	batchFuture.onComplete(function(result) {
		// 		results.push(result);

		// 		// Update progress
		// 		var totalProcessed = 0;
		// 		for (i in 0...index + 1)
		// 			totalProcessed += batches[i].length;

		// 		if (progressCallback != null)
		// 			progressCallback(totalProcessed, getTotalItemCount(batches));

		// 		// Process next batch
		// 		processBatchesRecursively(batches, index + 1, results, progressCallback)
		// 			.onComplete(function(_) promise.complete())
		// 			.onError(function(error) promise.error(error));
		// 	});
		// 	batchFuture.onError(function(error) {
		// 		promise.error(error);
		// 	});

		// 	return promise.future;
		// }

		// function getTotalItemCount(batches:Array<Array<NetworkItem>>):Int
		// {
		// 	var total = 0;
		// 	for (batch in batches)
		// 		total += batch.length;
		// 	return total;
		// }

		// function combineProcessedResults(results:Array<ProcessedItemsResult>):ProcessedItemsResult
		// {
		// 	var combined:ProcessedItemsResult = {
		// 		tickets: 0,
		// 		nonSongs: new Map<String, Int>(),
		// 		nonSongsNames: [],
		// 		unlockedSongs: [],
		// 		itemsToTrigger: []
		// 	};

		// 	for (result in results)
		// 	{
		// 		combined.tickets += result.tickets;

		// 		for (key in result.nonSongs.keys())
		// 		{
		// 			combined.nonSongs.set(key, result.nonSongs.get(key));
		// 		}

		// 		combined.nonSongsNames = combined.nonSongsNames.concat(result.nonSongsNames);
		// 		combined.unlockedSongs = combined.unlockedSongs.concat(result.unlockedSongs);
		// 		combined.itemsToTrigger = combined.itemsToTrigger.concat(result.itemsToTrigger);
		// 	}

		// 	return combined;
		// }

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

		function isModName(name:String):Bool
		{
			var mods = Mods.parseList().enabled;
			// trace("Checking: " + mod);

			if (mods != null && mods.length > 0)
			{
				for (mod in mods)
				{
					// trace("Looking for: " + name);
					if (mod == name)
					{
						// trace("Found: " + mod);
						return true;
					}
				}
			}
			// trace("Not Found: " + name);
			return false;
		}

		function validateModSong(song:String, mod:String):Bool
		{
			// Iterate through the weeks in WeekData
			for (i in 0...WeekData.weeksList.length)
			{
				var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

				// Check if the week folder matches the specified mod
				if (leWeek.folder == mod)
				{
					// Iterate through the songs in the week
					for (songData in leWeek.songs)
					{
						var songName = (cast songData[0] : String).toLowerCase().replace(" ", "-");
						// Check if the song name matches the specified song
						if (songName == song.toLowerCase().replace(" ", "-"))
						{
							return true;
						}
					}
				}
			}
			return false;
		}

		function checkIfLocked(song:String, mod:String):Bool
		{
			return !(APFreeplayManager.curUnlocked.contains(APEntryState.apGame.getSongAndMod(song + mod)));
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

	/*
 * TEMPORARY CUSTOM WEEK SYSTEM
 * ============================
 *
 * This system creates temporary, in-memory week data for mods that receive new songs
 * through Archipelago's custom song management system. It works as follows:
 *
 * 1. SLOT DATA PROCESSING:
 *    - Reads 'customWeeks' data from slot data (explicit week definitions)
 *    - Reads 'song_modifications' data (song additions/exclusions)
 *
 * 2. TEMPORARY WEEK CREATION:
 *    - Creates WeekData objects in memory (no file I/O)
 *    - Adds them directly to WeekData.weeksLoaded and WeekData.weeksList
 *    - Uses naming pattern: ap_custom_{modname} or ap_custom_base
 *
 * 3. AUTOMATIC CLEANUP:
 *    - Temporary weeks are stored in APGameState.temporaryWeeks
 *    - Automatically removed on disconnect or AP exit
 *    - No permanent files are created or modified
 *
 * EXAMPLE SLOT DATA STRUCTURE:
 * {
 *   "customWeeks": {
 *     "ap_custom_mymod": {
 *       "target_mod": "MyMod",
 *       "songs": ["New Song 1", "New Song 2"]
 *     }
 *   },
 *   "song_modifications": {
 *     "song_additions": [
 *       {"name": "Added Song", "targetMod": "SomeMod"}
 *     ]
 *   }
 * }
 */

/**
 * Generate temporary custom weeks for mods that received new songs through Archipelago
	 *
	 * This function processes slot data from the Python world generation that includes:
	 * - customWeeks: Explicitly defined custom weeks from HScript processing
	 * - song_modifications: Song additions/exclusions that require new week files
	 *
	 * Custom weeks are generated as JSON files in the appropriate mod directories
	 * and are automatically unlocked for Archipelago play.
	 */
	private function generateCustomWeeks():Void
	{
		if (_slotData == null)
		{
			trace("No slot data found");
			return;
		}

		var hasCustomWeeks = Reflect.hasField(_slotData, "customWeeks");
		var hasSongMods = Reflect.hasField(_slotData, "song_modifications");

		trace('hasSongMods: $hasSongMods');

		if (!hasCustomWeeks && !hasSongMods)
		{
			trace("No custom weeks or song modifications data found in slot data");
			return;
		}

		#if MODS_ALLOWED
		// Process custom weeks data if available
		if (hasCustomWeeks)
		{
			var customWeeksData:Dynamic = Reflect.field(_slotData, "customWeeks");
			if (customWeeksData != null)
			{
				// Process each custom week
				for (field in Reflect.fields(customWeeksData))
				{
					var weekData:Dynamic = Reflect.field(customWeeksData, field);
					var targetMod:String = weekData.targetMod != null ? weekData.targetMod : "";
					var songs:Array<String> = weekData.songs;

					if (songs == null || songs.length == 0)
					{
						trace('Invalid custom week data for ${field}: no songs');
						continue;
					}

					// Extract optional week-level metadata
					var difficulties:Array<String> = weekData.difficulties;
					var defaultIcon:String = weekData.icon;
					var defaultColor:Array<Int> = weekData.color;

					// Create metadata for songs, prioritizing per-song metadata over week defaults
					var songMetadata:Array<Dynamic> = [];

					// Check if per-song metadata is available
					if (weekData.songMetadata != null)
					{
						var perSongMetadata:Array<Dynamic> = weekData.songMetadata;
						for (i in 0...songs.length)
						{
							var songName = songs[i];
							var songMeta:Dynamic = {name: songName};

							// Find matching metadata for this song
							var foundMetadata:Dynamic = null;
							for (meta in perSongMetadata)
							{
								if (meta.name == songName)
								{
									foundMetadata = meta;
									break;
								}
							}

							// Use per-song metadata if available, otherwise fall back to week defaults
							if (foundMetadata != null)
							{
								songMeta.icon = foundMetadata.icon != null ? foundMetadata.icon : (defaultIcon != null ? defaultIcon : "face");
								songMeta.color = foundMetadata.color != null ? foundMetadata.color : (defaultColor != null ? defaultColor : [146, 113, 253]);
							}
							else
							{
								songMeta.icon = defaultIcon != null ? defaultIcon : "face";
								songMeta.color = defaultColor != null ? defaultColor : [146, 113, 253];
							}

							songMetadata.push(songMeta);
						}
					}
					else
					{
						// No per-song metadata, use week defaults for all songs
						for (song in songs)
						{
							songMetadata.push({
								name: song,
								icon: defaultIcon != null ? defaultIcon : "face",
								color: defaultColor != null ? defaultColor : [146, 113, 253]
							});
						}
					}

					// Create the custom week with metadata
					createOptimizedTemporaryWeek(field, targetMod, songs, songMetadata, difficulties);
					trace('Created custom week ${field} with ${songs.length} songs and per-song metadata');
				}
			}
		}

		// Process song modifications if available
		if (hasSongMods)
		{
			var songModsData:Dynamic = Reflect.field(_slotData, "song_modifications");
			trace('songModsData: $songModsData');
			if (songModsData != null)
			{
				processSongModifications(songModsData);
			}
		}

		// Reload week data to include newly generated weeks
		WeekData.reloadWeekFiles(false);
		trace("Custom weeks generated and week data reloaded");
		#else
		trace("Mods not allowed, skipping custom week generation");
		#end
	}

	// Process song additions and exclusions from slot data
	private function processSongModifications(songModsData:Dynamic):Void
	{
		// Process song additions - create optimized temporary weeks based on difficulties
		if (Reflect.hasField(songModsData, "song_additions"))
		{
			var songAdditions:Array<Dynamic> = Reflect.field(songModsData, "song_additions");
			if (songAdditions != null && songAdditions.length > 0)
			{
				trace('Processing ${songAdditions.length} song additions with difficulty optimization');

				// Group songs by target mod first, then by difficulty set
				var modGroups:Map<String, Array<Dynamic>> = new Map();

				for (addition in songAdditions)
				{
					var targetMod:String = addition.targetMod != null ? addition.targetMod : "";

					if (!modGroups.exists(targetMod))
					{
						modGroups.set(targetMod, []);
					}
					modGroups.get(targetMod).push(addition);
				}

				// For each mod, group by difficulties and create optimized weeks
				for (targetMod in modGroups.keys())
				{
					var modSongs = modGroups.get(targetMod);
					var difficultyGroups:Map<String, Array<Dynamic>> = new Map();

					// Group songs by their difficulty sets
					for (song in modSongs)
					{
						var difficultyKey:String;

						if (song.difficulties != null && song.difficulties.length > 0)
						{
							// Sort difficulties for consistent grouping (convert to lowercase)
							var sortedDiffs:Array<String> = [for (diff in song.difficulties.toIterable()) diff.toLowerCase()];
							sortedDiffs.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
							difficultyKey = sortedDiffs.join("|");
						}
						else
						{
							difficultyKey = "default";
						}

						if (!difficultyGroups.exists(difficultyKey))
						{
							difficultyGroups.set(difficultyKey, []);
						}
						difficultyGroups.get(difficultyKey).push(song);
					}

					// Create optimized weeks for each difficulty group
					for (difficultyKey in difficultyGroups.keys())
					{
						var songs = difficultyGroups.get(difficultyKey);
						if (songs.length == 0) continue;

						// Generate week name based on difficulty set
						var weekName:String;
						if (difficultyKey == "default")
						{
							weekName = 'ap_custom_' + (targetMod != "" ? targetMod : "base");
						}
						else
						{
							var diffSuffix = difficultyKey.replace("|", "_");
							weekName = 'ap_custom_' + (targetMod != "" ? targetMod : "base") + '_' + diffSuffix;
						}

						// Extract song names and metadata
						var songNames:Array<String> = [];
						var songMetadata:Array<Dynamic> = [];
						var weekDifficulties:Array<String> = null;

						for (song in songs)
						{
							songNames.push(song.name);

							// Create metadata with icon and color from slot data
							var metadata:Dynamic = {
								name: song.name,
								icon: song.icon != null ? song.icon : "face",
								color: song.color != null ? song.color : [146, 113, 253]
							};
							songMetadata.push(metadata);

							// Use first song's difficulties for the week
							if (weekDifficulties == null && song.difficulties != null && song.difficulties.length > 0)
							{
								weekDifficulties = [for (diff in song.difficulties.toIterable()) diff.toLowerCase()];
							}
						}

						createOptimizedTemporaryWeek(weekName, targetMod, songNames, songMetadata, weekDifficulties);
						trace('Created optimized week ${weekName} with ${songs.length} songs for difficulty set: ${difficultyKey}');
					}
				}

				trace('Completed optimized temporary week creation for song additions');
			}
		}

		// Note: Song exclusions don't need week generation, they're handled by removing songs from existing weeks
		// This would typically be handled during song list processing in other parts of the system
		if (Reflect.hasField(songModsData, "song_exclusions"))
		{
			var songExclusions:Array<Dynamic> = Reflect.field(songModsData, "song_exclusions");
			if (songExclusions != null && songExclusions.length > 0)
			{
				trace('Song exclusions found: ${songExclusions.length} exclusions to process');
				// Song exclusions are typically processed during song list filtering
				// rather than during week generation
			}
		}
	}

	// Generate a custom week file for a specific mod and song list
	private function generateCustomWeekFile(weekName:String, targetMod:String, songs:Array<String>):Void
	{
		try
		{
			trace('Generating custom week file: ${weekName} for mod: ${targetMod} with ${songs.length} songs: ${songs.join(", ")}');

			// Validate inputs
			if (weekName == null || weekName.trim() == "")
			{
				trace('Error: Invalid week name for custom week generation');
				return;
			}

			if (songs == null || songs.length == 0)
			{
				trace('Error: No songs provided for custom week ${weekName}');
				return;
			}

			// Create the temporary week directly (no file I/O)
			createTemporaryWeek(weekName, targetMod, songs);
		}
		catch (e:Dynamic)
		{
			trace('Error generating custom week file ${weekName}: ${e}');
			#if sys
			trace('Stack trace: ${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
			#end
		}
	}

	// Create a single temporary week for a mod
	private function createTemporaryWeek(weekName:String, targetMod:String, songs:Array<String>):Void
	{
		if (temporaryWeekNames.contains(weekName))
			weekName = weekName + "+";

		try
		{
			trace('Creating temporary week: ${weekName} for mod: ${targetMod} with ${songs.length} songs: ${songs.join(", ")}');

			// Create week file structure
			var weekFile:WeekFile = {
				songs: [],
				weekCharacters: ['bf', 'bf', 'gf'], // Default characters
				weekBackground: 'stage', // Default background
				weekBefore: '', // No prerequisite week
				storyName: weekName.replace("ap_custom_", "AP Custom "), // Display name
				weekName: weekName, // Internal name
				startUnlocked: true, // Always unlocked for AP weeks
				hiddenUntilUnlocked: false,
				hideStoryMode: false, // Show in story mode
				hideFreeplay: false, // Show in freeplay
				difficulties: '', // Use default difficulties
				category: 'archipelago' // Custom category for AP weeks
			};

			// Add songs to the week file
			for (song in songs)
			{
				// Format: [songName, iconName, [r, g, b]]
				weekFile.songs.push([song, 'face', [146, 113, 253]]); // Default icon and color
			}

			trace('weekFile: $weekFile');

			// Create WeekData object from WeekFile
			var weekData:WeekData = new WeekData(weekFile, weekName);
			weekData.folder = targetMod; // Set the mod folder

			// Add to temporary arrays for tracking
			temporaryWeeks.push(weekData);
			temporaryWeekNames.push(weekName);

			trace('weekFile: $weekData');

			// Add directly to the WeekData system (in-memory only)
			WeekData.weeksLoaded.set(weekName, weekData);
			WeekData.weeksList.push(weekName);

			trace('weeksLoaded: ${WeekData.weeksLoaded}');
			trace('weeksList: ${WeekData.weeksList}');

			trace('Successfully created temporary week: ${weekName}');
		}
		catch (e:Dynamic)
		{
			trace('Error creating temporary week ${weekName}: ${e}');
			#if sys
			trace('Stack trace: ${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
			#end
		}
	}

	// Create an optimized temporary week with metadata support
	private function createOptimizedTemporaryWeek(weekName:String, targetMod:String, songs:Array<String>, ?songMetadata:Array<Dynamic>, ?difficulties:Array<String>):Void
	{
		if (temporaryWeekNames.contains(weekName))
			weekName = weekName + "+";

		try
		{
			trace('Creating optimized temporary week: ${weekName} for mod: ${targetMod} with ${songs.length} songs: ${songs.join(", ")}');

			// Create week file structure
			var weekFile:WeekFile = {
				songs: [],
				weekCharacters: ['bf', 'bf', 'gf'], // Default characters
				weekBackground: 'stage', // Default background
				weekBefore: '', // No prerequisite week
				storyName: weekName.replace("ap_custom_", "AP Custom "), // Display name
				weekName: weekName, // Internal name
				startUnlocked: true, // Always unlocked for AP weeks
				hiddenUntilUnlocked: false,
				hideStoryMode: false, // Show in story mode
				hideFreeplay: false, // Show in freeplay
				difficulties: '', // Will be set below if provided
				category: 'archipelago' // Custom category for AP weeks
			};

			// Set custom difficulties if provided
			if (difficulties != null && difficulties.length > 0)
			{
				weekFile.difficulties = difficulties.join(',');
				trace('Set custom difficulties for week ${weekName}: ${difficulties.join(", ")}');
			}

			// Add songs to the week file with metadata
			for (i in 0...songs.length)
			{
				var songName = songs[i];
				var icon = "face"; // Default icon
				var color = [146, 113, 253]; // Default color

				// Use metadata if available
				if (songMetadata != null && i < songMetadata.length)
				{
					var metadata = songMetadata[i];
					if (metadata.icon != null) icon = metadata.icon;
					if (metadata.color != null) color = metadata.color;
				}

				// Format: [songName, iconName, [r, g, b]]
				weekFile.songs.push([songName, icon, color]);
				trace('Added song ${songName} with icon: ${icon}, color: ${color}');
			}

			// Create WeekData object from WeekFile
			var weekData:WeekData = new WeekData(weekFile, weekName);
			weekData.folder = targetMod; // Set the mod folder

			// Add to temporary arrays for tracking
			temporaryWeeks.push(weekData);
			temporaryWeekNames.push(weekName);

			// Add directly to the WeekData system (in-memory only)
			WeekData.weeksLoaded.set(weekName, weekData);
			WeekData.weeksList.push(weekName);

			trace('Successfully created optimized temporary week: ${weekName}');
		}
		catch (e:Dynamic)
		{
			trace('Error creating optimized temporary week ${weekName}: ${e}');
			#if sys
			trace('Stack trace: ${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
			#end
		}
	}

	/**
	 * Clean up all temporary weeks created for this AP session
	 * This removes them from WeekData.weeksLoaded and WeekData.weeksList
	 * but does not affect any permanent week files
	 */
	public static function cleanupTemporaryWeeks():Void
	{
		if (temporaryWeeks.length == 0)
		{
			return; // Nothing to clean up
		}

		trace('Cleaning up ${temporaryWeeks.length} temporary AP weeks');

		// Remove from WeekData system
		for (weekName in temporaryWeekNames)
		{
			WeekData.weeksLoaded.remove(weekName);
			WeekData.weeksList.remove(weekName);
			trace('Removed temporary week: ${weekName}');
		}

		// Clear our tracking arrays
		temporaryWeeks = [];
		temporaryWeekNames = [];

		trace('Temporary week cleanup completed');
	}

	/**
	 * Static function to force cleanup from anywhere in the codebase
	 * Useful for ensuring cleanup happens during app exit or state changes
	 */
	public static function forceCleanupTemporaryWeeks():Void
	{
		cleanupTemporaryWeeks();
	}

	/**
	 * Validate that all temporary weeks were created successfully
	 * @return true if all temporary weeks are valid, false if any issues found
	 */
	public function validateTemporaryWeeks():Bool
	{
		if (temporaryWeeks == null || temporaryWeekNames == null)
		{
			trace("Warning: Temporary week arrays are null");
			return false;
		}

		// Check that arrays have matching sizes
		if (temporaryWeeks.length != temporaryWeekNames.length)
		{
			trace('Warning: Temporary week arrays have mismatched sizes - weeks: ${temporaryWeeks.length}, names: ${temporaryWeekNames.length}');
			return false;
		}

		var validCount = 0;
		var totalCount = temporaryWeeks.length;

		// Validate each temporary week
		for (i in 0...temporaryWeeks.length)
		{
			var weekData = temporaryWeeks[i];
			var weekName = temporaryWeekNames[i];

			if (weekData == null)
			{
				trace('Warning: Temporary week at index ${i} is null');
				continue;
			}

			if (weekName == null || weekName.trim() == "")
			{
				trace('Warning: Temporary week name at index ${i} is null or empty');
				continue;
			}

			// Validate week data structure
			if (weekData.weekName == null || weekData.weekName.trim() == "")
			{
				trace('Warning: Week "${weekName}" has invalid weekName field');
				continue;
			}

			if (weekData.songs == null || weekData.songs.length == 0)
			{
				trace('Warning: Week "${weekName}" has no songs');
				continue;
			}

			// Validate song structure
			var validSongs = 0;
			for (song in weekData.songs)
			{
				if (song != null && song.length >= 2 && song[0] != null && song[0].trim() != "")
				{
					validSongs++;
				}
				else
				{
					trace('Warning: Week "${weekName}" has invalid song entry: ${song}');
				}
			}

			if (validSongs == 0)
			{
				trace('Warning: Week "${weekName}" has no valid songs');
				continue;
			}

			// Week passed all validations
			validCount++;
			trace('Validated temporary week: "${weekName}" with ${validSongs} songs');
		}

		var success = (validCount == totalCount && totalCount > 0);
		trace('Temporary week validation complete: ${validCount}/${totalCount} valid weeks');

		return success;
	}

	// Update the weekList.txt file to include the new custom week
	private function updateWeekList(targetMod:String, weekName:String):Void
	{
		#if MODS_ALLOWED
		try
		{
			var weekListPath:String;

			if (targetMod == "" || targetMod == null)
			{
				// Base game weekList
				weekListPath = Paths.getSharedPath('weeks/weekList.txt');
			}
			else
			{
				// Mod weekList
				weekListPath = Paths.mods('${targetMod}/weeks/weekList.txt');
			}

			var currentWeeks:Array<String> = [];

			// Read existing weekList if it exists
			if (FileSystem.exists(weekListPath))
			{
				var content = File.getContent(weekListPath);
				currentWeeks = content.split('\n').map(function(line) return line.trim()).filter(function(line) return line.length > 0);
			}

			// Add the new week if it's not already in the list
			if (!currentWeeks.contains(weekName))
			{
				currentWeeks.push(weekName);

				// Save the updated weekList
				var updatedContent = currentWeeks.join('\n') + '\n';
				File.saveContent(weekListPath, updatedContent);

				trace('Updated weekList.txt to include: ${weekName}');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error updating weekList for ${targetMod}: ${e}');
		}
		#end
	}

	// Check if custom week generation completed successfully
	public function validateCustomWeeks():Bool
	{
		#if MODS_ALLOWED
		if (_slotData == null)
		{
			return true; // No slot data, nothing to validate
		}

		var hasCustomWeeks = Reflect.hasField(_slotData, "customWeeks");
		var hasSongMods = Reflect.hasField(_slotData, "song_modifications");

		if (!hasCustomWeeks && !hasSongMods)
		{
			return true; // No custom week data, validation passes
		}

		var allWeeksExist = true;

		// Check custom weeks
		if (hasCustomWeeks)
		{
			var customWeeksData:Dynamic = Reflect.field(_slotData, "customWeeks");
			if (customWeeksData != null)
			{
				for (field in Reflect.fields(customWeeksData))
				{
					var weekData:Dynamic = Reflect.field(customWeeksData, field);
					var targetMod:String = weekData.target_mod;

					var weekFileName = field + ".json";
					var weekPath:String;

					if (targetMod == "" || targetMod == null)
					{
						weekPath = Paths.getSharedPath('weeks/${weekFileName}');
					}
					else
					{
						weekPath = Paths.mods('${targetMod}/weeks/${weekFileName}');
					}

					if (!FileSystem.exists(weekPath))
					{
						trace('Custom week file missing: ${weekPath}');
						allWeeksExist = false;
					}
				}
			}
		}

		// Check for generated weeks from song modifications
		if (hasSongMods)
		{
			var songModsData:Dynamic = Reflect.field(_slotData, "song_modifications");
			if (songModsData != null && Reflect.hasField(songModsData, "song_additions"))
			{
				var songAdditions:Array<Dynamic> = Reflect.field(songModsData, "song_additions");
				if (songAdditions != null && songAdditions.length > 0)
				{
					var modSongs:Map<String, Bool> = new Map();

					for (addition in songAdditions)
					{
						var targetMod:String = addition.targetMod != null ? addition.targetMod : "";
						modSongs.set(targetMod, true);
					}

					for (targetMod in modSongs.keys())
					{
						var weekName = 'ap_custom_' + (targetMod != "" ? targetMod : "base");
						var weekFileName = weekName + ".json";
						var weekPath:String;

						if (targetMod == "" || targetMod == null)
						{
							weekPath = Paths.getSharedPath('weeks/${weekFileName}');
						}
						else
						{
							weekPath = Paths.mods('${targetMod}/weeks/${weekFileName}');
						}

						if (!FileSystem.exists(weekPath))
						{
							trace('Generated custom week file missing: ${weekPath}');
							allWeeksExist = false;
						}
					}
				}
			}
		}

		return allWeeksExist;
		#else
		return true; // Mods not allowed, skip validation
		#end
	}

	/**
	 * Public function to manually trigger temporary week creation
	 * Can be called if weeks need to be regenerated
	 *
	 * Example usage:
	 * APGameState.instance.regenerateTemporaryWeeks();
	 */
	public function regenerateTemporaryWeeks():Void
	{
		trace("Manually regenerating temporary weeks...");
		generateCustomWeeks();

		if (validateTemporaryWeeks())
		{
			trace("Temporary week regeneration completed successfully");
		}
		else
		{
			trace("Warning: Some temporary weeks may not have been created correctly");
		}
	}

	public var isPurposefullyDisconnected:Bool = false;

	// Static variables to handle reconnection callbacks
	public static var pendingReconnection:Bool = false;
	public static var reconnectionCallback:Void->Void = null;
	public static var reconnectionTargetState:FlxState = null;

	// Temporary storage for offline queue during reconnection
	private static var _tempOfflineQueue:Array<archipelago.Definitions.OfflineQueueType> = null;

	/**
	 * Static method to trigger reconnection process manually
	 */
	public static function triggerReconnection():Void {
		if (instance != null && !pendingReconnection) {
			trace("Manually triggering reconnection process");
			instance.onSocketDisconnected();
		}
	}

	/**
	 * Static method to manually inject offline queue into current client
	 */
	public static function injectOfflineQueue(queue:Array<archipelago.Definitions.OfflineQueueType>):Bool {
		if (instance != null && instance._ap != null && queue != null && queue.length > 0) {
			try {
				trace('Manually injecting ${queue.length} items into current client offline queue');
				@:privateAccess instance._ap._offlineQueue = instance._ap._offlineQueue.concat(queue);
				trace('Manual offline queue injection successful');
				return true;
			} catch (e) {
				trace('Error during manual offline queue injection: ' + e);
				return false;
			}
		}
		return false;
	}

	private function onSocketDisconnected():Void
	{
		if (isPurposefullyDisconnected)
		{
			trace("Socket disconnected purposefully, not attempting reconnection");
			return;
		}

		trace("Socket disconnected unexpectedly, setting up reconnection callback");

		// Set up callback system for next state transition
		pendingReconnection = true;

		_ap.dontTryToReconnect = true; // Prevent automatic reconnection attempts

		// Store connection settings for later use
		var FNF = new FlxSave();
		FNF.bind("FNF");
		var lastGame:Dynamic = FNF.data.lastGame;
		var hostValue = "archipelago.gg";
		var portValue = "38281";
		var slotValue = "Player";
		var passwordValue = "";

		if (lastGame != null) {
			hostValue = lastGame.server != null ? lastGame.server : "archipelago.gg";
			portValue = lastGame.port != null ? lastGame.port : "38281";
			slotValue = lastGame.slot != null ? lastGame.slot : "Player";
		}
		FNF.destroy();

		// Create the reconnection callback that will be triggered on next state transition
		var gameStateInstance = this; // Capture current instance for closure
		reconnectionCallback = function() {
			trace("Executing reconnection callback during state transition");

			// First, show generic progress substate for cleanup
			@:privateAccess
			var cleanupTasks = [
				GenericProgressSubstate.createTask("Cleaning up temporary weeks...", function(results) {
					try {
						cleanupTemporaryWeeks();
						trace('Temporary weeks cleaned up successfully');
						return "cleanup_success";
					} catch (e) {
						trace('Error cleaning up temporary weeks: ' + e);
						return "cleanup_error";
					}
				}, false),
				GenericProgressSubstate.createTask("Cleaning up AP items and data...", function(results) {
					try {
						APItem.cleanupAllAPData();
						trace('AP items and data cleaned up successfully during disconnect');
						return "ap_cleanup_success";
					} catch (e) {
						trace('Error cleaning up AP items and data during disconnect: ' + e);
						return "ap_cleanup_error";
					}
				}, false),
				   GenericProgressSubstate.createTask("Gathering Offline Queue...", function(results) {
					   try {
						   if (gameStateInstance._ap != null && gameStateInstance._ap._offlineQueue != null) {
							   _tempOfflineQueue = gameStateInstance._ap._offlineQueue.copy();
							   trace('Offline queue gathered, ${_tempOfflineQueue != null ? _tempOfflineQueue.length : 0} items');
							   // Save offline queue to save data if it has items
							   if (_tempOfflineQueue.length > 0 && gameStateInstance._saveData != null) {
								   gameStateInstance._saveData.addItem("offlineQueue", _tempOfflineQueue);
								   gameStateInstance._saveData.save();
							   } else if (gameStateInstance._saveData != null && gameStateInstance._saveData.hasItem("offlineQueue")) {
								   gameStateInstance._saveData.removeItem("offlineQueue");
								   gameStateInstance._saveData.save();
							   }
						   } else {
							   _tempOfflineQueue = [];
							   trace('No offline queue found');
							   if (gameStateInstance._saveData != null && gameStateInstance._saveData.hasItem("offlineQueue")) {
								   gameStateInstance._saveData.removeItem("offlineQueue");
								   gameStateInstance._saveData.save();
							   }
						   }
						   return "offline_queue_gathered";
					   } catch (e) {
						   trace('Error gathering offline queue: ' + e);
						   _tempOfflineQueue = [];
						   if (gameStateInstance._saveData != null && gameStateInstance._saveData.hasItem("offlineQueue")) {
							   gameStateInstance._saveData.removeItem("offlineQueue");
							   gameStateInstance._saveData.save();
						   }
						   return "offline_queue_error";
					   }
				   }, false)
			];

			var cleanupDialog = new GenericProgressSubstate(
				"Preparing Reconnection",
				cleanupTasks,
				function(results) {
					// On cleanup complete, show connection substate
					trace("Cleanup complete, showing connection substate");

					var connectionSubstate = new ConnectionSubstate(
						hostValue,
						portValue,
						slotValue,
						passwordValue,
						function(client:Client, slotData:Dynamic) {
							// Reconnection successful - update the AP client and continue
							gameStateInstance._ap = client;
							APEntryState.ap = client;

							// Update game state with new connection
							archipelago.APPlayState.apGame = gameStateInstance;
							archipelago.APInfo.apGame = gameStateInstance;
							archipelago.APInfo.ap = gameStateInstance._ap;

							// Re-setup callbacks
							gameStateInstance._ap.onSocketDisconnected.add(gameStateInstance.onSocketDisconnected);
							gameStateInstance._ap.onPrintJSON.add(gameStateInstance.sendMessage);
							gameStateInstance._ap.onPrint.add(gameStateInstance.sendMessageSimple);

							// Restore death link state from ClientPrefs after reconnection
							trace('Restoring death link state after reconnection: ${ClientPrefs.data.deathlink}');
							gameStateInstance._ap.toggleDeathLink(ClientPrefs.data.deathlink);

							// Validate that the death link state was restored correctly
							gameStateInstance.validateDeathLinkState();

										APEntryState.gonnaRunSync = true; // Force sync on next update
										client.Sync();


							// Inject offline queue into new client if available
							if (_tempOfflineQueue != null && _tempOfflineQueue.length > 0) {
								trace('Injecting ${_tempOfflineQueue.length} items from offline queue into new client');
								trace('Offline queue contents: ${_tempOfflineQueue}');
								try {
									// Use @:privateAccess to access the private _offlineQueue field
									@:privateAccess gameStateInstance._ap._offlineQueue = _tempOfflineQueue.copy();
									// trace('Offline queue injection successful - new client queue length: ${gameStateInstance._ap._offlineQueue.length}');
								} catch (e) {
									trace('Error injecting offline queue: ' + e);
								}
								// Clear temp queue after injection
								_tempOfflineQueue = null;
							} else {
								trace('No offline queue to inject');
							}

							// Regenerate custom weeks
							gameStateInstance.generateCustomWeeks();

							trace('Reconnection successful!');

							// Clear the pending reconnection state
							pendingReconnection = false;
							reconnectionCallback = null;

							// Now proceed with the original state transition
							if (reconnectionTargetState != null) {
								trace("Proceeding with delayed state transition");
								var targetState = reconnectionTargetState;
								reconnectionTargetState = null;
								MusicBeatState.switchState(targetState);
							}
						},
						   function(error:String) {
							   // Reconnection failed - schedule another attempt
							   trace('Reconnection failed: ' + error + ' - scheduling retry');
							   // Grab and switch to the target state if set
							   var targetState = reconnectionTargetState;
							   pendingReconnection = false;
							   reconnectionCallback = null;
							   reconnectionTargetState = null;
							   if (targetState != null) {
								   MusicBeatState.switchState(targetState);
							   }
							   // Wait 3 seconds, then try again (unless purposefully disconnected)
							   haxe.Timer.delay(function() {
								   if (!isPurposefullyDisconnected) {
									   gameStateInstance.onSocketDisconnected();
								   } else {
									   trace('Purposefully disconnected, not retrying');
								   }
							   }, 3000);
						   }
					);

					FlxG.state.openSubState(connectionSubstate);
				},
				function(error, shouldThrow) {
					trace('Error during cleanup: ' + error);
					// Even if cleanup fails, try to reconnect
					var connectionSubstate = new ConnectionSubstate(
						hostValue,
						portValue,
						slotValue,
						passwordValue,
						function(client:Client, slotData:Dynamic) {
							// Same success handler as above
							gameStateInstance._ap = client;
							APEntryState.ap = client;
							archipelago.APPlayState.apGame = gameStateInstance;
							archipelago.APInfo.apGame = gameStateInstance;
							archipelago.APInfo.ap = gameStateInstance._ap;
							gameStateInstance._ap.onSocketDisconnected.add(gameStateInstance.onSocketDisconnected);
							gameStateInstance._ap.onPrintJSON.add(gameStateInstance.sendMessage);
							gameStateInstance._ap.onPrint.add(gameStateInstance.sendMessageSimple);

							// Restore death link state from ClientPrefs after reconnection (fallback)
							trace('Restoring death link state after reconnection (fallback): ${ClientPrefs.data.deathlink}');
							gameStateInstance._ap.toggleDeathLink(ClientPrefs.data.deathlink);

							// Validate that the death link state was restored correctly
							gameStateInstance.validateDeathLinkState();

							// Inject offline queue into new client if available
							if (_tempOfflineQueue != null && _tempOfflineQueue.length > 0) {
								trace('Injecting ${_tempOfflineQueue.length} items from offline queue into new client (fallback)');
								trace('Offline queue contents (fallback): ${_tempOfflineQueue}');
								try {
									// Use @:privateAccess to access the private _offlineQueue field
									@:privateAccess gameStateInstance._ap._offlineQueue = _tempOfflineQueue.copy();
									// trace('Offline queue injection successful (fallback) - new client queue length: ${gameStateInstance._ap._offlineQueue.length}');
								} catch (e) {
									trace('Error injecting offline queue (fallback): ' + e);
								}
								// Clear temp queue after injection
								_tempOfflineQueue = null;
							} else {
								trace('No offline queue to inject (fallback)');
							}

							gameStateInstance.generateCustomWeeks();
							trace('Reconnection successful after cleanup error!');
							pendingReconnection = false;
							reconnectionCallback = null;
							if (reconnectionTargetState != null) {
								var targetState = reconnectionTargetState;
								reconnectionTargetState = null;
								MusicBeatState.switchState(targetState);
							}
						},
						   function(error:String) {
							   trace('Reconnection failed: ' + error + ' - scheduling retry');
							   var targetState = reconnectionTargetState;
							   pendingReconnection = false;
							   reconnectionCallback = null;
							   reconnectionTargetState = null;
							   if (targetState != null) {
								   MusicBeatState.switchState(targetState);
							   }
							   haxe.Timer.delay(function() {
								   if (!isPurposefullyDisconnected) {
									   gameStateInstance.onSocketDisconnected();
								   } else {
									   trace('Purposefully disconnected, not retrying');
								   }
							   }, 3000);
						   }
					);
					FlxG.state.openSubState(connectionSubstate);
				},
				function() {
					// Cancel callback
					trace('Cleanup canceled by user');
					pendingReconnection = false;
					reconnectionCallback = null;
					reconnectionTargetState = null;
					_tempOfflineQueue = null;
				}
			);

			FlxG.state.openSubState(cleanupDialog);
		};
	}
	private function onCancel():Void
	{
		// Clean up temporary weeks when canceling/exiting AP mode
		cleanupTemporaryWeeks();

		// Clean up High Quality Trap temporary files
		#if ARCHIPELAGO_ALLOWED
		archipelago.HighQualityTrapManager.onAPSessionEnd();
		#end

		// Clean up AP Items and related data
		archipelago.APItem.cleanupAllAPData();

		// Clear reconnection callback state
		pendingReconnection = false;
		reconnectionCallback = null;
		reconnectionTargetState = null;
		_tempOfflineQueue = null;

		_ap.clientStatus = ClientStatus.UNKNOWN;
		_ap.onSocketDisconnected.remove(onSocketDisconnected);
		_ap = null;
		APEntryState.ap = null;
		APEntryState.apGame = null;
		APEntryState.inArchipelagoMode = false;
		MusicBeatState.switchState(new APEntryState());
	}

		private function onReconnect():Void
		{
			MusicBeatState.switchState(new archipelago.APCategoryState(this, APEntryState.ap));
		}

	/**
	 * Validates and synchronizes the death link state between ClientPrefs and the AP client
	 * Call this periodically or when you suspect the death link state might be out of sync
	 */
	public function validateDeathLinkState():Bool {
		if (_ap == null) return false;

		var clientPrefsEnabled = ClientPrefs.data.deathlink;
		var clientTagsHaveDeathLink = _ap.tagsManager.hasDeathLink();

		// Check if they're out of sync
		if (clientPrefsEnabled != clientTagsHaveDeathLink) {
			trace('Death Link state mismatch detected - ClientPrefs: $clientPrefsEnabled, Client Tags: $clientTagsHaveDeathLink');

			// Re-sync by toggling death link with the ClientPrefs setting
			if (clientPrefsEnabled) {
				_ap.tagsManager.enableDeathLink();
			} else {
				_ap.tagsManager.disableDeathLink();
			}

			trace('Death Link state synchronized to: $clientPrefsEnabled');
			return false; // Return false to indicate there was a sync issue
		}

		return true; // Return true to indicate state was already synced
	}

	/**
	 * Force-enable death link if it should be enabled but isn't
	 * This is a more aggressive sync that prioritizes the setting being enabled
	 */
	public function ensureDeathLinkEnabled():Void {
		if (_ap == null || !ClientPrefs.data.deathlink) return;

		if (!_ap.tagsManager.hasDeathLink()) {
			trace('Death Link should be enabled but client tags missing DeathLink - forcing enable');
			_ap.tagsManager.enableDeathLink();
		}
	}

		// public function onRoomUpdate(roomUpdatePacket:RoomUpdatePacket)
		// {
		//     _ap.clientStatus = ClientStatus.PLAYING;
		// }
	}
