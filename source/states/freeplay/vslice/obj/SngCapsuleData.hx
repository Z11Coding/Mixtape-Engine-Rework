package states.freeplay.vslice.obj;

import backend.WeekData;
import backend.pslice.Scoring.ScoringRank;
import metadata.STMetaFile.MetadataFile;

abstract class SngCapsuleData{
  /*
	 * Whether or not the song has been favorited.
	*/
	public var isFav:Bool = false;

	public var allowErect:Bool = false;
	public var metaSngId:String = "";

	public var isNew:Bool = false;
	public var metaAllowNew:Bool = false;
	public var folder:String = "";
	public var color:Int = -7179779;

	public var levelId(default, null):Int = 0;
	public var levelName(default, null):String = "";
	public var songId(default, null):String = '';

	public var songDifficulties(default, null):Array<String> = [];

	public var songName(default, null):String = '';
	public var songCharacter(default, null):String = '';
	public var songStartingBpm(default, null):Float = 0;
	public var difficultyRating(default, null):Int = 0;
	public var albumId(default, null):Null<String> = null;
	public var songPlayer(default, null):String = '';
	public var songWeekName(default, null):String = '';

	public var freeplayPrevStart(default, null):Float = 0;
	public var freeplayPrevEnd(default, null):Float = 0;
	public var currentDifficulty(default, set):String = "normal";
	public var instVariants:Array<String>;

	public var scoringRank:Null<ScoringRank> = null;

	function set_currentDifficulty(value:String):String
	{
		currentDifficulty = value;
		updateValues();
		updateMeta();
		return value;
	}

	public function new(levelId:Int, songId:String, songCharacter:String, color:FlxColor)
	{
		this.levelId = levelId;
		this.songName = songId.replace("-", " ");
		this.songCharacter = songCharacter;
		this.color = color;
		this.songId = songId;
		updateMeta();
		updateValues();
	}

	/**
	 * Toggle whether or not the song is favorited, then flush to save data.
	 * @return Whether or not the song is now favorited.
	 */
	public abstract function toggleFavorite():Bool;

	function updateMeta()
	{
		var potentiallyErect:String = (allowErect && (currentDifficulty == "erect") || (currentDifficulty == "nightmare")) ? "-erect" : "";
		var newSngId = songId + potentiallyErect;
		if (metaSngId == newSngId)
			return;
		metaSngId = newSngId;
		var meta = FreeplayManager.getPSliceMetadata(metaSngId);
		if (meta != null) {
			difficultyRating = meta.songRating;
			metaAllowNew = meta.allowNewTag;
			allowErect = meta.allowErectVariants;
			freeplayPrevStart = meta.freeplayPrevStart / meta.freeplaySongLength;
			freeplayPrevEnd = meta.freeplayPrevEnd / meta.freeplaySongLength;
			albumId = meta.albumId;
			instVariants = meta.altInstrumentalSongs.split(",");
			songPlayer = meta.freeplayCharacter;
			songWeekName = meta.freeplayWeekName;
		} else {
			//trace("P-SLICE CHECK FAILED! ASSUMING IT'S A MIXTAPE METAFILE AND READING IT AS SUCH...");
			var meta:MetadataFile = FreeplayManager.getMixtapeMetadata(metaSngId);
			if (meta != null) { // Mixtape Metadata doesn't have everything P-Slice does, so im gonna have to accomidate where I can
				difficultyRating = meta.freeplay?.ratings?.get(currentDifficulty.toLowerCase());
				metaAllowNew = true;
				allowErect = false;
				freeplayPrevStart = 0;
				freeplayPrevEnd = 0.2;
				songStartingBpm = try{backend.Song.getChart(getNativeSongId()+(currentDifficulty.toLowerCase() != "normal" ? currentDifficulty.toLowerCase() : ""), getNativeSongId()).bpm;}catch(e){1;}
				albumId = meta.freeplay?.album ?? '';
				instVariants = [];

				songPlayer = 'bf';
				songWeekName = '';
			} else {
				var meta:MetadataFile = states.freeplay.VSliceFreeplayState.instance.fpManager.metadata.get(getNativeSongId().toLowerCase());
				if (meta != null) {
					difficultyRating = meta.freeplay?.ratings?.get(currentDifficulty.toLowerCase());
					metaAllowNew = true;
					allowErect = false;
					freeplayPrevStart = 0;
					freeplayPrevEnd = 0.2;
					songStartingBpm = try{backend.Song.getChart(getNativeSongId()+(currentDifficulty.toLowerCase() != "normal" ? currentDifficulty.toLowerCase() : ""), getNativeSongId()).bpm;}catch(e){1;}
					albumId = meta.freeplay?.album ?? '';
					instVariants = [];

					songPlayer = 'bf';
					songWeekName = '';
				} else {
					//trace("NO METADATA COULD BE LOADED :(\nUSING DEFAULTS SO FREEPLAY DOESN'T HAVE A STROKE AND DIE");
					difficultyRating = -1;
					metaAllowNew = true;
					allowErect = false;
					freeplayPrevStart = 0;
					freeplayPrevEnd = 0.2;
					songStartingBpm = try{backend.Song.getChart(getNativeSongId()+(currentDifficulty.toLowerCase() != "normal" ? currentDifficulty.toLowerCase() : ""), getNativeSongId()).bpm;}catch(e){1;}
					albumId = 'noCover';
					instVariants = [];

					songPlayer = 'bf';
					songWeekName = '';
				}
			}
		}
	}

	abstract function updateValues():Void;

	public abstract function updateIsNewTag():Void;

	public abstract function loadAndGetDiffId():Int;

	// Gets real song id (potenctally to erect variant)
	public function getNativeSongId():String
	{
		if (!allowErect)
			return songId;
		var potentiallyErect:String = (currentDifficulty == "erect") || (currentDifficulty == "nightmare") ? "-erect" : "";
		return songId + potentiallyErect;
	}
    public abstract function hasErectSong():Bool;

    // Gets real song id (potenctally to erect variant)
	public function getNativeWeekId():String {
        var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[levelId]);
        return leWeek.folder;
    }
}
