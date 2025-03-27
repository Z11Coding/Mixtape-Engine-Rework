package yutautil;

import Date;
import flixel.FlxBasic;

enum Month {
    January;
    February;
    March;
    April;
    May;
    June;
    July;
    August;
    September;
    October;
    November;
    December;
}

enum Day {
    Sunday;
    Monday;
    Tuesday;
    Wednesday;
    Thursday;
    Friday;
    Saturday;
}

typedef NewDateObject = {year:Null<Int>, month:Null<Int>, day:Null<Int>, ?hour:Int, ?minute:Int, ?second:Int};

typedef DateHandler = flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>;

class ExtendedDate extends FlxBasic {
    public static var date:Date;

    public var dateAccess:Dynamic;

    public function new(year:Int, month:Int, day:Int, hour:Int = 0, minute:Int = 0, second:Int = 0) {
        if (ExtendedDate.date == null) {
            ExtendedDate.date = Date.now();
            trace("Initializing date...");
        }
        this.dateAccess = ExtendedDate.date;
        super();
        trace("It is currently " + this.dateAccess);
    }

    public static function createDate(type:Class<flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>>, now:Bool, _construct:NewDateObject):flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate> {
        return now ? (type == Date ? Date.now() : ExtendedDate.newDate()) :
            (_construct != null && _construct.year != null && _construct.month != null && _construct.day != null ? 
                (type == Date ? new Date(_construct.year, _construct.month, _construct.day, _construct.hour, _construct.minute, _construct.second) : new ExtendedDate(_construct.year, _construct.month, _construct.day, _construct.hour, _construct.minute, _construct.second)) : 
                (type == Date ? Date.now() : ExtendedDate.newDate()));
    }


    public static function newDate():ExtendedDate {
        return ExtendedDate.fromDate(Date.now());
    }
        
        
    public static function fromDate(date:Date):ExtendedDate {
        return new ExtendedDate(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
    }

    public static function fromDateType(date:flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>):ExtendedDate {
        var date:Dynamic = date;
        return new ExtendedDate(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
    }

    public function getFullYear():Int {
        return this.dateAccess.getFullYear();
    }

    public function getMonth():Int {
        return this.dateAccess.getMonth();
    }

    public function getDate():Int {
        return this.dateAccess.getDate();
    }

    public function getDay():Int {
        return this.dateAccess.getDay();
    }

    public function getHours():Int {
        return this.dateAccess.getHours();
    }

    public function getMinutes():Int {
        return this.dateAccess.getMinutes();
    }

    public function getSeconds():Int {
        return this.dateAccess.getSeconds();
    }

    public function getTime():Float {
        return this.dateAccess.getTime();
    }

    public function isMonth(month:Month):Bool {
        return this.getMonth() == Type.enumIndex(month);
    }

    public function isDay(day:Day):Bool {
        return this.getDay() == Type.enumIndex(day);
    }

    public function isWeekend():Bool {
        return this.isDay(Day.Saturday) || this.isDay(Day.Sunday);
    }

    public function isWeekday():Bool {
        return !this.isWeekend();
    }

    public function asString():String {
        return this.formatDate("%Y-%m-%d %H:%M:%S");
    }

    public static function getMonthByName(name:String):Month {
        return switch (name.toLowerCase()) {
            case "january": Month.January;
            case "february": Month.February;
            case "march": Month.March;
            case "april": Month.April;
            case "may": Month.May;
            case "june": Month.June;
            case "july": Month.July;
            case "august": Month.August;
            case "september": Month.September;
            case "october": Month.October;
            case "november": Month.November;
            case "december": Month.December;
            default: throw "Invalid month name";
        }
    }

    public static function getDayByName(name:String):Day {
        return switch (name.toLowerCase()) {
            case "sunday": Day.Sunday;
            case "monday": Day.Monday;
            case "tuesday": Day.Tuesday;
            case "wednesday": Day.Wednesday;
            case "thursday": Day.Thursday;
            case "friday": Day.Friday;
            case "saturday": Day.Saturday;
            default: throw "Invalid day name";
        }
    }

    public static function getMonthNumber(month:Month):Int {
        return Type.enumIndex(month);
    }

    public static function getDayNumber(day:Day):Int {
        return Type.enumIndex(day);
    }

    public override function update(elapsed:Float):Void {
        ExtendedDate.date = Date.now();
        dateAccess = ExtendedDate.date;
        super.update(elapsed);
    }

    public static function getMonthByNumber(number:Int):Month {
        return switch (number-1) {
            case 0: Month.January;
            case 1: Month.February;
            case 2: Month.March;
            case 3: Month.April;
            case 4: Month.May;
            case 5: Month.June;
            case 6: Month.July;
            case 7: Month.August;
            case 8: Month.September;
            case 9: Month.October;
            case 10: Month.November;
            case 11: Month.December;
            default: throw "Invalid month number";
        }
    }

    public static function getDayByNumber(number:Int):Day {
        return switch (number-1) {
            case 0: Day.Sunday;
            case 1: Day.Monday;
            case 2: Day.Tuesday;
            case 3: Day.Wednesday;
            case 4: Day.Thursday;
            case 5: Day.Friday;
            case 6: Day.Saturday;
            default: throw "Invalid day number";
        }
    }

    public function getDaysInMonth():Int {
        var month = this.getMonth();
        if (month == 1) {
            return this.isLeapYear() ? 29 : 28;
        } else if (month == 3 || month == 5 || month == 8 || month == 10) {
            return 30;
        } else {
            return 31;
        }
    }

    public function getDaysInYear():Int {
        return this.isLeapYear() ? 366 : 365;
    }

    public function getDaysLeftInMonth():Int {
        return this.getDaysInMonth() - this.getDate();
    }

    public function getDaysLeftInYear():Int {
        return this.getDaysInYear() - this.getDayOfYear();
    }

    public function getDayOfYear():Int {
        var dayOfYear = 0;
        for (i in 0...this.getMonth()) {
            dayOfYear += new ExtendedDate(this.getFullYear(), i, 1).getDaysInMonth();
        }
        return dayOfYear + this.getDate();
    }

    public function getWeekOfYear():Int {
        var firstDay = new ExtendedDate(this.getFullYear(), 0, 1);
        var diff = this.getTime() - firstDay.getTime();
        return Math.ceil(diff / (1000 * 60 * 60 * 24 * 7));
    }

    public function getWeekOfMonth():Int {
        return Math.ceil(this.getDate() / 7);
    }

    public function getWeeksLeftInYear():Int {
        return 52 - this.getWeekOfYear();
    }

    public function getWeeksLeftInMonth():Int {
        return Math.ceil(this.getDaysLeftInMonth() / 7);
    }

    public function today():ExtendedDate {
        return new ExtendedDate(this.getFullYear(), this.getMonth(), this.getDate());
    }

    public function tomorrow():ExtendedDate {
        return new ExtendedDate(this.getFullYear(), this.getMonth(), this.getDate() + 1);
    }

    public function yesterday():ExtendedDate {
        return new ExtendedDate(this.getFullYear(), this.getMonth(), this.getDate() - 1);
    }

    public function time():String {
        return this.formatDate("%H:%M:%S");
    }

    public static function exactTimeNow():String {
        // Return the date, as well as PC Time.
        
        return ExtendedDate.fromDate(Date.now()).formatDate("%Y-%m-%d %H:%M:%S");
    }

    public static function calcImpossibleDate():ExtendedDate {
        return new ExtendedDate(0, 0, 0, 0, 0, 0);
    }

    public static function fromString(date:String, format:String):ExtendedDate {
        var year = 0;
        var month = 0;
        var day = 0;
        var hour = 0;
        var minute = 0;
        var second = 0;
        var parts = format.split("");
        var values = date.split("");
        for (i in 0...parts.length) {
            switch (parts[i]) {
                case "%Y": year = Std.parseInt(values[i]);
                case "%m": month = Std.parseInt(values[i]);
                case "%d": day = Std.parseInt(values[i]);
                case "%H": hour = Std.parseInt(values[i]);
                case "%M": minute = Std.parseInt(values[i]);
                case "%S": second = Std.parseInt(values[i]);
            }
        }
        return new ExtendedDate(year, month, day, hour, minute, second);
    }

    

    public function formatDate(format:String):String {
        var formatted:String = format;
        formatted = formatted.replace("%Y", "" + this.getFullYear());
        formatted = formatted.replace("%m", StringTools.lpad("" + (this.getMonth() + 1), "0", 2));
        formatted = formatted.replace("%d", StringTools.lpad("" + this.getDate(), "0", 2));
        formatted = formatted.replace("%H", StringTools.lpad("" + this.getHours(), "0", 2));
        formatted = formatted.replace("%M", StringTools.lpad("" + this.getMinutes(), "0", 2));
        formatted = formatted.replace("%S", StringTools.lpad("" + this.getSeconds(), "0", 2));
        return formatted;
    }

    public static function formatDateObject(date:flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>, format:String):String {
        var date:Dynamic = date;
        var formatted:String = format;
        formatted = formatted.replace("%Y", "" + date.getFullYear());
        formatted = formatted.replace("%m", StringTools.lpad("" + (date.getMonth() + 1), "0", 2));
        formatted = formatted.replace("%d", StringTools.lpad("" + date.getDate(), "0", 2));
        formatted = formatted.replace("%H", StringTools.lpad("" + date.getHours(), "0", 2));
        formatted = formatted.replace("%M", StringTools.lpad("" + date.getMinutes(), "0", 2));
        formatted = formatted.replace("%S", StringTools.lpad("" + date.getSeconds(), "0", 2));
        return formatted;
    }

    // public function getMonthName():String {
    //     return Type.enumConstructor(Month.values()[this.getMonth()]);
    // }

    // public function getDayName():String {
    //     return Type.enumConstructor(Day.values()[this.getDay()]);
    // }

    public function isLeapYear():Bool {
        var year = this.getFullYear();
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }
}