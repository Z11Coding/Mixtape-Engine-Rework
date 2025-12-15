package substates;

import backend.GitHubAPI.GitHubAsset;
import backend.GitHubAPI.GitHubRelease;
import backend.GitHubAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import substates.GitHubPromptSubstate.GitHubButton;
import substates.GitHubPromptSubstate.GitHubButtonStyle;

class AssetSelectionSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var darkOverlay:FlxSprite;
	var promptPanel:FlxSprite;
	var titleText:FlxText;
	var instructionsText:FlxText;
	var assetItems:FlxTypedGroup<AssetItem>;
	var cancelButton:GitHubButton;

	var release:GitHubRelease;
	var assets:Array<GitHubAsset>;
	var onAssetSelected:GitHubAsset->Void;
	var onCancel:Void->Void;
	var selectedIndex:Int = 0;
	var scrollY:Float = 0;
	var maxScroll:Num = 0;

	public function new(release:GitHubRelease, assets:Array<GitHubAsset>, onAssetSelected:GitHubAsset->Void, onCancel:Void->Void) {
		super();

		this.release = release;
		this.assets = assets;
		this.onAssetSelected = onAssetSelected;
		this.onCancel = onCancel;

		FlxG.mouse.visible = true;

		createBackground();
		createPrompt();
		createAssetItems();
		updateSelection();
	}

	private function createBackground():Void {
		// Dark overlay
		darkOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0x88000000);
		add(darkOverlay);

		// GitHub-style background
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff0d1117);
		bg.alpha = 0.95;
		add(bg);
	}

	private function createPrompt():Void {
		// Main prompt panel
		promptPanel = new FlxSprite().makeGraphic(600, 450, 0xff21262d);
		promptPanel.screenCenter();

		// Add border
		var border = new FlxSprite().makeGraphic(602, 452, 0xff30363d);
		border.screenCenter();
		border.x -= 1;
		border.y -= 1;
		add(border);
		add(promptPanel);

		// Title
		titleText = new FlxText(promptPanel.x + 20, promptPanel.y + 20, promptPanel.width - 40,
			"Select Asset to Download", 20);
		titleText.setFormat(Paths.font('funkin.ttf'), 20, 0xfff0f6fc, CENTER, OUTLINE, 0xff21262d);
		titleText.borderSize = 1;
		add(titleText);

		// Instructions
		instructionsText = new FlxText(promptPanel.x + 20, promptPanel.y + 50, promptPanel.width - 40,
			"Release: " + release.name + "\nUse UP/DOWN to navigate, ENTER to select, ESCAPE to cancel", 14);
		instructionsText.setFormat(Paths.font('fnf1.ttf'), 14, 0xffe6edf3, CENTER);
		add(instructionsText);

		// Cancel button at bottom
		cancelButton = new GitHubButton(promptPanel.x + promptPanel.width - 110,
			promptPanel.y + promptPanel.height - 50, "Cancel", onCancel, GitHubButtonStyle.SECONDARY);
		add(cancelButton);

		// Asset items container
		assetItems = new FlxTypedGroup<AssetItem>();
		add(assetItems);

		// Animate in
		promptPanel.alpha = 0;
		titleText.alpha = 0;
		instructionsText.alpha = 0;
		cancelButton.alpha = 0;

		FlxTween.tween(promptPanel, {alpha: 1}, 0.3, {ease: FlxEase.quadOut});
		FlxTween.tween(titleText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.1});
		FlxTween.tween(instructionsText, {alpha: 1}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.15});
		FlxTween.tween(cancelButton, {alpha: 1}, 0.3, {ease: FlxEase.quadOut, startDelay: 0.2});
	}

	private function createAssetItems():Void {
		var itemHeight:Float = 60;
		var startY = promptPanel.y + 100;
		var maxVisibleHeight = promptPanel.height - 180; // Space for title, instructions, and cancel button

		for (i in 0...assets.length) {
			var asset = assets[i];
			var yPos = startY + (i * (itemHeight + 10));
			var item = new AssetItem(promptPanel.x + 20, yPos, promptPanel.width - 40, itemHeight, asset, i);
			assetItems.add(item);
		}

		// Calculate max scroll
		var totalHeight = assets.length * (itemHeight + 10);
		maxScroll = Math.max(0, totalHeight - maxVisibleHeight);
	}

	private function updateSelection():Void {
		if (assets.length == 0) return;

		for (i in 0...assetItems.length) {
			var item = assetItems.members[i];
			if (item != null) {
				item.setSelected(i == selectedIndex);
			}
		}

		// Auto-scroll to keep selected item visible
		if (assetItems.members[selectedIndex] != null) {
			var selectedItem = assetItems.members[selectedIndex];
			var targetY:Num = (selectedIndex * 70) - 100; // Account for spacing and offset

			if (targetY < 0) targetY = 0;
			if (targetY > maxScroll) targetY = maxScroll;

			FlxTween.tween(this, {scrollY: targetY}, 0.3, {ease: FlxEase.quadOut});
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Handle navigation
		var upPressed = controls.UI_UP_P;
		var downPressed = controls.UI_DOWN_P;
		var enterPressed = controls.ACCEPT;
		var backPressed = controls.BACK;

		if (upPressed) {
			changeSelection(-1);
		} else if (downPressed) {
			changeSelection(1);
		}

		if (enterPressed) {
			selectAsset();
		}

		if (backPressed) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			onCancel();
			close();
		}

		// Update scroll position for all items
		for (item in assetItems.members) {
			if (item != null) {
				item.y = item.baseY - scrollY;
				// Hide items that are outside the visible area
				var panelTop = promptPanel.y + 100;
				var panelBottom = promptPanel.y + promptPanel.height - 80;
				item.visible = (item.y + item.itemHeight > panelTop && item.y < panelBottom);
			}
		}
	}

	private function changeSelection(change:Int):Void {
		FlxG.sound.play(Paths.sound('scrollMenu'));
		selectedIndex = FlxMath.wrap(selectedIndex + change, 0, assets.length - 1);
		updateSelection();
	}

	private function selectAsset():Void {
		if (selectedIndex < 0 || selectedIndex >= assets.length) return;

		FlxG.sound.play(Paths.sound('confirmMenu'));
		var selectedAsset = assets[selectedIndex];
		onAssetSelected(selectedAsset);
		close();
	}
}

class AssetItem extends FlxSprite {
	public var baseY:Float;
	public var asset:GitHubAsset;
	public var index:Int;
	public var itemHeight:Float;

	private var bg:FlxSprite;
	private var nameText:FlxText;
	private var sizeText:FlxText;
	private var typeText:FlxText;

	public function new(x:Float, y:Float, width:Float, height:Float, asset:GitHubAsset, index:Int) {
		super(x, y);
		this.baseY = y;
		this.asset = asset;
		this.index = index;
		this.itemHeight = height;

		makeGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT);
		createComponents(width, height);
	}

	private function createComponents(width:Float, height:Float):Void {
		// Background
		bg = new FlxSprite().makeGraphic(Std.int(width), Std.int(height), 0xff161b22);
		bg.alpha = 0.8;

		// Name text
		nameText = new FlxText(10, 5, width - 20, asset.name, 14);
		nameText.setFormat(Paths.font('funkin.ttf'), 14, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 1;

		// Size text
		sizeText = new FlxText(10, 25, width - 20, "Size: " + GitHubAPI.formatFileSize(asset.size), 12);
		sizeText.setFormat(Paths.font('fnf1.ttf'), 12, 0xffe6edf3, LEFT);

		// Type/platform info
		var typeInfo = getAssetTypeInfo(asset.name);
		typeText = new FlxText(10, 40, width - 20, typeInfo, 11);
		typeText.setFormat(Paths.font('fnf1.ttf'), 11, 0xff58a6ff, LEFT);
	}

	private function getAssetTypeInfo(filename:String):String {
		var lower = filename.toLowerCase();

		if (lower.contains("windows") || lower.contains("win")) {
			return "Platform: Windows";
		} else if (lower.contains("linux")) {
			return "Platform: Linux";
		} else if (lower.contains("mac") || lower.contains("osx")) {
			return "Platform: macOS";
		} else if (lower.contains("android")) {
			return "Platform: Android";
		} else if (lower.contains(".zip")) {
			return "Type: Archive";
		} else if (lower.contains(".exe")) {
			return "Type: Windows Executable";
		} else if (lower.contains(".dmg")) {
			return "Type: macOS Disk Image";
		} else if (lower.contains(".deb")) {
			return "Type: Debian Package";
		} else if (lower.contains(".rpm")) {
			return "Type: RPM Package";
		} else if (lower.contains(".apk")) {
			return "Type: Android Package";
		}

		return "Type: Unknown";
	}

	public function setSelected(selected:Bool):Void {
		color = selected ? FlxColor.WHITE : FlxColor.GRAY;
		alpha = selected ? 1.0 : 0.8;

		if (bg != null) {
			bg.color = selected ? 0xff30363d : 0xff161b22;
		}

		if (nameText != null) {
			nameText.color = selected ? FlxColor.YELLOW : FlxColor.WHITE;
		}
	}

	override function draw():Void {
		if (bg != null) {
			bg.setPosition(x, y);
			bg.draw();
		}

		if (nameText != null) {
			nameText.setPosition(x + 10, y + 5);
			nameText.draw();
		}

		if (sizeText != null) {
			sizeText.setPosition(x + 10, y + 25);
			sizeText.draw();
		}

		if (typeText != null) {
			typeText.setPosition(x + 10, y + 40);
			typeText.draw();
		}

		super.draw();
	}
}
