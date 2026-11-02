package debug;
#if projection_probe
import backend.ClientPrefs;
import backend.Song;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import haxe.Json;
import managers.MegaManager;
import managers.PlayfieldManager;
import managers.ScriptManager;
import objects.notes.ExtraKeys;
import objects.notes.Note;
import objects.notes.StrumNote;
import states.PlayState;
import sys.io.File;

/** Compare actual atlas frames with the declared lane map, including recycled
 * notes after a skin reload. Uses the real assets and framebuffer, not OS input. */
@:access(objects.notes.Note)
class NoteDirectionRegressionState extends FlxState
{
	var cases:Array<{pixel:Bool,mania:Int,skin:String}> = [];
	var index=0;
	var phase=0;
	var checks=0;
	var failures:Array<Dynamic> = [];
	var receptors:Array<StrumNote> = [];
	var heads:Array<Note> = [];
	var label:FlxText;
	function check(ok:Bool,lane:Int,state:String,expected:Dynamic,actual:Dynamic):Void
	{
		checks++;
		if(!ok) failures.push({caseIndex:index,mania:ExtraKeys.mania+1,pixel:PlayState.isPixelStage,
			skin:cases[index].skin,lane:lane,state:state,expected:expected,actual:actual});
	}
	override public function create():Void
	{
		super.create();
		FlxG.autoPause=false; FlxG.sound.volume=0;
		FlxG.mouse.enabled=FlxG.mouse.visible=FlxG.keys.enabled=false;
		FlxG.camera.bgColor=0xFF151923;
		MegaManager.playfield=new PlayfieldManager(); MegaManager.scriptManager=new ScriptManager();
		MegaManager.conductor=new backend.RConductor();
		ClientPrefs.data.noteSkin=ClientPrefs.defaultData.noteSkin;
		ClientPrefs.data.noteColorStyle='Default';
		ClientPrefs.data.enableColorShader=false;
		for(mania in 0...18)
		{
			for(skin in ['noteSkins/NOTE_assets','noteSkins/NOTE_assets-chip','noteSkins/NOTE_assets-future'])
				cases.push({pixel:false,mania:mania,skin:skin});
			cases.push({pixel:true,mania:mania,skin:'noteSkins/NOTE_assets'});
		}
		label=new FlxText(16,16,1240,'',18); add(label);
		FlxG.signals.postDraw.add(afterDraw);
	}
	function prefix(sprite:FlxSprite,candidates:Array<String>):String
	{
		for(candidate in candidates) for(frame in sprite.frames.frames)
			if(frame.name!=null && StringTools.startsWith(frame.name,candidate)) return candidate;
		return null;
	}
	function names(sprite:FlxSprite):Array<String>
		return sprite.animation.curAnim==null ? [] : [for(frame in sprite.animation.curAnim.frames) sprite.frames.frames[frame].name];
	override public function update(elapsed:Float):Void
	{
		if(phase!=0) return;
		if(index==cases.length)
		{
			File.saveContent(ProjectionProbeMain.output+'/result.json',Json.stringify({passed:failures.length==0,cases:cases.length,
				checks:checks,failures:failures,scope:'Actual static/pressed/confirm/head atlas frames and recycled aliases, 1K through 18K'},null,'  '));
			ProjectionProbeMain.write((failures.length==0?'PASS':'FAIL')+': '+cases.length+' direction cases, '+checks+' checks, '+failures.length+' mismatches');
			Sys.exit(failures.length==0?0:1); return;
		}
		for(sprite in receptors) {remove(sprite);sprite.destroy();} receptors=[];
		for(sprite in heads) {remove(sprite);sprite.destroy();} heads=[];
		final c=cases[index]; ExtraKeys.mania=c.mania; PlayState.stageUI=c.pixel?'pixel':'normal';
		PlayfieldManager.SONG=Song.parseJSON(Json.stringify({song:'direction-probe',format:'psych_v1',bpm:120,speed:1,
			needsVoices:false,player1:'bf',player2:'dad',gfVersion:'gf',stage:'stage',mania:c.mania,arrowSkin:c.skin,notes:[],events:[]}),null,'');
		Paths.defaultSkin=c.skin;
		final mapping=ExtraKeys.keysShit.get(c.mania), letters:Array<String>=mapping.get('letters');
		final colors:Array<Int>=mapping.get('colArray'), shapes:Array<String>=mapping.get('strumAnims');
		final directions:Array<String>=mapping.get('anims'), pixelColumns:Array<Int>=mapping.get('pixelAnimIndex');
		for(lane in 0...c.mania+1)
		{
			final receptor=new StrumNote(0,0,lane,0); receptors.push(receptor); add(receptor);
			for(state in ['static','pressed','confirm'])
			{
				receptor.playAnim(state,true);
				if(c.pixel)
				{
					final row=state=='static'?0:state=='pressed'?1:3;
					check(receptor.animation.curAnim!=null && receptor.animation.curAnim.frames[0]==pixelColumns[lane]+18*row,
						lane,state,pixelColumns[lane]+18*row,receptor.animation.curAnim==null?-1:receptor.animation.curAnim.frames[0]);
				}
				else
				{
					final suffix=state=='pressed'?' press':' confirm';
					final candidates=state=='static'?['arrow'+shapes[lane],letters[lane]+'0','arrow'+directions[lane]]
						:[letters[lane]+suffix,shapes[lane].toLowerCase()+suffix,directions[lane].toLowerCase()+suffix];
					final expected=prefix(receptor,candidates), actual=names(receptor);
					check(expected!=null && actual.length>0 && actual.filter(name -> name==null || !StringTools.startsWith(name,expected)).length==0,
						lane,state,expected,actual);
				}
			}
			receptor.setPosition(30+lane*1210/(c.mania+1),130); receptor.scale.set(.32,.32); receptor.updateHitbox();
			final note=new Note(1000,0); note.setupNoteData({strumTime:1000,noteData:0,row:-1});
			if(!c.pixel) note.reloadNote(c.skin);
			note.setupNoteData({strumTime:1000,noteData:lane,row:-1});
			heads.push(note); add(note); note.setPosition(receptor.x,350); note.scale.set(.32,.32); note.updateHitbox();
			if(c.pixel) check(note.animation.curAnim!=null && note.animation.curAnim.frames[0]==pixelColumns[lane]+18,lane,'recycled head',pixelColumns[lane]+18,note.animation.curAnim==null?-1:note.animation.curAnim.frames[0]);
			else
			{
				final expected=prefix(note,[letters[lane]+'0',ExtraKeys.colArray[colors[lane]]+'0']);
				final actual=names(note);
				check(expected!=null && actual.length>0 && StringTools.startsWith(actual[0],expected),lane,'recycled head',expected,actual);
			}
		}
		label.text=(c.mania+1)+'K / '+(c.pixel?'pixel':c.skin)+'\nTop: receptor confirmations. Bottom: heads recycled after a skin reload.';
		phase=1;
	}
	function afterDraw():Void
	{
		if(phase!=1) return;
		if(cases[index].mania==5 || cases[index].mania==17) ProjectionProbeMain.capture('direction-case-'+index);
		phase=0; index++;
	}
}
#end
