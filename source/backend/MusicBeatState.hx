package backend;

import haxe.ds.HashMap;
import backend.window.CppAPI;
import flixel.FlxState;
import backend.PsychCamera;
import archipelago.APEntryState;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	public static var APFlip:Bool = false;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public static var pubCurDecStep:Float = 0;
	public static var pubCurDecBeat:Float = 0;

	public static var playErrorSound:Bool = false;

	public function handleFileDrop(file:String)
	{
		// trace('dropped files: ' + files);
		// This can be added to the state that needs it, and handle any files dropped.
	}

	override public function destroy()
	{
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
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized)
			initPsychCamera();

		super.create();

		// if (backend.window.CppAPI.getWindowOpacity()!=1)
		#if windows

		if (firstRun) {
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
			debug.FPSCounter.initMemory = this.sizeIn(yutautil.CollectionUtils.Size.Bytes, {verbose: ClientPrefs.data.showProgressInCMD, showObjects: false, showStack: false, showCurrent: false});
			trace('Initial memory usage: ' + debug.FPSCounter.initMemory);
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

	override function update(elapsed:Float)
	{
		if (emergencyOpacityFix) {
			CppAPI.setWindowOppacity(1);
			emergencyOpacityFix = false;
		}

		if (Main.audioDisconnected && getState() == PlayState.instance)
		{
			//Save your progress and THEN reset it (I knew there was a common use for this)
			//Doesn't save your exact spot, nor does it save anything but the place of your song, but i can work on that later
			PlayState.instance.triggerEvent('Save Song Posititon', null, null);
			FlxG.resetState();
		}
		else if (Main.audioDisconnected) FlxG.resetState();
		
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

		super.update(elapsed);
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

	public static function playSong(storyPlaylist:Array<String>, storyMode:Bool = false, difficulty:Int = 0, ?transition:String, ?type:String = null, ?manualDiff:Array<String> = null):Void {
		var songs:Array<backend.Song.SwagSong> = [];

		if (storyPlaylist.length > 1) {
			storyMode = true;
		}
		Difficulty.resetList();
		if (manualDiff != null) Difficulty.list = manualDiff;

		if (storyMode) {
			for (songPath in storyPlaylist) {
				var songLowercase:String = Paths.formatToSongPath(songPath);
				var formattedSong:String = Highscore.formatSong(songLowercase, difficulty);
				songs.push(Song.loadFromJson(formattedSong, songLowercase));
			}
			PlayState.storyPlaylist = songs.map(function(song:backend.Song.SwagSong):String {
				return song.song;
			});
			PlayState.SONG = null;
		} else {
			// songsInput is a String when storyMode is false
			var songLowercase:String = Paths.formatToSongPath(storyPlaylist[0]);
			var formattedSong:String = Highscore.formatSong(songLowercase, difficulty);
			PlayState.SONG = Song.loadFromJson(formattedSong, songLowercase);
		}

		PlayState.isStoryMode = storyMode;
		PlayState.storyDifficulty = difficulty;

		// Additional setup for PlayState as needed

		// Transition to PlayState
		switch (transition) {
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
	var preloadFunctions:Map<String, (FlxState)->Void> = [
		"PlayState" => function(state:FlxState) {
			if (state is PlayState) {
				@:privateAccess
				(cast state:PlayState).preGenerateNotes();
			}
		},
		"FreeplayState" => function(state:FlxState) {

				FreeplayManager.reloadFreeplay();

		},
		"OsuFreeplayState" => function(state:FlxState) {
				FreeplayManager.reloadFreeplay();
		}
	];

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
				try {
					preloadFunction(state);
				} catch (e:Dynamic) {
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

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
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
}
