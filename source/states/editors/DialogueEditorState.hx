package states.editors;

import cutscenes.DialogueStyle;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileFilter;
import haxe.Json;
import objects.TypedAlphabet;

import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueCharacter;
import states.editors.content.Prompt;

class DialogueEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var character:DialogueCharacter;
	var box:FlxSprite;
	var style:DialogueStyle;
	var daText:FlxSprite;

	var selectedText:FlxText;
	var animText:FlxText;

	var defaultLine:DialogueLine;
	var dialogueFile:DialogueFile = null;
	var unsavedProgress:Bool = false;

	override function create() {
		persistentUpdate = persistentDraw = true;
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.5);

		defaultLine = {
			portrait: DialogueCharacter.DEFAULT_CHARACTER,
			expression: 'talk',
			text: DEFAULT_TEXT,
			boxState: DEFAULT_BUBBLETYPE,
			speed: 0.05,
			sound: ''
		};

		dialogueFile = {
			dialogue: [
				copyDefaultLine()
			],
			style:""
		};
		switch(dialogueFile.style){
			case "pixel":{
				this.style = new PixelDialogueStyle();
			}
			default:{
				this.style = new PsychDialogueStyle();
			}
		}
		
		character = new DialogueCharacter();
		character.scrollFactor.set();
		add(character);

		box = style.makeDialogueBox();
		box.visible = true;
		add(box);

		addEditorBox();
		FlxG.mouse.visible = true;

		var lineTxt:String = "Press O to remove the current dialogue line, Press P to add another line after the current one.";
		var addLineText:FlxText = new FlxText(10, 10, FlxG.width - 20, lineTxt, 8);
		addLineText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		addLineText.scrollFactor.set();
		add(addLineText);

		selectedText = new FlxText(10, 32, FlxG.width - 20, '', 8);
		selectedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		selectedText.scrollFactor.set();
		add(selectedText);

		animText = new FlxText(10, 62, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);
		
		daText = style.initText();
		style.prepareLine(DEFAULT_TEXT,0.5,"dialogue");
		add(daText);
		changeText();
		super.create();

		MusicManager.playEditorMusic(ClientPrefs.data.editorMusVol);
	}

	var UI_box:PsychUIBox;
	function addEditorBox()
	{
		UI_box = new PsychUIBox(FlxG.width - 260, 10, 250, 210, ['Dialogue Line']);
		UI_box.scrollFactor.set();
		addDialogueLineUI();
		add(UI_box);
	}

	var characterInputText:PsychUIInputText;
	var lineInputText:PsychUIInputText;
	var angryCheckbox:PsychUICheckBox;
	var usePixel:PsychUICheckBox;
	var speedStepper:PsychUINumericStepper;
	var soundInputText:PsychUIInputText;
	function addDialogueLineUI() {
		var tab_group = UI_box.getTab('Dialogue Line').menu;

		characterInputText = new PsychUIInputText(10, 20, 80, DialogueCharacter.DEFAULT_CHARACTER, 8);
		speedStepper = new PsychUINumericStepper(10, characterInputText.y + 40, 0.005, 0.05, 0, 0.5, 3);

		angryCheckbox = new PsychUICheckBox(speedStepper.x + 120, speedStepper.y, "Angry Textbox", 200);
		angryCheckbox.onClick = function()
		{
			updateTextBox();
			dialogueFile.dialogue[curSelected].boxState = (angryCheckbox.checked ? 'angry' : 'normal');
		};
		usePixel = new PsychUICheckBox(characterInputText.x + 120, characterInputText.y, "Use pixel", 200);
		usePixel.onClick = function()
			{
				dialogueFile.style = usePixel.checked ? "pixel" : "";
				makeTextBox();
				updateTextBox();
				style.set_text(lineInputText.text);
				style.startLine();
			};
		soundInputText = new PsychUIInputText(10, speedStepper.y + 40, 150, '', 8);
		lineInputText = new PsychUIInputText(10, soundInputText.y + 35, 200, DEFAULT_TEXT, 8);
		lineInputText.onPressEnter = function(e)
		{
			if(e.shiftKey)
			{
				lineInputText.text += '\n';
				lineInputText.caretIndex++;
			}
			else PsychUIInputText.focusOn = null;
		};

		var loadButton:PsychUIButton = new PsychUIButton(20, lineInputText.y + 25, "Load Dialogue", function() {
			loadDialogue();
		});
		
		var saveButton:PsychUIButton = new PsychUIButton(loadButton.x + 120, loadButton.y, "Save Dialogue", function() {
			saveDialogue();
		});

		tab_group.add(new FlxText(10, speedStepper.y - 18, 0, 'Interval/Speed (ms):'));
		tab_group.add(new FlxText(10, characterInputText.y - 18, 0, 'Character:'));
		tab_group.add(new FlxText(10, soundInputText.y - 18, 0, 'Sound file name:'));
		tab_group.add(new FlxText(10, lineInputText.y - 18, 0, 'Text:'));
		tab_group.add(characterInputText);
		tab_group.add(angryCheckbox);
		tab_group.add(usePixel);
		tab_group.add(speedStepper);
		tab_group.add(soundInputText);
		tab_group.add(lineInputText);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
	}

	function copyDefaultLine():DialogueLine {
		var copyLine:DialogueLine = {
			portrait: defaultLine.portrait,
			expression: defaultLine.expression,
			text: defaultLine.text,
			boxState: defaultLine.boxState,
			speed: defaultLine.speed,
			sound: ''
		};
		return copyLine;
	}
	function makeTextBox(){
		switch(dialogueFile.style){
			case "pixel":{
				this.style = new PixelDialogueStyle();
			}
			default:{
				this.style = new PsychDialogueStyle();
			}
		}
		box = cast replace(box,style.makeDialogueBox());
		daText = cast replace(daText,style.initText());
		box.visible = true;
	}
	function updateTextBox() {
		var isAngry:Bool = angryCheckbox.checked;
		var lePos = switch (character.jsonFile.dialogue_pos){
			case "left": LEFT;
			case "right": RIGHT;
			case "center": CENTER;
			default: RIGHT;
		};
		style.playBoxAnim(lePos,IDLE,isAngry ? 'angry' : 'normal');
		//style.playBoxAnim(style.last_position,CLOSE_FINISH,lastBoxType);

	}

	function reloadCharacter() {
		character.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
		character.jsonFile = character.jsonFile;
		character.reloadAnimations();
		character.setGraphicSize(Std.int(character.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
		character.updateHitbox();
		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		switch(character.jsonFile.dialogue_pos) {
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;
			
			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		character.x += character.jsonFile.position[0];
		character.y += character.jsonFile.position[1];
		character.playAnim(); //Plays random animation
		characterAnimSpeed();

		if(character.animation.curAnim != null && character.jsonFile.animations != null) {
			animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
		} else {
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
	}

	private static var DEFAULT_TEXT:String = "coolswag";
	private static var DEFAULT_SPEED:Float = 0.05;
	private static var DEFAULT_BUBBLETYPE:String = "normal";
	function reloadText(skipDialogue:Bool) {
		var textToType:String = lineInputText.text;
		if(textToType == null || textToType.length < 1) textToType = ' ';

		style.set_text(textToType);
		style.startLine();

		if(skipDialogue) 
			style.finishLine();
		else if(style.get_delay() > 0)
		{
			if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
				character.playAnim(character.jsonFile.animations[curAnim].anim);
			}
			characterAnimSpeed();
		}

		daText.y = style.DEFAULT_TEXT_Y;
		if(style.rowCount() > 2) daText.y -= style.LONG_TEXT_ADD;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		var rpcText:String = lineInputText.text;
		if(rpcText == null || rpcText.length < 1) rpcText = '(Empty)';
		if(rpcText.length < 3) rpcText += '   '; //Fixes a bug on RPC that triggers an error when the text is too short
		DiscordClient.changePresence("Dialogue Editor", rpcText);
		#end
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText)) {
			if (sender == characterInputText)
			{
				character.reloadCharacterJson(characterInputText.text);
				reloadCharacter();
				if(character.jsonFile.animations.length > 0) {
					curAnim = 0;
					if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
						character.playAnim(character.jsonFile.animations[curAnim].anim, style.isLineFinished());
						animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
					} else {
						animText.text = 'ERROR! NO ANIMATIONS FOUND';
					}
					characterAnimSpeed();
				}
				dialogueFile.dialogue[curSelected].portrait = characterInputText.text;
				reloadText(false);
				updateTextBox();
			}
			else if(sender == lineInputText)
			{
				dialogueFile.dialogue[curSelected].text = lineInputText.text;

				var txt = lineInputText.text;
				if(txt == null) txt = '';
				style.set_text(txt);
				reloadText(true);
			}
			else if(sender == soundInputText)
			{
				style.finishLine();
				dialogueFile.dialogue[curSelected].sound = soundInputText.text;
				var snd = soundInputText.text;
				if(snd == null) snd = '';
				style.set_sound(snd);
			}
			unsavedProgress = true;
		} else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender == speedStepper)) {
			dialogueFile.dialogue[curSelected].speed = speedStepper.value;
			if(Math.isNaN(dialogueFile.dialogue[curSelected].speed) || dialogueFile.dialogue[curSelected].speed == null || dialogueFile.dialogue[curSelected].speed < 0.001) {
				dialogueFile.dialogue[curSelected].speed = 0.0;
			}
			style.set_delay(dialogueFile.dialogue[curSelected].speed);
			reloadText(false);
			unsavedProgress = true;
		}
	}

	var curSelected:Int = 0;
	var curAnim:Int = 0;
	var transitioning:Bool = false;
	override function update(elapsed:Float) {
		if(transitioning) {
			super.update(elapsed);
			return;
		}

		if(character.animation.curAnim != null) {
			if(style.isLineFinished()) {
				if(character.animationIsLoop() && character.animation.curAnim.finished) {
					character.playAnim(character.animation.curAnim.name, true);
				}
			} else if(character.animation.curAnim.finished) {
				character.animation.curAnim.restart();
			}
		}

		if(PsychUIInputText.focusOn == null)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.SPACE) {
				reloadText(false);
			}
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new states.editors.MasterEditorMenu());
					MusicManager.playMenuMusic(1);
					transitioning = true;
				}
				else openSubState(new ExitConfirmationPrompt(function() transitioning = true));
				return;
			}
			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];
			var controlText:Array<Bool> = [FlxG.keys.justPressed.D, FlxG.keys.justPressed.A];
			for (i in 0...controlAnim.length) {
				if(controlAnim[i] && character.jsonFile.animations.length > 0) {
					curAnim -= negaMult[i];
					if(curAnim < 0) curAnim = character.jsonFile.animations.length - 1;
					else if(curAnim >= character.jsonFile.animations.length) curAnim = 0;

					var animToPlay:String = character.jsonFile.animations[curAnim].anim;
					if(character.dialogueAnimations.exists(animToPlay)) {
						character.playAnim(animToPlay, style.isLineFinished());
						dialogueFile.dialogue[curSelected].expression = animToPlay;
					}
					animText.text = 'Animation: ' + animToPlay + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}
				if(controlText[i]) {
					changeText(negaMult[i]);
				}
			}

			if(FlxG.keys.justPressed.O) {
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if(dialogueFile.dialogue.length < 1) //You deleted everything, dumbo!
				{
					dialogueFile.dialogue = [
						copyDefaultLine()
					];
				}
				changeText();
			} else if(FlxG.keys.justPressed.P) {
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
			}
		}
		else ClientPrefs.toggleVolumeKeys(false);
		super.update(elapsed);
	}

	function changeText(add:Int = 0) {
		curSelected = FlxMath.wrap(curSelected + add, 0, dialogueFile.dialogue.length - 1);

		var curDialogue:DialogueLine = dialogueFile.dialogue[curSelected];
		characterInputText.text = curDialogue.portrait;
		lineInputText.text = curDialogue.text;
		angryCheckbox.checked = (curDialogue.boxState == 'angry');
		speedStepper.value = curDialogue.speed;

		if (curDialogue.sound == null) curDialogue.sound = '';
		soundInputText.text = curDialogue.sound;

		var snd = soundInputText.text;
		if(snd != null && snd.trim() == '') snd = 'dialogue';
		style.set_sound(snd);
		style.set_delay(speedStepper.value);

		curAnim = 0;
		character.reloadCharacterJson(characterInputText.text);
		reloadCharacter();
		reloadText(false);
		updateTextBox();

		if(character.jsonFile.animations.length > 0)
		{
			for (num => animData in character.jsonFile.animations)
			{
				if(animData != null && animData.anim == curDialogue.expression)
				{
					curAnim = num;
					break;
				}
			}
			var selectedAnim:String = character.jsonFile.animations[curAnim].anim;
			character.playAnim(selectedAnim, style.isLineFinished());
			animText.text = 'Animation: $selectedAnim (${curAnim + 1} / ${character.jsonFile.animations.length} ) - Press W or S to scroll';
		}
		else animText.text = 'ERROR! NO ANIMATIONS FOUND';
		characterAnimSpeed();

		selectedText.text = 'Line: (' + (curSelected + 1) + ' / ' + dialogueFile.dialogue.length + ') - Press A or D to scroll';
	}

	function characterAnimSpeed() {
		if(character.animation.curAnim != null) {
			var speed:Float = speedStepper.value;
			var rate:Float = 24 - (((speed - 0.05) / 5) * 480);
			if(rate < 12) rate = 12;
			else if(rate > 48) rate = 48;
			character.animation.curAnim.frameRate = rate;
		}
	}

	function loadDialogue() {
		var jsonFile = ImprovedFileHandling.openFile("Select the dialogue you wish to edit:", [{ext: "json", desc: "JSON File"}]);
		var jsonPath = ImprovedFileHandling.lastPath;
		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(jsonPath != null) fullPath = jsonPath;

		if(jsonFile != null) {
			var rawJson:String = File.getContent(jsonFile);
			if(rawJson != null) {
				var loadedDialog:DialogueFile = cast Json.parse(jsonFile);
				if(loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0) //Make sure it's really a dialogue file
				{
					dialogueFile = loadedDialog;
					makeTextBox();
					changeText();
					return;
				}
			}
		}
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	function saveDialogue() {
		var data:String = haxe.Json.stringify(dialogueFile, "\t");
		if (data.length > 0)
			ImprovedFileHandling.saveOperation("dialogue.json", {ext: "json", desc: "JSON File"}, Text, data);
	}
}