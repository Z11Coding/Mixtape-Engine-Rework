package debug;
#if projection_probe
import backend.ClientPrefs;
import backend.Controls;
import backend.RConductor;
import backend.Song;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import haxe.Json;
import managers.MegaManager;
import managers.PlayfieldManager;
import managers.ScriptManager;
import objects.notes.ExtraKeys;
import objects.notes.Note;
import objects.notes.Strumline;
import objects.notes.SustainNote;
import openfl.events.KeyboardEvent;
import states.PlayState;
import sys.io.File;

/** Loads JSON through Song/PlayfieldManager and sends real engine keyboard events.
 * Scoring/characters are isolated by InputProbePlayState; rendering/input are production code. */
@:access(managers.PlayfieldManager)
@:access(states.PlayState)
@:access(objects.notes.SustainNote)
@:access(objects.notes.Strumline)
@:access(flixel.addons.sound.FlxRhythmConductor)
class SustainGameplayRegressionState extends backend.MusicBeatState
{
  var manager:PlayfieldManager;
  var game:InputProbePlayState;
  var cases:Array<{pixel:Bool, mania:Int, down:Bool, modded:Bool, middle:Bool}> = [];
  var index:Int = 0;
  var checks:Int = 0;
  var ready:Bool = false;
  var silentTrack:flixel.sound.FlxSound;
  function check(ok:Bool, text:String):Void { checks++; if (!ok) throw 'case '+index+': '+text; }
  override public function create():Void
  {
    FlxG.autoPause = false;
    FlxG.sound.volume = 0;
    FlxG.mouse.enabled = FlxG.mouse.visible = false;
    FlxG.keys.enabled = false;
    ClientPrefs.loadDefaultKeys(); Controls.instance = new Controls();
    silentTrack = new flixel.sound.FlxSound().loadEmbedded(Paths.inst("tutorial"));
    RConductor.safeZoneOffset = 166;
    ClientPrefs.data.ghostTapping = true;
    ClientPrefs.data.noteColorStyle = 'Default';
    ClientPrefs.data.noteOffset = 0;
    ClientPrefs.data.opponentStrums = true;
    ClientPrefs.data.showNotes = true;
    ClientPrefs.data.gameplaySettings.set('scrolltype', 'multiplicative');
    ClientPrefs.data.gameplaySettings.set('scrollspeed', 1.0);
    for (pixel in [false,true]) for (mania in [3,5,8,17]) for (down in [false,true])
      for (modded in [false,true]) for (middle in [false,true])
        cases.push({pixel:pixel,mania:mania,down:down,modded:modded,middle:middle});
    FlxG.signals.postDraw.add(afterDraw);
  }
  function time(now:Float):Void
  {
    @:bypassAccessor MegaManager.conductor.musicPosition = now;
    @:bypassAccessor MegaManager.conductor.frameMusicPosition = now;
  }
  override public function update(elapsed:Float):Void
  {
    if (ready) return;
    if (index == cases.length)
    {
      File.saveContent(ProjectionProbeMain.output+'/result.json', Json.stringify({passed:true,cases:cases.length,checks:checks,
        scope:'JSON loader, keyboard press/hold/release, speed/layout/visibility; scoring callbacks isolated'},null,'  '));
      ProjectionProbeMain.write('PASS: '+cases.length+' gameplay-path cases, '+checks+' assertions'); Sys.exit(0); return;
    }
    final c=cases[index];
    if (manager != null) for (line in manager.allStrumLines) { remove(line); line.destroy(); }
    manager = new PlayfieldManager(); MegaManager.playfield = manager;
    MegaManager.scriptManager = new ScriptManager(); MegaManager.conductor = new RConductor();
    scripts = MegaManager.scriptManager;
    MegaManager.conductor.target = silentTrack;
    game = new InputProbePlayState(); PlayState.instance=game;
    game.playfield=manager; game.conductor=MegaManager.conductor;
    game.startedCountdown=true; game.generatedMusic=true; game.startedSong=false;
    game.cpuControlled=false; game.canPause=true;
    ExtraKeys.mania=c.mania; PlayState.stageUI=c.pixel?'pixel':'normal';
    ClientPrefs.data.downScroll=c.down; ClientPrefs.data.middleScroll=c.middle;
    PlayfieldManager.pressedGameplayKeys=[];
    manager.isModchartSong=c.modded; manager.skipArrowStartTween=false;
    final pos=FlxPoint.get(42,c.down?570:50);
    manager.playerStrums=new Strumline({strumlinePos:pos,player:1},true,1,c.modded);
    manager.opponentStrums=new Strumline({strumlinePos:pos,player:0},false,1,c.modded);
    manager.allStrumLines=[manager.opponentStrums,manager.playerStrums];
    for (line in manager.allStrumLines) { line.active=false; add(line); line.onNoteIncoming.add(function(_){}); }
    final count=c.mania+1;
    PlayfieldManager.keysArray[c.mania] = [for (lane in 0...count) [cast (65+lane)]];
    final notes:Array<Dynamic>=[];
    for (lane in 0...count) { notes.push([1000,lane,375,'']); notes.push([1000,lane+count,375,'']); }
    PlayfieldManager.SONG=Song.parseJSON(Json.stringify({song:'sustain-flow-probe',format:'psych_v1',bpm:120,speed:2.4,
      needsVoices:false,offset:0,player1:'bf',player2:'dad',player4:'',player5:'',gfVersion:'gf',stage:'stage',mania:c.mania,
      notes:[{sectionNotes:notes,sectionBeats:4,sectionSteps:16,mustHitSection:true,changeBPM:false,bpm:120}],events:[]}),null,'');
    manager.loadChart();
    check(Math.abs(manager.playerStrums.scrollSpeed-2.4)<0.0001,'loader did not synchronize scroll speed');
    check(manager.playerStrums.unspawnNotes.length==count*4,'loader must emit one head and exactly three sustain segments per lane');
    game.startReceptorIntro();
    // Advance tween frames normally; a single oversized step skips VarTween's delayed start values.
    for (frame in 0...720) FlxTween.globalManager.update(1.0/60.0);
    time(900);
    for (line in manager.allStrumLines)
    {
      if (line.mods != null) { line.mods.updateSpecialMods(); line.mods.updateStrums(); }
      line.updateNotes();
      var previous=-1e6;
      for (receptor in line.strumLineNotes.members)
      {
        check(receptor.alpha>.1,'opponent/player receptor never finished entering');
        check(receptor.x>previous,'lanes overlapped/reversed'); previous=receptor.x;
        check(receptor.x>=-1 && receptor.x+receptor.width<=FlxG.width+1,'multikey receptor outside screen');
      }
    }
    final player=manager.playerStrums;
    for (n in player.notes.members) { if (player.mods==null) n.followStrum(player.getByColumn(n.noteData),player.scrollSpeed); }
    final head=player.notes.members.filter(n -> n.alive && n.noteData==count-1 && n.strumTime==1000)[0];
    final hold=player.sustainNotes.members.filter(h -> h.alive && h.noteData==count-1 && h.strumTime==1000)[0];
    check(Math.abs((hold.x+(hold.vertices[0]+hold.vertices[2])/2)-(head.x+head.width/2))<2,'approach head/root X mismatch');
    check(Math.abs((hold.y+hold.vertices[1])-(head.y+head.height/2))<2,'approach head/root Y mismatch');
    manager.songSpeed=3.25;
    check(player.scrollSpeed==3.25 && manager.opponentStrums.scrollSpeed==3.25,'live global speed diverged');
    head.multSpeed=hold.multSpeed=1.3;
    hold.triggerRedraw();
    time(940);
    player.updateNotes();
    if (player.mods==null) head.followStrum(player.getByColumn(head.noteData),player.scrollSpeed);
    check(Math.abs((hold.y+hold.vertices[1])-(head.y+head.height/2))<2,'speed or multSpeed changed head/ribbon travel differently');
    time(1000);
    for (lane in 0...count)
    {
      final code:Int=PlayfieldManager.keysArray[c.mania][lane][0];
      manager.onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,true,code,code));
    }
    check(game.headHits==count && game.holdHits==count,'keyboard did not hit each head and first segment once (including lanes above 8)');
    time(1125);
    manager.keysCheck();
    check(game.holdHits==count*2,'holding did not consume due sustain segments');
    for (lane in 0...count)
    {
      final code:Int=PlayfieldManager.keysArray[c.mania][lane][0];
      manager.onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP,true,true,code,code));
    }
    manager.keysCheck();
    time(1250);
    manager.keysCheck();
    check(game.holdHits==count*2,'released lane kept consuming sustains');
    check(!player.isKeyHeld(count-1),'physical key remained latched after release');
    ProjectionProbeMain.write('CASE '+index+' '+Json.stringify(c)+' hits='+game.headHits+'/'+game.holdHits);
    ready=true;
  }
  function afterDraw():Void
  {
    if (!ready) return;
    if (index==0 || index==56 || index==62) ProjectionProbeMain.capture('flow-'+index);
    index++; ready=false;
  }
}
class InputProbePlayState extends PlayState
{
  public var headHits:Int=0;
  public var holdHits:Int=0;
  override public function goodNoteHit(note:Dynamic, noteAlt:objects.notes.PreloadNotes=null, customStrummer:Strumline):Void
  {
    if (note==null || note.wasGoodHit) return;
    if (!note.alive || note.noteData<0) throw 'judgement received recycled note';
    note.wasGoodHit=true;
    if (note is SustainNote) holdHits++; else headHits++;
  }
}
#end
