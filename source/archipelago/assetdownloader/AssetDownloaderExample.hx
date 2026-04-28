package archipelago.assetdownloader;

/**
 * Example implementation showing how to integrate the asset downloader
 * into Archipelago gameplay.
 */
class AssetDownloaderExample
{
	// This is a reference example - adapt to your needs

	/**
	 * Example: Create a simple item class that implements IAssetLocation
	 */
	public static function exampleItemImplementation()
	{
		// Your item class should look like this:
		/*
		class MyAPItem implements IAssetLocation
		{
			public var gameName(get, null):String;
			public var itemName(get, null):String;

			private var _gameName:String;
			private var _itemName:String;
			private var itemId:Int;

			public function new(game:String, item:String, id:Int)
			{
				_gameName = game;
				_itemName = item;
				itemId = id;
			}

			function get_gameName():String return _gameName;
			function get_itemName():String return _itemName;

			public function getSeed():Int return itemId;
		}
		*/
	}

	/**
	 * Example: JSON alias parsing function
	 */
	public static function parseAliasesJson(json:String):ItemSpriteAliases
	{
		try
		{
			var data = haxe.Json.parse(json);
			var aliases = new ItemSpriteAliases();

			if (Reflect.hasField(data, "aliases"))
			{
				var aliasArray:Array<Dynamic> = Reflect.field(data, "aliases");

				for (aliasData in aliasArray)
				{
					var alias = new ItemSpriteAlias();

					if (Reflect.hasField(aliasData, "aliasName"))
					{
						alias.aliasName = Reflect.field(aliasData, "aliasName");
					}

					if (Reflect.hasField(aliasData, "itemNames"))
					{
						var itemNames:Array<Dynamic> = Reflect.field(aliasData, "itemNames");
						for (itemName in itemNames)
						{
							alias.itemNames.push(cast itemName);
						}
					}

					aliases.aliases.push(alias);
				}
			}

			return aliases;
		}
		catch (e:Dynamic)
		{
			trace('Error parsing aliases JSON: ${e}');
			return new ItemSpriteAliases();
		}
	}

	/**
	 * Example: Using the sprite manager in a state
	 */
	public static function exampleUsageInState()
	{
		/*
		// In your APGameState or similar:

		private var spriteManager:ArchipelagoItemSprites;

		override public function create():Void
		{
			super.create();

			// Initialize sprite manager with alias parser
			spriteManager = new ArchipelagoItemSprites(
				parseAliasesJson,
				24 * 60 * 60  // Re-download every 24 hours
			);

			// Prepare assets for games you expect to encounter
			spriteManager.prepareGameAssets("FinalFantasyVI");
			spriteManager.prepareGameAssets("Zelda");
			spriteManager.prepareGameAssets("SuperMetroid");
		}

		// Helper function to get sprite for an item
		public function getItemSprite(item:IAssetLocation):Null<ItemSprite>
		{
			return spriteManager.tryGetCustomAsset(
				item,
				"Mixtape",  // Your game name for fallback
				true,       // Allow fallback to different game
				true        // Allow generic sprite fallback
			);
		}

		// Example: Display item sprite in UI
		function displayItemSprite(item:IAssetLocation):Void
		{
			var sprite = getItemSprite(item);

			if (sprite != null)
			{
				// Load and display the sprite
				var graphic = Paths.image(sprite.filePath);
				// Use graphic in your UI...
			}
			else
			{
				// Use placeholder or default icon
				var placeholder = Paths.image('ui/default_item');
				// Use placeholder...
			}
		}
		*/
	}

	/**
	 * Example: Integrating with trap notifications
	 */
	public static function exampleTrapNotification()
	{
		/*
		// In your trap handling code:

		function handleTrap(trap:APTrap):Void
		{
			var trapItem = new APItem(trap.gameName, trap.itemName, trap.itemId);
			var sprite = spriteManager.tryGetCustomAsset(trapItem, "Mixtape", true, true);

			if (sprite != null)
			{
				// Show notification with trap icon
				showTrapNotification(sprite.filePath, trap.description);
			}
			else
			{
				// Show notification with text only
				showTrapNotification(null, trap.description);
			}
		}
		*/
	}

	/**
	 * Example: Handling missing sprites gracefully
	 */
	public static function exampleErrorHandling()
	{
		/*
		// The system handles errors gracefully:

		function getItemIconPath(game:String, item:String):String
		{
			var location = new APItem(game, item);
			var sprite = spriteManager.tryGetCustomAsset(location, "Mixtape", true, true);

			if (sprite != null)
			{
				// Use downloaded icon
				return sprite.filePath;
			}
			else
			{
				// Use fallback icon
				return "assets/images/ui/default_icon.png";
			}
		}
		*/
	}

	/**
	 * Example: Check if system has sprites for a game before preparing
	 */
	public static function examplePreflightCheck()
	{
		/*
		function checkAndPrepareGame(gameName:String):Void
		{
			if (spriteManager.hasSpritesForGame(gameName))
			{
				trace('Already have sprites for ${gameName}');
			}
			else
			{
				trace('Downloading sprites for ${gameName}...');
				spriteManager.prepareGameAssets(gameName);
			}
		}
		*/
	}
}
