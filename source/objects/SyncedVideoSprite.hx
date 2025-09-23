package objects;

import backend.Conductor;
import flixel.addons.display.FlxPieDial;
import states.PlayState;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
#end

class SyncedVideoSprite extends FlxSpriteGroup {
	#if VIDEOS_ALLOWED
	public var finishCallback:Void->Void = null;
	public var onSkip:Void->Void = null;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;
	public var videoSprite:FlxVideoSprite;
	public var skipSprite:FlxPieDial;
	public var cover:FlxSprite;
	public var canSkip(default, set):Bool = false;

	private var videoName:String;
	public var waiting:Bool = false;

	// Sync properties
	public var syncOffset:Float = 0; // Additional offset in milliseconds
	public var creationTime:Float = 0; // When this sprite was created in conductor time
	public var isSynced:Bool = true; // Whether to sync to conductor
	private var targetStartTime:Float = 0; // When the video should start in conductor time
	private var hasStarted:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false, ?syncOffset:Float = 0, ?startImmediately:Bool = true) {
		super();

		this.videoName = videoName;
		this.syncOffset = syncOffset;
		this.creationTime = Conductor.songPosition;

		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		waiting = isWaiting;

		if (!startImmediately) {
			// If not starting immediately, calculate when it should start based on creation time + offset
			targetStartTime = creationTime + syncOffset;
		} else {
			// Start immediately, but still track timing for sync
			targetStartTime = creationTime;
		}

		if (!waiting) {
			// Add cover for non-waiting videos
			cover = new FlxSprite();
			cover.makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// Initialize sprites
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);
		if (canSkip) this.canSkip = true;

		// Callbacks
		if (!shouldLoop) videoSprite.bitmap.onEndReached.add(destroy);

		videoSprite.bitmap.onFormatSetup.add(function() {
			videoSprite.setGraphicSize(FlxG.width);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		});

		// Load and start video
		videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);

		if (startImmediately) {
			startVideo();
		}
	}

	private function startVideo():Void {
		if (hasStarted) return;

		hasStarted = true;
		if (isSynced) {
			// Calculate seek position based on conductor time
			var currentTime = Conductor.songPosition;
			var timeDiff:Num = currentTime - targetStartTime;

			if (timeDiff > 0) {
				// We're late, seek to the appropriate position
				videoSprite.bitmap.time = timeDiff;
			}
		}
	}

	public function queueStart(startTime:Float):Void {
		targetStartTime = startTime;
		hasStarted = false;
	}

	var alreadyDestroyed:Bool = false;
	override function destroy() {
		if (alreadyDestroyed) return;

		trace('SyncedVideo destroyed');
		if (cover != null) {
			remove(cover);
			cover.destroy();
		}

		if (finishCallback != null) finishCallback();
		onSkip = null;

		if (FlxG.state != null) {
			try {
				if (FlxG.state.members.contains(this))
					FlxG.state.remove(this);

				if (FlxG.state.subState != null && FlxG.state.subState.members.contains(this))
					FlxG.state.subState.remove(this);
			} catch (e) {
				trace("There was nothing to delete?");
			}
		}
		super.destroy();
		alreadyDestroyed = true;
	}

	override function update(elapsed:Float) {
		// Handle queued start
		if (!hasStarted && Conductor.songPosition >= targetStartTime) {
			startVideo();
		}

		// Handle sync updates
		if (isSynced && hasStarted && videoSprite.bitmap.isPlaying) {
			var currentTime = Conductor.songPosition;
			var expectedTime = currentTime - targetStartTime;
			var actualTime:Num = videoSprite.bitmap.time;
			var timeDiff = Math.abs(expectedTime - cast actualTime);

			// Resync if we're more than 100ms off
			if (timeDiff > 100) {
				videoSprite.bitmap.time = cast(expectedTime:Num);
			}
		}

		// Skip functionality
		if (canSkip) {
			if (Controls.instance.pressed('accept')) {
				holdingTime += elapsed;
				if (skipSprite == null) {
					skipSprite = new FlxPieDial(0, 0, 32, FlxColor.WHITE, 36, true, 24);
					skipSprite.x = FlxG.width - skipSprite.width - 20;
					skipSprite.y = FlxG.height - skipSprite.height - 20;
					skipSprite.amount = 0;
					add(skipSprite);
				}
				skipSprite.amount = holdingTime / _timeToSkip;
				if (holdingTime >= _timeToSkip) {
					trace("Video skipped");
					if (onSkip != null) onSkip();
					else destroy();
				}
			} else {
				holdingTime = Math.max(holdingTime - elapsed * 4, 0);
				if (skipSprite != null) {
					skipSprite.amount = holdingTime / _timeToSkip;
					if (holdingTime <= 0) {
						remove(skipSprite);
						skipSprite.destroy();
						skipSprite = null;
					}
				}
			}
		}

		super.update(elapsed);
	}

	public function pause():Void {
		if (videoSprite != null && videoSprite.bitmap != null)
			videoSprite.bitmap.pause();
	}

	public function resume():Void {
		if (videoSprite != null && videoSprite.bitmap != null)
			videoSprite.bitmap.resume();
	}

	public function stop():Void {
		if (videoSprite != null && videoSprite.bitmap != null)
			videoSprite.bitmap.stop();
	}

	function set_canSkip(value:Bool):Bool {
		canSkip = value;
		if (!canSkip && skipSprite != null) {
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
			holdingTime = 0;
		}
		return canSkip;
	}

	public function play():Void {
		startVideo();
	}
	#end
}
