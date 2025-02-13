package utils.yutautil;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxDestroyUtil;
import Reflect;
class MemoryHelper implements IFlxDestroyable {

    public var protectedFields:Map<String, Bool> = new Map();
    public var protectStatics:Bool = false;
    
    public function new() {}

    // Clear data from a specific state
    public inline function clearClassObject(state:Class<Dynamic>):Void {
        var methods = [];
        for (method in Type.getInstanceFields(state)) {
            if (Reflect.isFunction(Reflect.field(state, method))) {
                methods.push(method);
                addProtectedField(state, method);
            }
        }
        trace('Starting clearClassObject for state: ' + Type.getClassName(state));
        trace('Protected fields: ' + protectedFields);
        for (field in Type.getInstanceFields(state).filter(function(f:String):Bool {
            // trace('Checking field: ' + f);
            if (protectedFields.exists(f)) {
                return false;
            }
            return true;
        })) {
            if (protectedFields.exists(field)) { 
                trace('Skipping protected field: ' + field);
                continue;
            }
            var value = Reflect.getProperty(state, field);
            if (protectStatics && Reflect.hasField(state, field) && Reflect.field(state, field) == value) {
                trace('Skipping static field: ' + field);
                continue;
            }
            if (Std.is(value, Class)) {
                if (Reflect.hasField(value, "destroy")) {
                    trace('Field ' + field + ' has destroy method, destroying...');
                    FlxDestroyUtil.destroy(value);
                }
            }
            Reflect.setField(state, field, null);
        }
        for (method in methods) {
            removeProtectedField(method);
        }
        trace('Finished clearClassObject for state: ' + Type.getClassName(state));
    }

    public inline function addProtectedField(state:Class<Dynamic>, fieldName:String):Void {
        if (Reflect.hasField(state, fieldName)) {
            protectedFields.set(fieldName, true);
            trace('Added protected field ' + fieldName + ' to ' + Type.getClassName(state));
        } else {
            trace('Field ' + fieldName + ' does not exist in ' + Type.getClassName(state));
        }
    }

    public function removeProtectedField(fieldName:String):Void {
        protectedFields.remove(fieldName);
        trace('Removed protected field ' + fieldName);
    }

    public function setProtectStatics(protect:Bool):Void {
        protectStatics = protect;
    }


    // Clear data from a specific object
    public inline function clearObject(object:Dynamic, ?nullify:Bool = true):Void {
        for (field in Reflect.fields(object)) {
            if (protectedFields.exists(field)) {
                trace('Skipping protected field: ' + field);
                continue;
            }
            try {
                var value = Reflect.field(object, field);
                if (Std.is(value, Class) && Reflect.hasField(value, "destroy")) {
                    FlxDestroyUtil.destroy(value);
                }
                Reflect.setField(object, field, null);
                // trace("Field " + field + " is " + Reflect.field(object, field));
                if (nullify) {
                    Reflect.setProperty(FlxG.state, object, null);
                }
            } catch (e:Dynamic) {
                // trace('Error processing field ' + field + ': ' + e);
            }
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
    public function destroy():Void {
        clearObject(this);
        // super.destroy();
    }
}