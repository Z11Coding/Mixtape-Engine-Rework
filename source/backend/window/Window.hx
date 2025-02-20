package backend.window;

import lime.ui.WindowAttributes;
import openfl.system.Capabilities;
import openfl.Lib;

class Window
{
    public static var x(default,set):Int;
    public static var y(default,set):Int;
    public static var width(default,set):Int;
    public static var height(default,set):Int;
    public static var title(default,set):String;
    public static var dis_width(default,null):Float;
    public static var dis_height(default,null):Float;
    /**
    * Yeah, This Returns The Player's Computer Language.
    */
    public static var sys_lang(default,null):String;
    public static var os(default,null):String;

    static var doReset:Bool = false;

    /**
    * Resets All Window Variables.
    */
    public static function reset() {
        doReset = true;
        x = Lib.application.window.x;
        y = Lib.application.window.y;
        width = Lib.application.window.width;
        height = Lib.application.window.height;
        title = Lib.application.window.title;
        dis_width = Capabilities.screenResolutionX;
        dis_height = Capabilities.screenResolutionY;
        sys_lang = Capabilities.language;
        os = Capabilities.os;
        doReset = false;
    }

    #if windows
    /**
    * Gets the windows version.
    */
    public static function getWinVersion()
    {
        var win = Capabilities.os;
        if (win.toLowerCase().contains("window")) {
            return win.toLowerCase().replace("window ", "");
        } else { // ????????????????????????????????????
            trace("how??????????????????");
            return "null";
        }
    }
    #end

    #if mac
    public static function getMacVersion()
    {
        var mac = Capabilities.os;
        if (mac.toLowerCase().contains("mac os ")) {
            return mac.toLowerCase().replace("mac os ", "");
        } else { // ????????????????????????????????????
            trace("how??????????????????");
            return "null";
        }
    }
    #end

    public static function setPos(posX:Int, posY:Int) {
        x = posX;
        y = posY;
    }

    public static function setSize(w:Int, h:Int) {
        width = w;
        height = h;
    }

    public static function alert(msg:String, ?title:String = "Error!") {
        Lib.application.window.alert(msg, title);
    }

    /**
    * Creates A New Window.
    */
    public static function create(att:WindowAttributes):lime.ui.Window {
        return Lib.application.createWindow(att);
    }

    private static function set_x(i:Int) { if (!doReset) {Lib.application.window.x = i; x = i;} return i;}
    private static function set_y(i:Int) { if (!doReset) {Lib.application.window.y = i; y = i;} return i;}
    private static function set_width(i:Int) { if (!doReset) {Lib.application.window.width = i; width = i;} return i;}
    private static function set_height(i:Int) { if (!doReset) {Lib.application.window.height = i; height = i;} return i;}
    private static function set_title(s:String) { if (!doReset) {Lib.application.window.title = s; title = s;} return s;}
}