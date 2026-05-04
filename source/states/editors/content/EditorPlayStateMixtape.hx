package states.editors.content;

import backend.Rating;
import backend.Song;
import backend.modchart.ModManager;
import flixel.animation.FlxAnimationController;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import haxe.Json;
import objects.Character;
import objects.Note;
import objects.NoteSplash;
import objects.StrumNote;
import objects.playfields.*;
import openfl.events.KeyboardEvent;
import openfl.utils.Assets as OpenFlAssets;

class EditorPlayStateMixtape extends MusicBeatSubstate
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
	public var keysArray:Array<Dynamic>;
	public var modManager:ModManager;
	public var playerField:PlayField;
	public var dadField:PlayField;
	public var notefields = new NotefieldRenderer();
	public var playfields = new FlxTypedGroup<PlayField>();
	public var allNotes:Array<Note> = []; // all notes
  public static var instance:EditorPlayStateMixtape;

	public function new(?playbackRate:Float)
	{
		super();

		Cursor.hide();
		/* setting up some important data */
		this.playbackRate = playbackRate;
		this.startPos = conductor.musicPosition;

		RConductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		startOffset = conductor.beatLengthMs;
		timerToStart = startOffset;

		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (conductor.target != null)
			conductor.target.stop();

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);

    instance = this;

		/**** NOTES ****/
		playfield.setModMan(cast this);
		playfield.modManager.playerAmount = 2;
		for (i in 0...playfield.modManager.playerAmount)
			playfield.newPlayfield();

		//trace("Making PlayerField!");
		playfield.playerField = playfield.playfields.members[0];
		if (playfield.playerField != null) {
			playfield.playerField.noteField.isEditor = false;
			playfield.playerField.isPlayer = true;
			playfield.playerField.autoPlayed = false;
			playfield.playerField.noteHitCallback.add(goodNoteHit);
		}

		//trace("Making DadField!");
		playfield.dadField = playfield.playfields.members[1];
		if (playfield.dadField != null) {
			playfield.dadField.noteField.isEditor = false;
			playfield.dadField.isPlayer = false;
			playfield.dadField.autoPlayed = true;
			playfield.dadField.AIPlayer = false;
			playfield.dadField.noteHitCallback.add(opponentNoteHit);
		}

		PlayField.initExtras();

		playfield.addNoteMissCalbackToField((daNote:Note, field:PlayField) -> {
			if (MusicBeatState.getState() == PlayState.instance) {
        if (!field.autoPlayed && !daNote.ignoreNote && !PlayState.instance?.endingSong && (daNote.tooLate || !daNote.wasGoodHit))
          noteMiss(daNote, field);
      }
		}, playerField);

		playfield.addNoteMissCalbackToField((daNote:Note, field:PlayField) -> {
			if (MusicBeatState.getState() == PlayState.instance) {
        if (!field.autoPlayed && !daNote.ignoreNote && !PlayState.instance?.endingSong && (daNote.tooLate || !daNote.wasGoodHit))
          noteMiss(daNote, field);
      }
		}, dadField);

		for (field in playfield.playfields.members)
		{
			field.keyCount = Note.ammo[PlayfieldManager.mania[field.modNumber]];
			field.generateStrums();
		}
		for (field in playfield.playfields.members)
			field.fadeIn(true); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode

		playfield.modManager.registerDefaultModifiers();
		/***************/

    add(playfields);
		add(notefields);
		add(PlayField.extraStuff);

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

		playfield.addInput();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayfieldManager.SONG.song, null, true, songLength);
		#end
		RecalculateRating();
	}

	function manCalls() {
		conductor.addBeatCallback((curBeat:Int, backward:Bool) ->
		{
			if (PlayfieldManager.SONG.needsVoices && conductor.target.time >= -ClientPrefs.data.noteOffset)
			{
				var timeSub:Float = conductor.musicPosition - conductor.musicPositionOffset;
				var syncTime:Float = 20 * playbackRate;
				if (Math.abs(conductor.target.time - timeSub) > syncTime ||
				(vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime) ||
				(opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
				{
					resyncVocals();
				}
			}
		});
	}

  override function update(elapsed:Float)
	{
		playfield.modManager.update(elapsed, conductor.currentBeatTime, conductor.currentStepTime);

		for (field in playfield.playfields)
			field.noteField.songSpeed = songSpeed;

		if(controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			endSong();
			super.update(elapsed);
			return;
		}

		if (startingSong)
		{
			playfield.modManager.setValue('transformX', -400);
			playfield.modManager.setValue('transformY', -300);
			timerToStart -= elapsed * 1000;
			if(timerToStart < 0) startSong();
		}
		else
		{
			for (field in playfield.playfields.members)
				field.fadeIn(false); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode
			playfield.modManager.setValue('transformX', -400);
      playfield.modManager.setValue('transformY', -300);
		}

		var time:Float = CoolUtil.floorDecimal((conductor.musicPosition - ClientPrefs.data.noteOffset) / 1000, 1);
		dataTxt.text = 'Time: $time / ${songLength/1000}
		\nSection: ${conductor.currentMeasure}
		\nBeat: ${conductor.currentBeat}
		\nStep: ${conductor.currentStep}';
		super.update(elapsed);
	}

	override function destroy()
	{
		playfield.removeInput();
		FlxG.mouse.visible = true;
		super.destroy();
	}

	function startSong():Void
	{
		startingSong = false;
		@:privateAccess
		conductor.target.loadEmbedded(inst._sound);
		conductor.target.play();
		conductor.target.time = startPos;
		#if FLX_PITCH conductor.target.pitch = playbackRate; #end
		conductor.target.onComplete = finishSong;
		vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
		opponentVocals.volume = 1;
		opponentVocals.time = startPos;
		opponentVocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = conductor.target.length;
	}

	var characterFailed:Bool = false;

	function loadCharacterFile(char:String):CharacterFile
	{
		characterFailed = false;
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER +
				'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
			characterFailed = true;
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}

	var characterData:Dynamic = {
		vocalsP1: null,
		vocalsP2: null,
	};

	function updateJsonData():Void
	{
		for (i in 1...2)
		{
			var data:CharacterFile = loadCharacterFile(Reflect.field(PlayfieldManager.SONG, 'player$i'));
			Reflect.setField(characterData, 'vocalsP$i', data.vocals_file != null ? data.vocals_file : '');
		}
	}

	function generateSong():Void
	{
		var songData = PlayfieldManager.SONG;
		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				updateJsonData();
				var currentMod = backend.WeekData.getCurrentWeek().folder;
				if (currentMod != null && currentMod != "")
				{
					var generalVocals = Paths.voices(songData.song);
					if (generalVocals != null && generalVocals.length > 0)
					{
						vocals.loadEmbedded(generalVocals);
					}
					else
					{
						var playerVocals = Paths.voices(songData.song, (characterData.vocalsP1.vocalsFile == null || characterData.vocalsP1.vocalsFile.length < 1) ? 'Player' : characterData.vocalsP1.vocalsFile);
						vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));

						var oppVocals = Paths.voices(songData.song, (characterData.vocalsP2.vocalsFile == null || characterData.vocalsP2.vocalsFile.length < 1) ? 'Opponent' : characterData.vocalsP2.vocalsFile);
						if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
					}
				}
				else
				{
					var playerVocals = Paths.voices(songData.song, (characterData.vocalsP1.vocalsFile == null || characterData.vocalsP1.vocalsFile.length < 1) ? 'Player' : characterData.vocalsP1.vocalsFile);
					vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));

					var oppVocals = Paths.voices(songData.song, (characterData.vocalsP2.vocalsFile == null || characterData.vocalsP2.vocalsFile.length < 1) ? 'Opponent' : characterData.vocalsP2.vocalsFile);
					if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
				}
			}
		}
		catch (e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);
		playfield.loadChart(Paths.formatToSongPath(songData.song)+Difficulty.getFilePath(), Paths.formatToSongPath(songData.song));
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
		Cursor.show();
		Cursor.cursorMode = Default;
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
		var noteDiff:Float = Math.abs(note.strumTime - conductor.musicPosition + ClientPrefs.data.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - conductor.musicPosition));

		vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Rating.judgeNote(ratingsData, noteDiff / playbackRate);

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
				startDelay: conductor.beatLengthMs * 0.002 / playbackRate
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
			startDelay: conductor.beatLengthMs * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: conductor.beatLengthMs * 0.002 / playbackRate
		});
	}

	function opponentNoteHit(note:Note, field:PlayField):Void
	{
		if (PlayfieldManager.SONG.needsVoices && opponentVocals.length <= 0)
			vocals.volume = 1;

		if (note.visible)
		{
			var time:Float = 0.15;
			if (note.isSustainNote && !note.animation.curAnim.name.endsWith('tail')) time += 0.15;
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

		conductor.target.play();
		#if FLX_PITCH conductor.target.pitch = playbackRate; #end
		if (conductor.musicPosition <= vocals.length)
		{
			vocals.time = conductor.musicPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (conductor.musicPosition <= opponentVocals.length)
		{
			opponentVocals.time = conductor.musicPosition;
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
}
