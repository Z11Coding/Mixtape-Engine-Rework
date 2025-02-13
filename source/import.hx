#if !macro

//Discord API
#if DISCORD_ALLOWED
import backend.DiscordClient;
#end

#if desktop
import sys.thread.Thread;
#end

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end
import haxe.ds.Vector as HaxeVector; //apparently denpa uses vectors, which is required for camera panning i guess

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

// Madatory things
import backend.Cursor;
import backend.Controls;
import backend.Paths;
import backend.BaseStage.Countdown; //so that it doesn't bring up a "Type not found: Countdown"
import states.MusicBeatState;
import substates.MusicBeatSubstate;
import objects.notes.Note;
import utils.MemoryUtil;
import music.Conductor;
import backend.ClientPrefs;
import backend.Mods;
import objects.BGSprite;
import backend.Language;
import utils.CoolUtil;
import states.menus.MenuTracker;
import objects.Alphabet;
import states.LoadingState;
import backend.TransitionState;
import utils.window.Window;
import utils.window.CppAPI;
import music.Song;

//Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxDestroyUtil;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxBasic;


using StringTools;
using utils.yutautil.CollectionUtils;
using utils.yutautil.Table;
using utils.yutautil.ChanceSelector;

#end