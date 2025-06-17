package yutautil.fnf;

import backend.Song.SwagSong;
import metadata.STMetaFile.SongMetaSection;
import haxe.macro.Expr;
import haxe.io.File;
import haxe.macro.Context;
import haxe.io.Path;
import sys.io.File;
class IntegratedSong {

    public var swagSong:SwagSong; // The chart data
    public var metaData:SongMetaSection; // The metadata
    public var instrumental:FlxSound; // The instrumental sound, if any
    public var vocals:{
        bf:FlxSound,
        opponent:FlxSound,
        ?gf:FlxSound,
        ?other:Array<FlxSound>
    }; // Vocals for each character
    public var stage:flixel.util.typeLimit.OneofThree<
        stages.BaseStage,
        flixel.util.typeLimit.OneofTwo<psychlua.FunkinLua, psychlua.LegacyFunkinLua>,
        psychlua.HScript
    >; // The stage data, can be a BaseStage, FunkinLua, or HScript

    public function new(
        swagSong:SwagSong,
        metaData:SongMetaSection,
        instrumental:FlxSound = null,
        vocals:{
            bf:FlxSound,
            opponent:FlxSound,
            ?gf:FlxSound,
            ?other:Array<FlxSound>
        } = null,
        stage:flixel.util.typeLimit.OneofThree<
            stages.BaseStage,
            flixel.util.typeLimit.OneofTwo<psychlua.FunkinLua, psychlua.LegacyFunkinLua>,
            psychlua.HScript
        > = null
    ) {
        this.swagSong = swagSong;
        this.metaData = metaData;
        this.instrumental = instrumental;
        this.vocals = vocals != null ? vocals : {
            bf: null,
            opponent: null,
            gf: null,
            other: []
        };
        this.stage = stage;
    }

    // public function loadData():Void {
    //     // Load the song data from the swagSong
    //     // This could include parsing notes, events, etc.
    //     // For now, we just ensure the data is loaded
    //     if (swagSong == null) {
    //         throw "SwagSong data is not initialized.";
    //     }
    // }
}

class IntegratedSongInit {

    public static function create(swagSong:String, metaData:{
        name:String,
        artist:String,
        charter:String,
        mod:String
    }, ?instrumental:FlxSound, ?vocals:{
        bf:FlxSound,
        opponent:FlxSound,
        ?gf:FlxSound,
        ?other:Array<FlxSound>
    }, ?stage:flixel.util.typeLimit.OneofThree<
        stages.BaseStage,
        flixel.util.typeLimit.OneofTwo<psychlua.FunkinLua, psychlua.LegacyFunkinLua>,
        psychlua.HScript
    >):IntegratedSong {
        // Parse the swagSong JSON string into a SwagSong object
        var parsedSwagSong = haxe.Json.parse(swagSong);
        var song = new SwagSong(parsedSwagSong);
        
    }

    public static function fromSwagSong(swagSong:SwagSong):IntegratedSong {
        return new IntegratedSong(swagSong, {
            name: swagSong.song,
            artist: "",
            charter: "",
            mod: ""
        });
    }

    public macro function getFromFile(filePath:String, ?meta:SongMetaSection):Expr {
        var swagSong = haxe.io.File.getContent(filePath);
        var metaData = {
            name: "",
            artist: "",
            charter: "",
            mod: ""
        };
        if (meta != null) {
            metaData = meta;
        }
        return macro IntegratedSongInit.create(swagSong, metaData);
    }
}



class DeltaruneChartParser {

    /**
     * Parses a Deltarune-style chart text file into an IntegratedSong.
     * Each line: <time>,<column>,<sustainStart>[,<sustainEnd>]
     * This is making a lot of assumptions about the format, so it may need adjustments.
     */
    public static function parseChartFile(filePath:String):IntegratedSong {
        var lines = File.getContent(filePath).split("\n");
        var notes = [];
        for (line in lines) {
            line = StringTools.trim(line);
            if (line == "" || line.charAt(0) == "#") continue; // skip empty/comments
            var parts = line.split(",");
            if (parts.length < 3) continue;
            var strTime = parts[0];
            var strCol = parts[1];
            var strSusStart = parts[2];
            var strSusEnd = parts.length > 3 ? parts[3] : null;

            var time = Std.parseFloat(strTime);
            var col = Std.parseInt(strCol);
            var susStart = Std.parseFloat(strSusStart);
            var susEnd = strSusEnd != null ? Std.parseFloat(strSusEnd) : null;

            var note = {
                strumTime: time,
                noteData: col,
                sustainLength: (susEnd != null && susEnd > time) ? (susEnd - time) : 0,
                type: 0,
                mustPress: col == 1 // Example: 1 = player, 0 = opponent
            };
            notes.push(note);
        }

        var swagSongData = {
            song: Path.withoutExtension(Path.withoutDirectory(filePath)),
            notes: [{
                sectionNotes: notes,
                lengthInSteps: 16,
                typeOfSection: 0,
                mustHitSection: true
            }]
        };

        var swagSong = new SwagSong(swagSongData);

        return new IntegratedSong(swagSong, {
            name: swagSongData.song,
            artist: "Unknown",
            charter: "Unknown",
            mod: "Deltarune"
        });
    }
}