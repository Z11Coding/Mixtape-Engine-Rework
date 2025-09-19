package backend;

import archipelago.APEntryState;
import backend.PsychCamera;
import flixel.FlxState;
import haxe.ds.HashMap;
import yutautil.save.ObjectSerializer;
#if windows
import backend.window.CppAPI;
#end
#if debug
import debug.DebugManager;
#end

// @:autoBuild(yutautil.CrashTracker.instrument())

@:autoBuild(yutautil.StatePick.addToDatabase(MusicBeatState))
class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	// Application closing management
	public static var isClosing:Bool = false;
	private static var closeTimer:FlxTimer;
	private static var transitionTimeout:Float = 10.0; // 10 seconds timeout

	// Substate stacking system with ObjectSerializer for proper suspension/restoration
	private var substateQueue:Array<MusicBeatSubstate> = [];
	private var suspendedSubstateData:Array<{className:String, serializedData:Dynamic, originalSubstate:MusicBeatSubstate}> = [];

	private static var _apFlip:Bool = false;
	public static var APFlip(get, set):Bool;

	public static var words:Dynamic = yutautil.modules.SyncUtils.syncHttpRequestJson("https://random-word-api.herokuapp.com/all");
	public static var revokeControls:Bool = false;

	// AP State Tracking System
	private static var _apOptionsStateClass:Class<MusicBeatState> = null;
	private static var _apOptionsStateArgs:Array<Dynamic> = [];
	private static var _allowedStates:Array<Class<MusicBeatState>> = [];
	private static var _variablesToCapture:Array<String> = [];
	private static var _capturedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	private static var _navigationContext:String = null;

	/**
	 * Sets up state tracking for AP options system
	 * @param apOptionsStateClass The AP options state class to return to
	 * @param allowedStates Array of state classes that are allowed without triggering return
	 * @param variablesToCapture Array of variable names to capture from the current state
	 * @param stateArgs Optional constructor arguments for the AP options state
	 * @param context Optional context string to help identify the purpose of navigation
	 */
	public static function setAPOptionsTracking(apOptionsStateClass:Class<MusicBeatState>, allowedStates:Array<Class<MusicBeatState>>, ?variablesToCapture:Array<String>, ?stateArgs:Array<Dynamic>, ?context:String) {
		_apOptionsStateClass = apOptionsStateClass;
		_apOptionsStateArgs = stateArgs != null ? stateArgs.copy() : [];
		_allowedStates = allowedStates.copy();
		_variablesToCapture = variablesToCapture != null ? variablesToCapture.copy() : [];
		_navigationContext = context;
		_capturedVariables.clear();
	}

	/**
	 * Checks if we should return to AP options state
	 * Called automatically in update()
	 */
	private static function checkAPOptionsReturn(currentState:MusicBeatState) {
		if (_apOptionsStateClass == null) return;

		var currentStateClass = Type.getClass(currentState);

		// Check if current state class is in allowed states
		var isAllowed = false;
		for (allowedClass in _allowedStates) {
			if (currentStateClass == allowedClass) {
				isAllowed = true;
				break;
			}
		}

		// If current state is not in allowed states and is not the AP options state class itself
		if (!isAllowed && currentStateClass != _apOptionsStateClass) {
			// Capture variables if specified
			for (varName in _variablesToCapture) {
				try {
					var value = Reflect.field(currentState, varName);
					if (value != null) {
						_capturedVariables.set(varName, value);
					}
				} catch (e:Dynamic) {
					trace('Failed to capture variable: $varName from ${Type.getClassName(currentStateClass)}');
				}
			}

			// Store navigation context for the new state
			if (_navigationContext != null) {
				_capturedVariables.set("_navigationContext", _navigationContext);
			}

			// Create new instance of the AP options state
			var returnStateClass = _apOptionsStateClass;
			var returnStateArgs = _apOptionsStateArgs.copy();
			clearAPOptionsTracking();

			// Create new state instance
			var newState:MusicBeatState = Type.createInstance(returnStateClass, returnStateArgs);
			switchState(newState);
		}
	}

	/**
	 * Clears AP options tracking
	 */
	public static function clearAPOptionsTracking() {
		_apOptionsStateClass = null;
		_apOptionsStateArgs = [];
		_allowedStates = [];
		_variablesToCapture = [];
		_navigationContext = null;
		// Don't clear captured variables - let the AP options state handle them
	}

	/**
	 * Gets captured variables from tracked states
	 */
	public static function getCapturedVariables():Map<String, Dynamic> {
		return _capturedVariables;
	}

	/**
	 * Clears captured variables after they've been processed
	 */
	public static function clearCapturedVariables() {
		_capturedVariables.clear();
	}

	private static function get_APFlip():Bool
		return _apFlip;

	private static function set_APFlip(value:Bool):Bool
	{
		_apFlip = value;
		if (_apFlip || (yutautil.AprilFools.allowAF && FlxG.random.bool(25)))
		{
			FlxTween.tween(FlxG.camera, {angle: 180}, 0.5, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					if (FlxG.state is PlayState)
					{
						FlxTween.tween(PlayState.instance.camHUD, {angle: -180}, 0.5, {
							ease: FlxEase.quadOut,
							onComplete: function(tween:FlxTween)
							{
								FlxTween.tween(PlayState.instance.camOther, {angle: 180}, 0.5, {
									ease: FlxEase.quadOut
								});
							}
						});
					}
				}
			});
		}
		return _apFlip;
	}

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public static var pubCurDecStep:Float = 0;
	public static var pubCurDecBeat:Float = 0;
	public static var playErrorSound:Bool = false;
	public static var allowNuke:Bool = false;

	public function handleFileDrop(file:String)
	{
		// trace('dropped files: ' + files);
		// This can be added to the state that needs it, and handle any files dropped.
	}

	override public function destroy()
	{
		// Clean up suspended substate data
		substateQueue = [];
		suspendedSubstateData = [];

		if (allowNuke)
			Paths.nukeMemory();
		super.destroy();
	}

	public var controls(get, never):Controls;

	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function getVariables()
		return getState().variables;

	override function create()
	{
		// If a new state is created while closing, force a transition to exit
		if (isClosing) {
			FlxG.autoPause = false;
			backend.TransitionState.transitionState(states.ExitState, {transitionType: getRandomTransition()});
			return;
		}

		justgothere = true;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized)
			initPsychCamera();

		super.create();

		// if (!(this is PlayState) && PlayState.instance != null)
		// 	yutautil.MemoryHelper.freeMemory(PlayState.instance);

		// if (backend.window.CppAPI.getWindowOpacity()!=1)
		#if windows
		if (firstRun)
		{
			FlxTween.num(0, 1, 0.5, {
				ease: FlxEase.sineInOut,
				onComplete: function(tween:FlxTween)
				{
					#if cpp
					backend.window.CppAPI.setWindowOpacity(1);
					#end
					firstRun = false;
				}
			}, function(num)
			{
				CppAPI.setWindowOpacity(num);
			});
		}
		#end

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.5, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
		if (reopen)
		{
			reopen = false;
			openSubState(emptyStickers);
			// trace('reopened stickers');
		}
		TransitionState.currenttransition = null;
		transitionCheck = TransitionState.requiredTransition;
		if (TransitionState.requiredTransition != null)
		{
			TransitionState.transitionState(TransitionState.requiredTransition.state, TransitionState.requiredTransition.options,
				TransitionState.requiredTransition.args, TransitionState.requiredTransition.required);
			TransitionState.requiredTransition = null;
			new FlxTimer().start(1, function(e)
			{
				if (TransitionState.currenttransition == null && !TransitionState.isTransitioning)
				{
					var tr = transitionCheck;
					trace('transition failed');
					TransitionState.transitionState(tr.targetState, tr.options, tr.args, tr.required);
				}
				{}
			});
		}
		if (playErrorSound)
		{
			playErrorSound = false;
			FlxG.sound.play(Paths.sound('error'), 1, false);
		}
		if (APFlip || (yutautil.AprilFools.allowAF && FlxG.random.bool(25)))
		{
			FlxTween.tween(FlxG.camera, {angle: 180}, 0.5, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					if (this is PlayState)
					{
						FlxTween.tween(PlayState.instance.camHUD, {angle: -180}, 0.5, {
							ease: FlxEase.quadOut,
							onComplete: function(tween:FlxTween)
							{
								FlxTween.tween(PlayState.instance.camOther, {angle: 180}, 0.5, {
									ease: FlxEase.quadOut
								});
							}
						});
					}
				}
			});
		}
		emergencyOpacityFix = true;

		if (ClientPrefs.data.showInitialMemoryUsage && Sys.args().indexOf('-livereload') != -1)
		{
			debug.FPSCounter.initMemory = this.sizeIn(yutautil.CollectionUtils.Size.Bytes, {
				verbose: ClientPrefs.data.showProgressInCMD,
				showObjects: false,
				showStack: false,
				showCurrent: false
			});
			trace('Initial memory usage: ' + debug.FPSCounter.initMemory);
		}

		if (ClientPrefs.data.ultratrashMode && afm == null) {
			afm = new FlxSoundFilter();
			afm.filterType = FlxSoundFilterType.BANDPASS;
			afm.gain = 0;
			add(afm);

			var badqualitymic = new FlxSoundDistortionEffect();
			badqualitymic.edge = 5000;
			badqualitymic.eqBandwidth = 20000;
			badqualitymic.gain = 1;
			badqualitymic.lowpassCutoff = 0;
			badqualitymic.eqCenter = 20000;
			afm.addEffect(badqualitymic);

			effectArray.push(afm);
		}
	}

	public static var firstRun:Bool = true;
	public static var emergencyOpacityFix:Bool = false;

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		// trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	var zoomies:Float = 1.025;

	public static var transitionCheck:Dynamic = null;
	public static var emptyStickers:substates.StickerSubState = null;
	public static var reopen:Bool = false;
	public static var timePassedOnState:Float = 0;

	var allowLagAcheve:Bool = false;
	var justgothere:Bool = true;

	/**
	 * Queue a substate to be opened. If a substate is currently active,
	 * it will be suspended using ObjectSerializer and the new substate will be opened on top.
	 */
	public function queueSubstate(substate:MusicBeatSubstate):Void {
		if (subState != null && Std.isOfType(subState, MusicBeatSubstate)) {
			// Suspend current substate using ObjectSerializer
			var currentSubstate = cast(subState, MusicBeatSubstate);
			try {
				var className = Type.getClassName(Type.getClass(currentSubstate));
				var serializedData = ObjectSerializer.serialize(currentSubstate);

				suspendedSubstateData.push({
					className: className,
					serializedData: serializedData,
					originalSubstate: currentSubstate
				});

				trace('Suspended substate: ${className}');
			} catch (e:Dynamic) {
				trace('Warning: Failed to serialize substate for suspension: ${e}');
				// Fallback to simple reference storage if serialization fails
				suspendedSubstateData.push({
					className: "Unknown",
					serializedData: null,
					originalSubstate: currentSubstate
				});
			}

			closeSubState();
		}

		substateQueue.push(substate);
	}

	/**
	 * Clear all suspended substates (useful for cleanup or when you want to prevent restoration)
	 */
	public function clearSuspendedSubstates():Void {
		suspendedSubstateData = [];
		trace('Cleared all suspended substate data');
	}

	/**
	 * Get the number of currently suspended substates
	 */
	public function getSuspendedSubstateCount():Int {
		return suspendedSubstateData.length;
	}

	/**
	 * Override openSubState to work with the stacking system
	 */
	/*override public function openSubState(subState:flixel.FlxSubState):Void {
		if (Std.isOfType(subState, MusicBeatSubstate)) {
			queueSubstate(cast(subState, MusicBeatSubstate));
		} else {
			super.openSubState(subState);
		}
	}*/

	/**
	 * Override closeSubState to restore suspended substates using ObjectSerializer
	 */
	override public function closeSubState():Void {
		super.closeSubState();

		// If there are suspended substates, restore the most recent one
		if (suspendedSubstateData.length > 0) {
			var suspendedData = suspendedSubstateData.pop();

			try {
				var restoredSubstate:MusicBeatSubstate;

				if (suspendedData.serializedData != null) {
					// Try to restore from serialized data
					restoredSubstate = ObjectSerializer.deserialize(suspendedData.serializedData);
					if (restoredSubstate != null) {
						trace('Restored substate from serialized data: ${suspendedData.className}');
					} else {
						// Fallback to original substate reference
						restoredSubstate = suspendedData.originalSubstate;
						trace('Warning: Failed to deserialize, using original reference');
					}
				} else {
					// Fallback to original substate reference
					restoredSubstate = suspendedData.originalSubstate;
					trace('Using original substate reference for restoration');
				}

				substateQueue.push(restoredSubstate);
			} catch (e:Dynamic) {
				trace('Error restoring substate: ${e}');
				// Last resort: try to use the original substate reference
				if (suspendedData.originalSubstate != null) {
					substateQueue.push(suspendedData.originalSubstate);
					trace('Fallback: using original substate reference');
				}
			}
		}
	}

	var afm:FlxSoundFilter;
	public static var effectArray:Array<FlxSoundFilter> = [];

	override function update(elapsed:Float)
	{
		// Check AP options tracking
		checkAPOptionsReturn(this);

		// Disable all input when the application is closing
		if (isClosing) {
			// Start timer if transition is active but timer isn't running
			if (backend.TransitionState.currenttransition != null && closeTimer == null) {
				closeTimer = new FlxTimer().start(transitionTimeout, function(timer:FlxTimer) {
					// Force reset transition and try again with a different one
					trace("Transition timeout reached, forcing new transition");
					backend.TransitionState.currenttransition = null;
					closeTimer = null;
					FlxG.autoPause = false;
					backend.TransitionState.transitionState(states.ExitState, {transitionType: getRandomTransition()});
				});
			}
			// Clean up timer if transition completed naturally
			else if (backend.TransitionState.currenttransition == null && closeTimer != null) {
				closeTimer.cancel();
				closeTimer = null;
			}
			return;
		}

		// Suspend updating if debug overlay is active
		if (debug.DebugManager.isDebugOverlayVisible()) {
			// Only handle debug keys and essential systems when overlay is active
			debug.DebugManager.handleDebugKeys();
			return;
		}

		if (justgothere)
		{
			justgothere = false;
			new FlxTimer().start(5, function(e)
			{
				allowLagAcheve = true;
			});
		}
		#if windows
		if (emergencyOpacityFix)
		{
			CppAPI.setWindowOppacity(1);
			emergencyOpacityFix = false;
		}
		// TODO: Implement check to see if the window is focused, so that lag achievement doesn't trigger when the window is not focused
		if (allowLagAcheve && Main.fpsVar.lagging && !Achievements.isUnlocked('lag'))
		{
			Achievements.unlock('lag');
		}

		if (Main.audioDisconnected && getState() == PlayState.instance)
		{
			// Save your progress and THEN reset it (I knew there was a common use for this)
			// Doesn't save your exact spot, nor does it save anything but the place of your song, but i can work on that later
			PlayState.instance.triggerEvent('Save Song Posititon', null, null);
			FlxG.resetState();
		}
		else if (Main.audioDisconnected)
			FlxG.resetState();
		#end

		// everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (archipelago.APEntryState.inArchipelagoMode)
			archipelago.APItem.doCheck();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		// Handle debug keys
		debug.DebugManager.handleDebugKeys();

		super.update(elapsed);

		// Handle substate queue - open the most recent substate if one exists
		if (substateQueue.length > 0 && subState == null) {
			var nextSubstate = substateQueue.pop();
			super.openSubState(nextSubstate);
		}

		if (ClientPrefs.data.ultratrashMode) {
			if (FlxG.sound.music != null && FlxG.sound.music.playing) {
				afm.applyFilter(FlxG.sound.music);
			}

			// done like this so that it actually does it once as to not blow out your ears lol
			if (getState() == PlayState.instance) {
				for (vocal in [PlayState.instance.vocals, PlayState.instance.opponentVocals, PlayState.instance.gfVocals]) {
					if (vocal != null && vocal.playing) {
						afm.applyFilter(vocal);
					}
				}
			}

			for (sound in FlxG.sound.list) {
				if (sound != null && sound.playing) {
					afm.applyFilter(sound);
				}
			}
		}

		if (APEntryState.apGame != null && APEntryState.inArchipelagoMode)
			APEntryState.apGame.info().poll();
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function playSong(storyPlaylist:Array<String>, storyMode:Bool = false, difficulty:Int = 0, ?transition:String, ?type:String = null, ?manualDiff:Array<String> = null):Void
	{
		var songs:Array<backend.Song.SwagSong> = [];

		Difficulty.resetList();
		if (manualDiff != null)
			Difficulty.list = manualDiff;

		if (storyMode)
		{
			for (songPath in storyPlaylist)
			{
				var songLowercase:String = Paths.formatToSongPath(songPath);
				var formattedSong:String = Highscore.formatSong(songLowercase, difficulty);
				songs.push(Song.loadFromJson(formattedSong, songLowercase));
			}
			PlayState.storyPlaylist = songs.map(function(song:backend.Song.SwagSong):String
			{
				return song.song;
			});
			PlayState.SONG = null;
		}
		else
		{
			// songsInput is a String when storyMode is false
			var songLowercase:String = Paths.formatToSongPath(storyPlaylist[0]);
			var formattedSong:String = Highscore.formatSong(songLowercase, difficulty);
			PlayState.SONG = Song.loadFromJson(formattedSong, songLowercase);
		}

		PlayState.isStoryMode = storyMode;
		PlayState.storyDifficulty = difficulty;

		// Additional setup for PlayState as needed

		// Transition to PlayState
		switch (transition)
		{
			case "FlxG", "FlxG.switchState":
				FlxG.switchState(new PlayState());

			case "MusicBeatState":
				switchState(new PlayState());

			case "TransitionState":
				TransitionState.transitionState(PlayState, {
					transitionType: type
				});

			default:
				FlxG.switchState(new PlayState());
		}
	}

	// Like PlaySong, but made specifically for the Swap Trap
	public static function switchSong(song:String, difficulty:Int = 0, ?transition:String, ?type:String = null):Void
	{
		var songLowercase:String = Paths.formatToSongPath(song);
		var formattedSong:String = Highscore.formatSong(songLowercase, difficulty);
		PlayState.SONG = Song.loadFromJson(formattedSong, songLowercase);

		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = difficulty;

		// Transition to PlayState
		switch (transition)
		{
			case "FlxG", "FlxG.switchState":
				FlxG.switchState(new PlayState());

			case "MusicBeatState":
				switchState(new PlayState());

			case "TransitionState":
				TransitionState.transitionState(PlayState, {
					transitionType: type
				});

			default:
				FlxG.switchState(new PlayState());
		}
	}

	var preloadFunctions:Map<String, (FlxState) -> Void> = [
		"PlayState" => function(state:FlxState)
		{
			if (state is PlayState)
			{
				@:privateAccess
				(cast state : PlayState).preGenerateNotes();
			}
		}
		/*,
			"FreeplayState" => function(state:FlxState) {

					FreeplayManager.reloadFreeplay();

			},
			"OsuFreeplayState" => function(state:FlxState) {
					FreeplayManager.reloadFreeplay();
		}*/];

	public function hashCode():Int
	{
		return Type.getClassName(Type.getClass(this)).hashcode();
	}

	public function preloadState(switchState:Bool = false, state:FlxState, ?proceedOnError:Bool = true)
	{
		var stateClassName = Type.getClassName(Type.getClass(state)).split(".")[Lambda.count(Type.getClassName(Type.getClass(state)).split(".")) - 1];
		var preloadFunction = preloadFunctions.get(stateClassName);
		var errored = false;
		if (preloadFunction == null)
		{
			trace('No preload function for state: ' + stateClassName);
		}
		var preloader = function()
		{
			if (preloadFunction != null)
			{
				trace('Preloading state: ' + stateClassName);
				try
				{
					preloadFunction(state);
				}
				catch (e:Dynamic)
				{
					trace('Error during state preloading: ' + e);
				}
				preloadFunction = null;
			}
			if (switchState && (!errored || proceedOnError))
				return MusicBeatState.switchState(this);
		};

		var stateName = Type.getClassName(Type.getClass(state));

		yutautil.Threader.runInThread(preloader(), 1, 'State Preloader');
	}

	public static function preloadAndSwitchState(state:MusicBeatState)
	{
		if (state == null)
			state = cast(FlxG.state, MusicBeatState);
		if (state == FlxG.state)
		{
			resetState();
			return;
		}

		state.preloadState(true, state);
	}

	public static function switchState(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		// Add a "rare" chance (5%) to use TransitionState instead of normal transition
		if (FlxG.random.bool(5) && !FlxTransitionableState.skipNextTransIn && !(nextState is states.LoadingState || nextState is states.MixtapeLoadingScreen))
		{
			// Use TransitionState with random transition type
			var nextStateClass = Type.getClass(nextState);
			TransitionState.transitionState(nextStateClass, {
				transitionType: getRandomTransition()
			});
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
		// Add a rare chance (5%) to use TransitionState instead of normal transition
		if (FlxG.random.bool(5) && !FlxTransitionableState.skipNextTransIn)
		{
			// Use TransitionState with random transition type for reset
			var currentStateClass = Type.getClass(FlxG.state);
			TransitionState.transitionState(currentStateClass, {
				transitionType: getRandomTransition()
			});
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState
	{
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];

	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	private static function getRandomTransition():String
	{
		var availableTransitions:Array<String> = [
			"fadeOut", "fadeColor", "slideLeft", "slideRight",
			"slideUp", "slideDown", "slideRandom", "fallRandom",
			"fallSequential", "stickers", "melt", "instant",
			"transparent fade", "transparent close"
		];
		return FlxG.random.getObject(availableTransitions);
	}

	public static function resetClosingState():Void
	{
		isClosing = false;
		if (closeTimer != null) {
			closeTimer.cancel();
			closeTimer = null;
		}
	}
	override public function onFocusLost():Void
	{
		super.onFocusLost();
	}
}
