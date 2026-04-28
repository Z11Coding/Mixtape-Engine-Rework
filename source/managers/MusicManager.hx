package managers;

import options.MixtapeSettingsSubState;
import yutautil.ExtendedDate;

// Abstract for handling both path and sound returns
abstract MusicResource(Dynamic) {

    public var path(get, never):String;
    public var sound(get, never):FlxSound;

    public inline function get_path():String {
        return toString();
    }

    public inline function get_sound():FlxSound {
        return toFlxSound();
    }

    public inline function new(value:Dynamic) {
        this = value;
    }

    @:from static function fromString(path:String):MusicResource {
        return new MusicResource(path);
    }

    @:from static function fromFlxSound(sound:FlxSound):MusicResource {
        return new MusicResource(sound);
    }
    @:from static function fromSound(s:openfl.media.Sound):MusicResource {
        var flxSound:FlxSound = new FlxSound();
        flxSound.loadEmbedded(s, false, false);
        return new MusicResource(flxSound);
    }

    @:to public function toString():String {
        if (Std.isOfType(this, String)) {
            return cast this;
        } else if (Std.isOfType(this, FlxSound)) {
            var sound:FlxSound = cast this;
            @:privateAccess
            return sound._sound != null ? sound._sound.url : "";
        }
        return "";
    }

    @:to public function toFlxSound():FlxSound {
        if (Std.isOfType(this, FlxSound)) {
            return cast this;
        } else if (Std.isOfType(this, String)) {
            var path:String = cast this;
            return FlxG.sound.load(path, 1, false);
        }
        return null;
    }

    @:to public function toCompatible():flixel.util.typeLimit.OneOfThree<String, openfl.media.Sound, Class<openfl.media.Sound>> {
        if (Std.isOfType(this, String)) {
            return cast this;
        }

        if (Std.isOfType(this, FlxSound)) {
            var sound:FlxSound = cast this;
            @:privateAccess
            if (sound._sound != null) return sound._sound;
        }

        if (Std.isOfType(this, openfl.media.Sound)) {
            return cast this;
        }

        if (this.isClassOfType(openfl.media.Sound)) {
            return cast this;
        }

        throw "MusicResource cannot be converted to a compatible type";
    }

    public function getPath():String {
        return toString();
    }

    public function getSound(?volume:Float = 1.0):FlxSound {
        return toFlxSound().funcAndReturn(function(snd:FlxSound) {
            snd.volume = volume;
        });
    }

    public function isPath():Bool {
        return Std.isOfType(this, String);
    }

    public function isSound():Bool {
        return Std.isOfType(this, FlxSound);
    }
}

class MusicManager {
    // The place all things music are tracked.
    // As the engine expands, it's gonna get harder and harder to tell what plays what where
    // So this will basically take care of all of that for you!
    //Features
    /*
        * Menu Music Control!
        * Pause Menu Music Control!
        * Editor Music Control!
        * Playstate and Mini-Playstate Music Control (TBA)
        * Add Filters and Effects (TBA)
        * Play Sounds and Layered Music (TBA)
        * Modded Music (TBA)
    */
    // Basically, if it's related to audio, it'll be ran through here.

    // Music specific to the Main Menu/Main Menus (Freeplay, Story Mode, etc.)
    public static function playMenuMusic(?volume:Float, ?daSong:String, ?BPM:Float) { //It's a float because custom songs can be weird
        if (daSong != null) {
            MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/$daSong'), volume);
            if (BPM != null) Conductor.bpm = BPM;
        } else {
            setMenuMusic(ClientPrefs.data.menuSong, null, volume, true);
        }
    }

    // Music specific to the Pause Menu (This is for later)
    public static function playPauseMenuMusic(?volume:Float, ?daSong:String, ?BPM:Float) { //It's a float because custom songs can be weird
        if (daSong != null) {
            MegaManager.conductor.playMusic(Paths.formatToSongPath('pauseMusic/$daSong'), volume);
            if (BPM != null) Conductor.bpm = BPM;
        } else {
            setPauseMenuMusic(ClientPrefs.data.pauseMusic, null, volume, true);
        }
    }

    // Music specific to the Editors (except for the chart editor)
    // This one is separate because it can't mess with the BPM
    public static function playEditorMusic(?volume:Float, ?isChartEditor:Bool = false, ?daSong:String, ?BPM:Float) { //It's a float because custom songs can be weird
        if (!isChartEditor) { //Behave like normal
            if (daSong != null) {
                MegaManager.conductor.playMusic(Paths.formatToSongPath('editorMusic/$daSong'), volume);
            } else {
                setEditorMusic(ClientPrefs.data.editorMusic, null, volume, true);
            }
        } else {

        }
    }

    // plays the default menu music that is selected by the player if no song is set to play in the playMenuMusic arguments
    public static function setMenuMusic(daSong:String, ?BPM:Null<Float>, ?volume:Float, ?playMusic:Bool = false) { //It's a float because custom songs can be weird
        switch (daSong) {
            case "None":
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/none'), volume);
                Conductor.bpm = 0;
            case "Panix Press":
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/panixPress'), volume);
                Conductor.bpm = 150;
            case "TitleMania":
                if (playMusic)  {
                    trace('Current Hour: ${ExtendedDate.global().getHours()}');
                    if (ExtendedDate.global().getHours() > 19 || ExtendedDate.global().getHours() < 7) {
                        MegaManager.conductor.playMusic('menuMusic/titlemania-(night-mix)', volume);
                        Conductor.bpm = 90;
                    } else {
                        MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/titlemania'), volume);
                        Conductor.bpm = 100;
                    }
                }
            case "Base Game":
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/freakyMenu'), volume);
                Conductor.bpm = 102;
            case "Freeplay Random":
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/freeplayRandom'), volume);
                Conductor.bpm = 145;
            case "Pause Menu":
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}'), volume);
                switch (ClientPrefs.data.pauseMusic)
                {
                    //There's 100% a better way to do this im just lazy
                    case 'None':
                        Conductor.bpm = 0;
                    case 'Breakfast':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[1];
                    case 'Breakfast (Pixel)':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[2];
                    case 'Breakfast (Pico)':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[3];
                    case 'girlfriendsRingtone':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[4];
                    case 'stayFunky':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[5];
                    case 'Tea Time':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[6];
                    case 'Celebration':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[7];
                    case 'Drippy Genesis':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[8];
                    case 'Reglitch':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[9];
                    case 'False Memory':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[10];
                    case 'Funky Genesis':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[11];
                    case 'Late Night Cafe':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[12];
                    case 'Late Night Jersey':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[13];
                    case 'Silly Little Sample Song':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[14];
                }
            default:
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/$daSong'), volume);
                Conductor.bpm = BPM;
        }
    }

    // Sets the bpm of the current pause menu song or plays music that is selected by the player
    public static function setPauseMenuMusic(daSong:String, ?BPM:Null<Float>, ?volume:Float, ?playMusic:Bool = false) { //It's a float because custom songs can be weird
        switch (daSong) {
            //dont question it
            case 'None':
                Conductor.bpm = 0;
                FlxG.sound.music.volume = 0;
            case 'Breakfast':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[1];
            case 'Breakfast (Pixel)':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[2];
            case 'Breakfast (Pico)':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[3];
            case 'girlfriendsRingtone':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[4];
            case 'stayFunky':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[5];
            case 'Tea Time':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[6];
            case 'Celebration':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[7];
            case 'Drippy Genesis':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[8];
            case 'Reglitch':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[9];
            case 'False Memory':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[10];
            case 'Funky Genesis':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[11];
            case 'Late Night Cafe':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[12];
            case 'Late Night Jersey':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[13];
            case 'Silly Little Sample Song':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[14];
            default:
                if (playMusic) MegaManager.conductor.playMusic(Paths.formatToSongPath('pauseMusic/$daSong'), volume);
                Conductor.bpm = BPM;
        }
    }

    // plays the default editor music that is selected by the player if no song is set to play in the playEditorMusic arguments
    public static function setEditorMusic(daSong:String, ?BPM:Null<Float>, ?volume:Float, ?playMusic:Bool = false) { //It's a float because custom songs can be weird
        switch (daSong) {
            //dont question it
            case "None":
                MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/empty'), volume);
            case "Pause Menu":
                MegaManager.conductor.playMusic(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}'), volume);
            case "Menu Music" | "Menu Menu":
                MegaManager.conductor.playMusic(Paths.formatToSongPath('menuMusic/${ClientPrefs.data.menuSong}'), volume);
            default:
                MegaManager.conductor.playMusic(Paths.formatToSongPath('editorMusic/${ClientPrefs.data.editorMusic}'), volume);
        }
    }

    // GET MUSIC FUNCTIONS - Return FlxSound objects or paths instead of directly playing

    // Get menu music as FlxSound or path
    public static function getMenuMusic(?daSong:String, ?volume:Float = 1.0, ?returnPath:Bool = false):MusicResource {
        var targetSong = daSong != null ? daSong : ClientPrefs.data.menuSong;
        var musicPath:MusicResource;

        switch (targetSong) {
            case "None":
                musicPath = Paths.formatToSongPath('menuMusic/empty');
            case "Panix Press":
                musicPath = Paths.formatToSongPath('menuMusic/panixPress');
            case "TitleMania":
                musicPath = Paths.formatToSongPath('menuMusic/titlemania');
            case "Base Game":
                musicPath = Paths.formatToSongPath('menuMusic/freakyMenu');
            case "Freeplay Random":
                musicPath = Paths.formatToSongPath('menuMusic/freeplayRandom');
            case "Pause Menu":
                musicPath = Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}');
            default:
                musicPath = Paths.formatToSongPath('menuMusic/$targetSong');
        }

        return returnPath ? new MusicResource(musicPath).path : new MusicResource(new FlxSound().loadEmbedded(musicPath, false, false).funcAndReturn(function(snd:FlxSound) {
            snd.volume = volume;
        }));
    }

    // Get pause menu music as FlxSound or path
    public static function getPauseMenuMusic(?daSong:String, ?volume:Float = 1.0, ?returnPath:Bool = false):MusicResource {
        var targetSong = daSong != null ? daSong : ClientPrefs.data.pauseMusic;
        var musicPath:MusicResource;

        switch (targetSong) {
            case 'None':
                musicPath = Paths.formatToSongPath('pauseMusic/empty');
            default:
                musicPath = Paths.formatToSongPath('pauseMusic/$targetSong');
        }

        return returnPath ? new MusicResource(musicPath).path : new MusicResource(new FlxSound().loadEmbedded(musicPath, false, false).funcAndReturn(function(snd:FlxSound) {
            snd.volume = volume;
        }));
    }

    // Get editor music as FlxSound or path
    public static function getEditorMusic(?daSong:String, ?volume:Float = 1.0, ?returnPath:Bool = false):MusicResource {
        var targetSong = daSong != null ? daSong : ClientPrefs.data.editorMusic;
        var musicPath:MusicResource;

        switch (targetSong) {
            case "None":
                musicPath = Paths.formatToSongPath('menuMusic/empty');
            case "Pause Menu":
                musicPath = Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}');
            case "Menu Music" | "Menu Menu":
                musicPath = Paths.formatToSongPath('menuMusic/${ClientPrefs.data.menuSong}');
            default:
                musicPath = Paths.formatToSongPath('editorMusic/$targetSong');
        }

        return returnPath ? new MusicResource(musicPath).path : new MusicResource(new FlxSound().loadEmbedded(musicPath, false, false).funcAndReturn(function(snd:FlxSound) {
            snd.volume = volume;
        }));
    }

    // Utility function to get BPM for a specific song
    public static function getBPMForSong(songName:String, songType:String = "menu"):Float {
        switch (songType) {
            case "menu":
                switch (songName) {
                    case "None": return 0;
                    case "Panix Press": return 150;
                    case "TitleMania": return 100;
                    case "Base Game": return 102;
                    case "Freeplay Random": return 145;
                    default: return 120; // Default BPM
                }
            case "pause":
                switch (songName) {
                    case 'None': return 0;
                    case 'Breakfast': return MixtapeSettingsSubState.curBPMList[1];
                    case 'Breakfast (Pixel)': return MixtapeSettingsSubState.curBPMList[2];
                    case 'Breakfast (Pico)': return MixtapeSettingsSubState.curBPMList[3];
                    case 'girlfriendsRingtone': return MixtapeSettingsSubState.curBPMList[4];
                    case 'stayFunky': return MixtapeSettingsSubState.curBPMList[5];
                    case 'Tea Time': return MixtapeSettingsSubState.curBPMList[6];
                    case 'Celebration': return MixtapeSettingsSubState.curBPMList[7];
                    case 'Drippy Genesis': return MixtapeSettingsSubState.curBPMList[8];
                    case 'Reglitch': return MixtapeSettingsSubState.curBPMList[9];
                    case 'False Memory': return MixtapeSettingsSubState.curBPMList[10];
                    case 'Funky Genesis': return MixtapeSettingsSubState.curBPMList[11];
                    case 'Late Night Cafe': return MixtapeSettingsSubState.curBPMList[12];
                    case 'Late Night Jersey': return MixtapeSettingsSubState.curBPMList[13];
                    case 'Silly Little Sample Song': return MixtapeSettingsSubState.curBPMList[14];
                    default: return 120; // Default BPM
                }
            default:
                return 120; // Default BPM
        }
    }
}

class MusicControlPanel {
    // I'll make this later
}

class PlaylistHandler {
    // I'll make this later
}

class FavoritesHandler {
    // I'll make this later
}

class MusicSelectMenu extends MusicBeatState {
    // I'll make this later
}

class QuickMusicSelectMenu extends MusicBeatSubstate {
    // I'll make this later
}
