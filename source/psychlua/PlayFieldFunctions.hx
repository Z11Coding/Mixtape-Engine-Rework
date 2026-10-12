package psychlua;


class PlayFieldFunctions
{
	public static function implement(funk:FunkinLua)
	{
		//TODO: use this when the modchart system actually gets added
		var lua = funk.lua;
		Lua_helper.add_callback(lua, "thing", function()
		{
			// Do Thing
		});

	}
}
