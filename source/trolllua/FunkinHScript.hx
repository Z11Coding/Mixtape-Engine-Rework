package trolllua;

import haxe.CallStack;
import trolllua.Util.ModchartSprite;
#if USING_FLXANIMATE
import funkin.objects.FlxAnimateCompat; // vscode stfu
#end
import trolllua.FunkinScript.ScriptType;
import trolllua.objects.IndependentVideoSprite;
import funkin.scripts.*;
import trolllua.Globals.*;

import states.PlayState;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;

import backend.window.os.Windows;

import flixel.FlxG;
import flixel.math.FlxPoint;

import lime.app.Application;
import haxe.Constraints.Function;

import hscript.*;

class FunkinHScript extends FunkinScript
{
	public static final parser:Parser = {
		var parser = new Parser();

		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.allowTypes = true;

		parser.preprocesorValues = trolllua.macros.Sowy.getDefines();
		//parser.preprocesorValues.set("TROLL_ENGINE", Main.Version.semanticVersion);

		parser;
	};
	
	public static final defaultVars:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function init() // BRITISH
	{
		
	}

	inline public static function parseString(script:String, ?name:String = "Script")
	{
		parser.line = 1;
		return parser.parseString(script, name);
	}

	inline public static function parseFile(file:String, ?name:String)
		return parseString(File.getContent(file), (name == null ? file : name));

	public static function blankScript(?name, ?additionalVars)
	{
		return new FunkinHScript(null, name, additionalVars, false);
	}

	/** No exception catching or display */
	public static function _fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true)
		return new FunkinHScript(parseString(script, name), name, additionalVars, doCreateCall);

	// safe ver
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true):FunkinHScript
	{
		try {
			return _fromString(script, name, additionalVars, doCreateCall);
		}
		catch (e:haxe.Exception) {
			var errMsg = 'Error parsing hscript! ' #if hscriptPos + '$name:' + parser.line + ', ' #end + e.message;
			trace(errMsg);

			#if desktop
			Application.current.window.alert(errMsg, "Error on haxe script!");
			#end
		}

		return new FunkinHScript(null, name, additionalVars, doCreateCall);
	}

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true):FunkinHScript
	{
		name = (name == null ? file : name);

		try {
			return _fromString(File.getContent(file), name, additionalVars, doCreateCall);
		}
		catch(e:haxe.Exception) {
			var msg = "Error parsing hscript! " + e.message;
			trace(msg);

			#if desktop
			var title = "Error on haxe script!";

			#if (cpp && windows)
			if (Windows.msgBox(msg, title, RETRYCANCEL | ERROR) == RETRY)
				return fromFile(file, name, additionalVars, doCreateCall);
			#else
			Application.current.window.alert(msg, title);
			#end
			#end
		}

		return new FunkinHScript(null, name, additionalVars, doCreateCall);
	}

	private static inline function trim_redundant_error_trace(message:String, posInfo:haxe.PosInfos):String
	{
		if (message.startsWith(posInfo.fileName)) {
			var to_remove = posInfo.fileName + ":" + posInfo.lineNumber + ": ";
			message = message.substr(to_remove.length); 
		}

		return message;
	}

	////
	private var interpreter(default, null):Interp = new Interp();

	public function new(?parsed:Expr, ?name:String = "HScript", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true)
	{
		super(name, ScriptType.HSCRIPT);

		set("Std", Std);
		set("Type", Type);
		set("Reflect", Reflect);
		set("Math", Math);
		set("StringTools", StringTools);
		set("Main", Main);

		set("StringMap", haxe.ds.StringMap);
		set("ObjectMap", haxe.ds.ObjectMap);
		set("EnumValueMap", haxe.ds.EnumValueMap);
		set("IntMap", haxe.ds.IntMap);

		set("Date", Date);
		set("DateTools", DateTools);
		
		set("getClass", Type.resolveClass);
		set("getEnum", Type.resolveEnum);
		
		#if NMV_MOD_COMPATIBILITY
		set("addHaxeLibrary", function(c:String, ?p:String){
			// Dumb hardcoded whatever idc!!!

			if (c == 'KUTValueHandler')
				return;

			if (c == 'HitSingleMenu'){
				importClass("funkin.states.FreeplayState");
				return;
			}

			if (p == 'meta.states')
				p = 'funkin.states';

			if (p == 'gameObjects')
				p = 'funkin.objects';

			if (p == 'gameObjects.shader')
				p = 'funkin.objects.shaders';

			if (p == 'meta.data')
				p = 'funkin.data';

			if (p == 'meta.data.scripts')
				p = 'funkin.scripts';


			if(p != null)
				importClass('$p.$c');
			else
				importClass(c);
		});
		#end
		set("importClass", importClass);
		set("importEnum", importEnum);

		//set("print", print);
		
		set("script", this);
		set("global", Globals.variables);
		set("FunkinHScript", FunkinHScript);

		setDefaultVars();
		setFlixelVars();
		setVideoVars();
		setFNFVars();

		for (variable => arg in defaultVars)
			set(variable, arg);

		if (additionalVars != null)
		{
			for (key => value in additionalVars)
				set(key, value);
		}

		if (parsed != null){
			run(parsed);
			
			if (doCreateCall)
				call('onCreate');
		}
	}

	/**
		Helper function
		Sets a bunch of basic variables for the script depending on the state
	**/
	override function setDefaultVars() {
		super.setDefaultVars();

		var currentState = flixel.FlxG.state;
		
		set("state", currentState);
		set("game", currentState);
		
		if (currentState is PlayState){
			var currentState:PlayState = cast currentState;
			var debugPrint:Function = Reflect.makeVarArgs(function(toPrint) {
				currentState.addTextToDebug('$scriptName: ${toPrint.join(', ')}', FlxColor.RED);
			});

			set("getInstance", getInstance);
			set("debugPrint", debugPrint);

		}else{
			set("getInstance", @:privateAccess FlxG.get_state);
			set("debugPrint", get("trace"));
			
		}
	}

	private function setFlixelVars() 
	{
		set("FlxG", FlxG);
		#if NMV_MOD_COMPATIBILITY
		set("FlxSprite", ModchartSprite);
		#else
		set("FlxSprite", FlxSprite);
		#end
		set("FlxCamera", FlxCamera);
		set("FlxSound", FlxSound);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxGroup", flixel.group.FlxGroup);
		set("FlxSave", flixel.util.FlxSave); // should probably give it 1 save instead of giving it FlxSave
		set("FlxBar", flixel.ui.FlxBar);

		set("FlxAxes", Wrappers.FlxAxes);
		set("FlxBarFillDirection", flixel.ui.FlxBar.FlxBarFillDirection);
		set("FlxText", flixel.text.FlxText);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);
		set("FlxCameraFollowStyle", flixel.FlxCamera.FlxCameraFollowStyle);

		set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);

		set("FlxParticle", flixel.effects.particles.FlxParticle);
		set("FlxTypedEmitter", flixel.effects.particles.FlxEmitter.FlxTypedEmitter);
		set("FlxSkewedSprite", flixel.addons.effects.FlxSkewedSprite);

		// Abstracts
		set("BlendMode", Wrappers.BlendMode);

		set("FlxColor", Wrappers.SowyColor);
		set("FlxPoint", {
			get: FlxPoint.get,
			weak: FlxPoint.weak
		});
		set("FlxTextAlign", Wrappers.FlxTextAlign);
		set("FlxTweenType", Wrappers.FlxTweenType); 
		#if USING_FLXANIMATE
		set("FlxAnimate", FlxAnimateCompat);
		#end
	}

	private function setVideoVars() {
		// TODO: create a compatibility wrapper for the various versions
		// (so you can use any version of hxcodec and use the same versions)

		#if !VIDEOS_ALLOWED
		set("hxcodec", "0");
		set("MP4Handler", null);
		set("MP4Sprite", null);
		#else
		#if (hxCodec >= "3.0.0")
		set("hxcodec", "3.0.0");
		set("MP4Handler", hxcodec.flixel.FlxVideo);
		set("MP4Sprite", hxcodec.flixel.FlxVideoSprite); // idk how hxcodec 3.0.0 works :clueless:
		#elseif (hxCodec >= "2.6.1")
		set("hxcodec", "2.6.1");
		set("MP4Handler", hxcodec.VideoHandler);
		set("MP4Sprite", hxcodec.VideoSprite);
		#elseif (hxCodec == "2.6.0")
		set("hxcodec", "2.6.0");
		set("MP4Handler", VideoHandler);
		set("MP4Sprite", VideoSprite);
		#elseif (hxCodec)
		set("hxcodec", "1.0.0");
		set("MP4Handler", vlc.MP4Handler);
		set("MP4Sprite", vlc.MP4Sprite);
		#else
		set("hxcodec", "0");
		#end
		#if (hxvlc)
		set("hxvlc", "1.0.0");
		set("MP4Handler", hxvlc.flixel.FlxVideo);
		set("MP4Sprite", hxvlc.flixel.FlxVideoSprite);
		#else
		set("hxvlc", "0");
		#end
		#end	
		set("VideoSprite", IndependentVideoSprite); // Should use this in future !

	}

	private function setFNFVars() {
		// FNF-specific things
		//set("controls", PlayerSettings.player1.controls);
		//set("get_controls", () -> return PlayerSettings.player1.controls);
		
		set("Paths", backend.Paths);
		set("Conductor", backend.Conductor);
		set("ClientPrefs", backend.ClientPrefs);
		set("CoolUtil", backend.CoolUtil);

		set("newShader", Paths.getShader);

		set("PlayState", states.PlayState);
		set("MusicBeatState", backend.MusicBeatState);
		set("MusicBeatSubstate", backend.MusicBeatSubstate);
		set("GameOverSubstate", substates.GameOverSubstate);
		set("Song", backend.Song);
		set("BGSprite", objects.BGSprite);
		//set("RatingSprite", funkin.objects.RatingGroup.RatingSprite);

		set("Note", objects.Note);
		set("NoteObject", objects.NoteObject);
		set("NoteSplash", objects.NoteSplash);
		set("StrumNote", objects.StrumNote);
		set("PlayField", objects.playfields.PlayField);
		set("NoteField", objects.playfields.NoteField);

		set("ProxyField", objects.proxies.ProxyField);
		set("ProxySprite", objects.proxies.ProxySprite);
		set("AltBGSprite", objects.BGSprite.AltBGSprite);

		set("FlxSprite3D", objects.FlxSprite3D);

		set("AttachedSprite", objects.AttachedSprite);
		set("AttachedText", objects.AttachedText);

		set("Character", objects.Character);
		set("HealthIcon", objects.HealthIcon);

		//set("Wife3", data.JudgmentManager.Wife3);
		//set("PBot", data.JudgmentManager.PBot);
		//set("JudgmentManager", data.JudgmentManager);
		//set("Judgement", Wrappers.Judgment);

		set("ModManager", backend.modchart.ModManager);
		set("Modifier", backend.modchart.Modifier);
		set("SubModifier", backend.modchart.SubModifier);
		set("NoteModifier", backend.modchart.NoteModifier);
		set("EventTimeline", backend.modchart.EventTimeline);
		set("StepCallbackEvent", backend.modchart.events.StepCallbackEvent);
		set("CallbackEvent", backend.modchart.events.CallbackEvent);
		set("ModEvent", backend.modchart.events.ModEvent);
		set("EaseEvent", backend.modchart.events.EaseEvent);
		set("SetEvent", backend.modchart.events.SetEvent);

		//set("HScriptedHUD", funkin.objects.hud.HScriptedHUD);
		set("HScriptModifier", backend.modchart.HScriptModifier);

		set("HScriptedState", trolllua.states.HScriptedState);
		set("HScriptedSubstate", trolllua.states.HScriptedSubstate);
	} 

	function importClass(className:String)
	{
		// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
		// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
		// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
		var classSplit:Array<String> = className.split(".");
		var daClassName = classSplit[classSplit.length - 1]; // last one

		if (daClassName == '*')
		{
			var daClass = Type.resolveClass(className);

			while (classSplit.length > 0 && daClass == null)
			{
				daClassName = classSplit.pop();
				daClass = Type.resolveClass(classSplit.join("."));
				if (daClass != null)
					break;
			}
			if (daClass != null)
			{
				for (field in Reflect.fields(daClass))
					set(field, Reflect.field(daClass, field));
			}
			else
			{
				FlxG.log.error('Could not import class $className');
			}
		}
		else
		{
			set(daClassName, Type.resolveClass(className));
		}
	}

	function importEnum(enumName:String)
	{
		// same as importClass, but for enums
		// and it cant have enum.*;
		var splitted:Array<String> = enumName.split(".");
		var daEnum = Type.resolveEnum(enumName);
		if (daEnum != null)
			set(splitted.pop(), daEnum);
	}

	/**
	 * Parses and executes string code
	 */
	public function executeCode(source:String):Dynamic
		return run(parseString(source, scriptName));
	
	public function run(parsed:Expr) {
		var returnValue:Dynamic = null;
		try {
			trace('Running haxe script: $scriptName');
			returnValue = interpreter.execute(parsed);
		}
		catch (e:haxe.Exception)
		{
			var posInfo = interpreter.posInfos();
			var message = trim_redundant_error_trace(e.message, posInfo);
			
			haxe.Log.trace(message, posInfo);
		}
		return returnValue;
	}

	public function stop()
	{
		//trace('stopping $scriptName');

		// idk if there's really a stop function or anythin for hscript so
		if (interpreter != null && interpreter.variables != null)
			interpreter.variables.clear();

		interpreter = null;
	}

	public function get(varName:String):Dynamic
	{
		return (interpreter == null) ? null : interpreter.variables.get(varName);
	}

	public function set(varName:String, value:Dynamic):Void
	{
		if (interpreter != null)
			interpreter.variables.set(varName, value);
	}

	public function exists(varName:String):Bool
	{
		return interpreter != null && interpreter.variables.exists(varName);
	}

	public function call(func:String, ?parameters:Array<Dynamic>, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		var returnValue:Dynamic = executeFunc(func, parameters, null, extraVars);
		
		return returnValue == null ? Function_Continue : returnValue;
	}

	/**
	 * Calls a function within the script
	**/
	public function executeFunc(funcName:String, ?parameters:Array<Dynamic>, ?parentObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		var daFunc:Function = get(funcName);

		if (!Reflect.isFunction(daFunc))
			return null;

		if (parameters == null)
			parameters = [];

		if (parentObject != null){
			if (extraVars == null) extraVars = [];
			extraVars.set("this", parentObject);
		}

		var prevVals:Map<String, Dynamic> = null;

		if (extraVars != null) {
			prevVals = [];

			for (name => value in extraVars) {
				prevVals.set(name, get(name));
				set(name, value);
			}
		}

		var returnVal:Dynamic = null;
		try {
			returnVal = Reflect.callMethod(parentObject, daFunc, parameters);
		}
		catch (e:haxe.Exception)
		{
			var posInfo = interpreter.posInfos();
			var message = trim_redundant_error_trace(e.message, posInfo);

			//print('$scriptName: Error executing $funcName(${  parameters.join(', ')  })');
			//print(haxe.Log.formatOutput(message, posInfo));
		}

		if (prevVals != null) {
			for (name => value in prevVals)
				set(name, value);
		}

		return returnVal;
	}
}
