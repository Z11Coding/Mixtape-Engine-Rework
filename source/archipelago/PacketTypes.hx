package archipelago;

import haxe.DynamicAccess;

/** A data representation of a player in the multiworld. **/
typedef NetworkPlayer = {
	/** The team number the player is in. **/
	var team:Int;

	/** The slot number for the player. **/
	var slot:Int;

	/** The player's name in current time. **/
	var alias:String;

	/** The original name used when the session was generated. This is typically distinct in games which require baking names into ROMs or for async games. **/
	var name:String;
}

/** Items that are sent over the net (in packets). **/
typedef NetworkItem = {
	/** The item id of the item. Item ids are in the range of ±2⁵³-1. **/
	var item:Int;

	/** The location id of the item inside the world. Location ids are in the range of ±2⁵³-1. **/
	var location:Int;

	/** The player slot of the world the item is located in, except when inside an LocationInfo Packet then it will be the slot of the player to receive the item **/
	var player:Int;

	/** Flags to denote the item's importance. **/
	var flags:ItemFlags;

	/** The index number of the item. Not filled in by the AP server, but added by hxArchipelago for convenience. **/
	var ?index:Int;
}

/**
	Message nodes sent along with PrintJSON packet to be reconstructed into a legible message. The nodes are intended to be read in the order they are listed
	in the packet.
**/
typedef JSONMessagePart = {
	/**
		Used to denote the intent of the message part. This can be used to indicate special information which may be rendered differently depending on client.
		How these types are displayed in Archipelago's ALttP client is not the end-all be-all. Other clients may choose to interpret and display these messages differently.
	**/
	var ?type:JSONType;

	/** The content of the message part to be displayed. **/
	var ?text:String;
	
	/**
		Used to denote a console color to display the message part with and is only send if the `type` is `color`. This is limited to console colors due to backwards
		compatibility needs with games such as ALttP. Although background colors as well as foreground colors are listed, only one may be applied to a `JSONMessagePart`
		at a time.
	**/
	var ?color:String;

	/** Contains the `NetworkItem` flags that belong to the item **/
	var ?flags:ItemFlags;

	/** Marks owning player id for location/item **/
	var ?player:Int;
}

/** `type` is used to denote the intent of the message part. **/
enum abstract JSONType(String) from String to String {
	/** Regular text content. Is the default type and as such may be omitted. **/
	var JTYPE_TEXT = "text";

	/** player ID of someone on your team, should be resolved to Player Name **/
	var JTYPE_PLAYER_ID = "player_id";

	/** Player Name, could be a player within a multiplayer game or from another team, not ID resolvable **/
	var JTYPE_PLAYER_NAME = "player_name";

	/** Item ID, should be resolved to Item Name **/
	var JTYPE_ITEM_ID = "item_id";

	/** Item Name, not currently used over network, but supported by reference Clients. **/
	var JTYPE_ITEM_NAME = "item_name";

	/** Location ID, should be resolved to Location Name **/
	var JTYPE_LOCATION_ID = "location_id";

	/** Location Name, not currently used over network, but supported by reference Clients. **/
	var JTYPE_LOCATION_NAME = "location_name";

	/** Entrance Name. No ID mapping exists. **/
	var JTYPE_ENTRANCE_NAME = "entrance_name";

	/** Regular text that should be colored. Only `type` that will contain `color` data.**/
	var JTYPE_COLOR = "color";
}

/**
	An enumeration containing the possible client states that may be used to inform the server in StatusUpdate.
	The MultiServer automatically sets the client state to `ClientStatus.CONNECTED` on the first active connection to a slot.
**/
abstract ClientStatus(Int) from Int to Int {
	public static var UNKNOWN = 0;
	public static var CONNECTED = 5;
	public static var READY = 10;
	public static var PLAYING = 20;
	public static var GOAL = 30;
}

/** An object representing software versioning. Used in the Connect packet to allow the client to inform the server of the Archipelago version it supports. **/
private typedef INetworkVersion = {
	var major:Int;
	var minor:Int;
	var build:Int;
}

@:forward
// @:jsonStringify(function (ver:ap.PacketTypes.NetworkVersion)
// 	return {
// 		major: ver.major,
// 		minor: ver.minor,
// 		build: ver.build,
// 		"class": "Version"
// 	};
// )
@:json({"class": "Version"})
abstract NetworkVersion(INetworkVersion) from INetworkVersion to INetworkVersion {
	public function new(ver:INetworkVersion)
		this = ver;

	@:to
	public function toString()
		return '${this.major}.${this.minor}.${this.build}';

	@:from
	public static function fromArray(ver:Array<Int>) {
		var retval:INetworkVersion = {major: 0, minor: 0, build: 0};
		if (ver.length > 0)
			retval.major = ver[0];
		if (ver.length > 1)
			retval.minor = ver[1];
		if (ver.length > 2)
			retval.build = ver[2];
		return new NetworkVersion(retval);
	}

	@:to
	public function toArray()
		return [this.major, this.minor, this.build];

	@:op(A > B)
	function gt(rhs:NetworkVersion) {
		if (this.major == rhs.major) {
			if (this.minor == rhs.minor)
				return this.build > rhs.build;
			else return this.minor > rhs.minor;
		} else return this.major > rhs.major;
	}

	@:op(A < B)
	function lt(rhs:NetworkVersion) {
		if (this.major == rhs.major) {
			if (this.minor == rhs.minor)
				return this.build < rhs.build;
			else return this.minor < rhs.minor;
		} else return this.major < rhs.major;
	}

	@:op(A == B)
	function eq(rhs:NetworkVersion)
		return this.major == rhs.major && this.minor == rhs.minor && this.build == rhs.build;
}

/** An enum representing the nature of a slot. **/
abstract SlotType(Int) from Int to Int {
	static var STYPE_SPECTATOR = 0;
	static var STYPE_PLAYER = 1 << 0;
	static var STYPE_GROUP = 1 << 1;

	/** Whether this slot belongs to a spectator. **/
	public var isSpectator(get, never):Bool;
	/** Whether this slot belongs to a player.**/
	public var isPlayer(get, never):Bool;
	/** Whether this slot belongs to a group. **/
	public var isGroup(get, never):Bool;

	inline function get_isSpectator()
		return this == 0;

	inline function get_isPlayer()
		return this & STYPE_PLAYER == STYPE_PLAYER;

	inline function get_isGroup()
		return this & STYPE_GROUP == STYPE_GROUP;
}

/** An object representing static information about a slot. **/
typedef NetworkSlot = {
	var name:String;
	var game:String;
	var type:SlotType;

	/** Only populated in `type == group` **/
	var ?group_members:Array<Int>;
}

/** An enumeration containing the possible command permission, for commands that may be restricted. **/
abstract Permission(Int) from Int to Int {
	static var PERM_DISABLED = 0;
	static var PERM_ENABLED = 1 << 0;
	static var PERM_GOAL = 1 << 1;
	static var PERM_AUTO = 1 << 2;
	static var PERM_AUTO_GOAL = PERM_GOAL | PERM_AUTO;
	static var PERM_AUTO_ENABLED = PERM_AUTO_GOAL | PERM_ENABLED;

	/** Whether this feature is enabled by default. **/
	public var isEnabled(get, never):Bool;

	/** Whether this feature will be enabled upon reaching the player's goal. **/
	public var isEnabledOnGoal(get, never):Bool;

	/** Whether this feature will be triggered automatically upon reaching the player's goal. **/
	public var isAutoOnGoal(get, never):Bool;

	inline function get_isEnabled()
		return this & PERM_ENABLED == PERM_ENABLED;

	inline function get_isEnabledOnGoal()
		return this & PERM_GOAL == PERM_GOAL;

	inline function get_isAutoOnGoal()
		return this & PERM_AUTO_GOAL == PERM_AUTO_GOAL;
}

/** An object representing a Hint. **/
typedef Hint = {
	var receiving_player:Int;
	var finding_player:Int;
	var location:Int;
	var item:Int;
	var found:Bool;
	var entrance:String;
	var item_flags:Int;
}

/**
	A data package is a JSON object which may contain arbitrary metadata to enable a client to interact with the Archipelago server most
	easily and not maintain their own mappings. Some contents include:
	- Name to ID mappings for items and locations.
	- A checksum of each game's data package for clients to tell if a cached package is invalid.

	We encourage clients to cache the data package they receive on disk, or otherwise not tied to a session. You will know when your cache
	is outdated if the RoomInfo packet or the datapackage itself denote a different checksum than any locally cached ones.

	Important Notes about IDs and Names:
	- IDs ≤ 0 are reserved for "Archipelago" and should not be used by other world implementations.
	- The IDs from the game "Archipelago" (in `worlds/generic`) may be used in any world.
	  - Especially Location ID `-1`: `Cheat Console` and `-2`: `Server` (typically Remote Start Inventory)
	- Any names and IDs are only unique in its own world data package, but different games may reuse these names or IDs.
	  - At runtime, you will need to look up the game of the player to know which item or location ID/Name to lookup in the data package.
	  This can be easily achieved by reviewing the `slot_info` for a particular player ID prior to lookup.
**/
typedef DataPackageObject = {
	/** Mapping of all Games and their respective data **/
	var games:DynamicAccess<GameData>;
}

/** GameData is a dict but contains these keys and values. It's broken out into another "type" for ease of documentation. **/
typedef GameData = {
	/** Mapping of all item names to their respective ID. **/
	var item_name_to_id:DynamicAccess<Int>;

	/** Mapping of all location names to their respective ID. **/
	var location_name_to_id:DynamicAccess<Int>;

	/** A checksum hash of this game's data. **/
	var checksum:String;
}






abstract ItemFlags(Int) from Int to Int {
	static var FLAG_NONE = 0;
	static var FLAG_ADVANCEMENT = 1 << 0;
	static var FLAG_NEVER_EXCLUDE = 1 << 1;
	static var FLAG_TRAP = 1 << 2;

	/** If set, indicates the item can unlock logical advancement **/
	public var isAdvancement(get, never):Bool;

	/** If set, indicates the item is important but not in a way that unlocks advancement **/
	public var isNeverExclude(get, never):Bool;

	/** If set, indicates the item is a trap **/
	public var isTrap(get, never):Bool;

	inline function get_isAdvancement()
		return this & FLAG_ADVANCEMENT == FLAG_ADVANCEMENT;

	inline function get_isNeverExclude()
		return this & FLAG_NEVER_EXCLUDE == FLAG_NEVER_EXCLUDE;

	inline function get_isTrap()
		return this & FLAG_TRAP == FLAG_TRAP;
}

// TODO: figure out how to not have to include "class" through Tink library
// @:json({"class": "Version"})

/**
	A `DataStorageOperation` manipulates or alters the value of a key in the data storage. If the operation transforms the value from one state
	to another then the current value of the key is used as the starting point otherwise the Set's package default is used if the key does not
	exist on the server already. DataStorageOperations consist of an object containing both the operation to be applied, provided in the form
	of a string, as well as the value to be used for that operation, Example:
	```json
	{"operation": "add", "value": 12}
	```
**/
enum DataStorageOperation {
	/** Sets the current value of the key to `value`. **/
	@:json({operation: "replace"})
	Replace(value:Dynamic);

	/** If the key has no value yet, sets the current value of the key to `default` of the Set's package (`value` is ignored). **/
	@:json({operation: "default"})
	Default(value:Dynamic);

	/** Adds `value` to the current value of the key, if both the current value and `value` are arrays then `value` will be appended to the current value. **/
	@:json({operation: "add"})
	Add(value:Dynamic);

	/** Multiplies the current value of the key by `value`. **/
	@:json({operation: "mul"})
	Multiply(value:Dynamic);

	/** Multiplies the current value of the key to the power of `value`. **/
	@:json({operation: "pow"})
	Exponent(value:Dynamic);

	/** Sets the current value of the key to the remainder after division by `value`. **/
	@:json({operation: "mod"})
	Modulo(value:Dynamic);

	/** Sets the current value of the key to `value` if `value` is bigger. **/
	@:json({operation: "max"})
	Max(value:Dynamic);

	/** Sets the current value of the key to `value` if `value` is lower. **/
	@:json({operation: "min"})
	Min(value:Dynamic);

	/** Applies a bitwise AND to the current value of the key with `value`. **/
	@:json({operation: "and"})
	And(value:Dynamic);

	/** Applies a bitwise OR to the current value of the key with `value`. **/
	@:json({operation: "or"})
	Or(value:Dynamic);

	/** Applies a bitwise Exclusive OR to the current value of the key with `value`. **/
	@:json({operation: "xor"})
	Xor(value:Dynamic);

	/** Applies a bitwise left-shift to the current value of the key by `value`. **/
	@:json({operation: "left_shift"})
	LeftBitshift(value:Dynamic);

	/** Applies a bitwise right-shift to the current value of the key by `value`. **/
	@:json({operation: "right_shift"})
	RightBitshift(value:Dynamic);

	/** List only: removes the first instance of `value` found in the list. **/
	@:json({operation: "remove"})
	Remove(value:Dynamic);

	/** List or Dict: for lists it will remove the index of the `value` given. for dicts it removes the element with the specified key of `value`. **/
	@:json({operation: "pop"})
	Pop(value:Dynamic);

	/** Dict only: Updates the dictionary with the specified elements given in `value` creating new keys, or updating old ones if they previously existed. **/
	@:json({operation: "update"})
	Update(value:Dynamic);
}

/** These packets are are sent from the multiworld server to the client. They are not messages which the server accepts. **/
enum IncomingPacket {
	/**
		Sent to clients when they connect to an Archipelago server.
		@param version Object denoting the version of Archipelago which the server is running.
		@param generator_version Object denoting the version of Archipelago which generated the multiworld.
		@param tags Denotes special features or capabilities that the sender is capable of. Example: `WebHost`
		@param password Denoted whether a password is required to join this room.
		@param permissions Mapping of permission name to `Permission`, keys are: "forfeit", "collect" and "remaining".
		@param hint_cost The amount of points it costs to receive a hint from the server.
		@param location_check_points The amount of hint points you receive per item/location check completed.
		@param games List of games present in this multiworld.
		@param datapackage_versions **Deprecated.** Use `datapackage_checksums` instead. No longer present in 0.5.x.
		@param datapackage_checksums Checksum hash of the individual games' data packages the server will send.
			Used by newer clients to decide which games' caches are outdated.
		@param seed_name uniquely identifying name of this generation
		@param time Unix time stamp of "now". Send for time synchronization if wanted for things like the DeathLink Bounce.
	**/
	@:json({cmd: "RoomInfo"})
	RoomInfo(
		// HACK: due to how NetworkVersion is sent
		//version:NetworkVersion,
		version:DynamicAccess<Dynamic>,
		?generator_version:DynamicAccess<Dynamic>,
		tags:Array<String>,
		password:Bool,
		permissions:DynamicAccess<Permission>,
		hint_cost:Int,
		location_check_points:Int,
		games:Array<String>,
		?datapackage_versions:DynamicAccess<Int>,
		datapackage_checksums:DynamicAccess<String>,
		seed_name:String,
		time:Float
	);

	/**
		Sent to clients when the server refuses connection. This is sent during the initial connection handshake.
		@param errors _Optional._ When provided, should contain any one of: `InvalidSlot`, `InvalidGame`, `IncompatibleVersion`, `InvalidPassword`, or `InvalidItemsHandling`.
	**/
	@:json({cmd: "ConnectionRefused"})
	ConnectionRefused(
		?errors:Array<String>
	);

	/**
		Sent to clients when the connection handshake is successfully completed.
		@param team Your team number. See `NetworkPlayer` for more info on team number.
		@param slot Your slot number on your team. See `NetworkPlayer` for more info on the slot number.
		@param players List denoting other players in the multiworld, whether connected or not.
		@param missing_locations Contains ids of remaining locations that need to be checked. Useful for trackers, among other things.
		@param checked_locations Contains ids of all locations that have been checked. Useful for trackers, among other things. Location ids are in the range of ± 2⁵³-1.
		@param slot_data Contains a json object for slot related data, differs per game. Empty if not required.
		@param slot_info maps each slot to a `NetworkSlot` information
		@param hint_points Number of hint points that the current player has.
		@see NetworkPlayer
	**/
	@:json({cmd: "Connected"})
	Connected(
		team:Int,
		slot:Int,
		players:Array<NetworkPlayer>,
		missing_locations:Array<Int>,
		checked_locations:Array<Int>,
		?slot_data:Null<Dynamic>,
		slot_info:DynamicAccess<NetworkSlot>,
		hint_points:Int
	);

	/**
		Sent to clients when they receive an item.
		@param index The next empty slot in the list of items for the receiving client.
		@param items The items which the client is receiving.
	**/
	@:json({cmd: "ReceivedItems"})
	ReceivedItems(
		index:Int,
		items:Array<NetworkItem>
	);

	/**
		Sent to clients to acknowledge a received LocationScouts packet and responds with the item in the location(s) being scouted.
		@param items Contains list of item(s) in the location(s) scouted.
	**/
	@:json({cmd: "LocationInfo"})
	LocationInfo(
		locations:Array<NetworkItem>
	);

	/**
		Sent when there is a need to update information about the present game session.
		RoomUpdate may contain the same arguments from RoomInfo and, once authenticated, arguments from Connected with the following exceptions:
		- `players`: Sent in the event of an alias rename. Always sends all players, whether connected or not.
		- `checked_locations`: May be a partial update, containing new locations that were checked, especially from a coop partner in the same slot.
		- `missing_locations`: Never sent in this packet. If needed, it is the inverse of `checked_locations`.

		All arguments for this packet are optional, only changes are sent.
		@param version Object denoting the version of Archipelago which the server is running.
		@param generator_version Object denoting the version of Archipelago which generated the multiworld.
		@param tags Denotes special features or capabilities that the sender is capable of. Example: `WebHost`
		@param password Denoted whether a password is required to join this room.
		@param permissions Mapping of permission name to `Permission`, keys are: "forfeit", "collect" and "remaining".
		@param hint_cost The amount of points it costs to receive a hint from the server.
		@param location_check_points The amount of hint points you receive per item/location check completed.
		@param games List of games present in this multiworld.
		@param datapackage_versions **Deprecated.** Use `datapackage_checksums` instead. No longer present in 0.5.x.
		@param datapackage_checksums Checksum hash of the individual games' data packages the server will send.
			Used by newer clients to decide which games' caches are outdated.
		@param seed_name uniquely identifying name of this generation
		@param time Unix time stamp of "now". Send for time synchronization if wanted for things like the DeathLink Bounce.

		@param players Sent in the event of an alias rename. Always sends all players, whether connected or not.
		@param checked_locations May be a partial update, containing new locations that were checked, especially from a coop partner in the same slot.
		@param hint_points Number of hint points that the current player has.
	**/
	@:json({cmd: "RoomUpdate"})
	RoomUpdate(
		?version:DynamicAccess<Dynamic>,
		?generator_version:DynamicAccess<Dynamic>,
		?tags:Array<String>,
		?password:Bool,
		?permissions:DynamicAccess<Permission>,
		?hint_cost:Int,
		?location_check_points:Int,
		?games:Array<String>,
		?datapackage_versions:DynamicAccess<Int>,
		?datapackage_checksums:DynamicAccess<String>,
		?seed_name:String,
		?time:Float,

		?players:Array<NetworkPlayer>,
		?checked_locations:Array<Int>,
		?hint_points:Int,
	);

	/**
		Sent to clients purely to display a message to the player.
		@deprecated No longer used. Use `PrintJSON` instead.
		@param text Message to display to player.
	**/
	@:json({cmd: "Print"})
	Print(
		text:String
	);

	/**
		Sent to clients purely to display a message to the player. This packet differs from Print in that the data being sent with this packet
		allows for more configurable or specific messaging.
		@param data Type of this part of the message.
		@param type May be present to indicate the nature of this message. Known types are Hint and ItemSend.
		@param receiving Is present if type is Hint or ItemSend and marks the destination player's ID.
		@param item Is present if type is Hint or ItemSend and marks the source player id, location id, item id and item flags.
		@param found Is present if type is Hint, denotes whether the location hinted for was checked.
		@param team Team of the triggering player
		@param slot Slot of the triggering player
		@param message Original chat message without sender prefix
		@param tags Tags of the triggering player
		@param countdown Amount of seconds remaining on the countdown
	**/
	@:json({cmd: "PrintJSON"})
	PrintJSON(
		data:Array<JSONMessagePart>, // always
		?type:String, // defines the following
		?receiving:Int, // ItemSend, ItemCheat, Hint
		?item:NetworkItem, // ItemSend, ItemCheat, Hint
		?found:Bool, // Hint
		?team:Int, // Join, Part, Chat, TagsChanged, Goal, Release, Collect, ItemCheat
		?slot:Int, // Join, Part, Chat, TagsChanged, Goal, Release, Collect
		?message:String, // Chat, ServerChat
		?tags:DynamicAccess<String>, // Join, TagsChanged
		?countdown:Int // Countdown
	);

	/**
		Sent to clients to provide what is known as a 'data package' which contains information to enable a client to most easily communicate
		with the Archipelago server. Contents include things like location id to name mappings, among others; see Data Package Contents for more info.
		@param data The data package as a JSON object.
	**/
	@:json({cmd: "DataPackage"})
	DataPackage(
		data:DataPackageObject
	);

	/**
		Sent to clients after a client requested this message be sent to them, more info in the Bounce package.
		@param games *Optional.* Game names this message is targeting
		@param slots *Optional.* Player slot IDs that this message is targeting
		@param tags *Optional.* Client Tags this message is targeting
		@param data The data in the Bounce package copied
	**/
	@:json({cmd: "Bounced"})
	Bounced(
		games:Null<Array<String>>,
		slots:Null<Array<Int>>,
		tags:Null<Array<String>>,
		data:Dynamic
	);

	/**
		Sent to clients as a response to a Get package.

		Additional arguments added to the Get package that triggered this Retrieved will also be passed along.
		@param keys A key-value collection containing all the values for the keys requested in the Get package.
	**/
	@:json({cmd: "Retrieved"})
	Retrieved(
		keys:DynamicAccess<Dynamic>
	);

	/**
		Sent to clients in response to a Set package if `want_reply` was set to true, or if the client has registered to receive updates
		for a certain key using the SetNotify package. SetReply packages are sent even if a Set package did not alter the value for the key.
		@param key The key that was updated.
		@param value The new value for the key.
		@param original_value The value the key had before it was updated. Not present on "_read" prefixed special keys.
	**/
	@:json({cmd: "SetReply"})
	SetReply(
		key:String,
		value:Dynamic,
		?original_value:Dynamic
	);

	/**
		Sent to clients if the server caught a problem with a packet. This only occurs for errors that are explicitly checked for.
		@param type The PacketProblemType that was detected in the packet.
		@param original_cmd The `cmd` argument of the faulty packet, will be `null` if the `cmd` failed to be parsed.
		@param text A descriptive message of the problem at hand.
	**/
	@:json({cmd: "InvalidPacket"})
	InvalidPacket(
		type:String,
		?original_cmd:Null<String>,
		text:String
	);

	/** Catchall for unrecognized incoming packets. **/
	Unknown(
		cmd:String
	);
}

// Outgoing packets

/** These packets are sent purely from client to server. They are not accepted by clients. **/
enum OutgoingPacket {
	/**
		Sent by the client to initiate a connection to an Archipelago game session.
		@param password If the game session requires a password, it should be passed here.
		@param game The name of the game the client is playing. Example: `A Link to the Past`
		@param name The player name for this client.
		@param uuid Unique identifier for player client.
		@param version An object representing the Archipelago version this client supports.
		@param items_handling Flags configuring which items should be sent by the server. Read below for individual flags.
		@param tags Denotes special features or capabilities that the sender is capable of.
		@param slot_data If true, the Connect answer will contain `slot_data`
	**/
	@:json({cmd: "Connect"})
	Connect(
		password:Null<String>,
		game:String,
		name:String,
		uuid:String,
		// HACK: due to how NetworkVersion is sent
		//version:NetworkVersion,
		version:DynamicAccess<Dynamic>,
		items_handling:Int,
		tags:Array<String>,
		slot_data:Bool
	);

	/**
		Update arguments from the Connect package, currently only updating tags and `items_handling` is supported.
		@param items_handling Flags configuring which items should be sent by the server.
		@param tags Denotes special features or capabilities that the sender is capable of.
	**/
	@:json({cmd: "ConnectUpdate"})
	ConnectUpdate(
		items_handling:Null<Int>,
		tags:Null<Array<String>>
	);

	/** Sent to server to request a ReceivedItems packet to synchronize items. **/
	@:json({cmd: "Sync"})
	Sync;

	/**
		Sent to server to inform it of locations that the client has checked. Used to inform the server of new checks that are made, as well as to sync state.
		@param locations The ids of the locations checked by the client. May contain any number of checks, even ones sent before;
			duplicates do not cause issues with the Archipelago server.
	**/
	@:json({cmd: "LocationChecks"})
	LocationChecks(
		locations:Array<Int>
	);

	/**
		Sent to the server to inform it of locations the client has seen, but not checked. Useful in cases in which the item may appear in the game world,
		such as 'ledge items' in A Link to the Past. The server will always respond with a LocationInfo packet with the items located in the scouted location.
		@param locations The ids of the locations seen by the client. May contain any number of locations, even ones sent before;
			duplicates do not cause issues with the Archipelago server.
		@param create_as_hint If non-zero, the scouted locations get created and broadcasted as a player-visible hint.
			If 2 only new hints are broadcast, however this does not remove them from the LocationInfo reply.
	**/
	@:json({cmd: "LocationScouts"})
	LocationScouts(
		locations:Array<Int>,
		create_as_hint:Int
	);

	/**
		Sent to the server to update on the sender's status. Examples include readiness or goal completion. (Example: defeated Ganon in A Link to the Past)
		@param status One of `ClientStatus`.
		@see ClientStatus
	**/
	@:json({cmd: "StatusUpdate"})
	StatusUpdate(
		status:ClientStatus
	);

	/**
		Basic chat command which sends text to the server to be distributed to other clients.
		@param text Text to send to others.
	**/
	@:json({cmd: "Say"})
	Say(
		text:String
	);

	/**
		Requests the data package from the server. Does not require client authentication.
		@param games *Optional.* If specified, will only send back the specified data. Such as, ["Factorio"] -> Datapackage with only Factorio data.
	**/
	@:json({cmd: "GetDataPackage"})
	GetDataPackage(
		games:Null<Array<String>>
	);

	/**
		Send this message to the server, tell it which clients should receive the message and the server will forward the message to all those targets
		to which any one requirement applies.
		@param games *Optional.* Game names that should receive this message
		@param slots *Optional.* Player slot IDs that that should receive this message
		@param tags *Optional.* Client Tags that should receive this message
		@param data Any data you want to send
	**/
	@:json({cmd: "Bounce"})
	Bounce(
		games:Null<Array<String>>,
		slots:Null<Array<Int>>,
		tags:Null<Array<String>>,
		data:Dynamic
	);

	/**
		Used to request a single or multiple values from the server's data storage, see the Set package for how to write values to the data storage.
		A Get package will be answered with a Retrieved package.

		Additional arguments sent in this package will also be added to the Retrieved package it triggers.
		@param keys Keys to retrieve the values for.
	**/
	@:json({cmd: "Get"})
	Get(
		keys:Array<String>
	);

	/**
		Used to write data to the server's data storage, that data can then be shared across worlds or just saved for later.
		Values for keys in the data storage can be retrieved with a Get package, or monitored with a SetNotify package.
		@param key The key to manipulate.
		@param dflt The default value to use in case the key has no value on the server.
		@param want_reply If set, the server will send a SetReply response back to the client.
		@param operations Operations to apply to the value, multiple operations can be present and they will be executed in order of appearance.
	**/
	// TODO: handle changing "dflt" to "default" (I have no reason to believe this method will work 'cause jsonStringify is not working for NetworkVersion)
	// @:json({cmd: "Set"})
	@:jsonStringify((data:archipelago.PacketTypes.OutgoingPacket) -> {
		return switch (data) {
			case Set(key, dflt, want_reply, operations): {
					cmd: "Set",
					key: key,
					"default": dflt,
					want_reply: want_reply,
					operations: operations
				};
			default: null;
		}
	})
	Set(
		key:String,
		dflt:Dynamic,
		want_reply:Bool,
		operations:Array<DataStorageOperation>
	);

	/**
		Used to register your current session for receiving all SetReply packages of certain keys to allow your client to keep track of changes.
		@param keys Keys to receive all SetReply packages for.
	**/
	@:json({cmd: "SetNotify"})
	SetNotify(
		keys:Array<String>
	);
}

// Bounce packets

/** A special kind of Bounce packet that can be supported by any AP game. It targets the tag "DeathLink". **/
typedef DeathLinkBouncePacket = {
	/** Unix Time Stamp of time of death. **/
	var time:Float;

	/** _Optional._ Text to explain the cause of death, ex. "Berserker was run over by a train." **/
	var ?cause:String;

	/** Name of the player who first died. Can be a slot name, but can also be a name from within a multiplayer game. **/
	var source:String;
}
