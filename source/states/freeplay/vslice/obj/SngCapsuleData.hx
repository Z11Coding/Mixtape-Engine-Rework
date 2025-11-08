package states.freeplay.vslice.obj;

import flixel.util.FlxColor;

/**
 * Scoring rank system from P-Slice
 */
enum ScoringRank {
    SHIT;
    GOOD;
    GREAT;
    EXCELLENT;
    PERFECT;
    PERFECT_GOLD;
}

/**
 * Song data for V-Slice freeplay system, adapted for Mixtape Engine
 */
class FreeplaySongData {
    public var songName:String;
    public var artist:String;
    public var charter:String;
    public var color:String;
    public var week:String;
    public var folder:String;

    // V-Slice specific properties
    public var songCharacter:Null<String>;
    public var songStartingBpm:Null<Float>;
    public var difficultyRating:Null<Int>;
    public var scoringRank:Null<ScoringRank>;
    public var isNew:Bool = false;
    public var isFav:Bool = false;
    public var songWeekName:Null<String>;
    public var songId:String;
    public var currentDifficulty:String = "normal";

    // Reference to original metadata for enhanced functionality
    public var originalMetadata:Dynamic;

    public function new(songName:String, songId:String, ?songCharacter:String) {
        this.songName = songName;
        this.songId = songId;
        this.songCharacter = songCharacter != null ? songCharacter : 'bf';
        this.artist = '';
        this.charter = '';
        this.color = '#9271FD';
        this.week = '';
        this.folder = '';
        this.songStartingBpm = 102;
        this.difficultyRating = 0;
        this.scoringRank = null;
        this.songWeekName = '';
    }

    public function toggleFavorite():Bool {
        isFav = !isFav;
        // TODO: Save to ClientPrefs
        return isFav;
    }
}

/**
 * Freeplay style data for theming
 */
class FreeplayStyle {
    public var name:String;
    public var capsuleAssetKey:String;

    public function new(name:String, ?capsuleAssetKey:String) {
        this.name = name;
        this.capsuleAssetKey = capsuleAssetKey != null ? capsuleAssetKey : 'freeplay/freeplayCapsule/freeplayCapsule';
    }

    public function getCapsuleAssetKey():String {
        return capsuleAssetKey;
    }
}
