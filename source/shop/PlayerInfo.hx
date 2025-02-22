package shop;

class PlayerInfo {
    public static var curMoney:Int = -1;
    public static var curItems:Map<String, Dynamic> = new Map<String, Dynamic>();



    public static function saveInfo()
    {
        trace(curMoney);
        if (curItems != null && curMoney >= 0)
            curItems.set('money', curMoney);
        else
        {
            curItems.set('money', 0);
            curMoney = 0;
        }
        FlxG.save.data.curItems = curItems;
        FlxG.save.flush();
    }

    public static function loadInfo()
    {
        if (FlxG.save.data.curItems != null) 
            curItems = FlxG.save.data.curItems;
        else
        {
            curItems.set('money', 0);
            curItems.set('stuffyouown', []);
        }
    }

}