package;

import ClientPrefs;
import flixel.FlxG;

using StringTools;

class UnlockSystem
{
    var unlockNames:Array<String> = 
    [
        'Testing, Testing, 1, 2, 3...'
    ];
    var unlockDesc:Array<String> = 
    [
        'FC Test'
    ];
    var unlockReward:Array<Array<String>> = 
    [
        ['pixel_bf', "You've unlocked Pixel BF in the character select menu!"],
    ];
    var isUnlocked:Array<Bool> =
    [
        false
    ];

    public static function saveUnlocks()
    {
        
    }

    public static function loadUnlocks()
    {
        
    }

    function unlockItem(item:String)
    {
        
    }
}