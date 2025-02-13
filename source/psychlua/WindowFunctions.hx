package psychlua;
import llua.State;
import utils.window.*;
import states.PlayState;
class WindowFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		var game:PlayState = PlayState.instance;
		Lua_helper.add_callback(lua, "setWindowOppacity", function(num:Float = 1) {
			CppAPI.setWindowOppacity(num);
		});

		Lua_helper.add_callback(lua, "setWallpaper", function(path:String = "old") {
			CppAPI.setWallpaper(path);
		});

		Lua_helper.add_callback(lua, "hideTaskbar", function() {
			CppAPI.hideTaskbar();
		});

		Lua_helper.add_callback(lua, "restoreTaskbar", function() {
			CppAPI.restoreTaskbar();
		});

		Lua_helper.add_callback(lua, "hideWindows", function() {
			CppAPI.hideWindows();
		});

		Lua_helper.add_callback(lua, "restoreWindows", function() {
			CppAPI.restoreWindows();
		});

		Lua_helper.add_callback(lua, "setTransparency", function(color:Int, ?winName:String) {
			CppAPI.setTransparency(winName, color);
		});

		Lua_helper.add_callback(lua, "resetTransparency", function() {
			CppAPI.reset();
		});

		Lua_helper.add_callback(lua, "windowX", function() {
			return Window.x;
		});
		
		Lua_helper.add_callback(lua, "windowY", function() {
			return Window.y;
		});

		Lua_helper.add_callback(lua, "windowWidth", function() {
			return Window.width;
		});

		Lua_helper.add_callback(lua, "windowHeight", function() {
			return Window.height;
		});

		Lua_helper.add_callback(lua, "windowTitle", function() {
			return Window.title;
		});
		
		Lua_helper.add_callback(lua, "windowReset", function() {
			WindowUtils.resetTitle();
			Window.reset();
		});
		
		Lua_helper.add_callback(lua, "windowSetPos", function(x:Int, y:Int) {
			Window.setPos(x, y);
		});

		Lua_helper.add_callback(lua, "windowSetSize", function(width:Int, height:Int) {
			Window.setSize(width, height);
		});

		Lua_helper.add_callback(lua, "windowPopup", function(message:String = "", title:String = "") {
			Window.alert(message, title);
		});

		Lua_helper.add_callback(lua, "setWindowTitle", function(title:String = "") {
			WindowUtils.winTitle = title;
		});

		Lua_helper.add_callback(lua, "setWindowPrefix", function(title:String = "") {
			WindowUtils.prefix = title;
		});

		Lua_helper.add_callback(lua, "setWindowSuffix", function(title:String = "") {
			WindowUtils.suffix = title;
		});

		Lua_helper.add_callback(lua, "sendNotification", function(title:String = "", desc:String = "") {
			CppAPI.sendWindowsNotification(title, desc);
		});
	}
}