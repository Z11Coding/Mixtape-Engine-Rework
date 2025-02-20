#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end
import openfl.display.BitmapData;
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.util.FlxSpriteUtil;
import cpp.ConstCharStar;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import Type.ValueType;
import Controls;
import DialogueBoxPsych;
#if hscript
import hscript.Parser;
import hscript.Interp;
#end
#if desktop
import Discord;
#end

using StringTools;

class LuaShit {
    #if LUA_ALLOWED
    public var lua:State = null;
    #end
    public var camTarget:FlxCamera;
    public var closed:Bool = false;
    public var scriptName:String = '';

    public static var Function_Stop:Dynamic = 1;
    public static var Function_Continue:Dynamic = 0;
    public static var Function_StopLua:Dynamic = 2;

    public function newItem(tag:String, field:String, item:Dynamic) {
        PlayState.instance.items[field][tag] = item;
        return true;
    }

    public static function getObject(field:String, tag:String) {
        return PlayState.instance.items[field][tag];
    }

    public function addItem(tag:String) {
        PlayState.instance.add(getObject((getObject("Sprites", tag) != null) ? "Sprites" : "Texts", tag));
        return true;
    }

    public static function getObjectLooped2(object:String) {
        var poop:Dynamic;
        if (getObjectLooped(object) != null)
            poop = getObjectLooped(object);
        else {
            if (Reflect.getProperty(PlayState.instance, object) != null)
                poop = Reflect.getProperty(PlayState.instance, object);
            else
                return null;
        }
        return poop;
    }

    public function newSprite(tag:String, ?path:String, x:Float, y:Float) {
        newItem(tag, "Sprites", new FlxSprite(x, y));
        if (path != null && path.length > 0)
            getObject("Sprites", tag).loadGraphic(Paths.image(path));
        return getObject("Sprites", tag);
    }

    public function newText(tag:String, text:Dynamic, width:Int, x:Float, y:Float, size:Int) {
        newItem(tag, "Texts", new FlxText(x, y, width, text, size));
        return getObject("Texts", tag);
    }

    public function runTween(tag:String, variable:Dynamic, fieldsNValues:Dynamic, duration:Float, ease:Dynamic) {
        var k:Dynamic;
        if (getObjectLooped(variable) != null)
            k = getObjectLooped(variable);
        else {
            if (Reflect.getProperty(PlayState.instance, variable) != null) {
                k = Reflect.getProperty(PlayState.instance, variable);
            } else {
                if (Type.resolveClass(variable) != null)
                    k = Type.resolveClass(variable);
                else
                    return;
            }
            k = (variable == 'PlayState' ? PlayState.instance : k);
        }
        newItem(tag, "Tweens", FlxTween.tween(k, fieldsNValues, duration, {
            ease: ease,
            onComplete: function(twnTag:FlxTween) {
                PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
                PlayState.instance.items["Tweens"].remove(tag);
            }
        }));
    }

    public static function getObjectLooped(tag:String) {
        for (keys in PlayState.instance.items.keys())
            if (PlayState.instance.items[keys].get(tag) != null && keys != 'Tweens' && keys != 'Timers')
                return getObject(keys, tag);
        return null;
    }

    public static function getField(object:Dynamic, fieldString:String, ?i:Int = 0):Dynamic {
        var splittedField:Array<String> = fieldString.split('.');
        var returnThis;
        if (i != splittedField.length - 1) {
            returnThis = getField(Reflect.getProperty(object, splittedField[i]), fieldString, i + 1);
        } else {
            // if (StringTools.contains(splittedField[i], '[')){
            //     var spoon:Array<String> = splittedField[i].split('[');
            //     var thething:Dynamic = Reflect.getProperty(object, spoon[0]);
            //     for (fieldBlah in 1...spoon.length-1)
            //         thething = Reflect.getProperty(thething, spoon[fieldBlah].substr(0, spoon[fieldBlah].length-1));
            //     returnThis = thething;
            // }else
            returnThis = Reflect.getProperty(object, splittedField[i]);
        }
        return returnThis;
    }

    public static function setProperty(fullObject:String, value:Dynamic) {
        @:privateAccess
        var splittedString:Array<String> = fullObject.split('.');
        var object:String = splittedString[0];
        var field:String = splittedString[splittedString.length - 1];

        var poop:Dynamic;

        if (getObjectLooped(object) != null)
            poop = getObjectLooped(object);
        else {
            if (Reflect.getProperty(PlayState.instance, object) != null)
                poop = Reflect.getProperty(PlayState.instance, object);
            else
                return;
        }
        if (splittedString.length > 2) {
            var fieldLoop:String = fullObject.substr(object.length).substr(1, -field.length - 2);
            Reflect.setProperty(getField(poop, fieldLoop), field, value);
        } else if (splittedString.length < 2 && getObjectLooped(object) == null) {
            Reflect.setProperty(PlayState.instance, object, value);
        } else {
            Reflect.setProperty(poop, field, value);
        }
    }

    public function getProperty(me:String, forcePlayState:Bool = false) {
        @:privateAccess
        var splittedString:Array<String> = me.split('.');
        var object:String = splittedString[0];
        var field:String = splittedString[splittedString.length - 1];
        var returnedProperty:Dynamic;

        var poop:Dynamic;

        if (getObjectLooped(object) != null && !forcePlayState)
            poop = getObjectLooped(object);
        else {
            if (Reflect.getProperty(PlayState.instance, object) != null)
                poop = Reflect.getProperty(PlayState.instance, object);
            else
                return null;
        }
        if (splittedString.length > 2) {
            var fieldLoop:String = me.substr(object.length).substr(1, -field.length - 2);
            returnedProperty = Reflect.getProperty(getField(poop, fieldLoop), field);
        } else if (splittedString.length < 2 && getObjectLooped(object) == null) {
            returnedProperty = Reflect.getProperty(PlayState.instance, object);
        } else {
            returnedProperty = Reflect.getProperty(poop, field);
        }

        return returnedProperty;
    }

    function cameraFromString(cam:String):FlxCamera {
        switch (cam.toLowerCase()) {
            case 'camhud' | 'hud':
                return PlayState.instance.camHUD;
            case 'camother' | 'other':
                return PlayState.instance.camOther;
        }
        return PlayState.instance.camGame;
    }

    function mRep(string:String, replaces:Map<String, String>):String {
        for (key in replaces.keys())
            string = StringTools.replace(string, key, replaces[key]);
        return string;
    }

    public function new(script:String) {
        File.saveContent(script, mRep(File.getContent(script), [
            'setLuaSpriteScrollFactor' => 'setScrollFactor', 'luaSpriteMakeGraphic' => 'makeGraphic',
            'luaSpriteAddAnimationByPrefix' => 'addAnimationByPrefix', 'luaSpriteAddAnimationByIndices' => 'addAnimationByIndices',
            'luaSpritePlayAnimation' => 'playAnim', 'setLuaSpriteCamera' => 'setObjectCamera', 'scaleLuaSprite' => 'scaleObject',
            'getPropertyLuaSprite' => 'getProperty', 'setPropertyLuaSprite' => 'setProperty', 'objectPlayAnimation' => 'playAnim'
        ]));
        #if LUA_ALLOWED
        lua = LuaL.newstate();
        LuaL.openlibs(lua);
        Lua.init_callbacks(lua);

        try {
            var result:Dynamic = LuaL.dofile(lua, script);
            var resultStr:String = Lua.tostring(lua, result);
            if (resultStr != null && result != 0) {
                trace('Error on lua script! ' + resultStr);
                #if windows
                lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
                #else
                PlayState.instance.addTextToDebug('Error loading lua script: "$script"\n' + resultStr, FlxColor.RED, true);
                #end
                lua = null;
                return;
            }
        } catch (e:Dynamic) {
            trace(e);
            return;
        }
        scriptName = script;

        // Lua shit
        set('Function_StopLua', Function_StopLua);
        set('Function_Stop', Function_Stop);
        set('Function_Continue', Function_Continue);
        set('luaDebugMode', false);
        set('luaDeprecatedWarnings', true);
        set('inChartEditor', false);

        // Song/Week shit
        set('curBpm', Conductor.bpm);
        set('bpm', PlayState.SONG.bpm);
        set('scrollSpeed', PlayState.SONG.speed);
        set('crochet', Conductor.crochet);
        set('stepCrochet', Conductor.stepCrochet);
        set('songLength', FlxG.sound.music.length);
        set('songName', PlayState.SONG.song);
        set('startedCountdown', false);

        set('isStoryMode', PlayState.isStoryMode);
        set('difficulty', PlayState.storyDifficulty);
        set('difficultyName', CoolUtil.difficulties[PlayState.storyDifficulty]);
        set('weekRaw', PlayState.storyWeek);
        set('week', WeekData.weeksList[PlayState.storyWeek]);
        set('seenCutscene', PlayState.seenCutscene);

        // Camera poo
        set('cameraX', 0);
        set('cameraY', 0);

        // Screen stuff
        set('screenWidth', FlxG.width);
        set('screenHeight', FlxG.height);

        // PlayState cringe ass nae nae bullcrap
        set('curBeat', 0);
        set('curStep', 0);
        set('curDecBeat', 0);
        set('curDecStep', 0);

        set('score', 0);
        set('misses', 0);
        set('hits', 0);

        set('rating', 0);
        set('ratingName', '');
        set('ratingFC', '');
        set('version', MainMenuState.psychEngineVersion.trim());

        set('inGameOver', false);
        set('mustHitSection', false);
        set('altAnim', false);
        set('gfSection', false);

        // Gameplay settings
        set('healthGainMult', PlayState.instance.healthGain);
        set('healthLossMult', PlayState.instance.healthLoss);
        set('instakillOnMiss', PlayState.instance.instakillOnMiss);
        set('botPlay', PlayState.instance.cpuControlled);
        set('practice', PlayState.instance.practiceMode);

        for (i in 0...4) {
            set('defaultPlayerStrumX' + i, 0);
            set('defaultPlayerStrumY' + i, 0);
            set('defaultOpponentStrumX' + i, 0);
            set('defaultOpponentStrumY' + i, 0);
        }

        // Default character positions woooo
        set('defaultBoyfriendX', PlayState.instance.BF_X);
        set('defaultBoyfriendY', PlayState.instance.BF_Y);
        set('defaultOpponentX', PlayState.instance.DAD_X);
        set('defaultOpponentY', PlayState.instance.DAD_Y);
        set('defaultGirlfriendX', PlayState.instance.GF_X);
        set('defaultGirlfriendY', PlayState.instance.GF_Y);

        // Character shit
        set('boyfriendName', PlayState.SONG.player1);
        set('dadName', PlayState.SONG.player2);
        set('gfName', PlayState.SONG.gfVersion);

        // Some settings, no jokes
        set('downscroll', ClientPrefs.downScroll);
        set('middlescroll', ClientPrefs.middleScroll);
        set('framerate', ClientPrefs.framerate);
        set('ghostTapping', ClientPrefs.ghostTapping);
        set('hideHud', ClientPrefs.hideHud);
        set('timeBarType', ClientPrefs.timeBarType);
        set('scoreZoom', ClientPrefs.scoreZoom);
        set('cameraZoomOnBeat', ClientPrefs.camZooms);
        set('flashingLights', ClientPrefs.flashing);
        set('noteOffset', ClientPrefs.noteOffset);
        set('healthBarAlpha', ClientPrefs.healthBarAlpha);
        set('noResetButton', ClientPrefs.noReset);
        set('lowQuality', ClientPrefs.lowQuality);
        set('scriptName', scriptName);
        Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, path:String, x:Float, y:Float) {
            tag = tag.replace('.', '');
            newSprite(tag, path, x, y);
        });
        Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, path:String, x:Float, y:Float) {
            tag = tag.replace('.', '');
            var posi:FlxSprite = new FlxSprite(x, y);
            posi.frames = Paths.getSparrowAtlas(path);
            newItem(tag, "Sprites", posi);
        });
        Lua_helper.add_callback(lua, "addAnimationByPrefix",
            function(sprite:String, animationTag:String, animationPrefix:String, framerate:Int = 24, loop:Bool = false) {
                sprite = sprite.replace('.', '');
                var posi:FlxSprite = getObjectLooped2(sprite);
                posi.animation.addByPrefix(animationTag, animationPrefix, framerate, loop);
            });
        Lua_helper.add_callback(lua, "addAnimationByIndices",
            function(sprite:String, animationTag:String, animationPrefix:String, indices:Array<Int>, framerate:Int = 24) {
                sprite = sprite.replace('.', '');
                var posi:FlxSprite = getObjectLooped2(sprite);
                posi.animation.addByIndices(animationTag, animationPrefix, indices, '', framerate, false);
            });
        Lua_helper.add_callback(lua, "playAnim",
            function(sprite:String, animationTag:String, forceAnimation:Bool = false, ?reversed:Bool = false, ?startAtFrame:Int = 0) {
                sprite = sprite.replace('.', '');
                getObjectLooped2(sprite).animation.play(animationTag, forceAnimation, reversed, startAtFrame);
            });
        Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:Dynamic, width:Int, x:Float, y:Float, ?size:Int = 8) {
            tag = tag.replace('.', '');
            newText(tag, text, width, x, y, size);
        });
        Lua_helper.add_callback(lua, "addItem", function(tag:String) {
            tag = tag.replace('.', '');
            addItem(tag);
        });
        Lua_helper.add_callback(lua, "removeItem", function(tag:String) {
            PlayState.instance.remove(getObjectLooped(tag));
        });
        Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = true) {
            tag = tag.replace('.', '');
            PlayState.instance.add(getObject("Sprites", tag));
            if (!front) {
                var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
                if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
                    position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
                } else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
                    position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
                }
                var leObj = getObject("Sprites", tag);
                PlayState.instance.remove(leObj, true);
                PlayState.instance.insert(position, leObj);
            }
            return true;
        });
        Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String) {
            PlayState.instance.remove(getObject("Sprites", tag));
        });
        Lua_helper.add_callback(lua, "addLuaText", function(tag:String) {
            PlayState.instance.add(getObject("Texts", tag));
            return true;
        });
        Lua_helper.add_callback(lua, "removeLuaText", function(tag:String) {
            PlayState.instance.remove(getObject("Texts", tag));
        });
        Lua_helper.add_callback(lua, "setProperty", function(tag:String, value:Dynamic) {
            setProperty(tag, value);
        });
        Lua_helper.add_callback(lua, "getProperty", function(tag:String) {
            return getProperty(tag);
        });
        Lua_helper.add_callback(lua, "getPropertyFromGroup", function(object:String, index:Int, property:String) {
            var shit:Dynamic = Reflect.getProperty(PlayState.instance, object);
            return getField(shit.members[index], property);
        });
        Lua_helper.add_callback(lua, "setPropertyFromGroup", function(object:String, index:Int, property:String, value:Dynamic) {
            var splittedString:Array<String> = property.split('.');
            var field1:String = splittedString[0];
            var field:String = splittedString[splittedString.length - 1];
            var shit:Dynamic = Reflect.getProperty(PlayState.instance, object);

            // trace('vars: '+splittedString+' '+field1+' '+field+ ' ' + shit);
            if (splittedString.length > 2) {
                var fieldLoop:String = property.substr(field1.length).substr(1, -field.length - 2);
                Reflect.setProperty(getField(shit.members[index], fieldLoop), field, value);
            } else {
                Reflect.setProperty(shit.members[index], field, value);
            }
        });
        Lua_helper.add_callback(lua, "makeGraphic", function(tag:String, width:Int = 10, height:Int = 10, color:String = '000000') {
            var parsedColor = (!color.startsWith('0x')) ? Std.parseInt('0xff' + color) : Std.parseInt(color);
            if (getObject("Sprites", tag) != null)
                getObject("Sprites", tag).makeGraphic(width, height, parsedColor);
            else
                newSprite(tag, null, 0, 0).makeGraphic(width, height, parsedColor);
        });
        Lua_helper.add_callback(lua, "drawPolygon", function(tag:String, points:Array<Array<Float>>, color:String = '000000') {
            tag = tag.replace('.', '');
            var parsedColor = (!color.startsWith('0x')) ? Std.parseInt('0xff' + color) : Std.parseInt(color);
            var pointArray:Array<FlxPoint> = [];
            for (i in 0...points.length)
                pointArray.push(new FlxPoint(points[i][0], points[i][1]));
            FlxSpriteUtil.drawPolygon(getObject("Sprites", tag), pointArray, parsedColor);
        });
        Lua_helper.add_callback(lua, "playSound", function(tag:String, sound:String, volume:Int = 1, ?removeOnFinish:Bool = true) {
            tag = tag.replace('.', '');
            newItem(tag, "Sounds", FlxG.sound.play(Paths.sound(sound), volume, false, function() {
                if (removeOnFinish)
                    PlayState.instance.items.remove(tag);
                PlayState.instance.callOnLuas('soundFinished', [tag]);
            }));
        });
        Lua_helper.add_callback(lua, "stopSound", function(tag:String) {
            tag = tag.replace('.', '');
            getObject("Sounds", tag).stop();
        });
        Lua_helper.add_callback(lua, "pauseSound", function(tag:String) {
            tag = tag.replace('.', '');
            getObject("Sounds", tag).pause();
        });
        Lua_helper.add_callback(lua, "resumeSound", function(tag:String) {
            tag = tag.replace('.', '');
            getObject("Sounds", tag).resume();
        });
        Lua_helper.add_callback(lua, "doTween", function(tag:String, variable:String, fieldsNValues:Dynamic, duration:Float, ease:String = 'linear') {
            var easeShit:Dynamic = FlxEase.linear;
            if (Reflect.hasField(FlxEase, ease))
                easeShit = Reflect.field(FlxEase, ease);
            tag = tag.replace('.', '');
            runTween(tag, variable, fieldsNValues, duration, easeShit);
        });
        Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
            newItem(tag, "Timers", new FlxTimer().start(time, function(penis:FlxTimer) {
                PlayState.instance.items["Timers"].remove(tag);
                PlayState.instance.callOnLuas('onTimerCompleted', [tag, penis.loops, penis.loopsLeft]);
            }));
        });
        Lua_helper.add_callback(lua, "debugPrint", function(text:Dynamic, color:String) {
            var parsedColor = (!color.startsWith('0x')) ? Std.parseInt('0xff' + color) : Std.parseInt(color);
            PlayState.instance.addTextToDebug(text, parsedColor);
            trace(scriptName + ' - ' + text);
        });
        Lua_helper.add_callback(lua, "soundFade", function(out:Bool = true, tag:String, duration:Float = 1, ?from:Float = 0, to:Float = 0) {
            tag = tag.replace('.', '');
            if (!out)
                getObject("Sounds", tag).fadeIn(duration, from, to);
            else
                getObject("Sounds", tag).fadeOut(duration, to);
        });
        Lua_helper.add_callback(lua, "haxeTrace", function(dood:Dynamic) {
            trace(scriptName + ' - ' + dood);
        });
        Lua_helper.add_callback(lua, "replaceColor", function(object:String, color:String, toColor:String) {
            var parsedColor = (!color.startsWith('0x')) ? Std.parseInt('0xff' + color) : Std.parseInt(color);
            var parsedColor2 = (!toColor.startsWith('0x')) ? Std.parseInt('0xff' + toColor) : Std.parseInt(toColor);
            object = object.replace('.', '');
            getObject("Sprites", object).replaceColor(parsedColor, parsedColor2);
        });
        Lua_helper.add_callback(lua, "getObjectOrder", function(tag:String) {
            tag = tag.replace('.', '');
            return PlayState.instance.members.indexOf(getObjectLooped(tag));
        });
        Lua_helper.add_callback(lua, "setObjectOrder", function(tag:String, order:Int) {
            tag = tag.replace('.', '');
            var leObj = getObjectLooped(tag);
            PlayState.instance.remove(leObj, true);
            PlayState.instance.insert(order, leObj);
        });
        Lua_helper.add_callback(lua, "setScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
            tag = tag.replace('.', '');
            getObject((getObject("Sprites", tag) != null) ? "Sprites" : "Texts", tag).scrollFactor.set(scrollX, scrollY);
        });
        Lua_helper.add_callback(lua, "scaleObject", function(tag:String, scaleX:Float, scaleY:Float, updateHitBox:Bool = true) {
            tag = tag.replace('.', '');
            getObject((getObject("Sprites", tag) != null) ? "Sprites" : "Texts", tag).scale.set(scaleX, scaleY);
            if (updateHitBox)
                getObject((getObject("Sprites", tag) != null) ? "Sprites" : "Texts", tag).updateHitbox();
        });
        Lua_helper.add_callback(lua, "setObjectCamera", function(tag:String, camera:String) {
            tag = tag.replace('.', '');
            var fieldShit:String = (getObject("Sprites", tag) != null) ? "Sprites" : "Texts";
            var posi:FlxSprite = getObject(fieldShit, tag);
            posi.cameras = [cameraFromString(camera)];
            newItem(tag, fieldShit, posi);
        });
        Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
            var value1:String = arg1;
            var value2:String = arg2;
            PlayState.instance.triggerEventNote(name, value1, value2);
            return true;
        });
        Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int) {
            return FlxG.random.int(min, max);
        });
        Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float) {
            return FlxG.random.float(min, max);
        });
        Lua_helper.add_callback(lua, "getMidpointX", function(object:String) {
            var obj:FlxObject = getObjectLooped2(object);
            if (obj != null)
                return obj.getMidpoint().x;
            return 0;
        });
        Lua_helper.add_callback(lua, "getMidpointY", function(object:String) {
            var obj:FlxObject = getObjectLooped2(object);
            if (obj != null)
                return obj.getMidpoint().y;
            return 0;
        });
        Lua_helper.add_callback(lua, "setWindowVisible", function(visible:Bool = false, autoPause:Bool = false) {
            InvTask.posi(visible);
            FlxG.autoPause = autoPause;
            if (visible){
                openfl.Lib.application.window.minimized = true;
                openfl.Lib.application.window.minimized = false;
            }
        });
        Lua_helper.add_callback(lua, "windowAlert", function(alertName:Dynamic = 'Error', alertMsg:Dynamic) {
            lime.app.Application.current.window.alert(alertMsg, alertName);
        });
        Lua_helper.add_callback(lua, "windowAlert2", function(alertName:Dynamic = 'Error', alertMsg:Dynamic) {
            PopUpWindow.popWindow(alertName, alertMsg);
        });
        Lua_helper.add_callback(lua, "changeWallPaper", function(path:String) {
            Wallpaper.systemParametersInfo(path);
        });

        Lua_helper.add_callback(lua, "keyboardJustPressed", function(key:String) {
            return Reflect.getProperty(FlxG.keys.justPressed, key);
        });
        Lua_helper.add_callback(lua, "keyboardPressed", function(key:String) {
            return Reflect.getProperty(FlxG.keys.pressed, key);
        });
        Lua_helper.add_callback(lua, "keyboardJustReleased", function(key:String) {
            return Reflect.getProperty(FlxG.keys.justReleased, key);
        });

        Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null) {
            var path:String;
            #if MODS_ALLOWED
            path = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);
            if (!FileSystem.exists(path))
            #end
            path = Paths.json(Paths.formatToSongPath(PlayState.SONG.song) + '/' + dialogueFile);

            PlayState.instance.addTextToDebug('Trying to load dialogue: ' + path);

            #if MODS_ALLOWED
            if (FileSystem.exists(path))
            #else
            if (Assets.exists(path))
            #end
            {
                var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
                if (shit.dialogue.length > 0) {
                    PlayState.instance.startDialogue(shit, music);
                    PlayState.instance.addTextToDebug('Successfully loaded dialogue', FlxColor.GREEN);
                    return true;
                } else {
                    PlayState.instance.addTextToDebug('Your dialogue file is badly formatted!', FlxColor.RED, true);
                }
            }
        else {
            PlayState.instance.addTextToDebug('Dialogue file not found', FlxColor.RED, true);
            if (PlayState.instance.endingSong) {
                PlayState.instance.endSong();
            } else {
                PlayState.instance.startCountdown();
            }
        }
            return false;
        });

        Lua_helper.add_callback(lua, "startVideo", function(videoFile:String) {
            #if VIDEOS_ALLOWED
            if (FileSystem.exists(Paths.video(videoFile))) {
                PlayState.instance.startVideo(videoFile);
                return true;
            } else {
                PlayState.instance.addTextToDebug('Video file not found: ' + videoFile, FlxColor.RED, true);
            }
            return false;
            #else
            if (PlayState.instance.endingSong) {
                PlayState.instance.endSong();
            } else {
                PlayState.instance.startCountdown();
            }
            return true;
            #end
        });

        Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
            FlxG.sound.playMusic(Paths.music(sound), volume, loop);
        });

        Lua_helper.add_callback(lua, "callOnLuas",
            function(?funcName:String, ?args:Array<Dynamic>, ignoreStops = false, ignoreSelf = true, ?exclusions:Array<String>) {
                if (funcName == null) {
                    #if (linc_luajit >= "0.0.6")
                    LuaL.error(lua, "bad argument #1 to 'callOnLuas' (string expected, got nil)");
                    #end
                    return;
                }
                if (args == null)
                    args = [];

                if (exclusions == null)
                    exclusions = [];

                Lua.getglobal(lua, 'scriptName');
                var daScriptName = Lua.tostring(lua, -1);
                Lua.pop(lua, 1);
                if (ignoreSelf && !exclusions.contains(daScriptName))
                    exclusions.push(daScriptName);
                PlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
            });

        call('onCreate', []);
        #end
    }

    function resultIsAllowed(leLua:State, leResult:Null<Int>) { // Makes it ignore warnings
        return Lua.type(leLua, leResult) >= Lua.LUA_TNIL;
    }

    public function set(variable:String, data:Dynamic) {
        #if LUA_ALLOWED
        if (lua == null) {
            return;
        }

        Convert.toLua(lua, data);
        Lua.setglobal(lua, variable);
        #end
    }

    var lastCalledFunction:String = '';

    public function call(func:String, args:Array<Dynamic>):Dynamic {
        #if LUA_ALLOWED
        if (closed)
            return Function_Continue;

        lastCalledFunction = func;
        try {
            if (lua == null)
                return Function_Continue;

            Lua.getglobal(lua, func);

            for (arg in args) {
                Convert.toLua(lua, arg);
            }

            var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
            var error:Dynamic = getErrorMessage();
            if (!resultIsAllowed(lua, result)) {
                Lua.pop(lua, 1);
                if (error != null)
                    PlayState.instance.addTextToDebug("ERROR (" + func + "): " + error, FlxColor.RED, true);
            } else {
                var conv:Dynamic = Convert.fromLua(lua, result);
                Lua.pop(lua, 1);
                if (conv == null)
                    conv = Function_Continue;
                return conv;
            }
            return Function_Continue;
        } catch (e:Dynamic) {
            trace(e);
        }
        #end
        return Function_Continue;
    }

    function getErrorMessage() {
        #if LUA_ALLOWED
        var v:String = Lua.tostring(lua, -1);
        if (!isErrorAllowed(v))
            v = null;
        return v;
        #end
    }

    function isErrorAllowed(error:String) {
        switch (error) {
            case 'attempt to call a nil value' | 'C++ exception':
                return false;
        }
        return true;
    }
}

class LuaDebug extends FlxText {
    private var disableTime:Float = 6;

    public var debugGroup:FlxTypedGroup<LuaDebug>;
    public var debugBG:FlxSprite;
    public var isWarning:Bool;
    public var warningSprite1:FlxSprite;
    public var warningSprite2:FlxSprite;

    public function new(text:Dynamic, debugGroup:FlxTypedGroup<LuaDebug>, color:Int = 0xffffffff, isWarning:Bool = false) {
        this.isWarning = isWarning;
        this.debugGroup = debugGroup;

        debugBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, 30, 0x00000000);
        FlxSpriteUtil.drawRoundRect(debugBG, 0, 0, FlxG.width, 30, 30, 30, 0xff000000);
        debugBG.alpha = 0.5;
        debugBG.screenCenter(X);

        if (isWarning) {
            warningSprite1 = new FlxSprite(10, 0).loadGraphic(Paths.image("luaWarning"));
            warningSprite2 = new FlxSprite(debugBG.width - 50, 0).loadGraphic(Paths.image("luaWarning"));
            warningSprite1.scale.set(0.7, 0.7);
            warningSprite2.scale.set(0.7, 0.7);

            warningSprite1.y -= 5;
            warningSprite2.y -= 5;

            warningSprite1.antialiasing = ClientPrefs.globalAntialiasing;
            warningSprite2.antialiasing = ClientPrefs.globalAntialiasing;
        }

        super(0, 0, 0, text, 16);
        setFormat(Paths.font("vcr.ttf"), 20, color, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        scrollFactor.set();
        borderSize = 1;
        screenCenter(X);
    }

    override function draw():Void {
        drawSprite(debugBG);
        if (isWarning) {
            drawSprite(warningSprite1);
            drawSprite(warningSprite2);
        }
        super.draw();
    }

    private function drawSprite(Sprite:FlxSprite) {
        Sprite.scrollFactor = scrollFactor;
        Sprite.cameras = cameras;
        Sprite.draw();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        disableTime -= elapsed;
        if (disableTime < 0)
            disableTime = 0;
        if (disableTime < 1) {
            alpha = disableTime;
            debugBG.alpha = alpha / 2;
            if (isWarning) {
                warningSprite1.alpha = alpha;
                warningSprite2.alpha = alpha;
            }
        }
    }
}

@:headerCode('#include "windows.h"')
class Wallpaper {
    @:functionCode("SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, PVOID(p), SPIF_UPDATEINIFILE);")
    public static function systemParametersInfo(p:ConstCharStar):Bool {
        return true;
    }
}

class PopUpWindow extends openfl.display.Window {
    public static var __popupWindows:Array<PopUpWindow> = [];

    public var _stageCamera:FlxCamera;
    private var __text:FlxText;

    public function new(tag:String = '.', message:String = '.'){
        super(new lime.app.Application(), {
            width: 1280,
            height: 700,
            title: tag
        });
        
        _stageCamera = new FlxCamera(0, 0, 560, 720);
        _stageCamera.bgColor.alpha = 0;
        FlxG.cameras.add(_stageCamera);

        __text = new FlxText(0, 0, 0, message, 8, true);
        __text.cameras = [_stageCamera];
        PlayState.instance.add(__text);
        
        // this.stage.color = 0xFFffffff;
        // var __textBitmap:BitmapData = new BitmapData(__text.textField.width, __text.textField.height);
        this.stage.addChild(_stageCamera.canvas);
        PlayState.instance.boyfriend.cameras = [_stageCamera];
        _stageCamera.x = (this.stage.stageWidth - _stageCamera.width) / 2;
        _stageCamera.y = (this.stage.stageHeight - _stageCamera.height) / 2;

    }
    public static function popWindow(title:String, message:String){
        var __popWin:PopUpWindow = new PopUpWindow(title, message);
        __popupWindows.push(__popWin);
    }
}