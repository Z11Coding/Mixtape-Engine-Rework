package debug;

#if projection_probe
import backend.ClientPrefs;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import haxe.Json;
import managers.MegaManager;
import managers.PlayfieldManager;
import managers.ScriptManager;
import objects.notes.ExtraKeys;
import objects.notes.Note;
import objects.notes.Strumline;
import objects.notes.SustainNote;
import sys.io.File;

/** Real GPU hold coverage: vanilla/modchart, regular/pixel, 4K/18K, both scroll directions. */
@:access(objects.notes.SustainNote)
@:access(states.PlayState)
class SustainRegressionState extends FlxState
{
	var line:Strumline;
	var gameplay:states.PlayState;
	var label:FlxText;
	var cases:Array<{pixel:Bool, mania:Int, down:Bool, modded:Bool}> = [];
	var phase:Int = -1;
	var tick:Int;
	var checks:Int = 0;
	var name:String;
	override public function create():Void
	{
		super.create();
		FlxG.autoPause = false;
		FlxG.sound.volume = 0;
		FlxG.mouse.enabled = FlxG.mouse.visible = FlxG.keys.enabled = false;
		FlxG.camera.bgColor = 0xFF151923;
		MegaManager.playfield = new PlayfieldManager();
		MegaManager.playfield.skipArrowStartTween = true;
		MegaManager.scriptManager = new ScriptManager();
		MegaManager.conductor = new backend.RConductor();
		// Exercise the real hold lifetime method without starting a song/menu.
		gameplay = Type.createEmptyInstance(states.PlayState);
		gameplay.conductor = MegaManager.conductor;
		gameplay.playfield = MegaManager.playfield;
		gameplay.cpuControlled = false;
		gameplay.noteKillOffset = 350;
		for(pixel in [false,true]) for(mania in [3,17]) for(down in [false,true]) for(modded in [false,true])
			cases.push({pixel:pixel,mania:mania,down:down,modded:modded});
		label = new FlxText(16,16,1240,'',18);
		FlxG.signals.postDraw.add(afterDraw);
		nextCase();
	}
	function nextCase():Void
	{
		phase++;
		if(line != null) { remove(line); line.destroy(); MegaManager.playfield.allStrumLines.resize(0); }
		if(phase == cases.length)
		{
			File.saveContent(ProjectionProbeMain.output+'/result.json', Json.stringify({passed:true,cases:cases.length,checks:checks},null,'  '));
			ProjectionProbeMain.write('PASS: '+cases.length+' sustain renderer cases, '+checks+' geometry/atlas checks.');
			Sys.exit(0);
			return;
		}
		final item = cases[phase];
		ExtraKeys.mania = item.mania;
		states.PlayState.stageUI = item.pixel ? 'pixel' : 'normal';
		ClientPrefs.data.downScroll = item.down;
		ClientPrefs.data.middleScroll = false;
		name = (item.pixel?'pixel':'regular')+'-'+(item.mania+1)+'k-'+(item.down?'down':'up')+'-'+(item.modded?'modchart':'vanilla');
		line = new Strumline({strumlinePos:FlxPoint.get(120,item.down?520:110),player:0},false,1,item.modded);
		line.active = false;
		line.x = 120;
		if(line.txtActiveMods != null) line.txtActiveMods.visible = false;
		line.alpha = 1;
		MegaManager.playfield.allStrumLines.push(line);
		for(lane in 0...(item.mania+1))
		{
			final receptor = line.getByColumn(lane);
			final nativeScale = item.pixel ? states.PlayState.daPixelZoom*ExtraKeys.pixelScales[item.mania] : ExtraKeys.scales[item.mania];
			if(Math.abs(receptor.scale.x-nativeScale)>.07 || Math.abs(receptor.targetScale-nativeScale)>.07)
				throw name+': receptor lost its native skin/mania scale';
			receptor.setPosition(line.x+line.getXPos(lane),item.down?520:110);
			receptor.formerPosition.set(receptor.x,receptor.y);
			receptor.strumExtraModData.introTweenPercentage = 1;
			final note = new Note(1000,lane,line);
			note.setupNoteData({strumTime:1000,noteData:lane,row:-1});
			note.active = false;
			line.notes.add(note);
			final hold = new SustainNote(1000,lane,800,line);
			hold.setupNoteData({strumTime:1000,noteData:lane,sustainLength:800,parentST:1000,parentSL:800,
				isSustainNote:true,isSustainEnd:true,row:-1});
			hold.active = false;
			line.sustainNotes.add(hold);
			final expectedCenterX = item.pixel ? note.frameWidth*nativeScale/2 : Std.int(note.frame.sourceSize.x*nativeScale)/2;
			final expectedCenterY = item.pixel ? note.frameHeight*nativeScale/2 : Std.int(note.frame.sourceSize.y*nativeScale)/2;
			if(Math.abs(hold.headCenterX-expectedCenterX)>.1 || Math.abs(hold.headCenterY-expectedCenterY)>.1)
				throw name+': lane '+lane+' ribbon used a different head geometry/animation cache';
			if(item.pixel)
			{
				if(lane==0) ProjectionProbeMain.write('PIXEL dimensions: head '+note.frameWidth+'x'+note.frameHeight+' scale='+note.scale+' size='+note.width+'x'+note.height+' receptor '+receptor.frameWidth+'x'+receptor.frameHeight+' scale='+receptor.scale+' size='+receptor.width+'x'+receptor.height+' zoom='+states.PlayState.daPixelZoom);
				final color:Int = ExtraKeys.keysShit.get(item.mania).get('pixelAnimIndex')[lane];
				if(hold.animation.curAnim == null || hold.animation.curAnim.frames.length == 0 || hold.animation.curAnim.frames[0] != color+18)
					throw name+': tail must use the second ENDS row for lane '+lane;
				final expected = note.frameWidth*states.PlayState.daPixelZoom*ExtraKeys.pixelScales[item.mania];
				if(Math.abs(note.width-expected)>1.1) throw name+': pixel head was scaled more than once';
			}
			if(hold.flipY != item.down) throw name+': setup lost downscroll state';
		}
		if(line.mods != null)
		{
			// A neutral mod handler must put the ribbon root on the actual head,
			// before adding any perspective/curves to the same coordinates.
			line.mods.updateStrums();
			line.updateNotes();
			for(lane in 0...(item.mania+1))
			{
				final head=line.notes.members[lane], hold=line.sustainNotes.members[lane];
				final rootX=hold.x+(hold.vertices[0]+hold.vertices[2])/2;
				final rootY=hold.y+hold.vertices[1];
				if(Math.abs(rootX-(head.x+head.width/2))>1.5 || Math.abs(rootY-(head.y+head.height/2))>1.5)
					throw name+': neutral modchart root '+rootX+','+rootY+' differs from head '+(head.x+head.width/2)+','+(head.y+head.height/2);
			}
			line.mods.addMod('3d',1); line.mods.addMod('angley',18); line.mods.addMod('drunk',.25); line.mods.sortMods();
		}
		add(line);
		remove(label); add(label);
		tick = 0;
		ProjectionProbeMain.write('CASE '+name);
	}
	override public function update(elapsed:Float):Void
	{
		tick++;
		final item = cases[phase];
		// Changing relative chart times exercises the real conductor-backed paths
		// without audio, synthetic keyboard input or changing the host clock.
		final strumTime:Float = 400-tick*10;
		for(note in line.notes.members)
		{
			note.strumTime = strumTime;
			note.visible = tick<40;
			if(line.mods == null) note.followStrum(line.getByColumn(note.noteData),1);
			if(line.mods == null && Math.abs(note.scale.x-line.getByColumn(note.noteData).scale.x)>.001)
				throw name+': head/receptor scale mismatch';
		}
		for(hold in line.sustainNotes.members)
		{
			if(!hold.alive) continue;
			hold.strumTime = strumTime;
			if(tick==40)
			{
				line.hitNote(hold);
				if(!hold.alive || hold.fullSustainLength!=800 || hold.strumTime!=strumTime) throw name+': hitting the hold destroyed/reset its ribbon';
				// Cover both flags used by the real player/opponent callbacks.
				hold.mustPress = hold.noteData % 2 == 0;
				hold.wasGoodHit = hold.mustPress;
				hold.hitByOpponent = !hold.mustPress;
				hold.hitNote = false;
			}
			if(tick>=40)
			{
				gameplay.updateLiveNote(hold);
				if(!hold.alive || !hold.hitNote || hold.missedNote || hold.fullSustainLength!=800)
					throw name+': PlayState expired a live player/opponent sustain at its head time';
			}
		}
		if(line.mods != null) { line.mods.updateSpecialMods(); line.mods.updateStrums(); }
		line.updateNotes();
		if(tick>=120)
		{
			for(hold in line.sustainNotes.members)
			{
				if(tick==120 && (hold.visible || hold.sustainLength!=0)) throw name+': completed tail did not finish clipping';
				if(tick>120 && hold.alive) throw name+': completed hold was not recycled';
			}
			return;
		}
		for(hold in line.sustainNotes.members)
		{
			final body = hold.getHoldBodyFrame(), cap = hold.getAnimationFrame(hold.animation.curAnim.name);
			if(!hold.visible || hold.vertices.length<8 || body==null || cap==null) throw name+': missing sustain mesh';
			if(Math.abs(hold.graphicHeight-360)>.01) throw name+': full extent changed while clipping';
			for(i in 0...Std.int(hold.uvtData.length/2))
			{
				final frame = i>=hold.uvtData.length/2-4 ? cap : body;
				final u=hold.uvtData[i*2],v=hold.uvtData[i*2+1];
				if(!Math.isFinite(u) || !Math.isFinite(v) || u<frame.uv.x-.00001 || u>frame.uv.width+.00001
					|| v<frame.uv.y-.00001 || v>frame.uv.height+.00001) throw name+': UV escaped hold frame';
			}
			for(value in hold.vertices) if(!Math.isFinite(value)) throw name+': nonfinite geometry';
			if(!item.modded && tick>=40)
			{
				final rootY=hold.y+hold.vertices[1];
				final receptor=line.getByColumn(hold.noteData);
				if(Math.abs(rootY-(receptor.y+hold.headCenterY))>.1) throw name+': held root drifted from receptor: '+rootY;
			}
			checks++;
		}
		label.text = name+' / '+(tick<40?'approaching':'held + clipped')+'\nReal Strumline.updateNotes; no OS input.';
	}
	function afterDraw():Void
	{
		if(tick==15 || tick==65 || tick==117) ProjectionProbeMain.capture(name+'-'+tick);
		if(tick>=122) nextCase();
	}
}
#end
