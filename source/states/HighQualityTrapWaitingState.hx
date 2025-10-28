package states;

import archipelago.HighQualityTrapManager;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
 * HighQualityTrapWaitingState
 * A waiting state shown while downloading SiivaGunner repository
 * Prevents user from leaving during download and shows progress
 */
class HighQualityTrapWaitingState extends backend.MusicBeatState
{
	private var bg:FlxSprite;
	private var titleText:FlxText;
	private var statusText:FlxText;
	private var progressText:FlxText;
	private var loadingDots:FlxText;
	private var warningText:FlxText;

	private var dotsTimer:FlxTimer;
	private var checkTimer:FlxTimer;
	private var currentDots:Int = 0;
	private var downloadStarted:Bool = false;

	override function create()
	{
		super.create();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Loading some High Quality Rips", null);
		#end

		// Background
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(20, 20, 20));
		add(bg);

		// Title
		titleText = new FlxText(0, FlxG.height * 0.25, FlxG.width, "High Quality Trap - Initializing");
		titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		add(titleText);

		// Status
		statusText = new FlxText(0, FlxG.height * 0.4, FlxG.width, "Downloading SiivaGunner Repository...");
		statusText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.CYAN, CENTER);
		add(statusText);

		// Progress
		progressText = new FlxText(0, FlxG.height * 0.5, FlxG.width, "Please wait while files are being downloaded");
		progressText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.YELLOW, CENTER);
		add(progressText);

		// Loading animation
		loadingDots = new FlxText(0, FlxG.height * 0.6, FlxG.width, "");
		loadingDots.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		add(loadingDots);

		// Warning
		warningText = new FlxText(20, FlxG.height - 80, FlxG.width - 40,
			"Please do not close the game or press any keys during download.\nThis may take a few minutes depending on your internet connection.");
		warningText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.fromRGB(255, 150, 150), CENTER);
		add(warningText);

		// Start loading animation
		dotsTimer = new FlxTimer().start(0.5, updateLoadingDots, 0);

		// Start checking for download completion
		checkTimer = new FlxTimer().start(1.0, checkDownloadStatus, 0);

		// Actually start the download!
		if (!downloadStarted) {
			downloadStarted = true;
			// Activate the trap which will trigger the download
			HighQualityTrapManager.activateTrap();
		}

		// Fade in animation
		FlxTween.tween(titleText, {alpha: 0}, 0);
		FlxTween.tween(statusText, {alpha: 0}, 0);
		FlxTween.tween(progressText, {alpha: 0}, 0);
		FlxTween.tween(loadingDots, {alpha: 0}, 0);
		FlxTween.tween(warningText, {alpha: 0}, 0);

		FlxTween.tween(titleText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(statusText, {alpha: 1}, 0.7, {ease: FlxEase.quadOut});
		FlxTween.tween(progressText, {alpha: 1}, 0.9, {ease: FlxEase.quadOut});
		FlxTween.tween(loadingDots, {alpha: 1}, 1.1, {ease: FlxEase.quadOut});
		FlxTween.tween(warningText, {alpha: 1}, 1.3, {ease: FlxEase.quadOut});

		// Disable autoPause to prevent issues during download
		FlxG.autoPause = false;
	}

	private function updateLoadingDots(timer:FlxTimer):Void
	{
		currentDots = (currentDots + 1) % 4;
		var dots = "";
		for (i in 0...currentDots) {
			dots += ".";
		}
		loadingDots.text = dots;
	}

	private function checkDownloadStatus(timer:FlxTimer):Void
	{
		if (!HighQualityTrapManager.isTrapActive()) {
			// Trap was deactivated, return to main menu
			exitWaitingState("High Quality Trap was deactivated");
			return;
		}

		if (!HighQualityTrapManager.needsWaitingState()) {
			// Download completed!
			completeDownload();
			return;
		}

		// Update progress text if available
		var progress = HighQualityTrapManager.getDownloadProgress();
		if (progress > 0 && progress < 1) {
			progressText.text = 'Download Progress: ${Math.round(progress * 100)}%';
		}
	}

	private function completeDownload():Void
	{
		// Stop timers
		if (dotsTimer != null) {
			dotsTimer.cancel();
			dotsTimer = null;
		}
		if (checkTimer != null) {
			checkTimer.cancel();
			checkTimer = null;
		}

		// Update UI
		statusText.text = "Download Complete!";
		statusText.color = FlxColor.LIME;
		progressText.text = "Preparing testing environment...";
		loadingDots.text = "";

		// Brief delay then switch to test state
		new FlxTimer().start(1.5, function(timer:FlxTimer) {
			// Re-enable autoPause
			FlxG.autoPause = true;

			// Switch to the test state
			FlxG.switchState(new HighQualityTrapTestState());
		});
	}

	private function exitWaitingState(reason:String):Void
	{
		// Stop timers
		if (dotsTimer != null) {
			dotsTimer.cancel();
			dotsTimer = null;
		}
		if (checkTimer != null) {
			checkTimer.cancel();
			checkTimer = null;
		}

		// Update UI
		statusText.text = "Error: " + reason;
		statusText.color = FlxColor.RED;
		progressText.text = "Returning to main menu...";
		loadingDots.text = "";

		// Re-enable autoPause
		FlxG.autoPause = true;

		// Exit testing mode and return to main menu
		backend.MusicBeatState.exitTrapTestingMode();

		new FlxTimer().start(2.0, function(timer:FlxTimer) {
			FlxG.switchState(new MainMenuState());
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Check if we're still in testing mode
		if (!backend.MusicBeatState.isTrapTestingMode()) {
			FlxG.switchState(new MainMenuState());
			return;
		}

		// Block all input during download
		// Don't process any key inputs - all input is blocked in update()
	}

	override function destroy()
	{
		// Clean up timers
		if (dotsTimer != null) {
			dotsTimer.cancel();
			dotsTimer = null;
		}
		if (checkTimer != null) {
			checkTimer.cancel();
			checkTimer = null;
		}

		// Re-enable autoPause just in case
		FlxG.autoPause = true;

		super.destroy();
	}
}
