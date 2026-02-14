package yutautil.modules;

using StringTools;

/**
 * Represents whether a time is in AM, PM, or 24-hour (military) format.
 */
enum TimePeriod {
	AM;
	PM;
	Military;
}

/**
 * Underlying storage for a ClockTime value.
 * Time is always stored in 24-hour format internally.
 * Date fields are optional — when present, the ClockTime also represents a full date+time.
 */
typedef ClockTimeData = {
	hour:Int,
	minute:Int,
	second:Int,
	?year:Null<Int>,
	?month:Null<Int>,
	?day:Null<Int>,
};

/**
 * An abstract type representing a clock time (and optionally a date).
 *
 * Supports both 24-hour (military) and 12-hour AM/PM representations.
 * Time is always stored internally as 24-hour. Comparison operators, range
 * checks, arithmetic, and formatting are all provided.
 *
 * When date fields (year, month, day) are populated, the ClockTime can
 * represent a full date+time and convert to/from `Date` objects.
 */
abstract ClockTime(ClockTimeData) from ClockTimeData {
	// ── Construction ──────────────────────────────────────────────────

	/**
	 * Create a ClockTime in 24-hour format.
	 * @param hour   0–23
	 * @param minute 0–59
	 * @param second 0–59 (default 0)
	 * @param year   Optional year for date component
	 * @param month  Optional month (0–11) for date component
	 * @param day    Optional day (1–31) for date component
	 */
	public inline function new(hour:Int, minute:Int, second:Int = 0, ?year:Int, ?month:Int, ?day:Int) {
		this = {
			hour: clampInt(hour, 0, 23),
			minute: clampInt(minute, 0, 59),
			second: clampInt(second, 0, 59),
			year: year,
			month: month,
			day: day,
		};
	}

	/**
	 * Create a ClockTime from 24-hour (military) values.
	 */
	public static inline function fromMilitary(hour:Int, minute:Int, second:Int = 0):ClockTime {
		return new ClockTime(hour, minute, second);
	}

	/**
	 * Create a ClockTime from 12-hour AM/PM values.
	 * @param hour   1–12
	 * @param minute 0–59
	 * @param period `TimePeriod.AM` or `TimePeriod.PM` (`Military` is treated as-is)
	 * @param second 0–59 (default 0)
	 */
	public static function fromAMPM(hour:Int, minute:Int, period:TimePeriod, second:Int = 0):ClockTime {
		return new ClockTime(to24Hour(hour, period), minute, second);
	}

	/**
	 * Create a ClockTime from a `Date`, including full date information.
	 */
	public static function fromDate(date:Date):ClockTime {
		return new ClockTime(date.getHours(), date.getMinutes(), date.getSeconds(), date.getFullYear(), date.getMonth(), date.getDate());
	}

	/**
	 * Create a ClockTime representing the current moment (with date).
	 */
	public static inline function now():ClockTime {
		return fromDate(Date.now());
	}

	/**
	 * Parse a time (and optional date) string.
	 *
	 * Accepted formats:
	 * - `"HH:MM"`
	 * - `"HH:MM:SS"`
	 * - `"HH:MM AM"` / `"HH:MM PM"`
	 * - `"HH:MM:SS AM"` / `"HH:MM:SS PM"`
	 * - `"YYYY-MM-DD HH:MM:SS"`
	 * - `"YYYY-MM-DD HH:MM:SS AM/PM"`
	 */
	public static function fromString(str:String):ClockTime {
		var s = str.trim();
		var yr:Null<Int> = null;
		var mo:Null<Int> = null;
		var dy:Null<Int> = null;

		// Check for date portion "YYYY-MM-DD ..."
		if (s.length >= 10 && s.charAt(4) == "-" && s.charAt(7) == "-") {
			var datePart = s.substr(0, 10);
			var dateParts = datePart.split("-");
			if (dateParts.length == 3) {
				yr = Std.parseInt(dateParts[0]);
				mo = Std.parseInt(dateParts[1]);
				if (mo != null)
					mo -= 1; // Convert to 0-indexed
				dy = Std.parseInt(dateParts[2]);
			}
			s = s.substr(10).trim();
		}

		// Detect AM/PM suffix
		var period:Null<TimePeriod> = null;
		var upper = s.toUpperCase();
		if (upper.endsWith("AM")) {
			period = TimePeriod.AM;
			s = s.substr(0, s.length - 2).trim();
		} else if (upper.endsWith("PM")) {
			period = TimePeriod.PM;
			s = s.substr(0, s.length - 2).trim();
		}

		// Parse time "HH:MM" or "HH:MM:SS"
		var parts = s.split(":");
		var h = parts.length > 0 ? Std.parseInt(parts[0]) : 0;
		var m = parts.length > 1 ? Std.parseInt(parts[1]) : 0;
		var sec = parts.length > 2 ? Std.parseInt(parts[2]) : 0;
		if (h == null)
			h = 0;
		if (m == null)
			m = 0;
		if (sec == null)
			sec = 0;

		if (period != null)
			h = to24Hour(h, period);

		return new ClockTime(h, m, sec, yr, mo, dy);
	}

	// ── Properties ────────────────────────────────────────────────────

	/** Hour in 24-hour format (0–23). */
	public var hour(get, never):Int;

	inline function get_hour():Int
		return this.hour;

	/** Minute (0–59). */
	public var minute(get, never):Int;

	inline function get_minute():Int
		return this.minute;

	/** Second (0–59). */
	public var second(get, never):Int;

	inline function get_second():Int
		return this.second;

	/** Year, or null if no date component. */
	public var year(get, never):Null<Int>;

	inline function get_year():Null<Int>
		return this.year;

	/** Month (0-indexed, 0=Jan), or null if no date component. */
	public var month(get, never):Null<Int>;

	inline function get_month():Null<Int>
		return this.month;

	/** Day of month (1–31), or null if no date component. */
	public var day(get, never):Null<Int>;

	inline function get_day():Null<Int>
		return this.day;

	/** The `TimePeriod` (AM or PM) for this time. */
	public var period(get, never):TimePeriod;

	function get_period():TimePeriod {
		return this.hour < 12 ? TimePeriod.AM : TimePeriod.PM;
	}

	/** Hour in 12-hour format (1–12). */
	public var hour12(get, never):Int;

	function get_hour12():Int {
		var h = this.hour % 12;
		return h == 0 ? 12 : h;
	}

	/** Whether this ClockTime has date information (year/month/day). */
	public var hasDate(get, never):Bool;

	function get_hasDate():Bool {
		return this.year != null && this.month != null && this.day != null;
	}

	/** Total seconds since midnight (0–86399). Useful for time-only comparisons. */
	public var totalSeconds(get, never):Int;

	inline function get_totalSeconds():Int
		return this.hour * 3600 + this.minute * 60 + this.second;

	// ── Operators ─────────────────────────────────────────────────────

	@:op(A == B)
	public function equals(other:ClockTime):Bool {
		if (hasDate && other.hasDate)
			return year == other.year && month == other.month && day == other.day && totalSeconds == other.totalSeconds;
		return totalSeconds == other.totalSeconds;
	}

	@:op(A != B)
	public function notEquals(other:ClockTime):Bool {
		return !equals(other);
	}

	@:op(A < B)
	public function lessThan(other:ClockTime):Bool {
		if (hasDate && other.hasDate) {
			if (year != other.year)
				return year < other.year;
			if (month != other.month)
				return month < other.month;
			if (day != other.day)
				return day < other.day;
		}
		return totalSeconds < other.totalSeconds;
	}

	@:op(A <= B)
	public function lessOrEqual(other:ClockTime):Bool {
		return equals(other) || lessThan(other);
	}

	@:op(A > B)
	public function greaterThan(other:ClockTime):Bool {
		return !lessOrEqual(other);
	}

	@:op(A >= B)
	public function greaterOrEqual(other:ClockTime):Bool {
		return !lessThan(other);
	}

	// ── Range / Matching ──────────────────────────────────────────────

	/**
	 * Check if this time falls within a range (inclusive).
	 * Handles midnight wrap-around: if `start > end`, the range is
	 * treated as crossing midnight (e.g. 22:00 → 06:00).
	 *
	 * Only compares the time-of-day portion (ignores date fields).
	 */
	public function isInRange(start:ClockTime, end:ClockTime):Bool {
		var s = start.totalSeconds;
		var e = end.totalSeconds;
		var t = totalSeconds;
		if (s <= e)
			return t >= s && t <= e;
		// Wraps around midnight
		return t >= s || t <= e;
	}

	/**
	 * Check if this time matches another, ignoring seconds.
	 * Useful for "is it 3:30?" style checks.
	 */
	public function matchesHourMinute(other:ClockTime):Bool {
		return this.hour == other.hour && this.minute == other.minute;
	}

	/**
	 * Check if this time matches another exactly (hour, minute, second).
	 * Date fields are ignored — use `equals` for full date+time comparison.
	 */
	public function matchesExact(other:ClockTime):Bool {
		return totalSeconds == other.totalSeconds;
	}

	/**
	 * Check if this time is within `toleranceSeconds` of another time.
	 */
	public function isNear(other:ClockTime, toleranceSeconds:Int):Bool {
		var diff = totalSeconds - other.totalSeconds;
		if (diff < 0)
			diff = -diff;
		// Also check wrap-around at midnight
		var wrapDiff = 86400 - diff;
		return diff <= toleranceSeconds || wrapDiff <= toleranceSeconds;
	}

	// ── Arithmetic ────────────────────────────────────────────────────

	/**
	 * Return a new ClockTime offset by the given hours, minutes, and seconds.
	 * Wraps around midnight. Preserves date fields if present.
	 */
	public function add(hours:Int = 0, minutes:Int = 0, seconds:Int = 0):ClockTime {
		var total = totalSeconds + hours * 3600 + minutes * 60 + seconds;
		total = ((total % 86400) + 86400) % 86400; // Normalize to 0–86399
		var h = Std.int(total / 3600);
		var remainder = total - h * 3600;
		var m = Std.int(remainder / 60);
		var s = remainder - m * 60;
		return new ClockTime(h, m, s, this.year, this.month, this.day);
	}

	/**
	 * Return the difference in seconds between this time and another (time-of-day only).
	 * Result may be negative.
	 */
	public function diffSeconds(other:ClockTime):Int {
		return totalSeconds - other.totalSeconds;
	}

	// ── Builders ──────────────────────────────────────────────────────

	/**
	 * Return a copy of this ClockTime with date fields attached.
	 * @param year  Full year (e.g. 2026)
	 * @param month 0-indexed month (0=January)
	 * @param day   Day of month (1–31)
	 */
	public function withDate(year:Int, month:Int, day:Int):ClockTime {
		return new ClockTime(this.hour, this.minute, this.second, year, month, day);
	}

	/**
	 * Return a copy with only the time portion (date fields stripped).
	 */
	public function timeOnly():ClockTime {
		return new ClockTime(this.hour, this.minute, this.second);
	}

	// ── Conversion ────────────────────────────────────────────────────

	/**
	 * Convert to a `Date` object. Requires date fields to be present.
	 * Returns `null` if date fields are missing.
	 */
	public function toDate():Null<Date> {
		if (!hasDate)
			return null;
		return new Date(this.year, this.month, this.day, this.hour, this.minute, this.second);
	}

	/**
	 * Convert to total milliseconds since midnight.
	 */
	public inline function toMilliseconds():Float {
		return totalSeconds * 1000.0;
	}

	// ── Formatting ────────────────────────────────────────────────────

	/**
	 * Format as 24-hour string: `"HH:MM:SS"` or `"HH:MM"`.
	 */
	public function toMilitaryString(includeSeconds:Bool = true):String {
		var base = pad2(this.hour) + ":" + pad2(this.minute);
		if (includeSeconds)
			base += ":" + pad2(this.second);
		return base;
	}

	/**
	 * Format as 12-hour string: `"HH:MM:SS AM"` or `"HH:MM AM"`.
	 */
	public function toAMPMString(includeSeconds:Bool = true):String {
		var suffix = this.hour < 12 ? " AM" : " PM";
		var base = pad2(hour12) + ":" + pad2(this.minute);
		if (includeSeconds)
			base += ":" + pad2(this.second);
		return base + suffix;
	}

	/**
	 * Format as a full date+time string: `"YYYY-MM-DD HH:MM:SS"`.
	 * Falls back to time-only if no date component is present.
	 */
	public function toDateTimeString():String {
		if (!hasDate)
			return toMilitaryString();
		return Std.string(this.year) + "-" + pad2(this.month + 1) + "-" + pad2(this.day) + " " + toMilitaryString();
	}

	/**
	 * Format using the given `TimePeriod` style.
	 * - `Military` → 24-hour format
	 * - `AM` / `PM` → 12-hour format (period is derived from the actual hour)
	 */
	public function format(style:TimePeriod, includeSeconds:Bool = true):String {
		return switch (style) {
			case TimePeriod.Military: toMilitaryString(includeSeconds);
			case TimePeriod.AM | TimePeriod.PM: toAMPMString(includeSeconds);
		};
	}

	@:to
	public function toString():String {
		return hasDate ? toDateTimeString() : toMilitaryString();
	}

	// ── Internal Helpers ──────────────────────────────────────────────

	static function to24Hour(hour12:Int, period:TimePeriod):Int {
		return switch (period) {
			case TimePeriod.AM:
				hour12 == 12 ? 0 : clampInt(hour12, 1, 12);
			case TimePeriod.PM:
				hour12 == 12 ? 12 : clampInt(hour12, 1, 12) + 12;
			case TimePeriod.Military:
				clampInt(hour12, 0, 23);
		};
	}

	static inline function clampInt(v:Int, min:Int, max:Int):Int {
		return v < min ? min : (v > max ? max : v);
	}

	static function pad2(v:Int):String {
		return StringTools.lpad(Std.string(v), "0", 2);
	}
}
