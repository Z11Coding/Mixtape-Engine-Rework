package states;

import music.Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import lime.app.Application;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
import backend.PsychCamera;
import backend.Controls;
import backend.BaseStage;
import backend.math.Vector3;
import backend.CustomFadeTransition;
import backend.TransitionState;
import backend.Highscore;
import backend.Difficulty;
import music.Song;
import music.Song.SwagSong;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var oldStep:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	private function get_controls()
		return Controls.instance;

	var _psychCameraInitialized:Bool = false;

	public static var windowNameSuffix(default, set):String = "";
	public static var windowNameSuffix2(default, set):String = ""; //changes to "Outdated!" if the version of the engine is outdated
	public static var windowNamePrefix:String = "Friday Night Funkin': Mixtape Engine";

	// better then updating it all the time which can cause memory leaks
	static function set_windowNameSuffix(value:String){
		windowNameSuffix = value;
		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2;
		return value;
	}
	static function set_windowNameSuffix2(value:String){
		windowNameSuffix2 = value;
		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2;
		return value;
	}

	override public function new() {
		super();
	}

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!_psychCameraInitialized && Type.getClassName(Type.getClass(FlxG.state)) != 'PlayState') initPsychCamera();
		
		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;

		Application.current.window.title = windowNamePrefix + windowNameSuffix + windowNameSuffix2;
	}
	
	public static var emptyStickers:substates.StickerSubState = null;
	public static var reopen:Bool = false;
	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	var zoomies:Float = 1.025;
	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		if (ClientPrefs.data.forcePriority) {
			if (utils.window.Priority.getPriority() != ClientPrefs.data.gamePriority) {
				var success:Bool = utils.window.Priority.setPriority(ClientPrefs.data.gamePriority);
				if (!success) {
					trace("Failed to set game priority");
				}
			}
		} else {
			ClientPrefs.data.gamePriority = utils.window.Priority.getPriority();
		}
		if (ClientPrefs.data.gamePriority > 5) {
			ClientPrefs.data.gamePriority = 2;
			utils.window.Priority.setPriority(2);
		}

		if (Main.audioDisconnected && getState() == PlayState.instance)
		{
			//Save your progress and THEN reset it (I knew there was a common use for this)
			//Doesn't save your exact spot, nor does it save anything but the place of your song, but i can work on that later
			PlayState.instance.triggerEvent('Save Song Posititon', null, null);
			FlxG.resetState();
		}
		else if (Main.audioDisconnected) FlxG.resetState();

		oldStep = curStep;
		timePassedOnState += elapsed;
		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
		{
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

		FlxG.autoPause = ClientPrefs.data.autoPause;

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
		//if (APEntryState.apGame != null) APEntryState.apGame.info().poll();
	}

	override function destroy()
	{	
		MemoryUtil.clearMajor();
		MemoryUtil.clearMinor();
		var clearfuck:utils.yutautil.MemoryHelper = new utils.yutautil.MemoryHelper();
		clearfuck.clearClassObject(Type.getClass(this));
		super.destroy();
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
		FlxG.resetState();
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			final beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		final lastSection:Int = curSection;
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

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		final shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
		updateBeat();
	}

	override function startOutro(onOutroComplete:()->Void):Void
	{
		if (!FlxTransitionableState.skipNextTransIn)
		{
			openSubState(new CustomFadeTransition(0.6, false));
			CustomFadeTransition.finishCallback = onOutroComplete;
			return;
		}

		FlxTransitionableState.skipNextTransIn = false;

		onOutroComplete();
	}

	public var stages:Array<BaseStage> = [];
	//runs whenever the game hits a step
	public function stepHit():Void
	{
		//trace('Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	//runs whenever the game hits a beat
	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	//runs whenever the game hits a section
	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
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
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
