package backend;

import backend.window.CppAPI;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import backend.PsychCamera;
import substates.StickerSubState;
import backend.Song;
import flixel.tweens.FlxTween;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.5, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
		if (reopen)
		{
			reopen = false;
			openSubState(emptyStickers);
			//trace('reopened stickers');
		}
		TransitionState.currenttransition = null;
		transitionCheck = TransitionState.requiredTransition;
		if (TransitionState.requiredTransition != null)
		{
			TransitionState.transitionState(TransitionState.requiredTransition.state, TransitionState.requiredTransition.options, TransitionState.requiredTransition.args, TransitionState.requiredTransition.required);
			TransitionState.requiredTransition = null;
			new FlxTimer().start(1, function(e) {
				if (TransitionState.currenttransition == null && !TransitionState.isTransitioning)
				{
					var tr = transitionCheck;
					trace('transition failed');
					TransitionState.transitionState(tr.targetState, tr.options, tr.args, tr.required);
				}
				{

				}
			});
		}
	}

	public static var transitionCheck:Dynamic = null;

	public static var emptyStickers:StickerSubState = null;
	public static var reopen:Bool = false;
	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	var zoomies:Float = 1.025;
	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		if (TransitionState.currenttransition != null && !TransitionState.isTransitioning)
		{
			TransitionState.currenttransition = null;
		}
		EventFunc.updateAll();
		if (Main.audioDisconnected && getState() == PlayState.instance)
		{
			//Save your progress and THEN reset it (I knew there was a common use for this)
			//Doesn't save your exact spot, nor does it save anything but the place of your song, but i can work on that later
			PlayState.instance.triggerEvent('Save Song Posititon', null, null);
			FlxG.resetState();
		}
		else if (Main.audioDisconnected) FlxG.resetState();
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		backend.window.WindowUtils.updateTitle();

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	    /**
     * Plays music and sets the BPM for the Conductor.
     * @param musicPath The path to the music file.
     * @param bpm The beats per minute to set for the Conductor.
     * @param volume The volume for the music (0 to 1). Optional, defaults to 1.
     */
	 public function playMusic(musicPath:String, bpm:Float, volume:Float = 1):Void {
        // Stop any currently playing music
        if (FlxG.sound.music != null && FlxG.sound.music.playing) {
            FlxG.sound.music.stop();
        }

        // Play the new music track
        FlxG.sound.playMusic(Paths.music(musicPath), volume);

        // Change the BPM in the Conductor
        Conductor.bpm = bpm;
    }

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function playSong(storyPlaylist:Array<String>, storyMode:Bool = false, difficulty:Int = 0, ?transition:String, ?type:String = null, ?manualDiff:Array<String> = null):Void {
		var songs:Array<SwagSong> = [];

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
			PlayState.storyPlaylist = songs.map(function(song:SwagSong):String {
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

	public static function switchState(nextState:FlxState = null, noStick:Bool = false) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}
		


		MusicBeatState.reopen = !noStick;
		if(FlxTransitionableState.skipNextTransIn) {FlxG.switchState(nextState); FlxTransitionableState.skipNextTransIn = false;}
		else 
		{
			//trace("Transitioning to ${nextState} with random transition: ${options}");
			TransitionState.transitionState(Type.getClass(nextState), {
				transitionType: (function() {
					var transitions = ["fadeOut", "fadeColor", "slideLeft", "slideRight", "slideUp", "slideDown", "slideRandom", "fallRandom", "fallSequential", "stickers"];
					var options:Array<Chance> = [];
				
					for (transition in transitions) {
						var chance:Float;
						if (transition == "stickers") {
							// Assign a random chance between 70% and 100% for "stickers"
							if (!noStick) chance = 70 + Math.random() * 30;
							else chance = 0;
						} else {
							// Assign a random chance between 1% and 5% for other transitions
							chance = 1 + Math.random() * 4;
						}
						options.push({item: transition, chance: chance});
					}
				
					return ChanceSelector.selectOption(options);
				})()
			});
			trace("Transition complete");
		}
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) {FlxG.resetState(); FlxTransitionableState.skipNextTransIn = false;}
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));
		if(nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public static var cueReset:Bool = false;
	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.instance != null && PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}