package archipelago.assetdownloader;

/**
 * Represents an alias mapping for item sprites.
 * Maps an alias name to multiple item names.
 */
class ItemSpriteAlias
{
	public var aliasName:String = "";
	public var itemNames:Array<String> = [];

	public function new() {}
}

/**
 * Container for multiple item sprite aliases.
 * Used for loading alias configurations from JSON.
 */
class ItemSpriteAliases
{
	public var aliases:Array<ItemSpriteAlias> = [];

	public function new() {}
}
