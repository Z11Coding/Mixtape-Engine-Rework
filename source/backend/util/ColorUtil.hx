package backend.util;

/**
 * ...
 * @author Jack Bass
 */
class ColorUtil
{
    private static var hexCodes = "0123456789ABCDEF";

    public static function rgbToHex(r:Int, g:Int, b:Int):Int
    {
        var hexString = "0x";
        //Red
        hexString += hexCodes.charAt(Math.floor(r/16));
        hexString += hexCodes.charAt(r%16);
        //Green
        hexString += hexCodes.charAt(Math.floor(g/16));
        hexString += hexCodes.charAt(g%16);
        //Blue
        hexString += hexCodes.charAt(Math.floor(b/16));
        hexString += hexCodes.charAt(b%16);
        
        return Std.parseInt(hexString);
    }
    
    public static function rgbaToHex(r:Int, g:Int, b:Int, a:Int):Int
    {
        var hexString = "0x";
        //Red
        hexString += hexCodes.charAt(Math.floor(r/16));
        hexString += hexCodes.charAt(r%16);
        //Green
        hexString += hexCodes.charAt(Math.floor(g/16));
        hexString += hexCodes.charAt(g%16);
        //Blue
        hexString += hexCodes.charAt(Math.floor(b/16));
        hexString += hexCodes.charAt(b%16);
        //Alpha
        hexString += hexCodes.charAt(Math.floor(a/16));
        hexString += hexCodes.charAt(a%16);
        
        
        return Std.parseInt(hexString);
    }
}