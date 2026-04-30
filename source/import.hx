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

import animate.*;
import backend.AIPlayer;
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
import backend.Highscore;
import backend.Language;
import backend.Mods;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.NativeFileSystem;
import backend.Paths;
import backend.RConductor;
import backend.Rating;
import backend.Song;
import backend.TransitionState;
import backend.WeekData;
import backend.modchart.ModManager;
import backend.modchart.Modifier;
import backend.pslice.FreeplayThings;
import backend.pslice.ScaleMode as MobileScaleMode; // too lazy + its 3 in the morning lol
import backend.pslice.Scoring.ScoringRank;
import backend.pslice.Scoring;
import backend.pslice.StorageUtil;
import backend.ui.*; // Psych-UI
import backend.util.*;
import backend.window.Window;
import backend.window.WindowUtil;
import backend.window.WindowUtils;
import cache.Cache;
import cutscenes.DialogueBoxPsych;
import flixel.FlxBasic;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.sound.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.sound.filters.*;
import flixel.sound.filters.effects.*;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.media.openal.AL;
import lime.media.openal.ALAuxiliaryEffectSlot;
import lime.media.openal.ALEffect;
import lime.utils.Assets;
import managers.*;
import managers.DynamicSongManager;
import managers.DynamicSongScripting;
import managers.NotePoolManager;
import mechanics.*;
import metadata.STMetaFile.MetadataFile;
import objects.*;
import objects.Alphabet;
import objects.AudioDisplay;
import objects.BGSprite;
import objects.FunkinSprite;
import objects.Note.EventNote;
import objects.Note.SustainPart;
import objects.NoteObject;
import objects.SyncedVideoSprite;
import objects.VideoSprite;
import objects.playfields.*;
import openfl.display.StageQuality;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;
import shaders.*;
import shaders.ErrorHandledShader;
import shop.*;
import stages.*;
import stages.BaseStage;
import stages.StageData;
import states.LoadingState;
import states.PlayState;
import states.PlaylistState.PlaylistMetadata;
import states.PlaylistState.PlaylistSongMetadata;
import states.StoryMenuState;
import states.editors.CharacterEditorState;
import states.editors.ChartingState;
import states.editors.SourceEditorState;
import states.music.MusicEntry;
import states.music.MusicPlayerManager;
import states.music.MusicPlayerPlaylist;
import states.music.MusicPlayerState;
import states.music.MusicScanner;
import states.playbits.*; // All the bits
import substates.GameOverSubstate;
import substates.PauseSubState;
import substates.StickerSubState;
import substates.results.Tallies.SaveScoreData;
import yutautil.AprilFools;
import yutautil.AprilFools;
import yutautil.ChanceSelector.Chance;
import yutautil.ChanceSelector;
import yutautil.ChanceSelector;
import yutautil.ImprovedFileHandling;
import yutautil.UnoMechanic;
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
#if MECHANICS_MOD_ALLOWED
import mechanics.MechanicsPlaystate;
import mechanics.objects.Shape;
#end

#if (target.threaded)
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;
#end

#if LUA_ALLOWED
import backend.funkinmodchart.Manager;
import psychlua.*;

using psychlua.IntegratedScript;
#else
import psychlua.HScript;
import psychlua.LuaUtils;
#end

#if HSCRIPT_ALLOWED
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end


#if moonchart
import moonchart.Moonchart;
import moonchart.formats.*;
import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;
import moonchart.parsers.*;
#end

#end
