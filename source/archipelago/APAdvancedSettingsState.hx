package archipelago;

import archipelago.APEntryState;
import archipelago.APInfo;
import archipelago.APVersionSelectionState;
import archipelago.CustomAPLogic;
import archipelago.substates.InfoPanelSubstate;
import archipelago.substates.NumberInputSubstate;
import archipelago.substates.TextInputSubstate;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.WeekData;
import backend.ui.*;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxGradient;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import haxe.Exception;
import haxe.crypto.Base64;
import openfl.geom.Rectangle;
import options.*;
import states.*;
import substates.Prompt;
import substates.SongSelectSubState;
import yaml.Renderer;
import yaml.Yaml;
import yutautil.GenericProgressSubstate;

using yutautil.CollectionUtils;

// Callback function type for settings options
typedef SettingsCallback = Void->Void;

// Context menu option structure
typedef ContextMenuOption =
{
	var label:String;
	var value:Dynamic;
	var callback:Void->Void;
	var isSelected:Bool;
}

// Context menu types
enum ContextMenuType
{
	ENUM_SELECT(options:Array<ContextMenuOption>);
	BOOLEAN(trueLabel:String, falseLabel:String);
	EDIT_VALUE(editCallback:Void->Void);
}

// Settings option structure
typedef SettingsOption =
{
	var name:String;
	var description:String;
	var callback:SettingsCallback;
	var locked:Bool;
	var contextMenu:ContextMenuType; // Add context menu support
}

// State option structure for complex settings that open other states
typedef StateOption =
{
	var name:String;
	var description:String;
	var stateClass:Class<MusicBeatState>;
	var stateArgs:Array<Dynamic>;
	var allowedStates:Array<Class<MusicBeatState>>; // State classes that are allowed, preventing return to AP settings
	var variablesToCapture:Array<String>; // Variables to capture from the state when returning
	var locked:Bool;
}

// Page structure for organizing settings
typedef SettingsPage =
{
	var name:String;
	var description:String;
	var options:Array<SettingsOption>;
	var stateOptions:Array<StateOption>; // Separate array for state options
	var color:FlxColor;
}

// Slider control structure
typedef SliderControl =
{
	var background:FlxSprite;
	var handle:FlxSprite;
	var valueText:FlxText;
	var minValue:Float;
	var maxValue:Float;
	var currentValue:Float;
	var stepSize:Float;
	var isDragging:Bool;
	var onUpdate:Int->Void;
}

class APAdvancedSettingsState extends MusicBeatState
{
	// Core visual elements
	var bg:FlxSprite;
	var gradientOverlay:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var pageIndicator:FlxText;
	var statsPanel:FlxSprite;
	var statsText:FlxText;

	// Navigation elements
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var closeButton:FlxSprite;
	var exportButton:FlxSprite;
	var importButton:FlxSprite;

	// Animation elements
	var particles:FlxTypedGroup<FlxSprite>;
	var glowEffect:FlxSprite;

	// Pages system
	var pages:Array<SettingsPage> = [];
	var currentPage:Int = 0;
	var optionButtons:FlxTypedGroup<FlxSprite>;
	var optionTexts:FlxTypedGroup<FlxText>;

	// Button data tracking (since FlxSprite doesn't have setData/getData)
	var buttonData:Map<FlxSprite, Map<String, Dynamic>> = new Map();

	// Settings storage (similar to original)
	var progression_balancing:String = "normal";
	var accessibility:String = "full";
	var unlockType:String = "Per Song";
	var unlockMethod:String = "Song Completion";
	var gradeRequirement:String = "Any";
	var accRequirement:String = "Any";
	var allowMods:Bool = false;
	var includeSecrets:Bool = true;
	var includePico:Bool = true;
	var includeErect:Bool = true;
	var includeVanilla:Bool = true;
	// Player name setting
	var playerName:String = "Player";
	// Song selection settings with proper defaults
	var startingSong:String = "Tutorial";
	var victorySong:String = "Bopeebo";

	// Additional song data for display (icons, etc)
	var startingSongData:Dynamic = null;
	var victorySongData:Dynamic = null;
	var deathlink:Bool = false;

	// Filler weight settings
	var bbcWeight:Int = 3;
	var ghostChatWeight:Int = 3;
	var tutorialWeight:Int = 3;
	var svcWeight:Int = 3;
	var fakeTransWeight:Int = 3;
	var songswitchWeight:Int = 3;
	var resistanceWeight:Int = 3;
	var unoWeight:Int = 3;
	var pongWeight:Int = 3;
	var shieldWeight:Int = 3;
	var exLifeWeight:Int = 3;
	var MHPWeight:Int = 3;
	var MHPDWeight:Int = 3;

	// Navigation cooldown
	var navigationCooldown:Float = 0;
	var navigationDelay:Float = 0.15; // 150ms delay between navigation inputs
	var ticketPercent:Int = 25;
	var ticketWinPercent:Int = 75;
	var chartmodifierchance:Int = 5;
	var trapAmount:Int = 50;
	var songLimit:Int = 50;

	// Animation state
	var isAnimating:Bool = false;
	var transitionTime:Float = 0.3;

	// Temporary save system for state navigation
	static var tempSave:FlxSave;
	static var tempSaveData:Dynamic;

	// Slider controls
	var activeSliders:Map<String, SliderControl> = new Map();
	var selectedSlider:String = null;
	var isSliderActive:Bool = false;
	var sliderUpdateFunc:Float->Void = null;

	// Context menu system
	var contextMenuActive:Bool = false;
	var contextMenuBackground:FlxSprite;
	var contextMenuPanel:FlxSprite;
	var contextMenuButtons:FlxTypedGroup<FlxSprite>;
	var contextMenuTexts:FlxTypedGroup<FlxText>;
	var currentContextMenu:ContextMenuType;
	var contextMenuTarget:String; // Which option is showing the context menu

	// YAML import system
	var pendingYamlImport:archipelago.APYaml = null;

	// Constructors
	public function new(?yaml:archipelago.APYaml = null)
	{
		super();
		pendingYamlImport = yaml;
	}

	override function create()
	{
		super.create();

		// Initialize temporary save system
		initTempSave();

		// Check if we're returning from a state navigation
		if (tempSave != null && tempSave.data.shouldReturnToAdvancedSettings == true)
		{
			// Clear the return flag
			tempSave.data.shouldReturnToAdvancedSettings = false;
			var navContext = tempSave.data.navigationContext;
			tempSave.flush();

			// Load from temp data instead of regular settings
			loadFromTempData();

			// Show a brief notification about the navigation return
			if (navContext != null)
			{
				trace('Returned from navigation: $navContext');
			}
		}

		setupBackground();
		setupPages();
		setupUI();
		setupContextMenu();
		setupAnimations();

		// Initialize default song data
		initializeDefaultSongs();

		// Load current settings (skip if we already loaded from temp)
		if (tempSave == null || tempSave.data.shouldReturnToAdvancedSettings != false)
		{
			loadCurrentSettings();
		}

		// Animate in
		animateIn();

		// Setup particle system
		setupParticles();

		// Handle pending YAML import if one was provided
		if (pendingYamlImport != null)
		{
			// Delay the import to allow UI to fully initialize
			new FlxTimer().start(0.5, function(_)
			{
				importYamlData(pendingYamlImport);
			});
		}
	}

	function setupBackground()
	{
		// Dynamic gradient background
		bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF1a0d2e, 0xFF16213e, 0xFF0f3460], 1, 90);
		bg.scrollFactor.set();
		add(bg);

		// Animated overlay
		gradientOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, 0x33ff6b35, 0x00000000], 1, 0);
		gradientOverlay.scrollFactor.set();
		gradientOverlay.alpha = 0.6;
		add(gradientOverlay);

		// Animate overlay
		FlxTween.tween(gradientOverlay, {alpha: 0.8}, 2, {
			type: PINGPONG,
			ease: FlxEase.sineInOut
		});
	}

	// Helper functions for creating context menus
	function createEnumContextMenu(options:Array<String>, currentValue:String, setValue:String->Void):ContextMenuType
	{
		var contextOptions:Array<ContextMenuOption> = [];
		for (option in options)
		{
			contextOptions.push({
				label: option,
				value: option,
				callback: () ->
				{
					setValue(option);
					closeContextMenu();
					refreshCurrentPage();
				},
				isSelected: (option == currentValue) // Mark if this is the current selection
			});
		}
		return ENUM_SELECT(contextOptions);
	}

	function createBoolContextMenu(currentValue:Bool, setValue:Bool->Void, trueLabel:String = "ON", falseLabel:String = "OFF"):ContextMenuType
	{
		return BOOLEAN(trueLabel, falseLabel);
	}

	function createEditContextMenu(editCallback:Void->Void):ContextMenuType
	{
		return EDIT_VALUE(editCallback);
	}

	function importYamlData(yaml:archipelago.APYaml)
	{
		// Create import tasks for visual feedback
		var yamlFields = Reflect.fields(yaml.settings);

		var tasks = [
			GenericProgressSubstate.createTask("Preparing YAML import", function(results:Array<Dynamic>)
			{
				return "Import initialized";
			}),
			GenericProgressSubstate.createIterTask("Importing YAML settings", yamlFields, function(field:String)
			{
				if (Reflect.hasField(APEntryState.gameSettings.FNF, field))
				{
					var value:archipelago.APYaml.APOption = Reflect.field(yaml.settings, field);
					Reflect.setField(APEntryState.gameSettings.FNF, field, value);

					// Map YAML settings to local variables
					switch (field)
					{
						case "progression_balancing":
							progression_balancing = Std.string(value);
						case "accessibility":
							accessibility = Std.string(value);
						case "unlock_type":
							unlockType = Std.string(value);
						case "unlock_method":
							unlockMethod = Std.string(value);
						case "grade_requirement" | "graderequirement":
							gradeRequirement = Std.string(value);
						case "accuracy_requirement" | "accrequirement":
							accRequirement = Std.string(value);
						case "allow_mods" | "mods_enabled":
							allowMods = value == true;
						case "include_secrets":
							includeSecrets = value == true;
						case "include_pico":
							includePico = value == true;
						case "include_erect":
							includeErect = value == true;
						case "include_vanilla":
							includeVanilla = value == true;
						case "starting_song":
							startingSong = Std.string(value);
						case "victory_song":
							victorySong = Std.string(value);
						case "deathlink":
							deathlink = value == true;
						case "ticket_percent" | "ticket_percentage":
							ticketPercent = value;
						case "ticket_win_percent" | "ticket_win_percentage":
							ticketWinPercent = value;
						case "chart_modifier_chance" | "chart_modifier_change_chance":
							chartmodifierchance = value;
						case "trap_amount" | "trapAmount":
							trapAmount = value;
						case "song_limit":
							songLimit = value;
						// Filler weight settings
						case "bbcWeight":
							bbcWeight = value;
						case "ghostChatWeight":
							ghostChatWeight = value;
						case "tutorialWeight":
							tutorialWeight = value;
						case "songswitchWeight":
							songswitchWeight = value;
						case "resistanceWeight":
							resistanceWeight = value;
						case "unoWeight":
							unoWeight = value;
						case "pongWeight":
							pongWeight = value;
						case "svcWeight":
							svcWeight = value;
						case "fakeTransWeight":
							fakeTransWeight = value;
						case "shieldWeight":
							shieldWeight = value;
						case "exLifeWeight":
							exLifeWeight = value;
						case "MHPWeight":
							MHPWeight = value;
						case "MHPDWeight":
							MHPDWeight = value;
						// Handle any other potential fields that might exist
						default:
							trace('Unknown YAML field during import: $field = $value');
					}
				}
				return field + " imported";
			}),
			GenericProgressSubstate.createTask("Applying player name", function(results:Array<Dynamic>)
			{
				playerName = yaml.name;
				APEntryState.gameSettings.name = yaml.name;
				return "Player name set to: " + playerName;
			}),
			GenericProgressSubstate.createTask("Refreshing UI", function(results:Array<Dynamic>)
			{
				// Refresh the current page to show imported values
				loadPage(currentPage);
				return "UI refreshed";
			})
		];

		var progressSubstate = new GenericProgressSubstate("Importing YAML Configuration", tasks, function(results:Array<Dynamic>)
		{
			// On completion
			var successPrompt = new InfoPanelSubstate("YAML Import Complete",
				"YAML configuration has been successfully imported!\n\nPlayer: " + playerName + "\nSettings have been applied to the current configuration.",
				FlxColor.LIME);
			openSubState(successPrompt);
			pendingYamlImport = null; // Clear the pending import
		}, function(error:String, shouldThrow:Bool)
		{
			var errorPrompt = new InfoPanelSubstate("YAML Import Error", error, FlxColor.RED);
			openSubState(errorPrompt);
			pendingYamlImport = null; // Clear the pending import even on error
		}, function()
		{
			// On cancel
			pendingYamlImport = null; // Clear the pending import
		});

		openSubState(progressSubstate);
	}

	function setupPages()
	{
		// Main Settings Page
		var mainOptions:Array<SettingsOption> = [
			{
				name: "Player Name",
				description: "Set your player name",
				callback: () -> openPlayerNameInput(),
				locked: false,
				contextMenu: createEditContextMenu(() -> openPlayerNameInput())
			},
			{
				name: "Progression Balancing",
				description: "How items are distributed: disabled, normal, or extreme",
				callback: () -> cycleProgressionBalancing(),
				locked: false,
				contextMenu: createEnumContextMenu(["disabled", "normal", "extreme"], progression_balancing, (value) -> progression_balancing = value)
			},
			{
				name: "Accessibility",
				description: "full or minimal accessibility features",
				callback: () -> cycleAccessibility(),
				locked: false,
				contextMenu: createEnumContextMenu(["full", "minimal"], accessibility, (value) -> accessibility = value)
			},
			{
				name: "Unlock Type",
				description: "Per Song or Per Week unlocking",
				callback: () -> cycleUnlockType(),
				locked: false,
				contextMenu: createEnumContextMenu(["Per Song", "Per Week"], unlockType, (value) -> unlockType = value)
			},
			{
				name: "Unlock Method",
				description: "Note Checks, Song Completion, or Both",
				callback: () -> cycleUnlockMethod(),
				locked: false,
				contextMenu: createEnumContextMenu(["Note Checks", "Song Completion", "Both"], unlockMethod, (value) ->
				{
					unlockMethod = value;
					updateSongStats();
				})
			},
			{
				name: "DeathLink",
				description: "Enable/disable death synchronization",
				callback: () -> deathlink = !deathlink,
				locked: false,
				contextMenu: createBoolContextMenu(deathlink, (value) -> deathlink = value)
			}
		];

		// Songs & Content Page
		var songsOptions:Array<SettingsOption> = [
			{
				name: "Allow Mods",
				description: "Include modded songs in the pool",
				callback: () ->
				{
					allowMods = !allowMods;
					updateSongStats();
				},
				locked: false,
				contextMenu: createBoolContextMenu(allowMods, (value) ->
				{
					allowMods = value;
					updateSongStats();
				})
			},
			{
				name: "Include Secrets",
				description: "Include secret songs in the pool",
				callback: () ->
				{
					includeSecrets = !includeSecrets;
					updateSongStats();
				},
				locked: false,
				contextMenu: createBoolContextMenu(includeSecrets, (value) ->
				{
					includeSecrets = value;
					updateSongStats();
				})
			},
			{
				name: "Include Pico Mix",
				description: "Include pico mixes in the pool",
				callback: () ->
				{
					includePico = !includePico;
					updateSongStats();
				},
				locked: false,
				contextMenu: createBoolContextMenu(includePico, (value) ->
				{
					includePico = value;
					updateSongStats();
				})
			},
			{
				name: "Include Erect",
				description: "Include erect mixes in the pool",
				callback: () ->
				{
					includeErect = !includeErect;
					updateSongStats();
				},
				locked: false,
				contextMenu: createBoolContextMenu(includeErect, (value) ->
				{
					includeErect = value;
					updateSongStats();
				})
			},
			{
				name: "Include Vanilla",
				description: "Include base game songs (Base, Erect, Pico)",
				callback: () ->
				{
					includeVanilla = !includeVanilla;
					updateSongStats();
				},
				locked: false,
				contextMenu: createBoolContextMenu(includeVanilla, (value) ->
				{
					includeVanilla = value;
					updateSongStats();
				})
			},
			{
				name: "Starting Song",
				description: "Choose which song you start with",
				callback: () -> selectStartingSong(),
				locked: false,
				contextMenu: createEditContextMenu(() ->
				{
					startingSong = null;
					refreshCurrentPage();
				})
			},
			{
				name: "Victory Song",
				description: "Choose the final song for victory",
				callback: () -> selectVictorySong(),
				locked: false,
				contextMenu: createEditContextMenu(() ->
				{
					victorySong = null;
					refreshCurrentPage();
				})
			},
			{
				name: "Grade Requirement",
				description: "Minimum grade needed to complete songs",
				callback: () -> cycleGradeRequirement(),
				locked: false,
				contextMenu: createEnumContextMenu(APInfo.gradeList, gradeRequirement, (value) -> gradeRequirement = value)
			},
			{
				name: "Accuracy Requirement",
				description: "Minimum accuracy needed for completion",
				callback: () -> cycleAccuracyRequirement(),
				locked: false,
				contextMenu: createEnumContextMenu(APInfo.accuracyList, accRequirement, (value) -> accRequirement = value)
			}
		];

		// Advanced & Traps Page
		var trapsOptions:Array<SettingsOption> = [
			{
				name: "Trap Amount",
				description: "Total number of trap items (0-60)",
				callback: () -> adjustTrapAmount(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustTrapAmount())
			},
			{
				name: "Chart Modifier Chance",
				description: "Chance of getting chart modifiers (0-10)",
				callback: () -> adjustChartModifier(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustChartModifier())
			},
			{
				name: "Ticket Percentage",
				description: "Percentage of checks that are tickets (10-50%)",
				callback: () -> adjustTicketPercent(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustTicketPercent())
			},
			{
				name: "Ticket Win Percentage",
				description: "Percentage of tickets needed to win (50-90%)",
				callback: () -> adjustTicketWinPercent(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustTicketWinPercent())
			},
			{
				name: "Song Limit",
				description: "Maximum number of songs in your run",
				callback: () -> adjustSongLimit(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustSongLimit())
			}
		];

		// Filler Weights Page
		var fillerWeightsOptions:Array<SettingsOption> = [
			{
				name: "BBC Weight",
				description: "Weight for Blue Balls Curse Trap (0-10)",
				callback: () -> adjustBBCWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustBBCWeight())
			},
			{
				name: "Ghost Chat Weight",
				description: "Weight for Ghost Chat Trap (0-10)",
				callback: () -> adjustGhostChatWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustGhostChatWeight())
			},
			{
				name: "Tutorial Trap Weight",
				description: "Weight for the Tutorial Trap items (0-10)",
				callback: () -> adjustTutorialWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustTutorialWeight())
			},
			{
				name: "Song Switch Trap Weight",
				description: "Weight for the Song Switch Trap items (0-10)",
				callback: () -> adjustSongSwitchWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustSongSwitchWeight())
			},
			{
				name: "Resistance Trap Weight",
				description: "Weight for the Resistance Trap items (0-10)",
				callback: () -> adjustResistanceWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustResistanceWeight())
			},
			{
				name: "UNO Challenge Trap Weight",
				description: "Weight for the UNO Challenge Trap items (0-10)",
				callback: () -> adjustUNOWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustUNOWeight())
			},
			{
				name: "Pong Challenge Trap Weight",
				description: "Weight for the Pong Challenge Trap items (0-10)",
				callback: () -> adjustPongWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustPongWeight())
			},
			{
				name: "Extra Life Weight",
				description: "Weight for Extra Life items (0-10)",
				callback: () -> adjustexLifeWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustexLifeWeight())
			},
			{
				name: "SVC Weight",
				description: "Weight for Streamer Vs. Chat items (0-10)",
				callback: () -> adjustSVCWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustSVCWeight())
			},
			{
				name: "Fake Transition Weight",
				description: "Weight for Fake Transition items (0-10)",
				callback: () -> adjustFakeTransWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustFakeTransWeight())
			},
			{
				name: "Shield Weight",
				description: "Weight for Shield items (0-10)",
				callback: () -> adjustShieldWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustShieldWeight())
			},
			{
				name: "Max HP Up Weight",
				description: "Weight for Max HP Up filler items (0-10)",
				callback: () -> adjustMHPWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustMHPWeight())
			},
			{
				name: "Max HP Down Weight",
				description: "Weight for Max HP Down filler items (0-10)",
				callback: () -> adjustMHPDWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustMHPDWeight())
			}
		];

		// Example state options (you can add actual complex settings states here)
		var exampleStateOptions:Array<StateOption> = [
			createStateOption("Song Selection (DO NOT CLICK!)", "Open advanced song selection interface",
				cast states.freeplay.FreeplayState, // Example: open freeplay for song selection
				[], // No constructor args
				[states.CategoryState], // Allow navigation to these states
				["selectedSongs", "difficulty"] // Variables to capture
			)
		];

		pages = [
			{
				name: "MAIN SETTINGS",
				description: "Core game configuration options",
				options: mainOptions,
				stateOptions: [],
				color: FlxColor.CYAN
			},
			{
				name: "SONGS & CONTENT",
				description: "Configure which songs and content to include",
				options: songsOptions,
				stateOptions: [],
				color: FlxColor.LIME
			},
			{
				name: "ADVANCED & TRAPS",
				description: "Fine-tune difficulty and trap settings",
				options: trapsOptions,
				stateOptions: exampleStateOptions, // Add state options to this page
				color: FlxColor.ORANGE
			},
			{
				name: "FILLER/ITEM/TRAP WEIGHTS",
				description: "Configure item and trap generation weights",
				options: fillerWeightsOptions,
				stateOptions: [],
				color: FlxColor.PURPLE
			}
		];
	}

	function setupUI()
	{
		// Title
		titleText = new FlxText(50, 30, FlxG.width - 100, "ARCHIPELAGO SETTINGS", 48);
		titleText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 3;
		add(titleText);

		// Description
		descriptionText = new FlxText(50, 110, FlxG.width - 100, "", 20);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		add(descriptionText);

		// Page indicator
		pageIndicator = new FlxText(50, FlxG.height - 140, FlxG.width - 100, "", 16);
		pageIndicator.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		pageIndicator.borderSize = 1;
		add(pageIndicator);

		// Navigation arrows
		leftArrow = new FlxSprite(30, Std.int(FlxG.height / 2) - 25);
		leftArrow.makeGraphic(50, 50, FlxColor.TRANSPARENT);
		leftArrow.loadGraphic(Paths.image("ui/arrow-left")); // You'll need arrow graphics
		if (leftArrow.pixels == null)
		{
			leftArrow.makeGraphic(40, 30, FlxColor.WHITE);
		}
		add(leftArrow);

		rightArrow = new FlxSprite(Std.int(FlxG.width - 80), Std.int(FlxG.height / 2) - 25);
		rightArrow.makeGraphic(50, 50, FlxColor.TRANSPARENT);
		rightArrow.loadGraphic(Paths.image("ui/arrow-right"));
		if (rightArrow.pixels == null)
		{
			rightArrow.makeGraphic(40, 30, FlxColor.WHITE);
		}
		add(rightArrow);

		// Bottom buttons - reorganize to make room for import button
		var buttonWidth = 120;
		var buttonSpacing = 20;
		var totalWidth = (buttonWidth * 3) + (buttonSpacing * 2);
		var startX = Std.int((FlxG.width - totalWidth) / 2);

		exportButton = new FlxSprite(startX, Std.int(FlxG.height - 80));
		exportButton.makeGraphic(buttonWidth, 50, FlxColor.GREEN);
		add(exportButton);

		var exportText = new FlxText(exportButton.x, exportButton.y + 10, exportButton.width, "EXPORT YAML", 14);
		exportText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		exportText.borderSize = 1;
		add(exportText);

		importButton = new FlxSprite(startX + buttonWidth + buttonSpacing, Std.int(FlxG.height - 80));
		importButton.makeGraphic(buttonWidth, 50, FlxColor.BLUE);
		add(importButton);

		var importText = new FlxText(importButton.x, importButton.y + 10, importButton.width, "IMPORT YAML", 14);
		importText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		importText.borderSize = 1;
		add(importText);

		closeButton = new FlxSprite(startX + (buttonWidth + buttonSpacing) * 2, Std.int(FlxG.height - 80));
		closeButton.makeGraphic(buttonWidth, 50, FlxColor.RED);
		add(closeButton);

		var closeText = new FlxText(closeButton.x, closeButton.y + 10, closeButton.width, "CLOSE", 14);
		closeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		closeText.borderSize = 1;
		add(closeText);

		// Stats panel
		setupStatsPanel();

		// Option buttons group
		optionButtons = new FlxTypedGroup<FlxSprite>();
		add(optionButtons);

		optionTexts = new FlxTypedGroup<FlxText>();
		add(optionTexts);

		// Load initial page
		loadPage(0);
	}

	function setupContextMenu()
	{
		// Context menu background (covers entire screen)
		contextMenuBackground = new FlxSprite(0, 0);
		contextMenuBackground.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 120));
		contextMenuBackground.visible = false;
		add(contextMenuBackground);

		// Context menu buttons and texts groups
		contextMenuButtons = new FlxTypedGroup<FlxSprite>();
		add(contextMenuButtons);

		contextMenuTexts = new FlxTypedGroup<FlxText>();
		add(contextMenuTexts);
	}

	function showContextMenu(optionName:String, contextMenu:ContextMenuType, x:Float, y:Float)
	{
		if (contextMenuActive)
			return;

		contextMenuActive = true;
		currentContextMenu = contextMenu;
		contextMenuTarget = optionName;

		// Show background
		contextMenuBackground.visible = true;

		// Clear existing menu
		contextMenuButtons.clear();
		contextMenuTexts.clear();

		switch (contextMenu)
		{
			case ENUM_SELECT(options):
				createEnumSelectMenu(options, x, y);
			case BOOLEAN(trueLabel, falseLabel):
				createBooleanMenu(trueLabel, falseLabel, x, y);
			case EDIT_VALUE(editCallback):
				// For edit values, just call the callback directly
				closeContextMenu();
				editCallback();
		}
	}

	function createEnumSelectMenu(options:Array<ContextMenuOption>, x:Float, y:Float)
	{
		var menuWidth = 200;
		var menuHeight = options.length * 35 + 10;

		// Position menu near cursor but keep it on screen
		var menuX = Math.min(x, FlxG.width - menuWidth - 10);
		var menuY = Math.min(y, FlxG.height - menuHeight - 10);

		// Create panel background
		contextMenuPanel = new FlxSprite(menuX, menuY);
		contextMenuPanel.makeGraphic(menuWidth, menuHeight, FlxColor.fromRGB(40, 40, 60));
		add(contextMenuPanel);

		for (i in 0...options.length)
		{
			var option = options[i];
			var buttonY = menuY + 5 + (i * 35);

			// Create button - use different color if this option is selected
			var button = new FlxSprite(menuX + 5, buttonY);
			var buttonColor = (option.isSelected == true) ? FlxColor.fromRGB(80, 120, 80) : FlxColor.fromRGB(60, 60, 100);
			button.makeGraphic(menuWidth - 10, 30, buttonColor);
			button.ID = i;
			contextMenuButtons.add(button);

			// Create text - add checkmark for selected option
			var labelText = option.label;
			if (option.isSelected == true)
			{
				labelText = "✓ " + option.label;
			}
			var text = new FlxText(button.x + 5, button.y + 7, button.width - 10, labelText, 14);
			var textColor = (option.isSelected == true) ? FlxColor.LIME : FlxColor.WHITE;
			text.setFormat(Paths.font("vcr.ttf"), 14, textColor, LEFT, OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			text.ID = i;
			contextMenuTexts.add(text);
		}
	}

	function createBooleanMenu(trueLabel:String, falseLabel:String, x:Float, y:Float)
	{
		var menuWidth = 150;
		var menuHeight = 80;

		var menuX = Math.min(x, FlxG.width - menuWidth - 10);
		var menuY = Math.min(y, FlxG.height - menuHeight - 10);

		// Create panel background
		contextMenuPanel = new FlxSprite(menuX, menuY);
		contextMenuPanel.makeGraphic(menuWidth, menuHeight, FlxColor.fromRGB(40, 40, 60));
		add(contextMenuPanel);

		// True option
		var trueButton = new FlxSprite(menuX + 5, menuY + 5);
		trueButton.makeGraphic(menuWidth - 10, 30, FlxColor.fromRGB(60, 100, 60));
		trueButton.ID = 1; // true
		contextMenuButtons.add(trueButton);

		var trueText = new FlxText(trueButton.x + 5, trueButton.y + 7, trueButton.width - 10, trueLabel, 14);
		trueText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		trueText.borderSize = 1;
		trueText.ID = 1;
		contextMenuTexts.add(trueText);

		// False option
		var falseButton = new FlxSprite(menuX + 5, menuY + 40);
		falseButton.makeGraphic(menuWidth - 10, 30, FlxColor.fromRGB(100, 60, 60));
		falseButton.ID = 0; // false
		contextMenuButtons.add(falseButton);

		var falseText = new FlxText(falseButton.x + 5, falseButton.y + 7, falseButton.width - 10, falseLabel, 14);
		falseText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		falseText.borderSize = 1;
		falseText.ID = 0;
		contextMenuTexts.add(falseText);
	}

	function closeContextMenu()
	{
		if (!contextMenuActive)
			return;

		contextMenuActive = false;
		contextMenuBackground.visible = false;

		if (contextMenuPanel != null)
		{
			remove(contextMenuPanel);
			contextMenuPanel = null;
		}

		contextMenuButtons.clear();
		contextMenuTexts.clear();
	}

	function handleContextMenuInput()
	{
		// Close context menu on escape or back
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			closeContextMenu();
			return;
		}

		// Handle hover effects for context menu buttons and text
		for (i in 0...contextMenuButtons.length)
		{
			var button = contextMenuButtons.members[i];
			var text = contextMenuTexts.members[i];

			if (button != null && text != null)
			{
				if (FlxG.mouse.overlaps(button))
				{
					// Hover effect - brighten button and make text yellow
					button.color = FlxColor.fromRGB(120, 120, 160);
					text.color = FlxColor.YELLOW;
				}
				else
				{
					// Normal state - return to original colors based on context menu type
					switch (currentContextMenu)
					{
						case ENUM_SELECT(options):
							if (i < options.length && options[i].isSelected == true)
							{
								// Selected option gets green tint and lime text
								button.color = FlxColor.fromRGB(80, 120, 80);
								text.color = FlxColor.LIME;
							}
							else
							{
								// Unselected options get default colors
								button.color = FlxColor.fromRGB(60, 60, 100);
								text.color = FlxColor.WHITE;
							}
						case BOOLEAN(_, _):
							if (i == 1)
							{
								button.color = FlxColor.fromRGB(60, 100, 60); // True button green
								text.color = FlxColor.WHITE;
							}
							else
							{
								button.color = FlxColor.fromRGB(100, 60, 60); // False button red
								text.color = FlxColor.WHITE;
							}
						default:
							button.color = FlxColor.fromRGB(60, 60, 100);
							text.color = FlxColor.WHITE;
					}
				}
			}
		}

		// Handle mouse input for context menu
		if (FlxG.mouse.justPressed)
		{
			var clickedButton = -1;

			// Check if we clicked on a context menu button
			for (i in 0...contextMenuButtons.length)
			{
				var button = contextMenuButtons.members[i];
				if (button != null && FlxG.mouse.overlaps(button))
				{
					clickedButton = button.ID;
					break;
				}
			}

			if (clickedButton >= 0)
			{
				handleContextMenuClick(clickedButton);
			}
			else
			{
				// Clicked outside menu, close it
				closeContextMenu();
			}
		}
	}

	function handleContextMenuClick(buttonIndex:Int)
	{
		switch (currentContextMenu)
		{
			case ENUM_SELECT(options):
				if (buttonIndex < options.length)
				{
					var option = options[buttonIndex];
					option.callback();
					FlxG.sound.play(Paths.sound('scrollMenu'));
					refreshCurrentPage();
				}
			case BOOLEAN(trueLabel, falseLabel):
				// buttonIndex 1 = true, 0 = false
				var newValue = buttonIndex == 1;
				// Find the option and update it
				for (option in pages[currentPage].options)
				{
					if (option.name == contextMenuTarget)
					{
						// Update the boolean value (implementation depends on your data structure)
						if (option.callback != null)
						{
							option.callback(); // This should toggle the boolean
						}
						FlxG.sound.play(Paths.sound('scrollMenu'));
						refreshCurrentPage();
						break;
					}
				}
			case EDIT_VALUE(editCallback):
				// This case shouldn't happen here as EDIT_VALUE calls callback directly
		}

		closeContextMenu();
	}

	function setupStatsPanel()
	{
		// Instead of always visible panel, create a stats button
		statsPanel = new FlxSprite(FlxG.width - 100, 80);
		statsPanel.makeGraphic(80, 40, FlxColor.fromRGB(60, 60, 100));
		statsPanel.alpha = 0.9;
		add(statsPanel);

		var statsButtonText = new FlxText(statsPanel.x, statsPanel.y + 10, statsPanel.width, "STATS", 14);
		statsButtonText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		statsButtonText.borderSize = 1;
		add(statsButtonText);

		// Store the stats text for the info panel
		statsText = new FlxText(0, 0, 0, "", 12);
		updateSongStats();
	}

	function showStatsPanel()
	{
		var statsTitle = "SONG STATISTICS";
		openSubState(new InfoPanelSubstate(statsTitle, statsText.text, FlxColor.ORANGE));
	}

	function setupAnimations()
	{
		// Glow effect for title
		glowEffect = new FlxSprite(titleText.x - 10, titleText.y - 10);
		glowEffect.makeGraphic(Std.int(titleText.width + 20), Std.int(titleText.height + 20), FlxColor.CYAN);
		glowEffect.alpha = 0;
		insert(members.indexOf(titleText), glowEffect);

		FlxTween.tween(glowEffect, {alpha: 0.3}, 1.5, {
			type: PINGPONG,
			ease: FlxEase.sineInOut
		});
	}

	function setupParticles()
	{
		particles = new FlxTypedGroup<FlxSprite>();
		add(particles);

		// Create floating particles
		for (i in 0...20)
		{
			var particle = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			particle.makeGraphic(3, 3, FlxColor.WHITE);
			particle.alpha = FlxG.random.float(0.1, 0.5);
			particles.add(particle);

			// Animate particles
			FlxTween.tween(particle, {y: particle.y - FlxG.random.float(100, 300)}, FlxG.random.float(5, 10), {
				type: LOOPING,
				ease: FlxEase.sineInOut,
				onComplete: function(_)
				{
					particle.y = FlxG.height + 10;
					particle.x = FlxG.random.float(0, FlxG.width);
				}
			});
		}
	}

	function loadPage(pageIndex:Int)
	{
		if (pageIndex < 0 || pageIndex >= pages.length)
			return;

		currentPage = pageIndex;
		var page = pages[currentPage];

		// Clear existing options
		optionButtons.clear();
		optionTexts.clear();

		// Update page info
		descriptionText.text = page.description;
		pageIndicator.text = '${currentPage + 1} / ${pages.length} - ${page.name}';

		// Change title color based on page
		titleText.color = page.color;
		if (glowEffect != null)
		{
			glowEffect.color = page.color;
		}

		// Create option buttons (both regular and state options)
		var startY:Float = 140;
		var spacing:Float = 40; // Reduced spacing for more compact layout
		var optionIndex = 0;
		var totalOptions = page.options.length + page.stateOptions.length;
		var useCompactLayout = totalOptions > 8; // Use compact layout for pages with many options

		var leftColumnX = 60;
		var rightColumnX = Std.int(FlxG.width / 2) + 20;
		var buttonWidth = useCompactLayout ? Std.int((FlxG.width - 400) / 2) : FlxG.width - 350;
		var currentColumn = 0; // 0 for left, 1 for right

		// Add regular options
		for (i in 0...page.options.length)
		{
			var option = page.options[i];

			var xPos:Float;
			var yPos:Float;

			if (useCompactLayout)
			{
				// Two-column layout for pages with many options
				xPos = currentColumn == 0 ? leftColumnX : rightColumnX;
				yPos = startY + (Math.floor(optionIndex / 2) * spacing);
				currentColumn = (currentColumn + 1) % 2;
			}
			else
			{
				// Single column layout for pages with few options
				xPos = 100;
				yPos = startY + (optionIndex * spacing);
			}

			// Create button - start off-screen for animation
			var button = new FlxSprite(FlxG.width, yPos);
			button.makeGraphic(buttonWidth, useCompactLayout ? 35 : 40, option.locked ? FlxColor.GRAY : FlxColor.fromRGB(40, 40, 80));
			button.ID = optionIndex;
			// Store button data using our custom system
			buttonData.set(button, ["type" => "regular", "index" => i]);
			optionButtons.add(button);

			// Create text - start off-screen for animation
			var text = new FlxText(FlxG.width + 10, yPos + (useCompactLayout ? 8 : 10), button.width - 20, option.name, useCompactLayout ? 14 : 16);
			text.setFormat(Paths.font("vcr.ttf"), useCompactLayout ? 14 : 16, option.locked ? FlxColor.GRAY : FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			text.ID = optionIndex;
			optionTexts.add(text);

			// Add current value display
			var valueText = getCurrentValueText(option.name);
			if (valueText != "")
			{
				var valueWidth = useCompactLayout ? 100 : 140;
				var valueDisplay = new FlxText(FlxG.width + 10, yPos + (useCompactLayout ? 8 : 10), valueWidth, valueText, useCompactLayout ? 12 : 14);
				valueDisplay.setFormat(Paths.font("vcr.ttf"), useCompactLayout ? 12 : 14, page.color, RIGHT, OUTLINE, FlxColor.BLACK);
				valueDisplay.borderSize = 1;
				valueDisplay.ID = optionIndex + 1000; // Use different ID range for value displays
				optionTexts.add(valueDisplay);
			}
			optionIndex++;
		}

		// Add state options
		for (i in 0...page.stateOptions.length)
		{
			var stateOption = page.stateOptions[i];

			var xPos:Float;
			var yPos:Float;

			if (useCompactLayout)
			{
				// Two-column layout for pages with many options
				xPos = currentColumn == 0 ? leftColumnX : rightColumnX;
				yPos = startY + (Math.floor(optionIndex / 2) * spacing);
				currentColumn = (currentColumn + 1) % 2;
			}
			else
			{
				// Single column layout for pages with few options
				xPos = 100;
				yPos = startY + (optionIndex * spacing);
			}

			// Create button (different color to distinguish state options) - start off-screen for animation
			var button = new FlxSprite(FlxG.width, yPos);
			button.makeGraphic(buttonWidth, useCompactLayout ? 35 : 40, stateOption.locked ? FlxColor.GRAY : FlxColor.fromRGB(60, 40, 80));
			button.ID = optionIndex;
			// Store button data using our custom system
			buttonData.set(button, ["type" => "state", "index" => i]);
			optionButtons.add(button);

			// Create text with indicator - start off-screen for animation
			var text = new FlxText(FlxG.width + 10, yPos + (useCompactLayout ? 8 : 10), button.width - 20, stateOption.name + " →", useCompactLayout ? 14 : 16);
			text.setFormat(Paths.font("vcr.ttf"), useCompactLayout ? 14 : 16, stateOption.locked ? FlxColor.GRAY : FlxColor.CYAN, LEFT, OUTLINE,
				FlxColor.BLACK);
			text.borderSize = 1;
			text.ID = optionIndex;
			optionTexts.add(text);

			optionIndex++;
		}

		// Animate page transition
		animatePageTransition();
	}

	function getCurrentValueText(optionName:String):String
	{
		return switch (optionName)
		{
			case "Player Name": playerName;
			case "Progression Balancing": progression_balancing;
			case "Accessibility": accessibility;
			case "Unlock Type": unlockType;
			case "Unlock Method": unlockMethod;
			case "DeathLink": deathlink ? "ON" : "OFF";
			case "Allow Mods": allowMods ? "ON" : "OFF";
			case "Include Secrets": includeSecrets ? "ON" : "OFF";
			case "Include Pico Mix": includePico ? "ON" : "OFF";
			case "Include Erect": includeErect ? "ON" : "OFF";
			case "Include Vanilla": includeVanilla ? "ON" : "OFF";
			case "Starting Song": startingSong != null ? startingSong : "RANDOM";
			case "Victory Song": victorySong != null ? victorySong : "RANDOM";
			case "Grade Requirement": gradeRequirement;
			case "Accuracy Requirement": accRequirement;
			case "Trap Amount": Std.string(trapAmount);
			case "Chart Modifier Chance": Std.string(chartmodifierchance);
			case "Ticket Percentage": ticketPercent + "%";
			case "Ticket Win Percentage": ticketWinPercent + "%";
			case "Song Limit": Std.string(songLimit);
			case "BBC Weight": Std.string(bbcWeight);
			case "Ghost Chat Weight": Std.string(ghostChatWeight);
			case "Tutorial Trap Weight": Std.string(tutorialWeight);
			case "Song Switch Trap Weight": Std.string(songswitchWeight);
			case "Resistance Trap Weight": Std.string(resistanceWeight);
			case "UNO Challenge Trap Weight": Std.string(unoWeight);
			case "Pong Challenge Trap Weight": Std.string(pongWeight);
			case "SVC Weight": Std.string(svcWeight);
			case "Fake Transition Weight": Std.string(fakeTransWeight);
			case "Shield Weight": Std.string(shieldWeight);
			case "Max HP Up Weight": Std.string(MHPWeight);
			case "Max HP Down Weight": Std.string(MHPDWeight);
			case "Extra Life Weight": Std.string(exLifeWeight);
			default: "";
		}
	}

	function animatePageTransition()
	{
		if (isAnimating)
			return;
		isAnimating = true;

		var completedAnimations = 0;
		var totalAnimations = optionButtons.members.length;

		if (totalAnimations == 0)
		{
			isAnimating = false;
			return;
		}

		// Calculate layout variables for this page
		var page = pages[currentPage];
		var totalOptions = page.options.length + page.stateOptions.length;
		var useCompactLayout = totalOptions > 8;
		var leftColumnX = 60;
		var rightColumnX = Std.int(FlxG.width / 2) + 20;
		var buttonWidth = useCompactLayout ? Std.int((FlxG.width - 400) / 2) : FlxG.width - 350;

		// Animate buttons
		for (i in 0...optionButtons.members.length)
		{
			var button = optionButtons.members[i];

			if (button != null)
			{
				button.x = FlxG.width;
				// Calculate the target X position based on the layout
				var targetX:Float;
				if (useCompactLayout)
				{
					// Compact layout - determine which column this button should be in
					var column = i % 2;
					targetX = column == 0 ? leftColumnX : rightColumnX;
				}
				else
				{
					// Regular single-column layout
					targetX = 100;
				}

				FlxTween.tween(button, {x: targetX}, transitionTime + (i * 0.05), {
					ease: FlxEase.backOut,
					onComplete: function(_)
					{
						completedAnimations++;
						if (completedAnimations == totalAnimations)
						{
							isAnimating = false;
						}
					}
				});
			}
		}

		// Animate all text elements separately
		for (i in 0...optionTexts.members.length)
		{
			var text = optionTexts.members[i];

			if (text != null)
			{
				text.x = FlxG.width + 10;
				// Determine target X based on text content and positioning
				var targetX:Float;

				if (useCompactLayout)
				{
					// Compact layout - determine which column this text should be in
					var textIndex = text.ID < 1000 ? text.ID : text.ID - 1000; // Handle value displays
					var column = textIndex % 2;
					var baseX = column == 0 ? leftColumnX : rightColumnX;

					if (text.alignment == RIGHT)
					{
						// Value display text (right-aligned)
						targetX = baseX + buttonWidth - (useCompactLayout ? 110 : 150);
					}
					else
					{
						// Main option text (left-aligned)
						targetX = baseX + 10;
					}
				}
				else
				{
					// Regular single-column layout
					if (text.alignment == RIGHT)
					{
						targetX = 100 + (FlxG.width - 350) - 150;
					}
					else
					{
						targetX = 110;
					}
				}

				FlxTween.tween(text, {x: targetX}, transitionTime + (i * 0.05), {
					ease: FlxEase.backOut
				});
			}
		}
	}

	function animateIn()
	{
		// Animate UI elements in
		titleText.y = -100;
		FlxTween.tween(titleText, {y: 30}, 0.8, {ease: FlxEase.backOut});

		descriptionText.alpha = 0;
		FlxTween.tween(descriptionText, {alpha: 1}, 1.2, {ease: FlxEase.sineOut});

		leftArrow.x = -100;
		rightArrow.x = FlxG.width + 100;
		FlxTween.tween(leftArrow, {x: 30}, 1, {ease: FlxEase.backOut});
		FlxTween.tween(rightArrow, {x: FlxG.width - 80}, 1, {ease: FlxEase.backOut});

		exportButton.y = FlxG.height + 50;
		closeButton.y = FlxG.height + 50;
		FlxTween.tween(exportButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut});
		FlxTween.tween(closeButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut});
	}

	// Settings adjustment functions
	function cycleProgressionBalancing()
	{
		var options = ["disabled", "normal", "extreme"];
		var current = options.indexOf(progression_balancing);
		progression_balancing = options[(current + 1) % options.length];
	}

	function cycleAccessibility()
	{
		var options = ["full", "minimal"];
		var current = options.indexOf(accessibility);
		accessibility = options[(current + 1) % options.length];
	}

	function cycleUnlockType()
	{
		var options = ["Per Song", "Per Week"];
		var current = options.indexOf(unlockType);
		unlockType = options[(current + 1) % options.length];
	}

	function cycleUnlockMethod()
	{
		var options = ["Note Checks", "Song Completion", "Both"];
		var current = options.indexOf(unlockMethod);
		unlockMethod = options[(current + 1) % options.length];
		updateSongStats();
	}

	function cycleGradeRequirement()
	{
		var options = APInfo.gradeList;
		var current = options.indexOf(gradeRequirement);
		gradeRequirement = options[(current + 1) % options.length];
	}

	function cycleAccuracyRequirement()
	{
		var options = APInfo.accuracyList;
		var current = options.indexOf(accRequirement);
		accRequirement = options[(current + 1) % options.length];
	}

	function openPlayerNameInput()
	{
		var nameInput = new TextInputSubstate("Player Name", playerName, function(newName:String)
		{
			playerName = newName;
			refreshCurrentPage();
		}, function()
		{
			// Cancel callback - do nothing
		}, 30, // Max length
			"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_", // Allowed characters
			"Enter your player name for Archipelago", FlxColor.CYAN);
		openSubState(nameInput);
	}

	function adjustTrapAmount()
	{
		openSliderControl("Trap Amount", trapAmount, 0, 100, 50, function(value:Float)
		{
			trapAmount = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustChartModifier()
	{
		openSliderControl("Chart Modifier Chance", chartmodifierchance, 0, 10, 1, function(value:Float)
		{
			chartmodifierchance = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustTicketPercent()
	{
		openSliderControl("Ticket Percentage", ticketPercent, 10, 50, 5, function(value:Float)
		{
			ticketPercent = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustTicketWinPercent()
	{
		openSliderControl("Ticket Win Percentage", ticketWinPercent, 50, 90, 5, function(value:Float)
		{
			ticketWinPercent = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustSongLimit()
	{
		var maxSongs = calculateMaxAvailableSongs();
		openSliderControl("Song Limit", songLimit, 5, maxSongs, 1, function(value:Float)
		{
			songLimit = Std.int(value);
			updateSongStats();
			refreshCurrentPage();
		});
	}

	function adjustBBCWeight()
	{
		openSliderControl("BBC Trap Weight", bbcWeight, 0, 10, 1, function(value:Float)
		{
			bbcWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustGhostChatWeight()
	{
		openSliderControl("Ghost Chat Trap Weight", ghostChatWeight, 0, 10, 1, function(value:Float)
		{
			ghostChatWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustShieldWeight()
	{
		openSliderControl("Shield Item Weight", shieldWeight, 0, 10, 1, function(value:Float)
		{
			shieldWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustTutorialWeight()
	{
		openSliderControl("Tutorial Trap Weight", tutorialWeight, 0, 10, 1, function(value:Float)
		{
			tutorialWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustSongSwitchWeight()
	{
		openSliderControl("Song Switch Trap Weight", songswitchWeight, 0, 10, 1, function(value:Float)
		{
			songswitchWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustResistanceWeight()
	{
		openSliderControl("Resistance Trap Weight", resistanceWeight, 0, 10, 1, function(value:Float)
		{
			resistanceWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustUNOWeight()
	{
		openSliderControl("UNO Challenge Trap Weight", unoWeight, 0, 10, 1, function(value:Float)
		{
			unoWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustPongWeight()
	{
		openSliderControl("Pong Challenge Trap Weight", pongWeight, 0, 10, 1, function(value:Float)
		{
			pongWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustexLifeWeight()
	{
		openSliderControl("Extra Life Weight", exLifeWeight, 0, 10, 1, function(value:Float)
		{
			exLifeWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustSVCWeight()
	{
		openSliderControl("Streamer Vs. Chat Weight", svcWeight, 0, 10, 1, function(value:Float)
		{
			svcWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustFakeTransWeight()
	{
		openSliderControl("Fake Transition Weight", fakeTransWeight, 0, 10, 1, function(value:Float)
		{
			fakeTransWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustMHPWeight()
	{
		openSliderControl("Max HP Up Weight", MHPWeight, 0, 10, 1, function(value:Float)
		{
			MHPWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function adjustMHPDWeight()
	{
		openSliderControl("Max HP Down Weight", MHPDWeight, 0, 10, 1, function(value:Float)
		{
			MHPDWeight = Std.int(value);
			refreshCurrentPage();
		});
	}

	function openEnumSelectionPrompt(title:String, options:Array<ContextMenuOption>)
	{
		var enumSubstate = new EnumSelectionSubstate(title, options, function(selectedOption:ContextMenuOption)
		{
			// Directly set the value based on the option name and selected value
			setOptionValue(title, selectedOption.value);
			refreshCurrentPage();
		});
		openSubState(enumSubstate);
	}

	function openBooleanSelectionPrompt(title:String, trueLabel:String, falseLabel:String)
	{
		var boolOptions:Array<ContextMenuOption> = [
			{
				label: falseLabel,
				value: "false",
				callback: () -> {}, // Not used anymore
				isSelected: getCurrentBooleanValue(title) == false
			},
			{
				label: trueLabel,
				value: "true",
				callback: () -> {}, // Not used anymore
				isSelected: getCurrentBooleanValue(title) == true
			}
		];

		var enumSubstate = new EnumSelectionSubstate(title, boolOptions, function(selectedOption:ContextMenuOption)
		{
			// Directly set the boolean value based on the selected option
			var boolValue = selectedOption.value == "true";
			setOptionValue(title, boolValue);
			refreshCurrentPage();
		});
		openSubState(enumSubstate);
	}

	function setOptionValue(optionName:String, value:Dynamic)
	{
		switch (optionName)
		{
			case "Progression Balancing":
				progression_balancing = Std.string(value);
			case "Accessibility":
				accessibility = Std.string(value);
			case "Unlock Type":
				unlockType = Std.string(value);
			case "Unlock Method":
				unlockMethod = Std.string(value);
				updateSongStats();
			case "Grade Requirement":
				gradeRequirement = Std.string(value);
			case "Accuracy Requirement":
				accRequirement = Std.string(value);
			case "DeathLink":
				deathlink = cast(value, Bool);
			case "Allow Mods":
				allowMods = cast(value, Bool);
				updateSongStats();
			case "Include Secrets":
				includeSecrets = cast(value, Bool);
				updateSongStats();
			case "Include Pico Mix":
				includePico = cast(value, Bool);
				updateSongStats();
			case "Include Erect":
				includeErect = cast(value, Bool);
				updateSongStats();
			case "Include Vanilla":
				includeVanilla = cast(value, Bool);
				updateSongStats();
			default:
				trace('Unknown option: $optionName');
		}
	}

	function getCurrentBooleanValue(optionName:String):Bool
	{
		return switch (optionName)
		{
			case "DeathLink": deathlink;
			case "Allow Mods": allowMods;
			case "Include Secrets": includeSecrets;
			case "Include Pico Mix": includePico;
			case "Include Erect": includeErect;
			case "Include Vanilla": includeVanilla;
			default: false;
		}
	}

	function selectStartingSong()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Save current state data
		saveTempData();

		// Open song selection substate
		var songSelectSubstate = new substates.SongSelectSubState("Select Starting Song");
		songSelectSubstate.onSongSelected = function(songData:Dynamic)
		{
			// Format song name for YAML export
			var formattedName:String = songData.songName;
			if (songData.folder != null && songData.folder.length > 0)
			{
				formattedName = songData.songName + " (" + songData.folder + ")";
			}

			startingSong = formattedName;
			startingSongData = songData;
			refreshCurrentPage();
		};
		songSelectSubstate.onCancel = function()
		{
			// Just close, no action needed
		};

		openSubState(songSelectSubstate);
	}

	function selectVictorySong()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Save current state data
		saveTempData();

		// Open song selection substate
		var songSelectSubstate = new substates.SongSelectSubState("Select Victory Song");
		songSelectSubstate.onSongSelected = function(songData:Dynamic)
		{
			// Format song name for YAML export
			var formattedName:String = songData.songName;
			if (songData.folder != null && songData.folder.length > 0)
			{
				formattedName = songData.songName + " (" + songData.folder + ")";
			}

			victorySong = formattedName;
			victorySongData = songData;
			refreshCurrentPage();
		};
		songSelectSubstate.onCancel = function()
		{
			// Just close, no action needed
		};

		openSubState(songSelectSubstate);
	}

	function initializeDefaultSongs()
	{
		// Set default category if CategoryState.loadWeekForce is null
		if (states.CategoryState.loadWeekForce == null)
		{
			states.CategoryState.loadWeekForce = "all";
		}

		// Create FreeplayManager with true parameter to ensure proper initialization
		var fpManager = new managers.FreeplayManager(true);

		// Set up default song data for Tutorial (first song in the list)
		if (fpManager != null && fpManager.songList != null && fpManager.songList.length > 0)
		{
			var firstSong = fpManager.songList[0];

			startingSongData = {
				songName: firstSong.songName,
				folder: firstSong.folder,
				week: firstSong.week,
				songCharacter: firstSong.songCharacter,
				index: 0
			};

			victorySongData = {
				songName: firstSong.songName,
				folder: firstSong.folder,
				week: firstSong.week,
				songCharacter: firstSong.songCharacter,
				index: 0
			};

			// Update the string values to match the first song
			startingSong = firstSong.songName;
			if (firstSong.folder != null && firstSong.folder.length > 0)
			{
				startingSong = firstSong.songName + " (" + firstSong.folder + ")";
			}

			victorySong = startingSong; // Same as starting song by default
		}
		else
		{
			trace("Warning: Could not initialize default songs - FreeplayManager or song list is null");
		}
	}

	function refreshCurrentPage()
	{
		// Only refresh if UI has been set up
		if (statsText == null)
			return;

		loadPage(currentPage);
		updateSongStats();
		saveTempData(); // Save changes
	}

	function updateSongStats()
	{
		// Calculate song counts and stats
		var totalSongs = 0;
		var totalChecks = 0;
		var modCount = backend.Mods.parseList().enabled.length;

		// Base game songs
		if (includeVanilla)
		{
			totalSongs += APInfo.baseGame.length;
		}

		// Secret songs
		if (includePico)
		{
			totalSongs += APInfo.basePico.length;
		}

		// Secret songs
		if (includeErect)
		{
			totalSongs += APInfo.baseErect.length;
		}

		// Secret songs
		if (includeSecrets)
		{
			totalSongs += APInfo.secrets.length;
		}

		// Mod songs (approximate)
		if (allowMods)
		{
			totalSongs += modCount * 3; // Rough estimate
		}

		// Calculate checks based on unlock method
		switch (unlockMethod)
		{
			case "Song Completion":
				var calc1 = totalSongs * 2;
				var calc2 = songLimit * 2;
				totalChecks = Std.int(Math.min(calc1, calc2));
			case "Note Checks":
				var calc1 = totalSongs * 3;
				var calc2 = songLimit * 3;
				totalChecks = Std.int(Math.min(calc1, calc2));
			case "Both":
				var calc1 = totalSongs * 5;
				var calc2 = songLimit * 5;
				totalChecks = Std.int(Math.min(calc1, calc2));
			default:
				totalChecks = songLimit;
		}

		var statsString = "=== CURRENT STATS ===\n\n";
		statsString += "Available Songs: " + totalSongs + "\n";
		statsString += "Song Limit: " + songLimit + "\n";
		statsString += "Expected Checks: " + totalChecks + "\n";
		statsString += "Trap Items: " + trapAmount + "\n";
		statsString += "Mods Enabled: " + modCount + "\n\n";

		statsString += "Content Included:\n";
		statsString += "• Vanilla: " + (includeVanilla ? "YES" : "NO") + "\n";
		statsString += "• Erect: " + (includeErect ? "YES" : "NO") + "\n";
		statsString += "• Pico: " + (includePico ? "YES" : "NO") + "\n";
		statsString += "• Secrets: " + (includeSecrets ? "YES" : "NO") + "\n";
		statsString += "• Mods: " + (allowMods ? "YES" : "NO") + "\n\n";

		statsString += "Victory Condition:\n";
		statsString += "Complete: " + victorySong + "\n";

		// Only update the text if statsText has been initialized
		if (statsText != null)
		{
			statsText.text = statsString;
		}
	}

	function showCaptureResult(data:String)
	{
		openSubState(new Prompt("State Data Captured\n\nCaptured from closed state:\n\n" + data, 0, null, null, false));
	}

	/**
	 * Creates a state option that opens another state with proper tracking
	 * @param name Display name for the option
	 * @param description Description of what the option does
	 * @param stateClass The state class to switch to
	 * @param stateArgs Arguments to pass to the state constructor
	 * @param allowedStates Additional state classes that are allowed (prevents return loop)
	 * @param variablesToCapture Variables to capture when returning from the state
	 * @return StateOption that can be added to a page
	 */
	static function createStateOption(name:String, description:String, stateClass:Class<MusicBeatState>, ?stateArgs:Array<Dynamic>,
			?allowedStates:Array<Class<MusicBeatState>>, ?variablesToCapture:Array<String>):StateOption
	{
		if (stateArgs == null)
			stateArgs = [];
		if (allowedStates == null)
			allowedStates = [];
		if (variablesToCapture == null)
			variablesToCapture = [];

		// Automatically add the source state (APAdvancedSettingsState) to allowed states
		allowedStates.push(APAdvancedSettingsState);

		return {
			name: name,
			description: description,
			stateClass: stateClass,
			stateArgs: stateArgs,
			allowedStates: allowedStates,
			variablesToCapture: variablesToCapture,
			locked: false
		};
	}

	/**
	 * Switches to a state with AP options tracking
	 * @param stateOption The state option to execute
	 */
	function executeStateOption(stateOption:StateOption)
	{
		if (stateOption.locked)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.camera.shake(0.01, 0.2);
			return;
		}

		// Save current state before switching
		saveTempData();

		// For now, disable the problematic MusicBeatState tracking and use a simpler approach
		// Set a flag that other states can check
		APAdvancedSettingsState.tempSave.data.shouldReturnToAdvancedSettings = true;
		APAdvancedSettingsState.tempSave.flush();

		// Create and switch to the target state
		var targetState = Type.createInstance(stateOption.stateClass, stateOption.stateArgs);
		FlxG.sound.play(Paths.sound('confirmMenu'));
		MusicBeatState.switchState(targetState);
	}

	function loadCurrentSettings()
	{
		// Load from APEntryState.gameSettings.FNF
		if (APEntryState.gameSettings != null && APEntryState.gameSettings.FNF != null)
		{
			var settings = APEntryState.gameSettings.FNF;
			progression_balancing = settings.progression_balancing;
			accessibility = settings.accessibility;
			unlockType = settings.unlock_type;
			unlockMethod = settings.unlock_method;
			gradeRequirement = settings.graderequirement;
			accRequirement = settings.accrequirement;
			deathlink = settings.deathlink;
			ticketPercent = settings.ticket_percentage;
			ticketWinPercent = settings.ticket_win_percentage;
			chartmodifierchance = settings.chart_modifier_change_chance;
			trapAmount = settings.trapAmount;
			songLimit = settings.song_limit;

			// Existing settings
			allowMods = settings.mods_enabled;

			// Filler weight settings
			bbcWeight = settings.bbcWeight;
			ghostChatWeight = settings.ghostChatWeight;
			tutorialWeight = settings.tutorialWeight;
			songswitchWeight = settings.songswitchWeight;
			resistanceWeight = settings.resistanceWeight;
			unoWeight = settings.unoWeight;
			pongWeight = settings.pongWeight;
			svcWeight = settings.svcWeight;
			fakeTransWeight = settings.fakeTransWeight;
			shieldWeight = settings.shieldWeight;
			MHPWeight = settings.MHPWeight;
			MHPDWeight = settings.MHPDWeight;
			exLifeWeight = settings.exLifeWeight;

			// New settings with defaults if they don't exist
			includeSecrets = Reflect.hasField(settings, "include_secrets") ? settings.include_secrets : true;
			includePico = Reflect.hasField(settings, "include_pico") ? settings.include_pico : true;
			includeErect = Reflect.hasField(settings, "include_erect") ? settings.include_erect : true;
			includeVanilla = Reflect.hasField(settings, "include_vanilla") ? settings.include_vanilla : true;
			startingSong = settings.starting_song != null ? settings.starting_song : "Tutorial";
			victorySong = settings.victory_song != null ? settings.victory_song : "Tutorial";
		}
	}

	function saveCurrentSettings()
	{
		// Save to APEntryState.gameSettings.FNF
		if (APEntryState.gameSettings != null && APEntryState.gameSettings.FNF != null)
		{
			var settings = APEntryState.gameSettings.FNF;
			settings.progression_balancing = progression_balancing;
			settings.accessibility = accessibility;
			settings.unlock_type = unlockType;
			settings.unlock_method = unlockMethod;
			settings.graderequirement = gradeRequirement;
			settings.accrequirement = accRequirement;
			settings.deathlink = deathlink;
			settings.ticket_percentage = ticketPercent;
			settings.ticket_win_percentage = ticketWinPercent;
			settings.chart_modifier_change_chance = chartmodifierchance;
			settings.trapAmount = trapAmount;
			settings.song_limit = songLimit;
			settings.mods_enabled = allowMods;

			// Save new settings
			settings.include_secrets = includeSecrets;
			settings.include_pico = includePico;
			settings.include_erect = includeErect;
			settings.include_vanilla = includeVanilla;
			settings.starting_song = startingSong;
			settings.victory_song = victorySong;

			// Save filler weight settings
			settings.bbcWeight = bbcWeight;
			settings.ghostChatWeight = ghostChatWeight;
			settings.tutorialWeight = tutorialWeight;
			settings.songswitchWeight = songswitchWeight;
			settings.resistanceWeight = resistanceWeight;
			settings.unoWeight = unoWeight;
			settings.pongWeight = pongWeight;
			settings.svcWeight = svcWeight;
			settings.fakeTransWeight = fakeTransWeight;
			settings.shieldWeight = shieldWeight;
			settings.MHPWeight = MHPWeight;
			settings.MHPDWeight = MHPDWeight;
			settings.exLifeWeight = exLifeWeight;
		}
	}

	function exportYAML()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Save current settings
		saveCurrentSettings();

		// Show export animation
		FlxFlicker.flicker(exportButton, 0.5, 0.1);

		// Create animated dialog
		var exportDialog = new FlxText(Std.int(FlxG.width / 2) - 200, Std.int(FlxG.height / 2) - 50, 400, "EXPORTING YAML...", 24);
		exportDialog.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		exportDialog.borderSize = 2;
		exportDialog.alpha = 0;
		add(exportDialog);

		FlxTween.tween(exportDialog, {alpha: 1}, 0.3, {
			onComplete: function(_)
			{
				// Perform actual export (using similar logic to original)
				try
				{
					performYAMLExport();

					exportDialog.text = "EXPORT COMPLETED!";
					exportDialog.color = FlxColor.GREEN;

					new FlxTimer().start(1.5, function(_)
					{
						FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
							onComplete: function(_)
							{
								remove(exportDialog);
							}
						});
					});
				}
				catch (e:Dynamic)
				{
					exportDialog.text = "EXPORT FAILED!";
					exportDialog.color = FlxColor.RED;
					trace('Export error: $e');

					new FlxTimer().start(2, function(_)
					{
						FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
							onComplete: function(_)
							{
								remove(exportDialog);
							}
						});
					});
				}
			}
		});
	}

	function performYAMLExport()
	{
		var checks = 0;

		while (APSettingsSubState.globalSongList.length == 0)
		{
			APSettingsSubState.generateSongList();
			checks++;
		}
		APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;

		if (APEntryState.gameSettings.FNF.songList.length == 0)
		{
			while (APEntryState.gameSettings.FNF.songList.length == 0)
			{
				APSettingsSubState.generateSongList();
				checks++;
				APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;
			}
		}

		// Process CustomAPLogic scripts before generating YAML
		trace('Processing CustomAPLogic scripts...');
		CustomAPLogic.APHScriptProcessor.processAllMods();

		var yamlThing = {};
		for (thing in Reflect.fields(APEntryState.gameSettings.FNF))
		{
			Reflect.setField(yamlThing, thing, Reflect.field(APEntryState.gameSettings.FNF, thing));
		}

		// Add new settings
		Reflect.setField(yamlThing, "include_secrets", includeSecrets);
		Reflect.setField(yamlThing, "include_pico", includePico);
		Reflect.setField(yamlThing, "include_erect", includeErect);
		Reflect.setField(yamlThing, "include_vanilla", includeVanilla);
		if (startingSong != null)
		{
			Reflect.setField(yamlThing, "starting_song", startingSong);
		}
		else
		{
			Reflect.deleteField(yamlThing, "starting_song");
		}
		if (victorySong != null)
		{
			Reflect.setField(yamlThing, "victory_song", victorySong);
		}
		else
		{
			Reflect.deleteField(yamlThing, "victory_song");
		}

		// Generate and compress Python script for CustomAPLogic (ALWAYS compressed as Base64)
		if (CustomAPLogic.APDataStore.items.length > 0
			|| CustomAPLogic.APDataStore.locations.length > 0
			|| CustomAPLogic.APDataStore.customWeeks.length > 0
			|| Lambda.count(CustomAPLogic.APDataStore.customData) > 0)
		{
			trace('Generating Python script for CustomAPLogic...');

			// Process all mods first to ensure data is up to date
			CustomAPLogic.APHScriptProcessor.processAllMods();

			// Generate the Python script content using the same method as APSettingsSubState
			var pythonContent = CustomAPLogic.APPythonGenerator.generatePythonScript();

			if (pythonContent != null && pythonContent.length > 0)
			{
				// ALWAYS compress the Python script using Base64 encoding (NOT optional)
				var compressedPythonScript = Base64.encode(haxe.io.Bytes.ofString(pythonContent));

				// Embed as modData in the YAML
				Reflect.setField(yamlThing, "modData", compressedPythonScript);
				trace('Python script compressed and embedded as modData (${pythonContent.length} chars -> ${compressedPythonScript.length} chars Base64)');
			}
			else
			{
				trace('Warning: Python script generation returned empty content');
			}
		}

		APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;
		FlxG.random.shuffle(APEntryState.gameSettings.FNF.songList);

		var mainSettings = {
			name: playerName,
			description: APEntryState.gameSettings.description,
			game: APEntryState.gameSettings.game
		};

		var document = Yaml.render(mainSettings, Renderer.options().setFlowLevel(1));

		// Create enhanced comment with stats
		var comment = generateYAMLComment(yamlThing);

		var yamlString = "Friday Night Funkin:\n";
		for (key in Reflect.fields(yamlThing))
		{
			yamlString += "  " + key + ": " + Reflect.field(yamlThing, key) + "\n";
		}

		var finalDocument = document + comment + yamlString;

		trace('YAML export generated for player: ' + playerName);
		trace('YAML export content:\n' + finalDocument);

		#if sys
		if (!sys.FileSystem.exists("./PlayerSettings/"))
			sys.FileSystem.createDirectory("./PlayerSettings/");

		sys.io.File.saveContent("PlayerSettings/" + playerName + ".yaml", finalDocument);
		#end
	}

	function generateYAMLComment(yamlThing:Dynamic):String
	{
		var comment = "\n# Generated by Mixtape Engine Advanced Settings\n";
		comment += "# Export Date: " + Date.now().toString() + "\n";

		var songCount = Reflect.field(yamlThing, "songList") != null ? Reflect.field(yamlThing, "songList").length : 0;

		comment += "# Songs in pool: " + songCount + "\n";
		var modCount = Mods.parseList().enabled.length;
		var modComment = "";
		if (modCount == 0)
		{
			modComment = "No mods? Vanilla enjoyer detected!";
		}
		else if (modCount == 1)
		{
			modComment = "Just one mod? Testing the waters, huh?";
		}
		else if (modCount <= 3)
		{
			modComment = modCount + " mods. A modest modder!";
		}
		else if (modCount <= 7)
		{
			modComment = modCount + " mods. Getting spicy!";
		}
		else if (modCount <= 15)
		{
			modComment = modCount + " mods. Mod connoisseur!";
		}
		else if (modCount <= 30)
		{
			modComment = modCount + " mods. How do you even keep track?";
		}
		else if (modCount <= 50)
		{
			modComment = modCount + " mods. You must be insane...";
		}
		else if (modCount <= 100)
		{
			modComment = modCount + " mods. You are a madman! The Engine might not like this...";
		}
		else if (modCount <= 200)
		{
			modComment = modCount + " mods. Are you trying to break the game?!";
		}
		else
		{
			modComment = modCount + " mods. This is beyond all reason!";
		}
		comment += " # (" + modComment + ")\n";
		comment += "\n";
		comment += "# Song limit: " + songLimit + "\n";

		var totalChecks = switch (unlockMethod)
		{
			case "Song Completion": songLimit * 2;
			case "Note Checks": songLimit * 3;
			case "Both": songLimit * 5;
			default: songLimit;
		}

		comment += "# Expected checks: " + totalChecks + "\n";
		comment += "# Trap items: " + trapAmount + "\n";

		comment += "# Content includes:\n";
		comment += "#   - Vanilla songs: " + (includeVanilla ? "YES" : "NO") + "\n";
		comment += "#   - Erect songs: " + (includeErect ? "YES" : "NO") + "\n";
		comment += "#   - Pico songs: " + (includePico ? "YES" : "NO") + "\n";
		comment += "#   - Secret songs: " + (includeSecrets ? "YES" : "NO") + "\n";
		comment += "#   - Modded songs: " + (allowMods ? "YES" : "NO") + "\n";

		if (victorySong != null)
		{
			comment += "# Victory song: " + victorySong + "\n";
		}
		if (startingSong != null)
		{
			comment += "# Starting song: " + startingSong + "\n";
		}

		// Add modData information
		if (Reflect.hasField(yamlThing, "modData"))
		{
			comment += "# Contains compressed CustomAPLogic Python script (Base64 encoded)\n";
			var modDataLength = Std.string(Reflect.field(yamlThing, "modData")).length;
			comment += "# Compressed script size: " + modDataLength + " characters\n";
		}

		comment += "\n";
		return comment;
	}

	function importYAMLPrompt()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		var yamlPrompt = new Prompt("Import YAML Configuration\n\nThis will load settings from a YAML file and override current configuration.", 0, function()
		{
			// Proceed with import
			importYAMLFile();
		}, function()
		{
			// Cancel import
		}, 'Import', 'Cancel');

		openSubState(yamlPrompt);
	}

	function importYAMLFile()
	{
		var tasks = [
			GenericProgressSubstate.createTask("Opening file dialog", function(results:Array<Dynamic>)
			{
				var yamlContent = yutautil.ImprovedFileHandling.loadFile("Import YAML", [{ext: "yaml", desc: "FNF AP YAML File"}], Text);
				if (yamlContent == null)
				{
					throw new Exception("No file selected or file could not be loaded");
				}
				return yamlContent;
			}),
			GenericProgressSubstate.createTask("Parsing YAML structure", function(results:Array<Dynamic>)
			{
				var content:String = results[0];
				return new archipelago.APYaml(content);
			}),
			GenericProgressSubstate.createTask("Processing YAML content", function(results:Array<Dynamic>)
			{
				var content:String = results[0];
				var yamlLines = content.split('\n');
				// Process lines to show some progress
				var processedLines = 0;
				for (line in yamlLines)
				{
					if (line.trim().length > 0)
					{
						processedLines++;
					}
				}
				return 'Processed $processedLines lines';
			}),
			GenericProgressSubstate.createTask("Applying settings", function(results:Array<Dynamic>)
			{
				var yaml:archipelago.APYaml = results[1];

				// Apply settings to the current state
				playerName = yaml.name;
				APEntryState.gameSettings.name = yaml.name;

				for (field in Reflect.fields(yaml.settings))
				{
					if (Reflect.hasField(APEntryState.gameSettings.FNF, field))
					{
						var value:archipelago.APYaml.APOption = Reflect.field(yaml.settings, field);
						Reflect.setField(APEntryState.gameSettings.FNF, field, value);

						// Map YAML settings to local variables
						switch (field)
						{
							case "progression_balancing":
								progression_balancing = Std.string(value);
							case "accessibility":
								accessibility = Std.string(value);
							case "unlock_type":
								unlockType = Std.string(value);
							case "unlock_method":
								unlockMethod = Std.string(value);
							case "grade_requirement" | "graderequirement":
								gradeRequirement = Std.string(value);
							case "accuracy_requirement" | "accrequirement":
								accRequirement = Std.string(value);
							case "allow_mods" | "mods_enabled":
								allowMods = value == true;
							case "include_secrets":
								includeSecrets = value == true;
							case "include_pico":
								includePico = value == true;
							case "include_erect":
								includeErect = value == true;
							case "include_vanilla":
								includeVanilla = value == true;
							case "starting_song":
								startingSong = Std.string(value);
							case "victory_song":
								victorySong = Std.string(value);
							case "deathlink":
								deathlink = value == true;
							case "ticket_percent" | "ticket_percentage":
								ticketPercent = value;
							case "ticket_win_percent" | "ticket_win_percentage":
								ticketWinPercent = value;
							case "chart_modifier_chance" | "chart_modifier_change_chance":
								chartmodifierchance = value;
							case "trap_amount" | "trapAmount":
								trapAmount = value;
							case "song_limit":
								songLimit = value;
							// Filler weight settings
							case "bbcWeight":
								bbcWeight = value;
							case "ghostChatWeight":
								ghostChatWeight = value;
							case "tutorialWeight":
								tutorialWeight = value;
							case "songswitchWeight":
								songswitchWeight = value;
							case "resistanceWeight":
								resistanceWeight = value;
							case "unoWeight":
								unoWeight = value;
							case "pongWeight":
								pongWeight = value;
							case "svcWeight":
								svcWeight = value;
							case "fakeTransWeight":
								fakeTransWeight = value;
							case "shieldWeight":
								shieldWeight = value;
							case "MHPWeight":
								MHPWeight = value;
							case "MHPDWeight":
								MHPDWeight = value;
							case "exLifeWeight":
								exLifeWeight = value;
							// Handle any other potential fields that might exist
							default:
								trace('Unknown YAML field during import: $field = $value');
						}
					}
				}

				return "Settings applied successfully";
			}),
			GenericProgressSubstate.createTask("Refreshing UI", function(results:Array<Dynamic>)
			{
				// Refresh the current page to show imported values
				loadPage(currentPage);
				return "UI refreshed";
			})
		];

		var progressSubstate = new GenericProgressSubstate("Importing YAML Configuration", tasks, function(results:Array<Dynamic>)
		{
			// On completion
			var yaml:archipelago.APYaml = results[1];
			var successPrompt = new InfoPanelSubstate("YAML Import Complete",
				"YAML configuration has been successfully imported!\n\nPlayer: " + playerName + "\nSettings have been applied to the current configuration.",
				FlxColor.LIME);
			openSubState(successPrompt);
		}, function(error:String, shouldThrow:Bool)
		{
			if (error.indexOf("No file selected") == -1)
			{
				var errorPrompt = new InfoPanelSubstate("YAML Import Error", error, FlxColor.RED);
				openSubState(errorPrompt);
			}
			// If no file selected, just silently cancel
		}, function()
		{
			// On cancel - do nothing
		});

		openSubState(progressSubstate);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Update navigation cooldown
		if (navigationCooldown > 0)
		{
			navigationCooldown -= elapsed;
		}

		// Handle slider updates if one is active
		if (isSliderActive && sliderUpdateFunc != null)
		{
			sliderUpdateFunc(elapsed);
		}

		// Handle context menu input first
		if (contextMenuActive)
		{
			handleContextMenuInput();
			return; // Don't process other input while context menu is active
		}

		// Don't handle input if a substate is open or a slider is active
		if (subState != null || isSliderActive)
			return;

		// Handle input with cooldown
		if (navigationCooldown <= 0)
		{
			if (controls.UI_LEFT || FlxG.keys.justPressed.LEFT)
			{
				if (currentPage > 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					animatePageOut(-1, function()
					{
						loadPage(currentPage - 1);
					});
					navigationCooldown = navigationDelay;
				}
			}

			if (controls.UI_RIGHT || FlxG.keys.justPressed.RIGHT)
			{
				if (currentPage < pages.length - 1)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					animatePageOut(1, function()
					{
						loadPage(currentPage + 1);
					});
					navigationCooldown = navigationDelay;
				}
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closeSettings();
		}

		// Handle option selection
		if (controls.ACCEPT || FlxG.keys.justPressed.ENTER)
		{
			handleOptionClick();
		}

		// Handle mouse clicks
		handleMouseInput();
	}

	function handleOptionClick()
	{
		var selectedOption = 0; // You'd implement proper selection tracking
		if (selectedOption < pages[currentPage].options.length)
		{
			var option = pages[currentPage].options[selectedOption];
			if (!option.locked)
			{
				option.callback();
				// Play sound and refresh UI after any option change
				FlxG.sound.play(Paths.sound('scrollMenu'));
				refreshCurrentPage();
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.camera.shake(0.01, 0.2);
			}
		}
	}

	function handleMouseInput()
	{
		// Don't handle input if a substate is open or a slider is active
		if (subState != null || isSliderActive)
			return;

		var mousePos = FlxG.mouse.getPosition();

		// Check option button clicks
		optionButtons.forEachAlive(function(button:FlxSprite)
		{
			if (FlxG.mouse.overlaps(button))
			{
				var data = buttonData.get(button);
				if (data != null)
				{
					var type:String = data.get("type");
					var index:Int = data.get("index");

					// Handle left click
					if (FlxG.mouse.justPressed)
					{
						if (type == "regular")
						{
							var option = pages[currentPage].options[index];
							if (!option.locked)
							{
								// Check if this option has a context menu that should show on left-click
								if (option.contextMenu != null)
								{
									switch (option.contextMenu)
									{
										case ENUM_SELECT(options):
											// Show enum selection substate instead of context menu
											openEnumSelectionPrompt(option.name, options);
										case BOOLEAN(trueLabel, falseLabel):
											// Show boolean selection substate
											openBooleanSelectionPrompt(option.name, trueLabel, falseLabel);
										case EDIT_VALUE(editCallback):
											// For edit values, keep the original callback behavior
											option.callback();
											// Play sound and refresh UI after any option change
											FlxG.sound.play(Paths.sound('scrollMenu'));
											refreshCurrentPage();
									}
								}
								else
								{
									// Fallback to original callback if no context menu
									option.callback();
									// Play sound and refresh UI after any option change
									FlxG.sound.play(Paths.sound('scrollMenu'));
									refreshCurrentPage();
								}
							}
							else
							{
								FlxG.sound.play(Paths.sound('cancelMenu'));
								FlxG.camera.shake(0.01, 0.2);
							}
						}
						else if (type == "state")
						{
							var stateOption = pages[currentPage].stateOptions[index];
							executeStateOption(stateOption);
						}
					}

					// Handle right click for context menu
					if (FlxG.mouse.justPressedRight && type == "regular")
					{
						var option = pages[currentPage].options[index];
						if (!option.locked && option.contextMenu != null)
						{
							var mousePos = FlxG.mouse.getPosition();
							showContextMenu(option.name, option.contextMenu, mousePos.x, mousePos.y);
						}
					}
				}
			}
		});

		// Check navigation arrows
		if (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justPressed && currentPage > 0 && navigationCooldown <= 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			animatePageOut(-1, function()
			{
				loadPage(currentPage - 1);
			});
			navigationCooldown = navigationDelay;
		}

		if (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justPressed && currentPage < pages.length - 1 && navigationCooldown <= 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			animatePageOut(1, function()
			{
				loadPage(currentPage + 1);
			});
			navigationCooldown = navigationDelay;
		}

		// Check bottom buttons
		if (FlxG.mouse.overlaps(exportButton) && FlxG.mouse.justPressed)
		{
			exportYAML();
		}

		if (FlxG.mouse.overlaps(importButton) && FlxG.mouse.justPressed)
		{
			importYAMLPrompt();
		}

		if (FlxG.mouse.overlaps(closeButton) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closeSettings();
		}

		// Check stats panel button
		if (FlxG.mouse.overlaps(statsPanel) && FlxG.mouse.justPressed)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			showStatsPanel();
		}
	}

	// Temporary save system for state navigation
	function initTempSave()
	{
		if (tempSave == null)
		{
			tempSave = new FlxSave();
			tempSave.bind("APAdvancedSettingsTemp");
		}
		saveTempData();
	}

	function saveTempData()
	{
		tempSaveData = {
			progression_balancing: progression_balancing,
			accessibility: accessibility,
			unlockType: unlockType,
			unlockMethod: unlockMethod,
			gradeRequirement: gradeRequirement,
			accRequirement: accRequirement,
			allowMods: allowMods,
			includePico: includePico,
			includeErect: includeErect,
			includeVanilla: includeVanilla,
			startingSong: startingSong,
			victorySong: victorySong,
			playerName: playerName,
			deathlink: deathlink,
			ticketPercent: ticketPercent,
			ticketWinPercent: ticketWinPercent,
			chartmodifierchance: chartmodifierchance,
			trapAmount: trapAmount,
			songLimit: songLimit,
			currentPage: currentPage,
			// Filler weight settings
			bbcWeight: bbcWeight,
			ghostChatWeight: ghostChatWeight,
			tutorialWeight: tutorialWeight,
			songswitchWeight: songswitchWeight,
			resistanceWeight: resistanceWeight,
			unoWeight: unoWeight,
			pongWeight: pongWeight,
			svcWeight: svcWeight,
			fakeTransWeight: fakeTransWeight,
			shieldWeight: shieldWeight,
			MHPWeight: MHPWeight,
			MHPDWeight: MHPDWeight,
			exLifeWeight: exLifeWeight
		};

		if (tempSave != null)
		{
			tempSave.data.settings = tempSaveData;
			tempSave.flush();
		}
	}

	function loadFromTempData()
	{
		if (tempSave != null && tempSave.data.settings != null)
		{
			var data = tempSave.data.settings;
			progression_balancing = data.progression_balancing;
			accessibility = data.accessibility;
			unlockType = data.unlockType;
			unlockMethod = data.unlockMethod;
			gradeRequirement = data.gradeRequirement;
			accRequirement = data.accRequirement;
			allowMods = data.allowMods;
			includePico = data.includePico;
			includeErect = data.includeErect;
			includeVanilla = data.includeVanilla;
			startingSong = data.startingSong;
			victorySong = data.victorySong;
			playerName = Reflect.hasField(data, "playerName") ? data.playerName : "Player";
			deathlink = data.deathlink;
			ticketPercent = data.ticketPercent;
			ticketWinPercent = data.ticketWinPercent;
			chartmodifierchance = data.chartmodifierchance;
			trapAmount = data.trapAmount;
			songLimit = data.songLimit;

			// Restore current page if available
			if (Reflect.hasField(data, "currentPage"))
			{
				currentPage = data.currentPage;
			}

			// Load filler weight settings
			if (Reflect.hasField(data, "bbcWeight"))
				bbcWeight = data.bbcWeight;
			if (Reflect.hasField(data, "ghostChatWeight"))
				ghostChatWeight = data.ghostChatWeight;
			if (Reflect.hasField(data, "tutorialWeight"))
				tutorialWeight = data.tutorialWeight;
			if (Reflect.hasField(data, "songswitchWeight"))
				songswitchWeight = data.songswitchWeight;
			if (Reflect.hasField(data, "unoWeight"))
				unoWeight = data.unoWeight;
			if (Reflect.hasField(data, "pongWeight"))
				pongWeight = data.pongWeight;
			if (Reflect.hasField(data, "svcWeight"))
				svcWeight = data.svcWeight;
			if (Reflect.hasField(data, "fakeTransWeight"))
				fakeTransWeight = data.fakeTransWeight;
			if (Reflect.hasField(data, "shieldWeight"))
				shieldWeight = data.shieldWeight;
			if (Reflect.hasField(data, "MHPWeight"))
				MHPWeight = data.MHPWeight;
			if (Reflect.hasField(data, "MHPDWeight"))
				MHPDWeight = data.MHPDWeight;
			if (Reflect.hasField(data, "exLifeWeight"))
				exLifeWeight = data.exLifeWeight;
		}
	}

	// Page transition animations
	function animatePageOut(direction:Int, onComplete:Void->Void)
	{
		if (isAnimating)
			return;
		isAnimating = true;

		var targetX = direction > 0 ? -FlxG.width : FlxG.width;
		var completedAnimations = 0;
		var totalAnimations = optionButtons.members.length;

		if (totalAnimations == 0)
		{
			isAnimating = false;
			onComplete();
			return;
		}

		for (i in 0...optionButtons.members.length)
		{
			var button = optionButtons.members[i];
			var text = optionTexts.members[i];

			if (button != null)
			{
				FlxTween.tween(button, {x: targetX}, transitionTime * 0.5, {
					ease: FlxEase.backIn,
					onComplete: function(_)
					{
						completedAnimations++;
						if (completedAnimations == totalAnimations)
						{
							isAnimating = false; // Reset before calling onComplete
							onComplete();
						}
					}
				});
			}

			if (text != null)
			{
				FlxTween.tween(text, {x: targetX + 10}, transitionTime * 0.5, {
					ease: FlxEase.backIn
				});
			}
		}
	}

	// Slider control system
	function openSliderControl(name:String, currentValue:Float, minValue:Float, maxValue:Float, stepSize:Float, onUpdate:Float->Void)
	{
		// Set slider active to block other input
		isSliderActive = true;

		var sliderBg = new FlxSprite(0, 0);
		sliderBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 120));
		add(sliderBg);

		var panel = new FlxSprite(Std.int(FlxG.width / 2) - 300, Std.int(FlxG.height / 2) - 100);
		panel.makeGraphic(600, 200, FlxColor.fromRGB(20, 20, 40));
		add(panel);

		var titleText = new FlxText(panel.x + 20, panel.y + 20, panel.width - 40, name, 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Slider track
		var sliderTrack = new FlxSprite(panel.x + 50, panel.y + 80);
		sliderTrack.makeGraphic(Std.int(panel.width - 100), 10, FlxColor.GRAY);
		add(sliderTrack);

		// Slider handle
		var sliderHandle = new FlxSprite(0, sliderTrack.y - 10);
		sliderHandle.makeGraphic(20, 30, FlxColor.WHITE);
		add(sliderHandle);

		// Value text
		var valueText = new FlxText(panel.x + 20, panel.y + 120, panel.width - 40, "", 20);
		valueText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		valueText.borderSize = 1;
		add(valueText);

		// Update slider position and value
		var updateSlider = function(value:Float)
		{
			var normalizedValue = (value - minValue) / (maxValue - minValue);
			sliderHandle.x = sliderTrack.x + (normalizedValue * (sliderTrack.width - sliderHandle.width));
			valueText.text = Std.string(Std.int(value));
		};

		updateSlider(currentValue);

		// Input text button
		var inputButton = new FlxSprite(panel.x + 50, panel.y + 150);
		inputButton.makeGraphic(100, 30, FlxColor.GREEN);
		add(inputButton);

		var inputButtonText = new FlxText(inputButton.x, inputButton.y + 5, inputButton.width, "TYPE VALUE", 12);
		inputButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		inputButtonText.borderSize = 1;
		add(inputButtonText);

		// Close button
		var closeButton = new FlxSprite(panel.x + panel.width - 150, panel.y + 150);
		closeButton.makeGraphic(100, 30, FlxColor.RED);
		add(closeButton);

		var closeButtonText = new FlxText(closeButton.x, closeButton.y + 5, closeButton.width, "CLOSE", 12);
		closeButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		closeButtonText.borderSize = 1;
		add(closeButtonText);

		var isDragging = false;
		var currentVal = currentValue;
		var lastVal:Float = -1;

		// Create the update function and assign it
		sliderUpdateFunc = function(elapsed:Float)
		{
			if (FlxG.mouse.pressed && FlxG.mouse.overlaps(sliderTrack))
			{
				isDragging = true;
			}

			if (isDragging && FlxG.mouse.pressed)
			{
				var mouseX = FlxG.mouse.x;
				var relativeX = mouseX - sliderTrack.x;
				var normalizedX = Math.max(0, Math.min(1, relativeX / sliderTrack.width));
				currentVal = minValue + (normalizedX * (maxValue - minValue));
				currentVal = Math.round(currentVal / stepSize) * stepSize;
				updateSlider(currentVal);
				if (currentVal != lastVal)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
					lastVal = currentVal;
				}
			}

			if (!FlxG.mouse.pressed)
			{
				isDragging = false;
			}

			// Button clicks - only handle if slider is active
			if (FlxG.mouse.overlaps(inputButton) && FlxG.mouse.justPressed)
			{
				openSubState(new NumberInputSubstate(name, currentVal, minValue, maxValue, function(newValue:Float)
				{
					currentVal = newValue;
					updateSlider(currentVal);
				}, null, // no cancel callback needed
					stepSize, // use the provided step size
					stepSize != Std.int(stepSize), // allow decimals if step size is not integer
					'Enter a value between $minValue and $maxValue',
					pages[currentPage].color, // use current page theme color
					true // show number pad
				));
			}

			if (FlxG.mouse.overlaps(closeButton) && FlxG.mouse.justPressed)
			{
				onUpdate(currentVal);
				FlxG.sound.play(Paths.sound('confirmMenu'));

				// Remove all slider elements and reset state
				remove(sliderBg);
				remove(panel);
				remove(titleText);
				remove(sliderTrack);
				remove(sliderHandle);
				remove(valueText);
				remove(inputButton);
				remove(inputButtonText);
				remove(closeButton);
				remove(closeButtonText);

				// Reset slider state
				isSliderActive = false;
				sliderUpdateFunc = null;
			}
		};
	}

	function openValueInput(name:String, currentValue:Float, minValue:Float, maxValue:Float, onUpdate:Float->Void)
	{
		openSubState(new NumberInputSubstate(name, currentValue, minValue, maxValue, onUpdate, null, // no cancel callback needed
			1, // step size
			false, // no decimals for most AP settings
			'Enter a value between $minValue and $maxValue',
			pages[currentPage].color, // use current page theme color
			true // show number pad
		));
	}

	function calculateMaxAvailableSongs():Int
	{
		var total = 0;
		if (includeVanilla)
		{
			total += APInfo.baseGame.length;
		}
		if (includeErect)
		{
			total += APInfo.baseErect.length;
		}
		if (includePico)
		{
			total += APInfo.basePico.length;
		}
		if (includeSecrets)
		{
			total += APInfo.secrets.length;
		}
		if (allowMods)
		{
			total += backend.Mods.parseList().enabled.length * 3;
		}
		return Std.int(Math.max(5, total));
	}

	public static function restoreFromTemp():APAdvancedSettingsState
	{
		var state = new APAdvancedSettingsState();
		if (tempSave != null && tempSave.data.settings != null)
		{
			var data = tempSave.data.settings;
			state.progression_balancing = data.progression_balancing;
			state.accessibility = data.accessibility;
			state.unlockType = data.unlockType;
			state.unlockMethod = data.unlockMethod;
			state.gradeRequirement = data.gradeRequirement;
			state.accRequirement = data.accRequirement;
			state.allowMods = data.allowMods;
			state.includeSecrets = data.includeSecrets;
			state.includePico = data.includePico;
			state.includeErect = data.includeErect;
			state.includeVanilla = data.includeVanilla;
			state.startingSong = data.startingSong;
			state.victorySong = data.victorySong;
			state.deathlink = data.deathlink;
			state.ticketPercent = data.ticketPercent;
			state.ticketWinPercent = data.ticketWinPercent;
			state.chartmodifierchance = data.chartmodifierchance;
			state.trapAmount = data.trapAmount;
			state.songLimit = data.songLimit;

			// Load filler weight settings if available
			if (Reflect.hasField(data, "bbcWeight"))
				state.bbcWeight = data.bbcWeight;
			if (Reflect.hasField(data, "ghostChatWeight"))
				state.ghostChatWeight = data.ghostChatWeight;
			if (Reflect.hasField(data, "tutorialWeight"))
				state.tutorialWeight = data.tutorialWeight;
			if (Reflect.hasField(data, "songswitchWeight"))
				state.songswitchWeight = data.songswitchWeight;
			if (Reflect.hasField(data, "unoWeight"))
				state.unoWeight = data.unoWeight;
			if (Reflect.hasField(data, "pongWeight"))
				state.pongWeight = data.pongWeight;
			if (Reflect.hasField(data, "svcWeight"))
				state.svcWeight = data.svcWeight;
			if (Reflect.hasField(data, "fakeTransWeight"))
				state.fakeTransWeight = data.fakeTransWeight;
			if (Reflect.hasField(data, "shieldWeight"))
				state.shieldWeight = data.shieldWeight;
			if (Reflect.hasField(data, "MHPWeight"))
				state.MHPWeight = data.MHPWeight;
			if (Reflect.hasField(data, "MHPDWeight"))
				state.MHPDWeight = data.MHPDWeight;
			if (Reflect.hasField(data, "exLifeWeight"))
				state.exLifeWeight = data.exLifeWeight;
		}
		return state;
	}

	public static function returnToAdvancedSettings()
	{
		if (tempSave != null)
		{
			tempSave.data.shouldReturnToAdvancedSettings = true;
			tempSave.flush();
		}
		MusicBeatState.switchState(new APAdvancedSettingsState());
	}

	function closeSettings()
	{
		saveCurrentSettings();

		// Clean up temporary save
		if (tempSave != null)
		{
			tempSave.data.shouldReturnToAdvancedSettings = false;
			tempSave.data.settings = null;
			tempSave.flush();
		}

		// Clear AP tracking
		MusicBeatState.clearAPOptionsTracking();

		// Animate out all elements
		animateOut(function()
		{
			archipelago.APVersionSelectionState.smartLaunch();
		});
	}

	function animateOut(onComplete:Void->Void)
	{
		// Title and description slide up and fade
		FlxTween.tween(titleText, {y: titleText.y - 100, alpha: 0}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(descriptionText, {y: descriptionText.y - 100, alpha: 0}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(pageIndicator, {y: pageIndicator.y - 80, alpha: 0}, 0.4, {ease: FlxEase.backIn});

		// Navigation arrows fade out
		FlxTween.tween(leftArrow, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
		FlxTween.tween(rightArrow, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});

		// Option buttons slide down and fade
		optionButtons.forEachAlive(function(button:FlxSprite)
		{
			FlxTween.tween(button, {y: button.y + 50, alpha: 0}, FlxG.random.float(0.3, 0.6), {ease: FlxEase.backIn});
		});

		optionTexts.forEachAlive(function(text:FlxText)
		{
			FlxTween.tween(text, {y: text.y + 50, alpha: 0}, FlxG.random.float(0.3, 0.6), {ease: FlxEase.backIn});
		});

		// Stats panel button slides out
		if (statsPanel != null)
		{
			FlxTween.tween(statsPanel, {x: FlxG.width + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});
		}

		// Close button slides down
		FlxTween.tween(closeButton, {y: FlxG.height + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(exportButton, {y: FlxG.height + 50, alpha: 0}, 0.4, {ease: FlxEase.backIn});

		// Background fade
		FlxTween.tween(bg, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});
		FlxTween.tween(gradientOverlay, {alpha: 0}, 0.6, {ease: FlxEase.sineIn});

		// Particles fade out
		if (particles != null)
		{
			particles.forEachAlive(function(particle:FlxSprite)
			{
				FlxTween.tween(particle, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
			});
		}

		// Glow effect fade out
		if (glowEffect != null)
		{
			FlxTween.tween(glowEffect, {alpha: 0}, 0.2, {ease: FlxEase.sineIn});
		}

		// Call completion after longest animation
		new FlxTimer().start(0.6, function(_)
		{
			if (onComplete != null)
				onComplete();
		});
	}
}

/**
 * A scrollable substate for selecting from enum-like options
 */
class EnumSelectionSubstate extends MusicBeatSubstate
{
	var options:Array<ContextMenuOption>;
	var title:String;
	var onSelect:ContextMenuOption->Void;

	var bg:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var instructionText:FlxText;

	var optionButtons:FlxTypedGroup<FlxSprite>;
	var optionTexts:FlxTypedGroup<FlxText>;

	var selectedIndex:Int = 0;
	var scrollOffset:Int = 0;
	var maxVisibleOptions:Int = 8;

	var navigationCooldown:Float = 0;
	var navigationDelay:Float = 0.1;

	var isClosing:Bool = false;

	public function new(title:String, options:Array<ContextMenuOption>, onSelect:ContextMenuOption->Void)
	{
		super();
		this.title = title;
		this.options = options;
		this.onSelect = onSelect;

		// Find currently selected option
		for (i in 0...options.length)
		{
			if (options[i].isSelected == true)
			{
				selectedIndex = i;
				break;
			}
		}

		// Ensure selected item is visible
		updateScrollOffset();
	}

	override function create()
	{
		super.create();

		// Semi-transparent background
		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 150));
		add(bg);

		// Main panel
		var panelWidth = 400;
		var panelHeight = 500;
		panel = new FlxSprite((FlxG.width - panelWidth) / 2, (FlxG.height - panelHeight) / 2);
		panel.makeGraphic(panelWidth, panelHeight, FlxColor.fromRGB(30, 30, 50));
		add(panel);

		// Panel border
		var border = new FlxSprite(panel.x - 2, panel.y - 2);
		border.makeGraphic(panelWidth + 4, panelHeight + 4, FlxColor.fromRGB(80, 80, 120));
		insert(members.indexOf(panel), border);

		// Title
		titleText = new FlxText(panel.x + 10, panel.y + 15, panel.width - 20, title, 20);
		titleText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		// Instructions
		instructionText = new FlxText(panel.x + 10, panel.y + 50, panel.width - 20, "Use UP/DOWN or Mouse to select • ENTER/Click to choose • ESC to cancel",
			12);
		instructionText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.GRAY, CENTER, OUTLINE, FlxColor.BLACK);
		instructionText.borderSize = 1;
		add(instructionText);

		// Option lists
		optionButtons = new FlxTypedGroup<FlxSprite>();
		add(optionButtons);

		optionTexts = new FlxTypedGroup<FlxText>();
		add(optionTexts);

		createOptionList();

		// Animate in
		panel.alpha = 0;
		titleText.alpha = 0;
		instructionText.alpha = 0;

		FlxTween.tween(panel, {alpha: 1}, 0.2, {ease: FlxEase.sineOut});
		FlxTween.tween(titleText, {alpha: 1}, 0.3, {ease: FlxEase.sineOut});
		FlxTween.tween(instructionText, {alpha: 1}, 0.4, {ease: FlxEase.sineOut});
	}

	function createOptionList()
	{
		optionButtons.clear();
		optionTexts.clear();

		var startY = panel.y + 90;
		var buttonHeight = 35;
		var spacing = 2;

		var visibleEnd:Num = Math.min(scrollOffset + maxVisibleOptions, options.length);

		for (i in scrollOffset...visibleEnd)
		{
			var option = options[i];
			var yPos = startY + ((i - scrollOffset) * (buttonHeight + spacing));

			// Create button
			var button = new FlxSprite(panel.x + 10, yPos);
			var buttonColor = (i == selectedIndex) ? FlxColor.fromRGB(60, 120, 60) : FlxColor.fromRGB(50, 50, 80);
			if (option.isSelected == true)
			{
				buttonColor = (i == selectedIndex) ? FlxColor.fromRGB(80, 150, 80) : FlxColor.fromRGB(70, 130, 70);
			}
			button.makeGraphic(Std.int(panel.width - 20), buttonHeight, buttonColor);
			button.ID = i;
			optionButtons.add(button);

			// Create text
			var labelText = option.label;
			if (option.isSelected == true)
			{
				labelText = "✓ " + option.label;
			}

			var text = new FlxText(button.x + 10, button.y + 8, button.width - 20, labelText, 16);
			var textColor = (i == selectedIndex) ? FlxColor.YELLOW : FlxColor.WHITE;
			if (option.isSelected == true && i != selectedIndex)
			{
				textColor = FlxColor.LIME;
			}
			text.setFormat(Paths.font("vcr.ttf"), 16, textColor, LEFT, OUTLINE, FlxColor.BLACK);
			text.borderSize = 1;
			text.ID = i;
			optionTexts.add(text);
		}

		// Show scroll indicators if needed
		if (scrollOffset > 0)
		{
			var upArrow = new FlxText(panel.x + panel.width - 30, startY - 20, 20, "▲", 16);
			upArrow.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
			add(upArrow);
		}

		if (scrollOffset + maxVisibleOptions < options.length)
		{
			var downArrow = new FlxText(panel.x + panel.width - 30, startY + (maxVisibleOptions * 37) - 10, 20, "▼", 16);
			downArrow.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
			add(downArrow);
		}
	}

	function updateScrollOffset()
	{
		// Keep selected item visible
		if (selectedIndex < scrollOffset)
		{
			scrollOffset = selectedIndex;
		}
		else if (selectedIndex >= scrollOffset + maxVisibleOptions)
		{
			scrollOffset = selectedIndex - maxVisibleOptions + 1;
		}

		// Clamp scroll offset
		scrollOffset = Std.int(Math.max(0, Math.min(scrollOffset, Math.max(0, options.length - maxVisibleOptions))));
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		navigationCooldown -= elapsed;

		// Keyboard navigation
		if (navigationCooldown <= 0)
		{
			var needsRefresh = false;

			if (controls.UI_UP || FlxG.keys.justPressed.UP)
			{
				selectedIndex--;
				if (selectedIndex < 0)
					selectedIndex = options.length - 1;
				updateScrollOffset();
				needsRefresh = true;
				navigationCooldown = navigationDelay;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.UI_DOWN || FlxG.keys.justPressed.DOWN)
			{
				selectedIndex++;
				if (selectedIndex >= options.length)
					selectedIndex = 0;
				updateScrollOffset();
				needsRefresh = true;
				navigationCooldown = navigationDelay;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (needsRefresh)
			{
				createOptionList();
			}
		}

		// Mouse navigation
		optionButtons.forEachAlive(function(button:FlxSprite)
		{
			if (FlxG.mouse.overlaps(button))
			{
				var newIndex = button.ID;
				if (newIndex != selectedIndex)
				{
					selectedIndex = newIndex;
					createOptionList();
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (FlxG.mouse.justPressed)
				{
					selectCurrentOption();
				}
			}
		});

		// Selection
		if (controls.ACCEPT || FlxG.keys.justPressed.ENTER)
		{
			selectCurrentOption();
		}

		// Cancel
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			close();
		}

		// Click outside to cancel
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(panel))
		{
			close();
		}
	}

	function selectCurrentOption(playConfirmSound:Bool = true)
	{
		if (selectedIndex >= 0 && selectedIndex < options.length)
		{
			var selectedOption = options[selectedIndex];

			if (playConfirmSound)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			isClosing = true; // Mark that we're closing with animation

			// Animate out quickly
			FlxTween.tween(panel, {alpha: 0, y: panel.y - 20}, 0.15, {
				ease: FlxEase.backIn,
				onComplete: function(_)
				{
					if (playConfirmSound && onSelect != null)
					{
						onSelect(selectedOption);
					}
					c();
				}
			});

			FlxTween.tween(titleText, {alpha: 0}, 0.1);
			FlxTween.tween(instructionText, {alpha: 0}, 0.1);
			optionButtons.forEachAlive(function(button:FlxSprite)
			{
				FlxTween.tween(button, {alpha: 0}, 0.1);
			});
			optionTexts.forEachAlive(function(text:FlxText)
			{
				FlxTween.tween(text, {alpha: 0}, 0.1);
			});
		}
	}

	override function close()
	{
		// If we're already in the process of closing with animation, don't do anything
		if (isClosing)
			return;

		// Use selectCurrentOption with cancel sound instead of confirm sound
		selectCurrentOption(false);
	}

	function c()
		super.close();
}
