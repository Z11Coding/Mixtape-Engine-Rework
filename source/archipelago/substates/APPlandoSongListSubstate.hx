package archipelago.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import archipelago.PlandoData;
import archipelago.substates.SongSelectionButton;
import backend.Controls;
import backend.MusicBeatSubstate;
import backend.Paths;
import backend.WeekData;

/**
 * Substate for selecting songs for plando configuration
 * Displays grid of songs (4x3), supports mouse and keyboard input
 */
class APPlandoSongListSubstate extends MusicBeatSubstate
{
	private var selectedSongs:Array<String> = [];
	private var plandoData:PlandoData;
	private var fieldName:String;
	private var songList:Array<{name: String, mod: String}> = [];
	private var songButtons:Array<SongSelectionButton> = [];
	private var hoveredIndex:Int = -1;
	private var background:FlxSprite;
	private var selectedDisplay:FlxText;
	private var instructionText:FlxText;

	private static inline var GRID_COLS:Int = 3;
	private static inline var GRID_ROWS:Int = 4;
	private static inline var CELL_WIDTH:Float = 220;
	private static inline var CELL_HEIGHT:Float = 160;
	private static inline var GRID_START_X:Float = 60;
	private static inline var GRID_START_Y:Float = 200;

	public function new(plandoData:PlandoData, fieldName:String, ?startingSelection:Array<String>)
	{
		super();
		this.plandoData = plandoData;
		this.fieldName = fieldName;
		if (startingSelection != null)
			selectedSongs = startingSelection.copy();
	}


	override function create()
	{
		super.create();

		// Full-screen semi-transparent background
		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0.75;
		add(background);

		// Load songs from WeekData
		loadSongsFromWeekData();

		// Title
		var titleText = new FlxText(20, 15, FlxG.width - 40, "SELECT SONGS FOR PLANDO");
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Instructions
		instructionText = new FlxText(20, 60, FlxG.width - 40,
			"Arrow Keys: Navigate | SPACE: Select | Z/ENTER: Confirm | ESC/X: Cancel | Mouse: Click to select");
		instructionText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, CENTER);
		add(instructionText);

		// Create grid of song buttons
		createSongGrid();

		// Selected songs display
		selectedDisplay = new FlxText(20, FlxG.height - 100, FlxG.width - 40, "Selected Songs: None");
		selectedDisplay.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, LEFT, OUTLINE, FlxColor.BLACK);
		selectedDisplay.borderSize = 1;
		add(selectedDisplay);

		updateSelectedDisplay();
	}

	private function loadSongsFromWeekData():Void
	{
		songList = [];
		var addedSongs:Map<String, Bool> = new Map(); // Prevent duplicates

		if (WeekData.weeksList != null)
		{
			for (weekName in WeekData.weeksList)
			{
				if (WeekData.weeksLoaded.exists(weekName))
				{
					var week = WeekData.weeksLoaded.get(weekName);
					if (week != null && week.songs != null)
					{
						for (songName in week.songs)
						{
							var modName = (week.folder != null && week.folder.length > 0) ? week.folder : "";
							var uniqueId = songName + "|" + modName;

							if (!addedSongs.exists(uniqueId))
							{
								songList.push({name: songName, mod: modName});
								addedSongs.set(uniqueId, true);
							}
						}
					}
				}
			}
		}

		// Sort alphabetically
		songList.sort((a, b) -> {
			var aLower = (a.mod.length > 0 ? a.name + " (" + a.mod + ")" : a.name).toLowerCase();
			var bLower = (b.mod.length > 0 ? b.name + " (" + b.mod + ")" : b.name).toLowerCase();
			return aLower < bLower ? -1 : (aLower > bLower ? 1 : 0);
		});
	}

	private function createSongGrid():Void
	{
		songButtons = [];

		var maxIndex = GRID_COLS * GRID_ROWS;
		for (i in 0...maxIndex)
		{
			if (i >= songList.length) break;

			var col = i % GRID_COLS;
			var row = Math.floor(i / GRID_COLS);
			var x = GRID_START_X + (col * CELL_WIDTH);
			var y = GRID_START_Y + (row * CELL_HEIGHT);

			var song = songList[i];
			var button = new SongSelectionButton(x, y, CELL_WIDTH - 10, CELL_HEIGHT - 10, song.name, song.mod);
			add(button);
			songButtons.push(button);
		}
	}

	private function getSongDisplayName(song:{name:String, mod:String}):String
	{
		return song.mod.length > 0 ? song.name + " (" + song.mod + ")" : song.name;
	}

	private function updateSelectedDisplay():Void
	{
		if (selectedSongs.length == 0)
		{
			selectedDisplay.text = "Selected Songs: None";
		}
		else
		{
			selectedDisplay.text = "Selected Songs (" + selectedSongs.length + "): " + selectedSongs.join(" | ");
		}
	}

	private function updateButtonVisuals():Void
	{
		for (i in 0...songButtons.length)
		{
			var button = songButtons[i];
			var song = songList[i];
			var displayName = getSongDisplayName(song);
			var isSelected = selectedSongs.contains(displayName);
			var isHovered = (i == hoveredIndex);

			button.setSelected(isSelected);
			button.setHovered(isHovered);
		}
	}

	private function toggleSongSelection(index:Int):Void
	{
		if (index < 0 || index >= songList.length) return;

		var song = songList[index];
		var displayName = getSongDisplayName(song);

		var existingIdx = selectedSongs.indexOf(displayName);
		if (existingIdx >= 0)
		{
			selectedSongs.splice(existingIdx, 1);
		}
		else
		{
			selectedSongs.push(displayName);
		}

		updateSelectedDisplay();
		updateButtonVisuals();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		handleKeyboardInput();
		handleMouseInput();
		updateButtonVisuals();
	}

	private function handleKeyboardInput():Void
	{
		// Arrow key navigation
		if (controls.pressed('ui_left'))
		{
			hoveredIndex = Std.int(Math.max(0, hoveredIndex - 1));
		}
		else if (controls.pressed('ui_right'))
		{
			hoveredIndex = Std.int(Math.min(songList.length - 1, hoveredIndex + 1));
		}
		else if (controls.pressed('ui_up'))
		{
			hoveredIndex = Std.int(Math.max(0, hoveredIndex - GRID_COLS));
		}
		else if (controls.pressed('ui_down'))
		{
			hoveredIndex = Std.int(Math.min(songList.length - 1, hoveredIndex + GRID_COLS));
		}

		// Initialize selection if not set
		if (hoveredIndex < 0 && songList.length > 0)
			hoveredIndex = 0;

		// Select with space
		if (controls.justPressed('accept'))
		{
			if (hoveredIndex >= 0 && hoveredIndex < songList.length)
				toggleSongSelection(hoveredIndex);
		}

		// Confirm
		if (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER)
		{
			onConfirm();
		}

		// Cancel
		if (controls.justPressed('back'))
		{
			close();
		}
	}

	private function handleMouseInput():Void
	{
		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;

		hoveredIndex = -1;

		for (i in 0...songButtons.length)
		{
			var button = songButtons[i];
			if (button.overlapsPoint(FlxG.mouse.getWorldPosition()))
			{
				hoveredIndex = i;

				if (FlxG.mouse.justPressed)
				{
					toggleSongSelection(i);
				}
			}
		}
	}

	private function onConfirm():Void
	{
		// Update the correct field in plandoData based on fieldName
		switch(fieldName)
		{
			case "excludeSongLocations":
				plandoData.excludeSongLocations = selectedSongs.copy();
			case "prioritySongLocations":
				plandoData.prioritySongLocations = selectedSongs.copy();
			case "alwaysIncludeSongs":
				plandoData.alwaysIncludeSongs = selectedSongs.copy();
			case "potentialVictorySongs":
				plandoData.potentialVictorySongs = selectedSongs.copy();
			case "extraStartingSongs":
				plandoData.extraStartingSongs = selectedSongs.copy();
		}
		close();
	}
}

