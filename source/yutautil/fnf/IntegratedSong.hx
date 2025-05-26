package yutautil.fnf;

import backend.Song.SwagSong;
import metadata.STMetaFile.SongMetaSection;
import haxe.macro.Expr;
import haxe.io.File;
import haxe.macro.Context;

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