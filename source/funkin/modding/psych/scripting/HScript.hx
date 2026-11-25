#if HSCRIPT_ALLOWED
package funkin.modding.psych.scripting;

import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Interp;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.Conductor;
import funkin.Preferences;
import funkin.assets.Paths;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.stage.StageData;
import funkin.input.Controls;
import funkin.modding.ModManager;
import funkin.modding.PolymodHandler;
import funkin.play.Countdown;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.play.components.HealthIcon;
import funkin.play.modchartSystem.ModConstants;
import funkin.play.modchartSystem.ModEventHandler;
import funkin.play.modchartSystem.ModHandler;
import funkin.play.modchartSystem.NoteData;
import funkin.play.modchartSystem.modifiers.BaseModifier;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.Strumline;
import funkin.play.notes.StrumlineNote;
import funkin.play.song.Song;
import funkin.play.stage.Stage;
import funkin.ui.MusicBeatState;
import funkin.util.Constants;
import openfl.display.BlendMode;
import openfl.display.TriangleCulling;
#if LUA_ALLOWED
import funkin.modding.psych.scripting.FunkinLua;
#end
#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end

typedef HScriptInfos =
{
  > haxe.PosInfos,
  var ?funcName:String;
  var ?showLine:Null<Bool>;
  #if LUA_ALLOWED
  var ?isLua:Null<Bool>;
  #end
}

class HScript extends Iris
{
  public var filePath:String;
  public var origin:String;
  public var modFolder:Null<String>;
  public var returnValue:Dynamic;
  var varsToBring(default, set):Any = null;

  #if LUA_ALLOWED
  public var parentLua:Null<FunkinLua>;

  public static function initHaxeModule(parent:FunkinLua):Void
  {
    if (parent.hscript == null) parent.hscript = new HScript(parent, '', null, true);
  }

  public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null):Void
  {
    if (parent.hscript == null)
    {
      try
      {
        parent.hscript = new HScript(parent, code, varsToBring);
      }
      catch (e:Dynamic)
      {
        trace('Failed to initialize HScript in "${parent.scriptName}": ${Std.string(e)}');
      }
      return;
    }

    final hscript = parent.hscript;
    try
    {
      hscript.scriptCode = code;
      hscript.varsToBring = varsToBring;
      hscript.parse(true);
      hscript.returnValue = hscript.execute();
    }
    catch (e:Dynamic)
    {
      trace('Failed to execute HScript in "${parent.scriptName}": ${Std.string(e)}');
      hscript.returnValue = null;
    }
  }
  #end

  override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?manualRun:Bool = false)
  {
    this.filePath = file ?? '';
    this.origin = this.filePath;

    var code = file ?? '';
    var scriptName:Null<String> = null;
    #if sys
    if (parent == null && file != null && file.indexOf('\n') < 0 && FileSystem.exists(file) && !FileSystem.isDirectory(file))
    {
      code = File.getContent(file);
      scriptName = file;
      findModFolder(file);
    }
    #end

    #if LUA_ALLOWED
    if (scriptName == null && parent != null)
    {
      parentLua = cast parent;
      scriptName = parentLua.scriptName;
      origin = parentLua.scriptName;
      modFolder = parentLua.modFolder;
    }
    #end

    super(code, new IrisConfig(scriptName, false, false));

    final customInterp = new CustomInterp();
    customInterp.parentInstance = PlayState.instance;
    customInterp.showPosOnLog = false;
    this.interp = customInterp;

    preset();
    this.varsToBring = varsToBring;
    if (!manualRun)
    {
      try
      {
        returnValue = execute();
      }
      catch (e:Dynamic)
      {
        returnValue = null;
        destroy();
        throw e;
      }
    }
  }

  function findModFolder(path:String):Void
  {
    #if (sys && MODS_ALLOWED)
    final normalizedRoot = Path.normalize(PolymodHandler.MOD_FOLDER).replace('\\', '/');
    final normalizedPath = Path.normalize(path).replace('\\', '/');
    final prefix = normalizedRoot.endsWith('/') ? normalizedRoot : '$normalizedRoot/';
    if (!normalizedPath.startsWith(prefix)) return;

    final relativePath = normalizedPath.substring(prefix.length);
    final modId = relativePath.split('/')[0];
    if (ModManager.getModEngine(modId) == ModManager.ENGINE_PSYCH) modFolder = modId;
    #end
  }

  @:inheritDoc
  override function preset():Void
  {
    super.preset();

    set('Type', Type);
    set('Std', Std);
    set('Math', Math);
    set('StringTools', StringTools);
    set('Date', Date);
    set('FlxG', FlxG);
    set('FlxMath', flixel.math.FlxMath);
    set('FlxSprite', FlxSprite);
    set('FlxText', FlxText);
    set('FlxCamera', FlxCamera);
    set('FlxGamepadInputID', FlxGamepadInputID);
    set('FlxTimer', FlxTimer);
    set('FlxTween', FlxTween);
    set('FlxEase', FlxEase);
    set('FlxPoint', {get: FlxPoint.get, weak: FlxPoint.weak});
    set('FlxColor', FlxColor);
    set('FlxSound', FlxSound);
    set('FlxTypedGroup', FlxTypedGroup);
    set('FlxSpriteGroup', FlxSpriteGroup);
    set('BlendMode', BlendMode);
    set('FlxAxes', flixel.util.FlxAxes);
    set('FlxKey', flixel.input.keyboard.FlxKey);
    set('FlxTextAlign', FlxText.FlxTextAlign);
    set('FlxTextBorderStyle', FlxText.FlxTextBorderStyle);
    set('TriangleCulling', TriangleCulling);
    set('Paths', Paths);
    set('Conductor', Conductor);
    set('PlayState', PlayState);
    set('MusicBeatState', MusicBeatState);
    set('Preferences', Preferences);
    set('Constants', Constants);
    set('Song', Song);
    set('SongNoteData', SongNoteData);
    set('Stage', Stage);
    set('StageData', StageData);
    set('Character', BaseCharacter);
    set('Note', NoteSprite);
    set('StrumNote', StrumlineNote);
    set('Strumline', Strumline);
    set('NoteSplash', NoteSplash);
    set('HealthIcon', HealthIcon);
    set('Countdown', Countdown);
    set('ModConstants', ModConstants);
    set('ModHandler', ModHandler);
    set('ModEventHandler', ModEventHandler);
    set('NoteData', NoteData);
    set('BaseModifier', BaseModifier);
    set('CustomModifier', BaseModifier.CustomModifier);
    set('downScroll', Preferences.downscroll);
    set('upScroll', !Preferences.downscroll);
    set('modFolder', modFolder);
    set('currentModDirectory', modFolder ?? '');
    set('this', this);
    set('game', PlayState.instance);
    set('state', FlxG.state);
    set('controls', Controls.instance);
    set('screenWidth', FlxG.width);
    set('screenHeight', FlxG.height);
    set('songPosition', Conductor.instance.songPosition);
    set('health', PlayState.instance?.health ?? 1.0);
    set('Function_Stop', LuaUtils.Function_Stop);
    set('Function_Continue', LuaUtils.Function_Continue);
    set('Function_StopLua', LuaUtils.Function_StopLua);
    set('Function_StopHScript', LuaUtils.Function_StopHScript);
    set('Function_StopAll', LuaUtils.Function_StopAll);

    set('setVar', function(name:String, value:Dynamic)
    {
      MusicBeatState.getVariables().set(name, value);
      return value;
    });
    set('getVar', function(name:String)
    {
      return MusicBeatState.getVariables().get(name);
    });
    set('removeVar', function(name:String)
    {
      return MusicBeatState.getVariables().remove(name);
    });
    set('debugPrint', function(text:Dynamic, ?color:Dynamic)
    {
      final outputColor:FlxColor = color == null ? FlxColor.WHITE : cast color;
      if (PlayState.instance != null) PlayState.instance.addTextToDebug(Std.string(text), outputColor);
      else trace(Std.string(text));
    });
    set('getModSetting', function(saveTag:String, ?modName:String = null)
    {
      final targetMod = modName ?? this.modFolder;
      if (targetMod == null)
      {
        trace('getModSetting: no mod name was supplied and this script is not inside a Psych mod.');
        return null;
      }
      return LuaUtils.getModSetting(saveTag, targetMod);
    });

    set('keyJustPressed', function(name:String = '') return getControlState(name, 0));
    set('keyPressed', function(name:String = '') return getControlState(name, 1));
    set('keyReleased', function(name:String = '') return getControlState(name, 2));
    set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
    set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
    set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));
    set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
    set('anyGamepadPressed', function(name:String) return FlxG.gamepads.anyPressed(name));
    set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));
    set('gamepadJustPressed', function(id:Int, name:String)
    {
      final controller = FlxG.gamepads.getByID(id);
      return controller != null && Reflect.getProperty(controller.justPressed, name) == true;
    });
    set('gamepadPressed', function(id:Int, name:String)
    {
      final controller = FlxG.gamepads.getByID(id);
      return controller != null && Reflect.getProperty(controller.pressed, name) == true;
    });
    set('gamepadReleased', function(id:Int, name:String)
    {
      final controller = FlxG.gamepads.getByID(id);
      return controller != null && Reflect.getProperty(controller.justReleased, name) == true;
    });
    set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
    {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? 0.0 : controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
    {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? 0.0 : controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });

    set('getHealth', function() return PlayState.instance?.health ?? 1.0);
    set('getProperty', function(path:String) return getProperty(path));
    set('setProperty', function(path:String, value:Dynamic) return setProperty(path, value));
    set('getPropertyFromClass', function(className:String, path:String) return getClassProperty(className, path));
    set('setPropertyFromClass', function(className:String, path:String, value:Dynamic) return setClassProperty(className, path, value));

    set('setBlendMode', function(tag:String, mode:String)
    {
      final sprite = getSprite(tag);
      if (sprite != null) sprite.blend = ModConstants.blendModeFromString(mode);
    });
    set('getBlendMode', function(mode:String) return ModConstants.blendModeFromString(mode));
    set('culling', function(value:String)
    {
      return switch (value.toLowerCase())
      {
        case 'positive': TriangleCulling.POSITIVE;
        case 'negative': TriangleCulling.NEGATIVE;
        default: TriangleCulling.NONE;
      };
    });
    set('createCustomEase', function(name:String, ease:Float->Float)
    {
      final handler = PlayState.instance?.modchartEventHandler;
      if (handler != null) handler.customEases.set(name, ease);
    });
    set('createSprGroup', function(tag:String, addToGame:Bool = true)
    {
      var group:FlxTypedGroup<FlxSprite> = cast PlayState.instance?.variables.get(tag);
      if (group == null)
      {
        group = new FlxTypedGroup<FlxSprite>();
        if (addToGame)
        {
          PlayState.instance.variables.set(tag, group);
          PlayState.instance.add(group);
        }
      }
      return group;
    });
    set('addToSprGrp', function(tag:String, sprite:FlxSprite)
    {
      final group:FlxTypedGroup<FlxSprite> = cast PlayState.instance?.variables.get(tag);
      if (group != null) group.add(sprite);
      return group;
    });
    set('getSpr', function(tag:String) return getSprite(tag));
    set('createSpr', function(tag:String, imagePath:String, addToGame:Bool = true)
    {
      final sprite = new FlxSprite();
      sprite.loadGraphic(Paths.image(imagePath));
      sprite.scrollFactor.set();
      if (addToGame) addSprite(tag, sprite);
      return sprite;
    });
    set('createZSpr', function(tag:String, imagePath:String, addToGame:Bool = true)
    {
      final sprite = new funkin.graphics.ZSprite();
      sprite.loadGraphic(Paths.image(imagePath));
      sprite.scrollFactor.set();
      if (addToGame) addSprite(tag, sprite);
      return sprite;
    });
    set('createCloneMod', function(name:String) return ModConstants.createNewMod(name));
    set('createCustomMod', function(name:String, ?defaultValue:Float = 0) return ModConstants.createNewCustomMod(name, defaultValue));
    set('setResetEvent', function(callback:Void->Void) addResetCallback(callback));
    set('addResetEvent', function(callback:Void->Void) addResetCallback(callback));
    set('addUpdate', function(callback:Float->Void)
    {
      if (PlayState.instance != null) PlayState.instance.perframeFunctions.push(callback);
    });
    set('print', function(text:Dynamic, ?color:Dynamic)
    {
      final outputColor:FlxColor = color == null ? FlxColor.WHITE : cast color;
      if (PlayState.instance != null) PlayState.instance.modDebugNotif(Std.string(text), outputColor);
      else trace(Std.string(text));
    });
    set('stringSplit', function(input:String, separator:String) return input.split(separator));
    set('existsFromMap', function(map:Dynamic, key:Dynamic) return map != null && map.exists(key));
    set('getFromMap', function(map:Dynamic, key:Dynamic) return map == null ? null : map.get(key));
    set('addHaxeLibrary', function(className:String, ?packageName:String = '')
    {
      final path = packageName.length > 0 ? '$packageName.$className' : className;
      final resolved:Dynamic = Type.resolveClass(path) ?? Type.resolveEnum(path);
      if (resolved != null) set(className, resolved);
      else trace('addHaxeLibrary: could not resolve "$path".');
    });

    #if LUA_ALLOWED
    set('parentLua', parentLua);
    set('createGlobalCallback', function(name:String, callback:Dynamic)
    {
      if (name == 'makeVideoSprite') return;
      for (script in FunkinLua.runningScripts)
      {
        if (script.lua != null && !script.closed) Lua_helper.add_callback(script.lua, name, callback);
      }
      FunkinLua.customFunctions.set(name, callback);
    });
    set('createCallback', function(name:String, callback:Dynamic, ?funk:FunkinLua = null)
    {
      final target = funk ?? parentLua;
      if (target != null) target.addLocalCallback(name, callback);
      else trace('createCallback: no Lua script was provided.');
    });
    #else
    set('parentLua', null);
    #end
  }

  function getProperty(path:String):Dynamic
  {
    final split = path.split('.');
    var target:Dynamic = PlayState.instance;
    if (split.length == 0) return null;

    if (MusicBeatState.getVariables().exists(split[0]))
    {
      target = MusicBeatState.getVariables().get(split.shift());
    }
    else if (split[0] == 'game' || split[0] == 'this')
    {
      split.shift();
    }

    return getNestedProperty(target, split);
  }

  function setProperty(path:String, value:Dynamic):Dynamic
  {
    final split = path.split('.');
    if (split.length == 0) return value;
    var target:Dynamic = PlayState.instance;

    if (MusicBeatState.getVariables().exists(split[0]))
    {
      target = MusicBeatState.getVariables().get(split.shift());
    }
    else if (split[0] == 'game' || split[0] == 'this')
    {
      split.shift();
    }

    return setNestedProperty(target, split, value);
  }

  function getNestedProperty(target:Dynamic, path:Array<String>):Dynamic
  {
    for (field in path)
    {
      if (target == null) return null;
      target = Reflect.getProperty(target, field);
    }
    return target;
  }

  function setNestedProperty(target:Dynamic, path:Array<String>, value:Dynamic):Dynamic
  {
    if (path.length == 0) return value;
    for (i in 0...(path.length - 1))
    {
      if (target == null) return value;
      target = Reflect.getProperty(target, path[i]);
    }
    if (target != null) Reflect.setProperty(target, path[path.length - 1], value);
    return value;
  }

  function getClassProperty(className:String, path:String):Dynamic
  {
    final target:Dynamic = resolveScriptClass(className);
    return target == null ? null : getNestedProperty(target, path.split('.'));
  }

  function setClassProperty(className:String, path:String, value:Dynamic):Dynamic
  {
    final target:Dynamic = resolveScriptClass(className);
    if (target != null) setNestedProperty(target, path.split('.'), value);
    return value;
  }

  function getControlState(name:String, state:Int):Bool
  {
    return switch (name.toLowerCase())
    {
      case 'left':
        state == 0 ? Controls.instance.NOTE_LEFT_P : (state == 1 ? Controls.instance.NOTE_LEFT : Controls.instance.NOTE_LEFT_R);
      case 'down':
        state == 0 ? Controls.instance.NOTE_DOWN_P : (state == 1 ? Controls.instance.NOTE_DOWN : Controls.instance.NOTE_DOWN_R);
      case 'up':
        state == 0 ? Controls.instance.NOTE_UP_P : (state == 1 ? Controls.instance.NOTE_UP : Controls.instance.NOTE_UP_R);
      case 'right':
        state == 0 ? Controls.instance.NOTE_RIGHT_P : (state == 1 ? Controls.instance.NOTE_RIGHT : Controls.instance.NOTE_RIGHT_R);
      default:
        state == 0 ? Controls.instance.justPressed(name) : (state == 1 ? Controls.instance.pressed(name) : Controls.instance.justReleased(name));
    };
  }

  function resolveScriptClass(className:String):Dynamic
  {
    return switch (className)
    {
      case 'PlayState': PlayState;
      case 'Preferences' | 'ClientPrefs': Preferences;
      case 'Conductor': Conductor;
      case 'FlxG': FlxG;
      default: Type.resolveClass(className);
    };
  }

  function getSprite(tag:String):Null<FlxSprite>
  {
    if (PlayState.instance == null) return null;
    final customSprite = PlayState.instance.customLuaSprites.get(tag);
    if (customSprite != null) return customSprite;
    return cast PlayState.instance.variables.get(tag);
  }

  function addSprite(tag:String, sprite:FlxSprite):Void
  {
    if (PlayState.instance == null) return;
    PlayState.instance.customLuaSprites.set(tag, sprite);
    PlayState.instance.variables.set(tag, sprite);
    PlayState.instance.add(sprite);
  }

  function addResetCallback(callback:Void->Void):Void
  {
    final handler = PlayState.instance?.modchartEventHandler;
    if (handler != null) handler.modResetFuncs.push(callback);
  }

  #if LUA_ALLOWED
  public static function implement(funk:FunkinLua):Void
  {
    funk.addLocalCallback('runHaxeCode', function(code:String, ?varsToBring:Any = null, ?functionName:String = null, ?args:Array<Dynamic> = null):Dynamic
    {
      initHaxeModuleCode(funk, code, varsToBring);
      if (funk.hscript == null) return null;

      if (functionName == null) return funk.hscript.returnValue;
      final result = funk.hscript.call(functionName, args);
      if (result != null && LuaUtils.isLuaSupported(result.returnValue)) return result.returnValue;
      return null;
    });
    funk.addLocalCallback('runHaxeFunction', function(functionName:String, ?args:Array<Dynamic> = null):Dynamic
    {
      if (funk.hscript == null)
      {
        trace('runHaxeFunction: initialize HScript with runHaxeCode first.');
        return null;
      }

      final result = funk.hscript.call(functionName, args);
      return result != null && LuaUtils.isLuaSupported(result.returnValue) ? result.returnValue : null;
    });
    funk.addLocalCallback('addHaxeLibrary', function(className:String, ?packageName:String = ''):Void
    {
      initHaxeModule(funk);
      final path = packageName.length > 0 ? '$packageName.$className' : className;
      final resolved:Dynamic = Type.resolveClass(path) ?? Type.resolveEnum(path);
      if (resolved != null) funk.hscript.set(className, resolved);
      else trace('addHaxeLibrary: could not resolve "$path".');
    });
  }
  #end

  override function call(functionName:String, ?args:Array<Dynamic>):IrisCall
  {
    if (functionName == null || interp == null || !exists(functionName)) return null;

    try
    {
      final callback = interp.variables.get(functionName);
      final result = Reflect.callMethod(null, callback, args ?? []);
      return {funName: functionName, signature: callback, returnValue: result};
    }
    catch (e:IrisError)
    {
      Iris.error(Printer.errorToString(e, false), interp.posInfos());
    }
    catch (e:Dynamic)
    {
      Iris.error(Std.string(e), interp.posInfos());
    }
    return null;
  }

  override public function destroy():Void
  {
    origin = null;
    #if LUA_ALLOWED
    parentLua = null;
    #end
    super.destroy();
  }

  function set_varsToBring(values:Any):Any
  {
    if (varsToBring != null)
    {
      for (key in Reflect.fields(varsToBring))
      {
        final name = key.trim();
        if (exists(name)) interp.variables.remove(name);
      }
    }

    if (values != null)
    {
      for (key in Reflect.fields(values))
      {
        final name = key.trim();
        set(name, Reflect.field(values, key));
      }
    }
    return varsToBring = values;
  }
}

class CustomInterp extends Interp
{
  public var parentInstance(default, set):Dynamic;
  var instanceFields:Array<String> = [];

  function set_parentInstance(instance:Dynamic):Dynamic
  {
    parentInstance = instance;
    instanceFields = instance == null ? [] : Type.getInstanceFields(Type.getClass(instance));
    return instance;
  }

  public function new()
  {
    super();
  }

  override function fcall(object:Dynamic, functionName:String, args:Array<Dynamic>):Dynamic
  {
    for (usingFunction in usings)
    {
      final result = usingFunction.call(object, functionName, args);
      if (result != null) return result;
    }

    final callback = get(object, functionName);
    if (callback == null)
    {
      Iris.error('Tried to call null function $functionName', posInfos());
      return null;
    }
    return Reflect.callMethod(object, callback, args);
  }

  override function resolve(name:String):Dynamic
  {
    if (locals.exists(name)) return locals.get(name).r;
    if (variables.exists(name)) return variables.get(name);
    if (imports.exists(name)) return imports.get(name);
    if (parentInstance != null && instanceFields.contains(name)) return Reflect.getProperty(parentInstance, name);

    error(EUnknownVariable(name));
    return null;
  }
}
#end
