#if !macro
//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

import animate.*;
import backend.COD;
import backend.ClientPrefs;
import backend.Conductor;
import backend.Constants;
import backend.Controls;
import backend.CoolUtil;
import backend.Cursor;
import backend.CustomFadeTransition;
import backend.Difficulty;
import backend.FunkinSound;
import backend.Language;
import backend.Mods;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.NativeFileSystem;
import backend.Paths;
import backend.TransitionState;
import backend.pslice.FreeplayThings;
import backend.pslice.ScaleMode as MobileScaleMode; // too lazy + its 3 in the morning lol
import backend.pslice.StorageUtil;
import backend.ui.*; // Psych-UI
import backend.util.*;
import backend.window.Window;
import backend.window.WindowUtil;
import backend.window.WindowUtils;
import cache.Cache;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.sound.filters.*;
import flixel.sound.filters.effects.*;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import managers.*;
import mechanics.*;
import objects.Alphabet;
import objects.AudioDisplay;
import objects.BGSprite;
import objects.FunkinSprite;
import shaders.*;
import shop.*;
import stages.BaseStage;
import states.LoadingState;
import states.PlayState;
import states.editors.SourceEditorState;
import states.music.MusicEntry;
import states.music.MusicPlayerManager;
import states.music.MusicPlayerPlaylist;
import states.music.MusicPlayerState;
import states.music.MusicScanner;
import yutautil.AprilFools;
import yutautil.ChanceSelector;
import yutautil.ImprovedFileHandling;
import yutautil.YScript;

using StringTools;
using yutautil.CUMacroTools;
using yutautil.CollectionUtils;
using yutautil.FieldMap;
using yutautil.GenericObject;
using yutautil.HxTrace;
using yutautil.KonamiTracker;
using yutautil.MacroTypeUtils;
using yutautil.MetaData;
using yutautil.NamedArray;
using yutautil.Num;
using yutautil.PointerTools;
using yutautil.PyScript;
using yutautil.RuntimeTypedef;
using yutautil.Tracked;
using yutautil.TypeUtils;
using yutautil.Valid;
// using yutautil.lambda.LambdaCalculus;
using yutautil.modules.ASync.AResult;
using yutautil.modules.ASync.ASyncF;
using yutautil.modules.ASync;
#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

#if ARCHIPELAGO_ALLOWED
import archipelago.*;
import archipelago.console.*;
import archipelago.states.*;
import archipelago.substates.*;
import archipelago.traps.*;
#end

#if USING_MOONCHART
import moonchart.Moonchart;
import moonchart.formats.*;
import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;
import moonchart.parsers.*;
#end

#end
