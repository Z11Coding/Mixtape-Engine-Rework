package archipelago;

/** The current connection state of the Archipelago client. **/
enum abstract State(Int) {
	/** The client is not connected. **/
	var DISCONNECTED = 0;
	/** The client is in the process of connecting. **/
	var SOCKET_CONNECTING = 1;
	/** The client is connected to the server, but has not authenticated yet. **/
	var SOCKET_CONNECTED = 2;
	/** The client has received a RoomInfo packet, but has not authenticated yet. **/
	var ROOM_INFO = 3;
	/** The client has connected and authenticated to the server. **/
	var SLOT_CONNECTED = 4;

	@:op(A < B)
	static function lt(a:State, b:State):Bool;

	@:op(A <= B)
	static function lte(a:State, b:State):Bool;

	@:op(A > B)
	static function gt(a:State, b:State):Bool;

	@:op(A >= B)
	static function gte(a:State, b:State):Bool;

	@:op(A == B)
	static function eq(a:State, b:State):Bool;

	@:op(A != B)
	static function ne(a:State, b:State):Bool;
}

/** Indicates how to render the JSON packet(s) being processed. **/
enum RenderFormat {
	/** Render the packets as text only. **/
	TEXT;
	/** Render the packets as HTML. Not currently implemented. **/
	HTML;
	/** Render the packets as ANSI text. **/
	ANSI;
}

/** Queue kept for when checks and scouts cannot be sent (such as when the client is disconnected). **/
enum OfflineQueueType {
	/** A queued check. **/
	Check(id:Int);
	/** A queued scout. **/
	Scout(id:Int, asHint:Int);
}