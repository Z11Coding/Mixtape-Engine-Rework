package states.freeplay;

import backend.MusicBeatSubstate;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;

#if ARCHIPELAGO_ALLOWED
import archipelago.APEntryState;
import archipelago.APGameState;
import archipelago.APInfo;
import options.GameplayChangersSubstate;
#end

/**
 * HaxeUI-based options substate for VSlice Freeplay
 * This properly integrates HaxeUI components with Flixel's substate system
 */
class HaxeUIOptionsSubstate extends MusicBeatSubstate
{
	private var optionsMenu:VBox;
	private var parentState:Dynamic; // Reference to the parent VSliceFreeplayState

	public function new(parent:Dynamic)
	{
		this.parentState = parent;
		super();
	}

	override public function create():Void
	{
		super.create();

		// Initialize HaxeUI if needed
		if (!Toolkit.initialized) {
			Toolkit.init();
		}

		// Set up the camera and background
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		// Semi-transparent background
		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0x80000000);
		add(bg);

		createOptionsMenu();
	}

	private function createOptionsMenu():Void
	{
		// Create the main container
		optionsMenu = new VBox();
		optionsMenu.percentWidth = 25;
		optionsMenu.percentHeight = 80;
		optionsMenu.x = FlxG.width * 0.73;
		optionsMenu.y = FlxG.height * 0.1;
		optionsMenu.spacing = 10;

		// Menu title
		var menuTitle = new Label();

		#if ARCHIPELAGO_ALLOWED
		if (APEntryState.inArchipelagoMode)
		{
			menuTitle.text = "Archipelago Options";

			// Hinting section for AP mode
			var hintingSection = new VBox();
			hintingSection.spacing = 5;

			var hintingTitle = new Label();
			hintingTitle.text = "Hinting";
			hintingTitle.styleString = "font-size: 14px; font-weight: bold;";
			hintingSection.addComponent(hintingTitle);

			// Sanity section (character/stage hinting)
			if (APEntryState.apGame?.sanitySettings?.sanity_types != null)
			{
				var sanitySection = new VBox();
				sanitySection.spacing = 3;

				var sanityTitle = new Label();
				sanityTitle.text = "Sanity Hinting";
				sanityTitle.styleString = "font-size: 12px; font-weight: bold;";
				sanitySection.addComponent(sanityTitle);

				// Character hinting
				if (APEntryState.apGame.sanitySettings.sanity_types.contains("characters"))
				{
					var charHintButton = new Button();
					updateCharacterHintButton(charHintButton); // Will update text and cost
					charHintButton.onClick = function(_) {
						hintMissingCharacters();
					};
					sanitySection.addComponent(charHintButton);
				}

				// Stage hinting
				if (APEntryState.apGame.sanitySettings.sanity_types.contains("stages"))
				{
					var stageHintButton = new Button();
					updateStageHintButton(stageHintButton); // Will update text and cost
					stageHintButton.onClick = function(_) {
						hintMissingStages();
					};
					sanitySection.addComponent(stageHintButton);
				}

				hintingSection.addComponent(sanitySection);
			}

			optionsMenu.addComponent(hintingSection);
		}
		else
		#end
		{
			menuTitle.text = "Gameplay Options";

			// Regular gameplay changers button
			var gameplayButton = new Button();
			gameplayButton.text = "Gameplay Changers";
			gameplayButton.onClick = function(_) {
				// Close this substate and open GameplayChangers
				close();
				if (parentState != null && Reflect.hasField(parentState, "openSubState"))
				{
					Reflect.callMethod(parentState, Reflect.field(parentState, "openSubState"), [new GameplayChangersSubstate()]);
				}
			};
			optionsMenu.addComponent(gameplayButton);
		}

		optionsMenu.addComponent(menuTitle);

		// Close button
		var closeButton = new Button();
		closeButton.text = "Close";
		closeButton.onClick = function(_) {
			close();
		};
		optionsMenu.addComponent(closeButton);

		// Add the HaxeUI component to the screen so it appears in this substate
		haxe.ui.core.Screen.instance.addComponent(optionsMenu);

		// Ensure the component appears on top
		haxe.ui.core.Screen.instance.setComponentIndex(optionsMenu, haxe.ui.core.Screen.instance.numComponents - 1);
	}

	#if ARCHIPELAGO_ALLOWED
	/**
	 * Update character hint button text with cost estimation
	 */
	private function updateCharacterHintButton(button:Button):Void
	{
		var missingCharacters = getMissingCharactersForCurrentSong();
		var estimatedCost = missingCharacters.length * APInfo.hintCost;
		button.text = "Hint Characters (" + missingCharacters.length + " × " + APInfo.hintCost + " = " + estimatedCost + " pts)";
	}

	/**
	 * Update stage hint button text with cost estimation
	 */
	private function updateStageHintButton(button:Button):Void
	{
		var missingStages = getMissingStagesForCurrentSong();
		var estimatedCost = missingStages.length * APInfo.hintCost;
		button.text = "Hint Stages (" + missingStages.length + " × " + APInfo.hintCost + " = " + estimatedCost + " pts)";
	}

	/**
	 * Get missing characters for the current song
	 */
	private function getMissingCharactersForCurrentSong():Array<String>
	{
		if (parentState == null || !Reflect.hasField(parentState, "currentFilteredSongs") || !Reflect.hasField(parentState, "curSelected"))
			return [];

		var currentFilteredSongs = Reflect.field(parentState, "currentFilteredSongs");
		var curSelected = Reflect.field(parentState, "curSelected");

		if (currentFilteredSongs == null || curSelected < 0 || curSelected >= currentFilteredSongs.length)
			return [];

		var currentSong = currentFilteredSongs[curSelected];
		if (currentSong?.songData?.levelId == null)
			return [];

		var missingCharacters:Array<String> = [];
		var songId = currentSong.songData.levelId;

		try {
			var song = backend.Song.loadFromJson(songId, songId);
			if (song?.player1 != null && !APEntryState.ap.getIsReceivedItem("character-" + song.player1))
				missingCharacters.push("character-" + song.player1);
			if (song?.player2 != null && !APEntryState.ap.getIsReceivedItem("character-" + song.player2))
				missingCharacters.push("character-" + song.player2);
			if (song?.gfVersion != null && !APEntryState.ap.getIsReceivedItem("character-" + song.gfVersion))
				missingCharacters.push("character-" + song.gfVersion);
		} catch (e:Dynamic) {
			trace("Error loading song for character hints: " + e);
		}

		return missingCharacters;
	}

	/**
	 * Get missing stages for the current song
	 */
	private function getMissingStagesForCurrentSong():Array<String>
	{
		if (parentState == null || !Reflect.hasField(parentState, "currentFilteredSongs") || !Reflect.hasField(parentState, "curSelected"))
			return [];

		var currentFilteredSongs = Reflect.field(parentState, "currentFilteredSongs");
		var curSelected = Reflect.field(parentState, "curSelected");

		if (currentFilteredSongs == null || curSelected < 0 || curSelected >= currentFilteredSongs.length)
			return [];

		var currentSong = currentFilteredSongs[curSelected];
		if (currentSong?.songData?.levelId == null)
			return [];

		var missingStages:Array<String> = [];
		var songId = currentSong.songData.levelId;

		try {
			var song = backend.Song.loadFromJson(songId, songId);
			if (song?.stage != null && !APEntryState.ap.getIsReceivedItem("stage-" + song.stage))
				missingStages.push("stage-" + song.stage);
		} catch (e:Dynamic) {
			trace("Error loading song for stage hints: " + e);
		}

		return missingStages;
	}

	/**
	 * Hint missing characters
	 */
	private function hintMissingCharacters():Void
	{
		var missingCharacters = getMissingCharactersForCurrentSong();
		for (character in missingCharacters)
		{
			if (APInfo.hintPoints >= APInfo.hintCost)
			{
				APEntryState.ap.Say("!hint " + character);
				APInfo.hintPoints -= APInfo.hintCost;
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return; // Not enough points
			}
		}
		FlxG.sound.play(Paths.sound('confirmMenu'));
	}

	/**
	 * Hint missing stages
	 */
	private function hintMissingStages():Void
	{
		var missingStages = getMissingStagesForCurrentSong();
		for (stage in missingStages)
		{
			if (APInfo.hintPoints >= APInfo.hintCost)
			{
				APEntryState.ap.Say("!hint " + stage);
				APInfo.hintPoints -= APInfo.hintCost;
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return; // Not enough points
			}
		}
		FlxG.sound.play(Paths.sound('confirmMenu'));
	}
	#end

	override public function close():Void
	{
		// Clean up HaxeUI component
		if (optionsMenu != null)
		{
			haxe.ui.core.Screen.instance.removeComponent(optionsMenu);
			optionsMenu = null;
		}

		super.close();
	}

	override public function destroy():Void
	{
		// Ensure cleanup
		if (optionsMenu != null)
		{
			haxe.ui.core.Screen.instance.removeComponent(optionsMenu);
			optionsMenu = null;
		}

		parentState = null;
		super.destroy();
	}
}
