package states.editors.content;

import backend.modchart.ModManager;

import backend.Song;
import backend.Rating;

import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;

import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

class EditorPlayState extends MusicBeatSubstate
{
	// Borrowed from original PlayState
	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var inst:FlxSound;
	
	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	
	var comboGroup:FlxSpriteGroup;
	
	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];

	public var keysArray:Array<Dynamic>;
	public var modManager:ModManager;
	public var playerField:PlayField;
	public var dadField:PlayField;
	public var notefields = new NotefieldManager();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes

	public static var instance:EditorPlayState;
	
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;
	
	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;
	var guitarHeroSustains:Bool = false;

	var speedChanges:Array<SpeedEvent> = [];
	public var currentSV:SpeedEvent = {
		position: 0,
		startTime: 0,
		songTime: 0,
		speed: 1,
		startSpeed: 1
	};

	var _noteList:Array<Note>;
	public function new(noteList:Array<Note>, allVocals:Array<FlxSound>)
	{
		super();
		
		/* setting up some important data */
		this.vocals = allVocals[0];
		this.opponentVocals = allVocals[1];
		this._noteList = noteList;
		this.startPos = Conductor.songPosition;
		Conductor.songPosition = startPos;

		playbackRate = FlxG.sound.music.pitch;
		instance = this;
	}

	override function create()
	{
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;

		keysArray = backend.Keybinds.fill();

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);
		
		/**** NOTES ****/
		comboGroup = new FlxSpriteGroup();
		add(comboGroup);

		keysArray = backend.Keybinds.fill();
		modManager = new ModManager(this);

		playerField = new PlayField(modManager);
		playerField.modNumber = 0;
		playerField.characters = [];
		
		playerField.isPlayer = true;
		playerField.autoPlayed = false;
		playerField.isEditor = true;
		playerField.noteHitCallback = goodNoteHit;

		dadField = new PlayField(modManager);
		dadField.isPlayer = false;
		dadField.autoPlayed = true;
		dadField.isEditor = true;
		dadField.modNumber = 1;
		dadField.characters = [];
		dadField.noteHitCallback = opponentNoteHit;

		playfields.add(dadField);
		playfields.add(playerField);

		initPlayfield(dadField);
		initPlayfield(playerField);

		for (field in playfields.members)
		{
			field.keyCount = Note.ammo[PlayState.mania];
			field.generateStrums();
		}
		for (field in playfields.members)
			field.fadeIn(true); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode

		modManager.registerDefaultModifiers();
		/***************/

		speedChanges.push({
			position: 0,
			songTime: 0,
			startTime: 0,
			startSpeed: 1,
			speed: 1,
		});
		
		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);
		
		dataTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		dataTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);
		FlxG.mouse.visible = false;
		
		generateSong();
		_noteList = null;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, null, true, songLength);
		#end
		updateScore();
		cachePopUpScore();

		super.create();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	// good to call this whenever you make a playfield
	public function initPlayfield(field:PlayField)
	{
		notefields.add(field.noteField);

		field.judgeManager = ratingsData[0];

		field.noteRemoved.add((note:Note, field:PlayField) ->
		{
			allNotes.remove(note);
			unspawnNotes.remove(note);
			notes.remove(note);
		});
		field.noteMissed.add((daNote:Note, field:PlayField) ->
		{
			if (field.isPlayer && !field.autoPlayed && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
				noteMiss(daNote, field);
		});
		field.noteSpawned.add((dunceNote:Note, field:PlayField) ->
		{
			notes.add(dunceNote);
			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);
		});
	}

	public function getSV(time:Float)
	{
		var event:SpeedEvent = {
			position: 0,
			songTime: 0,
			startTime: 0,
			startSpeed: 1,
			speed: 1
		};
		for (shit in speedChanges)
		{
			if (shit.startTime <= time && shit.startTime >= event.startTime)
			{
				if (shit.startSpeed == null)
					shit.startSpeed = event.speed;
				event = shit;
			}
		}

		return event;
	}

	public function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}

	public inline function getVisualPosition()
		return getTimeFromSV(Conductor.songPosition, currentSV);

	public inline function getTimeFromSV(time:Float, event:SpeedEvent)
		return event.position + (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);

	override function update(elapsed:Float)
	{
		currentSV = getSV(Conductor.songPosition);
		Conductor.visualPosition = getVisualPosition();

		modManager.update(elapsed, curDecBeat, curDecStep);

		if(controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.F12)
		{
			endSong();
			super.update(elapsed);
			return;
		}
		
		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) startSong();
		}
		else
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= 0)
			{
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 2.5));
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}
		
		var time:Float = CoolUtil.floorDecimal((Conductor.songPosition - ClientPrefs.data.noteOffset) / 1000, 1);
		var songLen:Float = CoolUtil.floorDecimal(songLength / 1000, 1);
		dataTxt.text = 'Time: $time / $songLen' +
						'\n\nSection: $curSection' +
						'\nBeat: $curBeat' +
						'\nStep: $curStep';
		super.update(elapsed);
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}
	
	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM)
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.mouse.visible = true;
		super.destroy();
	}
	
	function startSong():Void
	{
		startingSong = false;
		FlxG.sound.music.onComplete = finishSong;
		if (FlxG.sound.music != null) {
			FlxG.sound.music.volume = 1;
			FlxG.sound.music.play();
		}
		if (vocals != null) {
			vocals.volume = 1;
			vocals.play();
		}
		if (opponentVocals != null) {
			opponentVocals.volume = 1;
			opponentVocals.play();
		}
		if (FlxG.sound.music != null) {
			FlxG.sound.music.time = startPos - Conductor.offset;
		}
		if (vocals != null) {
			vocals.time = startPos - Conductor.offset;
		}
		if (opponentVocals != null) {
			opponentVocals.time = startPos - Conductor.offset;
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
	}

	// Borrowed from PlayState
	function generateSong()
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		var songData = PlayState.SONG;
		Conductor.bpm = songData.bpm;

		if (FlxG.sound.music != null) {
			FlxG.sound.music.volume = 0;
		}
		if (vocals != null) {
			vocals.volume = 0;
		}
		if (opponentVocals != null) {
			opponentVocals.volume = 0;
		}

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var oldNote:Note = null;
		for (note in _noteList)
		{
			if(note == null || note.strumTime < startPos) continue;

			var idx: Int = _noteList.indexOf(note);
			if (idx != 0) {
				// CLEAR ANY POSSIBLE GHOST NOTES
				for (evilNote in unspawnNotes) {
					var matches: Bool = note.noteData == evilNote.noteData && note.mustPress == evilNote.mustPress;
					if (matches && Math.abs(note.strumTime - evilNote.strumTime) == 0.0) {
						evilNote.destroy();
						unspawnNotes.remove(evilNote);
						//continue;+
					}
				}
			}

			var swagNote:Note = new Note(note.strumTime, note.noteData, oldNote, false, this);
			swagNote.mustPress = note.mustPress;
			swagNote.sustainLength = note.sustainLength;
			swagNote.gfNote = note.gfNote;
			swagNote.noteType = note.noteType;
			swagNote.scrollFactor.set();
			swagNote.ID = allNotes.length;

			if (swagNote.fieldIndex == -1 && swagNote.field == null)
				swagNote.field = swagNote.mustPress ? playerField : dadField;

			if (swagNote.field != null)
				swagNote.fieldIndex = playfields.members.indexOf(swagNote.field);

			var playfield:PlayField = playfields.members[swagNote.fieldIndex];

			if (playfield != null)
			{
				playfield.queue(swagNote); // queues the note to be spawned
				allNotes.push(swagNote); // just for the sake of convenience
			}
			else
			{
				swagNote.destroy();
				continue;
			}

			var roundSus:Int = Math.floor(swagNote.sustainLength / Conductor.stepCrochet);
			if(roundSus > 0)
			{
				for (susNote in 0...roundSus + 1)
				{
					oldNote = allNotes[Std.int(allNotes.length - 1)];

					var sustainNote:Note = new Note(swagNote.strumTime + (Conductor.stepCrochet * susNote), note.noteData, oldNote, true, this);
					sustainNote.mustPress = swagNote.mustPress;
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = swagNote.noteType;
					sustainNote.scrollFactor.set();
					sustainNote.parent = swagNote;
					sustainNote.ID = allNotes.length;

					swagNote.tail.push(sustainNote);
					swagNote.unhitTail.push(sustainNote);
					sustainNote.fieldIndex = swagNote.fieldIndex;
					playfield.queue(sustainNote);
					allNotes.push(sustainNote);

					sustainNote.correctionOffset = swagNote.height / 2;
					if(!PlayState.isPixelStage)
					{
						if(oldNote.isSustainNote)
						{
							oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if(ClientPrefs.data.downScroll)
							sustainNote.correctionOffset = 0;
					}
					else if(oldNote.isSustainNote)
					{
						oldNote.scale.y /= playbackRate;
						oldNote.updateHitbox();
					}

					if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
					else if(ClientPrefs.data.middleScroll)
					{
						sustainNote.x += 310;
						if(sustainNote.noteData > 1) //Up and Right
							sustainNote.x += FlxG.width / 2 + 25;
					}
				}
			}

			if (swagNote.mustPress)
			{
				swagNote.x += FlxG.width / 2; // general offset
			}
			else if(ClientPrefs.data.middleScroll)
			{
				swagNote.x += 310;
				if(swagNote.noteData > 1) //Up and Right
				{
					swagNote.x += FlxG.width / 2 + 25;
				}
			}
			oldNote = swagNote;
		}

		allNotes.sort(sortByNotes);
		for (fuck in allNotes) unspawnNotes.push(fuck);
		for (field in playfields.members)
		{
			var goobaeg:Array<Note> = [];
			for (column in field.noteQueue)
			{
				if (column.length >= Note.ammo[PlayState.mania])
				{
					for (nIdx in 1...column.length)
					{
						var last = column[nIdx - 1];
						var current = column[nIdx];

						if (last == null || current == null)
							continue;
						if (last.isSustainNote || current.isSustainNote)
							continue; // holds only get fukt if their parents get fukt
						if (!last.alive || !current.alive)
							continue; // just incase
						if (Math.abs(last.strumTime - current.strumTime) <= Conductor.stepCrochet / (192 / 16))
						{
							if (last.sustainLength < current.sustainLength) // keep the longer hold
								field.removeNote(last);
							else
							{
								current.kill();
								goobaeg.push(current); // mark to delete after, cant delete here because otherwise it'd fuck w/ stuff
							}
						}
					}
				}
			}
			for (note in goobaeg)
				field.removeNote(note);
		}

		speedChanges.sort(svSort);
	}

	function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startTime, Obj2.startTime);
	}

	function sortByNotes(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	public function finishSong():Void
	{
		if(ClientPrefs.data.noteOffset <= 0) {
			endSong();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endSong();
			});
		}
	}

	public function endSong()
	{
		notes.forEachAlive(function(note:Note) invalidateNote(note));
		for (note in unspawnNotes)
			if(note != null) invalidateNote(note);

		FlxG.sound.music.pause();
		vocals.pause();
		if (opponentVocals != null) opponentVocals.pause();

		if(finishTimer != null)
			finishTimer.destroy();

		Conductor.songPosition = FlxG.sound.music.time = vocals.time = startPos - Conductor.offset;
		if (opponentVocals != null) opponentVocals.time = startPos - Conductor.offset;
		close();
	}
	
	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiPostfix:String = '';
		if (PlayState.stageUI != "normal")
		{
			uiPrefix = '${PlayState.stageUI}UI/';
			if (PlayState.isPixelStage) uiPostfix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiPostfix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiPostfix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				spr.destroy();
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(!note.ratingDisabled)
			songHits++;

		var uiPrefix:String = "";
		var uiPostfix:String = '';
		var antialias:Bool = ClientPrefs.data.globalAntialiasing;

		if (PlayState.stageUI != "normal")
		{
			uiPrefix = '${PlayState.stageUI}UI/';
			if (PlayState.isPixelStage) uiPostfix = '-pixel';
			antialias = !PlayState.isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiPostfix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		var separatedScore:String = Std.string(combo).lpad('0', 3);
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * PlayState.daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (key > -1)
		{
			var hitNotes:Array<Note> = [];
			var controlledFields:Array<PlayField> = [];

			for (field in playfields.members)
			{
				if (!field.autoPlayed && field.isPlayer && field.inControl)
				{
					controlledFields.push(field);
					field.keysPressed[key] = true;
					var note:Note = null;
					note = field.input(key);

					if (note == null)
					{
						var spr:StrumNote = field.strumNotes[key];
						if (spr != null && spr.animation.curAnim.name != 'confirm')
						{
							spr.playAnim('pressed');
							spr.resetAnim = 0;
						}
					}
					else
					{
						hitNotes.push(note);
					}
				}
			}
		}
	}

	public function getKeyFromEvent(key:FlxKey):Int
	{
		// var tempKeys:Array<Dynamic> = backend.Keybinds.fill();
		if (key != NONE)
		{
			for (i in 0...keysArray[PlayState.mania].length)
			{
				for (j in 0...keysArray[PlayState.mania][i].length)
				{
					if (key == keysArray[PlayState.mania][i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (key > -1)
		{
			// doesnt matter if THIS is done while paused
			// only worry would be if we implemented Lifts
			// but afaik we arent doing that
			// (though could be interesting to add)
			for (field in playfields.members)
			{
				if (field.inControl && !field.autoPlayed && field.isPlayer)
				{
					field.keysPressed[key] = false;

					if (!field.isHolding[key])
					{
						var spr:StrumNote = field.strumNotes[key];
						if (spr != null)
						{
							spr.playAnim('static');
							spr.resetAnim = 0;
						}
					}
				}
			}
		}
	}

	
	function opponentNoteHit(note:Note, field:PlayField):Void
	{
		if (PlayState.SONG.needsVoices && opponentVocals != null && opponentVocals.length <= 0)
			opponentVocals.volume = 1;

		if (note.visible)
		{
			var time:Float = 0.15;
			if (note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
				time += 0.15;
			var spr:StrumNote = field.strumNotes[note.noteData];
			if (spr != null)
			{
				spr.playAnim('confirm', true, note);
				spr.resetAnim = time;
			}
		}
		note.hitByOpponent = true;

		if (!note.isSustainNote && note.sustainLength == 0)
		{
			field.removeNote(note);
		}
		else if (note.isSustainNote)
			if (note.parent.unhitTail.contains(note))
				note.parent.unhitTail.remove(note);
	}

	function goodNoteHit(note:Note, field:PlayField):Void
	{
		if(note.wasGoodHit) return;

		note.wasGoodHit = true;

		if (!note.isSustainNote)
		{
			combo++;
			if(combo > 9999) combo = 9999;
			popUpScore(note);
		}

		// Strum animations
		if (note.visible)
		{
			var spr = field.strumNotes[note.noteData];
			if (spr != null && field.keysPressed[note.noteData])
				spr.playAnim('confirm', true, note);
		}
		vocals.volume = 1;
		
		if (!note.isSustainNote && note.tail.length == 0)
			field.removeNote(note);
		else if (note.isSustainNote)
		{
			if (note.parent != null)
				if (note.parent.unhitTail.contains(note))
					note.parent.unhitTail.remove(note);
		}
	}
	
	function noteMiss(daNote:Note, field:PlayField):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		for (note in field.spawnedNotes)
		{
			if (!note.alive || daNote.tail.contains(note) || note.isSustainNote)
				continue;
			if (daNote != note && field.isPlayer && daNote.noteData == note.noteData && Math.abs(daNote.strumTime - note.strumTime) < 1)
				field.removeNote(note);
		}

		if (!daNote.isSustainNote && daNote.unhitTail.length > 0)
		{
			for (tail in daNote.unhitTail)
			{
				tail.tooLate = true;
				tail.blockHit = true;
				tail.ignoreNote = true;
				// health -= daNote.missHealth * healthLoss; // this is kinda dumb tbh no other VSRG does this just FNF
			}
		}

		// score and data
		songMisses++;
		updateScore();
		vocals.volume = 0;
		combo = 0;
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	function updateScore()
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses';
}
