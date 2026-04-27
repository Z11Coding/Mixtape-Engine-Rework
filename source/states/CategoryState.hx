package states;

#if ARCHIPELAGO_ALLOWED
import archipelago.APEntryState;
#end

import backend.WeekData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import objects.AudioCircleDisplay;
import states.freeplay.VSliceFreeplayState.FreeplayStateParams;
import yutautil.ChanceSelector.Chance;

using yutautil.CollectionUtils;

typedef Category = {
	var name:String;
	var transition:Void -> Void;
	var isLocked:Bool;
}

class CategoryState extends MusicBeatState
{
	var circleoffun:AudioCircleDisplay;

	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	public var menuItems:Array<String> = [
		"All", "Base", "Erect", "Pico", "Playlists", "Music Player"
	];
	private var showMods:Bool = true;
	private var showSecrets:Bool = true;
	private var showSpecial:Bool = true;
	private var showAll:Bool = true;
	private var softCoded:Bool = true;

	//I'll softcode this eventually
	public var menuLocks:Array<Bool> = [
		false, false, false, false, false, false
	];
	public var specialOptions:Array<Void -> Void> = [
		//function() { FlxG.switchState(new FreeplayState()); }
	];

	private var hhhhhh:Bool = true;

	public static var loadWeekForce:String = null;
	public var catMode:String = ClientPrefs.data.showMods ? "Mods" : "Categories";

	public var showModsAsCategories:Bool = ClientPrefs.data.showMods;

	// Legacy Lua settings support
	public static var legacyLuaMode:options.legacylua.LegacyLuaCategoryState.LegacyLuaSettingsMode = null;

	private static var curSelected:Int = 0;
	public static var instaFreeplay:Bool = false;
	public static var freeplayStuff:FreeplayStateParams = {fromResults: null, fromCharSelect: null};

	//if you have em, put em here
	//and yes, this is the exact code from titlestate, and?
	var easterEggKeys:Array<String> = ['speciallilbaby'];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';

	var rightOption:String = 'mechanics';
	var rightItem:FlxSprite;

	// TODO: later, change to OneOfTwo<Array<String>, Map<String, Void -> Bool>> for categories, so it specifies that it must be one of the two types.

	public function new(?categories:Dynamic, ?showmods:Bool = true, ?showsecrets:Bool = true, ?showall:Bool = true, ?h:Bool = true, ?softCoded:Bool = true, ?showspecial:Bool = true) {
		super();
		this.softCoded = softCoded;
		if (categories != null) {
			menuItems = [];
			if (Std.is(categories, Array)) {
				menuItems = categories;
				menuLocks = [];
				for (i in 0...menuItems.length) {
					menuLocks.push(false);
				}
			} else if (categories.isMap()) {
				menuItems = [];
				menuLocks = [];
				for (key in categories.toIterable()) {
					menuItems.push(key);
					var lockValue = categories.get(key);
					if (Std.is(lockValue, Bool)) {
						menuLocks.push(lockValue);
					} else if (Std.is(lockValue, Void -> Bool)) {
						menuLocks.push(lockValue.toCallable()());
					} else {
						throw "CategoryState: 'categories' Map values must be either Bool or Void -> Bool!";
					}
				}
			} else if (Reflect.isObject(categories)) {
				var category:Category = cast categories;
				menuItems = [category.name];
				menuLocks = [category.isLocked];
				if (category.transition != null) {
					specialOptions.push(category.transition);
				} else {
					specialOptions.push(null);
				}
			} else {
				throw "CategoryState: 'categories' must be either an Array<String>, a Map<String, Void -> Bool>, or a Category!";
			}
		}
		this.showMods = showmods;
		this.showSecrets = showsecrets;
		this.showSpecial = showspecial;
		this.showAll = showall;
		this.hhhhhh = h;

		// Remove disabled categories from menuItems before validation
		if (!showAll && menuItems.contains("All")) {
			menuItems.remove("All");
		}
		if (!showMods && menuItems.contains("Mods")) {
			menuItems.remove("Mods");
		}
		if (!showSecrets && menuItems.contains("Secrets")) {
			menuItems.remove("Secrets");
		}
		if (!showSpecial && menuItems.contains("Special")) {
			menuItems.remove("Special");
		}
		if (!h && menuItems.contains("h?")) {
			menuItems.remove("h?");
		}

		// Now validate that disabled categories aren't still in the array
		if (menuItems.contains("All") && !showAll) {
			throw "CategoryState: 'All' category is disabled, yet it's in the menuItems array!";
		}
		if (menuItems.contains("Mods") && !showMods) {
			throw "CategoryState: 'Mods' category is disabled, yet it's in the menuItems array!";
		}
		if (menuItems.contains("Secrets") && !showSecrets) {
			throw "CategoryState: 'Secrets' category is disabled, yet it's in the menuItems array!";
		}
		if (menuItems.contains("Special") && !showSpecial) {
			throw "CategoryState: 'Special' category is disabled, yet it's in the menuItems array!";
		}
		// menuItems.mapIfBreak(it -> it.isEmpty(), throw "CategoryState: Empty strings are not allowed in the menuItems array!");

		if (menuItems.contains("h?")) {
			if (h) {
				throw "CategoryState: 'h?' category is reserved for a secret!";
			} else {
				throw "CategoryState: 'h?' category is disabled, yet it's in the menuItems array!";
			}
		}
	}

	override function create()
	{
		MemoryUtil.clearMajor();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Picking the Category", null);
		#end

		//menuItems = menuItems.filter(it -> (!it.isEmpty() && Alphabet.isValidText(it)));
		FlxTransitionableState.skipNextTransOut = false;

		if (showSecrets && (FlxG.save.data.gotIntoAnArgument || FlxG.save.data.gotbeatbattle || FlxG.save.data.gotbeatbattle2)) menuItems.insert(menuItems.length+1, "Secrets");

		if (showSpecial && (FlxG.save.data.specialbabyboy || FlxG.save.data.specialbabygirl)) menuItems.insert(menuItems.length+1, "Special");

		WeekData.reloadWeekFiles(false);
		var weeks:Array<WeekData> = [];
		for (i in 0...WeekData.weeksList.length) {
			weeks.push(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
		}
		var mods:Bool = false;

		if (catMode != 'Mods')
		for (i in 0...weeks.length) {
			//if(weekIsLocked(weeks[i].name)) continue;
			if (mods) break;

			var leWeek:WeekData = weeks[i];

			// trace('week: ${leWeek}');

			if (leWeek.category == null && showMods && catMode != 'Mods') {
				mods = true;
				if (!menuItems.contains("Mods")) {
					menuItems.push("Mods");
				}
				break;
			}
		}

		// Check for missing categories
		var existingCategories:Array<String> = [];
		for (item in menuItems) {
			existingCategories.push(item.toLowerCase());
		}

			if (softCoded && catMode != 'Mods')
		for (week in weeks) {
			if (week.category != null) {
				if (Std.is(week.category, String)) {
					var category:String = cast week.category;
					if (!existingCategories.contains(category.toLowerCase())) {
						menuItems.push(category);
					}
				} else if (Std.is(week.category, Array)) {
					var categories:Array<String> = cast week.category;
					for (cat in categories) {
						if (!existingCategories.contains(cat.toLowerCase())) {
							menuItems.push(cat);
						}
					}
				}
			}
		}


		// Remove duplicates from menuItems
		var filteredItems:Array<String> = [];
		for (item in menuItems) {
			if (!filteredItems.contains(item)) {
				filteredItems.push(item);
			}
		}
		menuItems = filteredItems;

		if (catMode == 'Mods') {
			menuItems = ["All"];
			for (mods in backend.Mods.parseList().enabled) {
				if (!menuItems.contains(mods)) {
					menuItems.push(mods);
				}
			}
		}



		// Move "All" to the front of menuItems
		if (menuItems.contains("All") && showAll) {
			menuItems.remove("All");
			menuItems.insert(0, "All");
		} else
		{ if (menuItems.contains("All")) menuItems.remove("All"); }




		// Main.simulateIntenseMaps();
		var hh:Array<Chance> = [
			{item: "h?", chance: 5}, // 5% chance to add "h?"
			{item: "no", chance: 95} // 95% chance to do nothing
		];

		Cursor.show();
		Cursor.cursorMode = Default;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.color = FlxColor.PURPLE;
		bg.scrollFactor.set();
		add(bg);

		try {
			circleoffun = new AudioCircleDisplay(FlxG.sound.music, FlxG.width/2, FlxG.height/2, Std.int(FlxG.width/2), Std.int(FlxG.height/2), 420, 5, FlxColor.PURPLE, 80, true, 1);
			circleoffun.scrollFactor.set();
			circleoffun.Rotate = true;
			//circleoffun.screenCenter();
			//circleoffun.y += 3000;
			add(circleoffun);
			/*FlxTween.tween(circleoffun, {y: circleoffun.y - 3000}, Conductor.crochet / 1300, {
				startDelay: 5,
				ease: FlxEase.quadOut
			});*/
		} catch(e:Dynamic) {
			trace("Failed to load AudioCircleDisplay, skipping...");
		}

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(20 * (!ClientPrefs.data.showMods ? i : 1), 320, menuItems[i], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			songText.ID = i;
			/*"""if (songText.letters[songText.letters.length-1].x > FlxG.width) {
				songText.scaleX = (songText.letters[songText.letters.length-1].x - FlxG.width) * 0.001;
			}"""*/
			grpMenuShit.add(songText);
			var isLocked:Bool = menuLocks[i];
			if (isLocked)
			{
				var lock:FlxSprite = new FlxSprite(songText.width + 10 + songText.x);
				lock.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = ClientPrefs.data.antialiasing;
				grpLocks.add(lock);
			}
		}

		if (rightOption != null && !(this is archipelago.APCategoryState) && !(this is options.legacylua.LegacyLuaCategoryState))
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}
		changeSelection();

		super.create();

		if (instaFreeplay) {
			FreeplayManager.openFreeplay(true, freeplayStuff);
			instaFreeplay = false;
		}

		MegaManager.conductor.addBeatCallback((curBeat:Int, backward:Bool) ->
		{
			FlxG.camera.zoom = zoomies;
			FlxTween.tween(FlxG.camera, {zoom: 1}, RConductor.crochet / 1300, {
				ease: FlxEase.quadOut
			});
		});
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		menuItem.loadGraphic(Paths.image('mechanicsMenu/MMod'));
		menuItem.setGraphicSize(Std.int(menuItem.width * 0.5));
		menuItem.updateHitbox();

		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		add(menuItem);
		return menuItem;
	}

	public function changeCategories(categories:Dynamic, showmods:Bool = true, showsecrets:Bool = true, showall:Bool = true, h:Bool = true, showspecial:Bool = true):Void {
		this.showMods = showmods;
		this.showSecrets = showsecrets;
		this.showSpecial = showspecial;
		this.showAll = showall;
		this.hhhhhh = h;
		this.softCoded = true;
		if (categories != null) {
			menuItems = [];
			if (Std.is(categories, Array)) {
				menuItems = categories;
				menuLocks = [];
				for (i in 0...menuItems.length) {
					menuLocks.push(false);
				}
			} else if (categories.isMap()) {
				menuItems = [];
				menuLocks = [];
				for (key in categories.toIterable()) {
					menuItems.push(key);
					var lockValue = categories.get(key);
					if (Std.is(lockValue, Bool)) {
						menuLocks.push(lockValue);
					} else if (Std.is(lockValue, Void -> Bool)) {
						menuLocks.push(lockValue.toCallable()());
					} else {
						throw "CategoryState: 'categories' Map values must be either Bool or Void -> Bool!";
					}
				}
			} else if (Reflect.isObject(categories)) {
				var category:Category = cast categories;
				menuItems = [category.name];
				menuLocks = [category.isLocked];
				if (category.transition != null) {
					specialOptions.push(category.transition);
				} else {
					specialOptions.push(null);
				}
			} else {
				throw "CategoryState: 'categories' must be either an Array<String>, a Map<String, Void -> Bool>, or a Category!";
			}
		} else {
			menuItems = ["All", "Base", "Erect", "Pico", "Playlists", "Music Player"];
			menuLocks = [false, false, false, false, false, false];
		}

		// Remove disabled categories from menuItems before validation
		if (!showAll && menuItems.contains("All")) {
			menuItems.remove("All");
		}
		if (!showMods && menuItems.contains("Mods")) {
			menuItems.remove("Mods");
		}
		if (!showSecrets && menuItems.contains("Secrets")) {
			menuItems.remove("Secrets");
		}
		if (!showSpecial && menuItems.contains("Special")) {
			menuItems.remove("Special");
		}
		if (!h && menuItems.contains("h?")) {
			menuItems.remove("h?");
		}

		// Now validate that disabled categories aren't still in the array
		if (menuItems.contains("All") && !showAll) {
			throw "CategoryState: 'All' category is disabled, yet it's in the menuItems array!";
		}
		if (menuItems.contains("Mods") && !showMods) {
			throw "CategoryState: 'Mods' category is disabled, yet it's in the menuItems array!";
		}
		if (menuItems.contains("Secrets") && !showSecrets) {
			throw "CategoryState: 'Secrets' category is disabled, yet it's in the menuItems array!";
		}
		if (menuItems.contains("Special") && !showSpecial) {
			throw "CategoryState: 'Special' category is disabled, yet it's in the menuItems array!";
		}
		// menuItems.mapIfBreak(it -> it.isEmpty(), throw "CategoryState: Empty strings are not allowed in the menuItems array!");

		if (menuItems.contains("h?")) {
			if (h) {
				throw "CategoryState: 'h?' category is reserved for a secret!";
			} else {
				throw "CategoryState: 'h?' category is disabled, yet it's in the menuItems array!";
			}
		}
		MusicBeatState.resetState();
	}

	var inDialogue:Bool = false;
	public var inFreeplay:Bool = false;
	override function update(elapsed:Float)
	{
		// If Legacy Lua settings are being edited, switch to Legacy Lua version
		if (options.legacylua.LegacyLuaSettingsState.inLegacyLuaSettingsMode && !(this is options.legacylua.LegacyLuaCategoryState)) {
			FlxG.switchState(new options.legacylua.LegacyLuaCategoryState());
			return;
		}

		if (inFreeplay && this.subState == null) {
			inFreeplay = false;
		}

		// Don't trigger resetState if we're in LegacyLua mode
		if (legacyLuaMode == null) {
			ClientPrefs.data.showMods && catMode != "Mods" || !ClientPrefs.data.showMods && catMode == "Mods"
				? MusicBeatState.resetState()
				: null;

			if (showModsAsCategories != ClientPrefs.data.showMods) {
				MusicBeatState.resetState();
			}
		}

			// trace('CategoryState: ' + catMode + ' | ' + showModsAsCategories + ' | ' + ClientPrefs.data.showMods);

		// Don't switch to AP versions if we're in LegacyLua mode or already in LegacyLua CategoryState
		if (archipelago.APEntryState.inArchipelagoMode && !(this is archipelago.APCategoryState) && legacyLuaMode == null && !(this is options.legacylua.LegacyLuaCategoryState)) {
			FlxG.switchState(new archipelago.APCategoryState(archipelago.APGameState.instance));
			return;
		}
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if(rightItem != null && FlxG.mouse.overlaps(rightItem))
		{
			Cursor.cursorMode = Pointer;
			if(FlxG.mouse.justPressed)
			{
				Cursor.cursorMode = Default;
				FlxG.switchState(new mechanics.MechanicMenu());
			}
		}

		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var back = controls.BACK;
		var controlsStrings:Array<String> = [];
		var shiftMult:Int = 1;
		if (!inDialogue)
		{
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;
			if (upP)
			{
				changeSelection(-shiftMult);
			}
			if (downP)
			{
				changeSelection(shiftMult);
			}

			// Don't allow CTRL if we're in freeplay or have VSliceFreeplayState as substate
			var hasVSliceSubstate = (subState != null && Std.isOfType(subState, states.freeplay.VSliceFreeplayState));

			if (FlxG.keys.justPressed.CONTROL && !inFreeplay && !hasVSliceSubstate)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				this.openSubState(new options.CategoriesSubstate());
			}

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							trace('YOOO! ' + word);
							FlxG.sound.play(Paths.sound('ToggleJingle'));

							if (word.toLowerCase() == 'speciallilbaby')
							{
								FlxG.switchState(new states.GodCode());
							}
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}

			var daSelected:String = menuItems[curSelected];
			loadWeekForce = daSelected.toLowerCase();
			if (accepted && menuLocks[curSelected])
			{
				accepted = false;
				FlxG.camera.shake(0.005, 0.5);
				FlxG.sound.play(Paths.sound("badnoise"+FlxG.random.int(1,3)), 1);
				grpMenuShit.forEach(function(item:FlxSprite)
				{
					if (item.ID == curSelected) FlxTween.color(item, 1, 0xffcc0002, 0xffffffff, {ease: FlxEase.sineIn});
				});
			}
			else if (accepted)
			{
				// Handle Legacy Lua override mode
				if (legacyLuaMode != null) {
					handleLegacyLuaOverride();
					return;
				}

				if (loadWeekForce == 'playlists') {
					MusicBeatState.switchState(new PlaylistState());
					return;
				}

				if (loadWeekForce == 'music player') {
					MusicBeatState.switchState(new MusicPlayerState());
					return;
				}

				// h?
				if (loadWeekForce == 'h?')
				{
					Achievements.unlock('h');
					Window.alert('h?', 'h?');
					Main.closeGame();
				}
				else if (curSelected < specialOptions.length && specialOptions[curSelected] != null)
				{
					specialOptions[curSelected]();
				}
				else
				{
					inFreeplay = true;
					FreeplayManager.openFreeplay(true);
				}
			}
		}
		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpMenuShit.members[lock.ID].y;
			lock.x = grpMenuShit.members[lock.ID].width + 10 + grpMenuShit.members[lock.ID].x;
		});
	}

	override function destroy()
	{
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected += change;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;
		var bullShit:Int = 0;
		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));
			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function handleLegacyLuaOverride():Void
	{
		switch (legacyLuaMode) {
			case options.legacylua.LegacyLuaCategoryState.LegacyLuaSettingsMode.MOD_SETTINGS:
				// Switch to LegacyLuaCategoryState for mod settings
				MusicBeatState.switchState(new options.legacylua.LegacyLuaCategoryState());
			case options.legacylua.LegacyLuaCategoryState.LegacyLuaSettingsMode.SONG_SETTINGS:
				// Go to freeplay for song overrides
				MusicBeatState.switchState(new options.legacylua.LegacyLuaFreeplayState());
		}
	}
}
