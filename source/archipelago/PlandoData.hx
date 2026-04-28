package archipelago;

import haxe.crypto.Base64;
import tjson.TJSON;

/**
 * Stores and manages Plando configuration data for Archipelago.
 * Handles serialization to JSON and Base64 for YAML export.
 */
class PlandoData
{
	// Song-related options
	public var excludeSongLocations:Array<String> = [];
	public var prioritySongLocations:Array<String> = [];
	public var alwaysIncludeSongs:Array<String> = [];
	public var potentialVictorySongs:Array<String> = [];
	public var extraStartingSongs:Array<String> = [];
	public var localSongs:Array<String> = [];
	public var nonLocalSongs:Array<String> = [];

	// Plando blocks (for custom item placement)
	public var plandoBlocks:Array<PlandoBlock> = [];

	public function new()
	{
	}

	/**
	 * Serialize plando data to a JSON object
	 */
	public function toJSON():Dynamic
	{
		var obj:Dynamic = {};

		// Only include non-empty arrays
		if (excludeSongLocations.length > 0)
			Reflect.setField(obj, "exclude_song_locations", excludeSongLocations);

		if (prioritySongLocations.length > 0)
			Reflect.setField(obj, "priority_song_locations", prioritySongLocations);

		if (alwaysIncludeSongs.length > 0)
			Reflect.setField(obj, "always_include_songs", alwaysIncludeSongs);

		if (potentialVictorySongs.length > 0)
			Reflect.setField(obj, "potential_victory_songs", potentialVictorySongs);

		if (extraStartingSongs.length > 0)
			Reflect.setField(obj, "extra_starting_songs", extraStartingSongs);

		if (localSongs.length > 0)
			Reflect.setField(obj, "local_songs", localSongs);

		if (nonLocalSongs.length > 0)
			Reflect.setField(obj, "non_local_songs", nonLocalSongs);

		if (extraStartingSongs.length > 0)
			Reflect.setField(obj, "extra_starting_songs", extraStartingSongs);

		// Include plando blocks if any exist
		if (plandoBlocks.length > 0)
		{
			var blocks = [];
			for (block in plandoBlocks)
			{
				blocks.push(block.toJSON());
			}
			Reflect.setField(obj, "plando_blocks", blocks);
		}

		return obj;
	}

	/**
	 * Convert plando data to Base64-encoded JSON string for YAML
	 */
	public function toBase64():String
	{
		var json = TJSON.encode(toJSON());
		return Base64.encode(haxe.io.Bytes.ofString(json));
	}

	/**
	 * Load plando data from JSON object
	 */
	public function fromJSON(obj:Dynamic):Void
	{
		var temp1 = Reflect.field(obj, "exclude_song_locations");
		excludeSongLocations = temp1 != null ? (temp1 : Array<String>) : [];

		var temp2 = Reflect.field(obj, "priority_song_locations");
		prioritySongLocations = temp2 != null ? (temp2 : Array<String>) : [];

		var temp3 = Reflect.field(obj, "always_include_songs");
		alwaysIncludeSongs = temp3 != null ? (temp3 : Array<String>) : [];

		var temp4 = Reflect.field(obj, "potential_victory_songs");
		potentialVictorySongs = temp4 != null ? (temp4 : Array<String>) : [];

		var temp5 = Reflect.field(obj, "extra_starting_songs");
		extraStartingSongs = temp5 != null ? (temp5 : Array<String>) : [];

		var temp6 = Reflect.field(obj, "local_songs");
		localSongs = temp6 != null ? (temp6 : Array<String>) : [];

		var temp7 = Reflect.field(obj, "non_local_songs");
		nonLocalSongs = temp7 != null ? (temp7 : Array<String>) : [];

		var blocks:Array<Dynamic> = Reflect.field(obj, "plando_blocks") ?? [];
		plandoBlocks = [];
		for (blockData in blocks)
		{
			var block = new PlandoBlock();
			block.fromJSON(blockData);
			plandoBlocks.push(block);
		}
	}

	/**
	 * Check if plando data is empty
	 */
	public function isEmpty():Bool
	{
		return excludeSongLocations.length == 0
			&& prioritySongLocations.length == 0
			&& alwaysIncludeSongs.length == 0
			&& potentialVictorySongs.length == 0
			&& extraStartingSongs.length == 0
			&& localSongs.length == 0
			&& nonLocalSongs.length == 0
			&& plandoBlocks.length == 0;
	}

	/**
	 * Clear all plando data
	 */
	public function clear():Void
	{
		excludeSongLocations = [];
		prioritySongLocations = [];
		alwaysIncludeSongs = [];
		potentialVictorySongs = [];
		extraStartingSongs = [];
		localSongs = [];
		nonLocalSongs = [];
		plandoBlocks = [];
	}
}

/**
 * Represents a single Plando Block for item placement
 * Follows Archipelago plando structure
 */
class PlandoBlock
{
	public var location:String = "";
	public var item:String = "";
	public var player:String = "";

	public function new(?location:String, ?item:String, ?player:String)
	{
		this.location = location ?? "";
		this.item = item ?? "";
		this.player = player ?? "";
	}

	public function toJSON():Dynamic
	{
		return {
			location: location,
			item: item,
			player: player
		};
	}

	public function fromJSON(obj:Dynamic):Void
	{
		location = Reflect.field(obj, "location") ?? "";
		item = Reflect.field(obj, "item") ?? "";
		player = Reflect.field(obj, "player") ?? "";
	}
}
