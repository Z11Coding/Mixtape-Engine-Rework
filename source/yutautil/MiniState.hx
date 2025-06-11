package yutautil;

import flixel.FlxSprite;
import flixel.group.FlxTypedGroup;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;

typedef MiniStateID = String;

class MiniState extends FlxTypedGroup<FlxSprite> {
    public static var activeStates:Map<MiniStateID, MiniState> = new Map();

    public var id:MiniStateID;
    public var x:Float;
    public var y:Float;
    public var width:Float;
    public var height:Float;
    public var closed:Bool = false;

    public function new(id:MiniStateID, x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 100) {
        super();
        this.id = id;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        activeStates.set(id, this);
    }

    public function addSprite(sprite:FlxSprite):Void {
        // Offset sprite to be relative to MiniState
        sprite.x += x;
        sprite.y += y;
        add(sprite);
    }

    public function moveTo(newX:Float, newY:Float):Void {
        var dx = newX - x;
        var dy = newY - y;
        for (sprite in members) {
            if (sprite != null) {
                sprite.x += dx;
                sprite.y += dy;
            }
        }
        x = newX;
        y = newY;
    }

    public function resize(newWidth:Float, newHeight:Float):Void {
        var scaleX = newWidth / width;
        var scaleY = newHeight / height;
        for (sprite in members) {
            if (sprite != null) {
                sprite.x = x + (sprite.x - x) * scaleX;
                sprite.y = y + (sprite.y - y) * scaleY;
                sprite.scale.x *= scaleX;
                sprite.scale.y *= scaleY;
            }
        }
        width = newWidth;
        height = newHeight;
    }

    public function close():Void {
        if (closed) return;
        closed = true;
        FlxDestroyUtil.destroyMembers(this);
        activeStates.remove(id);
    }

    public static function addMiniState(id:MiniStateID, x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 100):MiniState {
        if (activeStates.exists(id)) {
            return activeStates.get(id);
        }
        var state = new MiniState(id, x, y, width, height);
        return state;
    }

    public static function closeMiniState(id:MiniStateID):Void {
        var state = activeStates.get(id);
        if (state != null) {
            state.close();
        }
    }

    public static function closeAll():Void {
        for (state in activeStates) {
            state.close();
        }
        activeStates.clear();
    }
}