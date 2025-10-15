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
import sys.FileSystem;

typedef PackagingOptions = {
	var excludeMods:Bool;
	var excludePlayerSettings:Bool;
	var excludeSave:Bool;
	var excludeTemp:Bool;
	var excludeLogs:Bool;
	var excludeSource:Bool;
	var platform:String;
	var compressionLevel:Int;
	var outputPath:String;
}

class PackagingOptionsSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var gradientBar:FlxSprite;
	var checker:FlxBackdrop;
	var box:PsychUIBox;
	
	var titleText:FlxText;
	var platformDropdown:PsychUIDropDownMenu;
	var compressionSlider:PsychUISlider;
	var compressionLabel:FlxText;
	
	var excludeModsCheck:PsychUICheckBox;
	var excludePlayerSettingsCheck:PsychUICheckBox;
	var excludeSaveCheck:PsychUICheckBox;
	var excludeTempCheck:PsychUICheckBox;
	var excludeLogsCheck:PsychUICheckBox;
	var excludeSourceCheck:PsychUICheckBox;
	
	var outputPathInput:PsychUIInputText;
	var browseButton:PsychUIButton;
	
	var sizeEstimateText:FlxText;
	var packageButton:PsychUIButton;
	var cancelButton:PsychUIButton;
	
	var onComplete:PackagingOptions->Void;
	var onCancel:Void->Void;
	
	public function new(onComplete:PackagingOptions->Void, onCancel:Void->Void) {
		super();
		this.onComplete = onComplete;
		this.onCancel = onCancel;
	}
	
	override function create() {
		super.create();
		
		createBackground();
		createUI();
		updateSizeEstimate();
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
		
		titleText = new FlxText(0, box.y + 20, box.width, "Package Release", 24);
		titleText.setFormat(Paths.font('funkin.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		titleText.x = box.x;
		add(titleText);
		
		var yPos = titleText.y + 50;
		var spacing = 45;
		
		// Platform Selection
		var platformLabel = new FlxText(box.x + 20, yPos, 100, "Platform:", 16);
		platformLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(platformLabel);
		
		var platforms = ["Auto-detect", "Windows", "macOS", "Linux", "Android"];
		platformDropdown = new PsychUIDropDownMenu(box.x + 120, yPos - 5, platforms, function(index:Int, option:String) {
			updateSizeEstimate();
		});
		platformDropdown.selectedIndex = 0;
		add(platformDropdown);
		
		yPos += spacing;
		
		// Compression Level
		compressionLabel = new FlxText(box.x + 20, yPos, 200, "Compression: Normal", 16);
		compressionLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(compressionLabel);
		
		compressionSlider = new PsychUISlider(box.x + 220, yPos, function(value:Float) {
			var level = Std.int(value);
			var levelText = switch(level) {
				case 1, 2, 3: "Fast";
				case 4, 5, 6: "Normal";
				case 7, 8, 9: "Maximum";
				default: "Normal";
			};
			compressionLabel.text = "Compression: " + levelText + " (" + level + ")";
		}, 6, 1, 9, 200);
		add(compressionSlider);
		
		yPos += spacing;
		
		// Exclusion Options
		var excludeLabel = new FlxText(box.x + 20, yPos, 200, "Exclude from package:", 16);
		excludeLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(excludeLabel);
		
		yPos += 25;
		
		excludeModsCheck = new PsychUICheckBox(box.x + 20, yPos, "mods/ folder", 150);
		excludeModsCheck.checked = true;
		excludeModsCheck.onClick = updateSizeEstimate;
		add(excludeModsCheck);
		
		excludePlayerSettingsCheck = new PsychUICheckBox(box.x + 20, yPos, "PlayerSettings/ folder", 200);
		excludePlayerSettingsCheck.checked = true;
		excludePlayerSettingsCheck.onClick = updateSizeEstimate;
		add(excludePlayerSettingsCheck);
		
		yPos += 30;
		
		excludeSaveCheck = new PsychUICheckBox(box.x + 200, yPos, "save/ folder", 150);
		excludeSaveCheck.checked = true;
		excludeSaveCheck.onClick = updateSizeEstimate;
		add(excludeSaveCheck);
		
		excludeTempCheck = new PsychUICheckBox(box.x + 20, yPos, "temp/ folder", 150);
		excludeTempCheck.checked = true;
		excludeTempCheck.onClick = updateSizeEstimate;
		add(excludeTempCheck);
		
		yPos += 30;
		
		excludeLogsCheck = new PsychUICheckBox(box.x + 200, yPos, "logs/ folder", 150);
		excludeLogsCheck.checked = true;
		excludeLogsCheck.onClick = updateSizeEstimate;
		add(excludeLogsCheck);
		
		excludeSourceCheck = new PsychUICheckBox(box.x + 20, yPos, "source/ folder", 150);
		excludeSourceCheck.checked = false;
		excludeSourceCheck.onClick = updateSizeEstimate;
		add(excludeSourceCheck);
		
		yPos += spacing;
		
		// Output Path
		var outputLabel = new FlxText(box.x + 20, yPos, 100, "Output:", 16);
		outputLabel.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, LEFT);
		add(outputLabel);
		
		outputPathInput = new PsychUIInputText(box.x + 120, yPos - 5, 300, "./releases/", 14);
		add(outputPathInput);
		
		browseButton = new PsychUIButton(box.x + 430, yPos - 5, "Browse", function() {
			// Would implement file browser here
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}, 120, 25);
		add(browseButton);
		
		yPos += spacing;
		
		// Size Estimate
		sizeEstimateText = new FlxText(box.x + 20, yPos, 550, "Estimated size: Calculating...", 14);
		sizeEstimateText.setFormat(Paths.font('fnf1.ttf'), 14, FlxColor.YELLOW, LEFT);
		add(sizeEstimateText);
		
		yPos += 40;
		
		// Buttons
		packageButton = new PsychUIButton(box.x + 100, yPos, "Start Packaging", startPackaging, 150, 30);
		packageButton.color = FlxColor.GREEN;
		add(packageButton);
		
		cancelButton = new PsychUIButton(box.x + 350, yPos, "Cancel", function() {
			close();
			onCancel();
		}, 150, 30);
		cancelButton.color = FlxColor.RED;
		add(cancelButton);
	}
	
	private function updateSizeEstimate():Void {
		// Calculate estimated size based on current settings
		var estimatedSize = 0;
		var files = 0;
		
		// This would scan the directories and calculate actual sizes
		// For now, we'll use rough estimates
		estimatedSize += 50 * 1024 * 1024; // Base engine ~50MB
		files += 1000;
		
		if (!excludeModsCheck.checked && FileSystem.exists("./mods/")) {
			estimatedSize += 100 * 1024 * 1024; // Mods ~100MB
			files += 500;
		}
		
		if (!excludePlayerSettingsCheck.checked && FileSystem.exists("./PlayerSettings/")) {
			estimatedSize += 5 * 1024 * 1024; // PlayerSettings ~5MB
			files += 50;
		}
		
		if (!excludeSaveCheck.checked && FileSystem.exists("./save/")) {
			estimatedSize += 1 * 1024 * 1024; // Save ~1MB
			files += 10;
		}
		
		if (!excludeSourceCheck.checked && FileSystem.exists("./source/")) {
			estimatedSize += 10 * 1024 * 1024; // Source ~10MB
			files += 200;
		}
		
		if (!excludeTempCheck.checked) {
			estimatedSize += 5 * 1024 * 1024; // Temp files ~5MB
			files += 50;
		}
		
		// Apply compression estimate
		var compressionRatio = 1.0 - (compressionSlider.value / 10.0 * 0.3); // 0-30% compression
		estimatedSize = Std.int(estimatedSize * compressionRatio);
		
		var sizeText = formatFileSize(estimatedSize);
		sizeEstimateText.text = 'Estimated size: $sizeText ($files files)';
	}
	
	private function formatFileSize(bytes:Int):String {
		if (bytes < 1024) return bytes + " B";
		if (bytes < 1024 * 1024) return Math.round(bytes / 1024 * 10) / 10 + " KB";
		if (bytes < 1024 * 1024 * 1024) return Math.round(bytes / (1024 * 1024) * 10) / 10 + " MB";
		return Math.round(bytes / (1024 * 1024 * 1024) * 10) / 10 + " GB";
	}
	
	private function startPackaging():Void {
		if (outputPathInput.text.trim() == "") {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		
		var options:PackagingOptions = {
			excludeMods: excludeModsCheck.checked,
			excludePlayerSettings: excludePlayerSettingsCheck.checked,
			excludeSave: excludeSaveCheck.checked,
			excludeTemp: excludeTempCheck.checked,
			excludeLogs: excludeLogsCheck.checked,
			excludeSource: excludeSourceCheck.checked,
			platform: platformDropdown.list[platformDropdown.selectedIndex],
			compressionLevel: Std.int(compressionSlider.value),
			outputPath: outputPathInput.text.trim()
		};
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		close();
		onComplete(options);
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