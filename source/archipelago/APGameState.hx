package archipelago;

import yutautil.AprilFools;
import haxe.DynamicAccess;
import yutautil.MemoryHelper;
import flixel.FlxState;
import archipelago.Client;
import archipelago.PacketTypes;
import archipelago.APDisconnectSubstate;
import archipelago.APCategoryState;
import backend.WeekData;
import haxe.ds.Option;
import openfl.text.TextFormat;
import lime.app.Future;
import lime.app.Promise;

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

		trace("slotData: " + Std.string(slotData));
		trace("Retained slotData: " + Std.string(_slotData));

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
		_ap.onSlotConnected.add(onSlotConnected);
		APPlayState.deathByLink = false;
	}

	function handleRetrievedPacket(retrievedPacket:haxe.DynamicAccess<Dynamic>):Void
	{
		trace("Retrieved packet: " + retrievedPacket);
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

					if (APItems.exists(_ap.get_item_name(hint.item, _ap.get_player_game(hint.receiving_player))))
					{
						trace("Hint is for an Item, or a song you don't have. Skipping.");
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

						if (APFreeplayManager.hintTable.exists(locationName))
						{
							APFreeplayManager.hintTable.set(locationName, APFreeplayManager.hintTable.get(locationName) + "\n" + message);
						}
						else
						{
							APFreeplayManager.hintTable.set(locationName, message);
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
				case "Ghost":
					archipelago.APItem.createItemByName("Ghost").fromTrapLink = true;
				case "My Turn! Trap":
					archipelago.APItem.createItemByName("My Turn! Trap").fromTrapLink = true;
				case "Paralyze Trap":
					archipelago.APItem.createItemByName("Paralyze Trap").fromTrapLink = true;
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

		private function onSocketDisconnected():Void
		{
			FlxG.switchState(_disconnectSubstate);
		}

		private function onCancel():Void
		{
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
