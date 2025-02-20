package states.editors;

import flash.geom.Rectangle;
import tjson.TJSON as Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;

import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;

import flixel.util.FlxSort;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;

import backend.Song;
import backend.Section;
import backend.StageData;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;
import objects.HealthIcon;
import objects.AttachedSprite;
import objects.Character;
import substates.Prompt;

import flixel.util.FlxStringUtil;

import openfl.events.MouseEvent;

//import backend.FlxUIDropDownMenuCustom;


#if sys
import flash.media.Sound;
import sys.FileSystem;
import sys.io.File;
#end

import backend.MusicBeatChartingState;
import states.editors.content.*;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)


class ChartingStateOG extends MusicBeatChartingState
{
	function onClosing(e:Event):Void {
		var currentChartState = haxe.Json.stringify({"song": _song}); // Get current chart state as a string
		var autosavedChartState = FlxG.save.data.autosave; // Assuming this is the autosaved state

		if (currentChartState != autosavedChartState) {
			e.preventDefault(); // Prevent closing
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){Sys.exit(1);}, null,ignoreWarnings));
		}
	}

	
	public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	[	'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation',
		'EX Note',
		'GF Duet',
		'Beatbox Note',
		'Both Note',
		'Both Alt Note'
	];
	private var didAThing = false;
	public var ignoreWarnings = false;
	public var autoSave = true;
	public var autoSaveLength:Float = 60;
	var curNoteTypes:Array<String> = [];
	var undos = [];
	var redos = [];
	public var hitsound:FlxSound;
	final mouse_listeners:Array<openfl.events.EventType<openfl.events.MouseEvent>> = [
		MouseEvent.MOUSE_DOWN, MouseEvent.RIGHT_MOUSE_DOWN, MouseEvent.MOUSE_MOVE
	];
	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Change Focus', 'Move the focus of the camera to a specific character\nLeave it empty to return the camera to normal.'],
		['Set Game Cam Zoom and angle', "Value 1: Cam Zoom \n(1 is default, but depends in the stage's) \n Value 2: Cam angle"],
		['Set hud Cam Zoom and angle', "Value 1: Hud Cam Zoom \n\n (1 is default, but depends) \n Value 2: Cam angle"],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		["Constant SV", "Speed changes which don't affect note positions.\n(For example, a speed of 0 stops notes\ninstead of making them go onto the receptors.)\nValue 1: New Speed"],
		["Mult SV", "Speed changes which don't affect note positions.\n(For example, a speed of 0 stops notes\ninstead of making them go onto the receptors.)\nValue 1: Speed Multiplier"],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['Play Sound', "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"],
		['Change Mania', "Value 1: The new mania value (min: 0; max: 9)"],
		['Change Mania (Special)', "Value 1: The new mania value (min: 0; max: 9)"],
		['Super Burst', "Funnie Powerup"],
		['Burst Dad', "Funnie Dad Burst"],
		['Burst Boyfriend', "Funnie BF Burst"],
		['Burst Dad 2', "Funnie Dad 2 Burst"],
		['Burst BF2', "Funnie BF 2 Burst"],
		['Switch Scroll', "Swap da scroll. Value 1: True or False"],
		['Dad Fly', "Fly da dad. Value 1: True or False"],
		['Turn on StrumFocus', "focuses the strums"],
		['Turn off StrumFocus', "un-focuses the strums"],
		['Fade In', "Hello There.\nValue 1 = time it takes to fade."],
		['Fade Out', "Bye Bye!\nValue 1 = time it takes to fade."],
		['Silhouette', 'KSGDUSN UYGD WHERE DID THE CHARACTERS GO!?!?!!?\nValue 1 Can Either Be Black Or White. Leave Blank For Normal'],
		['Save Song Posititon', 'Place event where the player will start the song when they retry after they die.'],
		['False Timer', 'Dang that was a short so-OH MY GOD WAIT I HAVE 5 MINUTES LEFT WHAT!\nPlace the event where the timer will revert back to the next\nfalse timer event or the actual length of the song.'],
		['Chromatic Aberration', "Adds Le Chromatic Aberration.\nValue 1 = Amount Of Abberation"],
		['Move Window', "Move The Window. No Im Not Kidding. Value1 = X Posiion. Value2 = Y Position."],
		['Static', "Da Static\nValue 1 = Type Of Static:\n0 = Full Static\n1 = I See You\n2 = Half Static\n3 = No Static"],
		['Static Fade', "Da Static Fade\nValue 1 = Time To Fade Static\nValue 2 = Alpha to Fade Static To"],
		['Thunderstorm Trigger', "Ayo Its Raining.\nValue 1 = Type Of Storm.\n0 = light rain\n1 = heavy rain\n2 = thunderstorm\n3 = clear skys"],
		['Rave Mode', "Reworked and WAY cooler!\nValue 1 can either be \n0(Off), 1(Light Rave), 2(Light Rave with Spotlight),\n3(Light Rave with Philly Glow), 4(Light Rave with Spotlight and Philly Glow),\n5(Heavy Rave), 6(Heavy Rave with Spotlight),\n7(Heavy Rave with Philly Glow), 8(Heavy Rave with Spotlight and Philly Glow)\nValue 2 can either be A or M for Auto and Manual toggle.\n\nFor now, the spotlight is automated, and same with\nPhilly Glow, but i'm working on it."],
		['gfScared', "Value 1 can be true or false."],
		['Freeze Notes', "Freeze The Notes Mid-Song"],
		['Funnie Window Tween', 'Ayo What The Window Doin?\nValue 1: X,Y\nValue 2: Time'],
		['Chrom Beat Effect', "Does The Chromatic Abberation Effect\nOn Every Beathit.\nSlow = Every 4 beats\nFast = Every 2 beats\nFaster = Every 1 beat\nslower = Every 8 beats\nMUST BE LOWER CASE!"],
		['Change Lyric', 'AYO LYRICS!?!?!?!?!?!?ASKJSD:LKHSFCHU:OSCHNFC:OUSJKL BFLJS BFHNIKKS FNCS CFL>SFBHPOIS FLJKSN\nValue 1 = Lyrics\nValue 2 = Color And Effect\nValue 2 Is Optional.\nEx. Value 1 = da lyric Value 2 = white,fadein'],
		['Enable or Disable Dad Trail', 'Can be either true or false.\nDon\'t ask what it does, you already know.'],
		['Enable or Disable BF Trail', 'Can be either true or false.\nDon\'t ask what it does, you already know.'],
		['Enable or Disable GF Trail', 'Can be either true or false.\nDon\'t ask what it does, you already know.'],
		['window shake', 'Value 1: How Much (Ex: 12,12), Value 2: How Long'],

	];

	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	public static var goToPlayState:Bool = false;
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;
	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	var _song:SwagSong;
	var _inital_state_song:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var tempBpm:Float = 0;
	var playbackSpeed:Float = 1;

	var extraTracks:Array<FlxSound> = [];
	var vocals:FlxSound = null;
	var opponentVocals:FlxSound = null;
	var gfVocals:FlxSound = null;
	var soundTracksMap:Map<String, FlxSound> = [];

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;
	
	var zoomTxt:FlxText;

	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		2,
		3,
		4,
		6,
		8,
		12,
		16,
		24
	];

	var curZoom:Int = 2;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;
	//public var quants:Array<Float> = [4,2,1];
	/**/
	 
	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];

	var text:String = "";
	public static var vortex:Bool = false;
	public var mouseQuant:Bool = false;
	var score1notes:Int = 0;
    var score1sus:Float = 0;
    var score2notes:Int = 0;
    var score2sus:Float = 0;
    var holds1:Int = 0;
    var holds2:Int = 0;
    var notes1:Int = 0;
    var notes2:Int = 0;
	var hurts1:Int = 0;
	var hurts2:Int = 0;
	var dupes:Int = 0;

	function refreshBalance():Void {
		dupes = 0;

		score1notes = 0;
		score1sus = 0;
		score2notes = 0;
		score2sus = 0;
		holds1 = 0;
		holds2 = 0;
		notes1 = 0;
		notes2 = 0;
		hurts1 = 0;
		hurts2 = 0;
		for (sec in _song.notes) {
			dupes += countDupes(sec);
			for (n in sec.sectionNotes) {
				var d:Int = Std.int(n[1]);
				if (d < 0 || d >= 8)
					continue;
				var m:String = "";
				if (n.length >= 4 && Std.string(n[3]) != "0")
					m = n[3];
				/*if (m not in mints1) {
					mints1[m] = 0;
					mints2[m] = 0;
				}
	
				if (Std.string(m) != "" && Std.string(m) not in data["hurts"]) {
					print("unknown note " + str(m) + " found! please set up unknown mints!")
					classifyMints()
				}*/
				
				if (sec.mustHitSection) {
					if (d < 4) {
						/*if (m != "" && Std.parseInt(data["hurts"][m]) >= 2:
							mints2[m] += 1
							continue*/
						if (m == "Hurt Note") {
							hurts2 += 1;
							continue;
						}
						notes2 += 1;
						score2notes += 200;
						if (n[2] > 0) {
							score2sus += n[2] * 0.05;
							score2notes += 100;
							holds2 += 1;
						}
					} else {
						if (m == "Hurt Note") {
							hurts1 += 1;
							continue;
						}
						notes1 += 1;
						score1notes += 200;
						if (n[2] > 0) {
							score1sus += n[2] * 0.05;
							score1notes += 100;
							holds1 += 1;
						}
					}
				} else {
					if (d < 4) {
						/*if (m != "" && Std.parseInt(data["hurts"][m]) >= 2:
							mints2[m] += 1
							continue*/
						if (m == "Hurt Note") {
							hurts1 += 1;
							continue;
						}
						notes1 += 1;
						score1notes += 200;
						if (n[2] > 0) {
							score1sus += n[2] * 0.05;
							score1notes += 100;
							holds1 += 1;
						}
					} else {
						if (m == "Hurt Note") {
							hurts2 += 1;
							continue;
						}
						notes2 += 1;
						score2notes += 200;
						if (n[2] > 0) {
							score2sus += n[2] * 0.05;
							score2notes += 100;
							holds2 += 1;
						}
					}
				}
			}
		}
		updateZoom();
	}

	function removeDupes() {
		// remove dupes
		for (sec in _song.notes) {
			var mario:Array<Dynamic> = [];
			for (n in sec.sectionNotes) {
				var good:Bool = true;
				for (j in mario) {
					if (n[1] == j[1] && Math.abs(n[0] - j[0]) <= 10) {
						//print("dupe found at " + str(n[0]));
						good = false;
						sec.sectionNotes.remove(j);
						break;
					}
				}

				if (good)
					mario.insert(-1, n);
			}
			// sec.sectionNotes = mario;
		}

		refreshBalance();
	}

	function countDupes(sec:SwagSection):Int {
		var mario:Array<Dynamic> = [];
		var total:Int = 0;
		for (n in sec.sectionNotes) {
			var good:Bool = true;
			for (j in mario) {
				if (n[1] == j[1] && Math.abs(n[0] - j[0]) <= 10) {
					total++;
					good = false;
					break;
				}
			}

			if (good)
				mario.insert(-1, n);
		}
		return total;
	}

	var notSaved:Bool = false;

	override function create()
	{
		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			Difficulty.resetList();

			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 180.0,
				needsVoices: true,
				extraTracks: [],
				arrowSkin: '',
				splashSkin: 'noteSplashes',//idk it would crash if i didn't
				player1: 'bf',
				player2: 'bf',
				player5: null,
				player4: null,
				gfVersion: 'gf',
				speed: 1,
				offset: 0,
				stage: 'portal',
				format: 'mixtape_v1',
				mania: Note.defaultMania,
				startMania: Note.defaultMania
			};
			Song.chartPath = null;
			addSection();
			PlayState.SONG = _song;
		}

		_inital_state_song = _song;

		// Paths.clearMemory();

		hitsound = new FlxSound();

		PlayState.mania = _song.mania;

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		var s_termination = "s";
		if (_song.mania == 0) s_termination = "";
		DiscordClient.changePresence("Mixtape Chart Editor", StringTools.replace(_song.song, '-', ' ') + " (" + (_song.mania + 1) + " key" + s_termination + ")");
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('editors/eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, -100);
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		if(curSec >= _song.notes.length) curSec = _song.notes.length - 1;

		Cursor.show();
		//FlxG.save.bind('funkin', 'ninjamuffin99');

		tempBpm = _song.bpm;

		addSection();

		// sections = _song.notes;

		updateJsonData();
		currentSongName = Paths.formatToSongPath(_song.song);
		loadSong();
		reloadGridLayer();
		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(10, 300, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		//strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		//add(strumLine);

		quant = new AttachedSprite('chart_quant','chart_quant');
		quant.animation.addByPrefix('q','chart_quant',0,false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...(Note.ammo[_song.mania] * 2)){
			var note:StrumNote = new StrumNote(GRID_SIZE * (i+1), strumLine.y, i % Note.ammo[_song.mania]);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2 + 120;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		text =
		"W/S or Mouse Wheel - Change Conductor's strum time
		\nA/D - Go to the previous/next section
		\nLeft/Right - Change Snap
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate
		\nHold Shift to move 4x faster
		\nHold Control and click on an arrow to select it
		\nZ/X - Zoom in/out
		\nT - Refresh Balance data
		\n(Unavailable) T + Control - Connect the current Note Tail to the next Note
		\n(Unavailable) T + Alt - Connect all Note Tails in the current section
		\nEsc - Test your chart inside Chart Editor
		\nEnter - Play your chart
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song
		\n(Hold) Control + C - Copy Section
		\n(Hold) Control + X - Cut Section
		\n(Hold) Control + V - Paste Section
		\n(Hold) Control + S - Save to Autosave
		\n(Hold) Control + Left/Right - Shift Selected Note";

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 8, 0, tipTextArray[i], 16);
			tipText.y += i * 12;
			tipText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
			//tipText.borderSize = 2;
			tipText.scrollFactor.set();
			add(tipText);
		}
		add(UI_box);

		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		updateWaveform();
		//UI_box.selected_tab = 4;

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName) {
			changeSection();
		}
		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1 / 1", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);
		refreshBalance();
		
		updateGrid();

		super.create();
	}

	var check_mute_inst:FlxUICheckBox = null;
	var check_mute_vocals:FlxUICheckBox = null;
	var check_mute_vocals_opponent:FlxUICheckBox = null;
	var check_mute_vocals_gf:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var UI_songTitle:FlxUIInputText;
	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;
	var stageDropDown:FlxUIDropDownMenu;
	var sliderRate:FlxUISlider;
	function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
                UI_songTitle.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(UI_songTitle);
		
		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has Voice Track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			//trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			updateJsonData();
			loadSong();
			updateWaveform();
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){loadJson(_song.song.toLowerCase()); }, null,ignoreWarnings));
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function()
		{
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
			MusicBeatState.resetState();
		});

		var loadEventJson:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{
			
			var songName:String = Paths.formatToSongPath(_song.song);
			var file:String = Paths.json(songName + '/events');
			#if sys
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson(songName + '/events')) || #end FileSystem.exists(file))
			#else
			if (OpenFlAssets.exists(file))
			#end
			{
				clearEvents();
				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;
				changeSection(curSec);
			}
		});

		var removeDupeButton:FlxButton = new FlxButton(loadEventJson.x, loadEventJson.y + 30, "Clear Dupes", function()
		{
			removeDupes();
		});

		var saveEvents:FlxButton = new FlxButton(110, reloadSongJson.y, 'Save Events', function ()
		{
			saveEvents();
		});

		var clear_events:FlxButton = new FlxButton(320, 310, 'Clear events', function()
			{
				openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null,ignoreWarnings));
			});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(320, clear_events.y + 30, 'Clear notes', function()
			{
				openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){for (sec in 0..._song.notes.length) {
					_song.notes[sec].sectionNotes = [];
				}
				refreshBalance();
				updateGrid();
			}, null,ignoreWarnings));
				
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, Math.POSITIVE_INFINITY, 3);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Mods.currentModDirectory + '/characters/'), Paths.getSharedPath('characters/')];
		for(mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/characters/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('characters/')];
		#end

		var tempArray:Array<String> = [];
		var characters:Array<String> = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
		for (character in characters)
		{
			if(character.trim().length > 0)
				tempArray.push(character);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(charToCheck.trim().length > 0 && !charToCheck.endsWith('-dead') && !tempArray.contains(charToCheck)) {
							tempArray.push(charToCheck);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end
		characters.insert(0, null);
		tempArray = [];

		var player1DropDown = new FlxUIDropDownMenu(10, stepperSpeed.y + 45, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var gfVersionDropDown = new FlxUIDropDownMenu(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.gfVersion = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);

		var player2DropDown = new FlxUIDropDownMenu(player1DropDown.x, gfVersionDropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		var player4DropDown = new FlxUIDropDownMenu(player2DropDown.x + 140, player2DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player4 = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});
		player4DropDown.selectedLabel = _song.player4;
		blockPressWhileScrolling.push(player4DropDown);

		var player5DropDown = new FlxUIDropDownMenu(player4DropDown.x + 20, player4DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player5 = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});
		player5DropDown.selectedLabel = _song.player5;
		blockPressWhileScrolling.push(player5DropDown);

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Mods.currentModDirectory + '/stages/'), Paths.getSharedPath('stages/')];
		for(mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/stages/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('stages/')];
		#end

		var stageFile:Array<String> = Mods.mergeAllTextsNamed('data/stageList.txt', Paths.getSharedPath());
		var stages:Array<String> = [];
		for (stage in stageFile) {
			if(stage.trim().length > 0) {
				stages.push(stage);
			}
			tempArray.push(stage);
		}
		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var stageToCheck:String = file.substr(0, file.length - 5);
						if(stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck)) {
							tempArray.push(stageToCheck);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end

		if(stages.length < 1) stages.push('stage');

		stageDropDown = new FlxUIDropDownMenu(player1DropDown.x + 140, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(character:String)
		{
			_song.stage = stages[Std.parseInt(character)];
		});
		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		if (Difficulty.list.length <= 0 || Difficulty.list == []) Difficulty.list = Difficulty.defaultList;
		var difficultyDropDown = new FlxUIDropDownMenu(stageDropDown.x, player1DropDown.y + 40,
			FlxUIDropDownMenu.makeStrIdLabelArray(Difficulty.list, true), function(difficulty:String)
		{
			PlayState.storyDifficulty = 0;
			try
			{
				PlayState.SONG = Song.loadFromJson(_song.song.toLowerCase() + '-' + Difficulty.list[Std.parseInt(difficulty)].toLowerCase(), _song.song.toLowerCase());
				MusicBeatState.resetState();
			}
			catch (e:Any)
			{
				trace("File " + _song.song.toLowerCase() + Difficulty.getString(Std.parseInt(difficulty)) + " is not found.");
			}
		});
		if (Difficulty.list != null)
			difficultyDropDown.selectedLabel = Difficulty.list[PlayState.storyDifficulty];
		else
			difficultyDropDown.selectedLabel = Difficulty.list[PlayState.storyDifficulty];
		blockPressWhileScrolling.push(difficultyDropDown);


		var skin = PlayState.SONG.arrowSkin;
		if(skin == null) skin = '';
		noteSkinInputText = new FlxUIInputText(player2DropDown.x, player2DropDown.y + 50, 150, skin, 8);
		noteSkinInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(noteSkinInputText);

		var stepperMania:FlxUINumericStepper = new FlxUINumericStepper(73, stepperSpeed.y, 1, 3, Note.minMania, Note.maxMania, 1);
		stepperMania.value = _song.mania;
		stepperMania.name = 'mania';
		blockPressWhileTypingOnStepper.push(stepperMania);

		var stepperStartMania:FlxUINumericStepper = new FlxUINumericStepper(140, stepperSpeed.y, 1, 3, Note.minMania, Note.maxMania, 1);
		stepperStartMania.value = _song.startMania;
		stepperStartMania.name = 'startMania';
		blockPressWhileTypingOnStepper.push(stepperStartMania);
	
		noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x, noteSkinInputText.y + 35, 150, _song.splashSkin, 8);
		noteSplashesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(noteSplashesInputText.x + 5, noteSplashesInputText.y + 20, 'Change Notes', function() {
			_song.arrowSkin = noteSkinInputText.text;
			refreshBalance();
			updateGrid();
		});

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(removeDupeButton);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperMania);
		tab_group_song.add(stepperStartMania);
		tab_group_song.add(reloadNotesButton);
		tab_group_song.add(noteSkinInputText);
		tab_group_song.add(noteSplashesInputText);
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperBPM.x + 100, stepperBPM.y - 15, 0, 'Song Offset:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(stepperMania.x, stepperMania.y - 15, 0, 'Mania:'));
		tab_group_song.add(new FlxText(stepperStartMania.x, stepperStartMania.y - 15, 0, 'Start Mania:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'P2 (Opponent):'));
		tab_group_song.add(new FlxText(player4DropDown.x, player4DropDown.y - 15, 0, 'P4 (Opponent 2):'));
		tab_group_song.add(new FlxText(player5DropDown.x, player5DropDown.y - 15, 0, 'P5 (BF 2):'));
		tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'P3 (Girlfriend):'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'P1 (Player):'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		tab_group_song.add(new FlxText(difficultyDropDown.x, difficultyDropDown.y - 15, 0, 'Difficulty:'));
		tab_group_song.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		tab_group_song.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_song.add(player2DropDown);
		tab_group_song.add(player4DropDown);
		tab_group_song.add(player5DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(stageDropDown);
		tab_group_song.add(difficultyDropDown);

		UI_box.addGroup(tab_group_song);

		initPsychCamera().follow(camPos, LOCKON, 999);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_exSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	
	
	// // Starting BPM Numeric Stepper
	// var bpmTweenStart:FlxUINumericStepper = new FlxUINumericStepper(10, yPos, 60, 100, 300, 1, "Start BPM", 120);
	// add(bpmTweenStart);
	
	// // Ending BPM Numeric Stepper
	// var bpmTweenEnd:FlxUINumericStepper = new FlxUINumericStepper(10, yPos + 35, 60, 100, 300, 1, "End BPM", 120);
	// add(bpmTweenEnd);
	
	// // Duration Numeric Stepper (for beats or bars)
	// var bpmTweenDuration:FlxUINumericStepper = new FlxUINumericStepper(10, yPos + 70, 1, 1, 16, 1, "Duration (Beats/Bars)", 4);
	// add(bpmTweenDuration);
	
	// // Beats/Bars Toggle (optional, depending on your design)
	// var beatsBarsToggle:FlxUICheckBox = new FlxUICheckBox(10, yPos + 105, "Use Bars", null, true);
	// add(beatsBarsToggle);

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new FlxUICheckBox(10, check_mustHitSection.y + 22, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;

		check_exSection = new FlxUICheckBox(check_gfSection.x + 120, check_gfSection.y, null, null, "EX section", 100);
		check_exSection.name = 'check_ex';
		check_exSection.checked = _song.notes[curSec].exSection;

		check_altAnim = new FlxUICheckBox(check_exSection.x, check_gfSection.y + 22, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;
		
		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 99, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 3);
		if(check_changeBPM.checked) {
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		} else {
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;
		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function()
		{
			copyNotes();
		});
	
		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function()
		{
			pasteNotes(check_eventsSec.checked, check_notesSec.checked);
		});

		var cutButton:FlxButton = new FlxButton(10, pasteButton.y + 40, "Cut Section", function()
		{
			copyNotes();
			clearNotes();
		});
		cutButton.color = FlxColor.YELLOW;
		cutButton.label.color = FlxColor.WHITE;

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function()
		{
			if(check_notesSec.checked)
			{
				_song.notes[curSec].sectionNotes = [];
			}

			if(check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while(i > -1) {
					var event:Array<Dynamic> = _song.events[i];
					if(event != null && endThing > event[0] && event[0] >= startThing)
					{
						_song.events.remove(event);
					}
					--i;
				}
			}
			refreshBalance();
			updateGrid();
			updateNoteUI();
		});

		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;
		
		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function()
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + Note.ammo[_song.mania]) % (Note.ammo[_song.mania] * 2);
				_song.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
		});

		var stepperCopy:FlxUINumericStepper = null;
		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function()
		{
			var value:Int = Std.int(stepperCopy.value);
			if(value == 0) return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);


				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			refreshBalance();
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();
		
		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob > _song.mania){
					boob -= Note.ammo[_song.mania];
				}else{
					boob += Note.ammo[_song.mania];
				}
				
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}
			
			for (i in duetNotes){
			_song.notes[curSec].sectionNotes.push(i);
				
			}
			refreshBalance();
			updateGrid();
		});
		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % Note.ammo[_song.mania];
				boob = _song.mania - boob;
				if (note[1] > _song.mania) boob += Note.ammo[_song.mania];
				
				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				//duetNotes.push(copiedNote);
			}
			
			for (i in duetNotes){
			//_song.notes[curSec].sectionNotes.push(i);
				
			}
			refreshBalance();
			updateGrid();
		});
		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		var stepperSectionJump:FlxUINumericStepper = new FlxUINumericStepper(130, copyButton.y + 63, 1, 0, 0, 9999, 0);
		blockPressWhileTypingOnStepper.push(stepperSectionJump);

		var jumpSection:FlxButton = new FlxButton(110, copyButton.y + 40, "Jump Section", function()
		{
			var value:Int = Std.int(stepperSectionJump.value);
			changeSection(value);
		});

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 15, 0, 'Beats per Section:'));
		//tab_group_section.add(new FlxText(70, 10, 0, 'Step Length'));
		tab_group_section.add(stepperSectionJump);
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_exSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(jumpSection);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(cutButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; //I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenu;
	var currentType:Int = 0;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		while (key < noteTypeList.length) {
			curNoteTypes.push(noteTypeList[key]);
			key++;
		}

		#if sys
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'custom_notetypes/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				var fileName:String = file.toLowerCase().trim();
				var wordLen:Int = 4; //length of word ".lua" and ".txt";
				if((#if LUA_ALLOWED fileName.endsWith('.lua') || #end
					#if HSCRIPT_ALLOWED (fileName.endsWith('.hx') && (wordLen = 3) == 3) || #end
					fileName.endsWith('.txt')) && fileName != 'readme.txt')
				{
					var fileToCheck:String = file.substr(0, file.length - wordLen);
					if(!curNoteTypes.contains(fileToCheck))
					{
						curNoteTypes.push(fileToCheck);
						key++;
					}
				}
			}
		#end


		var displayNameList:Array<String> = curNoteTypes.copy();
		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FlxUIDropDownMenu(10, 105, FlxUIDropDownMenu.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = curNoteTypes[currentType];
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}
	

	var eventDropDown:FlxUIDropDownMenu;
	var descText:FlxText;
	var selectedEventText:FlxText;
	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		directories.push(Paths.getLibraryPath('custom_events/'));
		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
		for(mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_events/'));
		#end

		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenu(20, 50, FlxUIDropDownMenu.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
				if (curSelectedNote != null &&  eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null){
				curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
					
				}
				updateGrid();
			}
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUIInputText(20, 110, 100, "");
		//value1InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUIInputText(20, 150, 100, "");
		//value2InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if(curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;
				
				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);
			
		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);
			
		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);
			
		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}

	function changeEventSelected(change:Int = 0)
	{
		if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}
	
	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	var waveformTrackDropDown:FlxUIDropDownMenu;
	var waveformTrack:Null<FlxSound> = null;
	var trackVolumeSlider:FlxUISlider;
	function selectTrack(trackName:String){
		waveformTrack = soundTracksMap.get(trackName); 

		if (waveformTrack != null){
			trackVolumeSlider.value = waveformTrack.volume;
			trackVolumeSlider.visible = true;
		/*}else{
			trackVolumeSlider.visible = false;*/
		}
		
		updateWaveform();
	}

	function changeSelectedTrackVolume(val:Float)
	{
		if (waveformTrack != null)
			waveformTrack.volume = val;
		/*else
			trace("Erm. No track is selected!");*/
		
		trackVolumeSlider.value = val;
	}

	var metronome:FlxUICheckBox;
	var mouseScrollingQuant:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var voicesOppVolume:FlxUINumericStepper;
	var voicesgfVolume:FlxUINumericStepper;
	var hitVolume:FlxUINumericStepper;
	function addChartingUI() {
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		var trackNamesArray = ["None"];
		for (trackName in soundTracksMap.keys())
			trackNamesArray.push(trackName);

		waveformTrackDropDown = new FlxUIDropDownMenu(
			10, 90, 
			FlxUIDropDownMenu.makeStrIdLabelArray(trackNamesArray, false), 
			selectTrack
		);
		waveformTrackDropDown.selectedId = "None"; //curSelectedTrackName;
		blockPressWhileScrolling.push(waveformTrackDropDown);

		trackVolumeSlider = new FlxUISlider(
			this, 
			'_curTrackVolume', 
			waveformTrackDropDown.x + 150 - 10, 
			waveformTrackDropDown.y - 15, 
			0.0, 
			1.0, 
			Math.floor(waveformTrackDropDown.width), 
			null, 
			5, 
			FlxColor.WHITE, 
			FlxColor.BLACK
		);
		trackVolumeSlider.nameLabel.text = 'Track Volume';
		trackVolumeSlider.setVariable = false;
		trackVolumeSlider.callback = changeSelectedTrackVolume;
		trackVolumeSlider.value = 1.0;

		check_mute_inst = new FlxUICheckBox(10, 280, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new FlxUICheckBox(10, 190, null, null, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.callback = function()
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.callback = function()
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		};
		
		check_warnings = new FlxUICheckBox(10, 130, null, null, "Ignore Progress Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		check_mute_vocals = new FlxUICheckBox(check_mute_inst.x, check_mute_inst.y + 30, null, null, "Mute Main Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			var vol:Float = voicesVolume.value;
			if (check_mute_vocals.checked)
				vol = 0;

			if(vocals != null) vocals.volume = vol;
		};
		check_mute_vocals_opponent = new FlxUICheckBox(check_mute_vocals.x + 120, check_mute_vocals.y, null, null, "Mute Opp. Vocals (in editor)", 100);
		check_mute_vocals_opponent.checked = false;
		check_mute_vocals_opponent.callback = function()
		{
			var vol:Float = voicesOppVolume.value;
			if (check_mute_vocals_opponent.checked)
				vol = 0;

			if(opponentVocals != null) opponentVocals.volume = vol;
		};
		check_mute_vocals_gf = new FlxUICheckBox(check_mute_vocals_opponent.x, check_mute_inst.y, null, null, "Mute GF Vocals (in editor)", 100);
		check_mute_vocals_gf.checked = false;
		check_mute_vocals_gf.callback = function()
		{
			var vol:Float = voicesgfVolume.value;
			if (check_mute_vocals_gf.checked)
				vol = 0;

			if(gfVocals != null) gfVocals.volume = vol;
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100,
			function() {
				FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100,
			function() {
				FlxG.save.data.chart_metronome = metronome.checked;
			}
		);
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);
		
		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120,
			function() {
				FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
			}
		);
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		/*hitVolume = new FlxUINumericStepper(voicesVolume.x + 100, voicesVolume.y, 0.1, 1, 0, 2, 1);
		hitVolume.value = hitsound.volume;
		hitVolume.name = 'hit_volume';
		blockPressWhileTypingOnStepper.push(hitVolume);*/
		
		#if !html5
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 130, 0.5, 3, 150, null, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		//tab_group_chart.add(new FlxText(hitVolume.x, hitVolume.y - 15, 0, 'Hitsound Volume'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		//tab_group_chart.add(hitVolume);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);

		tab_group_chart.add(new FlxText(waveformTrackDropDown.x, waveformTrackDropDown.y - 15, 0, "Track"));
		tab_group_chart.add(waveformTrackDropDown);
		tab_group_chart.add(trackVolumeSlider);
		UI_box.addGroup(tab_group_chart);
	}

	function loadSong():Void
	{
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
			// vocals.stop();

		if (_song.extraTracks != null && _song.extraTracks.length > 0)
		{
			for (trackName in _song.extraTracks){
				var file:Dynamic = Paths.track(currentSongName, trackName);

				if (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)) {
					var newTrack = new FlxSound();

					soundTracksMap.set(
						trackName, 
						newTrack.loadEmbedded(file)
					);
					extraTracks.push(newTrack);
					FlxG.sound.list.add(newTrack);
				}
			}
		}

		if(vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		if(opponentVocals != null)
		{
			opponentVocals.stop();
			opponentVocals.destroy();
		}
		if(gfVocals != null)
		{
			gfVocals.stop();
			gfVocals.destroy();
		}

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		gfVocals = new FlxSound();

		var file:Dynamic = Paths.voices(_song.song, (characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'player' : characterData.vocalsP1);
		try
		{
			soundTracksMap.set(
				"Vocals", 
				vocals.loadEmbedded(file != null ? file : Paths.voices(PlayState.SONG.song))
			);
			FlxG.sound.list.add(vocals);
		}catch (e:Dynamic) {
			vocals = null;
		}
		var file:Dynamic = Paths.voices(_song.song, (characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'opponent' : characterData.vocalsP2);
		if (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)) {
			soundTracksMap.set(
				"Opponent Vocals", 
				opponentVocals.loadEmbedded(file)
			);
			FlxG.sound.list.add(opponentVocals);
		}else{
			opponentVocals = null;
		}
		var file:Dynamic = Paths.voices(_song.song, 'gf');
		if (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)) {
			soundTracksMap.set(
				"GF Vocals", 
				gfVocals.loadEmbedded(file)
			);
			FlxG.sound.list.add(gfVocals);
		}else{
			gfVocals = null;
		}
		soundTracksMap.set("Inst", FlxG.sound.music);

		/*if (_song.needsVoices)
		{
			try
			{
				var playerVocals = Paths.voices(_song.song, (characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'player' : characterData.vocalsP1);
				vocals.loadEmbedded(Paths.voices(_song.song));
				vocals.autoDestroy = false;
				FlxG.sound.list.add(vocals);
			}
			catch(e) {trace('ERR: '+e);}

			if (_song.newVoiceStyle)
			{
				try
				{
					var oppVocals = Paths.voices(_song.song, (characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'opponent' : characterData.vocalsP2);
					if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
					opponentVocals.autoDestroy = false;
					FlxG.sound.list.add(opponentVocals);
				}
				catch(e) {}

				try
				{
					var gfVoc = Paths.voices(_song.song, 'gf');
					if(gfVoc != null) gfVocals.loadEmbedded(gfVoc);
					opponentVocals.autoDestroy = false;
					FlxG.sound.list.add(opponentVocals);
				}
				catch(e) {}
			}
		}*/

		try 
		{
			if (_song.needsVoices)
			{
				var playerVocals = Paths.voices(_song.song, (characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'player' : characterData.vocalsP1);
				if(playerVocals != null) 
				{
					vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(_song.song));
					FlxG.sound.list.add(vocals);
				}

				var oppVocals = Paths.voices(_song.song, (characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'opponent' : characterData.vocalsP2);
				if(oppVocals != null) 
				{
					opponentVocals.loadEmbedded(oppVocals != null ? oppVocals : Paths.music('empty'));
					FlxG.sound.list.add(opponentVocals);
				}

				var gfVoc = Paths.voices(_song.song, (characterData.vocalsP3 == null || characterData.vocalsP3.length < 1) ? 'gf' : characterData.vocalsP3);
				if(gfVoc != null) 
				{
					gfVocals.loadEmbedded(gfVoc != null ? gfVoc : Paths.music('empty'));
					FlxG.sound.list.add(gfVocals);
				}
			}
			else if (_song.needsVoices)
			{
				var playerVocals = Paths.voices(_song.song);
				if(playerVocals != null) 
				{
					vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(_song.song));
					FlxG.sound.list.add(vocals);
				}
			}
		}
		catch(e) {}

		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;

		var curTime:Float = 0;
		//trace(_song.notes.length);
		if(_song.notes.length <= 1) //First load ever
		{
			trace('first load ever!!');
			while(curTime < FlxG.sound.music.length)
			{
				addSection();
				curTime += (60 / _song.bpm) * 4000;
			}
		}
	}

	var playtesting:Bool = false;
	var playtestingTime:Float = 0;
	var playtestingOnComplete:Void->Void = null;
	override function closeSubState()
	{
		if(playtesting)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = playtestingTime;
			FlxG.sound.music.onComplete = playtestingOnComplete;
			if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
			if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

			if(vocals != null)
			{
				vocals.pause();
				vocals.time = playtestingTime;
				if (voicesVolume != null) vocals.volume = voicesVolume.value;
				if (check_mute_vocals != null && check_mute_vocals.checked) vocals.volume = 0;
			}

			if(opponentVocals != null)
			{
				opponentVocals.pause();
				opponentVocals.time = playtestingTime;
				if (voicesOppVolume != null) opponentVocals.volume = voicesOppVolume.value;
				if (check_mute_vocals_opponent != null && check_mute_vocals_opponent.checked) opponentVocals.volume = 0;
			}

			if(gfVocals != null)
			{
				gfVocals.pause();
				gfVocals.time = playtestingTime;
				if (voicesgfVolume != null) gfVocals.volume = voicesgfVolume.value;
				if (check_mute_vocals_gf != null && check_mute_vocals_gf.checked) gfVocals.volume = 0;
			}

			#if DISCORD_ALLOWED
			// Updating Discord Rich Presence
			var s_termination = "s";
			if (_song.mania == 0) s_termination = "";
			DiscordClient.changePresence("Mixtape Chart Editor", StringTools.replace(_song.song, '-', ' ') + " (" + (_song.mania + 1) + " key" + s_termination + ")");
			#end
		}
		super.closeSubState();
	}

	function generateSong() {
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6/*, false*/);
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			if(opponentVocals != null) {
				opponentVocals.pause();
				opponentVocals.time = 0;
			}
			if(gfVocals != null) {
				gfVocals.pause();
				gfVocals.time = 0;
			}
			for (track in extraTracks){
				track.pause();
				track.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			if(vocals != null) vocals.play();
			if(opponentVocals != null) opponentVocals.play();
			if(gfVocals != null) gfVocals.play();
			for (track in extraTracks) track.play();
		};
	}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSec].mustHitSection = check.checked;

					updateGrid();
					updateHeads();

				case 'GF section':
					_song.notes[curSec].gfSection = check.checked;

					updateGrid();
					updateHeads();

				case 'EX section':
					_song.notes[curSec].exSection = check.checked;

					updateGrid();
					updateHeads();

				case 'Change BPM':
					_song.notes[curSec].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
					

				case "Alt Animation":
					_song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_beats')
			{
				_song.notes[curSec].sectionBeats = nums.value;
				reloadGridLayer();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'mania')
			{
				_song.mania = Std.int(nums.value);
				PlayState.mania = _song.mania;
				reloadGridLayer();
			}
			else if (wname == 'startMania')
			{
				_song.startMania = Std.int(nums.value);
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.bpm = nums.value;
			}
			else if (wname == 'note_susLength')
			{
				if(curSelectedNote != null && curSelectedNote[2] != null) {
					curSelectedNote[2] = nums.value;
					updateGrid();
				}
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSec].bpm = nums.value;
				updateGrid();
			}
			/*else if (wname == 'hit_volume')
			{
				hitsound.volume = nums.value;
				//FlxG.sound.volume = nums.value;
			}*/
		}
		else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == noteSplashesInputText) {
				_song.splashSkin = noteSplashesInputText.text;
			}
			else if(curSelectedNote != null)
			{
				if(sender == value1InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if(sender == value2InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if(sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = Std.int(sliderRate.value);
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (_song.notes[curSec].changeBPM)
				return _song.notes[curSec].sectionBeats * (_song.notes[curSec].bpm / _song.bpm);
			else
				return _song.notes[curSec].sectionBeats;
	}*/
	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if(_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		PlayState.mania = _song.mania;

		var gWidth = GRID_SIZE * (Note.ammo[_song.mania] * 2);
		camPos.x = -80 + gWidth;
		strumLine.width = gWidth;
		rightIcon.x = gWidth / 2 + GRID_SIZE * 2;

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...strumLineNotes.members.length){
			strumLineNotes.members[i].y = strumLine.y;
		}

		Cursor.show();//cause reasons. trust me
		camPos.y = strumLine.y;
		
		if(!disableAutoScrolling.checked) {
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				if (_song.notes[curSec + 1] == null)
				{
					addSection();
				}

				changeSection(curSec + 1, false);
			} else if(strumLine.y < -10) {
				changeSection(curSec - 1, false);
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);


		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} else {
			dummyArrow.visible = false;
		}

		if (_inital_state_song != _song){
			notSaved = true;
		} else{
			notSaved = false;
		}

		if (FlxG.mouse.overlaps(curRenderedNotes) && !FlxG.mouse.justPressed) Cursor.cursorMode = Pointer	;

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				Cursor.cursorMode = Grabbing;
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							curSelectedNote[3] = curNoteTypes[currentType];
							updateGrid();
						}
						else
						{
							//trace('tryin to delete note...');
							deleteNote(note);
						}
					}
				});
			}
			else
				{
					if (FlxG.mouse.x > gridBG.x
						&& FlxG.mouse.x < gridBG.x + gridBG.width
						&& FlxG.mouse.y > gridBG.y
						&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
					{
						FlxG.log.add('added note');
						addNote();
					}
				}
		}

		if (FlxG.mouse.justPressedRight)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				Cursor.cursorMode = Grabbing;
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						selectNote(note);
						curSelectedNote[3] = curNoteTypes[0];
						updateGrid();
					}
				});
			}
		}


		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = FirstCheckState.muteKeys;
			FlxG.sound.volumeDownKeys = FirstCheckState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = FirstCheckState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				if(FlxG.sound.music != null)
					FlxG.sound.music.stop();

				if(vocals != null)
				{
					vocals.pause();
					vocals.volume = 0;
				}
				if(opponentVocals != null)
				{
					opponentVocals.pause();
					opponentVocals.volume = 0;
				}
				if(gfVocals != null)
				{
					gfVocals.pause();
					gfVocals.volume = 0;
				}
				autosaveSong();
				playtesting = true;
				playtestingTime = Conductor.songPosition;
				playtestingOnComplete = FlxG.sound.music.onComplete;
				openSubState(new states.editors.EditorPlayState(playbackSpeed));
			}
			else if (FlxG.keys.justPressed.ENTER)
			{
				autosaveSong();
				Cursor.hide();
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if(vocals != null) vocals.stop();
				if(opponentVocals != null) opponentVocals.stop();
				if(gfVocals != null) gfVocals.stop();
				//if(_song.stage == null) _song.stage = stageDropDown.selectedLabel;
				StageData.loadDirectory(_song);
				LoadingState.loadAndSwitchState(new PlayState());
			}

			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}


			if (FlxG.keys.justPressed.BACKSPACE) {
				PlayState.chartingMode = false;
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('panixPress'));
				Cursor.hide();
				return;
			}



			if(FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL) {
				--curZoom;
				updateZoom();
			}
			if(FlxG.keys.justPressed.X && curZoom < zoomList.length-1 && !FlxG.keys.pressed.CONTROL) {
				curZoom++;
				updateZoom();
			}
			else if (FlxG.keys.justPressed.X && FlxG.keys.pressed.CONTROL)
			{
				copyNotes();
				clearNotes();
			}
			if(FlxG.keys.justPressed.T) {
				refreshBalance();
			}

			/*if(FlxG.keys.justPressed.T && FlxG.keys.pressed.CONTROL) {
				connectSelectedNoteTail();
			}

			if(FlxG.keys.justPressed.T && FlxG.keys.pressed.ALT) {
				connectAllNoteTailsInSection();
			}*/

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 4;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 5)
						UI_box.selected_tab = 0;
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if(vocals != null) vocals.play();
				if(opponentVocals != null) opponentVocals.play();
				if(gfVocals != null) gfVocals.play();
				pauseAndSetVocalsTime();
				if (!FlxG.sound.music.playing)
				{
					FlxG.sound.music.play();
					if(vocals != null) vocals.play();
					if(opponentVocals != null) opponentVocals.play();
					if(gfVocals != null) gfVocals.play();
					for (track in extraTracks){
						track.pause();
						track.time = FlxG.sound.music.time;
						track.play(false, FlxG.sound.music.time);
					}
				}
				else
				{
					FlxG.sound.music.pause();
					for (track in extraTracks) track.pause();
				}
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				for (track in extraTracks) track.pause();
				if (!mouseQuant)
					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet*0.8);
				else
				{
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.mouse.wheel > 0)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					} else {
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
				pauseAndSetVocalsTime();
			}

			if (FlxG.keys.pressed.V && FlxG.keys.pressed.CONTROL) pasteNotes(true, true);

			if (FlxG.keys.pressed.C && FlxG.keys.pressed.CONTROL) copyNotes();

			//ARROW VORTEX SHIT NO DEADASS



			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();
				for (track in extraTracks){
					track.pause();
					track.time = FlxG.sound.music.time;
				}

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				FlxG.sound.music.time += daTime * (FlxG.keys.pressed.W ? -1 : 1);

				pauseAndSetVocalsTime();
			}

			if(!vortex){
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN  )
				{
					FlxG.sound.music.pause();
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; //(Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; //(Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style = currentType;

			if (FlxG.keys.pressed.SHIFT){
				style = 3;
			}

			var conductorTime = Conductor.songPosition; //+ sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

			//AWW YOU MADE IT SEXY <3333 THX SHADMAR

			if(!blockInput){
				if(FlxG.keys.justPressed.RIGHT){
					curQuant++;
					if(curQuant>quantizations.length-1)
						curQuant = 0;

					quantization = quantizations[curQuant];
				}

				if(FlxG.keys.justPressed.LEFT){
					curQuant--;
					if(curQuant<0)
						curQuant = quantizations.length-1;

					quantization = quantizations[curQuant];
				}
				quant.animation.play('q', true, false, curQuant);
			}
			if(vortex && !blockInput){
				var controlArray:Array<Bool> = [false];

				if(controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if(controlArray[i])
							doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					for (track in extraTracks) track.pause();


					updateCurStep();
					//FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;

						//(Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;//snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; //(Math.floor((beat+snap) / snap) * snap);
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time:feces}, 0.1, {ease:FlxEase.circOut});
					pauseAndSetVocalsTime();

					var dastrum = 0;

					if (curSelectedNote != null){
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); //idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [false];

						if(controlArray.contains(true))
						{

							for (i in 0...controlArray.length)
							{
								if(controlArray[i])
									if(curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.D)
				changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A) {
				if(curSec <= 0) {
					changeSection(_song.notes.length-1);
				} else {
					changeSection(curSec - shiftThing);
				}
			}
		} else if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...blockPressWhileTypingOn.length) {
				if(blockPressWhileTypingOn[i].hasFocus) {
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		_song.bpm = tempBpm;

		strumLineNotes.visible = quant.visible = vortex;

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...strumLineNotes.members.length){
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		if(vocals != null) vocals.pitch = playbackSpeed;
		if(opponentVocals != null) opponentVocals.pitch = playbackSpeed;
		if(gfVocals != null) gfVocals.pitch = playbackSpeed;
		for (track in extraTracks) track.pitch = playbackSpeed;

		var curTime:Float = Conductor.songPosition - ClientPrefs.data.noteOffset;
		if(curTime < 0) curTime = 0;
		var songPercent:Float = 0;
		songPercent = (curTime / FlxG.sound.music.length * playbackSpeed);
		var secondsTotal:Int = Math.floor(curTime / 1000  * playbackSpeed);
		if(secondsTotal < 0) secondsTotal = 0;

		bpmTxt.text =
		"Song Name: " + _song.song + (notSaved ? "*" : "") +
		"\nMania: " + _song.mania +
		"\nStart Mania: " + _song.startMania +
		"\nTime: " + FlxStringUtil.formatTime(secondsTotal, false) + " / " + FlxStringUtil.formatTime(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2), false) +
		"\n" + Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
		"\n\nSection: " + curSec +
		"\nBeat: " + Std.string(curDecBeat).substring(0,4) +
		"\nStep: " + curStep +
		"\nBeat Snap: " + quantization + "th" + 
		"\n\nSong BPM: " + _song.bpm + 
		"\nScroll Speed: " + _song.speed +
		"\n\nBF: " + _song.player1 +
		"\nDAD: " + _song.player2 + 
		"\nGF: " + _song.gfVersion +
		"\nDAD 2: " + _song.player4 + 
		"\nBF 2: " + _song.player5 + 
		"\n\nStage: " + _song.stage;

		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			note.updateHitbox();
			if(curSelectedNote != null) {
				var noteDataToCheck:Int = note.noteData;
				if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.ammo[_song.mania];

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) {
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData % Note.ammo[_song.mania];
					if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.ammo[_song.mania];
						strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
						strumLineNotes.members[noteDataToCheck].resetAnim = (note.sustainLength / 1000) + 0.15;
					if(!playedSound[data]) {
						if((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress)){
							var soundToPlay = 'hitsound';
							if(_song.player1 == 'gf') { //Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);
							}

							hitsound.loadEmbedded(Paths.sound(soundToPlay));//would be coolio);
							FlxG.sound.list.add(hitsound);
							hitsound.pan = note.noteData < Note.ammo[_song.mania]? -0.3 : 0.3;
							hitsound.volume = 0.5;
							hitsound.play(true);
							playedSound[data] = true;
						}

						data = note.noteData;
						if(note.mustPress != _song.notes[curSec].mustHitSection)
						{
							data += 4;
						}
					}
				}
			}
		});

		if(metronome.checked && lastConductorPos != Conductor.songPosition) {
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if(metroStep != lastMetroStep) {
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
				//trace('Ticked');
			}
		}
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function pauseAndSetVocalsTime()
	{
		if(vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}

		if(opponentVocals != null)
		{
			opponentVocals.pause();
			opponentVocals.time = FlxG.sound.music.time;
		}

		if(gfVocals != null)
		{
			gfVocals.pause();
			gfVocals.time = FlxG.sound.music.time;
		}
	}

	function updateZoom() {
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if(daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';
		zoomTxt.text = 'Zoom: ' + zoomThing +
		"\n\n\nNote Balance:" +
		"\n\nNotes: " + notes1 + " / " + notes2 + " (" + (notes2 - notes1) + ")" +
		"\nLifts: " + holds1 + " / " + holds2 +  " (" + (holds2 - holds1) + ")" +
		"\nSustain: " + Math.round(score1sus) + " / " + Math.round(score2sus) +  " (" + Math.round(score2sus - score1sus) + ")" +
		"\nHurts: " + hurts1 + " / " + hurts2 +  " (" + (hurts2 - hurts1) + ")" +
		"\n\nDupes in this section: " + countDupes(_song.notes[curSec]) +
		"\nDupes total: " + dupes +
		"\nBalance code by Sketchie";
		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	function reloadGridLayer() {
		GRID_SIZE = Note.gridSizes[_song.mania];

		PlayState.mania = _song.mania;

		if (dummyArrow != null){
			dummyArrow.setGraphicSize(GRID_SIZE, GRID_SIZE);
			dummyArrow.updateHitbox();	
		}

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		var s_termination = "s";
		if (_song.mania == 0) s_termination = "";
		DiscordClient.changePresence("Mixtape Chart Editor", StringTools.replace(_song.song, '-', ' ') + " (" + (_song.mania + 1) + " key" + s_termination + ")");
		#end

		gridLayer.clear();
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE + GRID_SIZE * Note.ammo[_song.mania] * 2, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]));

		var oneHalf:Float = GRID_SIZE * Note.ammo[_song.mania];
		leftIcon.setPosition((oneHalf / 2) - (leftIcon.width / 2), -100);
		rightIcon.setPosition(((oneHalf * 2) - (oneHalf / 2)) - (rightIcon.width / 2), -100);

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE + GRID_SIZE * Note.ammo[_song.mania] * 2, leHeight + Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));
			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = gridBG.height;
		
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if(foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height).makeGraphic(Std.int(GRID_SIZE + GRID_SIZE * Note.ammo[_song.mania] * 2), Std.int(nextGridBG.height), FlxColor.BLACK);
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * Note.ammo[_song.mania])).makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);

		for (i in 1...4) {
			var beatsep1:FlxSprite = new FlxSprite(gridBG.x, (GRID_SIZE * (4 * curZoom)) * i).makeGraphic(Std.int(gridBG.width), 1, 0x44FF0000);
			if(vortex)
			{
				gridLayer.add(beatsep1);
			}
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);

		/*if (strumLine != null) */remove(strumLine);
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE + GRID_SIZE * Note.ammo[_song.mania] * 2), 4);
		add(strumLine);

		if (strumLineNotes != null)
		{
			strumLineNotes.clear();
			for (i in 0...(Note.ammo[_song.mania] * 2)){
				var note:StrumNote = new StrumNote(GRID_SIZE * (i+1), strumLine.y, i % Note.ammo[_song.mania]);
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.playAnim('static', true);
				strumLineNotes.add(note);
				note.scrollFactor.set(1, 1);
			}
		}

		updateGrid();
		#if desktop
		updateWaveform();
		#end

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
	}

	function strumLineUpdateY()
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	function updateWaveform() {
		#if desktop
		if(waveformPrinted) {
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * (Note.ammo[_song.mania] * 2)), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if (waveformTrack == null)
		{
			//trace("No track selected.");
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];
		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);
		
		var sound:FlxSound = waveformTrack;

		if (sound != null && sound._sound != null && sound._sound.__buffer != null) {
			var bytes:Bytes = sound._sound.__buffer.data.toBytes();
			wavData = waveformData(
				sound._sound.__buffer,
				bytes,
				st,
				et,
				1,
				wavData,
				Std.int(gridBG.height)
			);
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * (Note.ammo[_song.mania] * 2));
		var hSize:Int = Std.int(gSize / 2);

		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length)
		{
			var lmin:Float = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
					if (sample > lmax) lmax = sample;
				else if (sample < 0)
					if (sample < lmin) lmin = sample;

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}
		for (track in extraTracks){
			track.pause();
			track.time = FlxG.sound.music.time;
		}

		pauseAndSetVocalsTime();
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		//trace('changing section' + sec);

		if (_song.notes[sec] != null)
		{
			curSec = sec;

			updateGrid();

			if (updateMusic)
			{
				FlxG.sound.music.pause();
				for (track in extraTracks) track.pause();

				/*var daNum:Int = 0;
					var daLength:Float = 0;
					while (daNum <= sec)
					{
						daLength += lengthBpmBullshit();
						daNum++;
				}*/

				FlxG.sound.music.time = sectionStartTime();
				pauseAndSetVocalsTime();
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if(sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;
	
			if(blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
			{
				reloadGridLayer();
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_exSection.checked = sec.exSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	var characterData:Dynamic = {
		iconP1: null,
		iconP2: null,
		iconP3: null,
		iconP4: null,
		iconP5: null,
		vocalsP1: null,
		vocalsP2: null,
		vocalsP3: null,
		vocalsP4: null,
		vocalsP5: null
	};

	function updateJsonData():Void
	{
		for (i in 1...5)
		{
			var data:CharacterFile = loadCharacterFile(Reflect.field(_song, 'player$i'));
			Reflect.setField(characterData, 'iconP$i', !characterFailed ? data.healthicon : 'face');
			Reflect.setField(characterData, 'vocalsP$i', data.vocals_file != null ? data.vocals_file : '');
		}
		trace(characterData);
	}
	
	function updateHeads():Void
	{
		if (_song.notes[curSec].mustHitSection)
		{
			leftIcon.changeIcon(characterData.iconP1);
			rightIcon.changeIcon(characterData.iconP2);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon(characterData.iconP3);
			if (_song.notes[curSec].exSection) leftIcon.changeIcon(characterData.iconP4);
			if (_song.notes[curSec].exSection) leftIcon.changeIcon(characterData.iconP5);
			if (_song.notes[curSec].exSection) rightIcon.changeIcon(characterData.iconP4);
		}
		else
		{
			leftIcon.changeIcon(characterData.iconP2);
			rightIcon.changeIcon(characterData.iconP1);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon(characterData.iconP3);
			if (_song.notes[curSec].exSection) leftIcon.changeIcon(characterData.iconP5);
			if (_song.notes[curSec].exSection) leftIcon.changeIcon(characterData.iconP4);
			if (_song.notes[curSec].exSection) rightIcon.changeIcon(characterData.iconP5);
		}
	}

	var characterFailed:Bool = false;
	function loadCharacterFile(char:String):CharacterFile {
		characterFailed = false;
		var characterPath:String = 'characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			characterFailed = true;
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) {
				stepperSusLength.value = curSelectedNote[2];
				if(curSelectedNote[3] != null) {
					currentType = curNoteTypes.indexOf(curSelectedNote[3]);
					if(currentType <= 0) {
						noteTypeDropDown.selectedLabel = '';
					} else {
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			} else {
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if(selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

function updateGrid():Void
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();
		curRenderedNoteType.clear();
		nextRenderedNotes.clear();
		nextRenderedSustains.clear();

		if (_song.notes[curSec].changeBPM && _song.notes[curSec].bpm > 0)
		{
			Conductor.bpm = _song.notes[curSec].bpm;
			//trace('BPM of this section:');
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.bpm;
			for (i in 0...curSec)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

		// CURRENT SECTION
		var beats:Float = getSectionBeats();
		for (i in _song.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				curRenderedSustains.add(setupSusNote(note, beats));
			}

			if(i[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Int = curNoteTypes.indexOf(i[3]);
				var theType:String = '' + typeInt;
				if(typeInt < 0) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSec].mustHitSection;
			if(i[1] > Note.ammo[_song.mania] - 1) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if(note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
				//trace('test: ' + i[0], 'startThing: ' + startThing, 'endThing: ' + endThing);
			}
		}

		// NEXT SECTION
		var beats:Float = getSectionBeats(1);
		if(curSec < _song.notes.length-1) {
			for (i in _song.notes[curSec+1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}

		// NEXT EVENTS
		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}
	

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % Note.ammo[_song.mania], null, null, true);
		if(daSus != null) { //Common note
			if(!Std.isOfType(i[3], String)) //Convert old note type to new note type format
			{
				i[3] = curNoteTypes[i[3]];
			}
			if(i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { //Event note
			note.loadGraphic(Paths.image('editors/eventArrow'));
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if(isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec+1].mustHitSection) {
			if(daNoteInfo > Note.ammo[_song.mania] - 1) {
				note.x -= GRID_SIZE * Note.ammo[_song.mania];
			} else if(daSus != null) {
				note.x += GRID_SIZE * Note.ammo[_song.mania];
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);
		//if(isNextSection) note.y += gridBG.height;
		if(note.y < -150) note.y = -150;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			gfSection: false,
			exSection: false,
			sectionNotes: [],
			altAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1)
		{
			if(note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.ammo[_song.mania];
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if(i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
			}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.ammo[_song.mania];

		if(note.noteData > -1) //Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if(i == curSelectedNote) curSelectedNote = null;
					//FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else //Events
		{
			for (i in _song.events)
			{
				if(i[0] == note.strumTime)
				{
					if(i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					//FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
			}
		}

		refreshBalance();
		updateGrid();
		autosaveSong();
	}

	public function doANoteThing(cs, d, style){
		var delnote = false;
		if(strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			Cursor.cursorMode = Pointer;
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1,strumLine.y+1)) && note.noteData == d%Note.ammo[_song.mania])
				{
						//trace('tryin to delete note...');
						if(!delnote) deleteNote(note);
						delnote = true;
				}
			});
		}
		
		if (!delnote){
			addNote(cs, d, style);
		}
	}
	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		refreshBalance();
		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		//curUndoIndex++;
		//var newsong = _song.notes;
		//	undos.push(newsong);
		var noteStrum = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if(noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData % (Note.ammo[_song.mania] * 2), noteSus, curNoteTypes[daType]]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			_song.events.push([noteStrum, [[event, text1, text2]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + Note.ammo[_song.mania]) % (Note.ammo[_song.mania] * 2), noteSus, curNoteTypes[daType]]);
		}

		//trace(noteData + ', ' + noteStrum + ', ' + curSec);
		strumTimeInputText.text = '' + curSelectedNote[0];

		refreshBalance();
		updateGrid();
		updateNoteUI();
		autosaveSong();
	}
	
	// will figure this out l8r
	function redo()
	{
		//_song = redos[curRedoIndex];
	}

	function undo()
	{
		//redos.push(_song);
		undos.pop();
		//_song.notes = undos[undos.length - 1];
		///trace(_song.notes);
		//updateGrid();
		refreshBalance();
	}
	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function copyNotes() {
		notesCopied = [];
		sectionToCopy = curSec;
		for (i in 0..._song.notes[curSec].sectionNotes.length)
		{
			var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
			notesCopied.push(note);
		}

		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (event in _song.events)
		{
			var strumTime:Float = event[0];
			if(endThing > event[0] && event[0] >= startThing)
			{
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...event[1].length)
				{
					var eventToPush:Array<Dynamic> = event[1][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				notesCopied.push([strumTime, -1, copiedEventArray]);
			}
		}
	}

	function clearNotes() {
		_song.notes[curSection].sectionNotes = [];
			
		var i:Int = _song.events.length - 1;
		
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		while(i > -1) {
			var event:Array<Dynamic> = _song.events[i];
			if(event != null && endThing > event[0] && event[0] >= startThing)
			{
				_song.events.remove(event);
			}
			--i;
		}
		updateGrid();
		updateNoteUI();
	}

	function pasteNotes(events:Bool, notes:Bool) {
		if(notesCopied == null || notesCopied.length < 1)
		{
			return;
		}

		var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));
		//trace('Time to add: ' + addToTime);

		for (note in notesCopied)
		{
			var copiedNote:Array<Dynamic> = [];
			var newStrumTime:Float = note[0] + addToTime;
			if(note[1] < 0)
			{
				if(events)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...note[2].length)
					{
						var eventToPush:Array<Dynamic> = note[2][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([newStrumTime, copiedEventArray]);	
				}
			}
			else
			{
				if(notes)
				{
					if(note[4] != null) {
						copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
					} else {
						copiedNote = [newStrumTime, note[1], note[2], note[3]];
					}
					_song.notes[curSec].sectionNotes.push(copiedNote);
				}
			}
		}
		refreshBalance();
		updateGrid();
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		//shitty null fix, i fucking hate it when this happens
		//make it look sexier if possible
		if (Difficulty.getString() != Difficulty.getDefault()) {
			if(Difficulty.getString() == null){
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			}else{
				PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + Difficulty.getString(), song.toLowerCase());
			}
		}else{
			PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
		}
		MusicBeatState.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = haxe.Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		notSaved = false;
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var json = {
			"song": _song
		};

		var data:String = haxe.Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.formatToSongPath(_song.song) + ".json");
		}
	}
	
	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	/*function connectNoteTailToNextNote(note:Note):Void
	{
		var curNote:Note = note;
		var nextNote:Note;
		var sec:Int = curSec;
		var notePlayer:Int = note[1] / Note.ammo[_song.mania]; //replace NOTES with whatever your variable for multi-key is

		for (sec in curSec..._song.notes.length) {
			for (n in _song.notes[sec].sectionNotes) {
				if (n[1] / Note.ammo[_song.mania] == notePlayer 
					&& n[0] > curSelectedNote[0]
					&& (nextNote == null || n[0] < nextNote[0])) {
					nextNote = n;
				}
			}
			
			if (nextNote != null) {
				var tailLength:Float = nextNote[0] - i[0];
				if (nextNote[1] == i[1]) tailLength -= Conductor.stepCrochet; // prevent tails from overlapping
				note[2] = tailLength;      

				return;
			}
		}
	}

	function connectSelectedNoteTail():Void
	{
		if (curSelectedNote != null)
			connectNoteTailToNextNote(curSelectedNote);
	}

	function connectAllNoteTailsInSection():Void
	{
		for (n in _song.notes[curSec].sectionNotes)
			if (n[2] > 0) connectNoteTailToNextNote(n);
	}*/

	private function saveEvents()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: _song.events
		};
		var json = {
			"song": eventsSong
		}

		var data:String = haxe.Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	function onSaveComplete(_):Void
	{
		notSaved = false;
		_inital_state_song = _song;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		if(_song.notes[section] != null) val = _song.notes[section].sectionBeats;
		return val != null ? val : 4;
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}