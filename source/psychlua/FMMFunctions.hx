package psychlua;

import backend.funkinmodchart.Manager;
import backend.funkinmodchart.backend.standalone.Adapter;
import flixel.tweens.FlxEase;
import psychlua.FunkinLua;

// For PsychPlus/Funkin Modchart support for lua
class FMMFunctions
{
    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;

        // Add modifier
        Lua_helper.add_callback(lua, "addModifier", function(name:String, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null)
                MegaManager.playfield?.fmManager?.addModifier(name, field);
            else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // Set modifier percentage
        Lua_helper.add_callback(lua, "setPercentFMM", function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null)
                MegaManager.playfield?.fmManager?.setPercent(name, value, player, field);
            else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // Get modifier percentage
        Lua_helper.add_callback(lua, "getPercentFMM", function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            if (MegaManager.playfield?.fmManager != null)
                return MegaManager.playfield?.fmManager?.getPercent(name, player, field);
            return 0.0;
        });

        // Set value to a specific beat
        Lua_helper.add_callback(lua, "set", function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null)
                MegaManager.playfield?.fmManager?.set(name, beat, value, player, field);
            else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // Easing a modifier
        Lua_helper.add_callback(lua, "ease", function(name:String, beat:Float, length:Float, value:Float, easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null) {
                var easeFunc = getEaseFunction(easeName);
                MegaManager.playfield?.fmManager?.ease(name, beat, length, value, easeFunc, player, field);
            } else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // Add value with easing
        Lua_helper.add_callback(lua, "add", function(name:String, beat:Float, length:Float, value:Float, easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null) {
                var easeFunc = getEaseFunction(easeName);
                MegaManager.playfield?.fmManager?.add(name, beat, length, value, easeFunc, player, field);
            } else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // Establish and add value
        Lua_helper.add_callback(lua, "setAdd", function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null)
                MegaManager.playfield?.fmManager?.setAdd(name, beat, value, player, field);
        });

        // Add new playfield
        Lua_helper.add_callback(lua, "addPlayfield", function() {
            if (MegaManager.playfield?.fmManager != null)
                MegaManager.playfield?.fmManager?.addPlayfield();
        });

        // Create alias for modifier
        Lua_helper.add_callback(lua, "alias", function(name:String, aliasName:String, field:Int) {
            if (MegaManager.playfield?.fmManager != null)
                MegaManager.playfield?.fmManager?.alias(name, aliasName, field);
        });

        // Useful constants
        Lua_helper.add_callback(lua, "getHoldSize", function():Float {
            return Manager.HOLD_SIZE;
        });

        Lua_helper.add_callback(lua, "getHoldSizeDiv2", function():Float {
            return Manager.HOLD_SIZEDIV2;
        });

        Lua_helper.add_callback(lua, "getArrowSize", function():Float {
            return Manager.ARROW_SIZE;
        });

        Lua_helper.add_callback(lua, "getArrowSizeDiv2", function():Float {
            return Manager.ARROW_SIZEDIV2;
        });

        // Callback event: execute a function on a specific beat
        Lua_helper.add_callback(lua, "fmmcallback", function(beat:Float, funcName:String, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null) {
                MegaManager.playfield?.fmManager?.callback(beat, function(event) {
                    funk.call(funcName, []); // Don't pass event object to Lua
                }, field);
            } else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // repeater event: execute a function repeatedly over a period
        Lua_helper.add_callback(lua, "repeater", function(beat:Float, length:Float, funcName:String, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null) {
                MegaManager.playfield?.fmManager?.repeater(beat, length, function(event) {
                    funk.call(funcName, []); // No pasar el objeto event a Lua
                }, field);
            } else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        // Add scripted modifier (custom)
        Lua_helper.add_callback(lua, "addScriptedModifier", function(name:String, modifierInstance:Dynamic, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null && modifierInstance != null) {
                // The modifierInstance must be a Modifier instance created from Lua/HScript
                MegaManager.playfield?.fmManager?.addScriptedModifier(name, modifierInstance, field);
            } else
                trace('FUNKIN MODCHART MANAGER IS NULL! Are you sure you meant to use this?');
        });

        /*
        // Create node (node): link inputs and outputs with a function
        Lua_helper.add_callback(lua, "node", function(inputs:Array<String>, outputs:Array<String>, funcName:String, ?field:Int = -1) {
            if (MegaManager.playfield?.fmManager != null) {
                MegaManager.playfield?.fmManager?.node(inputs, outputs, function(curInput:Array<Float>, curOutput:Int):Int {
                    // Call Lua function with input values
                    var result:Dynamic = funk.call(funcName, [curInput]);
                    // Return result or current value if there is no result
                    if (result != null && Std.isOfType(result, Int)) {
                        return cast result;
                    }
                    return curOutput;
                }, field);
            }
        });
        */

        // Get current beat from Conductor
        Lua_helper.add_callback(lua, "getCurrentBeat", function():Float {
            return Conductor.songPosition / Conductor.crochet;
        });

        // Get current step from Conductor
        Lua_helper.add_callback(lua, "getCurrentStep", function():Float {
            return Conductor.songPosition / Conductor.stepCrochet;
        });

        // Get song time in milliseconds
        Lua_helper.add_callback(lua, "getSongPosition", function():Float {
            return Conductor.songPosition;
        });

        // Get current BPM
        Lua_helper.add_callback(lua, "getBPM", function():Float {
            return Conductor.bpm;
        });

        // Get number of players/playfields
        Lua_helper.add_callback(lua, "getPlayerCount", function():Int {
            return Adapter.instance.getPlayerCount();
        });
    }

    // Helper function to convert easing names to functions
    private static function getEaseFunction(easeName:String) {
        return LuaUtils.getTweenEaseByString(easeName);
    }
}
