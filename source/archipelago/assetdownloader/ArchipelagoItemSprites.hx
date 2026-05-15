package archipelago.assetdownloader;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/**
 * Main interface for Archipelago asset sprite management.
 * Handles downloading, caching, and retrieving game icons and item sprites.
 *
 * Usage:
 * 1. Create instance: var sprites = new ArchipelagoItemSprites(aliasConversionFunction);
 * 2. Prepare assets: sprites.prepareGameAssets("FinalFantasyVI");
 * 3. Get sprite: sprites.tryGetCustomAsset(location, "MyGame", true, true, result);
 */
class ArchipelagoItemSprites
{
	public static final ALIASES_FILE_NAME = "aliases.json";

	private var nameCleaner:NameCleaner;
	private var assetService:AssetService;
	private var spritesFolder:String;

	// Sprite lookup dictionaries
	private var spritesByGame:Map<String, Array<ItemSprite>>;
	private var spritesByItemName:Map<String, Array<ItemSprite>>;
	private var spritesByGameByItemName:Map<String, Map<String, ItemSprite>>;

	// Alias conversion function
	private var aliasConversion:String -> ItemSpriteAliases;

	/**
	 * Initializes the sprite manager
	 * @param aliasConversionFunction Function to convert JSON string to ItemSpriteAliases
	 * @param timeUntilRedownloadAssets How long before re-downloading (in seconds). null = never re-download
	 */
	public function new(aliasConversionFunction:String -> ItemSpriteAliases, timeUntilRedownloadAssets:Null<Float> = null)
	{
		nameCleaner = new NameCleaner();
		assetService = new AssetService(timeUntilRedownloadAssets);
		spritesFolder = AssetDownloaderPaths.getCustomAssetsDirectory();
		aliasConversion = aliasConversionFunction;

		loadCustomSprites();
	}

	/**
	 * Checks if this system has sprites for a given game
	 */
	public function hasSpritesForGame(gameName:String):Bool
	{
		var cleanGame = nameCleaner.cleanName(gameName);
		return spritesByGame.exists(cleanGame) || spritesByGameByItemName.exists(cleanGame);
	}

	/**
	 * Loads all existing custom sprites from the cache directory
	 */
	private function loadCustomSprites():Void
	{
		spritesByGame = new Map();
		spritesByItemName = new Map();
		spritesByGameByItemName = new Map();

		if (!FileSystem.exists(spritesFolder))
		{
			FileSystem.createDirectory(spritesFolder);
			return;
		}

		try
		{
			var gameSubfolders = FileSystem.readDirectory(spritesFolder);

			for (gameSubfolder in gameSubfolders)
			{
				var fullPath = haxe.io.Path.join([spritesFolder, gameSubfolder]);
				if (FileSystem.isDirectory(fullPath))
				{
					registerGameSprites(fullPath);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error loading custom sprites: ${e}');
		}
	}

	/**
	 * Registers all sprites in a game subfolder
	 */
	public function registerGameSprites(gameSubfolder:String):Void
	{
		try
		{
			var aliases = getAliases(gameSubfolder);
			var gameName = registerDirectSprites(gameSubfolder);

			if (gameName != null && gameName.length > 0)
			{
				registerAliasSprites(aliases, gameName);
			}
		}
		catch (e:Dynamic)
		{
			trace('Error registering game sprites: ${e}');
		}
	}

	/**
	 * Loads aliases from aliases.json if it exists
	 */
	private function getAliases(gameSubfolder:String):ItemSpriteAliases
	{
		try
		{
			var aliasesFile = haxe.io.Path.join([gameSubfolder, ALIASES_FILE_NAME]);

			if (FileSystem.exists(aliasesFile))
			{
				var content = File.getContent(aliasesFile);
				return aliasConversion(content);
			}
		}
		catch (e:Dynamic)
		{
			trace('Error loading aliases from ${gameSubfolder}: ${e}');
		}

		return new ItemSpriteAliases();
	}

	/**
	 * Registers direct sprite files in a folder
	 */
	private function registerDirectSprites(spritesGameFolder:String):String
	{
		var gameName = "";

		try
		{
			var files = getAllPngFiles(spritesGameFolder);

			for (file in files)
			{
				registerSprite(file);
				var sprite = new ItemSprite(file);
				if (gameName.length == 0)
				{
					gameName = sprite.game;
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error registering direct sprites: ${e}');
		}

		return gameName;
	}

	/**
	 * Gets all PNG files recursively from a directory
	 */
	private function getAllPngFiles(dir:String):Array<String>
	{
		var results:Array<String> = [];

		try
		{
			var files = FileSystem.readDirectory(dir);

			for (file in files)
			{
				var fullPath = haxe.io.Path.join([dir, file]);

				if (FileSystem.isDirectory(fullPath))
				{
					results = results.concat(getAllPngFiles(fullPath));
				}
				else if (file.endsWith(".png"))
				{
					results.push(fullPath);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error reading directory ${dir}: ${e}');
		}

		return results;
	}

	/**
	 * Registers sprites based on aliases
	 */
	private function registerAliasSprites(aliases:ItemSpriteAliases, gameName:String):Void
	{
		for (alias in aliases.aliases)
		{
			for (aliasItemName in alias.itemNames)
			{
				var cleanGame = nameCleaner.cleanName(gameName);
				var cleanAliasName = nameCleaner.cleanName(alias.aliasName);

				if (spritesByGameByItemName.exists(cleanGame))
				{
					var gameMap = spritesByGameByItemName.get(cleanGame);
					if (gameMap.exists(cleanAliasName))
					{
						var aliasSprite = gameMap.get(cleanAliasName);
						registerSpriteInternal(gameName, aliasItemName, aliasSprite, false);
					}
				}
			}
		}
	}

	/**
	 * Registers a sprite by file path
	 */
	public function registerSprite(file:String):Void
	{
		try
		{
			var sprite = new ItemSprite(file);
			registerSpriteInternal(sprite.game, sprite.item, sprite, true);
		}
		catch (e:Dynamic)
		{
			trace('Error registering sprite from file: ${e}');
		}
	}

	/**
	 * Registers a sprite with game and item names (internal helper)
	 */
	private function registerSpriteInternal(game:String, item:String, sprite:ItemSprite, overrideIfExists:Bool):Void
	{
		var cleanGame = nameCleaner.cleanName(game);
		var cleanItem = nameCleaner.cleanName(item);

		// Ensure maps exist
		if (!spritesByGame.exists(cleanGame))
		{
			spritesByGame.set(cleanGame, []);
		}

		if (!spritesByItemName.exists(cleanItem))
		{
			spritesByItemName.set(cleanItem, []);
		}

		if (!spritesByGameByItemName.exists(cleanGame))
		{
			spritesByGameByItemName.set(cleanGame, new Map());
		}

		// Add to lookup maps
		spritesByGame.get(cleanGame).push(sprite);
		spritesByItemName.get(cleanItem).push(sprite);

		var gameMap = spritesByGameByItemName.get(cleanGame);
		if (!gameMap.exists(cleanItem) || overrideIfExists)
		{
			gameMap.set(cleanItem, sprite);
		}
	}

	/**
	 * Prepares assets for a game (downloads if needed)
	 */
	public function prepareGameAssets(gameName:String):Void
	{
		assetService.tryDownloadGameAssets(gameName, this, false);
	}

	/**
	 * Tries to get a custom asset sprite with fallback logic
	 * @param location Asset location information
	 * @param myGameName Current game name (for fallback)
	 * @param fallbackOnDifferentGameAsset Try different game's assets
	 * @param fallbackOnGenericGameAsset Use generic game sprite
	 * @return Array with [success:Bool, sprite:ItemSprite] or null on failure
	 */
	public function tryGetCustomAsset(
		location:IAssetLocation,
		myGameName:String,
		fallbackOnDifferentGameAsset:Bool,
		fallbackOnGenericGameAsset:Bool):Null<ItemSprite>
	{
		// Prepare both games asynchronously
		assetService.tryDownloadGameAssets(myGameName, this, true);

		if (location != null)
		{
			assetService.tryDownloadGameAssets(location.gameName, this, true);
		}
		else
		{
			return null;
		}

		var myGame = nameCleaner.cleanName(myGameName);
		var game = nameCleaner.cleanName(location.gameName);
		var item = nameCleaner.cleanName(location.itemName);

		// Try exact match: location's game + item
		if (spritesByGameByItemName.exists(game))
		{
			var itemsInCorrectGame = spritesByGameByItemName.get(game);
			if (itemsInCorrectGame.exists(item))
			{
				return itemsInCorrectGame.get(item);
			}
		}

		// Try fallback: my game + item
		if (fallbackOnDifferentGameAsset && spritesByGameByItemName.exists(myGame))
		{
			var itemsInMyGame = spritesByGameByItemName.get(myGame);
			if (itemsInMyGame.exists(item))
			{
				return itemsInMyGame.get(item);
			}
		}

		// Try fallback: any game with matching item
		if (fallbackOnDifferentGameAsset && spritesByItemName.exists(item))
		{
			var spritesWithCorrectName = spritesByItemName.get(item);
			if (spritesWithCorrectName.length > 0)
			{
				var random = new haxe.ds.ObjectMap<Dynamic, Dynamic>();
				var seed = location.getSeed();
				var index = seed % spritesWithCorrectName.length;
				return spritesWithCorrectName[index];
			}
		}

		// Try generic fallback: location's game + empty item
		if (fallbackOnGenericGameAsset && spritesByGameByItemName.exists(game))
		{
			var itemsInCorrectGame = spritesByGameByItemName.get(game);
			if (itemsInCorrectGame.exists(""))
			{
				return itemsInCorrectGame.get("");
			}
		}

		return null;
	}
}

/**
 * Interface that items must implement to be used with sprite lookup
 */
interface IAssetLocation
{
	function getSeed():Int;
	var gameName(get, null):String;
	var itemName(get, null):String;
}
