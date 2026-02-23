package archipelago;

import archipelago.APEntryState;
import archipelago.APInfo;
import archipelago.APVersionSelectionState;
import archipelago.CustomAPLogic;
import archipelago.substates.InfoPanelSubstate;
import archipelago.substates.NumberInputSubstate;
import archipelago.substates.TextInputSubstate.InputMode;
import archipelago.substates.TextInputSubstate;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Song;
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
import stages.StageData;
import states.*;
import substates.Prompt;
import substates.SongSelectSubState;
import tjson.TJSON;
import yaml.Renderer;
import yaml.Yaml;
import yutautil.GenericProgressSubstate;

using yutautil.CollectionUtils;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

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
	BOOLEAN(trueLabel:String, falseLabel:String, setValue:Bool->Void);
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

	// Sanity settings
	var stagesanity:Bool = false;
	var charactersanity:Bool = false;
	var enable_sanity_locations:Bool = false;
	var sanity_completion_type:String = "on_getting";

	// Filler/Trap weight settings
	var bbcWeight:Int = 3;
	var ghostChatWeight:Int = 3;
	var tutorialWeight:Int = 3;
	var svcWeight:Int = 3;
	var fakeTransWeight:Int = 3;
	var songswitchWeight:Int = 3;
	var resistanceWeight:Int = 3;
	var unoWeight:Int = 3;
	var pongWeight:Int = 3;
	var ultConfusionWeight:Int = 3;
	var shieldWeight:Int = 3;
	var exLifeWeight:Int = 3;
	var MHPWeight:Int = 3;
	var MHPDWeight:Int = 3;

	// Z11's Optional Hell
	var starter_debuffs:Bool = false;
	var perma_traps:Bool = false;
	var hard_mode:Bool = false;
	var enable_shop:Bool = false;

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

	// Refresh queue system - waits for all tweens to complete
	var refreshQueued:Bool = false;
	var activeTweens:Array<FlxTween> = [];
	var tweenCheckTimer:Float = 0;
	var tweenCheckInterval:Float = 0.1; // Check every 100ms

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

	// Force export path for refresh functionality
	public var forceExportPath:String = null;
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
		else if (forceExportPath != null)
		{
			// Force export without import (shouldn't happen in refresh scenario)
			new FlxTimer().start(0.5, function(_) {
				performYAMLExportToPath(forceExportPath);
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
		return BOOLEAN(trueLabel, falseLabel, setValue);
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
				victorySong = null;  // Reset victory song
				startingSong = null; // Reset starting song
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
							// Only set if the value is actually present in YAML and not empty
							var songValue = APInfo.realName(Std.string(value));
							startingSong = (songValue != null && songValue.trim().length > 0) ? APInfo.realName(songValue) : null;
						case "victory_song":
							// Only set if the value is actually present in YAML and not empty
							var songValue = APInfo.realName(Std.string(value));
							victorySong = (songValue != null && songValue.trim().length > 0) ? APInfo.realName(songValue) : null;
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
						case "ultConfusionWeight":
							ultConfusionWeight = value;
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
						// Sanity settings
						case "enable_sanity_locations":
							enable_sanity_locations = value == true;
						case "sanity_completion_type":
							var completionType = Std.string(value);
							if (["on_getting", "on_playing", "on_beating"].indexOf(completionType) != -1) {
								sanity_completion_type = completionType;
							} else {
								trace('Invalid sanity_completion_type: $completionType, using default: on_getting');
								sanity_completion_type = "on_getting";
							}
						case "stagesanity":
							stagesanity = value == true;
						case "charactersanity":
							charactersanity = value == true;
						case "starter_debuffs":
							starter_debuffs = value == true;
						case "perma_traps":
							perma_traps = value == true;
						case "hard_mode":
							hard_mode = value == true;
						case "enable_shop":
							enable_shop = value == true;
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
			saveCurrentSettings();
			if (forceExportPath != null)
			{
				// This is a refresh operation - immediately trigger export to the forced path
				performYAMLExportToPath(forceExportPath);
			}
			else
			{
				// Regular import - show success message
				var successPrompt = new InfoPanelSubstate("YAML Import Complete",
					"YAML configuration has been successfully imported!\n\nPlayer: " + playerName + "\nSettings have been applied to the current configuration.",
					FlxColor.LIME);
				openSubState(successPrompt);
			}
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
				name: "Ultimate Confusion Trap Weight",
				description: "Weight for the Ultimate Confusion Trap items (0-10)",
				callback: () -> adjustConfusionWeight(),
				locked: false,
				contextMenu: createEditContextMenu(() -> adjustConfusionWeight())
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

		// Sanity Options Page - dynamically build based on enabled sanity types
		var sanityOptions:Array<SettingsOption> = [];

		// Always show the individual sanity type toggles first
		sanityOptions.push({
			name: "Stagesanity",
			description: "Enable stage-based items. Creates location checks for stages used in songs.",
			callback: function() {
				stagesanity = !stagesanity;
				refreshCurrentPage();
			},
			locked: false,
			contextMenu: createBoolContextMenu(stagesanity, function(value:Bool) {
				stagesanity = value;
				// Don't refresh here - the main callback will handle it
			})
		});

		sanityOptions.push({
			name: "Charactersanity",
			description: "Enable character-based items. Creates location checks for characters used in songs.",
			callback: function() {
				charactersanity = !charactersanity;
				refreshCurrentPage();
			},
			locked: false,
			contextMenu: createBoolContextMenu(charactersanity, function(value:Bool) {
				charactersanity = value;
				// Don't refresh here - the main callback will handle it
			})
		});

		// Always show location options (they control whether locations are created)
		// The user should be able to configure these even if no sanity types are currently enabled
		sanityOptions.push({
			name: "Enable Sanity Locations",
			description: "Enable or disable all sanity location types globally",
			callback: function() {
				enable_sanity_locations = !enable_sanity_locations;
				refreshCurrentPage();
			},
			locked: false,
			contextMenu: createBoolContextMenu(enable_sanity_locations, function(value:Bool) {
				enable_sanity_locations = value;
			})
		});

		sanityOptions.push({
			name: "Sanity Completion Type",
			description: "How sanity locations are accessed: on_getting, on_playing, or on_beating",
			callback: () -> cycleSanityCompletionType(),
			locked: false,
			contextMenu: createEnumContextMenu(["on_getting", "on_playing", "on_beating"], sanity_completion_type, (value) -> {
				sanity_completion_type = value;
				refreshCurrentPage(); // Force refresh to update the display
			})
		});

		// Example state options (you can add actual complex settings states here)
		var exampleStateOptions:Array<StateOption> = [
			createStateOption("Song Selection (DO NOT CLICK!)", "Open advanced song selection interface",
				cast states.freeplay.FreeplayState, // Example: open freeplay for song selection
				[], // No constructor args
				[states.CategoryState], // Allow navigation to these states
				["selectedSongs", "difficulty"] // Variables to capture
			)
		];


		// Z11 Options Page - things you can but probably shouldn't turn on
		var z11Options:Array<SettingsOption> = [];

		z11Options.push({
			name: "Starter Debuffs",
			description: "Inflicts you with four near-perminant debuffs (SEE WIKI PAGE FOR DEBUFF DETAILS)",
			callback: function() {
				starter_debuffs = !starter_debuffs;
				perma_traps = false; // Disable perma-traps if starter debuff is enabled
				refreshCurrentPage();
			},
			locked: false,
			contextMenu: createBoolContextMenu(starter_debuffs, function(value:Bool) {
				starter_debuffs = value;
				// Don't refresh here - the main callback will handle it
			})
		});

		z11Options.push({
			name: "Perma-Traps",
			description: "Makes the starting debuffs Trap Items instead (SEE WIKI PAGE FOR DEBUFF DETAILS)",
			callback: function() {
				perma_traps = !perma_traps;
				starter_debuffs = false; // Disable starter debuff if perma-traps is enabled
				refreshCurrentPage();
			},
			locked: false,
			contextMenu: createBoolContextMenu(perma_traps, function(value:Bool) {
				perma_traps = value;
				// Don't refresh here - the main callback will handle it
			})
		});

		z11Options.push({
			name: "HARD MODE",
			description: "Huh? You don't want to be able to play the game right off the bat? No problem! (SEE WIKI PAGE FOR HARD MODE DETAILS)",
			callback: function() {
				hard_mode = !hard_mode;
				if (hard_mode) FlxG.sound.play(Paths.sound('mus-mode'), 2);
				refreshCurrentPage();
			},
			locked: false,
			contextMenu: createBoolContextMenu(hard_mode, function(value:Bool) {
				hard_mode = value;
				if (hard_mode) FlxG.sound.play(Paths.sound('mus-mode'), 2);
				// Don't refresh here - the main callback will handle it
			})
		});

		z11Options.push({
			name: "Enable Shop",
			description: "Hey there. Heard you wanted to buy things from me. (SEE WIKI PAGE FOR SHOP DETAILS)",
			callback: function() {
				enable_shop = !enable_shop;
				if (enable_shop) FlxG.sound.play(Paths.sound('uh oh'), 2);
				else FlxG.sound.play(Paths.sound('ok nevermind were good'), 2);
				refreshCurrentPage();
			},
			locked: true,
			contextMenu: createBoolContextMenu(enable_shop, function(value:Bool) {
				enable_shop = value;
				if (enable_shop) FlxG.sound.play(Paths.sound('uh oh'), 2);
				else FlxG.sound.play(Paths.sound('ok nevermind were good'), 2);
				// Don't refresh here - the main callback will handle it
			})
		});

		z11Options.push({
			name: "???",
			description: "Oh me? Don't worry about why i'm here. Not yet, at least~",
			callback: function() {
				FlxG.sound.play(Paths.sound('mus-wawa'));
				refreshCurrentPage();
			},
			locked: true,
			contextMenu: createEditContextMenu(() -> giveNotice())
		});

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
			},
			{
				name: "SANITY OPTIONS",
				description: "Configure additional item types for stage and character checks",
				options: sanityOptions,
				stateOptions: [],
				color: FlxColor.PINK
			},
			{
				name: "Z11'S OPTIONAL HELL",
				description: "Fun(?) things I decided to add for those looking for something more than the usual >:)",
				options: z11Options,
				stateOptions: [],
				color: FlxColor.WHITE
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
			case BOOLEAN(trueLabel, falseLabel, setValue):
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
						case BOOLEAN(_, _, _):
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
			case BOOLEAN(trueLabel, falseLabel, setValue):
				// buttonIndex 1 = true, 0 = false
				var newValue = buttonIndex == 1;
				setValue(newValue);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				refreshCurrentPage();
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
		if (page.name == "Z11'S OPTIONAL HELL") {
			rainbowText = true;
		} else {rainbowText = false; titleText.color = page.color;}
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
			case "Ultimate Confusion Trap Weight": Std.string(ultConfusionWeight);
			case "SVC Weight": Std.string(svcWeight);
			case "Fake Transition Weight": Std.string(fakeTransWeight);
			case "Shield Weight": Std.string(shieldWeight);
			case "Max HP Up Weight": Std.string(MHPWeight);
			case "Max HP Down Weight": Std.string(MHPDWeight);
			case "Extra Life Weight": Std.string(exLifeWeight);
			case "Enable Sanity Locations": enable_sanity_locations ? "ON" : "OFF";
			case "Sanity Completion Type": sanity_completion_type;
			case "Stagesanity": stagesanity ? "ON" : "OFF";
			case "Charactersanity": charactersanity ? "ON" : "OFF";
			case "Starter Debuffs": starter_debuffs ? "ON" : "OFF";
			case "Perma-Traps": perma_traps ? "ON" : "OFF";
			case "HARD MODE": hard_mode ? "ON" : "OFF";
			case "Enable Shop": enable_shop ? "ON" : "OFF";
			case "???": true ? "Not Yet..." : "Not Yet...";
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

				trackTween(FlxTween.tween(button, {x: targetX}, transitionTime + (i * 0.05), {
					ease: FlxEase.backOut,
					onComplete: function(tween:FlxTween)
					{
						completedAnimations++;
						activeTweens.remove(tween); // Remove from tracking when complete
						if (completedAnimations == totalAnimations)
						{
							isAnimating = false;
						}
					}
				}));
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

				trackTween(FlxTween.tween(text, {x: targetX}, transitionTime + (i * 0.05), {
					ease: FlxEase.backOut
				}));
			}
		}
	}

	function animateIn()
	{
		// Animate UI elements in
		titleText.y = -100;
		trackTween(FlxTween.tween(titleText, {y: 30}, 0.8, {ease: FlxEase.backOut}));

		descriptionText.alpha = 0;
		trackTween(FlxTween.tween(descriptionText, {alpha: 1}, 1.2, {ease: FlxEase.sineOut}));

		leftArrow.x = -100;
		rightArrow.x = FlxG.width + 100;
		trackTween(FlxTween.tween(leftArrow, {x: 30}, 1, {ease: FlxEase.backOut}));
		trackTween(FlxTween.tween(rightArrow, {x: FlxG.width - 80}, 1, {ease: FlxEase.backOut}));

		exportButton.y = FlxG.height + 50;
		closeButton.y = FlxG.height + 50;
		trackTween(FlxTween.tween(exportButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut}));
		trackTween(FlxTween.tween(closeButton, {y: FlxG.height - 80}, 1.2, {ease: FlxEase.backOut}));
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

	function cycleSanityCompletionType()
	{
		var options = ["on_getting", "on_playing", "on_beating"];
		var current = options.indexOf(sanity_completion_type);
		sanity_completion_type = options[(current + 1) % options.length];
		refreshCurrentPage();
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
		}, 16, // Max length
			"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_", // Allowed characters
			"Enter your player name for Archipelago (YAML-safe characters only)", FlxColor.CYAN,
			YAML); // Use YAML input mode
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
		// First save current settings and regenerate song list to get accurate count
		saveCurrentSettings();
		if (APSettingsSubState.globalSongList.length == 0) // No need to do it if its already loaded
			APSettingsSubState.generateSongList();
		var maxSongs = Std.int(Math.max(5, APSettingsSubState.globalSongList.length));
		var count = 0;
		for (song in APSettingsSubState.globalSongList)
		{
			count++;
		}

		if (maxSongs != count)
		{
			trace("Discrepancy in song count! Counted: " + count + ", Length: " + maxSongs);
			maxSongs = count;
		}

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

	function adjustConfusionWeight()
	{
		openSliderControl("Ultimate Confusion Trap Weight", ultConfusionWeight, 0, 10, 1, function(value:Float)
		{
			ultConfusionWeight = Std.int(value);
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

	function openBooleanSelectionPrompt(title:String, trueLabel:String, falseLabel:String, setValue:Bool->Void)
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
			// Use the setValue callback to set the boolean value
			var boolValue = selectedOption.value == "true";
			setValue(boolValue);
			refreshCurrentPage();
		});
		openSubState(enumSubstate);
	}

	function giveNotice() openSubState(new Prompt("Give it time, hun.\nWe'll get to know each other soon enough,\nI promise~ ", 0, null, null, false, "Wait What", "Who the heck-"));

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
			case "Sanity Completion Type":
				sanity_completion_type = Std.string(value);
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

				// Check if this is a modded song and mods are disabled
				if (!allowMods)
				{
					allowMods = true;
					startingSong = formattedName;
					startingSongData = songData;
					updateSongStats();
					refreshCurrentPage();

					// Show info notification about enabling mods
					var infoPanel = new InfoPanelSubstate("Mods Auto-Enabled",
						"Mods have been automatically enabled because you selected a modded song:\n\n" +
						formattedName + "\n\nThis setting has been updated in your configuration.",
						FlxColor.LIME);
					openSubState(infoPanel);
					return;
				}
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

				// Check if this is a modded song and mods are disabled
				if (!allowMods)
				{
					allowMods = true;
					victorySong = formattedName;
					victorySongData = songData;
					updateSongStats();
					refreshCurrentPage();

					// Show info notification about enabling mods
					var infoPanel = new InfoPanelSubstate("Mods Auto-Enabled",
						"Mods have been automatically enabled because you selected a modded song:\n\n" +
						formattedName + "\n\nThis setting has been updated in your configuration.",
						FlxColor.LIME);
					openSubState(infoPanel);
					return;
				}
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
		if (states.CategoryState.loadWeekForce != "all")
		{
			states.CategoryState.loadWeekForce = "all";
		}

		// Create FreeplayManager with true parameter to ensure proper initialization
		var fpManager = new managers.FreeplayManager(true, true);

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

	function trackTween(tween:FlxTween):FlxTween
	{
		activeTweens.push(tween);
		return tween;
	}

	function refreshCurrentPage()
	{
		// Check if tweens are active or refresh already queued
		if (activeTweens.length > 0)
		{
			if (!refreshQueued)
			{
				refreshQueued = true;
				trace('Refresh queued - waiting for ${activeTweens.length} active tweens to complete');
			}
			return;
		}

		// Only refresh if UI has been set up
		if (statsText == null)
			return;

		// Clear queue flag since we're executing now
		refreshQueued = false;

		loadPage(currentPage);
		updateSongStats();
		saveTempData(); // Save changes
	}

	function updateSongStats()
	{
		// First save the current settings so the song list generation can use them
		saveCurrentSettings();

		// Regenerate the song list with current settings
		APSettingsSubState.generateSongList();

		// Calculate song counts and stats using the actual generated list
		var totalSongs = APSettingsSubState.globalSongList.length;
		var totalChecks = 0;
		var modCount = backend.Mods.parseList().enabled.length;

		// Calculate base song count from actual included categories
		var baseSongCount = 0;
		if (includeVanilla)
		{
			baseSongCount += APInfo.baseGame.length;
		}
		if (includePico)
		{
			baseSongCount += APInfo.basePico.length;
		}
		if (includeErect)
		{
			baseSongCount += APInfo.baseErect.length;
		}
		if (includeSecrets)
		{
			baseSongCount += APInfo.secrets.length;
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
		statsString += "Total Songs Generated: " + totalSongs + "\n";
		statsString += "Base Songs Included: " + baseSongCount + "\n";
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
	 * Scan all accessible charts using engine systems and extract stage information for stagesanity
	 * @return Map of stage names to arrays of song data with difficulties that use them
	 */
	function scanStagesFromCharts():Map<String, Array<{song:String, ?mod:String, difficulties:Array<String>}>>
	{
		var stageMap:Map<String, Array<{song:String, ?mod:String, difficulties:Array<String>}>> = new Map();

		// Set up category to get all songs
		if (states.CategoryState.loadWeekForce == null)
		{
			states.CategoryState.loadWeekForce = "all";
		}

		// Reload week data to ensure everything is available
		WeekData.reloadWeekFiles(false);

		// Create FreeplayManager to get the song list
		var fpManager = new managers.FreeplayManager(true);
		fpManager.reloadFreeplay(true, ''); // Use refresh=true to get all songs

		if (fpManager != null && fpManager.songList != null)
		{
			trace('Scanning ${fpManager.songList.length} songs for stage data...');

			for (songData in fpManager.songList)
			{
				if (songData == null) continue;

				var songName = songData.songName;
				var modName = songData.folder;
				var week = songData.week;

				// Get the week data to set the proper directory
				if (week >= 0 && week < WeekData.weeksList.length)
				{
					var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[week]);
					if (leWeek != null)
					{
						WeekData.setDirectoryFromWeek(leWeek);

						// Get available difficulties for this song
						Difficulty.loadFromWeek(leWeek);
						var difficulties = Difficulty.list.copy();

						// Track which difficulties use each stage for this song
						var stageToDirectDifficulties:Map<String, Array<String>> = new Map();

						// Scan each difficulty for stage data
						for (difficulty in difficulties)
						{
							try
							{
								// Use Song.getChart() which properly handles all chart formats
								var chartName = songName + Difficulty.getFilePath(Difficulty.list.indexOf(difficulty));
								var songData:SwagSong = Song.getChart(chartName, songName);

								if (songData != null)
								{
									// Extract stage information
									var stageName:String = songData.stage ?? StageData.vanillaSongStage(songName);

									if (stageName != null && stageName.trim().length > 0)
									{
										if (!stageToDirectDifficulties.exists(stageName))
										{
											stageToDirectDifficulties.set(stageName, []);
										}
										stageToDirectDifficulties.get(stageName).push(difficulty);
									} else if (stageName == null) {
										trace('No stage defined for $songName ($difficulty)');
										stageName = StageData.vanillaSongStage(songName);
										if (stageName != null && stageName.trim().length > 0)
										{
											if (!stageToDirectDifficulties.exists(stageName))
											{
												stageToDirectDifficulties.set(stageName, []);
											}
											stageToDirectDifficulties.get(stageName).push(difficulty);
										}
									}
								}
							}
							catch (e:Dynamic)
							{
								// trace('Failed to load chart for $songName ($difficulty): $e');
								continue;
							}
						}

						// Add songs to stage maps with their difficulties
						for (stageName in stageToDirectDifficulties.keys())
						{
							var difficultiesForStage = stageToDirectDifficulties.get(stageName);

							if (!stageMap.exists(stageName))
							{
								stageMap.set(stageName, []);
							}

							// Create song object with optional mod field
							var songObj:Dynamic = {
								song: songName,
								difficulties: difficultiesForStage.copy()
							};

							// Only add mod field if it exists and is not empty
							if (modName != null && modName.length > 0)
							{
								songObj.mod = modName;
							}

							// Check if this song is already in the list (merge difficulties if so)
							var existingSongIndex = -1;
							for (i in 0...stageMap.get(stageName).length)
							{
								var existingSong = stageMap.get(stageName)[i];
								var existingMod = Reflect.hasField(existingSong, "mod") ? existingSong.mod : null;
								var currentMod = Reflect.hasField(songObj, "mod") ? songObj.mod : null;

								if (existingSong.song == songObj.song && existingMod == currentMod)
								{
									existingSongIndex = i;
									break;
								}
							}

							if (existingSongIndex >= 0)
							{
								// Merge difficulties
								var existingSong = stageMap.get(stageName)[existingSongIndex];
								for (diff in difficultiesForStage)
								{
									if (!existingSong.difficulties.contains(diff))
									{
										existingSong.difficulties.push(diff);
									}
								}
							}
							else
							{
								// Add new song
								stageMap.get(stageName).push(songObj);
							}
						}
					}
				}
			}
		}
		else
		{
			trace("Stage scanning failed - FreeplayManager or song list is null");
		}

		// Scan secret songs if includeSecrets is enabled
		if (includeSecrets)
		{
			trace("Scanning secret songs for stage data...");

			for (secretSong in APInfo.secrets)
			{
				try
				{
					// Set up difficulties for each secret song based on FreeplayState logic
					var difficulties:Array<String> = [];
					switch (secretSong)
					{
						case 'Small Argument' | 'Beat Battle 2' | 'GeoStar':
							difficulties = ['Hard'];
						case "Beat Battle":
							difficulties = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
						default:
							difficulties = ['Hard']; // Default for any other secret songs
					}

					// Scan each difficulty for stage data
					for (difficulty in difficulties)
					{
						try
						{
							// Load the chart for this secret song and difficulty
							var chartName = switch (secretSong)
							{
								case 'Small Argument': 'small-argument-hard';
								case 'Beat Battle':
									switch (difficulty.toLowerCase())
									{
										case 'normal': 'beat-battle-normal';
										case 'reasonable': 'beat-battle-reasonable';
										case 'unreasonable': 'beat-battle-unreasonable';
										case 'semi-impossible': 'beat-battle-semi-impossible';
										case 'impossible': 'beat-battle-impossible';
										default: 'beat-battle-reasonable'; // Default fallback
									}
								case 'Beat Battle 2': 'beat-battle-2-hard';
								case 'GeoStar': 'geostar-hard';
								default: secretSong.toLowerCase() + '-' + difficulty.toLowerCase();
							}

							var folderName = switch (secretSong)
							{
								case 'Small Argument': 'small-argument';
								case 'Beat Battle': 'beat-battle';
								case 'Beat Battle 2': 'beat-battle-2';
								case 'GeoStar': 'geostar';
								default: secretSong.toLowerCase();
							}

							var songData:SwagSong = Song.getChart(chartName, folderName);

							if (songData != null)
							{
								// Extract stage information
								var stageName:String = songData.stage;

								if (stageName != null && stageName.trim().length > 0)
								{
									if (!stageMap.exists(stageName))
									{
										stageMap.set(stageName, []);
									}

									// Create song object (no mod field for secret songs)
									var songObj:Dynamic = {
										song: secretSong,
										difficulties: [difficulty]
									};

									// Check if this song is already in the list (merge difficulties if so)
									var existingSongIndex = -1;
									for (i in 0...stageMap.get(stageName).length)
									{
										var existingSong = stageMap.get(stageName)[i];
										if (existingSong.song == secretSong)
										{
											existingSongIndex = i;
											break;
										}
									}

									if (existingSongIndex >= 0)
									{
										// Merge difficulties
										var existingSong = stageMap.get(stageName)[existingSongIndex];
										if (!existingSong.difficulties.contains(difficulty))
										{
											existingSong.difficulties.push(difficulty);
										}
									}
									else
									{
										// Add new song
										stageMap.get(stageName).push(songObj);
									}
								}
							}
						}
						catch (e:Dynamic)
						{
							// trace('Failed to load chart for secret song $secretSong ($difficulty): $e');
							continue;
						}
					}
				}
				catch (e:Dynamic)
				{
					trace('Error scanning secret song ${secretSong}: ${e}');
				}
			}
		}

		return stageMap;
	}

	/**
	 * Scan all accessible charts using engine systems and extract character information for charactersanity
	 * @return Map of character names to arrays of song names that use them
	 */
	function scanCharactersFromCharts():Map<String, Array<{song:String, ?mod:String, difficulties:Array<String>}>>
	{
		var characterMap:Map<String, Array<{song:String, ?mod:String, difficulties:Array<String>}>> = new Map();

		// Set up category to get all songs
		if (states.CategoryState.loadWeekForce == null)
		{
			states.CategoryState.loadWeekForce = "all";
		}

		// Reload week data to ensure everything is available
		WeekData.reloadWeekFiles(false);

		// Create FreeplayManager to get the song list
		var fpManager = new managers.FreeplayManager(true);
		fpManager.reloadFreeplay(true, ''); // Use refresh=true to get all songs

		if (fpManager != null && fpManager.songList != null)
		{
			trace('Scanning ${fpManager.songList.length} songs for character data...');

			for (songData in fpManager.songList)
			{
				if (songData == null) continue;

				var songName = songData.songName;
				var modName = songData.folder;
				var week = songData.week;

				// Get the week data to set the proper directory
				if (week >= 0 && week < WeekData.weeksList.length)
				{
					var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[week]);
					if (leWeek != null)
					{
						WeekData.setDirectoryFromWeek(leWeek);

						// Get available difficulties for this song
						Difficulty.loadFromWeek(leWeek);
						var difficulties = Difficulty.list.copy();

						// Track which difficulties use each character for this song
						var characterToDifficulties:Map<String, Array<String>> = new Map();

						// Scan each difficulty for character data
						for (difficulty in difficulties)
						{
							try
							{
								// Use Song.getChart() which properly handles all chart formats
								var chartName = songName + Difficulty.getFilePath(Difficulty.list.indexOf(difficulty));
								var songData:SwagSong = Song.getChart(chartName, songName);

								if (songData != null)
								{
									// Extract character information
									var characters:Array<String> = [];

									// Check for player1 (boyfriend)
									if (songData.player1 != null && songData.player1.trim().length > 0)
										characters.push(songData.player1);

									// Check for player2 (opponent/dad)
									if (songData.player2 != null && songData.player2.trim().length > 0)
										characters.push(songData.player2);

									// Check for player4 (second opponent)
									if (songData.player4 != null && songData.player4.trim().length > 0)
										characters.push(songData.player4);

									// Check for player5 (third opponent)
									if (songData.player5 != null && songData.player5.trim().length > 0)
										characters.push(songData.player5);

									// Track which difficulty uses which characters
									for (character in characters)
									{
										if (!characterToDifficulties.exists(character))
										{
											characterToDifficulties.set(character, []);
										}
										characterToDifficulties.get(character).push(difficulty);
									}
								}
							}
							catch (e:Dynamic)
							{
								// trace('Failed to load chart for $songName ($difficulty): $e');
								continue;
							}
						}

						// Add songs to character maps with their difficulties
						for (character in characterToDifficulties.keys())
						{
							var difficultiesForCharacter = characterToDifficulties.get(character);

							if (!characterMap.exists(character))
							{
								characterMap.set(character, []);
							}

							// Create song object with optional mod field
							var songObj:Dynamic = {
								song: songName,
								difficulties: difficultiesForCharacter.copy()
							};

							// Only add mod field if it exists and is not empty
							if (modName != null && modName.length > 0)
							{
								songObj.mod = modName;
							}

							// Check if this song is already in the list (merge difficulties if so)
							var existingSongIndex = -1;
							for (i in 0...characterMap.get(character).length)
							{
								var existingSong = characterMap.get(character)[i];
								var existingMod = Reflect.hasField(existingSong, "mod") ? existingSong.mod : null;
								var currentMod = Reflect.hasField(songObj, "mod") ? songObj.mod : null;

								if (existingSong.song == songObj.song && existingMod == currentMod)
								{
									existingSongIndex = i;
									break;
								}
							}

							if (existingSongIndex >= 0)
							{
								// Merge difficulties
								var existingSong = characterMap.get(character)[existingSongIndex];
								for (diff in difficultiesForCharacter)
								{
									if (!existingSong.difficulties.contains(diff))
									{
										existingSong.difficulties.push(diff);
									}
								}
							}
							else
							{
								// Add new song
								characterMap.get(character).push(songObj);
							}
						}
					}
				}
			}
		}
		else
		{
			trace("Character scanning failed - FreeplayManager or song list is null");
		}

		// Scan secret songs if includeSecrets is enabled
		if (includeSecrets)
		{
			trace("Scanning secret songs for character data...");

			for (secretSong in APInfo.secrets)
			{
				try
				{
					// Set up difficulties for each secret song based on FreeplayState logic
					var difficulties:Array<String> = [];
					switch (secretSong)
					{
						case 'Small Argument' | 'Beat Battle 2' | 'GeoStar':
							difficulties = ['Hard'];
						case "Beat Battle":
							difficulties = ["Normal", "Reasonable", "Unreasonable", "Semi-Impossible", "Impossible"];
						default:
							difficulties = ['Hard']; // Default for any other secret songs
					}

					// Track which difficulties use each character for this song
					var characterToDifficulties:Map<String, Array<String>> = new Map();

					// Scan each difficulty for character data
					for (difficulty in difficulties)
					{
						try
						{
							// Load the chart for this secret song and difficulty
							var chartName = switch (secretSong)
							{
								case 'Small Argument': 'small-argument-hard';
								case 'Beat Battle':
									switch (difficulty.toLowerCase())
									{
										case 'normal': 'beat-battle-normal';
										case 'reasonable': 'beat-battle-reasonable';
										case 'unreasonable': 'beat-battle-unreasonable';
										case 'semi-impossible': 'beat-battle-semi-impossible';
										case 'impossible': 'beat-battle-impossible';
										default: 'beat-battle-reasonable'; // Default fallback
									}
								case 'Beat Battle 2': 'beat-battle-2-hard';
								case 'GeoStar': 'geostar-hard';
								default: secretSong.toLowerCase() + '-' + difficulty.toLowerCase();
							}

							var folderName = switch (secretSong)
							{
								case 'Small Argument': 'small-argument';
								case 'Beat Battle': 'beat-battle';
								case 'Beat Battle 2': 'beat-battle-2';
								case 'GeoStar': 'geostar';
								default: secretSong.toLowerCase();
							}

							var songData:SwagSong = Song.getChart(chartName, folderName);

							if (songData != null)
							{
								// Extract character information
								var characters:Array<String> = [];

								// Check for player1 (boyfriend)
								if (songData.player1 != null && songData.player1.trim().length > 0)
									characters.push(songData.player1);

								// Check for player2 (opponent/dad)
								if (songData.player2 != null && songData.player2.trim().length > 0)
									characters.push(songData.player2);

								// Check for player4 (second opponent)
								if (songData.player4 != null && songData.player4.trim().length > 0)
									characters.push(songData.player4);

								// Check for player5 (third opponent)
								if (songData.player5 != null && songData.player5.trim().length > 0)
									characters.push(songData.player5);

								// Track which difficulty uses which characters
								for (character in characters)
								{
									if (!characterToDifficulties.exists(character))
									{
										characterToDifficulties.set(character, []);
									}
									characterToDifficulties.get(character).push(difficulty);
								}
							}
						}
						catch (e:Dynamic)
						{
							// trace('Failed to load chart for secret song $secretSong ($difficulty): $e');
							continue;
						}
					}

					// Add songs to character maps with their difficulties
					for (character in characterToDifficulties.keys())
					{
						var difficultiesForCharacter = characterToDifficulties.get(character);

						if (!characterMap.exists(character))
						{
							characterMap.set(character, []);
						}

						// Create song object (no mod field for secret songs)
						var songObj:Dynamic = {
							song: secretSong,
							difficulties: difficultiesForCharacter.copy()
						};

						// Check if this song is already in the list (merge difficulties if so)
						var existingSongIndex = -1;
						for (i in 0...characterMap.get(character).length)
						{
							var existingSong = characterMap.get(character)[i];
							if (existingSong.song == secretSong)
							{
								existingSongIndex = i;
								break;
							}
						}

						if (existingSongIndex >= 0)
						{
							// Merge difficulties
							var existingSong = characterMap.get(character)[existingSongIndex];
							for (diff in difficultiesForCharacter)
							{
								if (!existingSong.difficulties.contains(diff))
								{
									existingSong.difficulties.push(diff);
								}
							}
						}
						else
						{
							// Add new song
							characterMap.get(character).push(songObj);
						}
					}
				}
				catch (e:Dynamic)
				{
					trace('Error scanning secret song ${secretSong}: ${e}');
				}
			}
		}

		return characterMap;
	}

	/**
	 * Generate the sanity data object for YAML export
	 * @return Dynamic object containing stage and character data
	 */
	function generateSanityData():Dynamic
	{
		var sanityData:Dynamic = {};

		if (stagesanity)
		{
			var stageMap = scanStagesFromCharts();
			var stageArray:Array<Dynamic> = [];

			for (stageName in stageMap.keys())
			{
				var songList = stageMap.get(stageName);
				if (songList != null && songList.length > 0)
				{
					stageArray.push({
						name: stageName,
						songs: songList
					});
				}
			}

			sanityData.Stage = stageArray;
		}

		if (charactersanity)
		{
			var characterMap = scanCharactersFromCharts();
			var characterArray:Array<Dynamic> = [];

			for (characterName in characterMap.keys())
			{
				var songList = characterMap.get(characterName);
				if (songList != null && songList.length > 0)
				{
					characterArray.push({
						name: characterName,
						songs: songList
					});
				}
			}

			sanityData.Character = characterArray;
		}

		return sanityData;
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
			ultConfusionWeight = settings.ultConfusionWeight;
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
			startingSong = settings.starting_song != null ? APInfo.realName(settings.starting_song) : "Tutorial";
			victorySong = settings.victory_song != null ? APInfo.realName(settings.victory_song) : "Tutorial";

			// Sanity settings with defaults
			enable_sanity_locations = Reflect.hasField(settings, "enable_sanity_locations") ? Reflect.field(settings, "enable_sanity_locations") : false;
			sanity_completion_type = Reflect.hasField(settings, "sanity_completion_type") ? Reflect.field(settings, "sanity_completion_type") : "on_getting";
			stagesanity = Reflect.hasField(settings, "stagesanity") ? settings.stagesanity : false;
			charactersanity = Reflect.hasField(settings, "charactersanity") ? settings.charactersanity : false;
			starter_debuffs = Reflect.hasField(settings, "starter_debuffs") ? settings.starter_debuffs : false;
			hard_mode = Reflect.hasField(settings, "hard_mode") ? settings.hard_mode : false;
			enable_shop = Reflect.hasField(settings, "enable_shop") ? settings.enable_shop : false;
			perma_traps = Reflect.hasField(settings, "perma_traps") ? settings.perma_traps : false;
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
			settings.ultConfusionWeight = ultConfusionWeight;
			settings.svcWeight = svcWeight;
			settings.fakeTransWeight = fakeTransWeight;
			settings.shieldWeight = shieldWeight;
			settings.MHPWeight = MHPWeight;
			settings.MHPDWeight = MHPDWeight;
			settings.exLifeWeight = exLifeWeight;

			// Save sanity settings
			Reflect.setField(settings, "enable_sanity_locations", enable_sanity_locations);
			Reflect.setField(settings, "sanity_completion_type", sanity_completion_type);
			settings.stagesanity = stagesanity;
			settings.charactersanity = charactersanity;
			settings.starter_debuffs = starter_debuffs;
			settings.perma_traps = perma_traps;
			settings.hard_mode = hard_mode;
			settings.enable_shop = enable_shop;
		}
	}

	function getTicketCount():Int
	{
		var ticketPercentFloat = ticketPercent / 100;
		var ticketCount = Std.int(Math.ceil(songLimit * ticketPercentFloat));
		return ticketCount;
	}

	function exportYAML()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Save current settings
		saveCurrentSettings();

		// Show styled export location choice dialog
		var exportChoiceSubstate = new ExportChoiceSubstate(function()
		{
			// User chose default location
			performYAMLExportToDefault();
		}, function()
		{
			// User chose custom location
			performYAMLExportWithDialog();
		});

		openSubState(exportChoiceSubstate);
	}

	function generateCustomContentInfoText():String
	{
		var content = "";

		// Summary
		content += "CUSTOM CONTENT SUMMARY:\n";
		content += "═══════════════════════\n\n";

		var totalContent = CustomAPLogic.APDataStore.getTotalCustomContent();
		content += "Total Custom Content Added: " + totalContent + "\n\n";

		// Items
		if (CustomAPLogic.APDataStore.items.length > 0) {
			content += "ITEMS (" + CustomAPLogic.APDataStore.items.length + "):\n";
			content += "─────────────────────────\n";
			for (item in CustomAPLogic.APDataStore.items) {
				var prefix = item.isTrap == true ? "[TRAP] " : "";
				var modSuffix = item.mod != null && item.mod != "" ? " (from " + item.mod + ")" : "";
				content += "• " + prefix + item.name + modSuffix + "\n";
			}
			content += "\n";
		}

		// Locations
		if (CustomAPLogic.APDataStore.locations.length > 0) {
			content += "LOCATIONS (" + CustomAPLogic.APDataStore.locations.length + "):\n";
			content += "─────────────────────────\n";
			for (location in CustomAPLogic.APDataStore.locations) {
				content += "• " + location.name + "\n";
				content += "  Song: " + location.originSong + " (Mod: " + location.targetMod + ")\n";
				content += "  Requires: ";
				var reqItems = [];
				for (req in location.accessRule.requiredItems) {
					var count = req.count != null && req.count > 1 ? req.count + "x " : "";
					reqItems.push(count + req.name);
				}
				content += reqItems.join(", ") + "\n\n";
			}
		}

		// Song Modifications
		if (CustomAPLogic.APDataStore.songAdditions.length > 0) {
			content += "SONG ADDITIONS (" + CustomAPLogic.APDataStore.songAdditions.length + "):\n";
			content += "─────────────────────────\n";
			for (song in CustomAPLogic.APDataStore.songAdditions) {
				content += "• " + song.name + " (to " + song.targetMod + ")\n";
			}
			content += "\n";
		}

		if (CustomAPLogic.APDataStore.songExclusions.length > 0) {
			content += "SONG EXCLUSIONS (" + CustomAPLogic.APDataStore.songExclusions.length + "):\n";
			content += "─────────────────────────\n";
			for (song in CustomAPLogic.APDataStore.songExclusions) {
				content += "• " + song.name + " (from " + song.targetMod + ")\n";
			}
			content += "\n";
		}

		// Custom Weeks
		if (CustomAPLogic.APDataStore.customWeeks.length > 0) {
			content += "CUSTOM WEEKS (" + CustomAPLogic.APDataStore.customWeeks.length + "):\n";
			content += "─────────────────────────\n";
			for (week in CustomAPLogic.APDataStore.customWeeks) {
				content += "• " + week.name + " (for " + week.targetMod + ")\n";
				content += "  Songs: " + week.songs.join(", ") + "\n\n";
			}
		}

		// Song Requirements - merge duplicate requirements and combine items
		if (CustomAPLogic.APDataStore.songRequirements.length > 0) {
			// Create a map to merge song requirements (one per song+targetMod combination)
			var mergedRequirements = new Map<String, CustomAPLogic.APSongRequirement>();
			for (req in CustomAPLogic.APDataStore.songRequirements) {
				var key = req.songName + "_" + req.targetMod;
				if (!mergedRequirements.exists(key)) {
					// First requirement for this song+mod - copy it
					var newReq:CustomAPLogic.APSongRequirement = {
						songName: req.songName,
						targetMod: req.targetMod,
						accessRule: {
							requiredItems: req.accessRule.requiredItems.copy()
						}
					};
					mergedRequirements.set(key, newReq);
				} else {
					// Merge additional requirements into existing one
					var existingReq = mergedRequirements.get(key);
					var existingItems = existingReq.accessRule.requiredItems;

					// Add new items that don't already exist (by name+mod combination)
					for (newItem in req.accessRule.requiredItems) {
						var itemExists = false;
						for (existingItem in existingItems) {
							if (existingItem.name == newItem.name &&
								existingItem.mod == newItem.mod) {
								// Item already exists - combine counts if needed
								if (newItem.count != null && newItem.count > 1 &&
									existingItem.count != null && existingItem.count > 1) {
									existingItem.count = Std.int(Math.max(existingItem.count, newItem.count));
								} else if (newItem.count != null && newItem.count > 1) {
									existingItem.count = newItem.count;
								}
								itemExists = true;
								break;
							}
						}

						if (!itemExists) {
							// Add new unique item
							existingItems.push(newItem);
						}
					}
				}
			}

			var uniqueCount = Lambda.count(mergedRequirements);
			content += "SONG REQUIREMENTS (" + uniqueCount + "):\n";
			content += "─────────────────────────\n";
			for (req in mergedRequirements) {
				content += "• " + req.songName + " (in " + req.targetMod + ")\n";
				content += "  Requires: ";
				var reqItems = [];
				for (item in req.accessRule.requiredItems) {
					var count = item.count != null && item.count > 1 ? item.count + "x " : "";
					var modSuffix = item.mod != null && item.mod != "" ? " (" + item.mod + ")" : "";
					reqItems.push(count + item.name + modSuffix);
				}
				content += reqItems.join(", ") + "\n\n";
			}
		}

		// Custom Data
		if (Lambda.count(CustomAPLogic.APDataStore.customData) > 0) {
			content += "CUSTOM DATA (" + Lambda.count(CustomAPLogic.APDataStore.customData) + " entries):\n";
			content += "─────────────────────────\n";
			for (key in CustomAPLogic.APDataStore.customData.keys()) {
				var value = CustomAPLogic.APDataStore.customData.get(key);
				content += "• " + key + ": " + Std.string(value) + "\n";
			}
			content += "\n";
		}

		// Success details per mod
		if (CustomAPLogic.APDataStore.processingSuccesses.length > 0) {
			content += "PROCESSING SUCCESSES:\n";
			content += "─────────────────────────\n";
			for (success in CustomAPLogic.APDataStore.processingSuccesses) {
				content += "✓ " + success.modName + "\n";
				content += "  Script: " + success.scriptPath.split("/").pop() + "\n";
				content += "  Added: " + success.itemsAdded + " items, " + success.locationsAdded + " locations\n";
				content += "  Songs: +" + success.songsAdded + " added, -" + success.songsExcluded + " excluded\n";
				content += "  Weeks: " + success.customWeeksAdded + " custom weeks\n";
				content += "  Requirements: " + success.songRequirementsAdded + " song requirements\n";
				content += "  Time: " + success.timestamp + "\n\n";
			}
		}

		return content;
	}

	function generateErrorInfoText():String
	{
		var content = "";

		content += "PROCESSING ERRORS:\n";
		content += "═══════════════════\n\n";

		// Get all errors and separate by type
		var allErrors = CustomAPLogic.APDataStore.processingErrors;
		var scriptErrors = [for (error in allErrors) if (error.errorType != "function_failure") error];
		var functionErrors = [for (error in allErrors) if (error.errorType == "function_failure") error];

		content += "Total Script Errors: " + scriptErrors.length + "\n";
		content += "Total Function Errors: " + functionErrors.length + "\n\n";

		// High-level script processing errors
		if (scriptErrors.length > 0) {
			content += "SCRIPT PROCESSING ERRORS:\n";
			content += "─────────────────────────\n";
			for (error in scriptErrors) {
				content += "❌ " + error.modName + "\n";
				content += "   Script: " + error.scriptPath.split("/").pop() + "\n";
				content += "   Type: " + error.errorType + "\n";
				content += "   Error: " + error.errorMessage + "\n";
				content += "   Time: " + error.timestamp + "\n\n";
			}
		}

		// Detailed function-level errors
		if (functionErrors.length > 0) {
			content += "FUNCTION ERRORS:\n";
			content += "───────────────\n";

			// Group errors by function type for better organization
			var groupedErrors = new Map<String, Array<APProcessingError>>();
			for (error in functionErrors) {
				// Extract function name from error message
				var functionName = "Unknown";
				if (error.errorMessage.indexOf("Function ") == 0) {
					var colonIndex = error.errorMessage.indexOf(":");
					if (colonIndex > 0) {
						functionName = error.errorMessage.substring(9, colonIndex); // Skip "Function "
					}
				}

				if (!groupedErrors.exists(functionName)) {
					groupedErrors.set(functionName, []);
				}
				groupedErrors.get(functionName).push(error);
			}

			// Display errors grouped by function
			for (functionName in groupedErrors.keys()) {
				var functionErrorList = groupedErrors.get(functionName);
				content += '${functionName.toUpperCase()} (${functionErrorList.length} errors):\n';

				for (i in 0...functionErrorList.length) {
					var error = functionErrorList[i];
					// Extract the actual error message after "Function functionName: "
					var displayMessage = error.errorMessage;
					var functionPrefix = 'Function ${functionName}: ';
					if (displayMessage.indexOf(functionPrefix) == 0) {
						displayMessage = displayMessage.substring(functionPrefix.length);
					}
					content += '  ${i + 1}. ${displayMessage}\n';
					content += '     Script: ${error.scriptPath.split("/").pop()}\n';
					content += '\n';
				}
			}
		}

		content += "TROUBLESHOOTING:\n";
		content += "───────────────\n";
		content += "• Check script syntax in HScript files\n";
		content += "• Ensure mod names are correct and enabled\n";
		content += "• Verify song names exist in target mods\n";
		content += "• Check for typos in item/location names\n";
		content += "• Avoid duplicate items, locations, or requirements\n";
		content += "• Ensure color arrays have exactly 3 values [R, G, B]\n";
		content += "• Verify difficulty names are not empty\n";
		content += "• Consult engine documentation for HScript AP integration\n";

		return content;
	}

	function showExportResults()
	{
		// Only show export results if mods are allowed
		if (!allowMods) {
			// For refresh operations, return to entry state without showing results
			if (forceExportPath != null) {
				FlxG.switchState(new APStyledEntryState());
			}
			return;
		}

		var hasSuccesses = CustomAPLogic.APDataStore.getTotalCustomContent() > 0 || CustomAPLogic.APDataStore.processingSuccesses.length > 0;
		var hasErrors = CustomAPLogic.APDataStore.processingErrors.length > 0;

		if (hasSuccesses && !hasErrors) {
			// Only successes - show green box
			var successContent = generateCustomContentInfoText();
			openSubState(new InfoPanelSubstate("Custom Content Export Success", successContent, FlxColor.LIME, function() {
				// For refresh operations, return to entry state after showing results
				if (forceExportPath != null) {
					FlxG.switchState(new APStyledEntryState());
				}
			}));
		}
		else if (!hasSuccesses && hasErrors) {
			// Only errors - show red box
			var errorContent = generateErrorInfoText();
			openSubState(new InfoPanelSubstate("Custom Content Processing Errors", errorContent, FlxColor.RED, function() {
				// For refresh operations, return to entry state after showing results
				if (forceExportPath != null) {
					FlxG.switchState(new APStyledEntryState());
				}
			}));
		}
		else if (hasSuccesses && hasErrors) {
			// Both - show success first, then error on close
			var successContent = generateCustomContentInfoText();
			openSubState(new InfoPanelSubstate("Custom Content Export Success", successContent, FlxColor.LIME, function() {
				// On close of success box, show error box
				var errorContent = generateErrorInfoText();
				openSubState(new InfoPanelSubstate("Custom Content Processing Errors", errorContent, FlxColor.RED, function() {
					// For refresh operations, return to entry state after showing all results
					if (forceExportPath != null) {
						FlxG.switchState(new APStyledEntryState());
					}
				}));
			}));
		}
		else if (forceExportPath != null) {
			// No custom content but this is a refresh - still return to entry state
			FlxG.switchState(new APStyledEntryState());
		}
	}

	// Central function to build YAML data object with all settings
	function buildYamlDataObject():Dynamic
	{
		// Ensure song list is generated
		var checks = 0;
		while (APSettingsSubState.globalSongList.length == 0)
		{
			APSettingsSubState.generateSongList();
			checks++;
			if (checks >= 20)
			{
				throw new Exception("No songs were found within the allowed time. Check to make sure your settings permit songs to be selected.");
			}
		}
		APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;

		if (APEntryState.gameSettings.FNF.songList.length == 0)
		{
			while (APEntryState.gameSettings.FNF.songList.length == 0)
			{
				APSettingsSubState.generateSongList();
				checks++;
				APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;
				if (checks >= 20)
				{
					throw new Exception("No songs were found within the allowed time. Check to make sure your settings permit songs to be selected.");
				}
			}
		}

		// Process CustomAPLogic scripts before generating YAML (only if allowMods is true)
		trace('Processing CustomAPLogic scripts...');
		if (allowMods)
		{
			CustomAPLogic.APHScriptProcessor.processAllMods();
		}
		else
		{
			trace('Skipping CustomAPLogic processing - allowMods is false');
		}

		// Build base YAML object from game settings
		var yamlThing = {};
		for (thing in Reflect.fields(APEntryState.gameSettings.FNF))
		{
			Reflect.setField(yamlThing, thing, Reflect.field(APEntryState.gameSettings.FNF, thing));
		}

		// Add all advanced settings
		Reflect.setField(yamlThing, "include_secrets", includeSecrets);
		Reflect.setField(yamlThing, "include_pico", includePico);
		Reflect.setField(yamlThing, "include_erect", includeErect);
		Reflect.setField(yamlThing, "include_vanilla", includeVanilla);
		Reflect.setField(yamlThing, "enable_sanity_locations", enable_sanity_locations);
		Reflect.setField(yamlThing, "sanity_completion_type", sanity_completion_type);
		Reflect.setField(yamlThing, "stagesanity", stagesanity);
		Reflect.setField(yamlThing, "charactersanity", charactersanity);
		Reflect.setField(yamlThing, "starter_debuffs", starter_debuffs);
		Reflect.setField(yamlThing, "perma_traps", perma_traps);
		Reflect.setField(yamlThing, "hard_mode", hard_mode);
		Reflect.setField(yamlThing, "enable_shop", enable_shop);
		Reflect.setField(yamlThing, "allow_mods", allowMods);

		// Handle optional song settings
		if (startingSong != null)
		{
			Reflect.setField(yamlThing, "starting_song", APInfo.toYAMLSafe(startingSong));
		}
		else
		{
			Reflect.deleteField(yamlThing, "starting_song");
		}
		if (victorySong != null)
		{
			Reflect.setField(yamlThing, "victory_song", APInfo.toYAMLSafe(victorySong));
		}
		else
		{
			Reflect.deleteField(yamlThing, "victory_song");
		}

		// Generate and compress Python script for CustomAPLogic (only if allowMods is true and content exists)
		if (allowMods && (CustomAPLogic.APDataStore.items.length > 0
			|| CustomAPLogic.APDataStore.locations.length > 0
			|| CustomAPLogic.APDataStore.customWeeks.length > 0
			|| Lambda.count(CustomAPLogic.APDataStore.customData) > 0))
		{
			trace('Generating Python script for CustomAPLogic...');

			// Generate the Python script content
			var pythonContent = CustomAPLogic.APPythonGenerator.generatePythonScript();

			if (pythonContent != null && pythonContent.length > 0)
			{
				// ALWAYS compress the Python script using Base64 encoding
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
		else if (!allowMods)
		{
			trace('Skipping Python script generation - allowMods is false');
		}

		// Add sanity data if any sanity options are enabled
		if (stagesanity || charactersanity)
		{
			var sanityData = generateSanityData();
			if (sanityData != null)
			{
				// Convert sanity data to JSON and encode in Base64
				var sanityJson = haxe.Json.stringify(sanityData);
				var compressedSanityData = Base64.encode(haxe.io.Bytes.ofString(sanityJson));

				// Embed as sanity in the YAML
				Reflect.setField(yamlThing, "sanity", compressedSanityData);
				trace('Sanity data compressed and embedded (${sanityJson.length} chars -> ${compressedSanityData.length} chars Base64)');
			}
		}

		// Shuffle song list
		APEntryState.gameSettings.FNF.songList = APSettingsSubState.globalSongList;
		FlxG.random.shuffle(APEntryState.gameSettings.FNF.songList);

		return yamlThing;
	}

	// Central function to generate complete YAML document
	function generateCompleteYamlDocument(yamlDataObject:Dynamic):String
	{
		var mainSettings = {
			name: playerName,
			description: APEntryState.gameSettings.description,
			game: APEntryState.gameSettings.game
		};

		var document = Yaml.render(mainSettings, Renderer.options().setFlowLevel(1));

		// Create enhanced comment with stats
		var comment = generateYAMLComment(yamlDataObject);

		var yamlString = "Friday Night Funkin:\n";
		for (key in Reflect.fields(yamlDataObject))
		{
			yamlString += "  " + key + ": " + Reflect.field(yamlDataObject, key) + "\n";
		}

		return document + comment + yamlString;
	}

	// Central function to save YAML to file with different destination options
	function saveYamlToFile(yamlContent:String, destination:String, ?specificPath:String):Void
	{
		#if sys
		switch (destination)
		{
			case "default":
				// Save to default PlayerSettings location
				if (!sys.FileSystem.exists("./PlayerSettings/"))
					sys.FileSystem.createDirectory("./PlayerSettings/");
				sys.io.File.saveContent("PlayerSettings/" + playerName + ".yaml", yamlContent);

			case "dialog":
				// Use ImprovedFileHandling to save the file with user-chosen location
				var defaultFileName = playerName + ".yaml";
				var success = yutautil.ImprovedFileHandling.saveOperation("Export YAML Configuration",
					{ext: "yaml", desc: "FNF AP YAML File"},
					Text,
					yamlContent,
					true);

				if (!success)
				{
					throw new Exception("Export was cancelled or failed");
				}

			case "specific":
				// Save to specific path
				if (specificPath == null)
				{
					throw new Exception("Specific path required but not provided");
				}
				sys.io.File.saveContent(specificPath, yamlContent);

			default:
				throw new Exception("Unknown destination type: " + destination);
		}
		#end
	}

	function performYAMLExportToDefault()
	{
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
				// Perform actual export to default location
				try
				{
					var yamlData = buildYamlDataObject();
					var yamlDocument = generateCompleteYamlDocument(yamlData);
					saveYamlToFile(yamlDocument, "default");

					exportDialog.text = "EXPORT COMPLETED!\nSaved to: PlayerSettings/" + playerName + ".yaml";
					exportDialog.color = FlxColor.GREEN;

					trace('YAML export generated for player: ' + playerName);
					trace('YAML export content:\n' + yamlDocument);

					new FlxTimer().start(2, function(_)
					{
						FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
							onComplete: function(_)
							{
								remove(exportDialog);
								// Show custom content info after export completes
								showExportResults();
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

	function performYAMLExportWithDialog()
	{
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
				// Perform actual export with file dialog
				try
				{
					var yamlData = buildYamlDataObject();
					var yamlDocument = generateCompleteYamlDocument(yamlData);
					saveYamlToFile(yamlDocument, "dialog");

					exportDialog.text = "EXPORT COMPLETED!";
					exportDialog.color = FlxColor.GREEN;

					trace('YAML export generated for player: ' + playerName);
					trace('YAML export content:\n' + yamlDocument);

					new FlxTimer().start(1.5, function(_)
					{
						FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
							onComplete: function(_)
							{
								remove(exportDialog);
								// Show custom content info after export completes
								showExportResults();
							}
						});
					});
				}
				catch (e:Dynamic)
				{
					var errorMessage = Std.string(e);
					exportDialog.text = "EXPORT FAILED!\n" + errorMessage;
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

	function performYAMLExportToPath(forcePath:String)
	{
		// Save current settings
		saveCurrentSettings();

		// Show export animation
		FlxFlicker.flicker(exportButton, 0.5, 0.1);

		// Create animated dialog
		var exportDialog = new FlxText(Std.int(FlxG.width / 2) - 200, Std.int(FlxG.height / 2) - 50, 400, "REFRESHING YAML...", 24);
		exportDialog.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		exportDialog.borderSize = 2;
		exportDialog.alpha = 0;
		add(exportDialog);

		FlxTween.tween(exportDialog, {alpha: 1}, 0.3, {
			onComplete: function(_)
			{
				// Perform actual export to the specified path
				try
				{
					var yamlData = buildYamlDataObject();
					var yamlDocument = generateCompleteYamlDocument(yamlData);
					saveYamlToFile(yamlDocument, "specific", forcePath);

					exportDialog.text = "YAML REFRESHED!\nSaved to: " + forcePath;
					exportDialog.color = FlxColor.GREEN;

					trace('YAML refresh export generated for player: ' + playerName);
					trace('YAML refresh export content:\n' + yamlDocument);

					new FlxTimer().start(2, function(_)
					{
						FlxTween.tween(exportDialog, {alpha: 0}, 0.5, {
							onComplete: function(_)
							{
								remove(exportDialog);
								// Show custom content info (which will handle returning to APStyledEntryState)
								showExportResults();
							}
						});
					});
				}
				catch (e:Dynamic)
				{
					var errorMessage = Std.string(e);
					exportDialog.text = "REFRESH FAILED!\n" + errorMessage;
					exportDialog.color = FlxColor.RED;
					trace('Refresh export error: $e');

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

		var sanityChecks = 0;
		if (enable_sanity_locations && (stagesanity || charactersanity))
		{
			if (stagesanity)
			{
				var stageMap = scanStagesFromCharts();
				sanityChecks += stageMap.lengthTo();
			}
			if (charactersanity)
			{
				var characterMap = scanCharactersFromCharts();
				sanityChecks += characterMap.lengthTo();
			}
		}

		comment += "# Expected checks: " + totalChecks + "\n";
		if (sanityChecks > 0)
		{
			comment += "# Sanity checks: " + sanityChecks + "\n";
			comment += "# Total checks: " + (totalChecks + sanityChecks) + "\n";
		}
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

		// Add sanity data information
		if (enable_sanity_locations && (stagesanity || charactersanity))
		{
			var sanityTypes:Array<String> = [];
			if (stagesanity) sanityTypes.push("Stages");
			if (charactersanity) sanityTypes.push("Characters");

			if (sanityTypes.length > 0)
			{
				comment += "# This YAML contains sanity data for " + sanityTypes.join(" and ") + "\n";
			}
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

				// Reset victory and starting songs before applying new settings
				victorySong = null;
				startingSong = null;

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
							case "enable_sanity_locations":
								enable_sanity_locations = value == true;
							case "sanity_completion_type":
								sanity_completion_type = Std.string(value);
							case "stagesanity":
								stagesanity = value == true;
							case "charactersanity":
								charactersanity = value == true;
							case "starter_debuffs":
								starter_debuffs = value == true;
							case "perma_traps":
								perma_traps = value == true;
							case "hard_mode":
								hard_mode = value == true;
							case "enable_shop":
								enable_shop = value == true;
							case "starting_song":
								// Only set if the value is actually present in YAML and not empty
								var songValue = Std.string(value);
								startingSong = (songValue != null && songValue.trim().length > 0) ? songValue : null;
							case "victory_song":
								// Only set if the value is actually present in YAML and not empty
								var songValue = Std.string(value);
								victorySong = (songValue != null && songValue.trim().length > 0) ? songValue : null;
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
							case "ultConfusionWeight":
								ultConfusionWeight = value;
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

	var pubE:Float = 0;
	var rainbowText:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (rainbowText) {
			titleText.color = FlxColor.fromHSL(((elapsed / 2) / 300 * 360) % 360, 1.0, 0.5*1.0);
			if (glowEffect != null) glowEffect.color = FlxColor.fromHSL(((elapsed / 2.5) / 300 * 360) % 360, 1.0, 0.5*1.0);
		}

		if (forceExportPath != null)
		{
			return; // Skip input handling during forced export refresh
		}

		// Update navigation cooldown
		if (navigationCooldown > 0)
		{
			navigationCooldown -= elapsed;
		}

		// Check for completed tweens and manage refresh queue
		tweenCheckTimer += elapsed;
		if (tweenCheckTimer >= tweenCheckInterval)
		{
			tweenCheckTimer = 0;

			// Remove completed tweens from tracking
			activeTweens = activeTweens.filter(function(tween:FlxTween) {
				return !tween.finished;
			});

			// If refresh is queued and no active tweens, execute refresh
			if (refreshQueued && activeTweens.length == 0)
			{
				trace('All tweens completed - executing queued refresh');
				refreshCurrentPage();
			}
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
										case BOOLEAN(trueLabel, falseLabel, setValue):
											// Show boolean selection substate
											openBooleanSelectionPrompt(option.name, trueLabel, falseLabel, setValue);
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
								if (option.name == "???") {
									FlxG.sound.play(Paths.sound('mus-wawa'), 5);
									giveNotice();
								}
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
			includeSecrets: includeSecrets,
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
			ultConfusionWeight: ultConfusionWeight,
			svcWeight: svcWeight,
			fakeTransWeight: fakeTransWeight,
			shieldWeight: shieldWeight,
			MHPWeight: MHPWeight,
			MHPDWeight: MHPDWeight,
			exLifeWeight: exLifeWeight,
			// Sanity settings
			enable_sanity_locations: enable_sanity_locations,
			sanity_completion_type: sanity_completion_type,
			stagesanity: stagesanity,
			charactersanity: charactersanity,
			starter_debuffs: starter_debuffs,
			perma_traps: perma_traps,
			hard_mode: hard_mode,
			enable_shop: enable_shop
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
			includeSecrets = data.includeSecrets;
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
			if (Reflect.hasField(data, "ultConfusionWeight"))
				ultConfusionWeight = data.ultConfusionWeight;
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

			// Load sanity settings
			if (Reflect.hasField(data, "enable_sanity_locations"))
				enable_sanity_locations = data.enable_sanity_locations;
			if (Reflect.hasField(data, "sanity_completion_type"))
				sanity_completion_type = data.sanity_completion_type;
			if (Reflect.hasField(data, "stagesanity"))
				stagesanity = data.stagesanity;
			if (Reflect.hasField(data, "charactersanity"))
				charactersanity = data.charactersanity;

			// Load Z11's Optional Hell
			if (Reflect.hasField(data, "starter_debuffs"))
				starter_debuffs = data.starter_debuffs;
			if (Reflect.hasField(data, "perma_traps"))
				perma_traps = data.perma_traps;
			if (Reflect.hasField(data, "hard_mode"))
				hard_mode = data.hard_mode;
			if (Reflect.hasField(data, "enable_shop"))
				enable_shop = data.enable_shop;
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

	/**
	 * Test function to validate that song filtering is working correctly
	 * Call this in the console to test the filtering functionality
	 */
	public static function testSongFiltering():Void
	{
		trace("=== TESTING SONG FILTERING ===");

		// Store original settings
		var originalSettings = null;
		if (APEntryState.gameSettings != null && APEntryState.gameSettings.FNF != null) {
			var settings = APEntryState.gameSettings.FNF;
			originalSettings = {
				include_vanilla: Reflect.hasField(settings, "include_vanilla") ? settings.include_vanilla : true,
				include_erect: Reflect.hasField(settings, "include_erect") ? settings.include_erect : true,
				include_pico: Reflect.hasField(settings, "include_pico") ? settings.include_pico : true,
				include_secrets: Reflect.hasField(settings, "include_secrets") ? settings.include_secrets : true,
				mods_enabled: settings.mods_enabled
			};
		}

		// Initialize settings if they don't exist
		if (APEntryState.gameSettings == null) {
			trace("Warning: APEntryState.gameSettings is null - cannot test filtering");
			return;
		}
		if (APEntryState.gameSettings.FNF == null) {
			trace("Warning: APEntryState.gameSettings.FNF is null - cannot test filtering");
			return;
		}

		var settings = APEntryState.gameSettings.FNF;

		// Test 1: Only Vanilla songs
		trace("Test 1: Only Vanilla songs");
		settings.include_vanilla = true;
		settings.include_erect = false;
		settings.include_pico = false;
		settings.include_secrets = false;
		settings.mods_enabled = false;
		APSettingsSubState.generateSongList();
		trace("Expected: " + APInfo.baseGame.length + " songs, Generated: " + APSettingsSubState.globalSongList.length);

		// Test 2: Only Erect songs
		trace("Test 2: Only Erect songs");
		settings.include_vanilla = false;
		settings.include_erect = true;
		settings.include_pico = false;
		settings.include_secrets = false;
		settings.mods_enabled = false;
		APSettingsSubState.generateSongList();
		trace("Expected: " + APInfo.baseErect.length + " songs, Generated: " + APSettingsSubState.globalSongList.length);

		// Test 3: Only Pico songs
		trace("Test 3: Only Pico songs");
		settings.include_vanilla = false;
		settings.include_erect = false;
		settings.include_pico = true;
		settings.include_secrets = false;
		settings.mods_enabled = false;
		APSettingsSubState.generateSongList();
		trace("Expected: " + APInfo.basePico.length + " songs, Generated: " + APSettingsSubState.globalSongList.length);

		// Test 4: Only Secrets
		trace("Test 4: Only Secrets");
		settings.include_vanilla = false;
		settings.include_erect = false;
		settings.include_pico = false;
		settings.include_secrets = true;
		settings.mods_enabled = false;
		APSettingsSubState.generateSongList();
		trace("Expected: " + APInfo.secrets.length + " songs, Generated: " + APSettingsSubState.globalSongList.length);

		// Test 5: All base content
		trace("Test 5: All base content");
		settings.include_vanilla = true;
		settings.include_erect = true;
		settings.include_pico = true;
		settings.include_secrets = true;
		settings.mods_enabled = false;
		APSettingsSubState.generateSongList();
		var expectedTotal = APInfo.baseGame.length + APInfo.baseErect.length + APInfo.basePico.length + APInfo.secrets.length;
		trace("Expected: " + expectedTotal + " songs, Generated: " + APSettingsSubState.globalSongList.length);

		// Test 6: Nothing included (should have 0 base songs, but might have mods)
		trace("Test 6: Nothing included");
		settings.include_vanilla = false;
		settings.include_erect = false;
		settings.include_pico = false;
		settings.include_secrets = false;
		settings.mods_enabled = false;
		APSettingsSubState.generateSongList();
		trace("Expected: 0 base songs, Generated: " + APSettingsSubState.globalSongList.length);

		// Restore original settings
		if (originalSettings != null) {
			trace("Restoring original settings...");
			settings.include_vanilla = originalSettings.include_vanilla;
			settings.include_erect = originalSettings.include_erect;
			settings.include_pico = originalSettings.include_pico;
			settings.include_secrets = originalSettings.include_secrets;
			settings.mods_enabled = originalSettings.mods_enabled;
			APSettingsSubState.generateSongList();
		}

		trace("=== SONG FILTERING TEST COMPLETE ===");
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
			if (Reflect.hasField(data, "ultConfusionWeight"))
				state.ultConfusionWeight = data.ultConfusionWeight;
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

/**
 * A styled substate for choosing export location (default vs custom)
 */
class ExportChoiceSubstate extends MusicBeatSubstate
{
	var background:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var defaultButton:FlxSprite;
	var customButton:FlxSprite;
	var defaultButtonText:FlxText;
	var customButtonText:FlxText;
	var defaultDescText:FlxText;
	var customDescText:FlxText;
	var cancelButton:FlxSprite;
	var cancelButtonText:FlxText;

	var onDefaultChoice:Void->Void;
	var onCustomChoice:Void->Void;
	var isAnimating:Bool = false;
	var isClosing:Bool = false;

	var dCamera:FlxCamera;

	public function new(onDefault:Void->Void, onCustom:Void->Void)
	{
		super();
		onDefaultChoice = onDefault;
		onCustomChoice = onCustom;

		setupCamera();
		setupBackground();
		setupPanel();
		animateIn();
	}

	function setupCamera():Void
	{
		dCamera = new FlxCamera();
		dCamera.bgColor.alpha = 0;
		FlxG.cameras.add(dCamera, false);
	}

	function setupBackground()
	{
		background = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 160));
		background.cameras = [dCamera];
		add(background);
	}

	function setupPanel()
	{
		var panelWidth = 500;
		var panelHeight = 400;

		// Main panel with gradient
		panel = FlxGradient.createGradientFlxSprite(panelWidth, panelHeight,
			[FlxColor.fromRGB(30, 30, 50), FlxColor.fromRGB(20, 20, 40)], 1, 90);
		panel.x = (FlxG.width - panelWidth) / 2;
		panel.y = (FlxG.height - panelHeight) / 2;
		panel.cameras = [dCamera];
		add(panel);

		// Title
		titleText = new FlxText(panel.x + 20, panel.y + 20, panelWidth - 40, "Export YAML Configuration", 24);
		titleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.cameras = [dCamera];
		add(titleText);

		// Description
		descriptionText = new FlxText(panel.x + 20, panel.y + 70, panelWidth - 40, "Choose where to save your YAML configuration:", 16);
		descriptionText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		descriptionText.borderSize = 1;
		descriptionText.cameras = [dCamera];
		add(descriptionText);

		// Default location button
		defaultButton = new FlxSprite(panel.x + 40, panel.y + 120);
		defaultButton.makeGraphic(Std.int(panelWidth - 80), 80, FlxColor.fromRGB(60, 100, 60));
		defaultButton.cameras = [dCamera];
		add(defaultButton);

		defaultButtonText = new FlxText(defaultButton.x + 10, defaultButton.y + 10, defaultButton.width - 20, "Default Location", 18);
		defaultButtonText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		defaultButtonText.borderSize = 1;
		defaultButtonText.cameras = [dCamera];
		add(defaultButtonText);

		defaultDescText = new FlxText(defaultButton.x + 10, defaultButton.y + 35, defaultButton.width - 20, "Save to PlayerSettings folder\n(Quick and automatic)", 12);
		defaultDescText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.LIME, CENTER, OUTLINE, FlxColor.BLACK);
		defaultDescText.borderSize = 1;
		defaultDescText.cameras = [dCamera];
		add(defaultDescText);

		// Custom location button
		customButton = new FlxSprite(panel.x + 40, panel.y + 220);
		customButton.makeGraphic(Std.int(panelWidth - 80), 80, FlxColor.fromRGB(60, 60, 100));
		customButton.cameras = [dCamera];
		add(customButton);

		customButtonText = new FlxText(customButton.x + 10, customButton.y + 10, customButton.width - 20, "Choose Location", 18);
		customButtonText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		customButtonText.borderSize = 1;
		customButtonText.cameras = [dCamera];
		add(customButtonText);

		customDescText = new FlxText(customButton.x + 10, customButton.y + 35, customButton.width - 20, "Open file dialog to choose\ncustom save location", 12);
		customDescText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.CYAN, CENTER, OUTLINE, FlxColor.BLACK);
		customDescText.borderSize = 1;
		customDescText.cameras = [dCamera];
		add(customDescText);

		// Cancel button
		cancelButton = new FlxSprite(panel.x + panelWidth - 80, panel.y + panelHeight - 50);
		cancelButton.makeGraphic(60, 30, FlxColor.fromRGB(100, 60, 60));
		cancelButton.cameras = [dCamera];
		add(cancelButton);

		cancelButtonText = new FlxText(cancelButton.x, cancelButton.y + 5, cancelButton.width, "CANCEL", 12);
		cancelButtonText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		cancelButtonText.borderSize = 1;
		cancelButtonText.cameras = [dCamera];
		add(cancelButtonText);
	}

	function animateIn()
	{
		isAnimating = true;

		// Hide all elements initially
		var allElements = [panel, titleText, descriptionText, defaultButton, customButton,
			defaultButtonText, customButtonText, defaultDescText, customDescText, cancelButton, cancelButtonText];

		for (element in allElements)
		{
			if (element != null)
			{
				element.alpha = 0;
			}
		}

		// Scale panel for animation
		panel.scale.set(0.5, 0.5);

		// Animate panel
		FlxTween.tween(panel, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.4, {
			ease: FlxEase.backOut
		});

		// Animate title
		FlxTween.tween(titleText, {alpha: 1}, 0.5, {
			ease: FlxEase.sineOut,
			startDelay: 0.1
		});

		// Animate description
		FlxTween.tween(descriptionText, {alpha: 1}, 0.5, {
			ease: FlxEase.sineOut,
			startDelay: 0.2
		});

		// Animate buttons
		var buttonElements = [defaultButton, defaultButtonText, defaultDescText];
		for (i in 0...buttonElements.length)
		{
			FlxTween.tween(buttonElements[i], {alpha: 1}, 0.3, {
				ease: FlxEase.sineOut,
				startDelay: 0.3 + (i * 0.05)
			});
		}

		var customElements = [customButton, customButtonText, customDescText];
		for (i in 0...customElements.length)
		{
			FlxTween.tween(customElements[i], {alpha: 1}, 0.3, {
				ease: FlxEase.sineOut,
				startDelay: 0.45 + (i * 0.05)
			});
		}

		// Animate cancel button
		FlxTween.tween(cancelButton, {alpha: 1}, 0.3, {
			ease: FlxEase.sineOut,
			startDelay: 0.6
		});

		FlxTween.tween(cancelButtonText, {alpha: 1}, 0.3, {
			ease: FlxEase.sineOut,
			startDelay: 0.6,
			onComplete: function(_)
			{
				isAnimating = false;
			}
		});
	}

	function animateOut(onComplete:Void->Void)
	{
		if (isAnimating)
			return;
		isAnimating = true;

		FlxTween.tween(panel, {"scale.x": 0.5, "scale.y": 0.5, alpha: 0}, 0.3, {
			ease: FlxEase.backIn,
			onComplete: function(_)
			{
				onComplete();
			}
		});

		FlxTween.tween(background, {alpha: 0}, 0.3, {ease: FlxEase.sineIn});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Don't handle input while animating
		if (isAnimating)
			return;

		// Close on escape
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closePanel();
			return;
		}

		// Handle button interactions
		handleButtonInteraction(defaultButton, defaultButtonText, function()
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			closePanel(function()
			{
				if (onDefaultChoice != null)
					onDefaultChoice();
			});
		});

		handleButtonInteraction(customButton, customButtonText, function()
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			closePanel(function()
			{
				if (onCustomChoice != null)
					onCustomChoice();
			});
		});

		handleButtonInteraction(cancelButton, cancelButtonText, function()
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closePanel();
		});

		// Click outside to cancel
		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(panel))
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			closePanel();
		}
	}

	function handleButtonInteraction(button:FlxSprite, buttonText:FlxText, onClick:Void->Void)
	{
		if (FlxG.mouse.overlaps(button))
		{
			button.color = FlxColor.WHITE;
			buttonText.color = FlxColor.BLACK;
			if (FlxG.mouse.justPressed)
			{
				onClick();
			}
		}
		else
		{
			button.color = FlxColor.WHITE;
			buttonText.color = FlxColor.WHITE;
		}
	}

	function closePanel(?onComplete:Void->Void)
	{
		if (isClosing)
			return;
		isClosing = true;

		animateOut(function()
		{
			if (onComplete != null)
				onComplete();
			forceClose();
		});
	}

	function forceClose()
	{
		super.close();
	}

	override function destroy()
	{
		if (dCamera != null)
		{
			FlxG.cameras.remove(dCamera);
			dCamera.destroy();
			dCamera = null;
		}
		super.destroy();
	}
}
