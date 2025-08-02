package source.objects;

package objects;

abstract Strum(Dynamic) from Dynamic to Dynamic {
    public inline function new(value:Dynamic) {
        this = value;
    }

    public inline function toStrumNote():StrumNote {
        return cast this;
    }

    public inline function toString():String {
        return Std.string(this);
    }
    
    @:from
    public static function fromStrumNote(note:StrumNote):Strum {
        return cast note;
    }

    @:from
    public static function fromChartingStrumNote(note:objects.charting.ChartingStrumNote):Strum {
        return cast note;
    }

    @:to
    public static function toStrumNote(strum:Strum):StrumNote {
        return cast strum;
    }

    @:to
    public static function toChartingStrumNote(strum:Strum):objects.charting.ChartingStrumNote {
        return cast strum;
    }

    public static function createStrumNote(x:Float, y:Float, leData:Int, ?playField:objects.playfields.PlayField):Strum {
        return cast new StrumNote(x, y, leData, playField);
    }

    public static function createChartingStrumNote(x:Float, y:Float, leData:Int, player:Int):Strum {
        return cast new objects.charting.ChartingStrumNote(x, y, leData, player);
    }

    public static function createStrum(x:Float, y:Float, leData:Int, player:Int):Strum {
        return cast new StrumNote(x, y, leData, player);
    }

    public inline function toChartingStrumNote():objects.charting.ChartingStrumNote {
        return cast this;
    }
}