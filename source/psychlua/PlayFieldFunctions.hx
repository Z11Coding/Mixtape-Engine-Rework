package psychlua;

import backend.modchartSystem.ModConstants;
import backend.modchartSystem.ModHandler;
import backend.modchartSystem.NoteData;
import backend.modchartSystem.modifiers.BaseModifier;
import objects.funkin.data.SongNoteData;
import objects.funkin.graphics.ZSprite;
import objects.notes.StrumNote;
import objects.notes.Strumline;
import openfl.display.BlendMode;
import openfl.display.TriangleCulling;

using StringTools;

class PlayFieldFunctions
{
	// Any strumlines added to here will be ignored by the any uses of "all" when picking targets. Useful if you know you are never going to use opponentStrums for example.
  static var allTargetExlusions:Array<Strumline> = [];

	public static function implement(funk:FunkinLua)
	{
		//TODO: use this when the modchart system actually gets added
		var lua = funk.lua;

    allTargetExlusions = [];

		funk.set('curBpm', MegaManager.conductor.currentBpm);
    funk.set('startingBPM', MegaManager.conductor.startBpm);
    funk.set('songPos', MegaManager.conductor.musicPosition);
    funk.set('beatPos', MegaManager.conductor.currentBeatTime);

    funk.set('measureLength', MegaManager.conductor.measureLengthMs);
    funk.set('beatLength', MegaManager.conductor.beatLengthMs);
    funk.set('stepLength', MegaManager.conductor.stepLengthMs);

    funk.set('stepsPerBeat', Constants.STEPS_PER_BEAT);

    funk.set('strumSize', ModConstants.strumSize);

    funk.set('modchartVersion', ModConstants.MODCHART_VERSION);
    funk.set('witfVersion', ModConstants.MODCHART_VERSION);

    funk.set('sw', FlxG.width);
    funk.set('sh', FlxG.height);
    funk.set('downScroll', ClientPrefs.data.downScroll);
    funk.set('upscroll', !ClientPrefs.data.downScroll);
    funk.set('upScroll', !ClientPrefs.data.downScroll);

    funk.set('invertStrumlineTarget', ModConstants.invertStrumlineTarget); // For swap chart mod

    Lua_helper.add_callback(lua, "getTypeLengthAtMS", MegaManager.conductor.getTypeLengthAtMs);
		Lua_helper.add_callback(lua, "getBeatTimeInMs", MegaManager.conductor.getCumulativeBeats);
    Lua_helper.add_callback(lua, "getStepTimeInMs", MegaManager.conductor.getCumulativeSteps);
    Lua_helper.add_callback(lua, "getTimeInSteps", MegaManager.conductor.getCumulativeMeasures);


    Lua_helper.add_callback(lua, "targetExclude", function(who:String):Void
    {
      var strummy:Null<Strumline> = ModConstants.grabStrumModTarget(who).strum;
      if (strummy != null) allTargetExlusions.push(strummy);
    });

    Lua_helper.add_callback(lua, "notesBehindHUD", function(newVal:Bool)
    {
      if (MegaManager.playfield != null)
      {
        MegaManager.playfield.notesAboveHUD = !newVal;
      }
    });

    // v0.8.1a -> New function that allows you to get the beats of notes between two points in a song, similar to using GetNoteData() for NotITG mirin
    // v[1] == the beats that the charted notes are on
    // v[2] == the column that the charted notes are on, starting from 0
    // v[3] == the hold length (0 means no hold) in ms
    // v[4] == the type of note (such as "default", "hurt", "invisible", "dodge",etc)

    // TODO:
    // FUNCS, FUNC_TWEEN, AND PERFRAME
    // OTHER LUA EVENT STUFF LOL

    Lua_helper.add_callback(lua, "setasleep", function(time:Float, playerTarget:String, newSleepState:Bool = false)
    {
      if (playerTarget == "bf" || playerTarget == "boyfriend" || playerTarget == "0" || playerTarget == "1")
      {
        PlayState.instance.addTextToDebug("Player strumline cannot be set to sleep!", FlxColor.ORANGE);
        return;
      }

      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (customStrummer in MegaManager.playfield.allStrumLines)
        {
          // DO NOT ASLEEP BF!
          if (customStrummer != MegaManager.playfield.playerStrums)
          {
            MegaManager.playfield.modchartEventHandler.funcModEvent(customStrummer.mods, time, function()
            {
              customStrummer.asleep = newSleepState;
            });
          }
        }
      }
      else
      {
        var modsTarget = ModConstants.grabStrumModTarget(playerTarget);
        if (modsTarget.strum != MegaManager.playfield.playerStrums)
        {
          MegaManager.playfield.modchartEventHandler.funcModEvent(modsTarget, time, function()
          {
            modsTarget.strum.asleep = newSleepState;
          });
        }
      }
    });

    Lua_helper.add_callback(lua, "setStrumControl", function(playerTarget:String, isPlayerControlled:Bool, time:Float)
    {
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (customStrummer in MegaManager.playfield.allStrumLines)
        {
          // DO NOT ASLEEP BF!
          if (!(customStrummer == MegaManager.playfield.playerStrums || customStrummer == MegaManager.playfield.opponentStrums))
          {
            MegaManager.playfield.modchartEventHandler.funcModEvent(customStrummer.mods, time, function()
            {
              customStrummer.isPlayerControlled = isPlayerControlled;
            });
          }
        }
      }
      else
      {
        var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

        if (modsTarget.strum == MegaManager.playfield.opponentStrums || modsTarget.strum == MegaManager.playfield.playerStrums)
        {
          MegaManager.scriptManager.addTextToDebug("Changing player control only works for custom strumlines!", FlxColor.ORANGE);
        }
        else
        {
          MegaManager.playfield.modchartEventHandler.funcModEvent(modsTarget, time, function()
          {
            modsTarget.strum.isPlayerControlled = isPlayerControlled;
          });
        }
      }
    });

    // LMAO
    Lua_helper.add_callback(lua, "easeFlip", function(ease1:String):String
    {
      return 'flip(${ease1})';
    });
    Lua_helper.add_callback(lua, "easeBlend", function(ease1:String, ease2:String):String
    {
      return 'blend(${ease1},${ease2})';
    });
    Lua_helper.add_callback(lua, "easeMerge", function(ease1:String, ease2:String):String
    {
      return 'merge(${ease1},${ease2})';
    });
    Lua_helper.add_callback(lua, "easeLerp", function(ease1:String, ease2:String):String
    {
      return 'lerp(${ease1},${ease2})';
    });

    Lua_helper.add_callback(lua, "flip", function(ease1:String):String
    {
      return 'flip(${ease1})';
    });
    Lua_helper.add_callback(lua, "blend", function(ease1:String, ease2:String):String
    {
      return 'blend(${ease1},${ease2})';
    });
    Lua_helper.add_callback(lua, "merge", function(ease1:String, ease2:String):String
    {
      return 'merge(${ease1},${ease2})';
    });
    Lua_helper.add_callback(lua, "lerp", function(ease1:String, ease2:String):String
    {
      return 'lerp(${ease1},${ease2})';
    });

    Lua_helper.add_callback(lua, "tween", tweenFunc_parser);
    Lua_helper.add_callback(lua, "ease", tweenFunc_parser);
    Lua_helper.add_callback(lua, "value", valueFunc);
    Lua_helper.add_callback(lua, "setdefault", setDefaultFunc_parser);
    Lua_helper.add_callback(lua, "set", setFunc_parser);
    Lua_helper.add_callback(lua, "add", addFunc_parser);

    Lua_helper.add_callback(lua, "tweenS", tweenStepFunc_parser);
    Lua_helper.add_callback(lua, "easeS", tweenStepFunc_parser);
    Lua_helper.add_callback(lua, "addS", addStepFunc_parser);

    Lua_helper.add_callback(lua, "setdefaults", function(data:String)
    {
      var input:String = StringTools.replace(data, "\n", "");
      input = StringTools.replace(input, " ", "");
      var a:Array<String> = input.split(',');

      var modValues:Array<Float> = [];
      var modNames:Array<String> = [];
      var targets:Array<String> = [];

      var inArray:Bool = false;
      var stage:Int = 0;
      var usingAltFormat:Bool = false;

      for (i in 0...a.length)
      {
        var str:String = a[i];

        if (StringTools.startsWith(str, "[")) inArray = true;
        if (StringTools.endsWith(str, "]")) inArray = false;
        if (!inArray) stage++;
      }
      if (stage - 1 < 2)
      {
        usingAltFormat = true; // player target is never used, meaning modNames is where the targets are as the user wants to use mirin styled mod table thingy
        trace("USING ALT FORMAT");
      }
      stage = 0;
      inArray = false;
      var modAlternator:Bool = false; // ping pongs between true and false during alt format
      // trace(a);
      for (i in 0...a.length)
      {
        var str:String = a[i];

        // trace(str);
        if (StringTools.startsWith(str, "[")) inArray = true;
        str = StringTools.replace(str, "[", "");
        if (StringTools.endsWith(str, "]")) inArray = false;
        str = StringTools.replace(str, "]", "");
        // trace(inArray);
        switch (stage)
        {
          case 0:
            if (usingAltFormat && modAlternator) modNames.push(str);
            else
              modValues.push(Std.parseFloat(str));
            modAlternator = !modAlternator;
          case 1:
            if (usingAltFormat) targets.push(str);
            else
              modNames.push(str);
          case 2:
            if (!usingAltFormat) targets.push(str);
        }
        if (!inArray) stage++;
      }

      multiFunc([], [], [], modValues, modNames, targets, "default");
    });
    Lua_helper.add_callback(lua, "sets", function(data:String)
    {
      var input:String = StringTools.replace(data, "\n", "");
      input = StringTools.replace(input, " ", "");
      var a:Array<String> = input.split(',');

      var startBeats:Array<Float> = [];
      var modValues:Array<Float> = [];
      var modNames:Array<String> = [];
      var targets:Array<String> = [];

      var inArray:Bool = false;
      var stage:Int = 0;
      var usingAltFormat:Bool = false;

      for (i in 0...a.length)
      {
        var str:String = a[i];

        if (StringTools.startsWith(str, "[")) inArray = true;
        if (StringTools.endsWith(str, "]")) inArray = false;
        if (!inArray) stage++;
      }
      if (stage - 1 < 3)
      {
        usingAltFormat = true; // player target is never used, meaning modNames is where the targets are as the user wants to use mirin styled mod table thingy
        trace("USING ALT FORMAT");
      }
      stage = 0;
      inArray = false;
      var modAlternator:Bool = false; // ping pongs between true and false during alt format
      // trace(a);
      for (i in 0...a.length)
      {
        var str:String = a[i];

        // trace(str);
        if (StringTools.startsWith(str, "[")) inArray = true;
        str = StringTools.replace(str, "[", "");
        if (StringTools.endsWith(str, "]")) inArray = false;
        str = StringTools.replace(str, "]", "");
        // trace(inArray);
        switch (stage)
        {
          case 0:
            startBeats.push(Std.parseFloat(str));
          case 1:
            if (usingAltFormat && modAlternator) modNames.push(str);
            else
              modValues.push(Std.parseFloat(str));
            modAlternator = !modAlternator;
          case 2:
            if (usingAltFormat) targets.push(str);
            else
              modNames.push(str);
          case 3:
            if (!usingAltFormat) targets.push(str);
        }
        if (!inArray) stage++;
      }

      multiFunc(startBeats, [], [], modValues, modNames, targets, "set");
    });
    Lua_helper.add_callback(lua, "setsStep", function(data:String)
    {
      var input:String = StringTools.replace(data, "\n", "");
      input = StringTools.replace(input, " ", "");
      var a:Array<String> = input.split(',');

      var startSteps:Array<Float> = [];
      var modValues:Array<Float> = [];
      var modNames:Array<String> = [];
      var targets:Array<String> = [];

      var inArray:Bool = false;
      var stage:Int = 0;
      var usingAltFormat:Bool = false;

      for (i in 0...a.length)
      {
        var str:String = a[i];

        if (StringTools.startsWith(str, "[")) inArray = true;
        if (StringTools.endsWith(str, "]")) inArray = false;
        if (!inArray) stage++;
      }
      if (stage - 1 < 3)
      {
        usingAltFormat = true; // player target is never used, meaning modNames is where the targets are as the user wants to use mirin styled mod table thingy
        trace("USING ALT FORMAT");
      }
      stage = 0;
      inArray = false;
      var modAlternator:Bool = false; // ping pongs between true and false during alt format
      // trace(a);
      for (i in 0...a.length)
      {
        var str:String = a[i];

        // trace(str);
        if (StringTools.startsWith(str, "[")) inArray = true;
        str = StringTools.replace(str, "[", "");
        if (StringTools.endsWith(str, "]")) inArray = false;
        str = StringTools.replace(str, "]", "");
        // trace(inArray);
        switch (stage)
        {
          case 0:
            startSteps.push(Std.parseFloat(str));
          case 1:
            if (usingAltFormat && modAlternator) modNames.push(str);
            else
              modValues.push(Std.parseFloat(str));
            modAlternator = !modAlternator;
          case 2:
            if (usingAltFormat) targets.push(str);
            else
              modNames.push(str);
          case 3:
            if (!usingAltFormat) targets.push(str);
        }
        if (!inArray) stage++;
      }

      multiFuncS(startSteps, [], [], modValues, modNames, targets, "set");
    });
    Lua_helper.add_callback(lua, "adds", function(data:String)
    {
      multiFuncParse(data, "add");
    });
    Lua_helper.add_callback(lua, "eases", function(data:String)
    {
      multiFuncParse(data, "tween");
    });
    Lua_helper.add_callback(lua, "tweens", function(data:String)
    {
      multiFuncParse(data, "tween");
    });
    Lua_helper.add_callback(lua, "values", function(data:String)
    {
      trace("!!! TEST !!!");

      // remove all \n and spaces
      var input:String = StringTools.replace(data, "\n", "");
      input = StringTools.replace(input, " ", "");
      // "[4,6,8.5,9],[0.75,1,1.5],[sineInOut,bounce,sineInOut],[100,drunk,200,tipsy],[bf,3]"
      // "4, 1, bounce, [100, -100], [x, y], bf"
      var a:Array<String> = input.split(',');

      // [[4], [6], [8.5], [9]] ....
      // [4], [1], [bounce], [[100], [-100]], [[x], [y]], [bf]
      var startBeats:Array<Float> = [];
      var lengthBeats:Array<Float> = [];
      var eases:Array<String> = [];
      var modStartValues:Array<Float> = [];
      var modEndValues:Array<Float> = [];
      var modNames:Array<String> = [];
      var targets:Array<String> = [];

      var inArray:Bool = false;
      var stage:Int = 0;
      var usingAltFormat:Bool = false;

      for (i in 0...a.length)
      {
        var str:String = a[i];

        if (StringTools.startsWith(str, "[")) inArray = true;
        if (StringTools.endsWith(str, "]")) inArray = false;
        if (!inArray) stage++;
      }
      trace("stage: " + stage);
      if (stage - 1 <= 4)
      {
        usingAltFormat = true; // player target is never used, meaning modNames is where the targets are as the user wants to use mirin styled mod table thingy
        trace("USING ALT FORMAT");
      }
      stage = 0;
      inArray = false;
      var modAlternator:Int = 0; // ping pongs between true and false during alt format
      // trace(a);
      for (i in 0...a.length)
      {
        var str:String = a[i];

        // trace(str);
        if (StringTools.startsWith(str, "[")) inArray = true;
        str = StringTools.replace(str, "[", "");
        if (StringTools.endsWith(str, "]")) inArray = false;
        str = StringTools.replace(str, "]", "");
        // trace(inArray);
        switch (stage)
        {
          case 0:
            startBeats.push(Std.parseFloat(str));
          case 1:
            lengthBeats.push(Std.parseFloat(str));
          case 2:
            eases.push(str);
          case 3:
            if (usingAltFormat)
            {
              switch (modAlternator)
              {
                case 0:
                  modStartValues.push(Std.parseFloat(str));
                case 1:
                  modEndValues.push(Std.parseFloat(str));
                case 2:
                  modNames.push(str);
              }
              modAlternator++;
              if (modAlternator > 2) modAlternator = 0;
            }
            else
            {
              modStartValues.push(Std.parseFloat(str));
            }
          case 4:
            if (usingAltFormat)
            {
              targets.push(str);
            }
            else
            {
              modEndValues.push(Std.parseFloat(str));
            }
          case 5:
            if (!usingAltFormat) modNames.push(str);
          case 6:
            if (!usingAltFormat) targets.push(str);
        }
        if (!inArray) stage++;
      }
      trace(" ---------- ");
      trace(startBeats);
      trace(lengthBeats);
      trace(eases);
      trace(modStartValues);
      trace(modEndValues);
      trace(modNames);
      trace(targets);
      trace("!!! FIN !!!");

      if (targets.length < 1)
      { // if empty, default to targetting all
        targets.push("all");
      }

      for (i in 0...startBeats.length)
      {
        var startBeat:Float = startBeats[i];
        var length:Float = 1;

        if (i < lengthBeats.length)
        {
          length = lengthBeats[i];
        }
        else
        {
          length = lengthBeats[lengthBeats.length - 1];
        }
        var e:String = "linear";

        if (i < eases.length)
        {
          e = eases[i];
        }
        else
        {
          e = eases[eases.length - 1];
        }
        for (m in 0...modNames.length)
        {
          var mn:String = modNames[m];
          var msv:Float = 1;
          if (m < modStartValues.length)
          {
            msv = modStartValues[m];
          }
          else
          {
            msv = modStartValues[modStartValues.length - 1];
          }
          var mev:Float = 0;
          if (m < modEndValues.length)
          {
            mev = modEndValues[m];
          }
          else
          {
            mev = modEndValues[modEndValues.length - 1];
          }
          for (k in 0...targets.length)
          {
            var t:String = targets[k];
            valueFunc(startBeat, length, e, msv, mev, mn, t);
          }
        }
      }
    });

    Lua_helper.add_callback(lua, "valuesStep", function(data:String)
    {
      trace("!!! TEST !!!");

      // remove all \n and spaces
      var input:String = StringTools.replace(data, "\n", "");
      input = StringTools.replace(input, " ", "");
      // "[4,6,8.5,9],[0.75,1,1.5],[sineInOut,bounce,sineInOut],[100,drunk,200,tipsy],[bf,3]"
      // "4, 1, bounce, [100, -100], [x, y], bf"
      var a:Array<String> = input.split(',');

      // [[4], [6], [8.5], [9]] ....
      // [4], [1], [bounce], [[100], [-100]], [[x], [y]], [bf]
      var startSteps:Array<Float> = [];
      var lengthSteps:Array<Float> = [];
      var eases:Array<String> = [];
      var modStartValues:Array<Float> = [];
      var modEndValues:Array<Float> = [];
      var modNames:Array<String> = [];
      var targets:Array<String> = [];

      var inArray:Bool = false;
      var stage:Int = 0;
      var usingAltFormat:Bool = false;

      for (i in 0...a.length)
      {
        var str:String = a[i];

        if (StringTools.startsWith(str, "[")) inArray = true;
        if (StringTools.endsWith(str, "]")) inArray = false;
        if (!inArray) stage++;
      }
      trace("stage: " + stage);
      if (stage - 1 <= 4)
      {
        usingAltFormat = true; // player target is never used, meaning modNames is where the targets are as the user wants to use mirin styled mod table thingy
        trace("USING ALT FORMAT");
      }
      stage = 0;
      inArray = false;
      var modAlternator:Int = 0; // ping pongs between true and false during alt format
      // trace(a);
      for (i in 0...a.length)
      {
        var str:String = a[i];

        // trace(str);
        if (StringTools.startsWith(str, "[")) inArray = true;
        str = StringTools.replace(str, "[", "");
        if (StringTools.endsWith(str, "]")) inArray = false;
        str = StringTools.replace(str, "]", "");
        // trace(inArray);
        switch (stage)
        {
          case 0:
            startSteps.push(Std.parseFloat(str));
          case 1:
            lengthSteps.push(Std.parseFloat(str));
          case 2:
            eases.push(str);
          case 3:
            if (usingAltFormat)
            {
              switch (modAlternator)
              {
                case 0:
                  modStartValues.push(Std.parseFloat(str));
                case 1:
                  modEndValues.push(Std.parseFloat(str));
                case 2:
                  modNames.push(str);
              }
              modAlternator++;
              if (modAlternator > 2) modAlternator = 0;
            }
            else
            {
              modStartValues.push(Std.parseFloat(str));
            }
          case 4:
            if (usingAltFormat)
            {
              targets.push(str);
            }
            else
            {
              modEndValues.push(Std.parseFloat(str));
            }
          case 5:
            if (!usingAltFormat) modNames.push(str);
          case 6:
            if (!usingAltFormat) targets.push(str);
        }
        if (!inArray) stage++;
      }
      trace(" ---------- ");
      trace(startSteps);
      trace(lengthSteps);
      trace(eases);
      trace(modStartValues);
      trace(modEndValues);
      trace(modNames);
      trace(targets);
      trace("!!! FIN !!!");

      if (targets.length < 1)
      { // if empty, default to targetting all
        targets.push("all");
      }

      for (i in 0...startSteps.length)
      {
        var startStep:Float = startSteps[i];
        var length:Float = 1;

        if (i < lengthSteps.length)
        {
          length = lengthSteps[i];
        }
        else
        {
          length = lengthSteps[lengthSteps.length - 1];
        }
        var e:String = "linear";

        if (i < eases.length)
        {
          e = eases[i];
        }
        else
        {
          e = eases[eases.length - 1];
        }
        for (m in 0...modNames.length)
        {
          var mn:String = modNames[m];
          var msv:Float = 1;
          if (m < modStartValues.length)
          {
            msv = modStartValues[m];
          }
          else
          {
            msv = modStartValues[modStartValues.length - 1];
          }
          var mev:Float = 0;
          if (m < modEndValues.length)
          {
            mev = modEndValues[m];
          }
          else
          {
            mev = modEndValues[modEndValues.length - 1];
          }
          for (k in 0...targets.length)
          {
            var t:String = targets[k];
            valueFunc(startStep, length, e, msv, mev, mn, t);
          }
        }
      }
    });

    Lua_helper.add_callback(lua, "reset", function(startBeat:Float, playerTarget:String = "all")
    {
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (strummer in MegaManager.playfield.allStrumLines)
        {
          if (!allTargetExlusions.contains(strummer)) MegaManager.playfield.modchartEventHandler.resetModEvent(strummer.mods, startBeat);
        }
      }
      else
      {
        var modsTarget = ModConstants.grabStrumModTarget(playerTarget);
        MegaManager.playfield.modchartEventHandler.resetModEvent(modsTarget, startBeat);
      }
    });

    Lua_helper.add_callback(lua, "resetS", function(startStep:Float, playerTarget:String = "all")
    {
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (strummer in MegaManager.playfield.allStrumLines)
        {
          if (!allTargetExlusions.contains(strummer)) MegaManager.playfield.modchartEventHandler.resetModEventS(strummer.mods, startStep);
        }
      }
      else
      {
        var modsTarget = ModConstants.grabStrumModTarget(playerTarget);
        MegaManager.playfield.modchartEventHandler.resetModEventS(modsTarget, startStep);
      }
    });

    Lua_helper.add_callback(lua, "resort", function(startStep:Float, playerTarget:String = "all")
    {
      MegaManager.playfield.modchartEventHandler.modChartHasResort = true;
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (strummer in MegaManager.playfield.allStrumLines)
        {
          if (!allTargetExlusions.contains(strummer)) MegaManager.playfield.modchartEventHandler.resortModEvent(strummer.mods, startBeat);
        }
      }
      else
      {
        var modsTarget = ModConstants.grabStrumModTarget(playerTarget);
        MegaManager.playfield.modchartEventHandler.resortModEvent(modsTarget, startBeat);
      }
    });

    Lua_helper.add_callback(lua, "resortS", function(startStep:Float, playerTarget:String = "all")
    {
      MegaManager.playfield.modchartEventHandler.modChartHasResort = true;
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (strummer in MegaManager.playfield.allStrumLines)
        {
          if (!allTargetExlusions.contains(strummer)) MegaManager.playfield.modchartEventHandler.resortModEventS(strummer.mods, startStep);
        }
      }
      else
      {
        var modsTarget = ModConstants.grabStrumModTarget(playerTarget);
        MegaManager.playfield.modchartEventHandler.resortModEventS(modsTarget, startStep);
      }
    });

    Lua_helper.add_callback(lua, "percentageMode", function(newval:Bool = false)
    {
      trace("set percentage mode to: " + newval);
      MegaManager.playfield.modchartEventHandler.percentageMods = newval;
      FunkinLua.luaTrace("'percentageMode' is not available!", FlxColor.RED);
    });

    /*Lua_helper.add_callback(lua, "hideNotifs", function(newval:Bool = false)
    {
      MegaManager.playfield.hideNotifs = newval;
      trace(MegaManager.playfield.hideNotifs ? "Will no longer display notifs..." : "Showing notifs!");
    });*/

    Lua_helper.add_callback(lua, "invertForDad", function(newval:Bool = false)
    {
      trace("set invert mode to: " + newval);
      MegaManager.playfield.modchartEventHandler.invertForOpponent = newval;
    });

    Lua_helper.add_callback(lua, "copyZoom", function(newval:Bool = false)
    {
      MegaManager.playfield.noteCamCopyHudZoom = newval;
    });

    Lua_helper.add_callback(lua, "centerPlayer", function(pointless:String = "")
    {
      var playerStrums:Strumline = MegaManager.playfield.playerStrums;
      if (playerStrums != null)
      {
        playerStrums.x = (FlxG.width / 2 - playerStrums.width / 2);
      }
    });
    Lua_helper.add_callback(lua, "hideOpponent", function(pointless:String = "")
    {
      trace("attempting to hide opponent");
      var strummer = MegaManager.playfield.playerStrums;
      if (strummer != null)
      {
        strummer.asleep = true;
        strummer.x = -999;
        strummer.visible = false;
        for (arrow in strummer.members)
        {
          arrow.visible = false;
        }
      }
    });

    Lua_helper.add_callback(lua, "centerStrum", function(playerTarget:String = "all")
    {
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (strummer in MegaManager.playfield.allStrumLines)
        {
          if (!allTargetExlusions.contains(strummer))
          {
            strummer.x = (FlxG.width / 2 - strummer.width / 2);
          }
        }
      }
      else
      {
        var strummer:FlxSprite = ModConstants.grabStrumModTarget(playerTarget).strum;
        if (strummer != null)
        {
          strummer.x = (FlxG.width / 2 - strummer.width / 2);
        }
      }
    });

    Lua_helper.add_callback(lua, "hideStrum", function(playerTarget:String = "opponent")
    {
      if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
      {
        for (strummer in MegaManager.playfield.allStrumLines)
        {
          if (!allTargetExlusions.contains(strummer))
          {
            strummer.asleep = true;
            strummer.x = -999;
            strummer.visible = false;
            for (arrow in strummer.members)
            {
              arrow.visible = false;
            }
          }
        }
      }
      else
      {
        var strummer:Strumline = ModConstants.grabStrumModTarget(playerTarget).strum;
        if (strummer != null)
        {
          strummer.asleep = true;
          strummer.x = -999;
          strummer.visible = false;
          for (arrow in strummer.members)
          {
            arrow.visible = false;
          }
        }
      }
    });

    Lua_helper.add_callback(lua, "centerOpponent", function(pointless:String = "")
    {
      var strummer:FlxSprite = MegaManager.playfield.opponentStrums;
      if (strummer != null)
      {
        strummer.x = (FlxG.width / 2 - strummer.width / 2);
      }
    });

    Lua_helper.add_callback(lua, "hidePlayer", function(pointless:String = "")
    {
      trace("attempting to hide player");
      var strummer:Strumline = MegaManager.playfield.playerStrums;
      if (strummer != null)
      {
        strummer.asleep = true;
        strummer.x = -999;
        strummer.visible = false;
        for (arrow in strummer.members)
        {
          arrow.visible = false;
        }
      }
    });

    // legacy function, just use the grain mod
    Lua_helper.add_callback(lua, "setGrain", function(newGrainValue:Float = 80, playerTarget:String = "all")
    {
      FunkinLua.luaTrace("'setGrain' is obsolete! Use the 'grain' modifier instead!", FlxColor.RED);
    });

    // legacy function, use createNewPlayer
    Lua_helper.add_callback(lua, "customStrumAmount", function(newval:Int = 0)
    {
      FunkinLua.luaTrace("'customStrumAmount' is obsolete! Use 'createNewPlayer()' instead!", true, FlxColor.RED);
    });

    Lua_helper.add_callback(lua, "createNewPlayer", function(playerControlled:Bool, ?noteStyle:String)
    {
      MegaManager.playfield.constructNewStrumLine(playerControlled);
    });

    Lua_helper.add_callback(lua, "aftSetup", function(startBeat:Null<Float> = null)
    {
      if (MegaManager.playfield.luaAFT_Capture != null)
      {
        FunkinLua.luaTrace("Only one Lua AFT sprite can exist.", FlxColor.ORANGE);
        return;
      }
      if (startBeat == null)
      {
        MegaManager.playfield.setUpLuaAft();
      }
      else
      {
        MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
        {
          MegaManager.playfield.setUpLuaAft();
        });
      }
    });

    /// Cuz why not lmao
    Lua_helper.add_callback(lua, "aftSetupS", function(startStep:Null<Float> = null)
    {
      if (MegaManager.playfield.luaAFT_Capture != null)
      {
        FunkinLua.luaTrace("Only one Lua AFT sprite can exist.", FlxColor.ORANGE);
        return;
      }
      if (startStep == null)
      {
        MegaManager.playfield.setUpLuaAft();
      }
      else
      {
        MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
        {
          MegaManager.playfield.setUpLuaAft();
        });
      }
    });

    Lua_helper.add_callback(lua, "aftCaptureAlpha", function(startBeat:Float, v:Float)
    {
      FunkinLua.luaTrace("aftTweenAlpha NOT SUPPORTED IN V0.8.0a", FlxColor.RED);
      /*
        if (MegaManager.playfield.luaAFT_Capture == null)
        {
          FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
          return;
        }
        MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function() {
          MegaManager.playfield.luaAFT_Capture.alpha = v;
          trace("oh hey, we alpha cap", v);
        });
       */
    });

    Lua_helper.add_callback(lua, "aftSpriteAlpha", function(startBeat:Float, v:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
      {
        MegaManager.playfield.luaAFT_sprite.alpha = v;
        trace("oh hey, we alpha spr", v);
      });
    });

    Lua_helper.add_callback(lua, "aftSpriteAlphaS", function(startStep:Float, v:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
      {
        MegaManager.playfield.luaAFT_sprite.alpha = v;
        trace("oh hey, we alpha spr", v);
      });
    });

    Lua_helper.add_callback(lua, "aftAlpha", function(startBeat:Float, v:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
      {
        // MegaManager.playfield.luaAFT_Capture.alpha = v;
        MegaManager.playfield.luaAFT_sprite.alpha = v;
        trace("oh hey, we alpha it", v);
      });
    });

    Lua_helper.add_callback(lua, "aftAlpha", function(startStep:Float, v:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
      {
        // MegaManager.playfield.luaAFT_Capture.alpha = v;
        MegaManager.playfield.luaAFT_sprite.alpha = v;
        trace("oh hey, we alpha it", v);
      });
    });

    Lua_helper.add_callback(lua, "aftRecursive", function(startBeat:Float, v:Bool)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
      {
        MegaManager.playfield.luaAFT_Capture.recursive = v;
      });
    });
    Lua_helper.add_callback(lua, "aftRecursiveS", function(startStep:Float, v:Bool)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
      {
        MegaManager.playfield.luaAFT_Capture.recursive = v;
      });
    });
    Lua_helper.add_callback(lua, "aftUpdateRate", function(startBeat:Float, v:Float, trueValue:Bool = false)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      if (trueValue)
      {
        MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
        {
          MegaManager.playfield.luaAFT_Capture.updateRate = v;
        });
      }
      else
      {
        MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
        {
          MegaManager.playfield.luaAFT_Capture.targetFps(v);
        });
      }
    });
    Lua_helper.add_callback(lua, "aftUpdateRateS", function(startStep:Float, v:Float, trueValue:Bool = false)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      if (trueValue)
      {
        MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
        {
          MegaManager.playfield.luaAFT_Capture.updateRate = v;
        });
      }
      else
      {
        MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
        {
          MegaManager.playfield.luaAFT_Capture.targetFps(v);
        });
      }
    });
    Lua_helper.add_callback(lua, "aftBlend", function(startBeat:Float, b:String)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
      {
        MegaManager.playfield.luaAFT_Capture.blendMode = b;
      });
    });
    Lua_helper.add_callback(lua, "aftBlendS", function(startStep:Float, b:String)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
      {
        MegaManager.playfield.luaAFT_Capture.blendMode = b;
      });
    });
    Lua_helper.add_callback(lua, "aftSize", function(startBeat:Float, s:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, function()
      {
        MegaManager.playfield.luaAFT_sprite.setGraphicSize(Std.int(MegaManager.playfield.luaAFT_Capture.w * s));
        trace("oh hey, we resized it");
      });
    });
    Lua_helper.add_callback(lua, "aftSizeS", function(startStep:Float, s:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcModEventS(ModConstants.grabStrumModTarget("bf"), startStep, function()
      {
        MegaManager.playfield.luaAFT_sprite.setGraphicSize(Std.int(MegaManager.playfield.luaAFT_Capture.w * s));
        trace("oh hey, we resized it");
      });
    });

    Lua_helper.add_callback(lua, "aftTweenAlpha", function(startBeat:Float, lengthInBeats:Float, easeToUse:String, modValue:Float)
    {
      FunkinLua.luaTrace("aftTweenAlpha NOT SUPPORTED IN V0.8.0a", FlxColor.RED);
      /*
        if (MegaManager.playfield.luaAFT_Capture == null)
        {
          FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
          return;
        }
        MegaManager.playfield.modchartEventHandler.funcTweenModEvent(ModConstants.grabStrumModTarget("bf"), startBeat, lengthInBeats,
          ModConstants.getEaseFromString(easeToUse), MegaManager.playfield.luaAFT_Capture.alpha, modValue, function(v) {
            // MegaManager.playfield.luaAFT_Capture.alpha = v;
            MegaManager.playfield.luaAFT_sprite.alpha = v;
            return v;
        }, "luaAFT_alpha");
       */
    });

    Lua_helper.add_callback(lua, "aftTweenSize", function(startBeat:Float, lengthInBeats:Float, easeToUse:String, modValue:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        // MegaManager.scriptManager.addTextToDebug("No lua aft sprite!");
        // trace("No lua aft!");
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcTweenModEvent(
        ModConstants.grabStrumModTarget("bf"),
        startBeat,
        lengthInBeats,
        ModConstants.getEaseFromString(easeToUse),
        1,
        modValue,
        function(v)
        {
          MegaManager.playfield.luaAFT_sprite.setGraphicSize(Std.int(MegaManager.playfield.luaAFT_Capture.w * v));
          return v;
        },
        "luaAFT_scale"
      );
    });
    Lua_helper.add_callback(lua, "aftTweenSizeS", function(startStep:Float, lengthInSteps:Float, easeToUse:String, modValue:Float)
    {
      if (MegaManager.playfield.luaAFT_Capture == null)
      {
        // MegaManager.scriptManager.addTextToDebug("No lua aft sprite!");
        // trace("No lua aft!");
        FunkinLua.luaTrace("Lua AFT sprite not created!", FlxColor.RED);
        return;
      }
      MegaManager.playfield.modchartEventHandler.funcTweenModEventS(
        ModConstants.grabStrumModTarget("bf"),
        startStep,
        lengthInSteps,
        ModConstants.getEaseFromString(easeToUse),
        1,
        modValue,
        function(v)
        {
          MegaManager.playfield.luaAFT_sprite.setGraphicSize(Std.int(MegaManager.playfield.luaAFT_Capture.w * v));
          return v;
        },
        "luaAFT_scale"
      );
    });

    // Compatibility Stuff
    Lua_helper.add_callback(lua, "newPlayField", function()
    {
      MegaManager.playfield.constructNewStrumLine(false); // default to not
    });

    Lua_helper.add_callback(lua, "initPlayfield", function(playerControlled:Bool)
		{
			MegaManager.playfield.constructNewStrumLine(playerControlled);
		});

    Lua_helper.add_callback(lua, "setPercent", function(modName:String, val:Float, player:Int = -1) {
      var pName:String = "all";
      switch (player) {
        case 0:
          pName = "opponent";
        case 1:
          pName = "player";
        case -1:
          pName = "all";
        default:
          pName = ("plr"+player);
      }
			setFunc_parser(MegaManager.conductor.currentBeat, (val/100), modName, pName);
    });

		Lua_helper.add_callback(lua, "addBlankMod", function(modName:String, defaultVal:Float = 0, player:Int = -1) {
      ModConstants.createNewCustomMod(modName, defaultVal);
		});

		Lua_helper.add_callback(lua, "setValue", function(modName:String, val:Float, player:Int = -1) {
			var pName:String = "all";
      switch (player) {
        case 0:
          pName = "opponent";
        case 1:
          pName = "player";
        case -1:
          pName = "all";
        default:
          pName = ("plr"+player);
      }
			setFunc_parser(MegaManager.conductor.currentBeat, val, modName, pName);
    });


    // TODO: Finish the compat
		/*Lua_helper.add_callback(lua, "getPercent", function(modName:String, player:Int)
      return MegaManager.playfield.modchartEventHandler.get(modName).percent;
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

		Lua_helper.add_callback(lua, "queueEaseL",
			function(step:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
				PlayState.instance.modManager.queueEaseL(step, length, modName, value, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseLB",
			function(beat:Float, length:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
				PlayState.instance.modManager.queueEaseLB(beat, length, modName, value, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueEaseB",
			function(beat:Float, endBeat:Float, modName:String, value:Float, style:Dynamic = 'linear', player = -1, ?startVal:Float)
				PlayState.instance.modManager.queueEaseB(beat, endBeat, modName, value, style, player, startVal)
		);

		Lua_helper.add_callback(lua, "queueSetB",
			function(beat:Float, modName:String, value:Float, player = -1)
				PlayState.instance.modManager.queueSetB(beat, modName, value, player)
		);

		Lua_helper.add_callback(lua, "queueFunc",
			function(step:Float, endStep:Float, callback:(CallbackEvent, Float) -> Void)
				PlayState.instance.modManager.queueFunc(step, endStep, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncL",
			function(step:Float, length:Float, callback:(CallbackEvent, Float) -> Void)
				PlayState.instance.modManager.queueFuncL(step, length, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncB",
			function(beat:Float, endBeat:Float, callback:(CallbackEvent, Float) -> Void)
				PlayState.instance.modManager.queueFuncB(beat, endBeat, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncLB",
			function(beat:Float, length:Float, callback:(CallbackEvent, Float) -> Void)
				PlayState.instance.modManager.queueFuncB(beat, length, callback)
		);

		Lua_helper.add_callback(lua, "queueFuncOnce",
			function(step:Float, callback:(CallbackEvent, Float) -> Void)
				PlayState.instance.modManager.queueFuncOnce(step, callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFunc",
			function(step:Float, endStep:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				PlayState.instance.modManager.queueEaseFunc(step, endStep, LuaUtils.getTweenEaseByString(style), callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFuncL",
			function(step:Float, length:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				PlayState.instance.modManager.queueEaseFuncL(step, length, LuaUtils.getTweenEaseByString(style), callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFuncB",
			function(beat:Float, endBeat:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				PlayState.instance.modManager.queueEaseFuncB(beat, endBeat, LuaUtils.getTweenEaseByString(style), callback)
		);

		Lua_helper.add_callback(lua, "queueEaseFuncLB",
			function(beat:Float, length:Float, style:String = 'linear', callback:(EaseEvent, Float, Float) -> Void)
				PlayState.instance.modManager.queueEaseFuncLB(beat, length, LuaUtils.getTweenEaseByString(style), callback)
		);*/
  }

  static function multiFuncParse(data:String, type:String):Void
  {
    // format: adds("[4, 6, 8.5, 9], [0.75, 1, 1.5], [sineInOut, bounce, sineInOut], [100, drunk, 200, tipsy], [bf, 3] ")
    // startBeat = [4, 6, 8.5, 9]. Loops through each one and adds it as an event
    // lengthInBeats = [0.75,1,1.5]. 4 will be 0.75, 6 will be 1. If startBeat iteration is larger then this array, default to last member (so 9 is 1.5)
    // easeToUse = ["sineInOut", "bounce"]. Same as above.
    // modValue = [100, "drunk", 100, "tipsy"] same as Mirin. Alternatively, it can have the same logic as above (as such, playerTarget will then still be used)
    // modName will become player target
    // playerTarget becomes unused.

    trace("!!! TEST !!!");

    // remove all \n and spaces
    var input:String = StringTools.replace(data, "\n", "");
    input = StringTools.replace(input, " ", "");
    // "[4,6,8.5,9],[0.75,1,1.5],[sineInOut,bounce,sineInOut],[100,drunk,200,tipsy],[bf,3]"
    // "4, 1, bounce, [100, -100], [x, y], bf"
    var a:Array<String> = input.split(',');

    // [[4], [6], [8.5], [9]] ....
    // [4], [1], [bounce], [[100], [-100]], [[x], [y]], [bf]
    var startBeats:Array<Float> = [];
    var lengthBeats:Array<Float> = [];
    var eases:Array<String> = [];
    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    var targets:Array<String> = [];

    var inArray:Bool = false;
    var stage:Int = 0;
    var usingAltFormat:Bool = false;

    for (i in 0...a.length)
    {
      var str:String = a[i];

      if (StringTools.startsWith(str, "[")) inArray = true;
      if (StringTools.endsWith(str, "]")) inArray = false;
      if (!inArray) stage++;
    }
    trace("stage: " + stage);
    if (stage - 1 < 5)
    {
      usingAltFormat = true; // player target is never used, meaning modNames is where the targets are as the user wants to use mirin styled mod table thingy
      trace("USING ALT FORMAT");
    }
    stage = 0;
    inArray = false;
    var modAlternator:Bool = false; // ping pongs between true and false during alt format
    // trace(a);
    for (i in 0...a.length)
    {
      var str:String = a[i];

      // trace(str);
      if (StringTools.startsWith(str, "[")) inArray = true;
      str = StringTools.replace(str, "[", "");
      if (StringTools.endsWith(str, "]")) inArray = false;
      str = StringTools.replace(str, "]", "");
      // trace(inArray);
      switch (stage)
      {
        case 0:
          startBeats.push(Std.parseFloat(str));
        case 1:
          lengthBeats.push(Std.parseFloat(str));
        case 2:
          eases.push(str);
        case 3:
          if (usingAltFormat && modAlternator) modNames.push(str);
          else
            modValues.push(Std.parseFloat(str));
          modAlternator = !modAlternator;
        case 4:
          if (usingAltFormat) targets.push(str);
          else
            modNames.push(str);
        case 5:
          if (!usingAltFormat) targets.push(str);
      }
      if (!inArray) stage++;
    }

    trace(" ---------- ");
    trace(startBeats);
    trace(lengthBeats);
    trace(eases);
    trace(modValues);
    trace(modNames);
    trace(targets);
    trace("!!! FIN !!!");

    multiFunc(startBeats, lengthBeats, eases, modValues, modNames, targets, type);
  }

  static function multiFunc(startBeats:Array<Float>, lengthBeats:Array<Float>, eases:Array<String>, modValues:Array<Float>, modNames:Array<String>, targets:Array<String>, type:String):Void
  {
    if (targets.length < 1)
    { // if empty, default to targetting all
      targets.push("all");
    }
    switch (type)
    {
      case "default":
        for (m in 0...modNames.length)
        {
          var mn:String = modNames[m];
          var mv:Float = 1;
          if (m < modValues.length)
          {
            mv = modValues[m];
          }
          else
          {
            mv = modValues[modValues.length - 1];
          }
          for (k in 0...targets.length)
          {
            var t:String = targets[k];
            setDefaultFunc(mv, mn, t);
          }
        }
      case "set":
        for (i in 0...startBeats.length)
        {
          var startBeat:Float = startBeats[i];
          for (m in 0...modNames.length)
          {
            var mn:String = modNames[m];
            var mv:Float = 1;
            if (m < modValues.length)
            {
              mv = modValues[m];
            }
            else
            {
              mv = modValues[modValues.length - 1];
            }
            for (k in 0...targets.length)
            {
              var t:String = targets[k];
              setFunc(startBeat, mv, mn, t);
            }
          }
        }
      case "add" | "tween":
        for (i in 0...startBeats.length)
        {
          var startBeat:Float = startBeats[i];
          var length:Float = 1;

          if (i < lengthBeats.length)
          {
            length = lengthBeats[i];
          }
          else
          {
            length = lengthBeats[lengthBeats.length - 1];
          }
          var e:String = "linear";

          if (i < eases.length)
          {
            e = eases[i];
          }
          else
          {
            e = eases[eases.length - 1];
          }
          for (m in 0...modNames.length)
          {
            var mn:String = modNames[m];
            var mv:Float = 1;
            if (m < modValues.length)
            {
              mv = modValues[m];
            }
            else
            {
              mv = modValues[modValues.length - 1];
            }
            for (k in 0...targets.length)
            {
              var t:String = targets[k];

              if (type == "add")
              {
                addFunc(startBeat, length, e, mv, mn, t);
              }
              else
              {
                tweenFunc(startBeat, length, e, mv, mn, t);
              }
            }
          }
        }
    }
  }

  static function multiFuncS(startSteps:Array<Float>, lengthSteps:Array<Float>, eases:Array<String>, modValues:Array<Float>, modNames:Array<String>, targets:Array<String>, type:String):Void
  {
    if (targets.length < 1)
    { // if empty, default to targetting all
      targets.push("all");
    }
    switch (type)
    {
      case "default":
        for (m in 0...modNames.length)
        {
          var mn:String = modNames[m];
          var mv:Float = 1;
          if (m < modValues.length)
          {
            mv = modValues[m];
          }
          else
          {
            mv = modValues[modValues.length - 1];
          }
          for (k in 0...targets.length)
          {
            var t:String = targets[k];
            setDefaultFunc(mv, mn, t);
          }
        }
      case "set":
        for (i in 0...startSteps.length)
        {
          var startStep:Float = startSteps[i];
          for (m in 0...modNames.length)
          {
            var mn:String = modNames[m];
            var mv:Float = 1;
            if (m < modValues.length)
            {
              mv = modValues[m];
            }
            else
            {
              mv = modValues[modValues.length - 1];
            }
            for (k in 0...targets.length)
            {
              var t:String = targets[k];
              setFuncS(startStep, mv, mn, t);
            }
          }
        }
      case "add" | "tween":
        for (i in 0...startSteps.length)
        {
          var startStep:Float = startSteps[i];
          var length:Float = 1;

          if (i < lengthSteps.length)
          {
            length = lengthSteps[i];
          }
          else
          {
            length = lengthSteps[lengthSteps.length - 1];
          }
          var e:String = "linear";

          if (i < eases.length)
          {
            e = eases[i];
          }
          else
          {
            e = eases[eases.length - 1];
          }
          for (m in 0...modNames.length)
          {
            var mn:String = modNames[m];
            var mv:Float = 1;
            if (m < modValues.length)
            {
              mv = modValues[m];
            }
            else
            {
              mv = modValues[modValues.length - 1];
            }
            for (k in 0...targets.length)
            {
              var t:String = targets[k];

              if (type == "add")
              {
                addFuncS(startStep, length, e, mv, mn, t);
              }
              else
              {
                tweenFuncS(startStep, length, e, mv, mn, t);
              }
            }
          }
        }
    }
  }

  static function valueFunc(startBeat:Float, lengthInBeats:Float, easeToUse:String, startingValue:Float, endingValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED TWEEN: " + modName);
    modName = ModConstants.modAliasCheck(modName);

    // trace("ease name : " + easeToUse);
    // trace("ease to use : " + ModConstants.getEaseFromString(easeToUse));
    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(
          strummer
        )) MegaManager.playfield.modchartEventHandler.valueTweenModEvent(
          strummer.mods,
          startBeat,
          lengthInBeats,
          ModConstants.getEaseFromString(easeToUse),
          startingValue,
          endingValue,
          modName
          );
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.valueTweenModEvent(
        modsTarget,
        startBeat,
        lengthInBeats,
        ModConstants.getEaseFromString(easeToUse),
        startingValue,
        endingValue,
        modName
      );
    }
  }

  static function formaterTargets(targetsRaw:Any):Array<String>
  {
    var targets:Array<String> = [];
    if (Std.isOfType(targetsRaw, Array))
    {
      var targetsArray:Array<String> = cast targetsRaw;
      for (i in targetsArray)
      {
        targets.push(i);
      }
    }
    else
    {
      targets = [(targetsRaw ?? "all")];
    }
    return targets;
  }

  static function setDefaultFunc_parser(modValue:Any, modName:Any, _playerTarget:Any = "all"):Void
  {
    var targets_raw:Any = _playerTarget;

    var modArray:Bool = false;
    if (Std.isOfType(modValue, Array))
    {
      // modName becomes playerTarget and _playerTarget is unused.
      modArray = true;
      targets_raw = modName;
    }

    var targets:Array<String> = formaterTargets(targets_raw);

    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    if (!modArray)
    {
      modValues = [modValue];
      modNames = [modName];
    }
    else
    {
      var isName:Bool = false;
      var modsInputArray:Array<String> = cast modValue;
      for (i in modsInputArray)
      {
        if (isName) modNames.push(i);
        else
          modValues.push(Std.parseFloat(i));
        isName = !isName;
      }
    }

    for (t in targets)
    {
      for (i in 0...modNames.length)
      {
        setDefaultFunc(modValues[i], modNames[i], t);
      }
    }
  }

  static function setFunc_parser(startBeat:Float, modValue:Any, modName:Any, _playerTarget:Any = "all"):Void
  {
    var targets_raw:Any = _playerTarget;

    var modArray:Bool = false;
    if (Std.isOfType(modValue, Array))
    {
      // modName becomes playerTarget and _playerTarget is unused.
      modArray = true;
      targets_raw = modName;
    }

    var targets:Array<String> = formaterTargets(targets_raw);

    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    if (!modArray)
    {
      modValues = [modValue];
      modNames = [modName];
    }
    else
    {
      var isName:Bool = false;
      var modsInputArray:Array<String> = cast modValue;
      for (i in modsInputArray)
      {
        if (isName) modNames.push(i);
        else
          modValues.push(Std.parseFloat(i));
        isName = !isName;
      }
    }

    for (t in targets)
    {
      for (i in 0...modNames.length)
      {
        setFunc(startBeat, modValues[i], modNames[i], t);
      }
    }
  }

  static function addFunc_parser(startBeat:Float, lengthInBeats:Float, easeToUse:String, modValue:Any, modName:Any, _playerTarget:Any = "all"):Void
  {
    var targets_raw:Any = _playerTarget;

    var modArray:Bool = false;
    if (Std.isOfType(modValue, Array))
    {
      // modName becomes playerTarget and _playerTarget is unused.
      modArray = true;
      targets_raw = modName;
    }

    var targets:Array<String> = formaterTargets(targets_raw);

    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    if (!modArray)
    {
      modValues = [modValue];
      modNames = [modName];
    }
    else
    {
      var isName:Bool = false;
      var modsInputArray:Array<String> = cast modValue;
      for (i in modsInputArray)
      {
        if (isName) modNames.push(i);
        else
          modValues.push(Std.parseFloat(i));
        isName = !isName;
      }
    }

    for (t in targets)
    {
      for (i in 0...modNames.length)
      {
        addFunc(startBeat, lengthInBeats, easeToUse, modValues[i], modNames[i], t);
      }
    }
  }

  // could be
  // tween(0, 4, "linear", 1, "beat", "3")
  // tween(0, 4, "linear", {1, "beat", 1, "drunk"}, {3,1})
  // Work In Progress replacement to allow users to input multiple mod values into the same function without needing to convert it all to a string like for tweens func

  static function tweenFunc_parser(startBeat:Float, lengthInBeats:Float, easeToUse:String, modValue:Any, modName:Any, _playerTarget:Any = "all"):Void
  {
    var targets_raw:Any = _playerTarget;
    var modArray:Bool = false;
    if (Std.isOfType(modValue, Array))
    {
      // modName becomes playerTarget and _playerTarget is unused.
      modArray = true;
      targets_raw = modName;
    }

    var targets:Array<String> = formaterTargets(targets_raw);

    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    if (!modArray)
    {
      modValues = [modValue];
      modNames = [modName];
    }
    else
    {
      var isName:Bool = false;
      var modsInputArray:Array<String> = cast modValue;
      for (i in modsInputArray)
      {
        if (isName) modNames.push(i);
        else
          modValues.push(Std.parseFloat(i));
        isName = !isName;
      }
    }

    for (t in targets)
    {
      for (i in 0...modNames.length)
      {
        tweenFunc(startBeat, lengthInBeats, easeToUse, modValues[i], modNames[i], t);
      }
    }
  }

  static function addStepFunc_parser(startStep:Float, lengthInSteps:Float, easeToUse:String, modValue:Any, modName:Any, _playerTarget:Any = "all"):Void
  {
    var targets_raw:Any = _playerTarget;

    var modArray:Bool = false;
    if (Std.isOfType(modValue, Array))
    {
      // modName becomes playerTarget and _playerTarget is unused.
      modArray = true;
      targets_raw = modName;
    }

    var targets:Array<String> = formaterTargets(targets_raw);

    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    if (!modArray)
    {
      modValues = [modValue];
      modNames = [modName];
    }
    else
    {
      var isName:Bool = false;
      var modsInputArray:Array<String> = cast modValue;
      for (i in modsInputArray)
      {
        if (isName) modNames.push(i);
        else
          modValues.push(Std.parseFloat(i));
        isName = !isName;
      }
    }

    for (t in targets)
    {
      for (i in 0...modNames.length)
      {
        addFuncS(startStep, lengthInSteps, easeToUse, modValues[i], modNames[i], t);
      }
    }
  }

  // could be
  // tween(0, 4, "linear", 1, "beat", "3")
  // tween(0, 4, "linear", {1, "beat", 1, "drunk"}, {3,1})
  // Work In Progress replacement to allow users to input multiple mod values into the same function without needing to convert it all to a string like for tweens func

  static function tweenStepFunc_parser(startStep:Float, lengthInSteps:Float, easeToUse:String, modValue:Any, modName:Any, _playerTarget:Any = "all"):Void
  {
    var targets_raw:Any = _playerTarget;
    var modArray:Bool = false;
    if (Std.isOfType(modValue, Array))
    {
      // modName becomes playerTarget and _playerTarget is unused.
      modArray = true;
      targets_raw = modName;
    }

    var targets:Array<String> = formaterTargets(targets_raw);

    var modValues:Array<Float> = [];
    var modNames:Array<String> = [];
    if (!modArray)
    {
      modValues = [modValue];
      modNames = [modName];
    }
    else
    {
      var isName:Bool = false;
      var modsInputArray:Array<String> = cast modValue;
      for (i in modsInputArray)
      {
        if (isName) modNames.push(i);
        else
          modValues.push(Std.parseFloat(i));
        isName = !isName;
      }
    }

    for (t in targets)
    {
      for (i in 0...modNames.length)
      {
        tweenFuncS(startStep, lengthInSteps, easeToUse, modValues[i], modNames[i], t);
      }
    }
  }

  static function tweenFunc(startBeat:Float, lengthInBeats:Float, easeToUse:String, modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED TWEEN: " + modName);
    modName = ModConstants.modAliasCheck(modName);

    // trace("ease name : " + easeToUse);
    // trace("ease to use : " + ModConstants.getEaseFromString(easeToUse));
    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(strummer))
        {
          MegaManager.playfield.modchartEventHandler.tweenModEvent(
            strummer.mods,
            startBeat,
            lengthInBeats,
            ModConstants.getEaseFromString(easeToUse),
            modValue,
            modName
          );
        }
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.tweenModEvent(
        modsTarget,
        startBeat,
        lengthInBeats,
        ModConstants.getEaseFromString(easeToUse),
        modValue,
        modName
      );
    }
  }

  static function tweenFuncS(startStep:Float, lengthInSteps:Float, easeToUse:String, modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED TWEEN: " + modName);
    modName = ModConstants.modAliasCheck(modName);

    // trace("ease name : " + easeToUse);
    // trace("ease to use : " + ModConstants.getEaseFromString(easeToUse));
    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(strummer))
        {
          MegaManager.playfield.modchartEventHandler.tweenModEventS(
            strummer.mods,
            startStep,
            lengthInSteps,
            ModConstants.getEaseFromString(easeToUse),
            modValue,
            modName
          );
        }
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.tweenModEventS(
        modsTarget,
        startStep,
        lengthInSteps,
        ModConstants.getEaseFromString(easeToUse),
        modValue,
        modName
      );
    }
  }

  static function setDefaultFunc(modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    modName = ModConstants.modAliasCheck(modName);

    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(strummer)) strummer.mods.setDefaultModVal(modName, modValue);
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      modsTarget.setDefaultModVal(modName, modValue);
    }
  }

  static function setFunc(startBeat:Float, modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED SET: " + modName);
    modName = ModConstants.modAliasCheck(modName);

    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(strummer)) MegaManager.playfield.modchartEventHandler.setModEvent(strummer.mods, startBeat, modValue, modName);
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.setModEvent(modsTarget, startBeat, modValue, modName);
    }
  }

  static function setFuncS(startStep:Float, modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED SET: " + modName);
    modName = ModConstants.modAliasCheck(modName);

    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(strummer)) MegaManager.playfield.modchartEventHandler.setModEventS(strummer.mods, startStep, modValue, modName);
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.setModEventS(modsTarget, startStep, modValue, modName);
    }
  }

  static function addFunc(startBeat:Float, lengthInBeats:Float, easeToUse:String, modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED ADD: " + modName);
    modName = ModConstants.modAliasCheck(modName);
    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(
          strummer
        )) MegaManager.playfield.modchartEventHandler.addModEvent(
          strummer.mods,
          startBeat,
          lengthInBeats,
          ModConstants.getEaseFromString(easeToUse),
          modValue,
          modName
          );
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.addModEvent(modsTarget, startBeat, lengthInBeats, ModConstants.getEaseFromString(easeToUse), modValue, modName);
    }
  }

  static function addFuncS(startStep:Float, lengthInSteps:Float, easeToUse:String, modValue:Float, modName:String, playerTarget:String = "all"):Void
  {
    // trace("WOW! WE NEED ADD: " + modName);
    modName = ModConstants.modAliasCheck(modName);
    if (playerTarget == "everyone" || playerTarget == "both" || playerTarget == "all")
    {
      for (strummer in MegaManager.playfield.allStrumLines)
      {
        if (!allTargetExlusions.contains(
          strummer
        )) MegaManager.playfield.modchartEventHandler.addModEventS(
          strummer.mods,
          startStep,
          lengthInSteps,
          ModConstants.getEaseFromString(easeToUse),
          modValue,
          modName
          );
      }
    }
    else
    {
      var modsTarget = ModConstants.grabStrumModTarget(playerTarget);

      MegaManager.playfield.modchartEventHandler.addModEventS(modsTarget, startStep, lengthInSteps, ModConstants.getEaseFromString(easeToUse), modValue, modName);
    }
  }
}
