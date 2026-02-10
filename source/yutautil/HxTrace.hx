package yutautil;

/**
 * Utility class for Haxe traces
 */

class HxTrace {
  private static var hxTrace:haxe.Constraints.Function = haxe.Log.trace;
    public static function log(v:Dynamic, ?infos:haxe.PosInfos):Void {
        hxTrace(v, infos);
    }
    public static inline function print(v:Dynamic):Void {
        hxTrace(v, null);
    }
}
