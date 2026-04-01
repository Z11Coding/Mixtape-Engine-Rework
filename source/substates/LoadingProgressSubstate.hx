package substates;

import backend.ClientPrefs;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import managers.LoadingStateTracker;

/**
 * Visual overlay showing loading progress during dynamic freeplay loading.
 * Displays progress bar, item counter, and optional animations.
 */
class LoadingProgressSubstate extends FlxSubState
{
	private var tracker:LoadingStateTracker;
	private var onCloseCallback:Void->Void;

	private var titleText:FlxText;
	private var progressText:FlxText;
	private var percentText:FlxText;

	private var progressBarFilled:flixel.FlxSprite;
	private var progressBarBg:flixel.FlxSprite;

	private var spinnerAngle:Float = 0;
	private var spinnerSpeed:Float = 180; // degrees per second
	private var closeDelay:Float = 0;
	private var hasStartedCloseDelay:Bool = false;

	public function new(tracker:LoadingStateTracker, ?onClose:Void->Void)
	{
		super();
		this.tracker = tracker;
		this.onCloseCallback = onClose != null ? onClose : () -> {};

		createUI();
	}

	private function createUI():Void
	{
		// Semi-transparent overlay background
		var overlay = new flixel.FlxSprite(0, 0);
		overlay.makeGraphic(FlxG.width, FlxG.height, 0x99000000);
		add(overlay);

		// Panel background
		var panelWidth = 400;
		var panelHeight = 150;
		var panelX = (FlxG.width - panelWidth) / 2;
		var panelY = (FlxG.height - panelHeight) / 2;

		var panel = new flixel.FlxSprite(panelX, panelY);
		panel.makeGraphic(panelWidth, panelHeight, 0xFF1F1F2E);
		add(panel);

		// Panel border using frameGraphic
		var border = new flixel.FlxSprite(panelX, panelY);
		border.makeGraphic(panelWidth, panelHeight, FlxColor.TRANSPARENT);
		flixel.util.FlxSpriteUtil.drawRect(border, 0, 0, panelWidth, panelHeight, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.CYAN});
		add(border);

		// Title text
		titleText = new FlxText(panelX + 10, panelY + 10, panelWidth - 20, "Loading Songs...");
		titleText.setFormat(null, 20, FlxColor.WHITE, "center");
		add(titleText);

		// Progress bar background
		var barX = panelX + 20;
		var barY = panelY + 45;
		var barWidth = panelWidth - 40;
		var barHeight = 20;

		progressBarBg = new flixel.FlxSprite(barX, barY);
		progressBarBg.makeGraphic(barWidth, barHeight, 0xFF333333);
		add(progressBarBg);

		// Progress bar foreground (filled bar)
		progressBarFilled = new flixel.FlxSprite(barX, barY);
		progressBarFilled.makeGraphic(1, barHeight, FlxColor.CYAN);
		progressBarFilled.scale.x = 0;
		add(progressBarFilled);

		// Counter text
		progressText = new FlxText(barX, barY + 30, barWidth, "0 / 0 songs");
		progressText.setFormat(null, 14, FlxColor.WHITE, "center");
		add(progressText);

		// Percentage text
		percentText = new FlxText(panelX + 10, panelY + 110, panelWidth - 20, "0%");
		percentText.setFormat(null, 16, FlxColor.CYAN, "center");
		add(percentText);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (tracker == null)
		{
			close();
			return;
		}

		// Update progress bar
		var progress = tracker.getProgress();
		var barWidth = progressBarBg.width;
		progressBarFilled.scale.x = barWidth * Math.max(0, Math.min(1, progress));

		// Update counters
		var loaded = tracker.getLoadedItems();
		var total = tracker.getTotalItems();
		progressText.text = loaded + " / " + total + " songs";

		var percentage = Math.round(progress * 100);
		percentText.text = percentage + "%";

		// Update spinner angle (for potential animation)
		spinnerAngle += spinnerSpeed * elapsed;
		if (spinnerAngle >= 360)
			spinnerAngle -= 360;

		// Close automatically when complete (only set once)
		if (tracker.isComplete() && !hasStartedCloseDelay)
		{
			hasStartedCloseDelay = true;
			closeDelay = 0.5;
		}

		// Handle manual dismiss with ESC
		if (ClientPrefs.data.allowScrollDuringLoad)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				close();
				if (onCloseCallback != null)
					onCloseCallback();
			}
		}

		// Handle delayed close
		if (closeDelay > 0)
		{
			closeDelay -= elapsed;
			if (closeDelay <= 0)
			{
				close();
				if (onCloseCallback != null)
					onCloseCallback();
			}
		}
	}
}
