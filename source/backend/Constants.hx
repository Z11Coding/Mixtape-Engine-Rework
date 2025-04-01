package backend;
import options.MixtapeSettingsSubState;

class Constants {
    // Things that dont change/change very little go here

    public static function playMenuMusic(?volume:Float, ?daSong:String, ?BPM:Float) { //It's a float because custom songs can be weird
        if (daSong != null) {
            FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/$daSong')), volume);
            if (BPM != null) Conductor.bpm = BPM;
        } else {
            changeMenuMusic(ClientPrefs.data.menuSong, null, volume);
        }
    }
    
    public static function changeMenuMusic(daSong:String, ?BPM:Null<Float>, ?volume:Float) { //It's a float because custom songs can be weird
        switch (daSong) {
            case "None":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/empty')), volume);
                Conductor.bpm = 0;
            case "Panix Press":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/panixPress')), volume);
                Conductor.bpm = 150;
            case "TitleMania":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/titlemania')), volume);
                Conductor.bpm = 100;
            case "Base Game":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/freakyMenu')), volume);
                Conductor.bpm = 102;
            case "Freeplay Random":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/freeplayRandom')), volume);
                Conductor.bpm = 145;
            case "Pause Menu":
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('pauseMusic/${ClientPrefs.data.pauseMusic}')), volume);
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
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath('menuMusic/$daSong')), volume);
                Conductor.bpm = BPM;
        }

    }
}