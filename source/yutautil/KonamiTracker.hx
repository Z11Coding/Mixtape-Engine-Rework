package yutautil;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.FlxBasic;

typedef CheatCallback = Cheat->Void;

typedef Cheat = {
    var code:Array<FlxKey>;
    var callback:CheatCallback;
}

class KonamiTracker extends FlxBasic {
    public static final KONAMI_CODE_1:Array<FlxKey> = [
        UP, UP, DOWN, DOWN, LEFT, RIGHT, LEFT, RIGHT, B, A
    ];
    public static final KONAMI_CODE_2:Array<FlxKey> = [
        UP, UP, DOWN, DOWN, LEFT, RIGHT, LEFT, RIGHT, B, A, ENTER
    ];

    var cheats:Array<Cheat>;
    var inputBuffer:Array<FlxKey> = [];
    var maxLength:Int = 0;

    public function new(?cheatTable:KeyIndexedArray<Array<FlxKey>, CheatCallback>, ?KonamiCallback:CheatCallback) {
        super();
        cheats = [];
        if (KonamiCallback != null) {
            addCheat(KONAMI_CODE_1, KonamiCallback);
            addCheat(KONAMI_CODE_2, KonamiCallback);
        }
        if (cheatTable != null) {
            for (entry in cheatTable) {
                addCheat(entry.key, entry.value);
            }
        }
    }

    public function addCheat(code:Array<FlxKey>, callback:CheatCallback):Void {
        cheats.push({ code: code, callback: callback });
        if (code.length > maxLength) maxLength = code.length;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        var pressed:Null<FlxKey> = getPressedKey();
        if (pressed != null) {
            inputBuffer.push(pressed);
            if (inputBuffer.length > maxLength)
                inputBuffer.shift();
            checkCheats();
        }
    }

    function checkCheats():Void {
        var matched = false;
        for (cheat in cheats) {
            if (matches(cheat.code)) {
                cheat.callback(cheat);
                inputBuffer = [];
                matched = true;
                break;
            }
        }
        if (!matched && !anyPartialMatch()) {
            inputBuffer = [];
        }
    }

    function matches(code:Array<FlxKey>):Bool {
        if (inputBuffer.length < code.length) return false;
        for (i in 0...code.length) {
            if (inputBuffer[inputBuffer.length - code.length + i] != code[i])
                return false;
        }
        return true;
    }

    function anyPartialMatch():Bool {
        for (cheat in cheats) {
            if (partialMatch(cheat.code)) return true;
        }
        return false;
    }

    function partialMatch(code:Array<FlxKey>):Bool {
        var len = inputBuffer.length;
        if (len == 0 || len > code.length) return false;
        for (i in 0...len) {
            if (inputBuffer[i] != code[i]) return false;
        }
        return true;
    }

    public var allowAllKeys:Bool = true;

    function getPressedKey():Null<FlxKey> {
        var keys = allowAllKeys
            ? [for (key in FlxKey.toStringMap.keys()) key]
            : [
                FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT,
                FlxKey.A, FlxKey.B, FlxKey.C, FlxKey.X, FlxKey.Y,
                FlxKey.Z, FlxKey.ENTER, FlxKey.SPACE
            ];
        for (key in keys) {
            // Use Reflect to access the justPressed property dynamically
            var justPressed = Reflect.field(FlxG.keys, "justPressed");
            if (justPressed != null && Reflect.callMethod(FlxG.keys, justPressed, [key])) {
                return key;
            }
        }
        return null;
    }
}