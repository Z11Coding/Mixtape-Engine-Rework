package psychlua;

import backend.modchart.SubModifier;
import backend.modchart.events.*;
import objects.playfields.PlayField;

class PlayFieldFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "newPlayField", function()
		{
			MegaManager.playfield.newPlayfield();
		});

		Lua_helper.add_callback(lua, "initPlayfield", function(field:PlayField)
		{
			MegaManager.playfield.initPlayfield(field);
		});

		//// mod manager
		Lua_helper.add_callback(lua, "setPercent", function(modName:String, val:Float, player:Int = -1)
			MegaManager.playfield.modManager.setPercent(modName, val, player)
		);

		Lua_helper.add_callback(lua, "addBlankMod", function(modName:String, defaultVal:Float = 0, player:Int = -1) {
			MegaManager.playfield.modManager.registerBlankMod(modName, defaultVal, player);
		});

		Lua_helper.add_callback(lua, "setValue", function(modName:String, val:Float, player:Int = -1)
			MegaManager.playfield.modManager.setValue(modName, val, player)
		);

		Lua_helper.add_callback(lua, "getPercent", function(modName:String, player:Int)
			return MegaManager.playfield.modManager.getPercent(modName, player)
		);

		Lua_helper.add_callback(lua, "getValue", function(modName:String, player:Int)
			return MegaManager.playfield.modManager.getValue(modName, player)
		);

		Lua_helper.add_callback(lua, "setCurrentValue", function(modName:String, val:Float, player:Int){
			return MegaManager.playfield.modManager.setCurrentValue(modName, val, player);
		});

		Lua_helper.add_callback(lua, "getTargetValue", function(modName:String, player:Int){
			return MegaManager.playfield.modManager.getTargetValue(modName, player);
		});

		Lua_helper.add_callback(lua, "queueSet", function(step:Float, modName:String, target:Float, player:Int = -1)
			MegaManager.playfield.modManager.queueSet(step, modName, target, player)
		);

		Lua_helper.add_callback(lua, "queueSetP", function(step:Float, modName:String, perc:Float, player:Int = -1)
			MegaManager.playfield.modManager.queueSetP(step, modName, perc, player)
		);

		Lua_helper.add_callback(lua, "queueEase",
			function(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
				MegaManager.playfield.modManager.queueEase(step, endStep, modName, percent, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseP",
			function(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
				MegaManager.playfield.modManager.queueEaseP(step, endStep, modName, percent, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseL",
			function(step:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
				MegaManager.playfield.modManager.queueEaseL(step, length, modName, value, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseLB",
			function(beat:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
				MegaManager.playfield.modManager.queueEaseLB(beat, length, modName, value, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseB",
			function(beat:Float, endBeat:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
				MegaManager.playfield.modManager.queueEaseB(beat, endBeat, modName, value, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueSetB",
			function(beat:Float, modName:String, value:Float, player = -1)
				MegaManager.playfield.modManager.queueSetB(beat, modName, value, player)
		);

		Lua_helper.add_callback(lua, "queueFunc",
			function(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void)
				MegaManager.playfield.modManager.queueFunc(step, endStep, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncL",
			function(step:Float, length:Float, callback:(CallbackEvent, Float) -> Void)
				MegaManager.playfield.modManager.queueFuncL(step, length, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncB",
			function(beat:Float, endBeat:Float, callback:(CallbackEvent, Float) -> Void)
				MegaManager.playfield.modManager.queueFuncB(beat, endBeat, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncLB",
			function(beat:Float, length:Float, callback:(CallbackEvent, Float) -> Void)
				MegaManager.playfield.modManager.queueFuncB(beat, length, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncOnce",
			function(step:Float, callback:(CallbackEvent, Float) -> Void)
				MegaManager.playfield.modManager.queueFuncOnce(step, callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFunc",
			function(step:Float, endStep:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				MegaManager.playfield.modManager.queueEaseFunc(step, endStep, LuaUtils.getTweenEaseByString(style), callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFuncL",
			function(step:Float, length:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				MegaManager.playfield.modManager.queueEaseFuncL(step, length, LuaUtils.getTweenEaseByString(style), callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFuncB",
			function(beat:Float, endBeat:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				MegaManager.playfield.modManager.queueEaseFuncB(beat, endBeat, LuaUtils.getTweenEaseByString(style), callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFuncLB",
			function(beat:Float, length:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				MegaManager.playfield.modManager.queueEaseFuncLB(beat, length, LuaUtils.getTweenEaseByString(style), callback)
		);

	}
}
