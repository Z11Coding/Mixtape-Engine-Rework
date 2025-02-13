package music;

import haxe.Json;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import music.Section;
import music.Conductor;
import states.PlayState;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	//@:optional var playerNotes:Array<Dynamic>;
	//@:optional var opponentNotes:Array<Dynamic>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var ?bpmT:music.Conductor.BPMTween;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	@:optional var player4:String;
	@:optional var player5:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	var mania:Int;
	@:optional var startMania:Int;

	@:optional var songCredit:String;
	@:optional var songCreditBarPath:String;
	@:optional var songCreditIcon:String;
	@:optional var event7:String;
	@:optional var event7Value:String;

	@:optional var windowName:String;
	@:optional var specialAudioName:String;
	@:optional var specialEventsName:String;

	@:optional var validScore:Bool;

	@:optional var usualMania:Int;
	@:optional var usualStartMania:Int;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;

	@:optional var extraTracks:Array<String>;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = false;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var player4:String = 'dad';
	public var player5:String = 'bf';
	public var gfVersion:String = 'gf';

	private static function onLoadJsonMixtape(songJson:Dynamic) // Convert old charts to newest format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
		
		if (songJson.mania == null)
		{
			songJson.mania = Note.defaultMania;
		}
		if (songJson.startMania == null)
		{
			songJson.startMania = Note.defaultMania;
		}
	}

	public static function hasDifficulty(songName:String, difficulty:String):Bool
	{
		var formattedSong:String = Paths.formatToSongPath(songName);
		var formDiff:String = Paths.formatToSongPath(difficulty);
		var jsonToFind:String = Paths.json(formattedSong + '/' + formattedSong + '-' + formDiff);
		#if MODS_ALLOWED
			if (!CoolUtil.defaultSongs.contains(formattedSong) && !CoolUtil.defaultSongsFormatted.contains(formattedSong))
				jsonToFind = Paths.modsJson(formattedSong + '/' + formattedSong + '-' + formDiff); #end
		if(FileSystem.exists(jsonToFind)) return true;

		return false;
	}

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}

			if (songJson.mania == null)
			{
				songJson.mania = Note.defaultMania;
			}
			if (songJson.startMania == null)
			{
				songJson.startMania = Note.defaultMania;
			}
			/*
			trace("DID A THING");
			trace("Manias: ");
			trace(songJson.mania);
			trace(songJson.startMania);*/
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < (Note.ammo[PlayState.mania])) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % Note.ammo[PlayState.mania]-1) + (gottaHitNote ? 0 : Note.ammo[PlayState.mania]-1);

				if(note[3] != null && !Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		trace(jsonInput);
		if(folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath.replace('/', '\\');
		backend.StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if(FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		#end
			rawData = Assets.getText(_lastPath);

		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawData = File.getContent(moddyFile);
		}
		#end

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'mixtape_v1'):SwagSong
	{
		var songJson:Dynamic = Json.parse(rawData);
		try {
			if(Reflect.hasField(songJson, 'song'))
			{
				var subSong:SwagSong = Reflect.field(songJson, 'song');
				if(subSong != null && Type.typeof(subSong) == TObject)
					songJson = subSong;
			}
			var fmt:String = songJson.format;
			if(fmt == null) fmt = songJson.format = 'unknown';
			trace(fmt);

			if (songJson.mania == null) {
				songJson.mania = Note.defaultMania;
			}
			if (songJson.startMania == null) {
				songJson.startMania = songJson.mania != null ? songJson.mania : Note.defaultMania;
			}

			switch (fmt)
			{
				case 'psych_v1':
					trace('converting chart $nameForError with format $fmt to psych_v1 format...');
					songJson.format = 'psych_v1_convert';
					convert(songJson);
				case 'psych_v1_convert':
					trace('converting chart $nameForError with format $fmt to psych_v1 format...');
					songJson.format = 'psych_v1';
					convert(songJson);
				case 'mixtape_v1':
					trace('converting chart $nameForError with format $fmt to mixtape_v1 format...');
					songJson.format = 'mixtape_v1_convert';
					onLoadJsonMixtape(songJson);
				default: 
					trace('converting chart $nameForError with format $fmt to mixtape_v1 format...');
					songJson.format = 'mixtape_v1_convert';
					onLoadJsonMixtape(songJson);
			}
		} catch (error:Dynamic) {
			trace('Failed to parse JSON with default method. Attempting to parse with parseJSONshit...');
			songJson = parseJSONshit(rawData);
		}
		return songJson;
	}
}