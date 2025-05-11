package psychlua;

import backend.modchart.SubModifier;
import objects.playfields.PlayField;

class PlayFieldFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "newPlayField", function()
		{
			PlayState.instance.newPlayfield();
		});

		Lua_helper.add_callback(lua, "initPlayfield", function(field:PlayField)
		{
			PlayState.instance.initPlayfield(field);
		});
		
		//// mod manager
		Lua_helper.add_callback(lua, "setPercent", function(modName:String, val:Float, player:Int = -1)
			PlayState.instance.modManager.setPercent(modName, val, player)
		);

		Lua_helper.add_callback(lua, "addBlankMod", function(modName:String, defaultVal:Float = 0, player:Int = -1) {
			PlayState.instance.modManager.registerBlankMod(modName, defaultVal, player);
		});

		Lua_helper.add_callback(lua, "setValue", function(modName:String, val:Float, player:Int = -1)
			PlayState.instance.modManager.setValue(modName, val, player)
		);

		Lua_helper.add_callback(lua, "getPercent", function(modName:String, player:Int)
			return PlayState.instance.modManager.getPercent(modName, player)
		);

		Lua_helper.add_callback(lua, "getValue", function(modName:String, player:Int)
			return PlayState.instance.modManager.getValue(modName, player)
		);

		Lua_helper.add_callback(lua, "setCurrentValue", function(modName:String, val:Float, player:Int){
			return PlayState.instance.modManager.setCurrentValue(modName, val, player);
		});
		
		Lua_helper.add_callback(lua, "getTargetValue", function(modName:String, player:Int){
			return PlayState.instance.modManager.getTargetValue(modName, player);
		});

		Lua_helper.add_callback(lua, "queueSet", function(step:Float, modName:String, target:Float, player:Int = -1)
			PlayState.instance.modManager.queueSet(step, modName, target, player)
		);

		Lua_helper.add_callback(lua, "queueSetP", function(step:Float, modName:String, perc:Float, player:Int = -1)
			PlayState.instance.modManager.queueSetP(step, modName, perc, player)
		);
		
		Lua_helper.add_callback(lua, "queueEase",
			function(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
				PlayState.instance.modManager.queueEase(step, endStep, modName, percent, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseP",
			function(step:Float, endStep:Float, modName:String, percent:Float, style:String = 'linear', player:Int = -1, ?startVal:Float)
				PlayState.instance.modManager.queueEaseP(step, endStep, modName, percent, style, player, startVal)
		);
		
	}
}