package psychlua;

import backend.window.*;
import openfl.Lib;
class WindowFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		var game:PlayState = PlayState.instance;

		#if windows
		Lua_helper.add_callback(lua, "setWindowOppacity", function(num:Float) {
			CppAPI.setWindowOppacity(num);
		});

		Lua_helper.add_callback(lua, "setWallpaper", function(path:String) {
			CppAPI.setWallpaper(path);
		});

		Lua_helper.add_callback(lua, "hideTaskbar", function(path:String) {
			CppAPI.hideTaskbar();
		});

		Lua_helper.add_callback(lua, "restoreTaskbar", function(path:String) {
			CppAPI.restoreTaskbar();
		});

		Lua_helper.add_callback(lua, "hideWindows", function(path:String) {
			CppAPI.hideWindows();
		});

		Lua_helper.add_callback(lua, "restoreWindows", function(path:String) {
			CppAPI.restoreWindows();
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

		Lua_helper.add_callback(lua, "windowPopup", function(message:String, title:String) {
			Window.alert(message, title);
		});

		Lua_helper.add_callback(lua, "setWindowTitle", function(title:String) {
			WindowUtils.winTitle = title;
		});

		Lua_helper.add_callback(lua, "setWindowPrefix", function(title:String) {
			WindowUtils.prefix = title;
		});

		Lua_helper.add_callback(lua, "setWindowSuffix", function(title:String) {
			WindowUtils.suffix = title;
		});

		Lua_helper.add_callback(lua, "setTransparency", function(color:Int, ?winName:String) {
			CppAPI.setTransparency(winName, color);
		});

		// Process Priority Functions
		Lua_helper.add_callback(lua, "setProcessPriority", function(priority:Int) {
			return CppAPI.setPriority(priority);
		});

		Lua_helper.add_callback(lua, "getProcessPriority", function() {
			return CppAPI.getPriority();
		});

		Lua_helper.add_callback(lua, "getProcessPriorityString", function() {
			return CppAPI.getPriorityString();
		});

		Lua_helper.add_callback(lua, "setProcessPriorityString", function(priorityString:String) {
			return CppAPI.setPriorityString(priorityString);
		});

		Lua_helper.add_callback(lua, "resetProcessPriorityToNormal", function() {
			return CppAPI.resetPriorityToNormal();
		});

		Lua_helper.add_callback(lua, "startProcessPriorityMonitoring", function(?targetPriority:Int = 2, ?forceLock:Bool = false, ?monitorIntervalMs:Float = 1000) {
			CppAPI.startPriorityMonitoring(targetPriority, forceLock, monitorIntervalMs);
		});

		Lua_helper.add_callback(lua, "stopProcessPriorityMonitoring", function() {
			CppAPI.stopPriorityMonitoring();
		});

		Lua_helper.add_callback(lua, "isProcessPriorityMonitoring", function() {
			return CppAPI.isMonitoring();
		});

		Lua_helper.add_callback(lua, "isProcessPriorityForceLockEnabled", function() {
			return CppAPI.isForceLockEnabled();
		});

		Lua_helper.add_callback(lua, "getProcessPriorityTarget", function() {
			return CppAPI.getTargetPriority();
		});

		Lua_helper.add_callback(lua, "setProcessPriorityTarget", function(priority:Int) {
			CppAPI.setTargetPriority(priority);
		});

		Lua_helper.add_callback(lua, "setProcessPriorityForceLock", function(enabled:Bool, ?targetPriority:Int) {
			CppAPI.setForceLock(enabled, targetPriority);
		});

		// Efficiency Mode Functions
		Lua_helper.add_callback(lua, "enableEfficiencyMode", function() {
			return backend.window.EfficiencyMode.setEfficiencyMode(true);
		});

		Lua_helper.add_callback(lua, "disableEfficiencyMode", function() {
			return backend.window.EfficiencyMode.setEfficiencyMode(false);
		});

		Lua_helper.add_callback(lua, "toggleEfficiencyMode", function() {
			return backend.window.EfficiencyMode.toggle();
		});

		Lua_helper.add_callback(lua, "isEfficiencyModeActive", function() {
			return backend.window.EfficiencyMode.isActive();
		});

		Lua_helper.add_callback(lua, "isEfficiencyModeSupported", function() {
			return backend.window.EfficiencyMode.isSupported();
		});

		Lua_helper.add_callback(lua, "getEfficiencyModeStatus", function() {
			return backend.window.EfficiencyMode.getStatusString();
		});

		Lua_helper.add_callback(lua, "getEfficiencyModeDescription", function() {
			return backend.window.EfficiencyMode.getDescription();
		});
		#end
	}
}
