package states.editors;

import backend.ClientPrefs;
import backend.Difficulty;
import backend.Mods;
import backend.Paths;
import backend.Song;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.media.Sound;
import states.LoadingState;
import states.PlayState;
import states.editors.MasterEditorMenu;
import substates.Prompt;
import yutautil.ImprovedFileHandling;
#if sys
import sys.FileSystem;
import sys.io.File;
#end


#if DISCORD_ALLOWED
import backend.Discord.DiscordClient;
#end

class ChartCreatorMenuState extends MusicBeatState
{
	private var bg:FlxSprite;
	private var titleText:FlxText;

	// Input fields
	private var songNameInput:FlxInputText;
	private var instFileText:FlxText;
	private var difficultyInput:FlxInputText;

	// Dropdowns and controls
	private var modDropDown:FlxUIDropDownMenu;
	private var beatsPerSectionStepper:FlxUINumericStepper;
	private var timeSignatureCheckBox:FlxUICheckBox;
	private var timeSignatureNumeratorStepper:FlxUINumericStepper;
	private var timeSignatureDenominatorDropDown:FlxUIDropDownMenu;
	private var chartEditorDropDown:FlxUIDropDownMenu;
	private var bpmStepper:FlxUINumericStepper;
	private var metronomeButton:FlxUIButton;
	private var stopMetronomeButton:FlxUIButton;
	private var tapTempoButton:FlxUIButton;

	// Buttons
	private var instBrowseButton:FlxUIButton;
	private var addVocalsButton:FlxUIButton;
	private var createButton:FlxUIButton;
	private var backButton:FlxUIButton;
	private var loadCurrentSongButton:FlxUIButton;
	private var loadChartButton:FlxUIButton;
	private var loadAutosaveButton:FlxUIButton;
	private var previewButton:FlxUIButton;
	private var stopPreviewButton:FlxUIButton;
	private var songGoButton:FlxUIButton;
	private var difficultyGoButton:FlxUIButton;
	private var convertChart:FlxUIButton;

	// File paths
	private var selectedInstPath:String = "";
	private var selectedVocalsPaths:Array<String> = [];
	private var vocalsLabels:Array<String> = []; // Labels like "Player", "Opponent", etc.

	// Vocals UI management
	private var vocalsGroup:FlxTypedGroup<FlxSprite>;
	private var vocalsTexts:Array<FlxText> = [];
	private var vocalsRemoveButtons:Array<FlxUIButton> = [];
	private var vocalsInputs:Array<FlxInputText> = []; // Added missing variable
	private var vocalsScrollBg:FlxSprite;
	private var vocalsScrollY:Float;
	private var vocalsScrollMaxHeight:Float;
	private var vocalsScrollOffset:Float = 0; // Added missing variable
	private var currentVocalsIndex:Int = 0;

	// Audio preview and mini player
	private var previewInst:FlxSound;
	private var previewVocals:Array<FlxSound> = [];
	private var isPreviewPlaying:Bool = false;
	private var previewSeekBar:FlxSprite;
	private var previewSeekHandle:FlxSprite;
	private var previewTimeText:FlxText;
	private var previewVolumeSlider:FlxSprite;
	private var previewVolumeHandle:FlxSprite;
	private var previewVolume:Float = 0.7;
	private var isDraggingSeek:Bool = false;
	private var isDraggingVolume:Bool = false;

	// Metronome and BPM detection
	private var metronomeSound:FlxSound;
	private var isMetronomePlaying:Bool = false;
	private var metronomeTimer:FlxTimer;
	private var tapTimes:Array<Float> = [];
	private var lastTapTime:Float = 0;

	// Available mods
	private var availableMods:Array<String>;

	// File existence tracking
	private var hasExistingInst:Bool = false;
	private var hasExistingVocals:Bool = false;
	private var hasExistingChart:Bool = false;
	private var lastCheckedSong:String = "";
	private var lastCheckedDifficulty:String = "";
	private var lastCheckedMod:String = "";

	// File drop support
	private var dragDropOverlay:FlxSprite;
	private var dragDropText:FlxText;
	private var isDragging:Bool = false;

	// Confirmation dialog variables
	private var dialogBg:FlxSprite;
	private var dialogBox:FlxSprite;
	private var border:FlxSprite;
	private var messageText:FlxText;
	private var yesButton:FlxUIButton;
	private var noButton:FlxUIButton;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		forceCursor = true;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Chart Creator Menu", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		// Title
		titleText = new FlxText(0, 50, FlxG.width, "Create New Chart", 32);
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Instructions
		var instructionText = new FlxText(0, 85, FlxG.width, "Fill out the form below to create a new chart", 16);
		instructionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
		add(instructionText);

		createInputFields();
		createDropDowns();
		createButtons();

		// Initialize vocals group
		vocalsGroup = new FlxTypedGroup<FlxSprite>();
		add(vocalsGroup);

		// Create drag and drop overlay (initially hidden)
		createFileDragOverlay();

		super.create();
	}

	function createInputFields()
	{
		// Create two-column layout for compact design
		var leftColumnX:Float = 50;
		var rightColumnX:Float = 400;
		var yPos:Float = 140;
		var spacing:Float = 35;

		// LEFT COLUMN
		// Song Name Input
		var songNameLabel = new FlxText(leftColumnX, yPos, 150, "Song Name:", 14);
		songNameLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(songNameLabel);

		songNameInput = new FlxInputText(leftColumnX + 100, yPos, 200, "", 14, FlxColor.BLACK, FlxColor.WHITE);
		songNameInput.filterMode = FlxInputText.ONLY_ALPHANUMERIC;
		add(songNameInput);

		// Song GO Button (initially hidden)
		songGoButton = new FlxUIButton(leftColumnX + 310, yPos - 3, "GO", onSongGo);
		songGoButton.resize(40, 20);
		songGoButton.visible = false;
		add(songGoButton);

		yPos += spacing;

		// Difficulty Input
		var difficultyLabel = new FlxText(leftColumnX, yPos, 150, "Difficulty:", 14);
		difficultyLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(difficultyLabel);

		difficultyInput = new FlxInputText(leftColumnX + 100, yPos, 120, "normal", 14, FlxColor.BLACK, FlxColor.WHITE);
		difficultyInput.filterMode = FlxInputText.ONLY_ALPHANUMERIC;
		add(difficultyInput);

		// Difficulty GO Button (initially hidden)
		difficultyGoButton = new FlxUIButton(leftColumnX + 230, yPos - 3, "GO", onDifficultyGo);
		difficultyGoButton.resize(40, 20);
		difficultyGoButton.visible = false;
		add(difficultyGoButton);

		yPos += spacing;

		// Inst File
		var instLabel = new FlxText(leftColumnX, yPos, 150, "Instrumental:", 14);
		instLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(instLabel);

		instFileText = new FlxText(leftColumnX + 100, yPos, 180, "No file selected", 12);
		instFileText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, LEFT, OUTLINE, FlxColor.BLACK);
		add(instFileText);

		instBrowseButton = new FlxUIButton(leftColumnX + 285, yPos - 3, "Browse", onInstBrowse);
		instBrowseButton.resize(60, 20);
		add(instBrowseButton);

		yPos += spacing;

		// Vocals Section with scrollable menu
		// RIGHT COLUMN - Audio Mini Player
		createAudioMiniPlayer(rightColumnX, 140);

		// Vocals area to the right of audio player (side by side)
		createVocalsScrollArea(rightColumnX + 270, 140);

		// File drop hint at bottom
		var dropHintText = new FlxText(50, FlxG.height - 120, FlxG.width - 100, "Tip: Drag & drop .ogg files here!", 12);
		dropHintText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
		add(dropHintText);
	}

	function createFileDragOverlay()
	{
		// Create semi-transparent overlay
		dragDropOverlay = new FlxSprite(0, 0);
		dragDropOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 150));
		dragDropOverlay.visible = false;
		dragDropOverlay.cameras = [FlxG.camera];
		add(dragDropOverlay);

		// Create drop text
		dragDropText = new FlxText(0, 0, FlxG.width, "Drop .ogg audio files here", 32);
		dragDropText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		dragDropText.screenCenter();
		dragDropText.visible = false;
		dragDropText.cameras = [FlxG.camera];
		add(dragDropText);
	}



	function createDropDowns()
	{
		// Compact settings area starting below vocals
		var yPos:Float = 320;
		var spacing:Float = 30;

		// Available mods
		availableMods = ["__mixtape__"];
		#if MODS_ALLOWED
		for (folder in Mods.getModDirectories()) {
			if (folder != null && folder.length > 0) {
				availableMods.push(folder);
			}
		}
		#end

		// Mod and Editor Selection - same line for compactness
		var modLabel = new FlxText(50, yPos, 60, "Mod:", 14);
		modLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(modLabel);

		modDropDown = new FlxUIDropDownMenu(110, yPos, FlxUIDropDownMenu.makeStrIdLabelArray(availableMods, true));
		#if MODS_ALLOWED
		var currentMod = Mods.currentModDirectory;
		if (currentMod != null && availableMods.indexOf(currentMod) > -1) {
			modDropDown.selectedLabel = currentMod;
		}
		#end
		add(modDropDown);

		var editorLabel = new FlxText(240, yPos, 60, "Editor:", 14);
		editorLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(editorLabel);

		var editorOptions = ["New", "Old", "Mixtape"];
		chartEditorDropDown = new FlxUIDropDownMenu(300, yPos, FlxUIDropDownMenu.makeStrIdLabelArray(editorOptions, true));
		var currentEditor = ClientPrefs.data.chartEditorStyle;
		if (currentEditor != null && editorOptions.indexOf(currentEditor) > -1) {
			chartEditorDropDown.selectedLabel = currentEditor;
		} else {
			chartEditorDropDown.selectedLabel = "New";
		}
		chartEditorDropDown.callback = function(str:String) {
			updateAutosaveButton();
		};
		chartEditorDropDown.callback = function(str:String) {
			updateAutosaveButton();
		};
		add(chartEditorDropDown);

		// Update autosave button visibility initially
		updateAutosaveButton();

		yPos += spacing;

		// Time Signature toggle - compact
		timeSignatureCheckBox = new FlxUICheckBox(50, yPos, null, null, "Time Signature Mode", 150);
		timeSignatureCheckBox.callback = onTimeSignatureToggle;
		add(timeSignatureCheckBox);

		yPos += 25;

		// Beats Per Section (default mode) - compact
		var beatsLabel = new FlxText(50, yPos, 100, "Beats/Section:", 14);
		beatsLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(beatsLabel);

		beatsPerSectionStepper = new FlxUINumericStepper(160, yPos, 1, 4, 1, 64, 0);
		add(beatsPerSectionStepper);

		// Time Signature (alternative mode) - compact and overlapped
		var timeSignatureLabel = new FlxText(50, yPos, 100, "Time Sig.:", 14);
		timeSignatureLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		timeSignatureLabel.visible = false;
		add(timeSignatureLabel);

		timeSignatureNumeratorStepper = new FlxUINumericStepper(130, yPos, 1, 4, 1, 32, 0);
		timeSignatureNumeratorStepper.visible = false;
		add(timeSignatureNumeratorStepper);

		var slashText = new FlxText(175, yPos + 2, 15, "/", 14);
		slashText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		slashText.visible = false;
		add(slashText);

		var denominatorOptions = ["2", "4", "8", "16"];
		timeSignatureDenominatorDropDown = new FlxUIDropDownMenu(190, yPos, FlxUIDropDownMenu.makeStrIdLabelArray(denominatorOptions, true));
		timeSignatureDenominatorDropDown.selectedLabel = "4";
		timeSignatureDenominatorDropDown.visible = false;
		add(timeSignatureDenominatorDropDown);

		yPos += spacing;

		// BPM and controls - all on one compact line
		var bpmLabel = new FlxText(50, yPos, 50, "BPM:", 14);
		bpmLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(bpmLabel);

		bpmStepper = new FlxUINumericStepper(100, yPos, 1, 100, 60, 300, 0);
		add(bpmStepper);

		// Compact metronome controls
		metronomeButton = new FlxUIButton(180, yPos - 3, "Metronome", onMetronome);
		metronomeButton.resize(80, 20);
		add(metronomeButton);

		stopMetronomeButton = new FlxUIButton(180, yPos - 3, "Stop Metro", onStopMetronome);
		stopMetronomeButton.resize(80, 20);
		stopMetronomeButton.visible = false;
		add(stopMetronomeButton);

		// Compact tap tempo
		tapTempoButton = new FlxUIButton(270, yPos - 3, "Tap", onTapTempo);
		tapTempoButton.resize(40, 20);
		add(tapTempoButton);
	}

	function createButtons()
	{
		// Create Chart Button
		createButton = new FlxUIButton(FlxG.width - 200, FlxG.height - 80, "Create Chart", onCreate);
		createButton.resize(150, 50);
		add(createButton);

		// Load Chart Button
		loadChartButton = new FlxUIButton(FlxG.width - 370, FlxG.height - 140, "Load Chart", onLoadChart);
		loadChartButton.resize(150, 50);
		add(loadChartButton);

		// Load Chart Button
		convertChart = new FlxUIButton(FlxG.width - 370, FlxG.height - 180, "Convert Chart", onConvertChart);
		convertChart.resize(150, 50);
		add(convertChart);

		// Load Current Song Button (if PlayfieldManager.SONG exists)
		if (PlayfieldManager.SONG != null) {
			loadCurrentSongButton = new FlxUIButton(FlxG.width - 370, FlxG.height - 80, "Load Current Song", onLoadCurrentSong);
			loadCurrentSongButton.resize(160, 50);
			add(loadCurrentSongButton);

			// Position Load Autosave to the left of Load Current Song
			loadAutosaveButton = new FlxUIButton(FlxG.width - 540, FlxG.height - 80, "Load Autosave", onLoadAutosave);
		} else {
			// Position Load Autosave normally when Load Current Song is not visible
			loadAutosaveButton = new FlxUIButton(FlxG.width - 370, FlxG.height - 85, "Load Autosave", onLoadAutosave);
		}

		loadAutosaveButton.resize(150, 30);
		add(loadAutosaveButton);
		updateAutosaveButton();

		// Back Button - positioned above Create Chart
		backButton = new FlxUIButton(FlxG.width - 200, FlxG.height - 140, "Back", onBack);
		backButton.resize(150, 50);
		add(backButton);
	}

	function onLoadCurrentSong()
	{
		if (PlayfieldManager.SONG == null) {
			showError("No song currently loaded in PlayState");
			return;
		}

		// Set mod directory to currently selected mod
		var targetMod = modDropDown.selectedLabel;
		#if MODS_ALLOWED
		if (targetMod != "__mixtape__") {
			Mods.currentModDirectory = targetMod;
		}
		#end

		// Pre-fill the form with current song data
		songNameInput.text = PlayfieldManager.SONG.song;
		difficultyInput.text = Difficulty.getString();

		// Launch the selected chart editor directly
		var originalStyle = ClientPrefs.data.chartEditorStyle;
		var selectedEditor = chartEditorDropDown.selectedLabel;
		if (selectedEditor != null && selectedEditor.length > 0) {
			ClientPrefs.data.chartEditorStyle = selectedEditor;
		}

		try {
			ClientPrefs.openChartEditor();
		} catch (e:Dynamic) {
			trace("Error opening chart editor: " + e);
			showError("Error opening chart editor. Please try again.");
			ClientPrefs.data.chartEditorStyle = originalStyle;
			return;
		}

		ClientPrefs.data.chartEditorStyle = originalStyle;
		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	function validateSongExists(songName:String, difficulty:String, targetMod:String):Bool
	{
		var formattedName = Paths.formatToSongPath(songName);
		var chartPath:String;

		if (targetMod == "__mixtape__") {
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
		} else {
			#if MODS_ALLOWED
			chartPath = 'mods/$targetMod/data/$formattedName/$formattedName-$difficulty.json';
			#else
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
			#end
		}

		#if sys
		return FileSystem.exists(chartPath);
		#else
		return false; // Can't check on non-sys platforms
		#end
	}

	function onLoadChart()
	{
		#if MODS_ALLOWED
		// Set mod directory to currently selected mod before loading
		var targetMod = modDropDown.selectedLabel;
		if (targetMod != "__mixtape__") {
			Mods.currentModDirectory = targetMod;
		}

		// Use file dialog to browse for chart files
		var filter:String = "Chart Files (*.json)|*.json";
		var title:String = "Load Existing Chart";

		try {
			// Use ImprovedFileHandling for cross-platform file dialog
			var path = ImprovedFileHandling.openFile(title, [{ext: "json", desc: "Chart Files"}]);
			if (path != null && path.length > 0) {
				loadChartFromFile(path);
			}
		} catch (e:Dynamic) {
			trace("Error opening file dialog: " + e);
			showError("Error opening file dialog. Please try again.");
		}
		#else
		showError("File loading is not available in this build.");
		#end
	}

	function onConvertChart()
	{
		#if MODS_ALLOWED
		// Set mod directory to currently selected mod before loading
		var targetMod = modDropDown.selectedLabel;
		if (targetMod != "__mixtape__") {
			Mods.currentModDirectory = targetMod;
		}

		// Use file dialog to browse for chart files
		var filter:String = "Chart Files (*.json)|*.json";
		var title:String = "Load Existing Chart";

		try {
			// Use ImprovedFileHandling for cross-platform file dialog
			var path = ImprovedFileHandling.openFile(title, [{ext: "json", desc: "Chart Files"}]);
			if (path != null && path.length > 0) {
				convertChartFromFile(path);
			}
		} catch (e:Dynamic) {
			trace("Error opening file dialog: " + e);
			showError("Error opening file dialog. Please try again.");
		}
		#else
		showError("File loading is not available in this build.");
		#end
	}

	function loadChartFromFile(path:String)
	{
		try {
			// Determine mod directory from file path
			var targetMod = "__mixtape__"; // Default to base game

			#if MODS_ALLOWED
			if (path.indexOf("mods/") != -1) {
				// Extract mod directory from path
				var pathParts = path.split("/");
				for (i in 0...pathParts.length) {
					if (pathParts[i] == "mods" && i + 1 < pathParts.length) {
						targetMod = pathParts[i + 1];
						break;
					}
				}
			}
			#end

			// Set the current mod directory
			#if MODS_ALLOWED
			if (targetMod != "__mixtape__") {
				Mods.currentModDirectory = targetMod;
				// Update UI to reflect correct mod
				modDropDown.selectedLabel = targetMod;
			}
			#end

			// Load the chart JSON
			var rawJson = sys.io.File.getContent(path);
			var chartData:backend.SwagSong = cast haxe.Json.parse(rawJson);

			if (chartData == null || chartData.song == null) {
				showError("Invalid chart file format.");
				return;
			}

			// Set PlayfieldManager.SONG to the loaded chart
			PlayfieldManager.SONG = chartData;
			PlayState.storyDifficulty = 1; // Default difficulty index
			PlayState.isStoryMode = false;

			// Launch the selected chart editor directly
			var originalStyle = ClientPrefs.data.chartEditorStyle;
			var selectedEditor = chartEditorDropDown.selectedLabel;
			if (selectedEditor != null && selectedEditor.length > 0) {
				ClientPrefs.data.chartEditorStyle = selectedEditor;
			}

			try {
				ClientPrefs.openChartEditor();
				FlxG.sound.play(Paths.sound('confirmMenu'));
			} catch (e:Dynamic) {
				trace("Error opening chart editor: " + e);
				showError("Error opening chart editor with loaded chart.");
				ClientPrefs.data.chartEditorStyle = originalStyle;
			}

		} catch (e:Dynamic) {
			trace("Error loading chart file: " + e);
			showError("Error loading chart file. Please check the file format.");
		}
	}

	function convertChartFromFile(path:String)
	{
		try {
			// Determine mod directory from file path
			var targetMod = "__mixtape__"; // Default to base game

			#if MODS_ALLOWED
			if (path.indexOf("mods/") != -1) {
				// Extract mod directory from path
				var pathParts = path.split("/");
				for (i in 0...pathParts.length) {
					if (pathParts[i] == "mods" && i + 1 < pathParts.length) {
						targetMod = pathParts[i + 1];
						break;
					}
				}
			}
			#end

			// Set the current mod directory
			#if MODS_ALLOWED
			if (targetMod != "__mixtape__") {
				Mods.currentModDirectory = targetMod;
				// Update UI to reflect correct mod
				modDropDown.selectedLabel = targetMod;
			}
			#end

			// Load the chart JSON
			var rawJson = sys.io.File.getContent(path);
			var chartData:backend.SwagSong = cast haxe.Json.parse(rawJson);

			if (chartData == null || chartData.song == null) {
				showError("Invalid chart file format.");
				return;
			}

			// Set PlayfieldManager.SONG to the loaded chart
			PlayfieldManager.SONG = chartData;
			PlayState.storyDifficulty = 1; // Default difficulty index
			PlayState.isStoryMode = false;

			// Launch the selected chart editor directly
			var originalStyle = ClientPrefs.data.chartEditorStyle;
			var selectedEditor = chartEditorDropDown.selectedLabel;
			if (selectedEditor != null && selectedEditor.length > 0) {
				ClientPrefs.data.chartEditorStyle = selectedEditor;
			}

			try {
				ClientPrefs.openChartEditor();
				FlxG.sound.play(Paths.sound('confirmMenu'));
			} catch (e:Dynamic) {
				trace("Error opening chart editor: " + e);
				showError("Error opening chart editor with loaded chart.");
				ClientPrefs.data.chartEditorStyle = originalStyle;
			}

		} catch (e:Dynamic) {
			trace("Error loading chart file: " + e);
			showError("Error loading chart file. Please check the file format.");
		}
	}

	function onTimeSignatureToggle()
	{
		var useTimeSignature = timeSignatureCheckBox.checked;

		// Toggle visibility of controls
		beatsPerSectionStepper.visible = !useTimeSignature;
		timeSignatureNumeratorStepper.visible = useTimeSignature;
		timeSignatureDenominatorDropDown.visible = useTimeSignature;

		// Find and toggle text labels visibility
		for (member in members) {
			if (Std.isOfType(member, FlxText)) {
				var text = cast(member, FlxText);
				if (text.text == "Beats/Section:") {
					text.visible = !useTimeSignature;
				} else if (text.text == "Time Sig.:") {
					text.visible = useTimeSignature;
				} else if (text.text == "/") {
					text.visible = useTimeSignature;
				}
			}
		}
	}

	function onAddVocals()
	{
		try {
			// Determine what type of vocal file we're adding
			var nextIndex = selectedVocalsPaths.length;
			var nextLabel = getDefaultVocalsLabel(nextIndex);
			var dialogTitle = 'Select Vocal File';

			// Show which type we're selecting with special handling for Player
			if (nextLabel == "Player") {
				dialogTitle += ' (Default/Player)';
			} else {
				dialogTitle += ' (' + nextLabel + ')';
			}

			var filePath = ImprovedFileHandling.openFile(dialogTitle, [{ext: "ogg", desc: "OGG Audio Files"}]);
			if (filePath != null && filePath.trim() != "") {
				var filename = filePath.split("/").pop().split("\\").pop();
				if (!filename.toLowerCase().endsWith(".ogg")) {
					showError("Only .ogg files are supported");
					return;
				}

				addVocalsToList(filePath, filename);

				// Reload audio with new vocals
				loadPreviewAudio();

				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
		} catch (e:Dynamic) {
			trace("Error opening file browser: " + e);
			showError("File browser not available: " + e);
		}
	}

	function addVocalsToList(path:String, filename:String)
	{
		// Check if this file is already added
		if (selectedVocalsPaths.indexOf(path) != -1) {
			showError("This vocals file has already been added!");
			return;
		}

		var index = selectedVocalsPaths.length;
		selectedVocalsPaths.push(path);

		// Use default label based on index
		var defaultLabel = getDefaultVocalsLabel(index);
		if (index >= vocalsLabels.length) {
			vocalsLabels.push(defaultLabel);
		}

		createVocalsListItem(path, filename, index);
	}

	function getDefaultVocalsLabel(index:Int):String
	{
		return switch (index) {
			case 0: "Player";
			case 1: "Opponent";
			case 2: "GF";
			default: "Custom" + (index - 2);
		};
	}

	function removeVocalsFromList(index:Int)
	{
		if (index >= 0 && index < selectedVocalsPaths.length) {
			// Remove from arrays
			selectedVocalsPaths.splice(index, 1);
			vocalsLabels.splice(index, 1);

			// Remove UI elements
			if (index < vocalsTexts.length) {
				remove(vocalsTexts[index]);
				vocalsTexts[index].destroy();
				vocalsTexts.splice(index, 1);
			}

			if (index < vocalsRemoveButtons.length) {
				remove(vocalsRemoveButtons[index]);
				vocalsRemoveButtons[index].destroy();
				vocalsRemoveButtons.splice(index, 1);
			}

			// Refresh the vocals list display
			refreshVocalsList();

			// Reload audio without removed vocals
			loadPreviewAudio();
		}
	}

	function refreshVocalsList()
	{
		// Clear existing vocals UI
		for (text in vocalsTexts) {
			if (text != null) {
				remove(text);
				text.destroy();
			}
		}
		for (button in vocalsRemoveButtons) {
			if (button != null) {
				remove(button);
				button.destroy();
			}
		}
		vocalsTexts = [];
		vocalsRemoveButtons = [];

		// Also need to find and remove label input fields (this requires tracking them)
		// For now, let's rebuild the entire vocals section

		// Recreate vocals list
		for (i in 0...selectedVocalsPaths.length) {
			var filename = selectedVocalsPaths[i].split("/").pop().split("\\").pop();
			// Don't use addVocalsToList here to avoid infinite recursion and duplicate checks
			createVocalsListItem(selectedVocalsPaths[i], filename, i);
		}
	}

	function createVocalsScrollArea(x:Float, y:Float)
	{
		// Vocals area header
		var vocalsLabel = new FlxText(x, y - 25, 180, "VOCALS TRACKS:", 14);
		vocalsLabel.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.CYAN, LEFT, OUTLINE, FlxColor.BLACK);
		add(vocalsLabel);

		// Create background for vocals scroll area
		vocalsScrollBg = new FlxSprite(x, y);
		vocalsScrollBg.makeGraphic(320, 100, FlxColor.fromRGB(30, 30, 30, 180));
		add(vocalsScrollBg);

		// Create subtle border
		var border = new FlxSprite(x - 1, y - 1);
		border.makeGraphic(322, 102, FlxColor.fromRGB(100, 100, 100, 120)); // Subtle gray border
		add(border);
		add(vocalsScrollBg); // Ensure bg is on top of border

		// Initialize scroll parameters
		vocalsScrollY = y + 5;
		vocalsScrollMaxHeight = 90;

		// Add vocals button in header area
		var addVocalsBtn = new FlxUIButton(x + 200, y - 25, "+ Add", onAddVocals);
		addVocalsBtn.resize(60, 20);
		add(addVocalsBtn);

		// Scroll hint at bottom of scroll area
		var scrollHint = new FlxText(x + 5, y + vocalsScrollMaxHeight - 15, 300, "Mouse wheel to scroll vocals", 9);
		scrollHint.setFormat(Paths.font("vcr.ttf"), 9, FlxColor.GRAY, LEFT);
		add(scrollHint);
	}

	function createVocalsListItem(path:String, filename:String, index:Int)
	{
		// Calculate position within scroll area (vocals start at top of scroll area)
		var itemY = vocalsScrollY + (index * 22) - vocalsScrollOffset; // Use scroll offset for proper scrolling
		var itemX = vocalsScrollBg.x + 5;

		// Create compact label input
		var labelInput = new FlxInputText(itemX, itemY, 70, getDefaultVocalsLabel(index), 8, FlxColor.BLACK, FlxColor.WHITE);
		labelInput.filterMode = FlxInputText.ONLY_ALPHANUMERIC;
		labelInput.size = 8;
		if (index >= vocalsLabels.length) {
			vocalsLabels.push(labelInput.text);
		}
		vocalsInputs.push(labelInput);

		// Create compact filename text with truncation
		var displayName = filename.length > 18 ? filename.substr(0, 15) + "..." : filename;
		var filenameText = new FlxText(itemX + 75, itemY + 2, 120, displayName, 8);
		filenameText.setFormat(Paths.font("vcr.ttf"), 8, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		vocalsTexts.push(filenameText);

		// Create compact remove button
		var removeButton = new FlxUIButton(itemX + 200, itemY, "X", function() {
			removeVocalsFromList(index);
		});
		removeButton.resize(18, 16);
		removeButton.label.size = 8;
		vocalsRemoveButtons.push(removeButton);

		// Add to display (clipping handled by scroll bounds)
		add(labelInput);
		add(filenameText);
		add(removeButton);

		// Update vocals labels array when input changes
		labelInput.callback = function(text:String, action:String) {
			if (index < vocalsLabels.length) {
				vocalsLabels[index] = text;
			}
		};
	}

	function onInstBrowse()
	{
		try {
			var filePath = ImprovedFileHandling.openFile("Select Instrumental File", [{ext: "ogg", desc: "OGG Audio Files"}]);
			if (filePath != null && filePath.trim() != "") {
				var filename = filePath.split("/").pop().split("\\").pop();
				if (!filename.toLowerCase().endsWith(".ogg")) {
					showError("Only .ogg files are supported");
					return;
				}

				selectedInstPath = filePath;
				instFileText.text = filename;
				instFileText.color = FlxColor.WHITE;

				// Load audio immediately for optimization
				loadPreviewAudio();

				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
		} catch (e:Dynamic) {
			trace("Error opening file browser: " + e);
			showError("File browser not available: " + e);
		}
	}

	function createAudioMiniPlayer(x:Float, y:Float)
	{
		// Compact square mini player background
		var playerBg = new FlxSprite(x, y);
		playerBg.makeGraphic(200, 160, FlxColor.fromRGB(30, 30, 30));
		add(playerBg);

		// Audio Player title
		var titleText = new FlxText(x + 10, y + 5, 180, "Audio Preview", 10);
		titleText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Play/Pause button (compact)
		previewButton = new FlxUIButton(x + 10, y + 20, "Play", onPreview);
		previewButton.resize(35, 25);
		add(previewButton);

		stopPreviewButton = new FlxUIButton(x + 10, y + 20, "Pause", onStopPreview);
		stopPreviewButton.resize(35, 25);
		stopPreviewButton.visible = false;
		add(stopPreviewButton);

		// Stop button (compact)
		var stopButton = new FlxUIButton(x + 50, y + 20, "Stop", onFullStop);
		stopButton.resize(35, 25);
		add(stopButton);

		// Time display (centered)
		previewTimeText = new FlxText(x + 90, y + 25, 100, "00:00 / 00:00", 10);
		previewTimeText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(previewTimeText);

		// Seek bar background (full width)
		previewSeekBar = new FlxSprite(x + 10, y + 55);
		previewSeekBar.makeGraphic(180, 6, FlxColor.fromRGB(60, 60, 60));
		add(previewSeekBar);

		// Seek bar handle
		previewSeekHandle = new FlxSprite(x + 10, y + 52);
		previewSeekHandle.makeGraphic(3, 12, FlxColor.WHITE);
		add(previewSeekHandle);

		// Volume label (compact)
		var volumeLabel = new FlxText(x + 10, y + 70, 60, "Volume:", 10);
		volumeLabel.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(volumeLabel);

		// Volume percentage (right-aligned)
		var volumeText = new FlxText(x + 150, y + 70, 40, Math.round(previewVolume * 100) + "%", 10);
		volumeText.setFormat(Paths.font("vcr.ttf"), 10, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		add(volumeText);

		// Volume slider background (full width)
		previewVolumeSlider = new FlxSprite(x + 10, y + 90);
		previewVolumeSlider.makeGraphic(180, 6, FlxColor.fromRGB(60, 60, 60));
		add(previewVolumeSlider);

		// Volume handle
		previewVolumeHandle = new FlxSprite(x + 10 + (previewVolume * 177), y + 87);
		previewVolumeHandle.makeGraphic(3, 12, FlxColor.CYAN);
		add(previewVolumeHandle);
	}

	function onPreview()
	{
		if (isPreviewPlaying) {
			onStopPreview();
			return;
		}

		if (selectedInstPath == "") {
			showError("Please select an instrumental file first");
			return;
		}

			try {
				// Stop any existing playback first
				onFullStop();

				// Use pre-loaded audio if available, otherwise load now
				if (previewInst == null) {
					trace("Loading instrumental from: " + selectedInstPath);
					loadPreviewAudio();
				}

				if (previewInst == null) {
					showError("Failed to load instrumental file - file may be corrupted or unsupported");
					trace("Failed to load: " + selectedInstPath);
					return;
				}			previewInst.volume = previewVolume;
			trace("Successfully loaded instrumental, length: " + previewInst.length + "ms");

			// Load vocals
			for (i in 0...selectedVocalsPaths.length) {
				var vocalsPath = selectedVocalsPaths[i];
				trace("Loading vocals from: " + vocalsPath);

				var vocalsSound:FlxSound = loadAudioFromFile(vocalsPath);
				if (vocalsSound != null) {
					vocalsSound.volume = previewVolume * 0.8;
					previewVocals.push(vocalsSound);
					trace("Successfully loaded vocals: " + vocalsPath);
				} else {
					trace("Failed to load vocals: " + vocalsPath);
				}
			}

			// Play all audio
			previewInst.play(false, 0); // Start from beginning
			trace("Started playing instrumental - Time: " + previewInst.time + "ms, Length: " + previewInst.length + "ms, Playing: " + previewInst.playing);

			for (vocals in previewVocals) {
				if (vocals != null) {
					vocals.play(false, 0); // Start from beginning
					trace("Started playing vocals");
				}
			}

			isPreviewPlaying = true;
			previewButton.visible = false;
			stopPreviewButton.visible = true;

			// If metronome was playing, restart it to sync with audio
			if (isMetronomePlaying) {
				onStopMetronome();
				// Small delay to ensure audio starts first, then sync metronome
				new FlxTimer().start(0.1, function(timer:FlxTimer) {
					if (isPreviewPlaying && previewInst != null && previewInst.playing) {
						// Start metronome synced to audio
						try {
							metronomeSound = FlxG.sound.load(Paths.sound('metronome'));
							if (metronomeSound != null) {
								isMetronomePlaying = true;
								metronomeButton.visible = false;
								stopMetronomeButton.visible = true;

								var bpm = bpmStepper.value;
								var interval = 60.0 / bpm;

								metronomeSound.play();

								metronomeTimer = new FlxTimer();
								metronomeTimer.start(interval, function(timer:FlxTimer) {
									if (isMetronomePlaying && metronomeSound != null &&
										isPreviewPlaying && previewInst != null && previewInst.playing) {
										metronomeSound.play();
									}
								}, 0);
							}
						} catch (e:Dynamic) {
							trace("Error syncing metronome: " + e);
						}
					}
				});
			}

			FlxG.sound.play(Paths.sound('confirmMenu'));
		} catch (e:Dynamic) {
			trace("Error playing preview: " + e);
			showError("Error playing audio preview: " + e);
			// Clean up on error
			onFullStop();
		}
	}

	function onStopPreview()
	{
		// Pause audio without destroying
		if (previewInst != null) {
			previewInst.pause();
		}
		for (vocals in previewVocals) {
			if (vocals != null) vocals.pause();
		}

		isPreviewPlaying = false;
		previewButton.visible = true;
		stopPreviewButton.visible = false;

		// Stop metronome when audio is paused (it will only play when audio is playing)
		// The metronome timer will still run but won't play sounds due to the condition check
	}

	function onFullStop()
	{
		// Stop and destroy all audio
		if (previewInst != null) {
			previewInst.stop();
			previewInst.destroy();
			previewInst = null;
		}

		for (vocals in previewVocals) {
			if (vocals != null) {
				vocals.stop();
				vocals.destroy();
			}
		}
		previewVocals = [];

		isPreviewPlaying = false;
		previewButton.visible = true;
		stopPreviewButton.visible = false;
	}

	function onMetronome()
	{
		if (isMetronomePlaying) {
			onStopMetronome();
			return;
		}

		try {
			// Load metronome sound (using menu blip as metronome click)
			metronomeSound = FlxG.sound.load(Paths.sound('metronome'));
			if (metronomeSound != null) {
				isMetronomePlaying = true;
				metronomeButton.visible = false;
				stopMetronomeButton.visible = true;

				// Calculate metronome interval in seconds
				var bpm = bpmStepper.value;
				var interval = 60.0 / bpm; // Beat interval in seconds

				// Only play first click if preview audio is also playing
				if (isPreviewPlaying && previewInst != null && previewInst.playing) {
					metronomeSound.play();
				}

				// Set up repeating timer for subsequent clicks
				metronomeTimer = new FlxTimer();
				metronomeTimer.start(interval, function(timer:FlxTimer) {
					// Only play metronome if both metronome and preview audio are playing
					if (isMetronomePlaying && metronomeSound != null &&
						isPreviewPlaying && previewInst != null && previewInst.playing) {
						metronomeSound.play();
					}
				}, 0); // 0 = infinite repeats
			}
		} catch (e:Dynamic) {
			trace("Error starting metronome: " + e);
			showError("Error starting metronome");
		}
	}

	function onStopMetronome()
	{
		isMetronomePlaying = false;
		metronomeButton.visible = true;
		stopMetronomeButton.visible = false;

		if (metronomeTimer != null) {
			metronomeTimer.cancel();
			metronomeTimer.destroy();
			metronomeTimer = null;
		}

		if (metronomeSound != null) {
			metronomeSound.stop();
			metronomeSound.destroy();
			metronomeSound = null;
		}
	}

	function onTapTempo()
	{
		var currentTime = haxe.Timer.stamp();

		// Reset if too much time has passed since last tap (more than 3 seconds)
		if (currentTime - lastTapTime > 3.0) {
			tapTimes = [];
		}

		tapTimes.push(currentTime);
		lastTapTime = currentTime;

		// Need at least 2 taps to calculate BPM
		if (tapTimes.length >= 2) {
			// Calculate average interval between taps
			var totalInterval:Float = 0;
			for (i in 1...tapTimes.length) {
				totalInterval += tapTimes[i] - tapTimes[i-1];
			}
			var avgInterval = totalInterval / (tapTimes.length - 1);

			// Convert to BPM (60 seconds / average interval)
			var calculatedBPM = 60.0 / avgInterval;

			// Clamp to reasonable BPM range
			calculatedBPM = Math.max(60, Math.min(300, calculatedBPM));

			// Update BPM stepper
			bpmStepper.value = Math.round(calculatedBPM);

			// Visual feedback with metronome sound
			FlxG.sound.play(Paths.sound('metronome'));
			showError('BPM detected: ${Math.round(calculatedBPM)}', FlxColor.GREEN);

			// Keep only last 8 taps for rolling average
			if (tapTimes.length > 8) {
				tapTimes = tapTimes.slice(tapTimes.length - 8);
			}
		} else {
			// First tap - just provide feedback with metronome sound
			FlxG.sound.play(Paths.sound('metronome'));
			showError('Tap to beat - need more taps to calculate BPM', FlxColor.YELLOW);
		}
	}



	function onCreate()
	{
		var songName = songNameInput.text.trim();
		if (songName == "") {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			showError("Song name is required!");
			return;
		}

		var difficulty = difficultyInput.text.trim().toLowerCase();
		if (difficulty == "") {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			showError("Difficulty is required!");
			return;
		}

		var targetMod = modDropDown.selectedLabel;

		// Check for all potential file overwrites
		var overwriteFiles = checkAllPotentialOverwrites(songName, difficulty, targetMod);
		if (overwriteFiles.length > 0) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			var warningMsg = 'Warning: Creating this chart will OVERWRITE the following existing files:\n\n';
			for (file in overwriteFiles) {
				warningMsg += '• ' + file + '\n';
			}
			warningMsg += '\nDo you want to continue?';

			// Show confirmation dialog
			openConfirmDialog(warningMsg, function(confirmed:Bool) {
				if (confirmed) {
					// User confirmed, proceed with creation
					proceedWithChartCreation();
				} else {
					// User cancelled
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			});
			return;
		}

		// No existing files, proceed normally
		proceedWithChartCreation();
	}

	function proceedWithChartCreation()
	{
		var songName = songNameInput.text.trim();
		var difficulty = difficultyInput.text.trim().toLowerCase();
		var targetMod = modDropDown.selectedLabel;

		#if desktop
		if (selectedInstPath == "") {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			showError("Please select an instrumental file (.ogg)");
			return;
		}
		#else
		if (selectedInstPath == "") {
			trace("No instrumental file selected - user will need to add files manually");
		}
		#end

		// Calculate beats per section
		// For compatibility, convert time signature to beats per section rather than using actual time signatures
		var beatsPerSection:Float = 4;
		if (timeSignatureCheckBox.checked) {
			var numerator = timeSignatureNumeratorStepper.value;
			var denominator = Std.parseInt(timeSignatureDenominatorDropDown.selectedLabel);
			if (denominator == null || denominator == 0) denominator = 4;

			// Convert time signature to equivalent beats per section using proper calculation
			// This matches how the New Chart Editor handles time signatures
			if (denominator == 8) {
				// For eighth note denominators (6/8, 9/8, 12/8), convert to quarter note equivalents
				beatsPerSection = numerator * 0.5; // Each pair of 8th notes = 1 quarter note
			} else if (denominator == 2) {
				// For half note denominators (3/2, 4/2), each beat is worth 2 quarter notes
				beatsPerSection = numerator * 2;
			} else if (denominator == 16) {
				// For sixteenth note denominators, each beat is worth 0.25 quarter notes
				beatsPerSection = numerator * 0.25;
			} else {
				// For quarter note denominators (4/4, 3/4, 2/4) and others, use numerator directly
				beatsPerSection = numerator;
			}

			// Ensure minimum of 1 beat per section for stability
			if (beatsPerSection < 1) beatsPerSection = 1;
		} else {
			beatsPerSection = beatsPerSectionStepper.value;
		}

		// Calculate number of sections based on instrumental length
		var sectionCount:Int = 8; // Default fallback
		#if sys
		if (selectedInstPath != "") {
			try {
				// Load instrumental to get duration using same method as preview
				var tempSound:FlxSound = null;
				var loaded = false;

				try {
					// Try FlxG.sound.load first
					tempSound = FlxG.sound.load(selectedInstPath, 0, false, false);
					if (tempSound != null && tempSound.length > 0) {
						loaded = true;
					} else {
						// Try manual FlxSound creation
						if (tempSound != null) tempSound.destroy();
						tempSound = new FlxSound();
						tempSound.loadEmbedded(selectedInstPath, false);
						loaded = (tempSound.length > 0);
					}
				} catch (e:Dynamic) {
					trace("Error loading for duration check: " + e);
					// Try stream loading as fallback
					if (tempSound != null) tempSound.destroy();
					tempSound = new FlxSound();
					tempSound.loadStream(selectedInstPath, false);
					loaded = (tempSound != null && tempSound.length > 0);
				}				if (loaded && tempSound.length > 0) {
					var songLengthMs = tempSound.length;
					var bpm = bpmStepper.value;

					// Calculate section length in milliseconds
					// Section length = (beatsPerSection / BPM) * 60 * 1000
					var sectionLengthMs = (beatsPerSection / bpm) * 60 * 1000;

					// Calculate needed sections, add 1 extra for safety
					sectionCount = Math.ceil(songLengthMs / sectionLengthMs) + 1;

					// Reasonable bounds (minimum 4, maximum 200 sections)
					sectionCount = Std.int(Math.max(4, Math.min(200, sectionCount)));

					trace('Song length: ${songLengthMs}ms, Section length: ${sectionLengthMs}ms, Sections needed: $sectionCount');
				} else {
					trace("Could not determine song length, using default section count");
				}

				if (tempSound != null) tempSound.destroy();
			} catch (e:Dynamic) {
				trace("Error calculating song length: " + e);
			}
		}
		#end

		// Create initial sections based on chart editor
		var selectedEditor = chartEditorDropDown.selectedLabel;
		var initialSections:Array<SwagSection> = [];

		if (selectedEditor == "New") {
			// New chart editor only needs one initial section
			var section = createInitialSection(beatsPerSection);
			section.mustHitSection = true; // Start with player section
			initialSections.push(section);
		} else {
			// Other editors benefit from multiple pre-created sections
			for (i in 0...sectionCount) {
				var section = createInitialSection(beatsPerSection);
				// Alternate between player and opponent sections for variety
				section.mustHitSection = (i % 2 == 0);
				initialSections.push(section);
			}
		}

		// Create the song data structure with multiple vocals support
		var songData:SwagSong = {
			song: songName,
			notes: initialSections,
			events: [],
			bpm: bpmStepper.value,
			needsVoices: selectedVocalsPaths.length > 0,
			speed: 1.0,
			offset: 0.0,
			player1: 'bf',
			player2: 'dad',
			player4: null,
			player5: null,
			gfVersion: 'gf',
			stage: 'stage',
			format: 'psych_v1',
			mania: 3,
			startMania: 3
		};

		// Set up mod directory if not __mixtape__
		if (targetMod != "__mixtape__") {
			#if MODS_ALLOWED
			Mods.currentModDirectory = targetMod;
			#end
		}

		// Save the chart JSON with difficulty
		var chartPath = getChartPath(songName, difficulty, targetMod);
		var jsonString = Json.stringify({"song": songData}, null, "\t");

		#if sys
		try {
			// Create directories and save chart file using standard file operations
			FileSystem.createDirectory(haxe.io.Path.directory(chartPath));
			File.saveContent(chartPath, jsonString);

			// Copy audio files
			copyAudioFilesImproved(songName, targetMod);

			trace("Successfully created chart at: " + chartPath);
		} catch (e:Dynamic) {
			trace("Error saving chart: " + e);
			showError("Error saving chart files: " + e);
			return;
		}
		#else
		trace("Chart creation completed. Manual file setup required on this platform.");
		#end

		// Set up PlayState with the new song
		PlayfieldManager.SONG = songData;
		PlayState.storyDifficulty = 1;
		PlayState.isStoryMode = false;

		// Launch the selected chart editor
		var originalStyle = ClientPrefs.data.chartEditorStyle;
		var selectedEditor = chartEditorDropDown.selectedLabel;
		if (selectedEditor != null && selectedEditor.length > 0) {
			ClientPrefs.data.chartEditorStyle = selectedEditor;
		}

		try {
			ClientPrefs.openChartEditor();
		} catch (e:Dynamic) {
			trace("Error opening chart editor: " + e);
			showError("Error opening chart editor. Please try again.");
			ClientPrefs.data.chartEditorStyle = originalStyle; // Restore on error
			return;
		}

		ClientPrefs.data.chartEditorStyle = originalStyle; // Restore original setting

		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	function createInitialSection(beatsPerSection:Float):SwagSection
	{
		return {
			sectionNotes: [],
			sectionBeats: beatsPerSection,
			sectionSteps: 4.0,
			mustHitSection: false,
			altAnim: false,
			gfSection: false,
			exSection: false
		};
	}

	function getChartPath(songName:String, difficulty:String, targetMod:String):String
	{
		var formattedName = Paths.formatToSongPath(songName);

		if (targetMod == "__mixtape__") {
			return 'assets/data/$formattedName/$formattedName-$difficulty.json';
		} else {
			#if MODS_ALLOWED
			return 'mods/$targetMod/data/$formattedName/$formattedName-$difficulty.json';
			#else
			return 'assets/data/$formattedName/$formattedName-$difficulty.json';
			#end
		}
	}

	#if sys
	function copyAudioFilesImproved(songName:String, targetMod:String)
	{
		var formattedName = Paths.formatToSongPath(songName);
		var audioDir:String;

		if (targetMod == "__mixtape__") {
			audioDir = 'assets/songs/$formattedName/';
		} else {
			#if MODS_ALLOWED
			audioDir = 'mods/$targetMod/songs/$formattedName/';
			#else
			audioDir = 'assets/songs/$formattedName/';
			#end
		}

		FileSystem.createDirectory(audioDir);

		// Copy instrumental
		if (selectedInstPath != "") {
			var instDestPath = audioDir + "Inst.ogg";
			try {
				File.copy(selectedInstPath, instDestPath);
				trace("Copied instrumental to: " + instDestPath);
			} catch (e:Dynamic) {
				trace("Error copying instrumental: " + e);
			}
		}

		// Copy only the main vocals file (no duplicates)
		if (selectedVocalsPaths.length > 0) {
			// Find the main vocals file (priority: Player > first file)
			var mainVocalsIndex = 0;
			for (i in 0...selectedVocalsPaths.length) {
				var label = (i < vocalsLabels.length) ? vocalsLabels[i] : "Custom" + (i + 1);
				if (label == "Player") {
					mainVocalsIndex = i;
					break;
				}
			}

			// Copy only the main vocals file as Voices.ogg
			var vocalsPath = selectedVocalsPaths[mainVocalsIndex];
			var label = (mainVocalsIndex < vocalsLabels.length) ? vocalsLabels[mainVocalsIndex] : "Custom" + (mainVocalsIndex + 1);
			var mainVocalsDestPath = audioDir + "Voices.ogg";

			try {
				File.copy(vocalsPath, mainVocalsDestPath);
				trace('Copied main vocals ("$label") to: $mainVocalsDestPath');
			} catch (e:Dynamic) {
				trace("Error copying main vocals: " + e);
			}
		}
	}
	#end

	function onBack()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new MasterEditorMenu());
	}

	function showError(message:String, ?color:FlxColor = null)
	{
		if (color == null) color = FlxColor.RED;

		// Create a simple message display
		var messageText = new FlxText(50, FlxG.height - 150, FlxG.width - 100, message, 16);
		messageText.setFormat(Paths.font("vcr.ttf"), 16, color, CENTER, OUTLINE, FlxColor.BLACK);
		messageText.cameras = [FlxG.camera]; // Ensure it's visible above other elements
		add(messageText);

		// Remove the message after 3 seconds
		new FlxTimer().start(3.0, function(timer:FlxTimer) {
			if (messageText != null) {
				remove(messageText);
				messageText.destroy();
			}
		});
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK) {
			// Don't allow back button if any text field is focused
			if (!isAnyTextFieldFocused()) {
				onBack();
			}
		}

		// Update mini player
		updateMiniPlayer();

		// Handle seek bar dragging
		handleSeekBarInput();

		// Handle volume slider dragging
		handleVolumeSliderInput();

		// Handle vocals scroll area mouse wheel
		handleVocalsScroll();

		// Handle drag visual feedback (this is approximate since we can't detect drag hover directly)
		// The actual file drop will be handled by handleFileDrop

		super.update(elapsed);
	}

	function updateMiniPlayer()
	{
		if (previewInst != null && previewTimeText != null) {
			var currentTime = previewInst.time;
			var totalTime = previewInst.length;

			// Debug: Check if audio is actually playing and time is updating
			if (isPreviewPlaying) {
				// trace("Audio time update - Current: " + currentTime + "ms, Total: " + totalTime + "ms, Playing: " + previewInst.playing);

				// If audio is supposed to be playing but isn't, try to restart it
				if (!previewInst.playing && currentTime < totalTime - 100) {
					trace("Audio stopped unexpectedly, restarting...");
					previewInst.play();

					// Restart vocals too
					for (vocals in previewVocals) {
						if (vocals != null && !vocals.playing) {
							vocals.play();
						}
					}
				}
			}

			// Update time display
			var currentMin = Math.floor(currentTime / 60000);
			var currentSec = Math.floor((currentTime % 60000) / 1000);
			var totalMin = Math.floor(totalTime / 60000);
			var totalSec = Math.floor((totalTime % 60000) / 1000);

			// Format time display with proper zero padding
			var currentMinStr = currentMin < 10 ? "0" + currentMin : "" + currentMin;
			var currentSecStr = currentSec < 10 ? "0" + currentSec : "" + currentSec;
			var totalMinStr = totalMin < 10 ? "0" + totalMin : "" + totalMin;
			var totalSecStr = totalSec < 10 ? "0" + totalSec : "" + totalSec;

			previewTimeText.text = '${currentMinStr}:${currentSecStr} / ${totalMinStr}:${totalSecStr}';

			// Update seek handle position (only if not dragging)
			if (!isDraggingSeek && previewSeekHandle != null && previewSeekBar != null) {
				var progress = totalTime > 0 ? currentTime / totalTime : 0;
				previewSeekHandle.x = previewSeekBar.x + (progress * (previewSeekBar.width - previewSeekHandle.width));
			}

			// Auto-stop when song ends
			if (isPreviewPlaying && currentTime >= totalTime - 100) {
				onFullStop();
			}
		}
	}

	function handleSeekBarInput()
	{
		if (previewSeekBar == null || previewSeekHandle == null || previewInst == null) return;

		// Check if mouse is over seek bar
		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;
		var overSeekBar = mouseX >= previewSeekBar.x && mouseX <= previewSeekBar.x + previewSeekBar.width &&
						  mouseY >= previewSeekBar.y - 8 && mouseY <= previewSeekBar.y + previewSeekBar.height + 8;

		if (overSeekBar && FlxG.mouse.justPressed) {
			isDraggingSeek = true;
		}

		if (isDraggingSeek) {
			if (FlxG.mouse.pressed) {
				// Update handle position
				var newX = Math.max(previewSeekBar.x, Math.min(previewSeekBar.x + previewSeekBar.width - previewSeekHandle.width, mouseX - previewSeekHandle.width / 2));
				previewSeekHandle.x = newX;

				// Update audio position
				var progress = (newX - previewSeekBar.x) / (previewSeekBar.width - previewSeekHandle.width);
				var newTime = progress * previewInst.length;
				previewInst.time = newTime;

				// Sync vocals
				for (vocals in previewVocals) {
					if (vocals != null) vocals.time = newTime;
				}
			} else {
				isDraggingSeek = false;
			}
		}
	}

	function handleVolumeSliderInput()
	{
		if (previewVolumeSlider == null || previewVolumeHandle == null) return;

		// Check if mouse is over volume slider
		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;
		var overVolumeSlider = mouseX >= previewVolumeSlider.x && mouseX <= previewVolumeSlider.x + previewVolumeSlider.width &&
							   mouseY >= previewVolumeSlider.y - 8 && mouseY <= previewVolumeSlider.y + previewVolumeSlider.height + 8;

		if (overVolumeSlider && FlxG.mouse.justPressed) {
			isDraggingVolume = true;
		}

		if (isDraggingVolume) {
			if (FlxG.mouse.pressed) {
				// Update handle position
				var newX = Math.max(previewVolumeSlider.x, Math.min(previewVolumeSlider.x + previewVolumeSlider.width - previewVolumeHandle.width, mouseX - previewVolumeHandle.width / 2));
				previewVolumeHandle.x = newX;

				// Update volume
				var progress = (newX - previewVolumeSlider.x) / (previewVolumeSlider.width - previewVolumeHandle.width);
				previewVolume = progress;

				// Apply volume to audio
				if (previewInst != null) previewInst.volume = previewVolume;
				for (vocals in previewVocals) {
					if (vocals != null) vocals.volume = previewVolume * 0.8;
				}

				// Update volume display
				updateVolumeDisplay();
			} else {
				isDraggingVolume = false;
			}
		}
	}

	function updateVolumeDisplay()
	{
		// Find and update volume text (now in the compact mini player area)
		for (member in members) {
			if (Std.isOfType(member, FlxText)) {
				var text = cast(member, FlxText);
				if (text.text.indexOf("%") != -1 && text.x > FlxG.width - 250) { // Adjusted for right-side positioning
					text.text = Math.round(previewVolume * 100) + "%";
					break;
				}
			}
		}
	}

	function handleVocalsScroll()
	{
		// Check if mouse is over vocals scroll area
		if (vocalsScrollBg == null) return;

		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;
		var overVocalsArea = mouseX >= vocalsScrollBg.x && mouseX <= vocalsScrollBg.x + vocalsScrollBg.width &&
							mouseY >= vocalsScrollBg.y && mouseY <= vocalsScrollBg.y + vocalsScrollBg.height;

		if (overVocalsArea && FlxG.mouse.wheel != 0) {
			// Scroll vocals content
			vocalsScrollOffset -= FlxG.mouse.wheel * 20; // Scroll speed

			// Clamp scroll bounds (basic implementation)
			var maxScroll = Math.max(0, (vocalsRemoveButtons.length * 25) - vocalsScrollMaxHeight);
			vocalsScrollOffset = Math.max(0, Math.min(maxScroll, vocalsScrollOffset));

			// Update positions of vocals items (simplified)
			updateVocalsDisplay();
		}
	}

	// Confirmation dialog
	function openConfirmDialog(message:String, onComplete:Bool -> Void)
	{
		// Create a simple confirmation dialog
		dialogBg = new FlxSprite(0, 0);
		dialogBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 150));
		add(dialogBg);

		dialogBox = new FlxSprite();
		dialogBox.makeGraphic(400, 200, FlxColor.BLACK);
		dialogBox.screenCenter();
		add(dialogBox);

		border = new FlxSprite(dialogBox.x - 2, dialogBox.y - 2);
		border.makeGraphic(404, 204, FlxColor.WHITE);
		add(border);
		dialogBox.x = border.x + 2;
		dialogBox.y = border.y + 2;

		messageText = new FlxText(dialogBox.x + 10, dialogBox.y + 20, dialogBox.width - 20, message, 14);
		messageText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(messageText);

		yesButton = new FlxUIButton(dialogBox.x + 50, dialogBox.y + 150, "Yes", function() {
			remove(dialogBg);
			remove(border);
			remove(dialogBox);
			remove(messageText);
			remove(yesButton);
			remove(noButton);
			onComplete(true);
		});
		yesButton.resize(80, 30);
		add(yesButton);

		noButton = new FlxUIButton(dialogBox.x + 270, dialogBox.y + 150, "No", function() {
			remove(dialogBg);
			remove(border);
			remove(dialogBox);
			remove(messageText);
			remove(yesButton);
			remove(noButton);
			onComplete(false);
		});
		noButton.resize(80, 30);
		add(noButton);
	}

	function checkAllPotentialOverwrites(songName:String, difficulty:String, targetMod:String):Array<String>
	{
		var overwrites:Array<String> = [];

		#if sys
		var formattedName = Paths.formatToSongPath(songName);

		// Determine paths based on mod
		var songDir:String;
		var chartPath:String;

		if (targetMod == "__mixtape__") {
			songDir = 'assets/songs/$formattedName/';
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
		} else {
			#if MODS_ALLOWED
			songDir = 'mods/$targetMod/songs/$formattedName/';
			chartPath = 'mods/$targetMod/data/$formattedName/$formattedName-$difficulty.json';
			#else
			songDir = 'assets/songs/$formattedName/';
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
			#end
		}

		// Check chart file
		if (FileSystem.exists(chartPath)) {
			overwrites.push('Chart: $formattedName-$difficulty.json');
		}

		// Check instrumental file (only if user has selected one)
		if (selectedInstPath != "" && FileSystem.exists(songDir + "Inst.ogg")) {
			overwrites.push('Instrumental: Inst.ogg');
		}

		// Check vocals file (only if user has selected vocals)
		if (selectedVocalsPaths.length > 0 && FileSystem.exists(songDir + "Voices.ogg")) {
			overwrites.push('Vocals: Voices.ogg');
		}

		// Check for additional vocals files that might be overwritten
		for (i in 0...selectedVocalsPaths.length) {
			var label = (i < vocalsLabels.length) ? vocalsLabels[i] : "Custom" + (i + 1);
			var vocalsFileName = 'Voices-$label.ogg';
			if (label == "Player") {
				vocalsFileName = "Voices.ogg"; // Main vocals file
			}

			if (FileSystem.exists(songDir + vocalsFileName) && overwrites.indexOf('Vocals: $vocalsFileName') == -1) {
				overwrites.push('Vocals: $vocalsFileName');
			}
		}
		#end

		return overwrites;
	}

	// GO Button callbacks
	function onSongGo()
	{
		var songName = songNameInput.text.trim();
		if (songName.length == 0) {
			showError("Song name is required!");
			return;
		}

		var difficulty = difficultyInput.text.trim();
		var targetMod = modDropDown.selectedLabel;

		// Check for overwrites before proceeding
		var overwriteFiles = checkGoButtonOverwrites(songName, difficulty, targetMod, true, false);
		if (overwriteFiles.length > 0) {
			var warningMsg = 'Warning: Creating this chart will OVERWRITE the following existing files:\n\n';
			for (file in overwriteFiles) {
				warningMsg += '• ' + file + '\n';
			}
			warningMsg += '\nDo you want to continue?';

			openConfirmDialog(warningMsg, function(confirmed:Bool) {
				if (confirmed) {
					proceedWithSongGo();
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			});
		} else {
			proceedWithSongGo();
		}
	}

	function proceedWithSongGo()
	{
		var songName = songNameInput.text.trim();
		var targetMod = modDropDown.selectedLabel;

		// Pre-fill audio paths if they exist
		var formattedName = Paths.formatToSongPath(songName);
		var songDir:String;

		if (targetMod == "__mixtape__") {
			songDir = 'assets/songs/$formattedName/';
		} else {
			#if MODS_ALLOWED
			songDir = 'mods/$targetMod/songs/$formattedName/';
			#else
			songDir = 'assets/songs/$formattedName/';
			#end
		}

		#if sys
		if (hasExistingInst && FileSystem.exists(songDir + "Inst.ogg")) {
			selectedInstPath = songDir + "Inst.ogg";
			instFileText.text = "Inst.ogg (auto-detected)";
			instFileText.color = FlxColor.GREEN;
		}

		if (hasExistingVocals && FileSystem.exists(songDir + "Voices.ogg")) {
			selectedVocalsPaths = [songDir + "Voices.ogg"];
			vocalsLabels = ["Player"];
			updateVocalsDisplay();
		}
		#end

		// Proceed with chart creation
		onCreate();
	}

	function onDifficultyGo()
	{
		var songName = songNameInput.text.trim();
		var difficulty = difficultyInput.text.trim();

		if (songName.length == 0 || difficulty.length == 0) {
			showError("Song name and difficulty are required!");
			return;
		}

		// Check if audio files are missing and required
		if (!hasExistingInst && selectedInstPath.length == 0) {
			showError("Please select an instrumental file before loading the chart!");
			return;
		}

		var targetMod = modDropDown.selectedLabel;

		// Check for overwrites if new audio files will be copied
		var overwriteFiles = checkGoButtonOverwrites(songName, difficulty, targetMod, false, true);
		if (overwriteFiles.length > 0) {
			var warningMsg = 'Warning: Loading this chart will OVERWRITE the following existing audio files:\n\n';
			for (file in overwriteFiles) {
				warningMsg += '• ' + file + '\n';
			}
			warningMsg += '\nDo you want to continue?';

			openConfirmDialog(warningMsg, function(confirmed:Bool) {
				if (confirmed) {
					proceedWithDifficultyGo();
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			});
		} else {
			proceedWithDifficultyGo();
		}
	}

	function proceedWithDifficultyGo()
	{
		var songName = songNameInput.text.trim();
		var difficulty = difficultyInput.text.trim();
		var targetMod = modDropDown.selectedLabel;
		var formattedName = Paths.formatToSongPath(songName);
		var chartPath:String;

		if (targetMod == "__mixtape__") {
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
		} else {
			#if MODS_ALLOWED
			chartPath = 'mods/$targetMod/data/$formattedName/$formattedName-$difficulty.json';
			#else
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
			#end
		}

		// If audio files are missing but selected, copy them first
		if (!hasExistingInst && selectedInstPath.length > 0) {
			#if sys
			copyAudioFilesImproved(songName, targetMod);
			#end
		}

		// Load the existing chart
		loadChartFromFile(chartPath);
	}

	function onLoadAutosave()
	{
		// Set mod directory to currently selected mod
		var targetMod = modDropDown.selectedLabel;
		#if MODS_ALLOWED
		if (targetMod != "__mixtape__") {
			Mods.currentModDirectory = targetMod;
		}
		#end

		var selectedEditor = chartEditorDropDown.selectedLabel;

		if (selectedEditor == "New") {
			// ChartingState - load backup file
			#if sys
			var foundBackup = false;
			if (FileSystem.exists("backups") && FileSystem.isDirectory("backups")) {
				var backupFiles = FileSystem.readDirectory("backups").filter(file -> file.endsWith('.bkp'));

				if (backupFiles.length > 0) {
					if (ClientPrefs.data.chartBackupSelection == "Recent") {
						// Auto-select most recent backup
						backupFiles.sort(function(a, b) {
							var statA = FileSystem.stat("backups/" + a);
							var statB = FileSystem.stat("backups/" + b);
							return Reflect.compare(statB.mtime.getTime(), statA.mtime.getTime());
						});

						// Load the most recent backup
						var mostRecent = "backups/" + backupFiles[0];
						loadChartFromFile(mostRecent);
						foundBackup = true;
					} else {
						// Show backup selection interface
						showBackupSelectionDialog(backupFiles);
						foundBackup = true;
					}
			}

			if (!foundBackup) {
				showError("No backup files found for the New chart editor!");
			}
			#else
			showError("Backup loading is not available in this build.");
			#end

		} else if (selectedEditor == "Old") {
			// ChartingStateOG - load from FlxSave
			if (FlxG.save.data.autosave != null) {
				try {
					// Parse and load the autosaved chart
					var autosaveData = haxe.Json.parse(FlxG.save.data.autosave);
					PlayfieldManager.SONG = autosaveData.song;

					// Switch to the Old chart editor to load the autosave
					var originalStyle = ClientPrefs.data.chartEditorStyle;
					ClientPrefs.data.chartEditorStyle = "Old";
					ClientPrefs.openChartEditor();
					ClientPrefs.data.chartEditorStyle = originalStyle;
				} catch (e:Dynamic) {
					showError("Error loading autosave data: " + e);
				}
			} else {
				showError("No autosave data found for the Old chart editor!");
			}

		} else if (selectedEditor == "Mixtape") {
			// MixtapeChartEditorState - no autosave feature
			showError("The Mixtape chart editor does not have autosave functionality.");
		}
	}
}

	function checkGoButtonOverwrites(songName:String, difficulty:String, targetMod:String, isNewChart:Bool, isLoadChart:Bool):Array<String>
	{
		var overwrites:Array<String> = [];

		#if sys
		var formattedName = Paths.formatToSongPath(songName);
		var songDir:String;

		if (targetMod == "__mixtape__") {
			songDir = 'assets/songs/$formattedName/';
		} else {
			#if MODS_ALLOWED
			songDir = 'mods/$targetMod/songs/$formattedName/';
			#else
			songDir = 'assets/songs/$formattedName/';
			#end
		}

		// For new chart creation (Song GO button)
		if (isNewChart) {
			// Check if we'll overwrite chart file when creating new
			var chartPath = getChartPath(songName, difficulty, targetMod);
			if (FileSystem.exists(chartPath)) {
				overwrites.push('Chart: $formattedName-$difficulty.json');
			}
		}

		// Check audio files only if user has selected new ones to copy
		if (selectedInstPath != "" && selectedInstPath != songDir + "Inst.ogg" && FileSystem.exists(songDir + "Inst.ogg")) {
			overwrites.push('Instrumental: Inst.ogg');
		}

		if (selectedVocalsPaths.length > 0) {
			// Check main vocals
			var wouldOverwriteMainVocals = false;
			for (path in selectedVocalsPaths) {
				if (path != songDir + "Voices.ogg") {
					wouldOverwriteMainVocals = true;
					break;
				}
			}
			if (wouldOverwriteMainVocals && FileSystem.exists(songDir + "Voices.ogg")) {
				overwrites.push('Vocals: Voices.ogg');
			}
		}
		#end

		return overwrites;
	}

	#if sys
	function showBackupSelectionDialog(backupFiles:Array<String>):Void
	{
		// Sort files alphabetically descending (similar to ChartingState)
		backupFiles.sort((a:String, b:String) -> (a.toUpperCase() < b.toUpperCase()) ? 1 : -1);

		// Create selection dialog background
		var selectionBg = new FlxSprite(0, 0);
		selectionBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 150));
		add(selectionBg);

		var dialogWidth = 450;
		var dialogHeight = 450; // Fixed height to accommodate pagination

		// Dialog box
		var selectionBox = new FlxSprite();
		selectionBox.makeGraphic(dialogWidth, Std.int(dialogHeight), FlxColor.BLACK);
		selectionBox.screenCenter();
		add(selectionBox);

		// Border
		var selectionBorder = new FlxSprite(selectionBox.x - 2, selectionBox.y - 2);
		selectionBorder.makeGraphic(dialogWidth + 4, Std.int(dialogHeight) + 4, FlxColor.WHITE);
		add(selectionBorder);
		selectionBox.x = selectionBorder.x + 2;
		selectionBox.y = selectionBorder.y + 2;

		// Title
		var titleText = new FlxText(selectionBox.x + 10, selectionBox.y + 20, selectionBox.width - 20, "Select a Backup to Load", 16);
		titleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Pagination setup
		var maxVisible = 10;
		var currentPage = 0;
		var totalPages = Math.ceil(backupFiles.length / maxVisible);
		var listHeight = Math.min(maxVisible, backupFiles.length);
		var buttons:Array<FlxUIButton> = [];
		var selectedIndex = 0;

		var loadButton:FlxUIButton;
		var cancelButton:FlxUIButton;

		// Page navigation variables
		var prevButton:FlxUIButton = null;
		var nextButton:FlxUIButton = null;
		var pageText:FlxText = null;

		// Define updatePageDisplay function first
		function updatePageDisplay() {
			// Clear current buttons
			for (button in buttons) {
				remove(button);
			}
			buttons = [];

			// Display files for current page
			var startIndex = currentPage * maxVisible;
			var endIndex = Math.min(startIndex + maxVisible, backupFiles.length);

			for (i in 0...(endIndex - startIndex).toNum()) {
				var fileIndex = startIndex + i;
				var fileButton = new FlxUIButton(selectionBox.x + 20, selectionBox.y + 60 + (i * 30), backupFiles[fileIndex], function() {
					selectedIndex = fileIndex;
					// Update button colors
					for (j in 0...buttons.length) {
						buttons[j].color = (startIndex + j == fileIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
					}
				});
				fileButton.resize(dialogWidth - 40, 25);
				fileButton.color = (i == 0) ? FlxColor.YELLOW : FlxColor.WHITE;
				add(fileButton);
				buttons.push(fileButton);
			}

			// Update page controls
			if (prevButton != null) prevButton.visible = currentPage > 0;
			if (nextButton != null) nextButton.visible = currentPage < totalPages - 1;
			if (pageText != null) pageText.text = 'Page ${currentPage + 1} / ${totalPages}';
		}

		// Page navigation setup (if multiple pages)

		if (totalPages > 1) {
			prevButton = new FlxUIButton(selectionBox.x + 20, selectionBox.y + dialogHeight - 120, "<", function() {
				if (currentPage > 0) {
					currentPage--;
					updatePageDisplay();
				}
			});
			prevButton.resize(30, 25);
			add(prevButton);

			nextButton = new FlxUIButton(selectionBox.x + dialogWidth - 50, selectionBox.y + dialogHeight - 120, ">", function() {
				if (currentPage < totalPages - 1) {
					currentPage++;
					updatePageDisplay();
				}
			});
			nextButton.resize(30, 25);
			add(nextButton);

			pageText = new FlxText(selectionBox.x + 60, selectionBox.y + dialogHeight - 115, dialogWidth - 120, 'Page ${currentPage + 1} / ${totalPages}', 12);
			pageText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			add(pageText);
		}

		// Initialize first page display
		updatePageDisplay();

		// Load button (moved down to avoid overlap)
		loadButton = new FlxUIButton(selectionBox.x + 50, selectionBox.y + dialogHeight - 50, "Load", function() {
			var selectedFile = "backups/" + backupFiles[selectedIndex];

			// Clean up dialog
			remove(selectionBg);
			remove(selectionBorder);
			remove(selectionBox);
			remove(titleText);
			for (button in buttons) remove(button);
			if (prevButton != null) remove(prevButton);
			if (nextButton != null) remove(nextButton);
			if (pageText != null) remove(pageText);
			remove(loadButton);
			remove(cancelButton);

			// Load the selected backup
			loadChartFromFile(selectedFile);
		});
		loadButton.resize(100, 30);
		add(loadButton);

		// Cancel button (moved down to avoid overlap)
		cancelButton = new FlxUIButton(selectionBox.x + dialogWidth - 150, selectionBox.y + dialogHeight - 50, "Cancel", function() {
			// Clean up dialog
			remove(selectionBg);
			remove(selectionBorder);
			remove(selectionBox);
			remove(titleText);
			for (button in buttons) remove(button);
			if (prevButton != null) remove(prevButton);
			if (nextButton != null) remove(nextButton);
			if (pageText != null) remove(pageText);
			remove(loadButton);
			remove(cancelButton);
		});
		cancelButton.resize(100, 30);
		add(cancelButton);
	}
	#end

	function updateVocalsDisplay()
	{
		// Reposition vocals items based on scroll offset
		for (i in 0...vocalsTexts.length) {
			if (i < vocalsTexts.length && vocalsTexts[i] != null) {
				var newY = vocalsScrollY + (i * 22) - vocalsScrollOffset;
				vocalsTexts[i].y = newY + 2; // +2 for vertical alignment
			}
		}

		for (i in 0...vocalsRemoveButtons.length) {
			if (i < vocalsRemoveButtons.length && vocalsRemoveButtons[i] != null) {
				var newY = vocalsScrollY + (i * 22) - vocalsScrollOffset;
				vocalsRemoveButtons[i].y = newY;
			}
		}

		for (i in 0...vocalsInputs.length) {
			if (i < vocalsInputs.length && vocalsInputs[i] != null) {
				var newY = vocalsScrollY + (i * 22) - vocalsScrollOffset;
				vocalsInputs[i].y = newY;
			}
		}
	}

	// File drop handling implementation
	override function handleFileDrop(filePath:String):Void
	{
		trace("File dropped: " + filePath);

		// Hide drag overlay if visible
		hideDragOverlay();

		// Validate file format
		if (!filePath.toLowerCase().endsWith(".ogg")) {
			showError("Only .ogg audio files are supported!");
			return;
		}

		// Check if file exists
		#if sys
		if (!FileSystem.exists(filePath)) {
			showError("File does not exist: " + filePath);
			return;
		}
		#end

		// Extract filename for display
		var filename = filePath.split("/").pop().split("\\").pop();

		// Ask user what type of file this should be using custom substate
		var fileTypePrompt = new FileTypeSelectionSubState(filename, function(fileType:String) {
			switch (fileType) {
				case "Instrumental":
					setInstrumentalFile(filePath, filename);
				case "Player":
					addVocalsFromDropWithType(filePath, filename, "Player");
				case "Opponent":
					addVocalsFromDropWithType(filePath, filename, "Opponent");
				case "GF":
					addVocalsFromDropWithType(filePath, filename, "GF");
				case "Custom":
					addVocalsFromDropWithType(filePath, filename, null); // Will prompt for custom name
				default:
					trace("User cancelled file drop");
			}
			closeSubState();
		});

		openSubState(fileTypePrompt);
	}

	function setInstrumentalFile(filePath:String, filename:String)
	{
		selectedInstPath = filePath;
		instFileText.text = filename;
		instFileText.color = FlxColor.WHITE;

		// Load audio immediately for optimization
		loadPreviewAudio();

		FlxG.sound.play(Paths.sound('confirmMenu'));
		showError("Instrumental file set: " + filename, FlxColor.GREEN);
	}

	function addVocalsFromDropWithType(filePath:String, filename:String, vocalType:String)
	{
		if (vocalType == null) {
			// Custom vocals - prompt for name using custom input substate
			var customPrompt = new CustomVocalInputSubState(function(result:String) {
				if (result != null && result.trim().length > 0) {
					addVocalsToListWithType(filePath, filename, result.trim());

					// Reload audio with new vocals
					loadPreviewAudio();

					FlxG.sound.play(Paths.sound('confirmMenu'));
					showError('Custom vocals file added: $filename as "${result.trim()}"', FlxColor.GREEN);
				}
				closeSubState();
			});
			openSubState(customPrompt);
		} else {
			addVocalsToListWithType(filePath, filename, vocalType);

			// Reload audio with new vocals
			loadPreviewAudio();

			FlxG.sound.play(Paths.sound('confirmMenu'));
			showError('$vocalType vocals file added: $filename', FlxColor.GREEN);
		}
	}

	function addVocalsToListWithType(filePath:String, filename:String, vocalType:String)
	{
		// Check if this vocal type is already added
		for (i in 0...vocalsLabels.length) {
			if (vocalsLabels[i] == vocalType) {
				showError('A "$vocalType" vocals file has already been added!');
				return;
			}
		}

		var index = selectedVocalsPaths.length;
		selectedVocalsPaths.push(filePath);
		vocalsLabels.push(vocalType);

		createVocalsListItem(filePath, filename, index);
	}

	function showDragOverlay()
	{
		isDragging = true;
		dragDropOverlay.visible = true;
		dragDropText.visible = true;
	}

	function hideDragOverlay()
	{
		isDragging = false;
		dragDropOverlay.visible = false;
		dragDropText.visible = false;
	}

	function isAnyTextFieldFocused():Bool
	{
		// Check main text fields
		if (songNameInput != null && songNameInput.hasFocus) return true;
		if (difficultyInput != null && difficultyInput.hasFocus) return true;

		// Check any vocals label inputs that might exist
		for (member in members) {
			if (Std.isOfType(member, FlxInputText)) {
				var textField = cast(member, FlxInputText);
				if (textField.hasFocus) return true;
			}
		}

		return false;
	}

	override function destroy()
	{
		// Disable cursor forcing
		forceCursor = false;

		// Clean up audio previews and mini player
		onFullStop();

		// Clean up metronome
		onStopMetronome();

		// Clean up drag overlay
		if (dragDropOverlay != null) {
			dragDropOverlay.destroy();
			dragDropOverlay = null;
		}
		if (dragDropText != null) {
			dragDropText.destroy();
			dragDropText = null;
		}

		// Clean up vocals UI
		for (text in vocalsTexts) {
			if (text != null) text.destroy();
		}
		for (button in vocalsRemoveButtons) {
			if (button != null) button.destroy();
		}

		vocalsTexts = [];
		vocalsRemoveButtons = [];
		selectedVocalsPaths = [];
		vocalsLabels = [];

		super.destroy();
	}

	/**
	 * Load preview audio (instrumental and vocals) for optimization
	 */
	function loadPreviewAudio()
	{
		// Clean up any existing audio first
		if (previewInst != null) {
			previewInst.stop();
			previewInst.destroy();
			previewInst = null;
		}

		for (vocals in previewVocals) {
			if (vocals != null) {
				vocals.stop();
				vocals.destroy();
			}
		}
		previewVocals = [];

		// Load instrumental
		if (selectedInstPath != "") {
			trace("Loading instrumental for preview: " + selectedInstPath);
			previewInst = loadAudioFromFile(selectedInstPath);
			if (previewInst != null) {
				previewInst.volume = previewVolume;
				trace("Pre-loaded instrumental, length: " + previewInst.length + "ms");
			}
		}

		// Load vocals
		for (i in 0...selectedVocalsPaths.length) {
			var vocalsPath = selectedVocalsPaths[i];
			trace("Pre-loading vocals: " + vocalsPath);

			var vocalsSound:FlxSound = loadAudioFromFile(vocalsPath);
			if (vocalsSound != null) {
				vocalsSound.volume = previewVolume * 0.8;
				previewVocals.push(vocalsSound);
				trace("Pre-loaded vocals: " + vocalsPath);
			}
		}
	}

	/**
	 * Load audio file using ImprovedFileHandling with bytes data for proper FlxSound creation
	 */
	function loadAudioFromFile(filePath:String):FlxSound
	{
		if (filePath == null || filePath.trim() == "") {
			trace("Invalid file path provided");
			return null;
		}

		try {
			#if sys
			// Method 1: Try using ImprovedFileHandling to read bytes and create OpenFL sound
			try {
				var audioBytes = sys.io.File.getBytes(filePath);
				if (audioBytes == null) {
					trace("Failed to read file bytes: " + filePath);
					return null;
				}

				trace("Successfully read " + audioBytes.length + " bytes from: " + filePath);

				// Create OpenFL Sound from bytes
				var openflSound = new openfl.media.Sound();
				openflSound.loadCompressedDataFromByteArray(audioBytes.getData(), audioBytes.length);

				// Create FlxSound from OpenFL Sound
				var sound = new FlxSound();
				sound.loadEmbedded(openflSound, false);

				if (sound.length > 0) {
					trace("Successfully loaded audio with bytes method, length: " + sound.length + "ms");
					return sound;
				} else {
					trace("Bytes method loaded but shows 0 length, trying alternative");
					sound.destroy();
				}
			} catch (e:Dynamic) {
				trace("Error with bytes loading method: " + e);
			}

			// Method 2: Try direct file:// URL approach
			try {
				var fileUrl = "file:///" + StringTools.replace(filePath, "\\", "/");
				var sound = FlxG.sound.load(fileUrl, 1.0, false, false);
				if (sound != null && sound.length > 0) {
					trace("File URL loading successful, length: " + sound.length + "ms");
					return sound;
				} else if (sound != null) {
					sound.destroy();
				}
			} catch (e:Dynamic) {
				trace("Error with file URL method: " + e);
			}

			// Method 3: Try OpenFL Assets loading (copy to assets temporarily)
			try {
				// Copy file to assets/music temporarily for OpenFL to access
				var tempName = "temp_audio_" + Std.random(9999) + ".ogg";
				var tempPath = "./assets/music/" + tempName;
				sys.io.File.copy(filePath, tempPath);

				// Load via Paths system
				var sound = FlxG.sound.load(Paths.music(StringTools.replace(tempName, ".ogg", "")), 1.0, false, false);

				// Clean up temp file
				if (sys.FileSystem.exists(tempPath)) {
					sys.FileSystem.deleteFile(tempPath);
				}

				if (sound != null && sound.length > 0) {
					trace("Temporary assets loading successful, length: " + sound.length + "ms");
					return sound;
				} else if (sound != null) {
					sound.destroy();
				}
			} catch (e:Dynamic) {
				trace("Error with temporary assets method: " + e);
			}

			// Method 4: Final fallback - direct path with different loading approaches
			try {
				var sound = new FlxSound();
				sound.loadStream(filePath, false, false, null, function() {
					trace("Stream loading completed, length: " + sound.length + "ms");
				});

				// Give it a moment to load
				if (sound != null) {
					return sound;
				}
			} catch (e:Dynamic) {
				trace("Error with stream loading: " + e);
			}

			trace("All loading methods failed for: " + filePath);
			return null;

			#else
			// For non-sys platforms, use standard FlxG.sound.load
			var sound = FlxG.sound.load(filePath, 1.0, false, false);
			if (sound != null && sound.length > 0) {
				trace("Standard loading successful, length: " + sound.length + "ms");
				return sound;
			} else {
				trace("Standard loading failed for: " + filePath);
				if (sound != null) sound.destroy();
				return null;
			}
			#end
		} catch (e:Dynamic) {
			trace("Exception during audio loading: " + e);
			return null;
		}
	}

	// File existence checking functions
	function checkExistingFiles()
	{
		var songName = songNameInput.text.trim();
		var difficulty = difficultyInput.text.trim();
		var targetMod = modDropDown.selectedLabel;

		// Only check if inputs have changed
		if (songName == lastCheckedSong && difficulty == lastCheckedDifficulty && targetMod == lastCheckedMod) {
			return;
		}

		lastCheckedSong = songName;
		lastCheckedDifficulty = difficulty;
		lastCheckedMod = targetMod;

		// Reset states
		hasExistingInst = false;
		hasExistingVocals = false;
		hasExistingChart = false;

		if (songName.length == 0) {
			songGoButton.visible = false;
			difficultyGoButton.visible = false;
			return;
		}

		#if sys
		var formattedName = Paths.formatToSongPath(songName);
		var songDir:String;
		var chartPath:String;

		// Determine paths based on mod
		if (targetMod == "__mixtape__") {
			songDir = 'assets/songs/$formattedName/';
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
		} else {
			#if MODS_ALLOWED
			songDir = 'mods/$targetMod/songs/$formattedName/';
			chartPath = 'mods/$targetMod/data/$formattedName/$formattedName-$difficulty.json';
			#else
			songDir = 'assets/songs/$formattedName/';
			chartPath = 'assets/data/$formattedName/$formattedName-$difficulty.json';
			#end
		}

		// Check for audio files
		hasExistingInst = FileSystem.exists(songDir + "Inst.ogg");
		hasExistingVocals = FileSystem.exists(songDir + "Voices.ogg");

		// Check for chart file (only if difficulty is provided)
		if (difficulty.length > 0) {
			hasExistingChart = FileSystem.exists(chartPath);
		}

		// Update GO button visibility
		updateGoButtons();
		#end
	}

	function updateGoButtons()
	{
		// Difficulty GO button takes priority if chart exists
		if (hasExistingChart && difficultyInput.text.trim().length > 0) {
			difficultyGoButton.visible = true;
			songGoButton.visible = false;

			// Update color based on audio availability
			if (hasExistingInst) {
				difficultyGoButton.color = FlxColor.GREEN; // Ready to load chart
			} else {
				difficultyGoButton.color = FlxColor.YELLOW; // Chart exists but missing audio
			}
		} else if (hasExistingInst) {
			// Show song GO if audio files exist but no chart
			songGoButton.visible = true;
			difficultyGoButton.visible = false;
			songGoButton.color = FlxColor.CYAN; // Ready for new chart creation
		} else {
			// Hide both if no existing files
			songGoButton.visible = false;
			difficultyGoButton.visible = false;
		}
	}

	function updateAutosaveButton()
	{
		// Only update if the button has been created
		if (loadAutosaveButton == null) return;

		var selectedEditor = chartEditorDropDown.selectedLabel;
		var hasAutosave = false;

		// Check for autosave based on selected chart editor
		if (selectedEditor == "New") {
			// ChartingState - uses .bkp backup files in backups/ directory
			#if sys
			if (FileSystem.exists("backups") && FileSystem.isDirectory("backups")) {
				var backupFiles = FileSystem.readDirectory("backups").filter(file -> file.endsWith('.bkp'));
				hasAutosave = backupFiles.length > 0;
			}
			#end
		} else if (selectedEditor == "Old") {
			// ChartingStateOG - uses FlxG.save.data.autosave
			hasAutosave = (FlxG.save.data.autosave != null);
		} else if (selectedEditor == "Mixtape") {
			// MixtapeChartEditorState - no autosave, only layout
			hasAutosave = false;
		}

		loadAutosaveButton.visible = hasAutosave;
	}
}

// Custom substate for file type selection
class FileTypeSelectionSubState extends MusicBeatSubstate
{
	private var filename:String;
	private var onComplete:String->Void;
	private var bg:FlxSprite;
	private var buttons:Array<FlxUIButton> = [];
	private var titleText:FlxText;

	public function new(filename:String, onComplete:String->Void)
	{
		this.filename = filename;
		this.onComplete = onComplete;
		super();
	}

	override function create()
	{
		super.create();

		// Semi-transparent background
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 150));
		add(bg);

		// Dialog box
		var dialogBox = new FlxSprite(0, 0);
		dialogBox.makeGraphic(500, 350, FlxColor.fromRGB(40, 40, 40, 255));
		dialogBox.screenCenter();
		add(dialogBox);

		// Title
		titleText = new FlxText(0, dialogBox.y + 20, dialogBox.width, 'What type of audio file is "$filename"?', 18);
		titleText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Buttons
		var buttonLabels = ["Instrumental", "Player Vocals", "Opponent Vocals", "GF Vocals", "Custom Vocals", "Cancel"];
		var buttonTypes = ["Instrumental", "Player", "Opponent", "GF", "Custom", "Cancel"];

		for (i in 0...buttonLabels.length) {
			var button = new FlxUIButton(dialogBox.x + 50, dialogBox.y + 80 + (i * 40), buttonLabels[i], function() {
				var selectedType = buttonTypes[i];
				if (onComplete != null) onComplete(selectedType);
			});
			button.resize(400, 30);
			buttons.push(button);
			add(button);
		}
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK) {
			if (onComplete != null) onComplete("Cancel");
		}
		super.update(elapsed);
	}
}

// Custom substate for vocal type input
class CustomVocalInputSubState extends MusicBeatSubstate
{
	private var onComplete:String->Void;
	private var bg:FlxSprite;
	private var input:FlxInputText;
	private var okButton:FlxUIButton;
	private var cancelButton:FlxUIButton;
	private var titleText:FlxText;

	public function new(onComplete:String->Void)
	{
		this.onComplete = onComplete;
		super();
	}

	override function create()
	{
		super.create();

		// Semi-transparent background
		bg = new FlxSprite(0, 0);
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 150));
		add(bg);

		// Dialog box
		var dialogBox = new FlxSprite(0, 0);
		dialogBox.makeGraphic(450, 200, FlxColor.fromRGB(40, 40, 40, 255));
		dialogBox.screenCenter();
		add(dialogBox);

		// Title
		titleText = new FlxText(0, dialogBox.y + 20, dialogBox.width, 'Enter custom vocal type name\n(e.g., "Chromatic", "Harmony")', 16);
		titleText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Input field
		input = new FlxInputText(dialogBox.x + 50, dialogBox.y + 80, 350, "Custom", 16, FlxColor.BLACK, FlxColor.WHITE);
		input.filterMode = FlxInputText.ONLY_ALPHANUMERIC;
		add(input);

		// OK Button
		okButton = new FlxUIButton(dialogBox.x + 80, dialogBox.y + 130, "OK", function() {
			if (onComplete != null) onComplete(input.text);
		});
		okButton.resize(100, 30);
		add(okButton);

		// Cancel Button
		cancelButton = new FlxUIButton(dialogBox.x + 270, dialogBox.y + 130, "Cancel", function() {
			if (onComplete != null) onComplete(null);
		});
		cancelButton.resize(100, 30);
		add(cancelButton);
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK) {
			// Don't allow back button if text field is focused
			if (input == null || !input.hasFocus) {
				if (onComplete != null) onComplete(null);
			}
		}
		super.update(elapsed);
	}
}
