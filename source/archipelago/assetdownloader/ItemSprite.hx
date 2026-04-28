package archipelago.assetdownloader;

import flixel.FlxSprite;
import haxe.io.Path;
import sys.io.File;

/**
 * Represents a single asset sprite with game and item name information.
 * Parses file paths to extract game and item names.
 * Supports conversion to FlxSprite and FunkinSprite.
 */
class ItemSprite
{
	public var game:String;
	public var item:String;
	public var filePath:String;
	public var fileName:String;

	public function new(filePath:String)
	{
		this.filePath = filePath;

		// Extract filename from path
		var path = new Path(filePath);
		fileName = path.file;

		// Parse game and item from filename (format: game_item.png or just game.png)
		var parts = fileName.split("_");

		if (parts.length == 1)
		{
			game = parts[0];
			item = "";
		}
		else
		{
			game = parts[0];
			// Join remaining parts in case item name has underscores
			item = parts.slice(1).join("_");
		}
	}

	/**
	 * Converts this sprite to a FlxSprite with the item texture
	 */
	public function toFlxSprite(x:Float = 0, y:Float = 0):FlxSprite
	{
		var sprite = new FlxSprite(x, y);
		try
		{
			// Load directly from file path (not through Paths system)
			sprite.loadGraphic(filePath);
		}
		catch (e:Dynamic)
		{
			trace('Error loading sprite as FlxSprite from ${filePath}: ${e}');
		}
		return sprite;
	}

	/**
	 * Converts this sprite to a FunkinSprite with the item texture
	 */
	public function toFunkinSprite(x:Float = 0, y:Float = 0):objects.FunkinSprite
	{
		var sprite = new objects.FunkinSprite(x, y);
		try
		{
			// Load directly from file path (not through Paths system)
			sprite.loadGraphic(filePath);
		}
		catch (e:Dynamic)
		{
			trace('Error loading sprite as FunkinSprite from ${filePath}: ${e}');
		}
		return sprite;
	}

	/**
	 * Gets the image path for use with Paths.image()
	 */
	public function getImagePath():String
	{
		return filePath;
	}

	/**
	 * Static helper to parse game and item names from a filename
	 */
	public static function getGameAndItem(fileName:String):{game:String, item:String}
	{
		var parts = fileName.split("_");

		if (parts.length == 1)
		{
			return {game: parts[0], item: ""};
		}

		var game = parts[0];
		var item = parts.slice(1).join("_");

		return {game: game, item: item};
	}
}
