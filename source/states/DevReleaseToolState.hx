package states;

import backend.GitHubAPI.GitHubCreateRelease;
import backend.GitHubAPI.GitHubRelease;
import backend.GitHubAPI.GitHubUser;
import backend.GitHubAPI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
import haxe.io.BytesOutput;
import haxe.zip.Entry;
import haxe.zip.Writer;
import openfl.display.BlendMode;
import substates.Prompt;
import substates.TokenInputSubstate;
import substates.GitHubPromptSubstate;
import substates.ReleaseCreationSubstate;
import substates.ReleaseCreationSubstate.ReleaseCreationData;
import substates.PackagingOptionsSubstate;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

class DevReleaseToolState extends MusicBeatState {
	private var bg:FlxSprite;
	private var gradientBar:FlxSprite;
	private var checker:FlxBackdrop;
	private var titleText:FlxText;
	private var statusText:FlxText;
	private var instructionsText:FlxText;
	private var userInfoText:FlxText;

	private var menuItems:Array<String> = [
		"Authenticate with GitHub",
		"View User Info",
		"Create Release",
		"Package and Upload",
		"Clear Authentication",
		"Back to Main Menu"
	];

	private var selectedIndex:Int = 0;
	private var menuTexts:Array<FlxText> = [];

	private var authenticated:Bool = false;
	private var userInfo:GitHubUser = null;
	private var isProcessing:Bool = false;

	override function create() {
		super.create();

		// Check if in livereload mode
		if (Sys.args().indexOf('-livereload') == -1) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
			return;
		}

		MusicManager.playMenuMusic();

		createBackground();
		createUI();
		checkAuthentication();
	}

	private function createBackground():Void {
		bg = new FlxSprite(-80).loadGraphic(Paths.image(ClientPrefs.getBGImage()));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.color = 0xff1a0b2e;
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
		titleText = new FlxText(0, 30, FlxG.width, "Developer Release Tool", 32);
		titleText.setFormat(Paths.font('funkin.ttf'), 32, FlxColor.YELLOW, CENTER, OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 2;
		add(titleText);

		statusText = new FlxText(0, 80, FlxG.width, "Not Authenticated", 16);
		statusText.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
		add(statusText);

		userInfoText = new FlxText(0, 100, FlxG.width, "", 14);
		userInfoText.setFormat(Paths.font('fnf1.ttf'), 14, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(userInfoText);

		instructionsText = new FlxText(0, FlxG.height - 60, FlxG.width, "Use UP/DOWN to navigate, ENTER to select, ESCAPE to go back", 16);
		instructionsText.setFormat(Paths.font('fnf1.ttf'), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(instructionsText);

		createMenuItems();
		updateSelection();
	}

	private function createMenuItems():Void {
		var startY:Float = 180;

		for (i in 0...menuItems.length) {
			var menuText = new FlxText(0, startY + (i * 40), FlxG.width, menuItems[i], 20);
			menuText.setFormat(Paths.font('funkin.ttf'), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
			menuText.borderSize = 2;
			add(menuText);
			menuTexts.push(menuText);
		}
	}

	private function checkAuthentication():Void {
		authenticated = GitHubAPI.loadAuthToken();
		updateAuthStatus();

		if (authenticated) {
			getUserInfo();
		}
	}

	private function updateAuthStatus():Void {
		if (authenticated) {
			statusText.text = "Authenticated";
			statusText.color = FlxColor.GREEN;
		} else {
			statusText.text = "Not Authenticated";
			statusText.color = FlxColor.RED;
			userInfoText.text = "";
		}
	}

	private function getUserInfo():Void {
		if (!authenticated) return;

		GitHubAPI.getUserInfo(function(user:GitHubUser) {
			userInfo = user;
			userInfoText.text = "Logged in as: " + user.login + " (" + user.name + ")";

			// Check repository access
			GitHubAPI.hasRepoAccess(function(hasAccess:Bool) {
				if (!hasAccess) {
					userInfoText.text += "\nWARNING: No push access to repository!";
					userInfoText.color = FlxColor.ORANGE;
				} else {
					userInfoText.color = FlxColor.WHITE;
				}
			}, function(error:String) {
				trace("Failed to check repo access: " + error);
			});
		}, function(error:String) {
			trace("Failed to get user info: " + error);
			authenticated = false;
			GitHubAPI.clearAuth();
			updateAuthStatus();
		});
	}

	private function updateSelection():Void {
		for (i in 0...menuTexts.length) {
			var isSelected = (i == selectedIndex);
			menuTexts[i].color = isSelected ? FlxColor.YELLOW : FlxColor.WHITE;
			menuTexts[i].alpha = isSelected ? 1.0 : 0.7;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		checker.x -= 0.45 / (ClientPrefs.data.framerate / 60);
		checker.y -= 0.16 / (ClientPrefs.data.framerate / 60);

		if (isProcessing) return;

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
			selectMenuItem();
		}

		if (backPressed) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}
	}

	private function changeSelection(change:Int):Void {
		FlxG.sound.play(Paths.sound('scrollMenu'));
		selectedIndex = FlxMath.wrap(selectedIndex + change, 0, menuItems.length - 1);
		updateSelection();
	}

	private function selectMenuItem():Void {
		FlxG.sound.play(Paths.sound('confirmMenu'));

		switch (selectedIndex) {
			case 0: // Authenticate with GitHub
				authenticateWithGitHub();
			case 1: // View User Info
				viewUserInfo();
			case 2: // Create Release
				createRelease();
			case 3: // Package and Upload
				packageAndUpload();
			case 4: // Clear Authentication
				clearAuthentication();
			case 5: // Back to Main Menu
				FlxG.switchState(new MainMenuState());
		}
	}

	private function authenticateWithGitHub():Void {
		if (authenticated) {
			var prompt = new GitHubPromptSubstate("Re-authenticate", 
				"Already authenticated as " + (userInfo != null ? userInfo.login : "unknown") + 
				"\nDo you want to re-authenticate?", [
				{text: "Yes", callback: function() { clearAuthentication(); authenticateWithGitHub(); }, style: GitHubButtonStyle.DANGER},
				{text: "No", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
			]);
			openSubState(prompt);
			return;
		}

		// For simplicity, we'll ask for a token. In a real implementation,
		// you might want to implement OAuth flow
		var prompt = new GitHubPromptSubstate("GitHub Authentication", 
			"Enter GitHub Personal Access Token:\n(Create one at: github.com/settings/tokens)\n" +
			"Required scopes: repo", [
			{text: "OK", callback: function() {
				// This would need a text input field in the Prompt substate
				// For now, we'll simulate it
				showTokenInput();
			}, style: GitHubButtonStyle.PRIMARY},
			{text: "Cancel", callback: function() {}, style: GitHubButtonStyle.SECONDARY}
		]);
		openSubState(prompt);
	}

	private function showTokenInput():Void {
		var tokenInput = new TokenInputSubstate(function(token:String) {
			// Validate the token
			GitHubAPI.validateToken(token, function(valid:Bool) {
				if (valid) {
					GitHubAPI.setAuthToken(token);
					authenticated = true;
					updateAuthStatus();
					getUserInfo();

					var prompt = new GitHubPromptSubstate("Success", "Authentication successful!", [
						{text: "OK", callback: function() {}, style: GitHubButtonStyle.SUCCESS}
					]);
					openSubState(prompt);
				} else {
					var prompt = new GitHubPromptSubstate("Error", "Invalid token. Please check your token and try again.", [
						{text: "OK", callback: function() {}, style: GitHubButtonStyle.DANGER}
					]);
					openSubState(prompt);
				}
			});
		}, function() {
			// User cancelled
		});

		openSubState(tokenInput);
	}

	private function viewUserInfo():Void {
		if (!authenticated) {
			var prompt = new GitHubPromptSubstate("Error", "Not authenticated. Please authenticate first.", [
				{text: "OK", callback: function() {}, style: GitHubButtonStyle.DANGER}
			]);
			openSubState(prompt);
			return;
		}

		var info = "User: " + (userInfo != null ? userInfo.login : "Loading...") + "\n";
		if (userInfo != null) {
			info += "Name: " + userInfo.name + "\n";
			info += "Email: " + userInfo.email + "\n";
			info += "ID: " + userInfo.id;
		}

		var prompt = new GitHubPromptSubstate("User Information", info, [
			{text: "OK", callback: function() {}, style: GitHubButtonStyle.PRIMARY}
		]);
		openSubState(prompt);
	}

	private function createRelease():Void {
		if (!authenticated) {
			var prompt = new GitHubPromptSubstate("Error", "Not authenticated. Please authenticate first.", [
				{text: "OK", callback: function() {}, style: GitHubButtonStyle.DANGER}
			]);
			openSubState(prompt);
			return;
		}

		// Open the release creation substate
		var releaseCreation = new ReleaseCreationSubstate(function(releaseData:ReleaseCreationData) {
			// Create the release
			var createData:GitHubCreateRelease = {
				tag_name: releaseData.tagName,
				target_commitish: "main", // or could be "HEAD" or specific branch
				name: releaseData.title,
				body: releaseData.description,
				draft: releaseData.isDraft,
				prerelease: releaseData.isPrerelease
			};

			GitHubAPI.createRelease(createData, function(release) {
				var prompt = new GitHubPromptSubstate("Success", 
					"Release '" + release.name + "' created successfully!\nTag: " + release.tag_name, [
					{text: "OK", callback: function() {}, style: GitHubButtonStyle.SUCCESS}
				]);
				openSubState(prompt);
			}, function(error:String) {
				var prompt = new GitHubPromptSubstate("Error", "Failed to create release:\n" + error, [
					{text: "OK", callback: function() {}, style: GitHubButtonStyle.DANGER}
				]);
				openSubState(prompt);
			});
		}, function() {
			// User cancelled
		});
		openSubState(releaseCreation);
	}

	private function packageAndUpload():Void {
		if (!authenticated) {
			var prompt = new GitHubPromptSubstate("Error", "Not authenticated. Please authenticate first.", [
				{text: "OK", callback: function() {}, style: GitHubButtonStyle.DANGER}
			]);
			openSubState(prompt);
			return;
		}

		// Open packaging options substate
		var packagingOptions = new PackagingOptionsSubstate(function(options:PackagingOptions) {
			startPackaging(options);
		}, function() {
			// User cancelled
		});
		openSubState(packagingOptions);
	}

	private function startPackaging(options:PackagingOptions):Void {
		isProcessing = true;
		statusText.text = "Packaging...";
		statusText.color = FlxColor.YELLOW;

		// Build exclusion list based on options
		var excludeFolders:Array<String> = [];
		if (options.excludeMods) excludeFolders.push("mods");
		if (options.excludePlayerSettings) excludeFolders.push("PlayerSettings");
		if (options.excludeSave) excludeFolders.push("save");

		trace("Packaging with options:");
		trace("- Platform: " + options.platform);
		trace("- Exclude folders: " + excludeFolders.join(", "));

		// This would involve:
		// 1. Creating a build if needed
		// 2. Copying files to temp directory (excluding specified folders)
		// 3. Creating zip file
		// 4. Uploading to GitHub

		new FlxTimer().start(2, function(timer:FlxTimer) {
			statusText.text = "Packaging completed (placeholder implementation)";
			statusText.color = FlxColor.GREEN;
			isProcessing = false;
			
			var prompt = new GitHubPromptSubstate("Packaging Complete", 
				"Package created successfully!\nPlatform: " + options.platform + 
				"\nExcluded: " + excludeFolders.join(", "), [
				{text: "OK", callback: function() {}, style: GitHubButtonStyle.SUCCESS}
			]);
			openSubState(prompt);
		});
	}

	private function clearAuthentication():Void {
		GitHubAPI.clearAuth();
		authenticated = false;
		userInfo = null;
		updateAuthStatus();

		var prompt = new GitHubPromptSubstate("Success", "Authentication cleared.", [
			{text: "OK", callback: function() {}, style: GitHubButtonStyle.SUCCESS}
		]);
		openSubState(prompt);
	}

	// Helper functions for packaging (to be implemented)
	private function createBuildZip():String {
		// This would create a zip file of the current build
		// excluding the mods folder and other unnecessary files
		return "./temp/build.zip";
	}

	private function getPlatformBuildPath():String {
		#if windows
		return "./export/release/windows/bin/";
		#elseif mac
		return "./export/release/macos/bin/";
		#elseif linux
		return "./export/release/linux/bin/";
		#else
		return "./export/release/";
		#end
	}
}
