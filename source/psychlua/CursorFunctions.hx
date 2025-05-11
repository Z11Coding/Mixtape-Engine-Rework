package psychlua;

class CursorFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		//Fun cursor things for lua
		Lua_helper.add_callback(lua, "getCursorMode", function()
		{
			return Cursor.cursorMode;
		});
		
		Lua_helper.add_callback(lua, "setCursorMode", function(mode:String)
		{
			Cursor.cursorMode = LuaUtils.interpCurseMode(mode);
		});
		
	}
}