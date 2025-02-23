package archipelago;

import hx.concurrent.lock.RLock;
import archipelago.Definitions;
import archipelago.PacketTypes;
import haxe.DynamicAccess;
import haxe.Exception;
import haxe.exceptions.NotImplementedException;
import haxe.Timer;
import helder.Set;
import hx.ws.Types.MessageType;
import hx.ws.WebSocket;
import haxe.Json as TJson;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if (lime && !AP_NO_LIME)
import lime.app.Event;
#end

using StringTools;
using archipelago.Bitsets;

enum Status {
	GOAL;
	WAITING;
	READY;
	PLAYING;
	UNKNOWN;
}

/** The Archipelago client for Haxe. **/
class Client {
	/** Read-only. The URI the client is configured to connect to. **/
	public var uri(default, null):String;

	/** Read-only. The game the client is configured to connect for. **/
	public var game(default, null):String;

	/** Read-only. The UUID to identify the client. Deprecated, and likely to be removed in a future version. **/
	public var uuid(default, null):String;

	/** The websocket client. **/
	private var _ws:WebSocket;

	/** The local timestamp indicating when the last connection attempt was initiated. **/
	private var _lastSocketConnect:Float = 0;

	/** The amount of time, in seconds, to wait before attempting to reconnect. **/
	private var _socketReconnectInterval:Float = 1.5;

	/** The list of players in this multiworld. **/
	private var _players:Array<NetworkPlayer> = [];

	/** The dictionary to associate location IDs to names. **/
	private var _locations:Map<Int, String> = [];

	/** The dictionary to associate item IDs to names. **/
	private var _items:Map<Int, String> = [];

	/** The dictionary to associate location IDs to names specific to a game. **/
	private var _gameLocations:Map<String, Map<Int, String>> = [];

	/** The dictionary to associate item IDs to names specific to a game. **/
	private var _gameItems:Map<String, Map<Int, String>> = [];

	/** A copy of the Data Package used by the client. **/
	private var _dataPackage:DataPackageObject;
	private var _gotDataPackage = false;

	/** The current server state for this client. **/
	public var clientStatus(default, set):ClientStatus = ClientStatus.UNKNOWN;

	/** Read-only. The current connection state of the client. **/
	public var state(default, null):State = State.DISCONNECTED;

	/** Read-only. A unique string identifier for this multiworld's seed. **/
	public var seed(default, null):String = "";

	/** Read-only. The slot name the client is connected to. **/
	public var slot(default, null):String = "";

	/** Read-only. Whether the server is password-protected. **/
	public var hasPassword(default, null):Bool = false;

	/** Read-only. The team number the player belongs to. Currently unused. **/
	public var team(default, null):Int = -1;

	/** Read-only. The slot number the player is in. **/
	public var slotnr(default, null):Int = -1;

	/** Read-only. The number of hint points the player has. **/
	public var hintPoints(default, null):Int = -1;

	/** Read-only. The number of hint points it costs to request a hint. **/
	public var hintCostPoints(get, null):Int;

	/** Read-only. The percentage of total hint points it costs to request a hint. **/
	public var hintCostPercent(default, null):Int = -1;

	/** Read-only. The total number of location checks in this world. **/
	public var locationCount(default, null):Int = -1;

	/** Read-only. Whether the data package is currently accurate to server data. **/
	public var dataPackageValid(default, null):Bool = false;

	/** Read-only. The UNIX time, in seconds, when the connection was established. **/
	public var serverConnectTime(default, null):Float = 0;

	/** Read-only. A local timestamp representing when the connection was established. **/
	public var localConnectTime(default, null):Float = 0;

	/** Read-only. The version of the AP server. **/
	public var serverVersion(default, null):NetworkVersion;

	/** Read-only. The list of checked location ids. **/
	public var checkedLocations(get, never):Array<Int>;

	/** Read-only. The list of unchecked location ids. **/
	public var missingLocations(get, never):Array<Int>;

	/** Read-only. The number of times connection has been attempted. Will be reset to 0 when connected. **/
	public var connectAttempts(default, null) = 0;

	/** Read-only. The current UNIX time for the server, in seconds, extrapolated based on `localConnectTime`. **/
	public var server_time(get, never):Float;

	/** The current client tags. **/
	public var tags(get, set):Array<String>;

	/** Information about player slots in this multiworld. **/
	private var _slotInfo:Map<Int, NetworkSlot>;

	/** Internal copy of client tags. **/
	private var _tags:Array<String> = [];

	/** The set of location ids that have been checked. **/
	private var _checkedLocations = new Set<Int>();

	/** The set of location ids that have not been checked. **/
	private var _missingLocations = new Set<Int>();

	/** The list of packets received since the last call to `poll()`. **/
	private var _recvQueue:Array<IncomingPacket> = [];

	/** Locks access to `_recvQueue` to the thread currently accessing it. **/
	private var _recvLock = new RLock();

	/** The list of packets queued to be sent upon the next call to `poll()`. **/
	private var _sendQueue:Array<OutgoingPacket> = [];

	/** Locks access to `_sendQueue` to the thread currently accessing it. **/
	private var _sendLock = new RLock();

	/** The list of checks and scouts which are queued to be sent when the connection is re-established. **/
	private var _offlineQueue:Array<OfflineQueueType> = [];

	/** Locks access to `_offlineQueue` to the thread currently accessing it. **/
	private var _offlineLock = new RLock();

	/** Whether the client has tried to connect to a WSS server. **/
	private var _hasTriedWSS = false;

	/** Whether the client has at any point succeeded in connecting to a slot. **/
	private var _hasBeenConnected = false;

	public var publicPacket:Array<IncomingPacket>;

	#if (lime && !AP_NO_LIME)
	/** Called when the websocket connects to the server. **/
	public var onSocketConnected(default, null) = new Event<Void->Void>();

	/**
		Called when the websocket reports an error.
		@param error The reported error message.
	**/
	public var onSocketError(default, null) = new Event<String->Void>();

	/** Called when the websocket disconnects from the server. **/
	public var onSocketDisconnected(default, null) = new Event<Void->Void>();

	/**
		Called when the client connects to the slot.
		@param slot_data The custom data sent from the server pertaining to the game, if any.
	**/
	public var onSlotConnected(default, null) = new Event<Dynamic->Void>();

	/**
		Called when an ItemsReceived packet is received.
		@param errors The error code(s) received from the server.
	**/
	public var onSlotRefused(default, null) = new Event<Array<String>->Void>();

	/** Called when the websocket disconnects from the slot. **/
	public var onSlotDisconnected(default, null) = new Event<Void->Void>();

	/** Called when a RoomInfo packet is received. **/
	public var onRoomInfo(default, null) = new Event<Void->Void>();

	/**
		Called when an ItemsReceived packet is received.
		@param items The list of items received.
	**/
	public var onItemsReceived(default, null) = new Event<Array<NetworkItem>->Void>();

	/**
		Called when a LocationInfo packet is received.
		@param items The list of items scouted.
	**/
	public var onLocationInfo(default, null) = new Event<Array<NetworkItem>->Void>();

	/**
		Called when the Data Package has changed.
		@param data The new content of the Data Package.
	**/
	public var onDataPackageChanged(default, null) = new Event<DataPackageObject->Void>();

	/**
		Called when a Print packet is received.
		@param text The text received.
	**/
	public var onPrint(default, null) = new Event<String->Void>();

	/**
		Called when a PrintJSON packet is received.
		@param data The content of the message, in `JSONMessagePart`s.
		@param item The item in question, if any.
		@param receiving The ID of the receiving player, if any.
	**/
	public var onPrintJSON(default, null) = new Event<(Array<JSONMessagePart>, Null<NetworkItem>, Null<Int>) -> Void>();

	/**
		Called when a Bounced packet is received.
		@param data The data contained in the packet.
	**/
	public var onBounced(default, null) = new Event<Dynamic->Void>();

	/**
		Called when locations have been checked.
		@param ids The ID numbers for the locations checked.
	**/
	public var onLocationChecked(default, null) = new Event<Array<Int>->Void>();

	/**
		Called when data has been retrieved from a Get call.
		@param keys A key-value collection containing all the values for the keys requested in the Get package.
	**/
	public var onRetrieved(default, null) = new Event<DynamicAccess<Dynamic>->Void>();

	/**
		Called when a Set operation has been processed, and a reply was requested.
		@param key The key that was updated.
		@param value The new value for the key.
		@param original_value The value the key had before it was updated.
	**/
	public var onSetReply(default, null) = new Event<(String, Dynamic, Dynamic) -> Void>();

	/**
		Called when an error occurs.
		@param funcName The function where the error was caught.
		@param data The error data.
	**/
	public var onThrow(default, null) = new Event<(String, Dynamic) -> Void>();

	inline function _hOnSocketConnected()
		return onSocketConnected.dispatch();

	inline function _hOnSocketError(error)
		return onSocketError.dispatch(error);

	inline function _hOnSocketDisconnected()
		return onSocketDisconnected.dispatch();

	inline function _hOnSlotConnected(slotData)
		return onSlotConnected.dispatch(slotData);

	inline function _hOnSlotRefused(errors)
		return onSlotRefused.dispatch(errors);

	inline function _hOnSlotDisconnected()
		return onSlotDisconnected.dispatch();

	inline function _hOnRoomInfo()
		return onRoomInfo.dispatch();

	inline function _hOnItemsReceived(items)
		return onItemsReceived.dispatch(items);

	inline function _hOnLocationInfo(items)
		return onLocationInfo.dispatch(items);

	inline function _hOnDataPackageChanged(data)
		return onDataPackageChanged.dispatch(data);

	inline function _hOnPrint(text)
		return onPrint.dispatch(text);

	inline function _hOnPrintJSON(data, item, receiving)
		return onPrintJSON.dispatch(data, item, receiving);

	inline function _hOnBounced(data)
		return onBounced.dispatch(data);

	inline function _hOnLocationChecked(data)
		return onLocationChecked.dispatch(data);

	inline function _hOnRetrieved(keys)
		return onRetrieved.dispatch(keys);

	inline function _hOnSetReply(key, value, original_value)
		return onSetReply.dispatch(key, value, original_value);

	inline function _hOnThrow(funcName, data:Dynamic)
		return onThrow.dispatch(funcName, data);
	#else

	/** Write-only. Called when the websocket connects to the server. **/
	public var _hOnSocketConnected(null, default):Void->Void = () -> {};

	/**
		Write-only. Called when the websocket reports an error.
		@param error The reported error message.
	**/
	public var _hOnSocketError(null, default):String->Void = (_) -> {};

	/** Write-only. Called when the websocket disconnects from the server. **/
	public var _hOnSocketDisconnected(null, default):Void->Void = () -> {};

	/**
		Write-only. Called when the client connects to the slot.
		@param slot_data The custom data sent from the server pertaining to the game, if any.
	**/
	dynamic public var _hOnSlotConnected(null, default):Dynamic->Void = (_) -> {};

	/** Write-only. Called if slot authentication fails. **/
	public var _hOnSlotRefused(null, default):Array<String>->Void = (_) -> {};

	/** Write-only. Called when the client disconnects from the slot. **/
	public var _hOnSlotDisconnected(null, default):Void->Void = () -> {};

	/** Write-only. Called when a RoomInfo packet is received. **/
	public dynamic var _hOnRoomInfo(null, default):Void->Void = () -> {};

	/** Write-only. Called when an ItemsReceived packet is received. **/
	public var _hOnItemsReceived(null, default):Array<NetworkItem>->Void = (_) -> {};

	/** Write-only. Called when a LocationInfo packet is received. **/
	public var _hOnLocationInfo(null, default):Array<NetworkItem>->Void = (_) -> {};

	/**
		Write-only. Called when the Data Package has changed.
		@param data The new content of the Data Package.
	**/
	public var _hOnDataPackageChanged(null, default):DataPackageObject->Void = (_) -> {};

	/**
		Write-only. Called when a Print packet is received.
		@param text The text received.
	**/
	public var _hOnPrint(null, default):String->Void = (_) -> {};

	/**
		Write-only. Called when a PrintJSON packet is received.
		@param data The content of the message, in `JSONMessagePart`s.
		@param item The item in question, if any.
		@param receiving The ID of the receiving player, if any.
	**/
	public var _hOnPrintJSON(null, default):(Array<JSONMessagePart>, Null<NetworkItem>, Null<Int>) -> Void = (_, _, _) -> {};

	/**
		Write-only. Called when a Bounced packet is received.
		@param data The data contained in the packet.
	**/
	public var _hOnBounced(null, default):Dynamic->Void = (_) -> {};

	/**
		Write-only. Called when locations have been checked.
		@param ids The ID numbers for the locations checked.
	**/
	public var _hOnLocationChecked(null, default):Array<Int>->Void = (_) -> {};

	/**
		Write-only. Called when data has been retrieved from a Get call.
		@param keys A key-value collection containing all the values for the keys requested in the Get package.
	**/
	public var _hOnRetrieved(null, default):DynamicAccess<Dynamic>->Void = (_) -> {};

	/**
		Write-only. Called when a Set operation has been processed, and a reply was requested.
		@param key The key that was updated.
		@param value The new value for the key.
		@param original_value The value the key had before it was updated.
	**/
	public var _hOnSetReply(null, default):(String, Dynamic, Dynamic) -> Void = (_, _, _) -> {};

	/**
		Write-only. Called when an error occurs.
		@param funcName The function where the error was caught.
		@param data The error data.
	**/
	public var _hOnThrow(null, default):(String, Dynamic) -> Void = (_, _) -> {};
	#end

	/**
		Creates a new instance of the Archipelago client.
		@param uuid The unique ID for this client. Deprecated, and likely to be removed in a later version.
		@param game The game to connect to.
		@param uri The server to connect to, including host name and port.
	**/
	public function new(uuid:String, game:String, uri:String = "ws://localhost:38281") {
		if (uri.length > 0) {
			var p = uri.indexOf("://");
			if (p < 0) {
				#if AP_PREFER_UNENCRYPTED
				this.uri = "ws://" + uri;
				p = 2;
				#else
				this.uri = "wss://" + uri;
				p = 3;
				#end
			} else
				this.uri = uri;

			var pColon = this.uri.indexOf(":", p + 3); // FIXME: [upstream] this fails for IPv6 addresses
			var pSlash = this.uri.indexOf("/", p + 3);
			if (pColon < 0 || (pSlash >= 0 && pColon > pSlash)) {
				var tmp = this.uri.substr(0, pSlash) + ":38281";
				if (pSlash >= 0)
					tmp += this.uri.substr(pSlash);
				this.uri = tmp;
			}
		}

		trace("Creating new AP client to " + uri);

		this.uuid = uuid;
		this.game = game;
		_dataPackage = {games: new DynamicAccess<GameData>()};
		connect_socket();
	}

	public function set_clientStatus(status:ClientStatus):ClientStatus {
		if (state == State.SLOT_CONNECTED)
			InternalSend(OutgoingPacket.StatusUpdate(status));
		trace("Client status set to " + status);
		return clientStatus = status;
	}

	public function set_goal() {
		if (state == State.SLOT_CONNECTED)
			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.GOAL));
			// InternalSend(OutgoingPacket.StatusUpdate(30));
	}



	// public function setStatusByEnum(status:Status) {
	// 	switch (status) {
	// 		case Status.GOAL:
	// 			set_goal();
	// 		case Status.WAITING:
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.WAITING));
	// 		case Status.READY:
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.READY));
	// 		case Status.FINISHED:
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.FINISHED));
	// 		case Status.DISCONNECTED:
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.DISCONNECTED));
	// 		case Status.UNKNOWN:
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.UNKNOWN));
	// 	}
	// } 

	// public function setStatusByString(status:String) {
	// 	switch (status) {
	// 		case "GOAL":
	// 			set_goal();
	// 		// case "WAITING":
	// 		// 	InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.WAITING));
	// 		case "READY":
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.READY));
	// 		case "PLAYING":
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.PLAYING));
	// 		// case "FINISHED":
	// 		// 	InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.FINISHED));
	// 		// case "DISCONNECTED":
	// 		// 	InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.DISCONNECTED));
	// 		case "UNKNOWN":
	// 			InternalSend(OutgoingPacket.StatusUpdate(ClientStatus.UNKNOWN));
	// 	}
	// }

	public function sendDeathLink(COD:String) {
		if (state == State.SLOT_CONNECTED && !APPlayState.deathByLink)
			InternalSend(OutgoingPacket.Bounce(null,null,['DeathLink'], {time: Timer.stamp(), cause: slot + ": " + COD, source: slot}));
	}


	public function toggleDeathLink(enable:Bool) {
		if (enable) {
			set_tags(['AP', 'Testing', 'DeathLink']);
		} else {
			set_tags(['AP', 'Testing']);
		}
	}

	public inline function get_server_time()
		return serverConnectTime + (Timer.stamp() - localConnectTime);

	var currentTags:Array<String> = [];

	inline function get_tags()
		return currentTags;

	public function set_tags(tags) {
		currentTags = tags;
		ConnectUpdate(null, tags);
		return tags;
	}

	public function update_tags(tags:Array<String>) {
		set_tags(tags);
	}

	public function add_tag(tag:String) {
		if (currentTags.indexOf(tag) == -1) {
			var t = currentTags.copy();
			t.push(tag);
			set_tags(t);
		}
	}

	public function remove_tag(tag:String) {
		var i = currentTags.indexOf(tag);
		if (i >= 0) {
			var t = currentTags.copy();
			t.splice(i, 1);
			set_tags(t);
		}
	}

	public function add_tags(tags:Array<String>) {
		for (tag in tags)
			add_tag(tag);
	}

	function get_hintCostPoints() {
		if (hintCostPercent <= 0)
			return hintCostPercent;
		if (locationCount <= 0)
			return locationCount;
		return Math.floor(Math.max(1, hintCostPercent * locationCount / 100));
	}

	inline function get_missingLocations()
		return _missingLocations.toArray();

	inline function get_checkedLocations()
		return _checkedLocations.toArray();

	/**
		Sets the Data Package's data.
		@param data The data to add to the Data Package.
	**/
	public function set_data_package(data:Dynamic) {
		// TODO: APDataPackageStore??
		trace("Setting data package");
		if (!dataPackageValid && data.games.toArray().length > 0) {
			_dataPackage = data;
			for (game => gamedata in _dataPackage.games) {
				_dataPackage.games[game] = gamedata;
				_gameItems.set(game, []);
				_gameLocations.set(game, []);
				for (itemName => itemId in gamedata.item_name_to_id) {
					_items[itemId] = itemName;
					_gameItems[game][itemId] = itemName;
				}
				for (locationName => locationId in gamedata.location_name_to_id) {
					_locations[locationId] = locationName;
					_gameLocations[game][locationId] = locationName;
				}
			}
		} else trace("Data package failed...");
		trace("Data package set");
		//trace(_dataPackage);
	}

	#if sys
	/**
		Loads the Data Package from a file. Only available on `sys` platforms.
		@param path The file to load.
		@return Whether the operation was successful.
	**/
	public function set_data_package_from_file(path:String) {
		if (!FileSystem.exists(path))
			return false;
		set_data_package(TJson.parse(File.getContent(path)));
		return true;
	}

	/**
		Saves the Data Package to a file. Only available on `sys` platforms.
		@param path The file to save to.
		@return Whether the operation was successful.
	**/
	public function save_data_package(path:String) {
		try {
			var f = File.write(path, true);
			f.writeString(TJson.stringify(_dataPackage));
			f.close();
		} catch (_) {
			return false;
		}
		return true;
	}
	#else

	/** Stub. Not available on this platform. **/
	public function set_data_package_from_file(path:String)
		return false;

	/** Stub. Not available on this platform. **/
	public function save_data_package(path:String)
		return false;
	#end

	/**
		Resolves a slot number into that player's current alias.
		@param slot The slot to look up.
		@return The name attached to the given slot number, or "Unknown" if no such slot exists. For a slot number of 0, "Server" is returned.
	**/
	public function get_player_alias(slot:Int):String {
		if (slot == 0)
			return "Server";
		for (player in _players)
			if (player.team == team && player.slot == slot)
				return player.alias;
		return "Unknown";
	}

	/**
		Resolves a slot number into that player's game.
		@param player The slot to look up.
		@return The game attached to the given slot number, or a blank string if no such slot exists. For a slot number of 0, "Archipelago" is returned.
	**/
	public function get_player_game(player:Int):String {
		if (player == 0)
			return "Archipelago";
		if (_slotInfo.exists(player))
			return _slotInfo[player].game;
		return "";
	}

	/**
		Resolves a location ID into the name of that location.
		@param code The location ID to look up.
		@param game The game to which the location belongs. Defaults to a blank string, which will attempt to devine a location name which may be incorrect if there is an ID collision.
		@return The name of the location attached to the given ID, or "Unknown" if it was not found.
	**/
	public function get_location_name(code:Int, game = "Friday Night Funkin"):String {
		if (game.length == 0) {
			if (_locations.exists(code))
				return _locations.get(code);
		} else if (_gameLocations.exists(game) && _gameLocations[game].exists(code))
			return _gameLocations[game][code];
		return "Unknown";
	}

	/**
		Resolves a location name into the ID of that location.
		@deprecated Usage is not recommended.
		@param name The name of the location to look up.
		@param game The game to which the location belongs. Defaults to a blank string, which will attempt to devine a location ID which may be incorrect if there is a name collision.
		@return The ID associated with the location name, or `null` if it was not found.
	**/
	public function get_location_id(name:String, game = "Friday Night Funkin"):Null<Int> {
		if (game.length == 0)
			game = this.game;
		if (_dataPackage.games.exists(game) && _dataPackage.games[game].location_name_to_id.exists(name))
			return _dataPackage.games[game].location_name_to_id[name];
		return null;
	}

	/**
		Resolves an item ID into the name of that item.
		@param code The item ID to look up.
		@param game The game to which the item belongs. Defaults to a blank string, which will attempt to devine an item name which may be incorrect if there is an ID collision.
		@return The name of the item attached to the given ID, or "Unknown" if it was not found.
	**/
	public function get_item_name(code:Int, game = "Friday Night Funkin"):String {
		if (game.length == 0) {
			if (_items.exists(code))
				return _items.get(code);
		} else if (_gameItems.exists(game) && _gameItems[game].exists(code))
			return _gameItems[game][code];
		return "Unknown";
	}

	/**
		Resolves an item name into the ID of that item.
		@deprecated Usage is not recommended.
		@param name The name of the item to look up.
		@param game The game to which the item belongs. Defaults to a blank string, which will attempt to devine an item ID which may be incorrect if there is a name collision.
		@return The ID associated with the item name, or `null` if it was not found.
	**/
	public function get_item_id(name:String, ?game = "Friday Night Funkin"):Null<Int> {
		if (game.length == 0)
			game = this.game;
		if (_dataPackage.games.exists(game) && _dataPackage.games[game].item_name_to_id.exists(name))
			return _dataPackage.games[game].item_name_to_id[name];
		return null;
	}

	/**
		Renders `JSONMessagePart`s into a more usable format.
		@param msg The `JSONMessagePart`s to render.
		@param fmt The format to render into.
		@return The rendered result.
		@throws NotImplementedException Thrown if HTML rendering was requested.
	**/
	public function render_json(msg:Array<JSONMessagePart>, fmt:RenderFormat = RenderFormat.TEXT) {
		if (fmt == RenderFormat.HTML)
			throw new NotImplementedException("ap.Client.render_json(..., HTML) not yet implemented [upstream]");

		var out:String = "";
		var colorIsSet:Bool = false;
		for (node in msg) {
			var color:String = null;
			var text:String = "";
			if (fmt != RenderFormat.TEXT)
				color = node.color;
			var id:Null<Int> = Std.parseInt(node.text);
			if (id == null)
				id = 0;
			switch (node.type) {
				case JTYPE_PLAYER_ID:
					if (color == null)
						color = id == slotnr ? "magenta" : "yellow";
					text = get_player_alias(id);
				case JTYPE_ITEM_ID:
					if (color == null) {
						if (node.flags.isAdvancement)
							color = "plum";
						else if (node.flags.isNeverExclude)
							color = "slateblue";
						else if (node.flags.isTrap)
							color = "salmon";
						else
							color = "cyan";
					}
					text = get_item_name(id, get_player_game(node.player));
				case JTYPE_LOCATION_ID:
					if (color == null)
						color = "blue";
					text = get_location_name(id, get_player_game(node.player));
				default:
					text = node.text;
			}
			switch (fmt) {
				case HTML:
				// not implemented yet
				case ANSI:
					if (color == null && colorIsSet) {
						out += color2ansi(""); // reset colour
						colorIsSet = false;
					} else if (color != null) {
						out += color2ansi(color);
						colorIsSet = true;
					}
					out += deansify(text);
				case TEXT:
					out += text;
			}
		}
		if (fmt == RenderFormat.ANSI && colorIsSet)
			out += color2ansi("");
		return out;
	}

	/**
		Sends a packet to the server.
		@param packet The packet to send.
		@return Whether the operation was successful.
	**/
	private inline function InternalSend(packet:OutgoingPacket):Bool {
		if (packet == null) {
			_hOnThrow("InternalSend", new Exception("Something tried to queue a null packet"));
			return false;
		}

		trace("> " + packet);
		if (!Reflect.hasField(packet, "cmd"))
			packet = parseOutgoingPacketSimplified(packet);

		_sendLock.execute(() -> _sendQueue.push(packet));

		return true;
	}

	/**
	 * Parses an outgoing packet and returns the enum type with its parameters.
	 * @param packet The outgoing packet as a Dynamic object.
	 * @return The parsed OutgoingPacket enum type.
	 **/
	private function parseOutgoingPacketSimplified(packet:Dynamic):Dynamic {
		var obj:Dynamic = {};
		switch (packet) {
			case OutgoingPacket.Connect(password, game, name, uuid, version, items_handling, tags, slot_data):
				obj.password = password;
				obj.game = game;
				obj.name = name;
				obj.uuid = uuid;
				obj.version = version;
				obj.items_handling = items_handling;
				obj.tags = tags;
				obj.slot_data = slot_data;
				obj.cmd = "Connect";
			case OutgoingPacket.ConnectUpdate(items_handling, tags):
				obj.items_handling = items_handling;
				obj.tags = tags;
				obj.cmd = "ConnectUpdate";
			case OutgoingPacket.Sync:
				obj.cmd = "Sync";
			case OutgoingPacket.LocationChecks(locations):
				obj.locations = locations;
				obj.cmd = "LocationChecks";
			case OutgoingPacket.LocationScouts(locations, create_as_hint):
				obj.locations = locations;
				obj.create_as_hint = create_as_hint;
				obj.cmd = "LocationScouts";
			case OutgoingPacket.StatusUpdate(status):
				obj.status = status;
				obj.cmd = "StatusUpdate";
			case OutgoingPacket.Say(text):
				obj.text = text;
				obj.cmd = "Say";
			case OutgoingPacket.GetDataPackage(games):
				obj.games = games;
				obj.cmd = "GetDataPackage";
			case OutgoingPacket.Bounce(games, slots, tags, data):
				obj.games = games != null ? games : [];
				obj.slots = slots != null ? slots : [];
				obj.tags = tags != null ? tags : [];
				obj.data = data != null ? data : {};
				obj.cmd = "Bounce";
			case OutgoingPacket.Get(keys):
				obj.keys = keys;
				obj.cmd = "Get";
			case OutgoingPacket.Set(key, dflt, want_reply, operations):
				obj.key = key;
				obj.dflt = dflt;
				obj.want_reply = want_reply;
				obj.operations = operations;
				obj.cmd = "Set";
			case OutgoingPacket.SetNotify(keys):
				obj.keys = keys;
				obj.cmd = "SetNotify";
			default:
				throw new Exception("Unknown outgoing packet type");
		}
		return obj;
	}

	/**
		Sends a LocationChecks packet to the server.
		@param location The locations to check.
		@return Whether the operation was successful.
	**/
	public function LocationChecks(locations:Array<Int>):Bool {
		if (state == State.SLOT_CONNECTED)
			return InternalSend(OutgoingPacket.LocationChecks(locations));
		else
			_offlineLock.execute(() -> {
				for (i in locations)
					_offlineQueue.push(Check(i));
			});
		for (loc in locations) {
			_checkedLocations.add(loc);
			_missingLocations.remove(loc);
		}
		return true;
	}

	/**
		Sends a LocationScouts packet to the server.
		@param location The locations to scout.
		@return Whether the operation was successful.
	**/
	public function LocationScouts(locations:Array<Int>, create_as_hint = 0):Bool {
		if (state == State.SLOT_CONNECTED)
			return InternalSend(OutgoingPacket.LocationScouts(locations, create_as_hint));
		else
			_offlineLock.execute(() -> {
				for (i in locations)
					_offlineQueue.push(Scout(i, create_as_hint));
			});
		return true;
	}

	/**
		Connects to a slot in the multiworld.
		@param name The slot name.
		@param password The password for this multiworld, if any.
		@param items_handling The flags regarding how item processing will be handled.
		@param tags The capability tags for this session. Defaults to `[]`.
		@param ver The minimum version number for this client. Currently defaults to 0.4.6; later versions may change this.
	**/
	public function ConnectSlot(name:String, password:Null<String>, items_handling:Int, ?tags:Array<String>, ?ver:NetworkVersion):Bool {
		if (state < State.SOCKET_CONNECTED)
			return false;

		if (tags == null)
			_tags = [];
		if (ver == null)
			ver = {
				major: 0,
				minor: 4,
				build: 6,
			};

		// HACK: because "class" is getting dropped every time I try to process this with tink
		var sendVer = new DynamicAccess<Dynamic>();
		sendVer.set("major", ver.major);
		sendVer.set("minor", ver.minor);
		sendVer.set("build", ver.build);
		sendVer.set("class", "Version");

		slot = name;
		trace("Connecting to slot...");
		return InternalSend(OutgoingPacket.Connect(password, game, name, uuid, sendVer, items_handling, tags, true));
	}

	/**
		Updates the connection with new item handling or tags.
		@param items_handling The flags regarding how item processing will be handled, if changed.
		@param tags The capability tags for this session, if changed.
	**/
	public function ConnectUpdate(?items_handling:Int, ?tags:Array<String>):Bool {
		if (items_handling == null && tags == null)
			return false;

		if (tags != null)
			_tags = tags;
		return InternalSend(OutgoingPacket.ConnectUpdate(items_handling, tags));
	}

	/**
		Synchronizes check progress with the multiworld server.
		@return Whether the operation was successful.
	**/
	public function Sync():Bool {
		if (state < State.SLOT_CONNECTED)
			return false;
		return InternalSend(OutgoingPacket.Sync);
	}

	/**
		Requests data package information from the multiworld server.
		@param include Optional. The games to include in the Data Package request. If not specified, will retrieve the complete Data Package.
		@return Whether the operation was successful.
	**/
	public function GetDataPackage(?games:Array<String>):Bool {
		if (state < State.SLOT_CONNECTED)
			return false;
		return InternalSend(OutgoingPacket.GetDataPackage(games));
	}

	/**
		Sends a Bounce packet to the multiworld server.
		@param data Arbitrary data to include in the Bounce packet.
		@param games Optional. The games to target for this packet.
		@param slots Optional. The slot numbers to target for this packet.
		@param tags Optional. The tags to target for this packet.
		@return Whether the operation was successful.
	**/
	public function Bounce(data:Dynamic, ?games:Array<String>, ?slots:Array<Int>, ?tags:Array<String>):Bool {
		if (state < State.ROOM_INFO)
			return false;
		return InternalSend(OutgoingPacket.Bounce(games, slots, tags, data));
	}

	/**
		Sends a text message to the multiworld server.
		@param text The text to send.
		@return Whether the operation was successful.
	**/
	public function Say(text:String):Bool {
		if (state < State.ROOM_INFO)
			return false;
		return InternalSend(OutgoingPacket.Say(text));
	}

	public function Get(keys:Array<String>) {
		if (state < State.SLOT_CONNECTED)
			return false;
		return InternalSend(OutgoingPacket.Get(keys));
	}

	public function Set(key:String, dflt:Dynamic, want_reply:Bool, operations:Array<DataStorageOperation>) {
		if (state < State.SLOT_CONNECTED)
			return false;
		return InternalSend(OutgoingPacket.Set(key, dflt, want_reply, operations));
	}

	public function SetNotify(keys:Array<String>) {
		if (state < State.SLOT_CONNECTED)
			return false;
		return InternalSend(OutgoingPacket.SetNotify(keys));
	}

	/** Polls the client for new packets. **/
	public function poll() {
		if (_ws != null && state == State.DISCONNECTED) {
			_ws.close();
			_ws = null;
		}
		if (_ws != null)
			process_queue();


		// var needDataPackage = if (_gotDataPackage) false else true;
		// try {
		// 	if (_ws != null && (_dataPackage.games[game] == null || _dataPackage == null || _dataPackage.games == null || _dataPackage.games[game].location_name_to_id == null || _dataPackage.games[game].item_name_to_id == null)) {
		// 		for (packets in _sendQueue) {
		// 			if (Reflect.hasField(packets, "cmd") && Reflect.field(packets, "cmd") == "GetDataPackage") {
		// 				needDataPackage = false;
		// 				break;
		// 			}
		// 		}
		// 		if (needDataPackage) {
		// 			GetDataPackage(
		// 				game == "Friday Night Funkin" ? ["Friday Night Funkin"] : null
		// 			);
		// 		}
		// 	} else {
		// 		needDataPackage = false;
		// 	}
		// } catch (e:Dynamic) {
		// 	trace("Error in poll: " + e + " while trying to get data package");
		// 	// _hOnThrow("poll", e);
		// }


		if (state < State.SOCKET_CONNECTED) {
			var t = Timer.stamp();
			if (t - _lastSocketConnect > _socketReconnectInterval) {
				if (state != State.DISCONNECTED) {
					_hOnThrow("poll", new Exception("Connect timed out"));
					trace("Connect timed out. Retrying.");
				} else
					trace("Reconnecting to server");
				connect_socket();
			}
		}
	}

	/**
	 * Parses an incoming packet, removes the cmd value, and returns the enum type with its parameters.
	 * @param packet The incoming packet as a Dynamic object.
	 * @return The parsed IncomingPacket enum type.
	 **/
	private function parseIncomingPacket(packet:Dynamic):IncomingPacket {

		trace("Advanced processing...");
		if (Reflect.hasField(packet, "cmd")) {
			Reflect.deleteField(packet, "cmd");
		}

		// Check fields to determine the packet type
		if (Reflect.hasField(packet, "version") && Reflect.hasField(packet, "tags") && Reflect.hasField(packet, "password")) {
			return IncomingPacket.RoomInfo(
				packet.version,
				packet.generator_version,
				packet.tags,
				packet.password,
				packet.permissions,
				packet.hint_cost,
				packet.location_check_points,
				packet.games,
				packet.datapackage_versions,
				packet.datapackage_checksums,
				packet.seed_name,
				packet.time
			);
		} else if (Reflect.hasField(packet, "errors")) {
			return IncomingPacket.ConnectionRefused(packet.errors);
		} else if (Reflect.hasField(packet, "team") && Reflect.hasField(packet, "slot") && Reflect.hasField(packet, "players")) {
			return IncomingPacket.Connected(
				packet.team,
				packet.slot,
				packet.players,
				packet.missing_locations,
				packet.checked_locations,
				packet.slot_data,
				packet.slot_info,
				packet.hint_points
			);
		} else if (Reflect.hasField(packet, "index") && Reflect.hasField(packet, "items")) {
			return IncomingPacket.ReceivedItems(packet.index, packet.items);
		} else if (Reflect.hasField(packet, "locations")) {
			return IncomingPacket.LocationInfo(packet.locations);
		} else if (Reflect.hasField(packet, "players") || Reflect.hasField(packet, "checked_locations") || Reflect.hasField(packet, "hint_points")) {
			return IncomingPacket.RoomUpdate(
				packet.version,
				packet.generator_version,
				packet.tags,
				packet.password,
				packet.permissions,
				packet.hint_cost,
				packet.location_check_points,
				packet.games,
				packet.datapackage_versions,
				packet.datapackage_checksums,
				packet.seed_name,
				packet.time,
				packet.players,
				packet.checked_locations,
				packet.hint_points
			);
		} else if (Reflect.hasField(packet, "data")) {
			return IncomingPacket.DataPackage(packet.data);
		} else if (Reflect.hasField(packet, "text")) {
			return IncomingPacket.Print(packet.text);
		} else if (Reflect.hasField(packet, "data") && Reflect.hasField(packet, "type")) {
			return IncomingPacket.PrintJSON(
				packet.data,
				packet.type,
				packet.receiving,
				packet.item,
				packet.found,
				packet.team,
				packet.slot,
				packet.message,
				packet.tags,
				packet.countdown
			);
		} else if (Reflect.hasField(packet, "games") || Reflect.hasField(packet, "slots") || Reflect.hasField(packet, "tags")) {
			return IncomingPacket.Bounced(
				packet.games,
				packet.slots,
				packet.tags,
				packet.data
			);
		} else if (Reflect.hasField(packet, "keys")) {
			return IncomingPacket.Retrieved(packet.keys);
		} else if (Reflect.hasField(packet, "key") && Reflect.hasField(packet, "value")) {
			return IncomingPacket.SetReply(
				packet.key,
				packet.value,
				packet.original_value
			);
		} else if (Reflect.hasField(packet, "type") && Reflect.hasField(packet, "text")) {
			return IncomingPacket.InvalidPacket(
				packet.type,
				packet.original_cmd,
				packet.text
			);
		} else {
			return IncomingPacket.Unknown(packet.cmd);
		}
	}

	private function parseIncomingPacketSimplified(packet:Dynamic):IncomingPacket {
		trace("Lazy Processing...");
		if (Reflect.hasField(packet, "cmd")) {
			var cmd = Reflect.field(packet, "cmd");
			switch (cmd) {
				case "RoomInfo":
					return IncomingPacket.RoomInfo(
						packet.version,
						packet.generator_version,
						packet.tags,
						packet.password,
						packet.permissions,
						packet.hint_cost,
						packet.location_check_points,
						packet.games,
						packet.datapackage_versions,
						packet.datapackage_checksums,
						packet.seed_name,
						packet.time
					);
				case "ConnectionRefused":
					return IncomingPacket.ConnectionRefused(packet.errors);
				case "Connected":
					return IncomingPacket.Connected(
						packet.team,
						packet.slot,
						packet.players,
						packet.missing_locations,
						packet.checked_locations,
						packet.slot_data,
						packet.slot_info,
						packet.hint_points
					);
				case "ReceivedItems":
					return IncomingPacket.ReceivedItems(packet.index, packet.items);
				case "LocationInfo":
					return IncomingPacket.LocationInfo(packet.locations);
				case "RoomUpdate":
					return IncomingPacket.RoomUpdate(
						packet.version,
						packet.generator_version,
						packet.tags,
						packet.password,
						packet.permissions,
						packet.hint_cost,
						packet.location_check_points,
						packet.games,
						packet.datapackage_versions,
						packet.datapackage_checksums,
						packet.seed_name,
						packet.time,
						packet.players,
						packet.checked_locations,
						packet.hint_points
					);
				case "DataPackage":
					return IncomingPacket.DataPackage(packet.data);
				case "Print":
					return IncomingPacket.Print(packet.text);
				case "PrintJSON":
					return IncomingPacket.PrintJSON(
						packet.data,
						packet.type,
						packet.receiving,
						packet.item,
						packet.found,
						packet.team,
						packet.slot,
						packet.message,
						packet.tags,
						packet.countdown
					);
				case "Bounced":
					_hOnBounced(packet.data);	
					return IncomingPacket.Bounced(
						packet.games,
						packet.slots,
						packet.tags,
						packet.data
					);
				case "Retrieved":
					return IncomingPacket.Retrieved(packet.keys);
				case "SetReply":
					return IncomingPacket.SetReply(
						packet.key,
						packet.value,
						packet.original_value
					);
				default:
					return IncomingPacket.Unknown(cmd);
			}
		} else {
			return IncomingPacket.Unknown(null);
		}
	}

	private function tryParseIncomingPacket(packet:Dynamic):IncomingPacket {
		try {
			return parseIncomingPacketSimplified(packet);
		} catch (e:Dynamic) {
			// _hOnThrow("tryParseIncomingPacket", e);
			return IncomingPacket.InvalidPacket(null, null, e.toString());
		}
	}

	/** Processes the packets currently in the queue. **/
	private function process_queue() {
		if (_sendQueue.length > 0) {
			_sendLock.execute(() -> {
				trace('Sending ${_sendQueue.length} queued packet(s)');
				_ws.send(TJson.stringify(_sendQueue));
				_sendQueue = [];
			});
		}

		_recvLock.acquire();
		var grabQueue = _recvQueue.slice(0);
		_recvQueue = [];
		_recvLock.release();

		if (grabQueue.length > 0)
			trace('Processing ${grabQueue.length} received packet(s)');

		for (packet in grabQueue) {
			var parsedPacket = parseIncomingPacketSimplified(packet);
			switch (parsedPacket)
			{
				case Unknown(cmd):
					parsedPacket = parseIncomingPacket(packet);
				default: 
			}
			// trace("< " + parsedPacket);
			switch (parsedPacket) {
				case RoomInfo(version, genver, tags, password, permissions, hint_cost, location_check_points, games, _, datapackage_checksums, seed_name, time):
					_hasBeenConnected = true;
					localConnectTime = Timer.stamp();
					serverConnectTime = time;
					serverVersion = [version["major"], version["minor"], version["build"]];
					seed = seed_name;
					hintCostPercent = hint_cost;
					hasPassword = password;
					hintPoints *= location_check_points;
					_tags = tags;
					if (state < State.ROOM_INFO)
						state = State.ROOM_INFO;
					_hOnRoomInfo();

					dataPackageValid = true;
					var games = new Set<String>();
					for (game => csum in datapackage_checksums) {
						try {
							if (!_dataPackage.games.exists(game)) { // new game
								games.add(game);
								continue;
							}
							if (_dataPackage.games[game].checksum != csum) { // existing update
								games.add(game);
								continue;
							}
						} catch (e) {
							trace(e.message);
							games.add(game);
						}
					}
					if (!(dataPackageValid = games.length > 0)){
						var gamess = yutautil.CollectionUtils.toArray(games, String);
						GetDataPackage(cast gamess);
					}else
						trace("DataPackage up to date");
						// GetDataPackage(games.toArray());
						// trace(_dataPackage);



					
				case ConnectionRefused(errors):
					_hOnSlotRefused(errors);

				case Connected(team, slot, players, missing_locations, checked_locations, slot_data, slot_info, hint_points):
					connectAttempts = 0;
					state = State.SLOT_CONNECTED;
					this.clientStatus = ClientStatus.CONNECTED;
					this.team = team;
					slotnr = slot;
					_players = players;
					locationCount = missing_locations.length + checked_locations.length;
					_slotInfo = [];
					for (id => info in slot_info)
						_slotInfo.set(Std.parseInt(id), info);
					hintPoints = hint_points;

					_checkedLocations = new Set<Int>(checked_locations);
					_missingLocations = new Set<Int>(missing_locations);

					if (_offlineQueue.length > 0) {
						var checks:Set<Int> = new Set<Int>(),
							scouts:Map<Int, Set<Int>> = [];
						_offlineLock.execute(() -> {
							for (q in _offlineQueue)
								switch (q) {
									case Check(id):
										checks.add(id);
									case Scout(id, asHint):
										if (scouts.exists(asHint)) scouts[asHint].add(id); else (scouts.set(asHint, new Set([id])));
								}
							_offlineQueue = [];
						});
						if (checks.length > 0)
							LocationChecks(checks.toArray());
						for (asHint => ids in scouts)
							LocationScouts(ids.toArray(), asHint);
					}

					trace(players);
					ArchPopup.startPopupCustom("Please wait...", "Fetching data for games...", "archColor");

					function data():Void {
						var gamePackages:Map<String, DataPackageObject> = [];
						for (game in players.mapT(function(p) return get_player_game(p.slot)).toIterable()) {
							// trace("Fetching data for game: " + game);
							var currentData = _dataPackage;
							var theGame:String = game;
							GetDataPackage([theGame]);
							while (_dataPackage == currentData) {
								// Wait for _dataPackage to change
								Sys.sleep(0.1);
							}
							gamePackages.set(game, _dataPackage);
						}
						var gameData = new DynamicAccess<GameData>();
						for (games => packages in gamePackages) {
							gameData.set(games, packages.games[games]);
						}

						APGameState.currentPackages = gameData;
						//trace("Game Data: " + gameData);

						var data:DataPackageObject = {
							games: gameData,
						};
						_dataPackage = data;
						return ArchPopup.startPopupCustom("The game can now be played!", "You are now connected to the server. Have fun!", "archColor");
					}

					yutautil.Threader.runInThread(data(), "DataPackageFetcher");

				// ArchPopup.startPopupCustom("The game can now be played!", "You are now connected to the server. Have fun!", "archColor");
					//

				trace("Data: " + slot_data);

					_hOnSlotConnected(slot_data);
					_hOnLocationChecked(checked_locations);

				case ReceivedItems(index, items):
					var index:Int = index;
					for (item in items)
						item.index = index++;
					_hOnItemsReceived(items);

				case LocationInfo(locations):
					_hOnLocationInfo(locations);

				case RoomUpdate(_, _, tags, password, _, _, _, _, _, _, _, _, players, checked_locations, hint_points):
					if (checked_locations != null && checked_locations.length > 0) {
						for (loc in checked_locations) {
							_checkedLocations.add(loc);
							_missingLocations.remove(loc);
						}
						_hOnLocationChecked(checked_locations);
					}
					if (tags != null)
						_tags = tags;
					if (password != null)
						hasPassword = password;
					if (players != null)
						_players = players;
					if (hint_points != null)
						hintPoints = hint_points;

				case DataPackage(pdata):
					var data:DataPackageObject = {
						games: _dataPackage.games.copy(),
					};
					for (game => gameData in pdata.games)
						data.games[game] = gameData;
					dataPackageValid = false;
					set_data_package(data);
					//trace('Data Package:' + data);
					dataPackageValid = true;
					_hOnDataPackageChanged(_dataPackage);
					_gotDataPackage = true;


				case Print(text): // NOTE: no longer present in spec
					_hOnPrint(text);

				case PrintJSON(data, type, receiving, item, found, team, slot, message, tags, countdown):
					_hOnPrintJSON(data, item, receiving);

				case Bounced(games, slots, tags, data):
					if (games != null && !games.contains(game))
						break;
					if (slots != null && !slots.contains(slotnr))
						break;
					if (tags != null) {
						var tagMatch = false;
						for (bTag in tags)
							tagMatch = tagMatch || this.tags.contains(bTag);
						if (!tagMatch)
							break;
					}
					_hOnBounced(data);
					// trace(data);

				// BUG: "Cannot access non-static abstract field statically" on extracting "keys"
				// case Retrieved(keys):
				//	_hOnRetrieved(keys);

				case SetReply(key, value, original_value):
					_hOnSetReply(key, value, original_value);

				case x:
					// before going any further, deconstruct the packet into an anon, and see if it is a Death Link Packet.
					// if it is, then we need to handle it differently.

					var packet = {};
					for (field in Reflect.fields(x)) {
						Reflect.setField(packet, field, Reflect.field(x, field));
					}
					if (Reflect.hasField(packet, "time") && Reflect.hasField(packet, "cause") && Reflect.hasField(packet, "source")) {
							// _hOnDeathLinkBounce(packet.time, packet.cause, packet.source);
						}

					try {
						trace('unhandled cmd ${x.getName()}');
						_hOnThrow("process_queue", x);
					} catch (e) {
						trace('Strange error... Attempting to recover');
						// trace(x);
					}
					// Attempt read via "cmd" field as text.
					if (Reflect.hasField(x, "cmd")) {
						Reflect.deleteField(x, "cmd");
						_recvQueue.push(x);
					} else {
						trace('Unhandled cmd: ${Reflect.field(x, "cmd")}');
					}
			}
		}
	}

	/** Resets the client to its original state. **/
	public function reset() {
		if (_ws != null)
			_ws.close();
		_ws = null;
		_offlineQueue = [];
		_sendQueue = [];
		_recvQueue = [];
		seed = "";
		slot = "";
		team = -1;
		slotnr = -1;
		_players = [];
		connectAttempts = 0;
		_hasTriedWSS = false;
		_hasBeenConnected = false;
		this.clientStatus = ClientStatus.UNKNOWN;
		state = State.DISCONNECTED;
		hasPassword = false;
	}

	/** Called when the websocket is opened. **/
	private function onopen() {
		trace("onopen()");
		trace("Server connected");
		state = State.SOCKET_CONNECTED;
		_hOnSocketConnected();
		_socketReconnectInterval = 1.5;
	}

	/** Called when the websocket is closed. **/
	private function onclose() {
		trace("onclose()");
		if (state > State.SOCKET_CONNECTING) {
			trace("Server disconnected");
			state = State.DISCONNECTED;
			_hOnSocketDisconnected();
		}
		if (!_hasBeenConnected && !_hasTriedWSS) {
			trace("Disconnected immediately; may be a WSS socket (upgrading)");
			uri = toggleWSS(uri);
		}
		state = State.DISCONNECTED;
		seed = "";
		_ws.close();
	}

	/**
		Called when the websocket receives a message.
		@param msg The message received.
	**/
	private function onmessage(msg:MessageType) {
		trace("onmessage()");
		switch (msg) {
			case StrMessage(content):
				_recvLock.execute(() -> {
					try {
						var newPackets:Array<IncomingPacket> = TJson.parse(content);
						// trace(newPackets);
						for (newPacket in newPackets)
							_recvQueue.push(newPacket);
					} catch (e) {
						trace("EXCEPTION onmessage: " + e);
						_hOnThrow("onmessage", e);
					}
				});

			default:
		}
	}

	/**
		Called when the websocket encounters an error.
		@param e The error data.
	**/
	private function onerror(e:Dynamic) {
		trace("onerror()");
		_hOnSocketError(Std.string(e));
		_hOnThrow("onerror", e);
		// TODO: this is where apclientpp switches between wss and ws
	}

	/** Creates a new websocket client and connects to the server. **/
	private function connect_socket() {
		if (_ws != null)
			_ws.close();
		if (uri.length == 0) {
			_ws = null;
			state = State.DISCONNECTED;
			return;
		}
		state = State.SOCKET_CONNECTING;
		trace("Connecting to " + uri);
		
		try {
			_lastSocketConnect = Timer.stamp();
			_socketReconnectInterval *= 2;
			if (_socketReconnectInterval > 15)
				_socketReconnectInterval = 15;
			connectAttempts++;

			_ws = new WebSocket(uri);
			_ws.onopen = onopen;
			_ws.onclose = onclose;
			_ws.onmessage = onmessage;
			_ws.onerror = onerror;
		} catch (e:Exception) {
			trace("Error connecting to AP socket", e);
			_hOnThrow("connect_socket", e);
			if (e.message == "ssl network error" && uri.startsWith("wss:")) {
				trace("WSS connection not found; auto-switching to WS");
				_hasTriedWSS = true;
				uri = toggleWSS(uri);
			}
		}
	}

	public function disconnect_socket() {
		if (_ws != null) {
			_ws.close();
			state = State.DISCONNECTED;
		}
	}

	/**
		Converts a color string to an ANSI representation of that string.
		@param color The color to convert.
		@return The ANSI representation of the color.
	**/
	private static function color2ansi(color:String):String
		return switch (color) {
			case "red": "\x1b[31m";
			case "green": "\x1b[32m";
			case "yellow": "\x1b[33m";
			case "blue": "\x1b[34m";
			case "magenta": "\x1b[35m";
			case "cyan": "\x1b[36m";
			case "plum": "\x1b[38:5:219m";
			case "slateblue": "\x1b[38:5:62m";
			case "salmon": "\x1b[38:5:210m";
			default: "\x1b[0m";
		}

	/**
		Strips ANSI escape codes from a string.
		@param text The string to de-ANSIfy.
		@return The de-ANSIfied string.
	**/
	private static inline function deansify(text:String):String
		return ~/\x1b\[[\d:]+m/g.replace(text, "");

	/**
		Changes a wss:// URI into ws://, and vice versa.
		@param uri The URI to convert.
		@return The URI with the opposite protocol. If the original URI does not have a protocol specified, a wss:// URI is returned.
	**/
	private static function toggleWSS(uri:String):String {
		var isWSS = uri.startsWith("wss://");
		var baseURI = (~/^wss?:\/\//).replace(uri, "");
		return (isWSS ? "ws://" : "wss://") + baseURI;
	}
}
