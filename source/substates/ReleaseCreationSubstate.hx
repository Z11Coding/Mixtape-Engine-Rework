package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.group.FlxGroup.FlxTypedGroup;
import backend.ui.*;
import flixel.addons.display.FlxBackdrop;
import openfl.display.BlendMode;
import backend.GitHubAPI.GitHubCreateRelease;

class ReleaseCreationSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var gradientBar:FlxSprite;
	var checker:FlxBackdrop;
	var box:PsychUIBox;
	
	var titleText:FlxText;
	var tagInput:PsychUIInputText;
	var nameInput:PsychUIInputText;
	var descriptionInput:PsychUIInputText;
	var preReleaseCheck:PsychUICheckBox;
	var draftCheck:PsychUICheckBox;
	var targetBranchInput:PsychUIInputText;
	
	var createButton:PsychUIButton;
	var cancelButton:PsychUIButton;
	
	var onComplete:ReleaseCreationData->Void;
	var onCancel:Void->Void;
	
	public function new(onComplete:ReleaseCreationData->Void, onCancel:Void->Void) {
		super();
		this.onComplete = onComplete;
		this.onCancel = onCancel;
	}
	
	override function create() {
		super.create();
		
		createBackground();
		createUI();
	}
	
	private function createBackground():Void {
		bg = new FlxSprite(-80).loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.color = 0xff1a0b2e;
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.8;
		add(bg);

		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55AE59E4, 0xAAFFA319], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		gradientBar.alpha = 0.7;
		add(gradientBar);

		checker = new FlxBackdrop(Paths.image('loading_screen/bgpattern'), XY, Std.int(0.2), Std.int(0.2));
		checker.blend = BlendMode.LAYER;
		checker.alpha = 0.3;
		add(checker);
	}
	
	private function createUI():Void {
		box = new PsychUIBox(FlxG.width / 2 - 300, FlxG.height / 2 - 250, 600, 500);
		add(box);
		
		titleText = new FlxText(0, box.y + 20, box.width, "Create GitHub Release", 24);
		titleText.setFormat(Paths.font('funkin.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.x = box.x;
		add(titleText);
		
		var yPos = titleText.y + 50;
		var spacing = 60;
		
		// Tag Name (Version)
		var tagLabel = new FlxText(box.x + 20, yPos, 100, "Tag:", 16);
		tagLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(tagLabel);
		
		tagInput = new PsychUIInputText(box.x + 120, yPos - 5, 200, "v1.0.0", 16);
		add(tagInput);
		
		yPos += spacing;
		
		// Release Name
		var nameLabel = new FlxText(box.x + 20, yPos, 100, "Title:", 16);
		nameLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(nameLabel);
		
		nameInput = new PsychUIInputText(box.x + 120, yPos - 5, 450, "Release Title", 16);
		add(nameInput);
		
		yPos += spacing;
		
		// Target Branch
		var branchLabel = new FlxText(box.x + 20, yPos, 100, "Branch:", 16);
		branchLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(branchLabel);
		
		targetBranchInput = new PsychUIInputText(box.x + 120, yPos - 5, 200, "main", 16);
		add(targetBranchInput);
		
		yPos += spacing;
		
		// Description
		var descLabel = new FlxText(box.x + 20, yPos, 100, "Description:", 16);
		descLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(descLabel);
		
		descriptionInput = new PsychUIInputText(box.x + 20, yPos + 25, 550, "Release description...", 14);
		descriptionInput.height = 80;
		add(descriptionInput);
		
		yPos += 120;
		
		// Checkboxes
		preReleaseCheck = new PsychUICheckBox(box.x + 20, yPos, "Pre-release", 100);
		preReleaseCheck.checked = false;
		add(preReleaseCheck);
		
		draftCheck = new PsychUICheckBox(box.x + 200, yPos, "Draft", 100);
		draftCheck.checked = false;
		add(draftCheck);
		
		yPos += 50;
		
		// Buttons
		createButton = new PsychUIButton(box.x + 100, yPos, "Create Release", createRelease, 150, 30);
		createButton.color = FlxColor.GREEN;
		add(createButton);
		
		cancelButton = new PsychUIButton(box.x + 350, yPos, "Cancel", function() {
			close();
			onCancel();
		}, 150, 30);
		cancelButton.color = FlxColor.RED;
		add(cancelButton);
	}
	
	private function createRelease():Void {
		if (tagInput.text.trim() == "" || nameInput.text.trim() == "") {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		
		var releaseData:ReleaseCreationData = {
			tagName: tagInput.text.trim(),
			title: nameInput.text.trim(),
			description: descriptionInput.text.trim(),
			isDraft: draftCheck.checked,
			isPrerelease: preReleaseCheck.checked
		};
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		close();
		onComplete(releaseData);
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		
		checker.x -= 0.45 / (ClientPrefs.data.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.data.framerate / 60);
		
		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			onCancel();
		}
	}
}

typedef ReleaseCreationData = {
	var tagName:String;
	var title:String;
	var description:String;
	var isDraft:Bool;
	var isPrerelease:Bool;
}