package states.music;

import flixel.graphics.frames.FlxAtlasFrames;

/**
 * Represents a playable audio entry in the Music Player.
 * Can be a song from a chart, or a standalone audio file.
 */
class MusicEntry
{
	/** Display name of the song */
	public var displayName:String;

	/** Internal song identifier (used for file paths) */
	public var songId:String;

	/** Artist name from metadata, if available */
	public var artist:String = "Unknown";

	/** Album/source information */
	public var album:String = "";

	/** Source type: "chart", "music_folder", "mod_music", etc. */
	public var sourceType:String;

	/** Mod directory this comes from, null = base game */
	public var modSource:String;

	/** Path to album artwork, null = no cover */
	public var coverPath:String;

	/** Whether this song has an instrumental track */
	public var hasInst:Bool = true;

	/** Whether this song has vocal tracks */
	public var hasVocals:Bool = true;

	/** Whether this song has player-specific vocals */
	public var hasPlayerVocals:Bool = false;

	/** Whether this song has opponent-specific vocals */
	public var hasOpponentVocals:Bool = false;

	/** Whether this song has GF-specific vocals */
	public var hasGFVocals:Bool = false;

	/** Character associated with this song (for charts) */
	public var character:String = "";

	/** Stage associated with this song (for charts) */
	public var stage:String = "";

	/** BPM if available */
	public var bpm:Float = 0;

	/** Duration in seconds if available */
	public var duration:Float = 0;

	public function new(displayName:String, songId:String, sourceType:String, modSource:String = null)
	{
		this.displayName = displayName;
		this.songId = songId;
		this.sourceType = sourceType;
		this.modSource = modSource;
		this.coverPath = null;
	}

	/**
	 * Returns a display label showing the song source
	 */
	public function getSourceLabel():String
	{
		if (sourceType == "chart") {
			return modSource != null ? '[${modSource}]' : '[Base Game]';
		}
		if (sourceType == "mod_music") {
			return modSource != null ? '[Music - ${modSource}]' : '[Music]';
		}
		if (sourceType == "base_music") {
			return "[Music - Base]";
		}
		return "[$sourceType]";
	}

	/**
	 * Returns full display label with artist
	 */
	public function getFullLabel():String
	{
		var label = displayName;
		if (artist != null && artist != "" && artist != "Unknown") {
			label += ' - $artist';
		}
		return label;
	}

	/**
	 * Returns true if this is a modded entry
	 */
	public function isModded():Bool
	{
		return modSource != null && modSource != "";
	}

	/**
	 * Returns true if this can be played with separate track control
	 */
	public function supportsSeparateTracks():Bool
	{
		return sourceType == "chart" && (hasInst || hasVocals);
	}
}
