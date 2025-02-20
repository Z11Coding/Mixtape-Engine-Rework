package yutautil;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxDestroyUtil;
import Reflect;

class MemoryHelper {
    public function new() {}

    // Clear data from a specific state
    public inline function clearClassObject(state:Class<Dynamic>):Void {
        trace('Starting clearClassObject for state: ' + Type.getClassName(state));
        for (field in Type.getInstanceFields(state)) {
            // trace('Processing field: ' + field);
            var value = Reflect.getProperty(state, field);
            if (Std.is(value, Dynamic)) {
                // trace('Field ' + field + ' is Dynamic');
                if (Reflect.hasField(value, "destroy")) {
                    // trace('Field ' + field + ' has destroy method, destroying...');
                    FlxDestroyUtil.destroy(value);
                } else {
                    // trace('Field ' + field + ' does not have destroy method');
                }
            } else {
                // trace('Field ' + field + ' is not Dynamic');
            }
            Reflect.setField(state, field, null);
            // trace('Field ' + field + ' set to null');
            // trace("Field " + field + " is " + Reflect.field(state, field));
        }
        trace('Finished clearClassObject for state: ' + Type.getClassName(state));
    }

    // Clear data from a specific object
    public inline function clearObject(object:Dynamic):Void {
        for (field in Reflect.fields(object)) {
            var value = Reflect.field(object, field);
            if (Std.is(value, Dynamic) && Reflect.hasField(value, "destroy")) {
                FlxDestroyUtil.destroy(value);
            }
            Reflect.setField(object, field, null);
        }
    }

    // Clear data from objects within a state
    public inline function clearObjectsInState(state:FlxState):Void {
        for (object in state.members) {
            clearObject(object);
        }
    }

    // Clear data from a specific group
    public inline function clearGroup(group:FlxGroup):Void {
        for (object in group.members) {
            clearObject(object);
        }
    }
}