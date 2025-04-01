package yutautil;

import yutautil.ExtendedDate;

// Simply manage if it's allowed.

// TODO: Adjust this class to work with every holiday

class AprilFools {
    private var _allowAF:Bool = false;

    public static var allowAF(get, never):Bool;

    private static function get_allowAF():Bool {
        return ClientPrefs.data.aprilFools && ExtendedDate.global().isAprilFools();
    }
}