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
import archipelago.Client;
import archipelago.PacketTypes;
import backend.Paths;
import backend.WeekData.WeekFile;
import backend.WeekData;
import flixel.FlxState;
import haxe.DynamicAccess;
import haxe.ds.Option;
import lime.app.Future;
import lime.app.Promise;
import openfl.text.TextFormat;
import yutautil.AprilFools;
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
	nonSongs:Map<String, Int>,
	nonSongsNames:Array<String>,
	unlockedSongs:Array<{song:String, mod:String}>,
	itemsToTrigger:Array<String>
};

class APGameState
{
	public static var instance:APGameState;

	private var _ap:Client;
	private var _seed:String;
	private var _disconnectSubstate:APDisconnectSubstate;
	private var _saveData:yutautil.save.MixSaveWrapper;

	// Temporary weeks created for AP session - automatically cleaned up on disconnect/exit
	public static var temporaryWeeks:Array<WeekData> = [];
	public static var temporaryWeekNames:Array<String> = [];

	public var connected(get, never):Bool;

	public var APLocations:Array<Int> = [];
	public var APItems:Map<String, Int> = new Map<String, Int>();
	public var ItemIndex:Int = -1;

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

	public function checkGoal(songName:String, ?modName:String):Bool
	{
		modName = (modName != null && modName != "") ? modName.trim() : "";
		var info = info();
		var locations = locationData(songName, modName).concat(noteData(songName, modName));
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

		_disconnectSubstate = new APDisconnectSubstate(_ap);
		_disconnectSubstate.setSeed(_seed);
		_disconnectSubstate.onCancel.add(onCancel);
		_disconnectSubstate.onReconnect.add(onReconnect);

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

		_ap.toggleDeathLink(slotData != null
			&& Reflect.hasField(slotData, "deathLink") ? slotData?.deathLink : ClientPrefs.data.deathlink);
			ClientPrefs.data.deathlink = slotData != null
			&& Reflect.hasField(slotData, "deathLink") ? slotData?.deathLink : ClientPrefs.data.deathlink;

		_ap.onRetrieved.add(handleRetrievedPacket);

		// _ap.onConnect.add(function() {
		//     _ap.clientStatus = ClientStatus.CONNECTED;
		// });

		// _ap.onRoomInfo.add(onRoomInfo);
		// _ap.onSlotRefused.add(onSlotRefused);
		// _ap.onSlotConnected.add(onSlotConnected);
		APPlayState.deathByLink = false;

		// Generate custom week files if they don't exist
		// This processes slot data that contains information about:
		// - Custom weeks defined in HScript files
		// - Song modifications (additions/exclusions) from mod processing
		generateCustomWeeks();
	}

	function handleRetrievedPacket(retrievedPacket:haxe.DynamicAccess<Dynamic>):Void
	{
		//trace("Retrieved packet: " + retrievedPacket);
		for (key in retrievedPacket.keys())
		{
			var value = retrievedPacket.get(key);
			if (key.indexOf("_read_hints_") != -1)
			{
				APFreeplayManager.hintTable = new Map<String, String>();
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

						var songName = getFullNameFromSongAndMod(songName);

						if (APFreeplayManager.hintTable.exists(songName))
						{
							APFreeplayManager.hintTable.set(songName, APFreeplayManager.hintTable.get(songName) + "\n" + message);
						}
						else
						{
							APFreeplayManager.hintTable.set(songName, message);
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
		for (hint in APFreeplayManager.hintTable.keys())
		{
			APFreeplayManager.curHinted = [];
			var message = APFreeplayManager.hintTable.get(hint);
			trace("Hint: " + hint + " - " + message);
			var hintSong = getSongAndMod(hint);
			APFreeplayManager.curHinted.push({song: hintSong.song, mod: hintSong.mod != null ? hintSong.mod : ""});
			trace(hintSong);
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
		if (_saveData.hasItem("hasPocketLens"))
		{
			APItem.hasPocketLens = _saveData.getItem("hasPocketLens");
		}
		_saveData.save();
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
		_saveData.addItem("hasPocketLens", APItem.hasPocketLens);
		_saveData.save();
		trace("Save data updated!");
	}

	public function info()
	{
		return _ap;
	}

	function bouncy(data:Dynamic)
	{
		trace("Bounce packet received: " + haxe.Json.stringify(data));

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
				archipelago.APItem.APChartModifier.restoreFromSave(modifier).fromTrapLink = true;
			}
			else
			{
				archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
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
					archipelago.APItem.createItemByName("Blue Balls Curse").fromTrapLink = true;
					backend.COD.COD.COD = "Killed by Blue Balls Curse.\n(Instant Death TrapLink)";
				case "Ghost":
					archipelago.APItem.createItemByName("Ghost").fromTrapLink = true;
				case "My Turn! Trap":
					archipelago.APItem.createItemByName("My Turn! Trap").fromTrapLink = true;
				case "Paralyze Trap":
					archipelago.APItem.createItemByName("Paralyze Trap").fromTrapLink = true;
				case "Phone Trap" | "Literature Trap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Home Trap":
					archipelago.APItem.createItemByName("Tutorial Trap").fromTrapLink = true;
				case "Ice Trap":
					archipelago.APItem.createItemByName("Ice Trap").fromTrapLink = true;
				case "Freeze Trap" | "Frozen Trap" | "Bubble Trap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Army Trap" | "Police Trap" | "Buyon Trap" | "OmoTrap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Damage Trap":
					archipelago.APItem.createItemByName('Damage Trap').fromTrapLink = true;
				case "Chaos Control Trap":
					archipelago.APItem.createItemByName("Chaos Control Trap").fromTrapLink = true;
				case "Confuse Trap":
					archipelago.APItem.createItemByName("Confuse Trap").fromTrapLink = true;
				case "Eject Ability":
					archipelago.APItem.createItemByName("Eject Ability").fromTrapLink = true;
				case "Whoops! Trap":
					archipelago.APItem.createItemByName("Whoops! Trap").fromTrapLink = true;
				case "Zoom Trap":
					archipelago.APItem.createItemByName("Zoom Trap").fromTrapLink = true;
				case "Posession Trap":
					archipelago.APItem.createItemByName("Posession Trap").fromTrapLink = true;
				case "Poison Trap" | "Poison Mushroom":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Confound Trap":
					archipelago.APItem.createItemByName("Confound Trap").fromTrapLink = true;
				case "Fast Trap":
					archipelago.APItem.createItemByName("Fast Trap").fromTrapLink = true;
				case "Slow Trap" | "Slowness Trap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Deisometric Trap" | "Camera Rotate Trap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Push Trap":
					archipelago.APItem.createItemByName('Push Trap').fromTrapLink = true;
				case "Input Sequence Trap":
					archipelago.APItem.createItemByName('Input Sequence Trap').fromTrapLink = true;
				case "Pokemon Trivia Trap":
					archipelago.APItem.createItemByName('Pokemon Trivia Trap').fromTrapLink = true;
				case "Thwimp Trap":
					archipelago.APItem.createItemByName('Thwimp Trap').fromTrapLink = true;
				case "Tiny Trap":
					archipelago.APItem.createItemByName('Tiny Trap').fromTrapLink = true;
				case "Bonk Trap":
					archipelago.APItem.createItemByName('Bonk Trap').fromTrapLink = true;
				case "Bald Trap":
					archipelago.APItem.createItemByName('Bald Trap').fromTrapLink = true;
				case "Bomb" | "TNT Barrel Trap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Controller Drift Trap":
					archipelago.APItem.createItemByName("Controller Drift Trap").fromTrapLink = true;
				case "Timer Trap":
					archipelago.APItem.createItemByName("Timer Trap").fromTrapLink = true;
				case "Jump Trap" | "Spring Trap":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Animal Bonus Trap":
					archipelago.APItem.createItemByName("Animal Bonus Trap").fromTrapLink = true;
				case "Hiccup Trap":
					archipelago.APItem.createItemByName("Hiccup Trap").fromTrapLink = true;
				case "Gooey Bag":
					archipelago.APItem.createItemByName("Gooey Bag").fromTrapLink = true;
				case "Nut Trap":
					archipelago.APItem.createItemByName("Nut Trap").fromTrapLink = true;
				case "Pokemon Count Trap":
					archipelago.APItem.createItemByName("Pokemon Count Trap").fromTrapLink = true;
				case "Exposition Trap":
					archipelago.APItem.createItemByName("Exposition Trap").fromTrapLink = true;
				case "Double Damage":
					archipelago.APItem.createItemByName("Double Damage").fromTrapLink = true;
				case "Instant Crystal Trap" | "One Hit KO":
					archipelago.APItem.createItemByName(trapName).fromTrapLink = true;
				case "Mirror Trap":
					archipelago.APItem.createItemByName("Mirror Trap").fromTrapLink = true;
				case "Pixellation Trap":
					archipelago.APItem.createItemByName("Pixellation Trap").fromTrapLink = true;
				case "Swap Trap":
					archipelago.APItem.createItemByName("Swap Trap").fromTrapLink = true;
				default:
					// If it's not a known trap, we can just log it.
					trace("Unknown trap link received: " + trapName + ".");
			}
		}
	}

	function onSlotConnected(slotData:Dynamic)
	{
		if (backend.ClientPrefs.data.deathlink)
			_ap.tags.push("DeathLink");

		trace("Slot Data Connected and Custom Songs Grabbed!");
	}

	function sendMessage(data:Array<JSONMessagePart>, item:Dynamic, receiving:Dynamic)
	{
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

				// Show popup notification that we sent an item
				archipelago.APItem.popup('Sent "$itemName" to $receivingPlayerName', "Item Sent!", false);
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
		archipelago.console.MainTab.addMessage(text);

	public function disconnectAP()
	{
		// Clean up temporary weeks when manually disconnecting
		cleanupTemporaryWeeks();

		_ap.disconnect_socket();
		_ap = null;
		if (APEntryState.ap != null)
		{
			APEntryState.ap = null;
		}
	}		public function getSongAndMod(songName:String):{song:String, ?mod:String}
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
			var nonSongs:Map<String, Int> = [];
			var nonSongsNames:Array<String> = [];
			var unlockedSongs:Array<{song:String, mod:String}> = [];
			var itemsToTrigger:Array<String> = [];

			APFreeplayManager.curMissing = [];

			for (songName in songs)
			{
				var itemName = info().get_item_name(songName.item);

				if (APItems.exists(itemName) && APItems.get(itemName) == songName.item)
				{
					nonSongs.set(itemName, songName.index);
					nonSongsNames.push(itemName);
					continue;
				}

				// Use the realName function to convert special keywords back to actual brackets
				itemName = APInfo.realName(itemName);

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
				itemsToTrigger: itemsToTrigger
			};
		}

		function applyProcessedItems(result:ProcessedItemsResult)
		{
			var songCopy:Array<{song:String, mod:String}> = APFreeplayManager.curUnlocked.copy();
			// Apply all unlocked songs
			for (song in result.unlockedSongs)
			{
				if (!isSync)
					ArchPopup.startPopupSong(song.song, 'archColor');
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

	private function onSocketDisconnected():Void
	{
		// Clean up temporary weeks when disconnecting
		cleanupTemporaryWeeks();
		FlxG.switchState(_disconnectSubstate);
	}		private function onCancel():Void
		{
			// Clean up temporary weeks when canceling/exiting AP mode
			cleanupTemporaryWeeks();

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

		// public function onRoomUpdate(roomUpdatePacket:RoomUpdatePacket)
		// {
		//     _ap.clientStatus = ClientStatus.PLAYING;
		// }
	}
