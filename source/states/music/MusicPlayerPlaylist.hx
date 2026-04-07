package states.music;

/**
 * Represents a playlist in the Music Player
 */
class MusicPlayerPlaylist
{
	/** Playlist name/title */
	public var name:String;

	/** Playlist description */
	public var description:String = "";

	/** Songs in this playlist */
	public var songs:Array<MusicEntry> = [];

	/** Creation timestamp */
	public var createdAt:Float;

	/** Last modified timestamp */
	public var modifiedAt:Float;

	public function new(name:String)
	{
		this.name = name;
		this.createdAt = Date.now().getTime();
		this.modifiedAt = Date.now().getTime();
	}

	/**
	 * Adds a song to the playlist
	 */
	public function addSong(entry:MusicEntry):Void
	{
		if (!songs.contains(entry)) {
			songs.push(entry);
			updateModifiedTime();
		}
	}

	/**
	 * Removes a song from the playlist
	 */
	public function removeSong(entry:MusicEntry):Void
	{
		songs.remove(entry);
		updateModifiedTime();
	}

	/**
	 * Clears all songs from the playlist
	 */
	public function clear():Void
	{
		songs = [];
		updateModifiedTime();
	}

	/**
	 * Moves a song to a different index
	 */
	public function moveSong(fromIndex:Int, toIndex:Int):Void
	{
		if (fromIndex >= 0 && fromIndex < songs.length && toIndex >= 0 && toIndex < songs.length) {
			var song = songs[fromIndex];
			songs.remove(song);
			songs.insert(toIndex, song);
			updateModifiedTime();
		}
	}

	/**
	 * Updates the modified timestamp
	 */
	private function updateModifiedTime():Void
	{
		modifiedAt = Date.now().getTime();
	}

	/**
	 * Converts to JSON for persistence
	 */
	public function toJson():Dynamic
	{
		return {
			name: name,
			description: description,
			songs: songs.map((s) -> ({
				displayName: s.displayName,
				songId: s.songId,
				sourceType: s.sourceType,
				modSource: s.modSource
			})),
			createdAt: createdAt,
			modifiedAt: modifiedAt
		};
	}

	/**
	 * Creates a playlist from JSON data
	 */
	public static function fromJson(data:Dynamic):MusicPlayerPlaylist
	{
		try {
			var playlist = new MusicPlayerPlaylist(data.name);
			if (data.description != null) {
				playlist.description = data.description;
			}
			if (data.createdAt != null) {
				playlist.createdAt = data.createdAt;
			}
			if (data.modifiedAt != null) {
				playlist.modifiedAt = data.modifiedAt;
			}

			// Try to restore songs
		if (data.songs != null) {
			var songArray:Array<Dynamic> = cast data.songs;
			for (songData in songArray) {
				var entry = new MusicEntry(
					songData.displayName,
					songData.songId,
					songData.sourceType,
					songData.modSource
				);
				playlist.songs.push(entry);
			}
		}

			return playlist;
		} catch (e:Dynamic) {
			trace('Error loading playlist from JSON: $e');
			return null;
		}
	}
}
