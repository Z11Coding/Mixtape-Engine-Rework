// artemis integration by skedgyedgy, API ver: 1.3
// https://github.com/skedgyedgy/Artemis.Plugins.FNF/releases/tags/1.3

package backend;

import flixel.util.FlxColor;
import haxe.Json;
#if sys
import haxe.Http;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class ArtemisIntegration {
    private static inline var ArtemisAPIUrlDirectoryName:String = "Artemis";
    private static inline var ArtemisAPIUrlFile:String = "./webserver.txt";
    private static inline var ArtemisAPIPluginEndpoints:String = "plugins/endpoints";
    private static inline var THETHINGIMADE:String = "plugins/84c5243c-5492-4965-940c-4ce006524c06/";

    private static var artemisApiUrl:String = "http://localhost:9696/";
    private static var fnfEndpoints:String = "http://localhost:9696/plugins/84c5243c-5492-4965-940c-4ce006524c06/";

    public static inline var DefaultModName:String = "modpack-mixup"; // if your mod completely replaces vanilla content then change this to your mod name!!!

    public static var artemisAvailable:Bool = false;

    public static function initialize ():Void {
        #if sys
        if (ClientPrefs.data.enableArtemis) {
            trace ("attempting to initialize artemis integration...");
            // get the file that says what the local artemis webserver's url is.
            // the file not being there is a pretty good indication that the user doesn't have artemis so if it isn't there just don't enable this integration
            var path:String = haxe.io.Path.join ([Sys.getEnv ("ProgramData"), ArtemisAPIUrlDirectoryName]);
            if (sys.FileSystem.exists (path) && sys.FileSystem.isDirectory (path)) {
                // is this part stupid? i'm not fluent in haxe so i have no clue if this is stupid or not i'm just rolling with what the api says
                path = haxe.io.Path.join ([path, ArtemisAPIUrlFile]);
                if (sys.FileSystem.exists (path) && !sys.FileSystem.isDirectory (path)) {
                    artemisApiUrl = sys.io.File.getContent (path);

                    // we still need to check to make sure artemis, and its webserver, are actually open
                    // if this request errors out we'll just do nothing for now
                    // TODO: make it retry after a few seconds three or five times??? it might be pointless to do that though
                    trace ("pinging artemis api webserver...");
                    var endpointsRequest = new haxe.Http (artemisApiUrl + ArtemisAPIPluginEndpoints);

                    endpointsRequest.onData = function (data:String) {
                        // do one final check to make sure we didn't just connect to some random ass webserver
                        var r = ~/[\x{200B}-\x{200D}\x{FEFF}]/g;
                        var trimmedData = r.replace (data, ''); // when the web request returns with a zero width space at the start for no fucking reason
                        // trace ("recieved response from what i think/hopefully is the artemis webserver:" + trimmedData);
                        try {
                            var response = haxe.Json.parse (trimmedData);

                            trace ("AHA that's a json response, assuming it's artemis");
                            // TODO: probably should add a check to make sure it's an actual artemis server and not just some random ass webserver that happens to match this criteria

                            fnfEndpoints = artemisApiUrl + THETHINGIMADE;
                            artemisAvailable = true;

                            setBackgroundColor ("#FF000000");
                        } catch (e) {
                            // yep nope if it's not json then it's definitely not what we're looking for
                            // just assume it's a random ass webserver and don't enable integration
                            trace ("nope nevermind, that's not json. probably not an artemis server (" + e + ")");
                        }
                    }

                    endpointsRequest.onError = function (data:String) { trace ("nope nevermind, couldn't connect to server. (recieved error " + data + ")"); }

                    endpointsRequest.request ();
                } else {
                    trace ("nope nevermind, it probably isn't installed (file's not there)");
                }
            } else {
                trace ("nope nevermind, it probably isn't installed (directory's not there)");
            }
        }
        #end
    }

    public static function sendBoyfriendHealth (health:Float) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetHealth");
            request.setPostData (Std.string (health));
            request.request (true);
        }
        #end
    }

    public static function setBackgroundFlxColor (color:FlxColor) {
        #if sys
        setBackgroundColor (StringTools.hex (color));
        #end
    }

    public static function setBackgroundColor (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetBackgroundHex");
            request.setPostData (hexCode);
            request.request (true);
        }
        #end
    }

    public static function setAccentColor1 (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetAccent1Hex");
            request.setPostData (hexCode);
            request.request (true);
        }
        #end
    }

    public static function setAccentColor2 (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetAccent2Hex");
            request.setPostData (hexCode);
            request.request (true);
        }
        #end
    }
    
    public static function setAccentColor3 (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetAccent3Hex");
            request.setPostData (hexCode);
            request.request (true);
        }
        #end
    }
    
    public static function setAccentColor4 (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetAccent4Hex");
            request.setPostData (hexCode);
            request.request (true);
        }
        #end
    }

    public static function setBlammedLights (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetBlammedHex");
            request.setPostData (Json.stringify ({ FlashHex: hexCode, FadeTime: 1 }));
            request.request (true);
        }
        #end
    }

    public static function triggerFlash (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "TriggerFlash");
            request.setPostData (Json.stringify ({ FlashHex: hexCode, FadeTime: 2 }));
            request.request (true);
        }
        #end
    }

    public static function setFadeColor (hexCode:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetFadeHex");
            request.setPostData (hexCode);
            request.request (true);
        }
        #end
    }

    public static function toggleFade (enable:Bool) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "ToggleFade");
            request.setPostData (Std.string (enable));
            request.request (true);
        }
        #end
    }

    public static function setDadHealthColor (dadHex:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetDadHex");
            request.setPostData (dadHex);
            request.request (true);
        }
        #end
    }

    public static function setBfHealthColor (bfHex:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetBFHex");
            request.setPostData (bfHex);
            request.request (true);
        }
        #end
    }

    public static function setHealthbarFlxColors (dadColor:FlxColor, bfColor:FlxColor) {
        #if sys
        if (artemisAvailable) {
            setDadHealthColor (StringTools.hex (dadColor));
            setBfHealthColor (StringTools.hex (bfColor));
        }
        #end
    }

    public static function setBeat (beat:Int) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetBeat");
            request.setPostData (Std.string (beat));
            request.request (true);
        }
        #end
    }

    public static function setSongProgress (progress:Float) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetSongProgress");
            request.setPostData (Std.string (progress));
            request.request (true);
        }
        #end
    }

    public static function setCombo (combo:Int) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetCombo");
            request.setPostData (Std.string (combo));
            request.request (true);
        }
        #end
    }

    public static function setRating (rating:Float) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetRating");
            request.setPostData (Std.string (rating));
            request.request (true);
        }
        #end
    }

    public static function noteHit (noteDirection:Int, noteType:String, accuracy:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "NoteHit");
            request.setPostData (Json.stringify ({ NoteDirection: noteDirection, NoteType: noteType, NoteHitAccuracy: accuracy }));
            request.request (true);
        }
        #end
    }

    public static function noteMiss (noteDirection:Int, noteType:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "NoteMiss");
            request.setPostData (Json.stringify ({ NoteDirection: noteDirection, NoteType: noteType }));
            request.request (true);
        }
        #end
    }

    public static function breakCombo () {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "BreakCombo");
            request.request (true);
        }
        #end
    }

    public static function setComboType (comboType:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetComboType");
            request.setPostData (comboType);
            request.request (true);
        }
        #end
    }

    public static function startSong () {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "StartSong");
            request.request (true);
        }
        #end
    }

    public static function setGameState (gameState:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetGameState");
            request.setPostData (gameState);
            request.request (true);
        }
        #end
    }

    public static function setModName (modName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetModName");
            request.setPostData (modName);
            request.request (true);
        }
        #end
    }

    public static function resetModName () {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetModName");
            request.setPostData (DefaultModName);
            request.request (true);
        }
        #end
    }

    public static function setSongName (songName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetSongName");
            request.setPostData (songName);
            request.request (true);
        }
        #end
    }

    public static function setDifficulty (difficulty:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetDifficultyName");
            request.setPostData (difficulty);
            request.request (true);
        }
        #end
    }

    public static function setDadName (dadName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetDadName");
            request.setPostData (dadName);
            request.request (true);
        }
        #end
    }

    public static function setDad2Name (dadName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetDad2Name");
            request.setPostData (dadName);
            request.request (true);
        }
        #end
    }

    public static function setBfName (bfName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetBfName");
            request.setPostData (bfName);
            request.request (true);
        }
        #end
    }

    public static function setBf2Name (bfName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetBf2Name");
            request.setPostData (bfName);
            request.request (true);
        }
        #end
    }

    public static function setGfName (gfName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetGfName");
            request.setPostData (gfName);
            request.request (true);
        }
        #end
    }

    public static function setStageName (stageName:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetStageName");
            request.setPostData (stageName);
            request.request (true);
        }
        #end
    }

    public static function setIsPixelStage (isPixelStage:Bool) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetIsPixelStage");
            request.setPostData (Std.string (isPixelStage));
            request.request (true);
        }
        #end
    }

    public static function triggerCustomEvent (eventName:String, customArgColor:String, customArgInt:Int) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "TriggerCustomEvent");
            request.setPostData (Json.stringify ({ Name: eventName, Hex: customArgColor, Num: customArgInt }));
            request.request (true);
        }
        #end
    }

    public static function autoUpdateControls () {
        #if sys
        if (artemisAvailable) {
            // help i don't know what i'm doing here so i'm playing it extremely safe
            var leftKeybinds:Array<String> = [];
            var downKeybinds:Array<String> = [];
            var upKeybinds:Array<String> = [];
            var rightKeybinds:Array<String> = [];
            var spaceKeybinds:Array<String> = [];

            switch (Note.ammo[PlayState.mania])
            {
                case 1: for (bind in ClientPrefs.keyBinds.get("note_one1")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                case 2:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_two1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_two2")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 3:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_three1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_three2")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_three3")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 4:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_left")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_down")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_up")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_right")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 5:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_five1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_five2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_five3")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_five4")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_five5")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 6:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_six1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_six2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_six3")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_six4")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_six5")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_six6")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 7:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_seven1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_seven2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_seven3")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_seven4")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_seven5")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_seven6")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_seven7")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 8:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_eight1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight5")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight6")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight7")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_eight8")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 9:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_nine1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine5")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine6")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine7")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine8")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_nine9")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 10:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_ten1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten5")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten6")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten7")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten8")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten9")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ten10")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 11:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_elev1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev5")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev6")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev7")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev8")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev9")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev10")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_elev11")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 12:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_twel1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel5")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel6")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel7")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel8")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel9")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel10")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel11")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_twel12")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 14:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_fort1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort5")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort6")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort7")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort8")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort9")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort10")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort11")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort12")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort13")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_fort14")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
                case 18:
                {
                    for (bind in ClientPrefs.keyBinds.get("note_ate1")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate2")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate3")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate4")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate5")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate6")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate7")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate8")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate9")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate10")) spaceKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate11")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate12")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate13")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate14")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate15")) leftKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate16")) downKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate17")) upKeybinds.push (InputFormatter.getKeyName (bind));
                    for (bind in ClientPrefs.keyBinds.get("note_ate18")) rightKeybinds.push (InputFormatter.getKeyName (bind));
                }
            }

            var controlMap:Map<String, Array<String>>;

            if (PlayState.mania != 3)
                controlMap = ["note_left" => leftKeybinds, "note_down" => downKeybinds, "note_up" => upKeybinds, "note_right" => rightKeybinds, "note_space" => spaceKeybinds];
            else
                controlMap = ["note_left" => leftKeybinds, "note_down" => downKeybinds, "note_up" => upKeybinds, "note_right" => rightKeybinds];
            setControls (controlMap);
        }
        #end
    }

    public static function setControls (controlMap:Map<String, Array<String>>) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetControls");
            request.setPostData (Json.stringify (controlMap));
            // trace (Json.stringify (controlMap));
            request.request (true);
        }
        #end
    }

    public static function autoUpdateControlColors (isPixelStage) {
        #if sys
        if (artemisAvailable) {
            var leftColor:FlxColor = FlxColor.fromString ("#FFC24B99");
            var downColor:FlxColor = FlxColor.fromString ("#FF00FFFF");
            var upColor:FlxColor = FlxColor.fromString ("#FF12FA05");
            var rightColor:FlxColor = FlxColor.fromString ("#FFF9393F");
            var spaceColor:FlxColor = FlxColor.fromString ("#FFFFFF");
            if (isPixelStage) {
                leftColor = FlxColor.fromString ("#FFE276FF");
                downColor = FlxColor.fromString ("#FF3DCAFF");
                upColor = FlxColor.fromString ("#FF71E300");
                rightColor = FlxColor.fromString ("#FFFF884E");
                spaceColor = FlxColor.fromString ("#FFFFFF");
            }

            var hexCodes:Map<String, String> = ["note_left" => StringTools.hex (leftColor), "note_down" => StringTools.hex (downColor), "note_up" => StringTools.hex (upColor), "note_right" => StringTools.hex (rightColor), "note_space" => StringTools.hex (spaceColor)];
            setControlColors (hexCodes);
        }
        #end
    }

    public static function setControlColors (hexCodes:Map<String, String>) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetControlColors");
            request.setPostData (Json.stringify (hexCodes));
            // trace (Json.stringify (hexCodes));
            request.request (true);
        }
        #end
    }

    public static function resetAllFlags () {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "ResetAllFlags");
            request.request (true);
        }
        #end
    }

    public static function setCustomFlag (flag:Int, value:Bool) {
        #if sys
        if (artemisAvailable) {
            var request:haxe.Http;
            if (value) request = new haxe.Http (fnfEndpoints + "EnableFlag");
            else request = new haxe.Http (fnfEndpoints + "DisableFlag");
            request.setPostData (Std.string (flag));
            request.request (true);
        }
        #end
    }

    public static function setCustomString (flag:Int, value:String) {
        #if sys
        if (artemisAvailable) {
            var request:haxe.Http = new haxe.Http (fnfEndpoints + "SetCustomString");
            request.setPostData (Json.stringify ({ Id: flag, Value: value }));
            request.request (true);
        }
        #end
    }

    public static function setCustomNumber (flag:Int, value:Int) {
        #if sys
        if (artemisAvailable) {
            var request:haxe.Http = new haxe.Http (fnfEndpoints + "SetCustomNumber");
            request.setPostData (Json.stringify ({ Id: flag, Value: value }));
            request.request (true);
        }
        #end
    }

    public static function sendProfileRelativePath (directory:String) {
        #if sys
        if (artemisAvailable) {
            sendProfileAbsolutePath (sys.FileSystem.absolutePath (directory));
        }
        #end
    }

    public static function sendProfileAbsolutePath (directory:String) {
        #if sys
        if (artemisAvailable) {
            var request = new haxe.Http (fnfEndpoints + "SetProfile");
            request.setPostData (directory);
            request.request (true);
        }
        #end
    }

    public static function onError (error:String) {
        trace (error);
    }
}