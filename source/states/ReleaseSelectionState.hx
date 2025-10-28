package states;

import backend.GitHubAPI.GitHubAsset;
import backend.GitHubAPI.GitHubRelease;
import backend.GitHubAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import substates.GitHubPromptSubstate.GitHubButtonStyle;
import substates.GitHubPromptSubstate;
import substates.Prompt;
import substates.ReleaseInfoSubstate;

class ReleaseSelectionState extends MusicBeatState {
	private var releases:Array<GitHubRelease> = [];
	private var releaseItems:FlxTypedGroup<ReleaseItem>;
	private var scrollY:Float = 0;
	private var maxScroll:Float = 0;
	private var selectedIndex:Int = 0;

	private var bg:FlxSprite;
	private var gradientBar:FlxSprite;
	private var checker:FlxBackdrop;
	private var titleText:FlxText;
	private var instructionsText:FlxText;
	private var loadingText:FlxText;
	private var errorText:FlxText;

	private var loading:Bool = true;
	private var scrollSpeed:Float = 100;

	override function create() {
		super.create();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Checking out the other versions of Mixtape Engine", null);
		#end

		FlxG.mouse.visible = true; // Enable mouse cursor
		MusicManager.playMenuMusic();

		createBackground();
		createUI();
		loadReleases();
	}

	private function createBackground():Void {
		bg = new FlxSprite(-80).loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.color = 0xff270138;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		gradientBar = FlxGradient.createGradientFlxSprite(Math.round(FlxG.width), 512, [0x00ff0000, 0x55AE59E4, 0xAAFFA319], 1, 90, true);
		gradientBar.y = FlxG.height - gradientBar.height;
		add(gradientBar);
		gradientBar.scrollFactor.set(0, 0);

		checker = new FlxBackdrop(Paths.image('loading_screen/bgpattern'), XY, Std.int(0.2), Std.int(0.2));
		checker.blend = BlendMode.LAYER;
		add(checker);
		checker.scrollFactor.set(0, 0.07);
	}

	private function createUI():Void {
		titleText = new FlxText(0, 30, FlxG.width, "Select Release to Install", 32);
		titleText.setFormat(Paths.font('funkin.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		instructionsText = new FlxText(0, 80, FlxG.width, "Use UP/DOWN to navigate, ENTER to view details, ESCAPE to go back", 16);
		instructionsText.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(instructionsText);

		loadingText = new FlxText(0, FlxG.height / 2 - 20, FlxG.width, "Loading releases...", 24);
		loadingText.setFormat(Paths.font('funkin.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		loadingText.borderSize = 2;
		add(loadingText);

		errorText = new FlxText(0, FlxG.height / 2 - 20, FlxG.width, "", 20);
		errorText.setFormat(Paths.font('funkin.ttf'), 20, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
		errorText.borderSize = 2;
		errorText.visible = false;
		add(errorText);

		releaseItems = new FlxTypedGroup<ReleaseItem>();
		add(releaseItems);
	}

	private function loadReleases():Void {
		GitHubAPI.getPublicReleases(onReleasesLoaded, onError);
	}

	private function onReleasesLoaded(releasesData:Array<GitHubRelease>):Void {
		releases = releasesData;
		loading = false;
		loadingText.visible = false;

		if (releases.length == 0) {
			onError("No releases found");
			return;
		}

		createReleaseItems();
		updateSelection();
	}

	private function onError(error:String):Void {
		loading = false;
		loadingText.visible = false;
		errorText.text = "Error: " + error + "\nPress ESCAPE to go back";
		errorText.visible = true;
	}

	private function createReleaseItems():Void {
		var yPos:Float = 140;

		for (i in 0...releases.length) {
			var release = releases[i];
			var item = new ReleaseItem(20, yPos, release, i);
			releaseItems.add(item);
			yPos += item.itemHeight + 10;
		}

		maxScroll = Math.max(0, yPos - FlxG.height + 50);
	}

	private function updateSelection():Void {
		if (releases.length == 0) return;

		for (i in 0...releaseItems.length) {
			var item = releaseItems.members[i];
			if (item != null) {
				item.setSelected(i == selectedIndex);
			}
		}

		// Auto-scroll to keep selected item visible
		if (releaseItems.members[selectedIndex] != null) {
			var selectedItem = releaseItems.members[selectedIndex];
			var targetY = selectedItem.y - 200;

			if (targetY < 0) targetY = 0;
			if (targetY > maxScroll) targetY = maxScroll;

			FlxTween.tween(this, {scrollY: targetY}, 0.3, {ease: flixel.tweens.FlxEase.quadOut});
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		checker.x -= 0.45 / (ClientPrefs.data.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.data.framerate / 60);

		if (loading) return;

		if (errorText.visible) {
			if (controls.BACK) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(new MainMenuState());
			}
			return;
		}

		if (releases.length == 0) return;

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
			selectRelease();
		}

		if (backPressed) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		// Update scroll position for all items
		for (item in releaseItems.members) {
			if (item != null) {
				item.y = item.baseY - scrollY;
			}
		}
	}

	private function changeSelection(change:Int):Void {
		FlxG.sound.play(Paths.sound('scrollMenu'));
		selectedIndex = FlxMath.wrap(selectedIndex + change, 0, releases.length - 1);
		updateSelection();
	}

	private function selectRelease():Void {
		if (selectedIndex < 0 || selectedIndex >= releases.length) return;

		var selectedRelease = releases[selectedIndex];

		// Open detailed release info substate
		var releaseInfo = new ReleaseInfoSubstate(selectedRelease, function(release:GitHubRelease) {
			// Handle installation
			installRelease(release);
		}, function() {
			// Handle back - nothing special needed as substate closes
		});

		openSubState(releaseInfo);
	}

	private function installRelease(release:GitHubRelease):Void {
		// Check if this is an older version that doesn't support built-in updates
		if (isOlderThanBeta13(release)) {
			var prompt = new GitHubPromptSubstate("Warning: Older Version",
				"This version (" + release.tag_name + ") is beta12 or lower and doesn't have a built-in way to upgrade the engine.\n\n" +
				"You will need to manually download future updates or use external tools.\n\n" +
				"Continue with installation?", [
				{text: "Install Anyway", callback: function() { proceedWithInstall(release); }, style: GitHubButtonStyle.DANGER},
				{text: "Cancel", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
			]);
			openSubState(prompt);
			return;
		}

		proceedWithInstall(release);
	}

	private function proceedWithInstall(release:GitHubRelease):Void {
		var assets = GitHubAPI.getPlatformAssets(release);

		if (assets.length == 0) {
			var prompt = new GitHubPromptSubstate("No Compatible Files",
				"No compatible files found for your platform in this release.", [
				{text: "OK", callback: function() {}, style: GitHubButtonStyle.DANGER}
			]);
			openSubState(prompt);
			return;
		}

		if (assets.length == 1) {
			downloadRelease(release, assets[0]);
		} else {
			// Multiple assets, let user choose
			showAssetSelection(release, assets);
		}
	}

	private function isOlderThanBeta13(release:GitHubRelease):Bool {
		// Try to use release date first (more reliable)
		if (release.published_at != null && release.published_at.length > 0) {
			try {
				// Parse the ISO date format (YYYY-MM-DDTHH:MM:SSZ)
				var dateStr = release.published_at.split('T')[0]; // Get just the date part
				var parts = dateStr.split('-');
				if (parts.length == 3) {
					var year = Std.parseInt(parts[0]);
					var month = Std.parseInt(parts[1]);
					var day = Std.parseInt(parts[2]);

					// Set cutoff date to October 15, 2025 (yesterday) for testing
					// In a real scenario, this would be the date when beta13... existed.
					var cutoffYear = 2025;
					var cutoffMonth = 10;
					var cutoffDay = 15;

					if (year < cutoffYear) {
						return true;
					} else if (year == cutoffYear) {
						if (month < cutoffMonth) {
							return true;
						} else if (month == cutoffMonth && day < cutoffDay) {
							return true;
						}
					}

					return false; // Release is newer than cutoff
				}
			} catch (e:Dynamic) {
				// If date parsing fails, fall back to string checking
				trace("Date parsing failed for " + release.tag_name + ": " + e);
			}
		}

		// Fallback to string-based checking if date parsing fails
		var tag = release.tag_name.toLowerCase();

		// Remove 'v' prefix if present
		if (tag.charAt(0) == 'v') {
			tag = tag.substr(1);
		}

		// Check for beta versions
		if (tag.indexOf('beta') != -1) {
			var betaStr = tag.split('beta')[1];
			if (betaStr != null && betaStr.length > 0) {
				// Extract beta number
				var betaNum = Std.parseInt(betaStr.split('-')[0].split('.')[0]);
				if (betaNum != null && betaNum <= 12) {
					return true;
				}
			}
		}

		// Check for alpha versions (all considered older)
		if (tag.indexOf('alpha') != -1) {
			return true;
		}

		// Check for very old version patterns like 0.x.x
		var versionParts = tag.split('.');
		if (versionParts.length >= 1) {
			var major = Std.parseInt(versionParts[0]);
			if (major != null && major == 0) {
				return true;
			}
		}

		return false;
	}

	private function showAssetSelection(release:GitHubRelease, assets:Array<GitHubAsset>):Void {
		var assetNames = [];
		for (asset in assets) {
			assetNames.push(asset.name + " (" + GitHubAPI.formatFileSize(asset.size) + ")");
		}

		// For now, we'll automatically select the first compatible asset
		// TODO: Implement proper asset selection UI
		if (assets.length == 1) {
			var prompt = new GitHubPromptSubstate("Download Release",
				"Download " + assets[0].name + " (" + GitHubAPI.formatFileSize(assets[0].size) + ")?", [
				{text: "Download", callback: function() { downloadRelease(release, assets[0]); }, style: GitHubButtonStyle.SUCCESS},
				{text: "Cancel", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
			]);
			openSubState(prompt);
		} else {
			// Multiple assets - show first one for now
			var prompt = new GitHubPromptSubstate("Multiple Files Available",
				"Multiple compatible files found. Downloading: " + assets[0].name +
				" (" + GitHubAPI.formatFileSize(assets[0].size) + ")", [
				{text: "Download", callback: function() { downloadRelease(release, assets[0]); }, style: GitHubButtonStyle.SUCCESS},
				{text: "Cancel", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
			]);
			openSubState(prompt);
		}
	}

	private function downloadRelease(release:GitHubRelease, asset:GitHubAsset):Void {
		FlxG.sound.play(Paths.sound('confirmMenu'));

		// Store the selected release and asset data
		UpdateState.selectedRelease = release;
		UpdateState.selectedAsset = asset;

		FlxG.switchState(new UpdateState());
	}
}

class ReleaseItem extends FlxSpriteGroup {
	public var baseY:Float;
	public var release:GitHubRelease;
	public var index:Int;
	public var itemHeight:Float = 120;

	private var bg:FlxSprite;
	private var titleText:FlxText;
	private var dateText:FlxText;
	private var bodyText:FlxText;
	private var assetsText:FlxText;
	private var versionBadge:FlxSprite;
	private var versionText:FlxText;

	public function new(x:Float, y:Float, release:GitHubRelease, index:Int) {
		super(x, y);
		this.baseY = y;
		this.release = release;
		this.index = index;

		createComponents();
	}

	private function createComponents():Void {
		// Background
		bg = new FlxSprite().makeGraphic(FlxG.width - 40, Std.int(itemHeight), FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// Version badge
		versionBadge = new FlxSprite(10, 10).makeGraphic(80, 20, release.prerelease ? FlxColor.ORANGE : FlxColor.GREEN);
		add(versionBadge);

		versionText = new FlxText(10, 10, 80, release.prerelease ? "PRE" : "STABLE", 12);
		versionText.setFormat(Paths.font('fnf1.ttf'), 12, FlxColor.WHITE, CENTER);
		add(versionText);

		// Title
		titleText = new FlxText(100, 8, bg.width - 110, release.name, 18);
		titleText.setFormat(Paths.font('funkin.ttf'), 18, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(titleText);

		// Date
		dateText = new FlxText(100, 30, bg.width - 110, "Released: " + GitHubAPI.formatDate(release.published_at), 14);
		dateText.setFormat(Paths.font('fnf1.ttf'), 14, FlxColor.GRAY, LEFT);
		add(dateText);

		// Body (description/changelog) - add warning for older releases
		var bodyContent = "";
		if (isOlderThanBeta13(release)) {
			bodyContent = "⚠️ WARNING: This release does not support manual updating and downgrading.\n\n";
		}

		var bodyPreview = release.body.length > 200 ? release.body.substring(0, 200) + "..." : release.body;
		bodyContent += bodyPreview;

		bodyText = new FlxText(100, 50, bg.width - 110, bodyContent, 12);
		bodyText.setFormat(Paths.font('fnf1.ttf'), 12, FlxColor.WHITE, LEFT);
		add(bodyText);

		// Assets info
		var assetInfo = "Assets: ";
		var platformAssets = GitHubAPI.getPlatformAssets(release);
		for (i in 0...platformAssets.length) {
			if (i > 0) assetInfo += ", ";
			assetInfo += platformAssets[i].name + " (" + GitHubAPI.formatFileSize(platformAssets[i].size) + ")";
		}

		assetsText = new FlxText(10, itemHeight - 25, bg.width - 20, assetInfo, 11);
		assetsText.setFormat(Paths.font('fnf1.ttf'), 11, FlxColor.CYAN, LEFT);
		add(assetsText);
	}

	private function isOlderThanBeta13(release:GitHubRelease):Bool {
		// Try to use release date first (more reliable)
		if (release.published_at != null && release.published_at.length > 0) {
			try {
				// Parse the ISO date format (YYYY-MM-DDTHH:MM:SSZ)
				var dateStr = release.published_at.split('T')[0]; // Get just the date part
				var parts = dateStr.split('-');
				if (parts.length == 3) {
					var year = Std.parseInt(parts[0]);
					var month = Std.parseInt(parts[1]);
					var day = Std.parseInt(parts[2]);

					// Set cutoff date to October 15, 2025 (yesterday) for testing
					// In a real scenario, this would be the date when beta13 was released
					var cutoffYear = 2025;
					var cutoffMonth = 10;
					var cutoffDay = 15;

					if (year < cutoffYear) {
						return true;
					} else if (year == cutoffYear) {
						if (month < cutoffMonth) {
							return true;
						} else if (month == cutoffMonth && day < cutoffDay) {
							return true;
						}
					}

					return false; // Release is newer than cutoff
				}
			} catch (e:Dynamic) {
				// If date parsing fails, fall back to string checking
				trace("Date parsing failed for " + release.tag_name + ": " + e);
			}
		}

		// Fallback to string-based checking if date parsing fails
		var tag = release.tag_name.toLowerCase();

		// Remove 'v' prefix if present
		if (tag.charAt(0) == 'v') {
			tag = tag.substr(1);
		}

		// Check for beta versions
		if (tag.indexOf('beta') != -1) {
			var betaStr = tag.split('beta')[1];
			if (betaStr != null && betaStr.length > 0) {
				// Extract beta number
				var betaNum = Std.parseInt(betaStr.split('-')[0].split('.')[0]);
				if (betaNum != null && betaNum <= 12) {
					return true;
				}
			}
		}

		// Check for alpha versions (all considered older)
		if (tag.indexOf('alpha') != -1) {
			return true;
		}

		// Check for very old version patterns like 0.x.x
		var versionParts = tag.split('.');
		if (versionParts.length >= 1) {
			var major = Std.parseInt(versionParts[0]);
			if (major != null && major == 0) {
				return true;
			}
		}

		return false;
	}

	public function setSelected(selected:Bool):Void {
		bg.color = selected ? FlxColor.WHITE : FlxColor.GRAY;
		bg.alpha = selected ? 0.8 : 0.6;

		titleText.color = selected ? FlxColor.YELLOW : FlxColor.WHITE;
	}
}
