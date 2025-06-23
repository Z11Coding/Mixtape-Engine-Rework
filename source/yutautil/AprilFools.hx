package yutautil;

import yutautil.ExtendedDate;

// Simply manage if it's allowed.
class AprilFools {
    private var _allowAF:Bool = false;

    public static var allowAF(get, never):Bool;
    public static var debug:Bool = false;

    private static function get_allowAF():Bool {
        return ClientPrefs.data.allowEvents && (ExtendedDate.global().isAprilFools() || debug);
    }

    public static function randomModchartEffect(){
        switch(FlxG.random.int(0, 54, [23, 24])) {
            case 0:
                PlayState.instance.modManager.setValue('boost', 1);
            case 1:
                PlayState.instance.modManager.setValue('wave', 1);
            case 2:
                PlayState.instance.modManager.setValue('brake', 1);
            case 3:
                PlayState.instance.modManager.setValue('stealth', 1);
            case 4:
                PlayState.instance.modManager.setValue('sudden', 1);
            case 5:
                PlayState.instance.modManager.setValue('blink', 1);
            case 6:
                PlayState.instance.modManager.setValue('vanish', 1);
            case 7:
                PlayState.instance.modManager.setValue('beat', 1);
            case 8:
                PlayState.instance.modManager.setValue('confusion', 1);
            case 9:
                PlayState.instance.modManager.setValue('roll', 1);
            case 10:
                PlayState.instance.modManager.setValue('twirl', 1);
            case 11:
                PlayState.instance.modManager.setValue('dizzy', 1);
            case 12:
                PlayState.instance.modManager.setValue('drunk', 1);
            case 13:
                PlayState.instance.modManager.setValue('tipsy', 1);
            case 14:
                PlayState.instance.modManager.setValue('bumpy', 1);
            case 15:
                PlayState.instance.modManager.setValue('opponentSwap', 1);
            case 16:
                PlayState.instance.modManager.setValue('tornado', 1);
            case 17:
                PlayState.instance.modManager.setValue('zigzag', 1);
            case 18:
                PlayState.instance.modManager.setValue('sawtooth', 1);
            case 19:
                PlayState.instance.modManager.setValue('square', 1);
            case 20:
                PlayState.instance.modManager.setValue('bounce', 1);
            case 21:
                PlayState.instance.modManager.setValue('bounceZ', 1);
            case 22:
                PlayState.instance.modManager.setValue('tornado', 1);
            case 25:
                PlayState.instance.modManager.setValue('itgTornado', 1);
            case 26:
                PlayState.instance.modManager.setValue('itgTornadoTan', 1);
            case 27:
                PlayState.instance.modManager.setValue('digital', 1);
            case 28:
                PlayState.instance.modManager.setValue('digitalZ', 1);
            case 29:
                PlayState.instance.modManager.setValue('receptorScroll', 1);
            case 30:
                PlayState.instance.modManager.setValue('reverse', 1);
            case 31:
                PlayState.instance.modManager.setValue('split', 1);
            case 32:
                PlayState.instance.modManager.setValue('alternate', 1);
            case 33:
                PlayState.instance.modManager.setValue('cross', 1);
            case 34:
                PlayState.instance.modManager.setValue('centered', 1);
            case 35:
                PlayState.instance.modManager.setValue('schmovinDrunk', 1);
            case 36:
                PlayState.instance.modManager.setValue('schmovinDrunkY', 1);
            case 37:
                PlayState.instance.modManager.setValue('schmovinDrunkZ', 1);
            case 38:
                PlayState.instance.modManager.setValue('schmovinTipsyX', 1);
            case 39:
                PlayState.instance.modManager.setValue('schmovinTipsyZ', 1);
            case 40:
                PlayState.instance.modManager.setValue('schmovinBumpyX', 1);
            case 41:
                PlayState.instance.modManager.setValue('schmovinBumpyY', 1);
            case 42:
                PlayState.instance.modManager.setValue('schmovinDrunkTan', 1);
            case 43:
                PlayState.instance.modManager.setValue('schmovinDrunkTanY', 1);
            case 44:
                PlayState.instance.modManager.setValue('schmovinDrunkTanZ', 1);
            case 45:
                PlayState.instance.modManager.setValue('schmovinTipsyTanX', 1);
            case 46:
                PlayState.instance.modManager.setValue('schmovinTipsyTan', 1);
            case 47:
                PlayState.instance.modManager.setValue('schmovinTipsyTanZ', 1);
            case 48:
                PlayState.instance.modManager.setValue('schmovinBumpyTanX', 1);
            case 49:
                PlayState.instance.modManager.setValue('schmovinBumpyTanY', 1);
            case 50:
                PlayState.instance.modManager.setValue('schmovinBumpyTan', 1);
            case 51:
                PlayState.instance.modManager.setValue('schmovinBumpyTan', 1);
            case 52:
                PlayState.instance.modManager.setValue('reverse', 0.5, 1);
                PlayState.instance.modManager.setValue('flip', 0.5, 1);
                PlayState.instance.modManager.setValue('schmovinSpiralX', 2, 1);
                PlayState.instance.modManager.setValue('schmovinSpiralY', 2, 1);
                PlayState.instance.modManager.setValue('transformX', -24, 1);
                PlayState.instance.modManager.setValue('transformY', 15, 1);
            case 53:
                PlayState.instance.modManager.setValue('flip', 1);
            case 54:
                PlayState.instance.modManager.setValue('invert', 1);
        }
    }
}