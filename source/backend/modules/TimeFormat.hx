package backend.modules;

class TimeFormat {
    private var minutes:Int;
    private var seconds:Int;
    private var decimals:Int;
    private var totalTimeInDecimals:Float;

    public function new(minutes:Int, seconds:Int, decimals:Int = 0) {
        this.minutes = minutes;
        this.seconds = seconds;
        this.decimals = decimals;
        this.wrapSeconds();
        this.updateTotalTimeInDecimals();
    }

    private function wrapSeconds():Void {
        if (this.seconds >= 60) {
            this.minutes += Std.int(this.seconds / 60);
            this.seconds = this.seconds % 60;
        }
    }

    private function updateTotalTimeInDecimals():Void {
        this.totalTimeInDecimals = this.minutes + this.seconds / 60 + this.decimals / 60000;
    }

    public function toMilliseconds():Float {
        return (this.minutes * 60 + this.seconds) * 1000 + this.decimals;
    }

    public function toMinutesWithDecimals():Float {
        return this.totalTimeInDecimals;
    }

    public function toSecondsWithDecimals():Float {
        return this.minutes * 60 + this.seconds + this.decimals / 1000;
    }

        public function toString(decimalPlaces:Int = 0):String {
            var decimalsString:String = "";
            if (decimalPlaces > 0) {
                decimalsString = "." + Std.string(this.decimals).substr(0, decimalPlaces);
            }
            return Std.string(this.minutes) + ":" + Std.string(this.seconds) + decimalsString;
        }

    public static function fromMilliseconds(milliseconds:Float):TimeFormat {
        var totalSeconds = milliseconds / 1000;
        var minutes = Std.int(totalSeconds / 60);
        var seconds = Std.int(totalSeconds % 60);
        var decimals = Std.int((totalSeconds - Std.int(totalSeconds)) * 1000);
        return new TimeFormat(minutes, seconds, decimals);
    }

    public static function fromMinutesWithDecimals(minutesWithDecimals:Float):TimeFormat {
        var minutes = Std.int(minutesWithDecimals);
        var seconds = Std.int((minutesWithDecimals - minutes) * 60);
        var decimals = Std.int(((minutesWithDecimals - minutes) * 60 - Std.int((minutesWithDecimals - minutes) * 60)) * 1000);
        return new TimeFormat(minutes, seconds, decimals);
    }

    public static function fromSecondsWithDecimals(secondsWithDecimals:Float):TimeFormat {
        var minutes = Std.int(secondsWithDecimals / 60);
        var seconds = Std.int(secondsWithDecimals % 60);
        var decimals = Std.int((secondsWithDecimals - Std.int(secondsWithDecimals)) * 1000);
        return new TimeFormat(minutes, seconds, decimals);
    }

    public static function fromText(text:String):TimeFormat {
        var parts:Array<String> = text.split(":");
        var minutes:Int = Std.parseInt(parts[0]);
        var seconds:Int = 0;
        var decimals:Int = 0;
    
        if (parts.length > 1) {
            var secondsParts:Array<String> = parts[1].split(".");
            seconds = Std.parseInt(secondsParts[0]);
            if (secondsParts.length > 1) {
                var decimalsString:String = secondsParts[1];
                decimals = Std.parseInt(decimalsString);
                decimals = decimals * Math.pow(10, 3 - decimalsString.length);
            }
        }
    
        return new TimeFormat(minutes, seconds, decimals);
    }

    public static macro function fromExpression(expr:Expr):Expr {
        return TimeFormatMacro.fromExpression(expr);
    }

    
}
