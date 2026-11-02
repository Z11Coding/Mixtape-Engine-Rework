package debug;
#if projection_probe
import backend.ClientPrefs;
import backend.Controls;
import backend.Song;
import flixel.FlxG;
import flixel.FlxState;
import managers.MegaManager;
import managers.PlayfieldManager;
import objects.notes.PreloadNotes;
import objects.notes.Strumline;
import objects.notes.SustainNote;
import openfl.events.KeyboardEvent;
import states.PlayState;
import haxe.Json;
import sys.io.File;

class SustainFullGameplayProbe extends FlxState
{
  override public function create():Void
  {
    super.create();
    FlxG.autoPause=false; FlxG.mouse.enabled=FlxG.mouse.visible=false;
    ClientPrefs.loadDefaultKeys(); Controls.instance=new Controls();
    Main.fpsVar = new debug.FPSCounter();
    new MegaManager();
    ClientPrefs.data.healthMode='Mixtape'; ClientPrefs.data.downScroll=false; ClientPrefs.data.middleScroll=false;
    ClientPrefs.data.opponentStrums=true; ClientPrefs.data.showNotes=true; ClientPrefs.data.ghostTapping=true;
    ClientPrefs.data.noteSplashes=true; ClientPrefs.data.gameplaySettings.set('botplay',false);
    ClientPrefs.data.gameplaySettings.set('scrolltype','multiplicative');
    ClientPrefs.data.gameplaySettings.set('scrollspeed',1.0);
    PlayfieldManager.SONG=Song.getChart('tutorial','tutorial');
    final song=PlayfieldManager.SONG;
    song.speed=2.4; song.notes=[{sectionNotes:[[5000,0,600,''],[5000,4,600,'']],
      sectionBeats:4,sectionSteps:16,mustHitSection:true,changeBPM:false,bpm:song.bpm}];
    song.events=[];
    // Normal startup already has a menu music object before entering PlayState.
    FlxG.sound.playMusic(Paths.inst('tutorial'),0,false);
    FlxG.sound.music.stop();
    FlxG.switchState(new FullProbePlayState());
  }
}
@:access(managers.PlayfieldManager)
@:access(states.PlayState)
class FullProbePlayState extends PlayState
{
  var pressedProbe:Bool=false;
  var releasedProbe:Bool=false;
  var headHits:Int=0;
  var holdHits:Int=0;
  var elapsedProbe:Float=0;
  var afterRelease:Int=0;
  var captured:Bool=false;
  var checkedLiveHold:Bool=false;
  var finishing:Bool=false;
  override function hasModchart():Bool return Sys.getEnv('MIXTAPE_FULL_MODCHART')=='1';
  override public function create():Void
  {
    super.create();
    validateChordDirections();
    ProjectionProbeMain.write('FULL_PLAYSTATE_CREATED');
    FlxG.sound.volume=0;
    FlxG.signals.postDraw.add(snapshot);
  }
  function validateChordDirections():Void
  {
    final previous=playfield.noteRows[0][0], allowed=ghostsAllowed;
    playfield.noteRows[0][0]=[{noteData:0,noteType:''},{noteData:2,noteType:''}];
    ghostsAllowed=true;
    boyfriend.mostRecentRow=-1;
    final hit:Dynamic={noteData:2,noteType:'',row:0,mustPress:true,isSustainNote:false,animSuffix:'',nextNote:{},prevNote:{}};
    playAnim(hit,boyfriend,'singUP',true);
    if (boyfriend.getAnimationName()!='singLEFT' || boyfriend.doubleGhosts[1].animation.curAnim?.name!='singUP')
      throw 'chord primary/ghost animation direction mismatch';
    boyfriend.ghostTweenGrp[1]?.cancel(); boyfriend.doubleGhosts[1].visible=false;
    boyfriend.mostRecentRow=-1; boyfriend.dance();
    playfield.noteRows[0][0]=previous; ghostsAllowed=allowed;
  }
  override public function goodNoteHit(note:Dynamic, noteAlt:PreloadNotes=null, customStrummer:Strumline):Void
  {
    final fresh=note!=null && !note.wasGoodHit;
    final sustain=note is SustainNote;
    super.goodNoteHit(note,noteAlt,customStrummer);
    if (fresh && note.wasGoodHit)
    { if (sustain) holdHits++; else headHits++; }
  }
  override public function update(elapsed:Float):Void
  {
    elapsedProbe+=elapsed;
    if (elapsedProbe>30) throw 'full gameplay did not reach target time';
    super.update(elapsed);
    final now=conductor.musicPosition;
    final code:Int=PlayfieldManager.keysArray[3][0][0];
    if (now>=5000 && !pressedProbe)
    {
      pressedProbe=true;
      playfield.onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,true,code,code));
    }
    if (now>=5025 && now<5100 && !checkedLiveHold)
    {
      final held=playerStrumline.sustainNotes.members.filter(n -> n!=null && n.alive && n.wasGoodHit);
      if (held.length==0 || !held[0].visible || held[0].vertices.length<4) throw 'judged ribbon disappeared before its tail time';
      final cover=held[0].noteHoldSplash;
      if (cover==null || !cover.alive || !cover.visible || cover.animation.curAnim?.name!='hold'
        || !playerStrumline.holdSplashes.members.contains(cover)) throw 'hold cover did not enter the real draw/update group';
      final receptor=playerStrumline.getByColumn(0);
      if (Math.abs(cover.x-receptor.x)>1 || Math.abs(cover.y-receptor.y)>1) throw 'hold cover is displaced from receptor';
      final cpuHolds=opponentStrumline.sustainNotes.members.filter(n -> n!=null && n.alive && n.hitByOpponent);
      if (cpuHolds.length==0 || !cpuHolds[0].visible || cpuHolds[0].vertices.length<4) throw 'opponent judged ribbon disappeared before its tail time';
      checkedLiveHold=true;
    }
    if (now>=5250 && !releasedProbe)
    {
      releasedProbe=true;
      playfield.onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP,true,true,code,code));
      afterRelease=holdHits;
    }
    if (now>=5800 && !finishing)
    {
      if (!checkedLiveHold) throw 'live ribbon/cover check was skipped';
      if (headHits!=1 || afterRelease<1 || holdHits!=afterRelease || songScore<=0) throw 'full judgement failed: '+headHits+'/'+afterRelease+'/'+holdHits;
      if (opponentStrumline.getByColumn(0).alpha<0.1) throw 'full opponent receptor is invisible';
      finishing=true;
      FlxG.switchState(new FullProbeFinishedState({passed:true,headHits:headHits,holdHits:holdHits,
        modchart:playfield.isModchartSong,score:songScore,misses:songMisses,liveRibbonAndCover:true,opponentLiveRibbon:true,coverAligned:true,chordDirections:true,
        scope:'actual PlayState, countdown, audio clock, keyboard, scoring, live ribbon/VFX and state exit'}));
    }
  }
  override public function destroy():Void
  {
    FlxG.signals.postDraw.remove(snapshot);
    super.destroy();
  }

  function snapshot():Void
  {
    if (releasedProbe && !captured) { ProjectionProbeMain.capture('full-gameplay'); captured=true; }
  }
}
class FullProbeFinishedState extends FlxState
{
  var result:Dynamic;
  public function new(result:Dynamic) { super(); this.result=result; }
  override public function create():Void
  {
    super.create();
    result.stateExit=true;
    File.saveContent(ProjectionProbeMain.output+'/result.json',Json.stringify(result,null,'  '));
    ProjectionProbeMain.write('PASS FULL PLAYSTATE, HOLD VFX AND STATE EXIT: '+Json.stringify(result));
    Sys.exit(0);
  }
}
#end
