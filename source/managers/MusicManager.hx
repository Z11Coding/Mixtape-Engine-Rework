package managers;

import options.MixtapeSettingsSubState;

class MusicManager {
    // The place all things music are tracked.
    // As the engine expands, it's gonna get harder and harder to tell what plays what where
    // So this will basically take care of all of that for you!
    //Features
    /*
        * Menu Music Control!
        * Pause Menu Music Control (TBA)
        * Editor Music Control (TBA)
        * Playstate and Mini-Playstate Music Control (TBA)
        * Add Filters and Effects (TBA)
        * Play Sounds and Layered Music (TBA)
        * Modded Music (TBA)
    */
    // Basically, if it's related to audio, it'll be ran through here.
   
    // Music specific to the Main Menu/Main Menus (Freeplay, Story Mode, etc.) 
    public static function playMenuMusic(?volume:Float, ?daSong:String, ?BPM:Float) { //It's a float because custom songs can be weird
        if (daSong != null) {
            FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/$daSong')), volume);
            if (BPM != null) Conductor.bpm = BPM;
        } else {
            setMenuMusic(ClientPrefs.data.menuSong, null, volume, true);
        }
    }

    // Music specific to the Pause Menu (This is for later)
    public static function playPauseMenuMusic(?volume:Float, ?daSong:String, ?BPM:Float) { //It's a float because custom songs can be weird
        if (daSong != null) {
            FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('pauseMusic/$daSong')), volume);
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
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('editorMusic/$daSong')), volume);
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
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/empty')), volume);
                Conductor.bpm = 0;
            case "Panix Press":
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/panixPress')), volume);
                Conductor.bpm = 150;
            case "TitleMania":
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/titlemania')), volume);
                Conductor.bpm = 100;
            case "Base Game":
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/freakyMenu')), volume);
                Conductor.bpm = 102;
            case "Freeplay Random":
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/freeplayRandom')), volume);
                Conductor.bpm = 145;
            case "Pause Menu":
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}')), volume);
                switch (ClientPrefs.data.pauseMusic)
                {
                    //dont question it
                    case 'None':
                        Conductor.bpm = 0;
                    case 'Breakfast':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[1];
                    case 'Tea Time':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[2];
                    case 'Celebration':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[3];
                    case 'Drippy Genesis':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[4];
                    case 'Reglitch':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[5];
                    case 'False Memory':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[6];
                    case 'Funky Genesis':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[7];
                    case 'Late Night Cafe':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[8];
                    case 'Late Night Jersey':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[9];
                    case 'Silly Little Sample Song':
                        Conductor.bpm = MixtapeSettingsSubState.curBPMList[10];
                }
            default:
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/$daSong')), volume);
                Conductor.bpm = BPM;
        }
    }

    // Sets the bpm of the current pause menu song or plays music that is selected by the player
    public static function setPauseMenuMusic(daSong:String, ?BPM:Null<Float>, ?volume:Float, ?playMusic:Bool = false) { //It's a float because custom songs can be weird
        switch (daSong) {
            //dont question it
            case 'None':
                Conductor.bpm = 0;
            case 'Breakfast':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[1];
            case 'Tea Time':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[2];
            case 'Celebration':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[3];
            case 'Drippy Genesis':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[4];
            case 'Reglitch':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[5];
            case 'False Memory':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[6];
            case 'Funky Genesis':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[7];
            case 'Late Night Cafe':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[8];
            case 'Late Night Jersey':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[9];
            case 'Silly Little Sample Song':
                Conductor.bpm = MixtapeSettingsSubState.curBPMList[10];
            default:
                if (playMusic) FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('pauseMusic/$daSong')), volume);
                Conductor.bpm = BPM;
        }
    }

    // plays the default editor music that is selected by the player if no song is set to play in the playEditorMusic arguments
    public static function setEditorMusic(daSong:String, ?BPM:Null<Float>, ?volume:Float, ?playMusic:Bool = false) { //It's a float because custom songs can be weird
        switch (daSong) {
            //dont question it
            case "None":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/empty')), volume);
            case "Pause Menu":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}')), volume);
            case "Menu Music" | "Menu Menu":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/${ClientPrefs.data.menuSong}')), volume);
            default:
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('editorMusic/${ClientPrefs.data.editorMusic}')), volume);
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