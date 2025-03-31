package yutautil;

import yutautil.ExtendedDate;

// Simply manage if it's allowed.

class AprilFools {
    private var _allowAF:Bool = false;

    public var allowAF(get, never):Bool;

    private function get_allowAF():Bool {
        return ClientPrefs.data.aprilFools && ExtendedDate.global().isAprilFools();
    }
}