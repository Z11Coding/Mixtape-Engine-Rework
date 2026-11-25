package funkin.play.modchartSystem;

#if sys
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
#end
import funkin.modding.ModManager;
import funkin.modding.PolymodHandler;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventType;
import funkin.play.PlayState;
import funkin.Conductor;
#if LUA_ALLOWED
import funkin.modding.psych.scripting.FunkinLua;
#end
#if HSCRIPT_ALLOWED
import funkin.modding.psych.scripting.HScript as PsychHScript;
#end

using StringTools;

@:nullSafety
class PsychScriptRuntime
{
  #if sys
  #if LUA_ALLOWED
  final luaScripts:Array<FunkinLua> = [];
  #else
  final luaScripts:Array<HazardModLuaTest> = [];
  #end
  #if HSCRIPT_ALLOWED
  final hscriptScripts:Array<PsychHScriptInstance> = [];
  #end
  #end
  public function new(state:PlayState)
  {
    #if sys
    for (scriptPath in getScriptPaths(state))
    {
      loadScript(scriptPath);
    }
    #end
  }

  public function call(functionName:String, ?args:Array<Dynamic>):Void
  {
    #if sys
    final callbackArgs:Array<Dynamic> = args ?? [];

    for (script in luaScripts.copy())
    {
      #if LUA_ALLOWED
      script.set('curBeat', Conductor.instance.currentBeat);
      script.set('curStep', Conductor.instance.currentStep);
      script.set('songPosition', Conductor.instance.songPosition);
      #else
      script.setGlobal('curBeat', Conductor.instance.currentBeat);
      script.setGlobal('curStep', Conductor.instance.currentStep);
      script.setGlobal('songPosition', Conductor.instance.songPosition);
      #end
      script.call(functionName, callbackArgs);
      #if LUA_ALLOWED
      if (script.closed) luaScripts.remove(script);
      #end
    }

    #if HSCRIPT_ALLOWED
    for (script in hscriptScripts.copy())
    {
      script.setGlobal('curBeat', Conductor.instance.currentBeat);
      script.setGlobal('curStep', Conductor.instance.currentStep);
      script.setGlobal('songPosition', Conductor.instance.songPosition);
      script.call(functionName, callbackArgs);
    }
    #end
    #end
  }

  public function dispatchEvent(event:ScriptEvent):Void
  {
    if (event == null) return;

    switch (event.type)
    {
      case ScriptEventType.UPDATE:
        call('onUpdate', [Reflect.field(event, 'elapsed')]);
      case ScriptEventType.SONG_STEP_HIT:
        call('onStepHit', [Reflect.field(event, 'step')]);
      case ScriptEventType.SONG_BEAT_HIT:
        call('onBeatHit', [Reflect.field(event, 'beat')]);
      case ScriptEventType.SONG_START:
        call('onSongStart');
      case ScriptEventType.SONG_END:
        call('onSongEnd');
      case ScriptEventType.SONG_RETRY:
        call('onSongRetry');
      case ScriptEventType.PAUSE:
        call('onPause');
      case ScriptEventType.RESUME:
        call('onResume');
      case ScriptEventType.COUNTDOWN_START:
        call('onCountdownStart');
      case ScriptEventType.COUNTDOWN_STEP:
        call('onCountdownTick', [countdownCounter(Reflect.field(event, 'step'))]);
      case ScriptEventType.COUNTDOWN_END:
        call('onCountdownEnd');
      case ScriptEventType.SONG_LOADED:
        call('onSongLoaded');
      case ScriptEventType.SONG_EVENT:
        callSongEvent(event);
      case ScriptEventType.NOTE_HIT:
        callNoteEvent('goodNoteHit', event);
      case ScriptEventType.NOTE_MISS:
        callNoteEvent('noteMiss', event);
      case ScriptEventType.NOTE_HOLD_HIT:
        callNoteEvent('goodNoteHit', event);
      case ScriptEventType.NOTE_HOLD_DROP:
        callNoteEvent('noteMiss', event);
      case ScriptEventType.NOTE_GHOST_MISS:
        call('noteMissPress', [Reflect.field(event, 'dir')]);
      case ScriptEventType.GAME_OVER:
        call('onGameOver');
      default:
    }
  }

  public function destroy():Void
  {
    #if sys
    call('onDestroy');
    for (script in luaScripts)
    {
      script.stop();
    }
    luaScripts.resize(0);
    #if HSCRIPT_ALLOWED
    for (script in hscriptScripts)
    {
      script.destroy();
    }
    hscriptScripts.resize(0);
    #end
    #end
  }

  public function addScript(path:String):Bool
  {
    #if sys
    if (!FileSystem.exists(path) || FileSystem.isDirectory(path) || hasScript(path)) return false;
    loadScript(path);
    return hasScript(path);
    #else
    return false;
    #end
  }

  public function removeScript(path:String):Bool
  {
    #if sys
    var removed = false;
    for (script in luaScripts.copy())
    {
      if (script.scriptName == path)
      {
        script.call('onDestroy', []);
        script.stop();
        luaScripts.remove(script);
        removed = true;
      }
    }

    #if HSCRIPT_ALLOWED
    for (script in hscriptScripts.copy())
    {
      if (script.path == path)
      {
        script.call('onDestroy', []);
        script.destroy();
        hscriptScripts.remove(script);
        removed = true;
      }
    }
    #end
    return removed;
    #else
    return false;
    #end
  }

  public function hasScript(path:String):Bool
  {
    #if sys
    for (script in luaScripts)
    {
      if (script.scriptName == path) return true;
    }
    #if HSCRIPT_ALLOWED
    for (script in hscriptScripts)
    {
      if (script.path == path) return true;
    }
    #end
    #end
    return false;
  }

  public function callHScript(functionName:String, ?args:Array<Dynamic>):Void
  {
    #if (sys && HSCRIPT_ALLOWED)
    final callbackArgs:Array<Dynamic> = args ?? [];
    for (script in hscriptScripts.copy())
    {
      script.call(functionName, callbackArgs);
    }
    #end
  }

  public function setHScript(variable:String, value:Dynamic, ?exclusions:Array<String>):Void
  {
    #if (sys && HSCRIPT_ALLOWED)
    final excluded = exclusions ?? [];
    for (script in hscriptScripts)
    {
      if (!excluded.contains(script.path)) script.setGlobal(variable, value);
    }
    #end
  }

  function callSongEvent(event:ScriptEvent):Void
  {
    final eventData:Dynamic = Reflect.field(event, 'eventData');
    if (eventData == null) return;

    final value:Dynamic = Reflect.field(eventData, 'value');
    final eventKind:Null<String> = cast Reflect.field(eventData, 'eventKind');
    final eventName:Null<String> = eventKind == 'PsychEvent' ? cast Reflect.field(value, 'name') : eventKind;
    final value1:Dynamic = value != null ? Reflect.field(value, 'value1') : null;
    final value2:Dynamic = value != null ? Reflect.field(value, 'value2') : null;

    call('onEvent', [eventName ?? '', value1 ?? '', value2 ?? '']);
  }

  function callNoteEvent(functionName:String, event:ScriptEvent):Void
  {
    var note:Dynamic = Reflect.field(event, 'note');
    var isSustain = false;
    if (note == null)
    {
      note = Reflect.field(event, 'holdNote');
      isSustain = note != null;
    }
    if (note == null) return;

    final noteData:Dynamic = Reflect.field(note, 'noteData');
    final noteIndex = findNoteIndex(note, noteData);
    final noteDataDirection:Dynamic = noteData != null ? Reflect.field(noteData, 'data') : null;
    final rawDirection:Dynamic = noteDataDirection ?? Reflect.field(note, 'direction') ?? Reflect.field(note, 'noteDirection');
    final direction = intValue(rawDirection) % 4;
    final noteType:Dynamic = Reflect.field(note, 'kind') ?? (noteData != null ? Reflect.field(noteData, 'kind') : null);
    final sustain:Dynamic = isSustain || Reflect.field(note, 'isHoldNote') == true;
    call(functionName, [noteIndex, direction, noteType ?? '', sustain]);
  }

  function findNoteIndex(note:Dynamic, noteData:Dynamic):Int
  {
    final strumLines:Dynamic = PlayState.instance != null ? Reflect.field(PlayState.instance, 'allStrumLines') : null;
    if (!Std.isOfType(strumLines, Array)) return -1;

    final lines:Array<Dynamic> = cast strumLines;
    for (strumLine in lines)
    {
      final noteGroup:Dynamic = Reflect.field(strumLine, 'notes');
      final members:Dynamic = noteGroup != null ? Reflect.field(noteGroup, 'members') : null;
      if (Std.isOfType(members, Array))
      {
        final noteMembers:Array<Dynamic> = cast members;
        final index = noteMembers.indexOf(note);
        if (index >= 0) return index;
      }

      final chartNotes:Dynamic = Reflect.field(strumLine, 'noteData');
      if (noteData != null && Std.isOfType(chartNotes, Array))
      {
        final chartNoteData:Array<Dynamic> = cast chartNotes;
        final index = chartNoteData.indexOf(noteData);
        if (index >= 0) return index;
      }
    }
    return -1;
  }

  function countdownCounter(step:Dynamic):Int
  {
    return switch (Std.string(step).toUpperCase())
    {
      case 'THREE':
        0;
      case 'TWO':
        1;
      case 'ONE':
        2;
      case 'GO':
        3;
      default:
        -1;
    }
  }

  function intValue(value:Dynamic):Int
  {
    if (value == null) return 0;
    final parsed = Std.parseInt(Std.string(value));
    return parsed ?? 0;
  }

  #if sys
  function loadScript(path:String):Void
  {
    final extension = Path.extension(path).toLowerCase();
    if (extension == 'lua')
    {
      #if LUA_ALLOWED
      final script = new FunkinLua(path);
      if (!script.closed && script.lua != null) luaScripts.push(script);
      #else
      final script = new HazardModLuaTest(path, Path.directory(path), Path.withoutDirectory(path));
      luaScripts.push(script);
      #end
      return;
    }

    #if HSCRIPT_ALLOWED
    try
    {
      final script = new PsychHScript(null, path);
      final instance = new PsychHScriptInstance(path, script);
      hscriptScripts.push(instance);
      instance.call('onCreate', []);
    }
    catch (e:Dynamic)
    {
      trace('Failed to load Psych HScript "$path": ${Std.string(e)}');
    }
    #end
  }

  function getScriptPaths(state:PlayState):Array<String>
  {
    final result:Array<String> = [];
    final songId = state.currentSong?.id.toLowerCase() ?? '';
    final stageId = state.currentChart?.stage.toLowerCase() ?? '';
    final characterIds = [
      state.currentChart?.characters?.player,
      state.currentChart?.characters?.opponent,
      state.currentChart?.characters?.girlfriend
    ].filter((id) -> id != null && id.trim() != '').map((id) -> id.toLowerCase());

    for (modId in ModManager.getEnabledPsychModDirectories())
    {
      final modRoot = Path.join([PolymodHandler.MOD_FOLDER, modId]);
      final pack = ModManager.getPack(modId);
      final runsGlobally:Dynamic = pack != null ? Reflect.field(pack, 'runsGlobally') : null;

      if (runsGlobally != false) appendScripts(result, Path.join([modRoot, 'scripts']), false);

      if (songId != '')
      {
        appendScripts(result, Path.join([modRoot, 'data', songId]));
        appendScripts(result, Path.join([modRoot, 'scripts', 'songs', songId]));
      }

      if (stageId != '')
      {
        appendNamedScripts(result, Path.join([modRoot, 'stages']), stageId);
        appendNamedScripts(result, Path.join([modRoot, 'scripts', 'stages']), stageId);
      }

      for (characterId in characterIds)
      {
        appendNamedScripts(result, Path.join([modRoot, 'characters']), characterId);
        appendNamedScripts(result, Path.join([modRoot, 'scripts', 'characters']), characterId);
      }
    }

    return result;
  }

  function appendNamedScripts(result:Array<String>, directory:String, name:String):Void
  {
    for (extension in ['lua', 'hx', 'hscript'])
    {
      final path = Path.join([directory, '$name.$extension']);
      if (FileSystem.exists(path) && !FileSystem.isDirectory(path) && !result.contains(path)) result.push(path);
    }
  }

  function appendScripts(result:Array<String>, directory:String, recursive:Bool = true):Void
  {
    if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;

    final entries = FileSystem.readDirectory(directory);
    entries.sort(Reflect.compare);

    for (entry in entries)
    {
      final path = Path.join([directory, entry]);
      if (FileSystem.isDirectory(path))
      {
        if (recursive) appendScripts(result, path, recursive);
        continue;
      }

      final extension = Path.extension(path).toLowerCase();
      if (['lua', 'hx', 'hscript'].contains(extension) && !result.contains(path)) result.push(path);
    }
  }
  #end
}

#if (sys && HSCRIPT_ALLOWED)
private class PsychHScriptInstance
{
  public final path:String;

  final script:PsychHScript;

  public function new(path:String, script:PsychHScript)
  {
    this.path = path;
    this.script = script;
  }

  public function call(functionName:String, args:Array<Dynamic>):Void
  {
    try
    {
      script.call(functionName, args);
    }
    catch (e:Dynamic)
    {
      trace('Psych HScript callback "$functionName" failed in "$path": ${Std.string(e)}');
    }
  }

  public function setGlobal(variable:String, value:Dynamic):Void
  {
    script.set(variable, value);
  }

  public function destroy():Void
  {
    script.destroy();
  }
}
#end
