package backend;

import archipelago.APEntryState;
import backend.GarbageController;
import backend.PsychCamera;
import backend.StateTracker;
import flixel.FlxState;
import haxe.ds.HashMap;
import yutautil.AprilFools;
import yutautil.save.ObjectSerializer;
#if windows
import backend.window.CppAPI;
#end
#if debug
import debug.DebugManager;
#end

@:access(MusicBeatState)
class UnsupportedStateClass<T:FlxState> extends MusicBeatState {
	var value:T;
	public function new(value:T) {
		this.value = value;
		super();
	}

	override public function create() {
		super.create();
		trace("Warning: UnsupportedStateClass instantiated for " + Type.getClassName(Type.getClass(value)) + ". This state cannot be used directly.");
		backend.TransitionState.transitionState(value,{transitionType: MusicBeatState.getRandomTransition()});
	}
}
@:access(MusicBeatState)
class MBSubstateClass<T:MusicBeatSubstate> extends MusicBeatState {
	var value:T;
	public function new(value:T) {
		this.value = value;
		super();
	}

	override public function create() {
		super.create();
		trace("Warning: MBSubstateClass instantiated for " + Type.getClassName(Type.getClass(value)) + ". This substate cannot be used directly.");
		backend.TransitionState.transitionState(value,{transitionType: MusicBeatState.getRandomTransition()});
	}
}


/**
 * Enum for specifying Garbage Collection behavior for states
 */
enum GCBehavior {
	AUTO; // Let MusicBeatState determine based on state type
	DISABLE; // Disable GC for this state
	ENABLE; // Enable GC for this state
	LOADING; // Use loading behavior (enable GC with cleanup)
}

@:autoBuild(yutautil.StatePick.addToDatabase(MusicBeatState))
class MusicBeatState extends yutautil.SafeManagedState
{
	/**
	 * Garbage Collection behavior for this state
	 * Override in subclasses to customize GC behavior
	 */
	public var gcBehavior:GCBehavior = AUTO;
	public var didGCBehavior:Bool = false;

	// Application closing management
	public static var isClosing:Bool = false;
	private static var closeTimer:FlxTimer;
	private static var transitionTimeout:Float = 10.0; // 10 seconds timeout

	// High Quality Trap Testing Mode
	private static var _trapTestingMode:Bool = false;
	private static var _allowedTestingStates:Array<String> = [
		"states.HighQualityTrapWaitingState",
		"states.HighQualityTrapTestState",
		"states.PlayState",
		"states.LoadingState",
		"states.MixtapeLoadingScreen"
	];

	/**
	 * Enter High Quality Trap testing mode with state restrictions
	 */
	public static function enterTrapTestingMode():Void {
		_trapTestingMode = true;
		trace("MusicBeatState: Entered High Quality Trap testing mode");
	}

	/**
	 * Exit High Quality Trap testing mode
	 */
	public static function exitTrapTestingMode():Void {
		_trapTestingMode = false;
		trace("MusicBeatState: Exited High Quality Trap testing mode");
	}

	/**
	 * Check if currently in trap testing mode
	 */
	public static function isTrapTestingMode():Bool {
		return _trapTestingMode;
	}

	/**
	 * Check if a state class is allowed during trap testing mode
	 */
	public static function isStateAllowedInTesting(stateClass:Class<FlxState>):Bool {
		if (!_trapTestingMode) return true; // Not in testing mode, all states allowed

		var className = Type.getClassName(stateClass);
		return _allowedTestingStates.contains(className);
	}

	// Substate stacking system with ObjectSerializer for proper suspension/restoration
	private var substateQueue:Array<MusicBeatSubstate> = [];
	private var suspendedSubstateData:Array<{className:String, serializedData:Dynamic, originalSubstate:MusicBeatSubstate}> = [];

	private static var _apFlip:Bool = false;
	public static var APFlip(get, set):Bool;

	public static var words:Dynamic = yutautil.modules.SyncUtils.syncHttpRequestJson("https://random-word-api.herokuapp.com/all");
	public static var revokeControls(default, set):Bool = false;
	private static function set_revokeControls(value:Bool):Bool
	{
		FlxG.inputs.reset();
		FlxG.keys.enabled = !value;
		if (!value)
			Cursor.show();
		else
			Cursor.hide();
		return value;
	}

	// State Tracking System
	private static var _stateTracker:StateTracker = new StateTracker();

	/**
	 * Sets up state tracking system
	 * @param trackedState The specific state class to track variables from
	 * @param returnState The state class to return to when leaving allowed states
	 * @param allowedStates Array of state classes that are allowed without triggering return
	 * @param variablesToTrack Array of variable names to track from the tracked state
	 * @param returnArgs Optional constructor arguments for the return state
	 * @param context Optional context string for this tracking session
	 */
	public static function setupStateTracking(
		trackedState:Dynamic,
		returnState:Dynamic,
		allowedStates:Array<Dynamic>,
		variablesToTrack:Array<String>,
		?returnArgs:Array<Dynamic>,
		?context:String
	) {
		_stateTracker.setupTracking(trackedState, returnState, allowedStates, variablesToTrack, returnArgs, context);
	}

	/**
	 * Backward compatibility method - deprecated, use setupStateTracking instead
	 */
	@:deprecated("Use setupStateTracking instead")
	@:deprecated("Use setupStateTracking instead")
	public static function setAPOptionsTracking(
		returnState:Dynamic,
		allowedStates:Array<Dynamic>,
		?variablesToCapture:Array<String>,
		?stateArgs:Array<Dynamic>,
		?context:String
	) {
		// For backward compatibility, assume the first allowed state is the tracked state
		var trackedState:Dynamic = allowedStates.length > 0 ? allowedStates[0] : returnState;
		setupStateTracking(trackedState, returnState, allowedStates, variablesToCapture != null ? variablesToCapture : [], stateArgs, context);
	}

	/**
	 * Updates state tracking and checks for returns
	 * Called automatically in update()
	 */
	private static function updateStateTracking(currentState:MusicBeatState) {
		if (!_stateTracker.isActive()) return;

		// Update tracked variables from current state (only if it's the tracked state)
		_stateTracker.updateFromState(currentState);

		// Check if we should return to the return state
		_stateTracker.checkForReturn(currentState);
	}

	/**
	 * Clears state tracking
	 */
	public static function clearStateTracking() {
		_stateTracker.clear();
	}

	/**
	 * Gets tracked variables from the state tracker
	 */
	public static function getTrackedVariables():Map<String, Dynamic> {
		return _stateTracker.getTrackedVariables();
	}

	/**
	 * Clears tracked variables after they've been processed
	 */
	public static function clearTrackedVariables() {
		_stateTracker.clear();
	}

	/**
	 * Backward compatibility methods - deprecated
	 */
	@:deprecated("Use getTrackedVariables instead")
	public static function getCapturedVariables():Map<String, Dynamic> {
		return getTrackedVariables();
	}

	@:deprecated("Use clearTrackedVariables instead")
	public static function clearCapturedVariables() {
		clearTrackedVariables();
	}

	@:deprecated("Use clearStateTracking instead")
	public static function clearAPOptionsTracking() {
		clearStateTracking();
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

	public static var playErrorSound:Bool = false;
	public static var allowNuke:Bool = false;
	public static var useLite:Bool = false;

	public function handleFileDrop(file:String)
	{
		// trace('dropped files: ' + files);
		// This can be added to the state that needs it, and handle any files dropped.
	}

	override public function destroy()
	{
		// Handle state-specific GC cleanup before destruction
		handleStateExitCleanup();

		// Clean up suspended substate data
		substateQueue = [];
		suspendedSubstateData = [];
		conductor.reset();

		if (allowNuke)
			Paths.nukeMemory(useLite);
		super.destroy();
	}

	public var controls(get, never):Controls;
	public var forceCursor:Bool = false;

	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function getVariables()
		return getState().variables;

	public var conductor:RConductor = MegaManager.conductor;

	override function create()
	{
		// If a new state is created while closing, force a transition to exit
		if (isClosing) {
			FlxG.autoPause = false;
			backend.TransitionState.transitionState(states.ExitState, {transitionType: getRandomTransition()});
			return;
		}

		// Handle Garbage Collection for this state
		handleGarbageCollection();

		justgothere = true;
		allowNuke = true;
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
			debug.FPSCounter.initMemory = this.sizeIn(yutautil.CollectionUtils.Size.B, {
				verbose: ClientPrefs.data.showProgressInCMD,
				showObjects: false,
				showStack: false,
				showCurrent: false
			});
			trace('Initial memory usage: ' + debug.FPSCounter.initMemory);
		}

		if ((ClientPrefs.data.ultratrashMode || AprilFools.allowAF) && afm == null) {
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

		#if ARCHIPELAGO_ALLOWED
		// Check for pending Archipelago reconnection
		if (archipelago.APEntryState.inArchipelagoMode &&
			archipelago.APGameState.pendingReconnection &&
			archipelago.APGameState.reconnectionCallback != null) {

			trace("Pending AP reconnection detected during state switch, triggering reconnection callback");

			// Execute the reconnection callback
			archipelago.APGameState.reconnectionCallback();
		}

		// trace("State created, resetting APItem waitingForTransition flag");
		archipelago.APItem.waitingForTransition = false;
		// trace("APItem waitingForTransition flag reset to " + archipelago.APItem.waitingForTransition);


		// Update Archipelago tags on every state switch
		updateAPTags();
		#end
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
		// Update trace management system (frame-based limiting and threading)
		backend.modules.TraceManager.update();

		// Check trap testing mode restrictions
		if (_trapTestingMode && !isStateAllowedInTesting(Type.getClass(FlxG.state))) {
			trace("MusicBeatState: Attempted to switch to disallowed state during trap testing: " + Type.getClass(FlxG.state) + ". Returning to test state.");
			FlxG.switchState(new states.HighQualityTrapTestState());
			return;
		}

		// Update state tracking system
		updateStateTracking(this);

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
			resetPlayStateIfNeeded();
		}
		else if (Main.audioDisconnected)
			FlxG.resetState();
		#end

		// everyStep();
		//var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		//curStep = RConductor.instance.currentStep;
		//curBeat = RConductor.instance.currentBeat;
		//curSection = RConductor.instance.currentMeasure;

		#if ARCHIPELAGO_ALLOWED
		if (archipelago.APEntryState.inArchipelagoMode)
			archipelago.APItem.doCheck();
		#end

		/*if (oldStep != curStep)
		{
			if (curStep > 0)
				RConductor.instance.onStepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}*/

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		// Handle debug keys
		debug.DebugManager.handleDebugKeys();

		// Force cursor visibility if requested
		if (forceCursor) {
			FlxG.mouse.visible = true;
		}

		super.update(elapsed);
		conductor.update(null);

		// Handle substate queue - open the most recent substate if one exists
		if (substateQueue.length > 0 && subState == null) {
			var nextSubstate = substateQueue.pop();
			super.openSubState(nextSubstate);
		}

		if (false == true) {
			// if (FlxG.sound.music != null && FlxG.sound.music.playing) {
			// 	afm.applyFilter(FlxG.sound.music);
			// }

			// done like this so that it actually does it once as to not blow out your ears lol
		// 	if (getState() == PlayState.instance) {
		// 		for (vocal in [PlayState.instance.vocals, PlayState.instance.opponentVocals, PlayState.instance.gfVocals]) {
		// 			if (vocal != null && vocal.playing) {
		// 				afm.applyFilter(vocal);
		// 			}
		// 		}
		// 	}

		// 	for (sound in FlxG.sound.list) {
		// 		if (sound != null && sound.playing) {
		// 			afm.applyFilter(sound);
		// 		}
		// 	}
		}

		#if ARCHIPELAGO_ALLOWED
		if (APEntryState.apGame != null && APEntryState.inArchipelagoMode)
			APEntryState.apGame.info()?.poll();
		#end
	}

	/*private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			RConductor.instance.onMeasureHit();
		}
	}

	private function rollbackSection():Void
	{
		if (RConductor.instance.currentMeasure < 0)
			return;

		var lastSection:Int = RConductor.instance.currentMeasure;
		RConductor.instance.currentMeasure = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				RConductor.instance.currentMeasure++;
			}
		}

		if (RConductor.instance.currentMeasure > lastSection)
			RConductor.instance.onMeasureHit();
	}*/

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
			PlayfieldManager.SONG = null;
		}
		else
		{
			// songsInput is a String when storyMode is false
			var songLowercase:String = Paths.formatToSongPath(storyPlaylist[0]);
			var formattedSong:String = Highscore.formatSong(songLowercase, difficulty);
			PlayfieldManager.SONG = Song.loadFromJson(formattedSong, songLowercase);
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
		PlayfieldManager.SONG = Song.loadFromJson(formattedSong, songLowercase);

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
				//@:privateAccess
				//(cast state : PlayState).preGenerateNotes();
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

		MusicBeatState.switchState(state);
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


		if (AprilFools.allowAF && FlxG.random.bool(7))
		{
			AprilFools.showFakeCrashMessage(nextState);
		}


		// Check for pending Archipelago reconnection
		if (!(FlxG.state is PlayState))
		if (archipelago.APEntryState.inArchipelagoMode &&
			archipelago.APGameState.pendingReconnection &&
			archipelago.APGameState.reconnectionCallback != null) {

			trace("Pending AP reconnection detected during state switch, triggering reconnection callback");

			// Store the target state for after reconnection
			archipelago.APGameState.reconnectionTargetState = nextState;

			// Execute the reconnection callback
			archipelago.APGameState.reconnectionCallback();
			return; // Don't proceed with normal state transition yet
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
		// TODO: figure out why this sometimes doesn't work in the game over substate
		/*if (FlxG.random.bool(5) && !FlxTransitionableState.skipNextTransIn)
		{
			// Use TransitionState with random transition type for reset
			var currentStateClass = Type.getClass(FlxG.state);
			TransitionState.transitionState(currentStateClass, {
				transitionType: getRandomTransition()
			});
			return;
		}*/

		// Check if we're resetting PlayState with preloadSong enabled
		if (Std.isOfType(FlxG.state, PlayState) && ClientPrefs.data.preloadSong)
		{
			// Create new PlayState instance with playlist data if applicable
			var playState = cast(FlxG.state, PlayState);
			var playlistMeta = PlayState.isPlaylist ? playState.curPlaylist : null;
			var songlistMeta = PlayState.isPlaylist ? playState.curSonglist : null;

			PlayState.nextReloadAll = true;

			#if ARCHIPELAGO_ALLOWED
			var newState:FlxState = archipelago.APEntryState.inArchipelagoMode ?
				new archipelago.APPlayState(playlistMeta, songlistMeta) :
				new PlayState(playlistMeta, songlistMeta);
			#else
			var newState:FlxState = new PlayState(playlistMeta, songlistMeta);
			#end

			@:privateAccess
			states.LoadingState._doingRestart = true;
			states.LoadingState.loadAndSwitchState(newState);
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	private static function resetPlayStateIfNeeded()
	{
		// Check if we're resetting PlayState with preloadSong enabled
		if (Std.isOfType(FlxG.state, PlayState) && ClientPrefs.data.preloadSong)
		{
			// Create new PlayState instance with playlist data if applicable
			var playState = cast(FlxG.state, PlayState);
			var playlistMeta = PlayState.isPlaylist ? playState.curPlaylist : null;
			var songlistMeta = PlayState.isPlaylist ? playState.curSonglist : null;

			PlayState.nextReloadAll = true;

			#if ARCHIPELAGO_ALLOWED
			var newState:FlxState = archipelago.APEntryState.inArchipelagoMode ?
				new archipelago.APPlayState(playlistMeta, songlistMeta) :
				new PlayState(playlistMeta, songlistMeta);
			#else
			var newState:FlxState = new PlayState(playlistMeta, songlistMeta);
			#end

			@:privateAccess
			states.LoadingState._doingRestart = true;
			states.LoadingState.loadAndSwitchState(newState);
		}
		else
		{
			FlxG.resetState();
		}
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));
		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() resetPlayStateIfNeeded();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState
	{
		return try
		{
		cast(FlxG.state, MusicBeatState);
		}
		catch (e:Dynamic)
		{
			if (FlxG.state is MusicBeatSubstate)
				new MBSubstateClass(cast(FlxG.state, MusicBeatSubstate));
			else
				new UnsupportedStateClass(FlxG.state);
			null;
		}
	}

	public var stages:Array<BaseStage> = [];

	@:allow(backend.RConductor)
	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	/*function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}*/

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

	/**
	 * Updates Archipelago tags to ensure they're properly set on every state switch
	 */
	private static function updateAPTags():Void
	{
		#if ARCHIPELAGO_ALLOWED
		// Only update tags if we're in Archipelago mode and have a valid client
		if (archipelago.APEntryState.inArchipelagoMode && archipelago.APEntryState.ap != null) {
			try {
				// Set base tags and add DeathLink/TrapLink based on settings
				archipelago.APEntryState.ap.updateLinkTags(ClientPrefs.data.deathlink, ClientPrefs.data.traplink);
				trace("MusicBeatState: Updated AP tags - DeathLink: " + ClientPrefs.data.deathlink + ", TrapLink: " + ClientPrefs.data.traplink);
			} catch (e:Dynamic) {
				trace("MusicBeatState: Error updating AP tags: " + e);
			}
		}
		#end
	}

	/**
	 * Handle garbage collection behavior for this state
	 */
	private function handleGarbageCollection():Void {
		if (!GarbageController.isExperimentalMode()) {didGCBehavior = true; return;}

		var behavior = determineGCBehavior();

		switch (behavior) {
			case DISABLE:
				GarbageController.disableForState();
			case ENABLE:
				GarbageController.enableForLoading(); // Uses normal enabling
			case LOADING:
				GarbageController.forceCleanupBeforeLoading();
			case AUTO:
				// AUTO behavior already handled by determineGCBehavior
		}
		didGCBehavior = true;

		while (!didGCBehavior) {
			// Enforce this flag is set.
			// This is to prevent any weird edge cases where GC behavior isn't set properly for a state, which can cause issues
			didGCBehavior = true;
			trace("Warning: GC behavior flag was not set properly.");
		}

	}

	/**
	 * Determine the appropriate GC behavior for this state
	 */
	private function determineGCBehavior():GCBehavior {
		if (gcBehavior != AUTO) return gcBehavior;

		// Auto-determine behavior based on state class
		var className = Type.getClassName(Type.getClass(this));

		// Loading states should enable GC with cleanup
		if (className.contains("LoadingState") || className.contains("LoadingScreen")) {
			return LOADING;
		}

		// PlayState and menu states should disable GC
		if (className.contains("PlayState") ||
			className.contains("MenuState") ||
			className.contains("MainMenuState") ||
			className.contains("FreeplayState") ||
			className.contains("StoryMenuState") ||
			className.contains("OptionsState") ||
			className.contains("ChartingState") ||
			className.contains("ChartEditorState")) {
			return DISABLE;
		}

		// Default to enable for other states
		return ENABLE;
	}

	/**
	 * Handle cleanup when exiting certain states
	 */
	private function handleStateExitCleanup():Void {
		if (!GarbageController.isExperimentalMode()) return;

		var className = Type.getClassName(Type.getClass(this));

		// Force cleanup after PlayState
		if (className.contains("PlayState")) {
			GarbageController.forceCleanupAfterPlayState();
		}
	}

	/**
	 * Manual GC control methods for states that need custom behavior
	 */
	public function setGCBehavior(behavior:GCBehavior):Void {
		gcBehavior = behavior;
		handleGarbageCollection();
	}

	public function disableGC():Void {
		if (GarbageController.isExperimentalMode()) {
			GarbageController.disableForState();
		}
	}

	public function enableGC():Void {
		if (GarbageController.isExperimentalMode()) {
			GarbageController.enableForLoading();
		}
	}

	public function forceGCCleanup():Void {
		if (GarbageController.isExperimentalMode()) {
			GarbageController.forceCleanupBeforeLoading();
		}
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
	}
}
