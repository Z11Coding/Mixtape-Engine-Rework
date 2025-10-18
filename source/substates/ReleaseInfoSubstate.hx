package substates;

import backend.GitHubAPI.GitHubAsset;
import backend.GitHubAPI.GitHubRelease;
import backend.GitHubAPI;
import backend.ui.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;
import substates.GitHubPromptSubstate.GitHubButtonStyle;
import substates.GitHubPromptSubstate;

class ReleaseInfoSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var gradientBar:FlxSprite;
	var checker:FlxBackdrop;
	var box:PsychUIBox;

	var titleText:FlxText;
	var versionText:FlxText;
	var authorText:FlxText;
	var dateText:FlxText;
	var descriptionText:FlxText;
	var assetsText:FlxText;

	var scrollContainer:FlxTypedGroup<FlxSprite>;
	var scrollableElements:Array<FlxText> = [];
	var scrollY:Float = 0;
	var maxScroll:Float = 0;
	var scrollSpeed:Float = 300; // Increased from 50 to 300 for faster scrolling

	var installButton:PsychUIButton;
	var backButton:PsychUIButton;
	var viewOnlineButton:PsychUIButton;
	var scrollIndicator:FlxText;

	var release:GitHubRelease;
	var onInstall:GitHubRelease->Void;
	var onBack:Void->Void;

	public function new(release:GitHubRelease, onInstall:GitHubRelease->Void, onBack:Void->Void) {
		super();

		this.release = release;
		this.onInstall = onInstall;
		this.onBack = onBack;
	}

	override function create() {
		super.create();

		FlxG.mouse.visible = true; // Enable mouse cursor

		createBackground();
		createContent();
		createButtons();

		updateScrollBounds();
	}

	private function createBackground():Void {
		// Dark background
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff0d1117);
		add(bg);

		// Animated checker pattern
		checker = new FlxBackdrop(Paths.image('psych-ui/checker', 'embed'), XY);
		checker.alpha = 0.1;
		checker.blend = BlendMode.OVERLAY;
		add(checker);

		// Top gradient bar
		gradientBar = FlxGradient.createGradientFlxSprite(FlxG.width, 60, [0xff58a6ff, 0xff0969da]);
		add(gradientBar);

		// Main content box
		box = new PsychUIBox(50, 80, FlxG.width - 100, FlxG.height - 160);
		add(box);
	}

	private function createContent():Void {
		var yPos:Float = box.y + 20;
		var spacing:Float = 25;
		var textWidth:Float = box.width - 40;

		scrollableElements = []; // Reset scrollable elements array

		// Title (with responsive font sizing)
		var titleStr = release.name != null ? release.name : release.tag_name;
		var titleFontSize = 24;

		// Reduce font size for very long titles
		if (titleStr.length > 50) {
			titleFontSize = 18;
		} else if (titleStr.length > 30) {
			titleFontSize = 20;
		}

		titleText = new FlxText(box.x + 20, yPos, textWidth, titleStr, titleFontSize);
		titleText.setFormat(Paths.font('fnf1.ttf'), titleFontSize, FlxColor.WHITE, LEFT);
		titleText.wordWrap = true;
		add(titleText);
		scrollableElements.push(titleText);

		yPos += Math.max(titleText.height, 30) + spacing;

		// Version/Tag
		versionText = new FlxText(box.x + 20, yPos, textWidth, "Version: " + release.tag_name, 16);
		versionText.setFormat(Paths.font('fnf1.ttf'), 16, 0xff58a6ff, LEFT);
		add(versionText);
		scrollableElements.push(versionText);

		yPos += spacing;

		// Author
		authorText = new FlxText(box.x + 20, yPos, textWidth, "Author: " + release.author.login, 16);
		authorText.setFormat(Paths.font('fnf1.ttf'), 16, 0xff7c3aed, LEFT);
		add(authorText);
		scrollableElements.push(authorText);

		yPos += spacing;

		// Date
		var dateStr = release.published_at != null ? formatDate(release.published_at) : "Draft";
		dateText = new FlxText(box.x + 20, yPos, textWidth, "Released: " + dateStr, 16);
		dateText.setFormat(Paths.font('fnf1.ttf'), 16, 0xff6b7280, LEFT);
		add(dateText);
		scrollableElements.push(dateText);

		yPos += spacing;

		// Status badges
		var badgeText = "";
		if (release.prerelease) badgeText += "[PRE-RELEASE] ";
		if (release.draft) badgeText += "[DRAFT] ";

		if (badgeText != "") {
			var statusText = new FlxText(box.x + 20, yPos, textWidth, badgeText, 14);
			statusText.setFormat(Paths.font('fnf1.ttf'), 14, release.prerelease ? 0xfffb8500 : 0xffdc2626, LEFT);
			add(statusText);
			scrollableElements.push(statusText);
			yPos += spacing;
		}

		// Assets info
		var assets = GitHubAPI.getPlatformAssets(release);
		var assetInfo = "Compatible files: " + assets.length;
		if (assets.length > 0) {
			assetInfo += "\n";
			for (i in 0...Math.floor(Math.min(assets.length, 3))) {
				assetInfo += "• " + assets[i].name + " (" + GitHubAPI.formatFileSize(assets[i].size) + ")\n";
			}
			if (assets.length > 3) {
				assetInfo += "• ... and " + (assets.length - 3) + " more";
			}
		}

		assetsText = new FlxText(box.x + 20, yPos, textWidth, assetInfo, 14);
		assetsText.setFormat(Paths.font('fnf1.ttf'), 14, 0xff22c55e, LEFT);
		assetsText.wordWrap = true;
		add(assetsText);
		scrollableElements.push(assetsText);

		yPos += Math.max(assetsText.height, 40) + spacing;

		// Description
		var descLabel = new FlxText(box.x + 20, yPos, textWidth, "Description:", 18);
		descLabel.setFormat(Paths.font('fnf1.ttf'), 18, FlxColor.WHITE, LEFT);
		add(descLabel);
		scrollableElements.push(descLabel);

		yPos += spacing;

		// Description content
		var description = release.body != null ? release.body : "No description provided.";
		var originalLength = description.length;
		var maxLength = 30000;
		var wasTruncated = false;

		if (description.length > maxLength) {
			description = description.substring(0, maxLength) + "...";
			wasTruncated = true;
		}

		descriptionText = new FlxText(box.x + 20, yPos, textWidth, description, 14);
		descriptionText.setFormat(Paths.font('fnf1.ttf'), 14, 0xffe5e7eb, LEFT);
		descriptionText.wordWrap = true;
		add(descriptionText);
		scrollableElements.push(descriptionText);

		// Add truncation indicator if text was cut off
		if (wasTruncated) {
			var remainingChars = originalLength - maxLength;
			var truncationText = new FlxText(box.x + 20, yPos + descriptionText.height + 5, textWidth,
				"(" + remainingChars + " more characters - view online for full description)", 12);
			truncationText.setFormat(Paths.font('fnf1.ttf'), 12, 0xff888888, LEFT);
			truncationText.wordWrap = true;
			add(truncationText);
			scrollableElements.push(truncationText);
		}
	}

	private function createButtons():Void {
		var buttonY = box.y + box.height - 60;
		var buttonWidth = 120;
		var buttonSpacing = 20;

		// View Online button (leftmost)
		viewOnlineButton = new PsychUIButton(box.x + buttonSpacing, buttonY,
			"View Online", function() {
				var releaseUrl = release.html_url;
				if (releaseUrl != null && releaseUrl != "") {
					try {
						// Use CoolUtil to open the URL in the default browser
						CoolUtil.browserLoad(releaseUrl);
						FlxG.sound.play(Paths.sound('confirmMenu'));
					} catch (e:Dynamic) {
						// If opening URL fails, show the URL in a dialog
						var prompt = new GitHubPromptSubstate("Release URL",
							"Visit this URL to view the release online:\n\n" + releaseUrl, [
							{text: "OK", callback: function() {}, style: GitHubButtonStyle.PRIMARY}
						]);
						openSubState(prompt);
					}
				} else {
					// No URL available
					var prompt = new GitHubPromptSubstate("No URL Available",
						"No online URL is available for this release.", [
						{text: "OK", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
					]);
					openSubState(prompt);
				}
			}, buttonWidth);
		add(viewOnlineButton);

		// Install button (center)
		installButton = new PsychUIButton(box.x + box.width - buttonWidth - buttonSpacing - buttonWidth - buttonSpacing, buttonY,
			"Install", function() {
				// Check if in livereload mode (compiler is running)
				if (Sys.args().indexOf('-livereload') != -1) {
					var prompt = new GitHubPromptSubstate("Cannot Update During Compilation",
						"You can't update while using the compiler.\n\n" +
						"Please stop the compilation process and try again.", [
						{text: "OK", callback: function() {}, style: GitHubButtonStyle.PRIMARY}
					]);
					openSubState(prompt);
					return;
				}

				// Check if this is an older version that doesn't support built-in updates
				if (isOlderThanBeta13(release)) {
					var prompt = new GitHubPromptSubstate("Warning: Older Version",
						"This version (" + release.tag_name + ") is beta12 or lower and doesn't have a built-in way to upgrade the engine.\n\n" +
						"You will need to manually download future updates or use external tools.\n\n" +
						"Continue with installation?", [
						{text: "Install Anyway", callback: function() {
							close();
							onInstall(release);
						}, style: GitHubButtonStyle.DANGER},
						{text: "Cancel", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
					]);
					openSubState(prompt);
					return;
				}

				close();
				onInstall(release);
			}, buttonWidth);
		add(installButton);

		// Back button (rightmost)
		backButton = new PsychUIButton(box.x + box.width - buttonWidth - buttonSpacing, buttonY,
			"Back", function() {
				close();
				onBack();
			}, buttonWidth);
		add(backButton);

		// Scroll indicator
		scrollIndicator = new FlxText(box.x + 20, buttonY + 10, 200, "", 12);
		scrollIndicator.setFormat(Paths.font('fnf1.ttf'), 12, 0xff6b7280, LEFT);
		add(scrollIndicator);

		// Disable install button if no compatible assets
		var assets = GitHubAPI.getPlatformAssets(release);
		if (assets.length == 0) {
			installButton.label = "No Files";
			installButton.color = 0xff6b7280;
			// TODO: Actually disable the button functionality
		}
	}

	private function updateScrollBounds():Void {
		if (scrollableElements.length == 0) {
			maxScroll = 0;
			return;
		}

		// Find the bottom-most element
		var maxY = box.y + 20;
		for (element in scrollableElements) {
			var elementBottom = element.y + element.height;
			if (elementBottom > maxY) {
				maxY = elementBottom;
			}
		}

		var contentHeight = maxY - (box.y + 20);
		var availableHeight = box.height - 100; // Reserve space for buttons

		maxScroll = Math.max(0, contentHeight - availableHeight);
	}

	private function formatDate(dateStr:String):String {
		// Basic date formatting - you might want to use a proper date library
		try {
			var parts = dateStr.split("T")[0].split("-");
			if (parts.length >= 3) {
				return parts[1] + "/" + parts[2] + "/" + parts[0];
			}
		} catch (e) {
			// Fallback to original string
		}
		return dateStr;
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

	override function update(elapsed:Float) {
		super.update(elapsed);

		// Animate background
		checker.x -= 0.45 / (ClientPrefs.data.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.data.framerate / 60);

		// Update scroll indicator
		if (maxScroll > 0) {
			var scrollPercent = Math.round((scrollY / maxScroll) * 100);
			var scrollInfo = "Use UP/DOWN/Mouse Wheel to scroll (" + scrollPercent + "%)";

			// Add helpful hints
			if (scrollY == 0) {
				scrollInfo += " - At top";
			} else if (scrollY >= maxScroll) {
				scrollInfo += " - At bottom";
			}

			scrollIndicator.text = scrollInfo;
			scrollIndicator.visible = true;
		} else {
			scrollIndicator.text = "Content fits on screen";
			scrollIndicator.visible = true;
		}

		// Handle scrolling
		if (maxScroll > 0) {
			var scroll = 0.0;

			// Keyboard scrolling (faster)
			if (controls.UI_UP_P || FlxG.keys.pressed.UP) {
				scroll = -scrollSpeed * elapsed;
			} else if (controls.UI_DOWN_P || FlxG.keys.pressed.DOWN) {
				scroll = scrollSpeed * elapsed;
			}

			// Mouse wheel scrolling (even faster for quick navigation)
			if (FlxG.mouse.wheel != 0) {
				scroll = -FlxG.mouse.wheel * (scrollSpeed * 2); // 2x speed for mouse wheel
			}

			// Page Up/Page Down for large jumps
			if (FlxG.keys.justPressed.PAGEUP) {
				scroll = -(scrollSpeed * 5); // 5x speed for page jumps
			} else if (FlxG.keys.justPressed.PAGEDOWN) {
				scroll = (scrollSpeed * 5);
			}

			if (scroll != 0) {
				var oldScrollY = scrollY;
				scrollY = FlxMath.bound(scrollY + scroll, 0, maxScroll);

				// Apply scroll offset to scrollable elements
				var scrollDelta = scrollY - oldScrollY;
				for (element in scrollableElements) {
					element.y -= scrollDelta;
				}

				// Play subtle scroll sound if actually scrolled
				if (scrollDelta != 0 && (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN ||
					FlxG.keys.justPressed.PAGEUP || FlxG.keys.justPressed.PAGEDOWN)) {
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
				}
			}
		}

		// Handle input
		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			onBack();
		}

		if (controls.ACCEPT) {
			var assets = GitHubAPI.getPlatformAssets(release);
			if (assets.length > 0) {
				// Check if in livereload mode (compiler is running)
				if (Sys.args().indexOf('-livereload') != -1) {
					var prompt = new GitHubPromptSubstate("Cannot Update During Compilation",
						"You can't update while using the compiler.\n\n" +
						"Open the game in a normal instance to update.", [
						{text: "OK", callback: function() {}, style: GitHubButtonStyle.PRIMARY}
					]);
					openSubState(prompt);
					return;
				}

				// Check if this is an older version that doesn't support built-in updates
				if (isOlderThanBeta13(release)) {
					var prompt = new GitHubPromptSubstate("Warning: Older Version",
						"This version (" + release.tag_name + ") is beta12 or lower and doesn't have a built-in way to upgrade the engine.\n\n" +
						"You will need to manually download future updates or use external tools.\n\n" +
						"Continue with installation?", [
						{text: "Install Anyway", callback: function() {
							close();
							onInstall(release);
						}, style: GitHubButtonStyle.DANGER},
						{text: "Cancel", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
					]);
					openSubState(prompt);
					return;
				}

				FlxG.sound.play(Paths.sound('confirmMenu'));
				close();
				onInstall(release);
			} else {
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}
	}
}
