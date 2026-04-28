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
 * Substate for selecting LOCAL and NON-LOCAL songs
 * Prevents songs from being in both lists simultaneously
 */
class APPlandoLocalSongsSubstate extends MusicBeatSubstate
{
	private var localSongs:Array<String> = [];
	private var nonLocalSongs:Array<String> = [];
	private var plandoData:PlandoData;
	private var allSongs:Array<{name: String, mod: String}> = [];
	
	private var currentMode:Int = 0; // 0 = local, 1 = non-local
	private var hoveredIndex:Int = -1;
	private var songButtons:Array<SongSelectionButton> = [];
	
	private var background:FlxSprite;
	private var modeDisplay:FlxText;
	private var selectedDisplay:FlxText;
	private var instructionText:FlxText;
	
	private static inline var GRID_COLS:Int = 3;
	private static inline var GRID_ROWS:Int = 4;
	private static inline var CELL_WIDTH:Float = 220;
	private static inline var CELL_HEIGHT:Float = 160;
	private static inline var GRID_START_X:Float = 60;
	private static inline var GRID_START_Y:Float = 200;
	
	public function new(plandoData:PlandoData, ?startingLocal:Array<String>, ?startingNonLocal:Array<String>)
	{
		super();
		this.plandoData = plandoData;
		if (startingLocal != null)
			localSongs = startingLocal.copy();
		if (startingNonLocal != null)
			nonLocalSongs = startingNonLocal.copy();
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
		var titleText = new FlxText(20, 15, FlxG.width - 40, "SELECT LOCAL / NON-LOCAL SONGS");
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);
		
		// Mode display
		modeDisplay = new FlxText(20, 60, FlxG.width - 40, "Mode: LOCAL SONGS | Press TAB to switch");
		modeDisplay.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER);
		add(modeDisplay);
		
		// Instructions
		instructionText = new FlxText(20, 85, FlxG.width - 40, 
			"Arrow Keys: Navigate | SPACE: Select | TAB: Switch Mode | Z/ENTER: Confirm | ESC/X: Cancel");
		instructionText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.YELLOW, CENTER);
		add(instructionText);
		
		// Create grid of song buttons
		createSongGrid();
		
		// Selected songs display
		selectedDisplay = new FlxText(20, FlxG.height - 100, FlxG.width - 40, 
			"Local: 0 | Non-Local: 0");
		selectedDisplay.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.LIME, LEFT, OUTLINE, FlxColor.BLACK);
		selectedDisplay.borderSize = 1;
		add(selectedDisplay);
		
		updateModeDisplay();
		updateSelectedDisplay();
	}
	
	private function loadSongsFromWeekData():Void
	{
		allSongs = [];
		var addedSongs:Map<String, Bool> = new Map();
		
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
								allSongs.push({name: songName, mod: modName});
								addedSongs.set(uniqueId, true);
							}
						}
					}
				}
			}
		}
		
		// Sort alphabetically
		allSongs.sort((a, b) -> {
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
			if (i >= allSongs.length) break;
			
			var col = i % GRID_COLS;
			var row = Math.floor(i / GRID_COLS);
			var x = GRID_START_X + (col * CELL_WIDTH);
			var y = GRID_START_Y + (row * CELL_HEIGHT);
			
			var song = allSongs[i];
			var button = new SongSelectionButton(x, y, CELL_WIDTH - 10, CELL_HEIGHT - 10, song.name, song.mod);
			add(button);
			songButtons.push(button);
		}
	}
	
	private function getSongDisplayName(song:{name:String, mod:String}):String
	{
		return song.mod.length > 0 ? song.name + " (" + song.mod + ")" : song.name;
	}
	
	private function updateModeDisplay():Void
	{
		var modeText = currentMode == 0 ? "LOCAL SONGS" : "NON-LOCAL SONGS";
		modeDisplay.text = "Mode: " + modeText + " | Press TAB to switch";
	}
	
	private function updateSelectedDisplay():Void
	{
		selectedDisplay.text = "Local: " + localSongs.length + " | Non-Local: " + nonLocalSongs.length;
	}
	
	private function updateButtonVisuals():Void
	{
		var currentList = currentMode == 0 ? localSongs : nonLocalSongs;
		
		for (i in 0...songButtons.length)
		{
			var button = songButtons[i];
			var song = allSongs[i];
			var displayName = getSongDisplayName(song);
			var isSelected = currentList.contains(displayName);
			var isHovered = (i == hoveredIndex);
			
			button.setSelected(isSelected);
			button.setHovered(isHovered);
		}
	}
	
	private function toggleSongSelection(index:Int):Void
	{
		if (index < 0 || index >= allSongs.length) return;
		
		var song = allSongs[index];
		var displayName = getSongDisplayName(song);
		
		var currentList = currentMode == 0 ? localSongs : nonLocalSongs;
		var otherList = currentMode == 0 ? nonLocalSongs : localSongs;
		
		// Remove from other list if present (mutual exclusion)
		var otherIdx = otherList.indexOf(displayName);
		if (otherIdx >= 0)
		{
			otherList.splice(otherIdx, 1);
		}
		
		// Toggle in current list
		var existingIdx = currentList.indexOf(displayName);
		if (existingIdx >= 0)
		{
			currentList.splice(existingIdx, 1);
		}
		else
		{
			currentList.push(displayName);
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
		// Switch mode with TAB
		if (FlxG.keys.justPressed.TAB)
		{
			currentMode = 1 - currentMode;
			hoveredIndex = -1;
			updateModeDisplay();
		}
		
		// Arrow key navigation
		if (controls.pressed('ui_left'))
		{
			hoveredIndex = Std.int(Math.max(0, hoveredIndex - 1));
		}
		else if (controls.pressed('ui_right'))
		{
			hoveredIndex = Std.int(Math.min(allSongs.length - 1, hoveredIndex + 1));
		}
		else if (controls.pressed('ui_up'))
		{
			hoveredIndex = Std.int(Math.max(0, hoveredIndex - GRID_COLS));
		}
		else if (controls.pressed('ui_down'))
		{
			hoveredIndex = Std.int(Math.min(allSongs.length - 1, hoveredIndex + GRID_COLS));
		}
		
		// Initialize selection if not set
		if (hoveredIndex < 0 && allSongs.length > 0)
			hoveredIndex = 0;
		
		// Select with space
		if (controls.justPressed('accept'))
		{
			if (hoveredIndex >= 0 && hoveredIndex < allSongs.length)
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
		plandoData.localSongs = localSongs.copy();
		plandoData.nonLocalSongs = nonLocalSongs.copy();
		close();
	}
}
