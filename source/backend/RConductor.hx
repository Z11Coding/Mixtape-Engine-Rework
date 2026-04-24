package backend;

import backend.Song.SwagSong;
import flixel.addons.sound.FlxRhythmConductor.RhythmSignal;

class RConductor extends FlxRhythmConductor {
  // TODO: Connect all the fun FNF stuff to the Rhythm Condoctor through this

  public static var instance:RConductor;


  //Modchart System Stuff
  public static var visualPosition:Float = 0;

  public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds
	public static var bpmChangeMap:Array<MusicTimeChangeEvent> = [];
  public static var crochet:Float = ((60 / instance.currentBpm) * 1000);
  public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

  private inline static final _internalJackLimit:Float = 192 / 16;
	public static var jackLimit(get, default):Float = -1;
	@:noCompletion static function get_jackLimit()
		return (jackLimit < 0) ? (jackLimit = RConductor.stepCrochet / _internalJackLimit) : jackLimit;

	public static var ROWS_PER_BEAT = 48; // from Stepmania

  override function new() {
    super();
    instance = this;
    addBeatCallback((beat:Int, backward:Bool) ->
    {
      stagesFunc(function(stage:BaseStage)
      {
        stage.curBeat = instance.currentBeat;
        stage.curDecBeat = instance.beatLengthMs;
        stage.beatHit();
      });
    });

    addStepCallback((beat:Int, backward:Bool) ->
    {
      stagesFunc(function(stage:BaseStage)
      {
        stage.curStep = instance.currentStep;
        stage.curDecStep = instance.stepLengthMs;
        stage.stepHit();
      });
    });

    addSectionCallback((beat:Int, backward:Bool) ->
    {
      stagesFunc(function(stage:BaseStage)
      {
        stage.curSection = instance.currentMeasure;
        stage.sectionHit();
      });
    });
  }

  public function playSong(songPath:String) {
    loadMetaFromFilePath(songPath);
    FlxG.sound.playMusic(songPath, 1, false);
  }

  public function addStepCallback(func:RhythmSignal<Int>)
    this.onStepHit.add(func);

  public function addBeatCallback(func:RhythmSignal<Int>)
    this.onBeatHit.add(func);

  public function addSectionCallback(func:RhythmSignal<Int>)
    this.onMeasureHit.add(func);

  public inline static function secsToRow(sex:Float):Int
		return Math.round(this.currentBeat * ROWS_PER_BEAT);

  public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if(song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:MusicTimeChangeEvent = new MusicTimeChangeEvent(
					totalPos,
					curBPM
        );
				bpmChangeMap.push(event);
			}

			if ((song.notes[i].bpmT && song.notes[i].endBPM != null && song.notes[i].startBPM != null) && song.notes[i].endBPM != song.notes[i].startBPM)
			{
				var tween:MusicTimeChangeEvent = new MusicTimeChangeEvent(
          totalPos,
          song.notes[i].endBPM,
					song.notes[i].sectionSteps,
          song.notes[i].sectionBeats,
					(song.notes[i].endTime - song.notes[i].startTime),
          'Linear'
        );
				bpmChangeMap.push(tween);
			}

			var deltaSteps:Int = Math.round(getSectionSteps(song, i) * getSectionBeats(song, i));
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
    trace("new BPM map BUDDY " + bpmChangeMap);
	}

  static function getSectionBeats(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;
		if(song.notes[section] != null) val = song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}

	static function getSectionSteps(song:SwagSong, section:Int)
	{
		var val:Null<Float> = null;
		if(song.notes[section] != null) val = song.notes[section].sectionSteps;
		return val != null ? val : 4;
	}

  inline public static function calculateCrochet(bpm:Float){
		return (60/bpm)*1000;
	}
}
