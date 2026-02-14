package yutautil;

import Date;
import haxe.ds.Either;

using StringTools;
#if !macro
import flixel.FlxBasic;
#end

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

enum StringMode {
    Names;
    Numbers;
}

typedef NewDateObject = {year:Null<Int>, month:Null<Int>, day:Null<Int>, ?hour:Int, ?minute:Int, ?second:Int};

#if !macro
typedef DateHandler = flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>;
#else
typedef DateHandler = Date;
#end

typedef BirthInfo = {
    name: String,
    birthday: Either<{year: Int, month: Int, day: Int}, {year: Int, month: Month, day: Int}>
};

#if !macro
class ExtendedDate extends FlxBasic {
#else
class ExtendedDate {
#end
    public static var date:Date;

    public var dateAccess:Dynamic;

    public static var instance:ExtendedDate;

    public var StringMode:StringMode = null;

    public static var birthInfos:Array<BirthInfo> = [
        {name: "Z11", birthday: Either.Left({year: 2005, month: 11, day: 22})},
        {name: "Yuta", birthday: Either.Left({year: 1999, month: 11, day: 10})},
        {name: "Magi", birthday: Either.Right({year: 2004, month: July, day: 29})},
        {name: "Dylan", birthday: Either.Right({year: 2005, month: October, day: 26})},
        {name: "AnotherGuy", birthday: Either.Right({year: 2000, month: April, day: 6})},
    ];

    public function new(year:Int, month:Int, day:Int, hour:Int = 0, minute:Int = 0, second:Int = 0) {
        if (year == 0 && month == 0 && day == 0) {
            this.dateAccess = Date.now();
        } else {
            this.dateAccess = new Date(year, month, day, hour, minute, second);
        }

        #if !macro
        if (ExtendedDate.date == null) {
            ExtendedDate.date = Date.now();
            trace("Initializing date...");
        }
        this.dateAccess = ExtendedDate.date;
        super();
        #end

        trace("It is currently " + this.dateAccess);

        if (instance != null) {
            #if !macro
            instance.destroy();
            #end
            instance = null;
        }

        instance = this; // Prevent Overflow

        this.StringMode = yutautil.ExtendedDate.StringMode.Names;
        this.checkBirthdays();
    }

    #if !macro
    public static function createDate(type:Class<flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>>, now:Bool, _construct:NewDateObject):flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate> {
        return now ? (type == Date ? Date.now() : ExtendedDate.newDate()) :
            (_construct != null && _construct.year != null && _construct.month != null && _construct.day != null ?
                (type == Date ? new Date(_construct.year, _construct.month, _construct.day, _construct.hour, _construct.minute, _construct.second) : new ExtendedDate(_construct.year, _construct.month, _construct.day, _construct.hour, _construct.minute, _construct.second)) :
                (type == Date ? Date.now() : ExtendedDate.newDate()));
    }
    #else
    public static function createDate(type:Class<Date>, now:Bool, _construct:NewDateObject):Date {
        return now ? Date.now() :
            (_construct != null && _construct.year != null && _construct.month != null && _construct.day != null ?
                new Date(_construct.year, _construct.month, _construct.day, _construct.hour, _construct.minute, _construct.second) :
                Date.now());
    }
    #end

    public static inline function global():ExtendedDate {
        return (ExtendedDate.instance == null ? new ExtendedDate(0, 0, 0) : ExtendedDate.instance);
    }

    public static function newDate():ExtendedDate {
        return ExtendedDate.fromDate(Date.now());
    }

    public static function fromDate(date:Date):ExtendedDate {
        return new ExtendedDate(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
    }

    #if !macro
    public static function fromDateType(date:flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>):ExtendedDate {
        var date:Dynamic = date;
        return new ExtendedDate(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
    }
    #else
    public static function fromDateType(date:Date):ExtendedDate {
        return new ExtendedDate(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
    }
    #end

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

    public function isAprilFools():Bool {
        return this.getMonth() == 3 && this.getDate() == 1;
    }

    public function isNewYearsDay():Bool {
        return this.getMonth() == 0 && this.getDate() == 1;
    }

    public function isValentinesDay():Bool {
        return this.getMonth() == 1 && this.getDate() == 14;
    }

    public function isIndependenceDay():Bool {
        return this.getMonth() == 6 && this.getDate() == 4;
    }

    public function isLaborDay():Bool {
        return this.getMonth() == 8 && this.getDay() == 1 && this.getWeekOfMonth() == 1;
    }

    public function isEaster():Bool {
        // Easter is the first Sunday after the first full moon on or after the vernal equinox (March 21).
        // This is a simplified version and may not be accurate for all years.
        var year = this.getFullYear();
        var month = this.getMonth();
        var day = this.getDate();
        var a = year % 19;
        var b = Math.floor(year / 100);
        var c = year % 100;
        var d = Math.floor(b / 4);
        var e = b % 4;
        var f = Math.floor((b + 8) / 25);
        var g = Math.floor((b - f + 1) / 16);
        var h = (19 * a + b - d - g + 15) % 30;
        var i = Math.floor(c / 16);
        var k = c % 16;
        var l = (32 + 2 * e + 2 * i - h - k) % 7;
        var m = Math.floor((a + 11 * h + 22 * l) / 451);
        var monthEaster = Math.floor((h + l - m + 90) / 25);
        var dayEaster = (h + l - m + 28) % 31 + 1;

        return month == monthEaster && day == dayEaster;
    }

    public function isHatsuneMikuDay():Bool {
        return this.getMonth() == 3 && this.getDate() == 9;
    }

    public function isHatsuneMikuBirthday():Bool {
        return this.getMonth() == 8 && this.getDate() == 31;
    }

    public function isNewYearsEve():Bool {
        return this.getMonth() == 11 && this.getDate() == 31;
    }

    public function isEasterSeason():Bool {
        // Easter season is considered to be the 40 days leading up to Easter Sunday.
        var year = this.getFullYear();
        var month = this.getMonth();
        var day = this.getDate();
        var easterDate = new ExtendedDate(year, 3, 1); // March 1st
        var easterSunday = easterDate.isEaster();
        return easterSunday && (month == 2 || (month == 3 && day <= 31));
    }

    public function isHalloween():Bool {
        return this.getMonth() == 9 && this.getDate() == 31;
    }

    public function isHalloweenSeason():Bool {
        return this.getMonth() == 9 && this.getDate() >= 28 && this.getDate() <= 31;
    }

    public function isChristmas():Bool {
        return this.getMonth() == 11 && this.getDate() == 25;
    }

    public function isChristmasSeason():Bool {
        return (this.getMonth() == 11 && this.getDate() >= 24) || (this.getMonth() == 11 && this.getDate() <= 31);
    }

    public function isThanksgiving():Bool {
        // Thanksgiving is the fourth Thursday of November
        return this.getMonth() == 10 && this.getDay() == 4 && this.getWeekOfMonth() == 4;
    }

    public function isPrideMonth():Bool {
        // Pride Month is June
        return this.getMonth() == 5;
    }

    public function isBirthday(birthInfo:BirthInfo):Bool {
        var todayMonth = this.getMonth();
        var todayDay = this.getDate();
        return switch (birthInfo.birthday) {
            case Either.Left(date):
                date.month == todayMonth && date.day == todayDay;
            case Either.Right(date):
                (Type.enumIndex(date.month)+2) == todayMonth && date.day == todayDay;
        }
    }

    public function getAge(birthInfo:BirthInfo):Int {
        var currentYear = this.getFullYear();
        var todayMonth = this.getMonth();
        var todayDay = this.getDate();
        return switch (birthInfo.birthday) {
            case Either.Left(date):
                var age = currentYear - date.year;
                if (todayMonth < date.month || (todayMonth == date.month && todayDay < date.day)) {
                    age -= 1;
                }
                age;
            case Either.Right(date):
                var age = currentYear - date.year;
                if (todayMonth < Type.enumIndex(date.month) || (todayMonth == Type.enumIndex(date.month) && todayDay < date.day)) {
                    age -= 1;
                }
                age;
        }
    }

    public function checkBirthdays():Void {
        for (birthInfo in birthInfos) {
            if (this.isBirthday(birthInfo)) {
                trace(birthInfo.name + "'s birthday is today!" + " They are " + this.getAge(birthInfo) + " years old.");
            }
        }
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

    #if !macro
    public override function update(elapsed:Float):Void {
        ExtendedDate.date = Date.now();
        dateAccess = ExtendedDate.date;
        super.update(elapsed);
    }
    #end

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

    public static function getCurrentMonth():Month {
        return getMonthByNumber(Date.now().getMonth() + 1);
    }

    public static function getCurrentDay():Day {
        return getDayByNumber(Date.now().getDay() + 1);
    }

    public static function getCurrentMonthAndDay():{month:Month, day:Day} {
        return {month: getCurrentMonth(), day: getCurrentDay()};
    }

    public static function getCurrentMonthDayYear():{month:Month, day:Day, year:Int} {
        return {month: getCurrentMonth(), day: getCurrentDay(), year: Date.now().getFullYear()};
    }

    public static function getFullDateObject():{year:Int, month:Month, day:Day, date:Int, time:String} {
        var now = Date.now();
        return {
            year: now.getFullYear(),
            month: getMonthByNumber(now.getMonth() + 1),
            day: getDayByNumber(now.getDay() + 1),
            date: now.getDate(),
            time: ExtendedDate.formatDateObject(now, "%H:%M:%S")
        };
    }

    #if !macro
    public static function getCustomDateObject(date:flixel.util.typeLimit.OneOfTwo<Date, ExtendedDate>, format:String):{year:Int, month:Month, day:Day, date:Int, time:String} {
        var date:Dynamic = date;
        return {
            year: date.getFullYear(),
            month: getMonthByNumber(date.getMonth() + 1),
            day: getDayByNumber(date.getDay() + 1),
            date: date.getDate(),
            time: ExtendedDate.formatDateObject(date, format)
        };
    }
    #else
    public static function getCustomDateObject(date:Date, format:String):{year:Int, month:Month, day:Day, date:Int, time:String} {
        return {
            year: date.getFullYear(),
            month: getMonthByNumber(date.getMonth() + 1),
            day: getDayByNumber(date.getDay() + 1),
            date: date.getDate(),
            time: ExtendedDate.formatDateObject(date, format)
        };
    }
    #end

    public function getDateObject():{year:Int, month:Month, day:Day, date:Int, time:String} {
        return {
            year: this.getFullYear(),
            month: getMonthByNumber(this.getMonth() + 1),
            day: getDayByNumber(this.getDay() + 1),
            date: this.getDate(),
            time: this.time()
        };
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

    #if !macro
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
    #else
    public static function formatDateObject(date:Date, format:String):String {
        var formatted:String = format;
        formatted = formatted.replace("%Y", "" + date.getFullYear());
        formatted = formatted.replace("%m", StringTools.lpad("" + (date.getMonth() + 1), "0", 2));
        formatted = formatted.replace("%d", StringTools.lpad("" + date.getDate(), "0", 2));
        formatted = formatted.replace("%H", StringTools.lpad("" + date.getHours(), "0", 2));
        formatted = formatted.replace("%M", StringTools.lpad("" + date.getMinutes(), "0", 2));
        formatted = formatted.replace("%S", StringTools.lpad("" + date.getSeconds(), "0", 2));
        return formatted;
    }
    #end

    public function isLeapYear():Bool {
        var year = this.getFullYear();
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    }

    // ── ClockTime Integration ─────────────────────────────────────────

    /**
     * Create a `ClockTime` from this ExtendedDate's current time (with date).
     */
    public function toClockTime():yutautil.modules.ClockTime {
        return new yutautil.modules.ClockTime(this.getHours(), this.getMinutes(), this.getSeconds(), this.getFullYear(), this.getMonth(), this.getDate());
    }

    /**
     * Create a `ClockTime` from this ExtendedDate's time-of-day only (no date component).
     */
    public function toClockTimeOnly():yutautil.modules.ClockTime {
        return new yutautil.modules.ClockTime(this.getHours(), this.getMinutes(), this.getSeconds());
    }

    /**
     * Create a `ClockTime` representing the current system time (with date).
     */
    public static function clockTimeNow():yutautil.modules.ClockTime {
        return yutautil.modules.ClockTime.now();
    }

    /**
     * Create an `ExtendedDate` from a `ClockTime`.
     * If the ClockTime has no date component, the current date is used.
     */
    public static function fromClockTime(ct:yutautil.modules.ClockTime):ExtendedDate {
        if (ct.hasDate) {
            return new ExtendedDate(ct.year, ct.month, ct.day, ct.hour, ct.minute, ct.second);
        }
        var now = Date.now();
        return new ExtendedDate(now.getFullYear(), now.getMonth(), now.getDate(), ct.hour, ct.minute, ct.second);
    }

    /**
     * Check if this ExtendedDate's time-of-day matches a `ClockTime` exactly
     * (hour, minute, second). Date fields on the ClockTime are ignored.
     */
    public function isAtTime(ct:yutautil.modules.ClockTime):Bool {
        return this.getHours() == ct.hour && this.getMinutes() == ct.minute && this.getSeconds() == ct.second;
    }

    /**
     * Check if this ExtendedDate's time-of-day matches a `ClockTime`'s
     * hour and minute (seconds are ignored).
     */
    public function isAtTimeApprox(ct:yutautil.modules.ClockTime):Bool {
        return this.getHours() == ct.hour && this.getMinutes() == ct.minute;
    }

    /**
     * Check if this ExtendedDate's time-of-day falls within a range
     * defined by two `ClockTime` values (inclusive).
     *
     * Handles midnight wrap-around: if `start` is later than `end`,
     * the range is treated as crossing midnight (e.g. 22:00 → 06:00).
     */
    public function isInTimeRange(start:yutautil.modules.ClockTime, end:yutautil.modules.ClockTime):Bool {
        return this.toClockTimeOnly().isInRange(start, end);
    }

    /**
     * Check if this ExtendedDate is within `toleranceSeconds` of a `ClockTime`.
     */
    public function isNearTime(ct:yutautil.modules.ClockTime, toleranceSeconds:Int):Bool {
        return this.toClockTimeOnly().isNear(ct, toleranceSeconds);
    }

    #if (LUA_ALLOWED && !macro)
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "getFullYear", function():Int
		{
			return instance.getFullYear();
		});

		Lua_helper.add_callback(lua, "getMonth", function():Int
		{
			return instance.getMonth();
		});

        Lua_helper.add_callback(lua, "getDate", function():Int
		{
			return instance.getDate();
		});

        Lua_helper.add_callback(lua, "getDay", function():Int
		{
			return instance.getDay();
		});

        Lua_helper.add_callback(lua, "getHours", function():Int
		{
			return instance.getHours();
		});

        Lua_helper.add_callback(lua, "getMinutes", function():Int
		{
			return instance.getMinutes();
		});

        Lua_helper.add_callback(lua, "getSeconds", function():Int
		{
			return instance.getSeconds();
		});

        Lua_helper.add_callback(lua, "getTime", function():Float
		{
			return instance.getTime();
		});

        Lua_helper.add_callback(lua, "isWeekend", function():Bool
		{
			return instance.isWeekend();
		});

        Lua_helper.add_callback(lua, "isWeekday", function():Bool
		{
			return instance.isWeekday();
		});

        Lua_helper.add_callback(lua, "isAprilFools", function():Bool
		{
			return instance.isAprilFools();
		});

        Lua_helper.add_callback(lua, "isNewYearsDay", function():Bool
		{
			return instance.isNewYearsDay();
		});

        Lua_helper.add_callback(lua, "isValentinesDay", function():Bool
		{
			return instance.isValentinesDay();
		});

        Lua_helper.add_callback(lua, "isIndependenceDay", function():Bool
		{
			return instance.isIndependenceDay();
		});

        Lua_helper.add_callback(lua, "isLaborDay", function():Bool
		{
			return instance.isLaborDay();
		});

        Lua_helper.add_callback(lua, "isEaster", function():Bool
		{
			return instance.isEaster();
		});

        Lua_helper.add_callback(lua, "isHatsuneMikuDay", function():Bool
		{
			return instance.isHatsuneMikuDay();
		});

        Lua_helper.add_callback(lua, "isHatsuneMikuBirthday", function():Bool
		{
			return instance.isHatsuneMikuBirthday();
		});

        Lua_helper.add_callback(lua, "isNewYearsEve", function():Bool
		{
			return instance.isNewYearsEve();
		});

        Lua_helper.add_callback(lua, "isEasterSeason", function():Bool
		{
			return instance.isEasterSeason();
		});

        Lua_helper.add_callback(lua, "isHalloween", function():Bool
		{
			return instance.isHalloween();
		});

        Lua_helper.add_callback(lua, "isHalloweenSeason", function():Bool
		{
			return instance.isHalloweenSeason();
		});

        Lua_helper.add_callback(lua, "isChristmas", function():Bool
		{
			return instance.isChristmas();
		});

        Lua_helper.add_callback(lua, "isChristmasSeason", function():Bool
		{
			return instance.isChristmasSeason();
		});

        Lua_helper.add_callback(lua, "isThanksgiving", function():Bool
		{
			return instance.isThanksgiving();
		});

        Lua_helper.add_callback(lua, "isPrideMonth", function():Bool
		{
			return instance.isPrideMonth();
		});

        Lua_helper.add_callback(lua, "dateAsString", function():String
		{
			return instance.asString();
		});

        Lua_helper.add_callback(lua, "getDaysInMonth", function():Int
		{
			return instance.getDaysInMonth();
		});

        Lua_helper.add_callback(lua, "getDaysInYear", function():Int
		{
			return instance.getDaysInYear();
		});

        Lua_helper.add_callback(lua, "getDaysLeftInMonth", function():Int
		{
			return instance.getDaysLeftInMonth();
		});

        Lua_helper.add_callback(lua, "getDaysLeftInYear", function():Int
		{
			return instance.getDaysLeftInYear();
		});

        Lua_helper.add_callback(lua, "getDayOfYear", function():Int
		{
			return instance.getDayOfYear();
		});

        Lua_helper.add_callback(lua, "getWeekOfYear", function():Int
		{
			return instance.getWeekOfYear();
		});

        Lua_helper.add_callback(lua, "getWeekOfMonth", function():Int
		{
			return instance.getWeekOfMonth();
		});

        Lua_helper.add_callback(lua, "getWeeksLeftInYear", function():Int
		{
			return instance.getWeeksLeftInYear();
		});

        Lua_helper.add_callback(lua, "getWeeksLeftInMonth", function():Int
		{
			return instance.getWeeksLeftInMonth();
		});

        Lua_helper.add_callback(lua, "getWeeksLeftInMonth", function():Int
		{
			return instance.getWeeksLeftInMonth();
		});

        Lua_helper.add_callback(lua, "time", function():String
		{
			return instance.time();
		});

        Lua_helper.add_callback(lua, "exactTimeNow", function():String
		{
			return exactTimeNow();
		});

        Lua_helper.add_callback(lua, "formatDate", function(format:String):String
		{
			return instance.formatDate(format);
		});

        Lua_helper.add_callback(lua, "isLeapYear", function():Bool
		{
			return instance.isLeapYear();
		});
	}
	#end
}
