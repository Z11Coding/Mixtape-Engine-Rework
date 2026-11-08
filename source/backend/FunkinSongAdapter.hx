package backend;

import haxe.Json;

#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

typedef FunkinSongInfo = {
	var mod:String;
	var id:String;
	var title:String;
	var artist:String;
	var charter:String;
	var player:String;
	var girlfriend:String;
	var opponent:String;
	var stage:String;
	var difficulties:Array<String>;
}

/**
 * Adapts Funkin's native level, song metadata, and chart files to the
 * existing WeekData and SwagSong systems.
 */
class FunkinSongAdapter {
	private static inline var SYNTHETIC_PREFIX:String = '__funkin__';

	#if MODS_ALLOWED
	public static function discover():Array<FunkinSongInfo> {
		var result:Array<FunkinSongInfo> = [];
		for (mod in Mods.parseList().vslice) {
			var discoveredSongs:Map<String, Bool> = new Map<String, Bool>();
			var levelsPath:String = Paths.mods('$mod/data/levels');
			if (FileSystem.exists(levelsPath) && FileSystem.isDirectory(levelsPath)) {
				for (levelFile in FileSystem.readDirectory(levelsPath)) {
					if (!levelFile.endsWith('.json'))
						continue;

					var levelPath:String = '$levelsPath/$levelFile';
					try {
						var level:Dynamic = Json.parse(File.getContent(levelPath));
						if (level.songs == null || !Std.isOfType(level.songs, Array))
							continue;

						var levelSongs:Array<Dynamic> = cast level.songs;
						for (songIdValue in levelSongs) {
							var songId:String = Std.string(songIdValue);
							if (!discoveredSongs.exists(songId) && addSong(result, mod, songId))
								discoveredSongs.set(songId, true);
						}
					} catch (e:Dynamic) {
						trace('FunkinSongAdapter: failed to read $levelPath: $e');
					}
				}
			}

			// Keep support for packs that do not provide a level file.
			var songsPath:String = Paths.mods('$mod/data/songs');
			if (!FileSystem.exists(songsPath) || !FileSystem.isDirectory(songsPath))
				continue;

			for (songId in FileSystem.readDirectory(songsPath)) {
				if (!discoveredSongs.exists(songId) && addSong(result, mod, songId))
					discoveredSongs.set(songId, true);
			}
		}
		trace(result);
		return result;
	}

	private static function addSong(result:Array<FunkinSongInfo>, mod:String, songId:String):Bool {
		var songPath:String = Paths.mods('$mod/data/songs/$songId');
		var metadataPath:String = '$songPath/$songId-metadata.json';
		if (!FileSystem.isDirectory(songPath) || !FileSystem.exists(metadataPath))
			return false;

		try {
			var metadata:Dynamic = Json.parse(File.getContent(metadataPath));
			var playData:Dynamic = metadata.playData;
			var difficulties:Array<String> = [];
			if (playData != null && playData.difficulties != null)
				difficulties = cast playData.difficulties;
			if (difficulties.length == 0)
				difficulties = ['normal'];

			var characters:Dynamic = playData == null ? null : playData.characters;
			result.push({
				mod: mod,
				id: songId,
				title: metadata.songName ?? songId,
				artist: metadata.artist ?? 'Unknown',
				charter: metadata.charter ?? 'Unknown',
				player: characters?.player ?? 'bf',
				girlfriend: characters?.girlfriend ?? 'gf',
				opponent: characters?.opponent ?? 'dad',
				stage: playData?.stage ?? 'stage',
				difficulties: difficulties
			});
			return true;
		} catch (e:Dynamic) {
			trace('FunkinSongAdapter: failed to read $metadataPath: $e');
			return false;
		}
	}

	public static function registerSyntheticWeeks():Void {
		for (song in discover()) {
			var weekId:String = SYNTHETIC_PREFIX + song.mod + '__' + song.id;
			if (WeekData.weeksLoaded.exists(weekId)) {
				trace("Week already exists: "+weekId);
				continue;
			}
			var weekFile:WeekFile = WeekData.createWeekFile();
			weekFile.songs = [[song.id, song.player, [146, 113, 253]]];
			weekFile.weekName = song.mod;
			weekFile.storyName = song.mod;
			weekFile.hideStoryMode = true;
			weekFile.hideFreeplay = false;
			weekFile.difficulties = song.difficulties.join(',');
			weekFile.category = 'mods';

			var week:WeekData = new WeekData(weekFile, weekId);
			week.folder = song.mod;
			WeekData.weeksLoaded.set(weekId, week);
			WeekData.weeksList.push(weekId);
			trace("added week "+weekId);
		}
	}

	public static function loadChart(songId:String, difficulty:String, mod:String):Null<Song.SwagSong> {
		var chartPath:String = Paths.mods('$mod/data/songs/$songId/$songId-chart.json');
		if (!FileSystem.exists(chartPath))
			return null;

		try {
			var chart:Dynamic = Json.parse(File.getContent(chartPath));
			var notes:Dynamic = chart.notes;
			var difficultyNotes:Array<Dynamic> = resolveDifficulty(notes, difficulty);
			if (difficultyNotes == null)
				return null;

			var metadata:Dynamic = Json.parse(File.getContent(Paths.mods('$mod/data/songs/$songId/$songId-metadata.json')));
			var playData:Dynamic = metadata.playData;
			var characters:Dynamic = playData?.characters;
			var bpm:Float = firstBpm(chart, metadata);
			var speed:Float = resolveScrollSpeed(chart.scrollSpeed, difficulty);
			var timeChanges:Array<Dynamic> = chart.timeChanges ?? metadata.timeChanges ?? [];
			var sections:Array<Song.SwagSection> = [];
			var measureLength:Float = 60000.0 / bpm * 4.0;

			for (note in difficultyNotes) {
				var time:Float = cast (note.t ?? note.time ?? 0);
				var sectionIndex:Int = Std.int(time / measureLength);
				while (sections.length <= sectionIndex) {
					var sectionBpm:Float = bpmAtTime(timeChanges, sections.length * measureLength, bpm);
					sections.push({
						sectionNotes: [],
						sectionBeats: 4,
						sectionSteps: 16,
						mustHitSection: true,
						bpm: sectionBpm,
						changeBPM: sections.length > 0 && sectionBpm != sections[sections.length - 1].bpm
					});
				}

				var lane:Int = Std.int(note.d ?? note.data ?? 0);
				var length:Float = cast (note.l ?? note.length ?? 0);
				var kind:String = note.k ?? note.kind ?? '';
				sections[sectionIndex].sectionNotes.push([time, lane, length, kind]);
			}

			if (sections.length == 0)
				sections.push({sectionNotes: [], sectionBeats: 4, sectionSteps: 16, mustHitSection: true, bpm: bpm});

			return {
				song: songId,
				notes: sections,
				events: [],
				bpm: bpm,
				needsVoices: true,
				speed: speed,
				offset: 0,
				player1: characters?.player ?? 'bf',
				player2: characters?.opponent ?? 'dad',
				player4: '',
				player5: '',
				gfVersion: characters?.girlfriend ?? 'gf',
				stage: playData?.stage ?? 'stage',
				format: 'psych_v1',
				mania: 0,
				startMania: 0
			};
		} catch (e:Dynamic) {
			trace('FunkinSongAdapter: failed to load $chartPath: $e');
			return null;
		}
	}

	private static function resolveDifficulty(notes:Dynamic, difficulty:String):Array<Dynamic> {
		if (notes == null)
			return null;
		if (Std.isOfType(notes, Array))
			return cast notes;

		var exact:Dynamic = Reflect.field(notes, difficulty);
		if (exact != null)
			return cast exact;
		for (field in Reflect.fields(notes))
			if (field.toLowerCase() == difficulty.toLowerCase())
				return cast Reflect.field(notes, field);
		if (difficulty.toLowerCase() == 'normal') {
			var fields:Array<String> = Reflect.fields(notes);
			if (fields.length > 0)
				return cast Reflect.field(notes, fields[0]);
		}
		return null;
	}

	private static function firstBpm(chart:Dynamic, metadata:Dynamic):Float {
		if (chart.timeChanges != null && chart.timeChanges.length > 0)
			return chart.timeChanges[0].bpm;
		if (metadata.timeChanges != null && metadata.timeChanges.length > 0)
			return metadata.timeChanges[0].bpm;
		return 100;
	}

	private static function bpmAtTime(timeChanges:Array<Dynamic>, time:Float, fallback:Float):Float {
		var result:Float = fallback;
		for (change in timeChanges) {
			var changeTime:Float = cast (change.t ?? change.time ?? 0);
			if (changeTime > time)
				break;
			result = change.bpm;
		}
		return result;
	}

	private static function resolveScrollSpeed(scrollSpeed:Dynamic, difficulty:String):Float {
		if (scrollSpeed == null)
			return 1;
		if (Std.isOfType(scrollSpeed, Float) || Std.isOfType(scrollSpeed, Int))
			return scrollSpeed;
		var value:Dynamic = Reflect.field(scrollSpeed, difficulty);
		if (value == null)
			for (field in Reflect.fields(scrollSpeed))
				if (field.toLowerCase() == difficulty.toLowerCase())
					value = Reflect.field(scrollSpeed, field);
		return value == null ? 1 : value;
	}
	#end
}
