package states.editors;

import backend.Song;
import backend.Section;
import backend.Rating;

import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;

import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

import haxe.Json;
import objects.Character;
import openfl.utils.Assets as OpenFlAssets;

import backend.modchart.ModManager;

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
	
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	
	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];
	
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;
	
	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;
	
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

    //Mixtape
    var speedChanges:Array<SpeedEvent> = [];
	public var currentSV:SpeedEvent = {
		position: 0,
		startTime: 0,
		songTime: 0,
		speed: 1,
		startSpeed: 1
	};
    public var keysArray:Array<Dynamic>;
	public var modManager:ModManager;
	public var playerField:PlayField;
	public var dadField:PlayField;
	public var notefields = new NotefieldRenderer();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes
    public static var instance:EditorPlayState;

	public function new(playbackRate:Float)
	{
		super();
		
		/* setting up some important data */
		this.playbackRate = playbackRate;
		this.startPos = Conductor.songPosition;

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		
		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);

        instance = this;
		
		/**** NOTES ****/
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

        add(playfields);
		add(notefields);
		
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
		
		generateSong(PlayState.SONG.song);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, null, true, songLength);
		#end
		RecalculateRating();
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

        for (field in playfields)
			field.noteField.songSpeed = songSpeed;

		if(controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			endSong();
			super.update(elapsed);
			return;
		}
		
		if (startingSong)
		{
            modManager.setValue('transformX', -400);
            modManager.setValue('transformY', -300);
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) startSong();
		}
		else 
		{
			for (field in playfields.members)
				field.fadeIn(true); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode
			modManager.setValue('transformX', -400);
            modManager.setValue('transformY', -300);
			Conductor.songPosition += elapsed * 1000 * playbackRate;
		}
		
		var time:Float = CoolUtil.floorDecimal((Conductor.songPosition - ClientPrefs.data.noteOffset) / 1000, 1);
		dataTxt.text = 'Time: $time / ${songLength/1000}
						\nSection: $curSection
						\nBeat: $curBeat
						\nStep: $curStep';
		super.update(elapsed);
	}
	
	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if (PlayState.SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * playbackRate;
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime ||
			(vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime) ||
			(opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}
		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		//notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

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
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.time = startPos;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong;
		vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
		opponentVocals.volume = 1;
		opponentVocals.time = startPos;
		opponentVocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
	}

	// Borrowed from PlayState
    var noteIndex:Int = -1;
	function generateSong(dataPath:String)
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

		var boyfriendVocals:String = loadCharacterFile(PlayState.SONG.player1).vocals_file;
		var dadVocals:String = loadCharacterFile(PlayState.SONG.player2).vocals_file;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriendVocals == null || boyfriendVocals.length < 1) ? 'Player' : boyfriendVocals);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				var oppVocals = Paths.voices(songData.song, (dadVocals == null || dadVocals.length < 1) ? 'Opponent' : dadVocals);
				if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch(e:Dynamic) {}

		vocals.volume = 0;
		opponentVocals.volume = 0;

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);
		FlxG.sound.music.volume = 0;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if(daStrumTime < startPos) continue;

				var daNoteData:Int;
                daNoteData = Std.int(songNotes[1] % Note.ammo[PlayState.mania]);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > (Note.ammo[PlayState.mania] - 1))
                {
                    gottaHitNote = !section.mustHitSection;
                }

				var oldNote:Note;
				if (allNotes.length > 0)
					oldNote = allNotes[Std.int(allNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, this);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				//swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
                swagNote.noteIndex = noteIndex++;
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingStateOG.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

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

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);

				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = allNotes[Std.int(allNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true, this);
						sustainNote.mustPress = gottaHitNote;
						//sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
                        sustainNote.noteIndex = swagNote.noteIndex;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						sustainNote.fieldIndex = swagNote.fieldIndex;
						playfield.queue(sustainNote);
						allNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);
                        swagNote.unhitTail.push(sustainNote);

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
							if(daNoteData > 1) //Up and Right
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
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
			}
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
		vocals.pause();
		vocals.destroy();
		opponentVocals.pause();
		opponentVocals.destroy();
		if(finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		close();
	}

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			Paths.image(rating.image);
		
		for (i in 0...10)
			Paths.image('num' + i);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(!note.ratingDisabled)
		{
			songHits++;
			totalPlayed++;
			RecalculateRating(false);
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
			if (!ClientPrefs.data.comboStacking)
				lastScore.push(numScore);

			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				insert(members.indexOf(strumLineNotes), numScore);

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
		/*
			trace(combo);
			trace(seperatedScore);
			*/

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
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

		if (!controls.controllerMode)
		{
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

		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
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

	
	function opponentNoteHit(note:Note, field:PlayField):Void
	{
		if (PlayState.SONG.needsVoices && opponentVocals.length <= 0)
			vocals.volume = 1;

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
	
	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		vocals.play();
		opponentVocals.play();
	}

	function RecalculateRating(badHit:Bool = false) {
		if(totalPlayed != 0) //Prevent divide by 0
			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

		fullComboUpdate();
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
	}

	function updateScore(miss:Bool = false)
	{
		var str:String = '?';
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str = '$percent% - $ratingFC';
		}
		scoreTxt.text = 'Hits: $songHits | Misses: $songMisses | Rating: $str';
	}
	
	function fullComboUpdate()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = 'Clear';
		if(songMisses < 1)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB';
	}
	
	function loadCharacterFile(char:String):CharacterFile {
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end
		return cast Json.parse(rawJson);
	}
}