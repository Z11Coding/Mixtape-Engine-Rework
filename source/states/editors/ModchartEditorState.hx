package states.editors;

import backend.Song.SwagSection;
import backend.Song.SwagSong;
import backend.Song;
import backend.modchart.*;
import backend.modchart.Modifier;
import backend.modchart.modifiers.*;
import backend.modchart.modifiers.extra.*;
import backend.modchart.modifiers.shmoovin.*;
import backend.modchart.modifiers.shmoovin.false_paradise.*;
import backend.modchart.modifiers.shmoovin.psych_noteTween.*;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.ui.Anchor;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxAxes;
import flixel.util.FlxSort;
import haxe.Json;
import lime.utils.Assets;
import objects.Note;
import objects.playfields.PlayField;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
import stages.StageData;
import states.editors.content.ModchartFile;
import states.editors.content.ModchartRenderer;
#if (flixel < "5.3.0")
import flixel.system.FlxSound;
#else
import flixel.sound.FlxSound;
#end




class ModchartEditorEvent extends FlxSprite
{
    public var data:Array<Dynamic>;
    public function new (data:Array<Dynamic>)
    {
      this.data = data;
      super(-300, 0);
      loadGraphic(Paths.image('editors/eventIcon'));
      setGraphicSize(ModchartEditorState.gridSize, ModchartEditorState.gridSize);
      updateHitbox();
      antialiasing = true;
    }
    public function getBeatTime():Float { return data[ModchartFile.EVENT_DATA][ModchartFile.EVENT_TIME]; }
}

class ModchartEditorState extends MusicBeatState
{
    var hasUnsavedChanges:Bool = false;
    override function closeSubState()
    {
		persistentUpdate = true;
		super.closeSubState();
	}

    public static function getBPMFromSeconds(time:Float){
        return Conductor.getBPMFromSeconds(time);
	}




    //pain
    //tried using a macro but idk how to use them lol
    public static var modifierList:Array<Class<Modifier>> = [
        ReverseModifier,
        SwapModifier,
        DrunkModifier,
        BeatModifier,
        AlphaModifier,
        ScaleModifier,
        ConfusionModifier,
        OpponentModifier,
        TransformModifier,
        InfinitePathModifier,
        PathModifier,
        AccelModifier,
        ReceptorScrollModifier,
        PerspectiveModifier,
        ZoomModifier,
        SnapModifier,
        SpiralModifier,
        SchmovinDrunkModifier,
        FlaccidModifier,
        AngleModifier,
        SkewModifier,
        WiggleModifier,

        //Shmoovin
        ArrowShape,
        CounterClockWise,
        EyeShape,
        SchmovinArrowShape,
        Vibrate,
        Wiggle,
        Bounce,
        Drugged,
        Radionic,
        Carousel,

        //Compat.
        NoteTweenAngle,
        NoteTweenDirection
    ];
    public static var easeList:Array<String> = [
        "backIn",
        "backInOut",
        "backOut",
        "bounceIn",
        "bounceInOut",
        "bounceOut",
        "circIn",
        "circInOut",
        "circOut",
        "cubeIn",
        "cubeInOut",
        "cubeOut",
        "elasticIn",
        "elasticInOut",
        "elasticOut",
        "expoIn",
        "expoInOut",
        "expoOut",
        "linear",
        "quadIn",
        "quadInOut",
        "quadOut",
        "quartIn",
        "quartInOut",
        "quartOut",
        "quintIn",
        "quintInOut",
        "quintOut",
        "sineIn",
        "sineInOut",
        "sineOut",
        "smoothStepIn",
        "smoothStepInOut",
        "smoothStepOut",
        "smootherStepIn",
        "smootherStepInOut",
        "smootherStepOut",
    ];

    //used for indexing
    public static var MOD_NAME = ModchartFile.MOD_NAME; //the modifier name
    public static var MOD_CLASS = ModchartFile.MOD_CLASS; //the class/custom mod it uses
    public static var MOD_TYPE = ModchartFile.MOD_TYPE; //the type, which changes if its for the player, opponent, a specific lane or all
    public static var MOD_PF = ModchartFile.MOD_PF; //the playfield that mod uses
    public static var MOD_LANE = ModchartFile.MOD_LANE; //the lane the mod uses

    public static var EVENT_TYPE = ModchartFile.EVENT_TYPE; //event type (set or ease)
    public static var EVENT_DATA = ModchartFile.EVENT_DATA; //event data
    public static var EVENT_REPEAT = ModchartFile.EVENT_REPEAT; //event repeat data

    public static var EVENT_TIME = ModchartFile.EVENT_TIME; //event time (in beats)
    public static var EVENT_SETDATA = ModchartFile.EVENT_SETDATA; //event data (for sets)
    public static var EVENT_EASETIME = ModchartFile.EVENT_EASETIME; //event ease time
    public static var EVENT_EASE = ModchartFile.EVENT_EASE; //event ease
    public static var EVENT_EASEDATA = ModchartFile.EVENT_EASEDATA; //event data (for eases)

    public static var EVENT_REPEATBOOL = ModchartFile.EVENT_REPEATBOOL; //if event should repeat
    public static var EVENT_REPEATCOUNT = ModchartFile.EVENT_REPEATCOUNT; //how many times it repeats
    public static var EVENT_REPEATBEATGAP = ModchartFile.EVENT_REPEATBEATGAP; //how many beats in between each repeat

    public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
    public var notes:FlxTypedGroup<Note>;
    public var allNotes:Array<Note> = [];
    public var loadedNotes:Array<Note> = []; //stored notes from the chart that unspawnNotes can copy from
    public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;
	public var gfVocals:FlxSound;
    var generatedMusic:Bool = false;


    private var grid:FlxBackdrop;
    private var line:FlxSprite;
    var beatTexts:Array<FlxText> = [];
    public var eventSprites:FlxTypedGroup<ModchartEditorEvent>;
    public static var gridSize:Int = 64;
    public var highlight:FlxSprite;
    public var debugText:FlxText;
    var highlightedEvent:Array<Dynamic> = null;
    var stackedHighlightedEvents:Array<Array<Dynamic>> = [];

    var UI_box:PsychUIBox;

    var textBlockers:Array<PsychUIInputText> = [];
    var scrollBlockers:Array<PsychUIDropDownMenu> = [];

    var playbackSpeed:Float = 1;

    var activeModifiersText:FlxText;
    var selectedEventBox:FlxSprite;

    public var playfieldRenderer:ModchartRenderer;

    override public function new()
    {
        super();
    }
    override public function create()
    {
        Cursor.cursorMode = Default;
        initPsychCamera();

        camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		persistentUpdate = true;
		persistentDraw = true;

        #if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Making A Modchart", null);
		#end

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ClientPrefs.getBGImage(true)));
		if (ClientPrefs.data.menuTheme == "Dark")
			bg.color = 0xFFFDE871;
		// Simple rainbow effect for Pride Month

		if (yutautil.ExtendedDate.global().isPrideMonth() && ClientPrefs.data.allowEvents)
		{
			trace("Happy Pride Month!");
			var oldBGColor = bg.color;
			var updateRainbowBG:Void->Void;
			updateRainbowBG = function() {
				var now = Date.now();
				var t = now.getSeconds() + (now.getTime() % 1000) / 1000;
				bg.color = FlxColor.fromHSB((t * 60) % 360, 1, 1);
				if (!yutautil.ExtendedDate.instance.isPrideMonth() && ClientPrefs.data.allowEvents)
				{
					bg.color = oldBGColor; // Reset to original color if not Pride Month
					FlxG.signals.postUpdate.remove(updateRainbowBG);
				}
			};
			bg.color = FlxColor.fromHSB((Date.now().getSeconds() * 6) % 360, 1, 1);
			FlxG.signals.postUpdate.add(updateRainbowBG);
		}
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		if (PlayState.SONG == null)
			PlayState.SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(PlayState.SONG);
		Conductor.bpm = PlayState.SONG.bpm;

        FlxG.mouse.visible = true;

        loadSongAudio();

		playfieldRenderer = new ModchartRenderer(null, allNotes, this);
		playfieldRenderer.cameras = [camHUD];
        //playfieldRenderer.inEditor = true;
		add(playfieldRenderer);

        generateSong(PlayState.SONG.song);
        playfieldRenderer.allNotes = playfieldRenderer.unspawnNotes = allNotes;
        notes = playfieldRenderer.notes;

        #if ("flixel-addons" >= "3.0.0")
        grid = new FlxBackdrop(FlxGraphic.fromBitmapData(createGrid(gridSize, gridSize, Std.int(gridSize*48), gridSize)), FlxAxes.X, 0, 0);
        #else
        grid = new FlxBackdrop(FlxGraphic.fromBitmapData(createGrid(gridSize, gridSize, Std.int(gridSize*48), gridSize)), 0, 0, true, false);
        #end

        add(grid);

        for (i in 0...12)
        {
            var beatText = new FlxText(-50, gridSize, 0, i+"", 32);
            add(beatText);
            beatTexts.push(beatText);
        }

        eventSprites = new FlxTypedGroup<ModchartEditorEvent>();
        add(eventSprites);

        highlight = new FlxSprite().makeGraphic(gridSize,gridSize);
        highlight.alpha = 0.5;
        add(highlight);

        selectedEventBox = new FlxSprite().makeGraphic(32,32);
        selectedEventBox.y = gridSize*0.5;
        selectedEventBox.visible = false;
        add(selectedEventBox);

        updateEventSprites();

        line = new FlxSprite().makeGraphic(10, gridSize);
        add(line);

        //gridGap = FlxMath.remapToRange(Conductor.stepCrochet, 0, Conductor.stepCrochet, 0, gridSize); //idk why i even thought this was how i do it
        //trace(gridGap);

        debugText = new FlxText(0, gridSize*2, 0, "", 16);
        debugText.alignment = FlxTextAlign.LEFT;


        var tabs = [
            'Editor',
			//'Modifiers',
			'Events',
			'Playfields',
		];

        UI_box = new PsychUIBox(100, gridSize*2, FlxG.width-200, 550, tabs);
		UI_box.scrollFactor.set();
        UI_box.canMinimize = false;
        add(UI_box);

        add(debugText);

        super.create(); //do here because tooltips be dumb
        setupEditorUI();
        setupModifierUI();
        setupEventUI();
        setupPlayfieldUI();


        var hideNotes:PsychUIButton = new PsychUIButton(0, FlxG.height, 'Show/Hide Notes', function ()
        {
            //camHUD.visible = !camHUD.visible;
            playfieldRenderer.visible = !playfieldRenderer.visible;
        });
        hideNotes.scale.y *= 1.5;
        hideNotes.updateHitbox();
        hideNotes.y -= hideNotes.height;
        add(hideNotes);

        var hideUI:PsychUIButton = new PsychUIButton(FlxG.width, FlxG.height, 'Show/Hide UI', function ()
        {
            UI_box.visible = !UI_box.visible;
            debugText.visible = !debugText.visible;
            //camGame.visible = !camGame.visible;
        });
        hideUI.y -= hideUI.height;
        hideUI.x -= hideUI.width;
        add(hideUI);
    }

    var dirtyUpdateNotes:Bool = false;
    var dirtyUpdateEvents:Bool = false;
    var dirtyUpdateModifiers:Bool = false;
    var totalElapsed:Float = 0;
    override public function update(elapsed:Float)
    {
        totalElapsed += elapsed;
        highlight.alpha = 0.8+Math.sin(totalElapsed*5)*0.15;
        super.update(elapsed);
        if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
        Conductor.songPosition = FlxG.sound.music.time;


        var songPosPixelPos = (((Conductor.songPosition/Conductor.stepCrochet)%4)*gridSize);
        grid.x = -curDecStep*gridSize;
        line.x = gridSize*4;

        for (i in 0...beatTexts.length)
        {
            beatTexts[i].x = -songPosPixelPos + (gridSize*4*(i+1)) - 16;
            beatTexts[i].text = ""+ (Math.floor(Conductor.songPosition/Conductor.crochet)+i);
        }
        var eventIsSelected:Bool = false;
        for (i in 0...eventSprites.members.length)
        {
            var pos = grid.x + (eventSprites.members[i].getBeatTime()*gridSize*4)+(gridSize*4);
            //var dec = eventSprites.members[i].beatTime-Math.floor(eventSprites.members[i].beatTime);
            eventSprites.members[i].x = pos; //+ (dec*4*gridSize);
            if (highlightedEvent != null)
                if (eventSprites.members[i].data == highlightedEvent)
                {
                    eventIsSelected = true;
                    selectedEventBox.x = pos;
                }

        }
        selectedEventBox.visible = eventIsSelected;


        var blockInput = false;
        if (PsychUIInputText.focusOn != null)
        {
            blockInput = true;
            FlxG.sound.muteKeys = [];
            FlxG.sound.volumeDownKeys = [];
            FlxG.sound.volumeUpKeys = [];
        }

        if (!blockInput)
        {
            FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
            if (FlxG.keys.justPressed.SPACE)
            {
                if (FlxG.sound.music.playing)
                {
                    FlxG.sound.music.pause();
                    if(vocals != null) vocals.pause();
                    if(opponentVocals != null) opponentVocals.pause();
                    if(gfVocals != null) gfVocals.pause();
                    playfieldRenderer.editorPaused = true;
                }
                else
                {
                    if(vocals != null) {
                        vocals.play();
                        vocals.pause();
                        vocals.time = FlxG.sound.music.time;
                        vocals.play();
                    }
                    if(opponentVocals != null) {
                        opponentVocals.play();
                        opponentVocals.pause();
                        opponentVocals.time = FlxG.sound.music.time;
                        opponentVocals.play();
                    }
                    if(gfVocals != null) {
                        gfVocals.play();
                        gfVocals.pause();
                        gfVocals.time = FlxG.sound.music.time;
                        gfVocals.play();
                    }
                    FlxG.sound.music.play();
                    playfieldRenderer.editorPaused = false;
                    dirtyUpdateNotes = true;
                    dirtyUpdateEvents = true;
                }
            }
            var shiftThing:Int = 1;
            if (FlxG.keys.pressed.SHIFT)
                shiftThing = 4;
            if (FlxG.mouse.wheel != 0)
            {
                FlxG.sound.music.pause();
                if(vocals != null) vocals.pause();
                if(opponentVocals != null) opponentVocals.pause();
                if(gfVocals != null) gfVocals.pause();
                FlxG.sound.music.time += (FlxG.mouse.wheel * Conductor.stepCrochet*0.8*shiftThing);
                if(vocals != null) {
                    vocals.pause();
                    vocals.time = FlxG.sound.music.time;
                }
                if(opponentVocals != null) {
                    opponentVocals.pause();
                    opponentVocals.time = FlxG.sound.music.time;
                }
                if(gfVocals != null) {
                    gfVocals.pause();
                    gfVocals.time = FlxG.sound.music.time;
                }
                playfieldRenderer.editorPaused = true;
                dirtyUpdateNotes = true;
                dirtyUpdateEvents = true;
            }

            if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
            {
                FlxG.sound.music.pause();
                if(vocals != null) vocals.pause();
                if(opponentVocals != null) opponentVocals.pause();
                if(gfVocals != null) gfVocals.pause();
                FlxG.sound.music.time += (Conductor.crochet*4*shiftThing);
                dirtyUpdateNotes = true;
                dirtyUpdateEvents = true;
            }
            if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
            {
                FlxG.sound.music.pause();
                if(vocals != null) vocals.pause();
                if(opponentVocals != null) opponentVocals.pause();
                if(gfVocals != null) gfVocals.pause();
                FlxG.sound.music.time -= (Conductor.crochet*4*shiftThing);
                dirtyUpdateNotes = true;
                dirtyUpdateEvents = true;
            }
            var holdingShift = FlxG.keys.pressed.SHIFT;
            var holdingLB = FlxG.keys.pressed.LBRACKET;
            var holdingRB = FlxG.keys.pressed.RBRACKET;
            var pressedLB = FlxG.keys.justPressed.LBRACKET;
            var pressedRB = FlxG.keys.justPressed.RBRACKET;

            var curSpeed = playbackSpeed;

            if (!holdingShift && pressedLB || holdingShift && holdingLB)
                playbackSpeed -= 0.01;
            if (!holdingShift && pressedRB || holdingShift && holdingRB)
                playbackSpeed += 0.01;
            if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
                playbackSpeed = 1;
            //
            if (curSpeed != playbackSpeed)
                dirtyUpdateEvents = true;
        }

        if (playbackSpeed <= 0.5)
            playbackSpeed = 0.5;
        if (playbackSpeed >= 3)
            playbackSpeed = 3;

        playfieldRenderer.speed = playbackSpeed; //adjust the speed of tweens
        FlxG.sound.music.pitch = playbackSpeed;
        vocals.pitch = playbackSpeed;
        opponentVocals.pitch = playbackSpeed;
        gfVocals.pitch = playbackSpeed;

        if (FlxG.mouse.y < grid.y+grid.height && FlxG.mouse.y > grid.y) //not using overlap because the grid would go out of world bounds
        {
            if (FlxG.keys.pressed.SHIFT)
                highlight.x = FlxG.mouse.x;
            else
                highlight.x = (Math.floor((FlxG.mouse.x-(grid.x%gridSize))/gridSize)*gridSize)+(grid.x%gridSize);
            if (FlxG.mouse.overlaps(eventSprites))
            {
                if (FlxG.mouse.justPressed)
                {
                    stackedHighlightedEvents = []; //reset stacked events
                }
                eventSprites.forEachAlive(function(event:ModchartEditorEvent)
                {
                    if (FlxG.mouse.overlaps(event))
                    {
                        if (FlxG.mouse.justPressed)
                        {
                            highlightedEvent = event.data;
                            stackedHighlightedEvents.push(event.data);
                            onSelectEvent();
                            //trace(stackedHighlightedEvents);
                        }
                        if (FlxG.keys.justPressed.DELETE)
                            deleteEvent();
                    }
                });
                if (FlxG.mouse.justPressed)
                {
                    updateStackedEventDataStepper();
                }
            }
            else
            {
                if (FlxG.mouse.justPressed)
                {
                    var timeFromMouse = ((highlight.x-grid.x)/gridSize/4)-1;
                    //trace(timeFromMouse);
                    var event = addNewEvent(timeFromMouse);
                    highlightedEvent = event;
                    onSelectEvent();
                    updateEventSprites();
                    dirtyUpdateEvents = true;
                }
            }
        }

        if (dirtyUpdateNotes)
        {
            clearNotesAfter(Conductor.songPosition+2000); //so scrolling back doesnt lag shit
            loadedNotes = allNotes.copy();
            clearNotesBefore(Conductor.songPosition);
            dirtyUpdateNotes = false;
        }

        if (dirtyUpdateModifiers)
        {
            dirtyUpdateEvents = true;
            dirtyUpdateModifiers = false;
        }

        if (dirtyUpdateEvents)
        {
            FlxTween.globalManager.completeAll();
            playfieldRenderer.modManager.modchartFile.loadEvents();
            dirtyUpdateEvents = false;
            playfieldRenderer.update(0);
            updateEventSprites();
        }

        if (playfieldRenderer.modManager.modchartFile.data.playfields != playfieldCountStepper.value)
        {
            playfieldRenderer.modManager.modchartFile.data.playfields = Std.int(playfieldCountStepper.value);
            playfieldRenderer.loadPlayfields();
        }


        if (FlxG.keys.justPressed.ESCAPE)
        {
            var exitFunc = function()
            {
                FlxG.mouse.visible = false;
                FlxG.sound.music.stop();
                if(vocals != null) vocals.stop();
                if(opponentVocals != null) opponentVocals.stop();
                if(gfVocals != null) gfVocals.stop();

                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
            };
            if (hasUnsavedChanges)
            {
                persistentUpdate = false;
                openSubState(new ModchartEditorExitSubstate(exitFunc));
            }
            else
                exitFunc();

        }

        var curBpmChange = getBPMFromSeconds(Conductor.songPosition);
        if (curBpmChange.songTime <= 0)
        {
            curBpmChange.bpm = PlayState.SONG.bpm; //start bpm
        }
        if (curBpmChange.bpm != Conductor.bpm)
        {
            //trace('changed bpm to ' + curBpmChange.bpm);
            Conductor.bpm = curBpmChange.bpm;
        }

        debugText.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
		"\nBeat: " + Std.string(curDecBeat).substring(0,4) +
		"\nStep: " + curStep + "\n";

        var leText = "Active Modifiers: \n";
        for (modName => mod in playfieldRenderer.modManager.register)
        {
            for (player in 0...mod.percents.length-1) {
                if (mod.getValue(player) != 0)
                {
                    leText += modName + ": " + FlxMath.roundDecimal(mod.getValue(player), 2);
                    for (subModName => subMod in mod.submods)
                    {
                        leText += "    " + subModName + ": " + FlxMath.roundDecimal(subMod.getValue(player), 2);
                    }
                    leText += "\n";
                }
            }
        }

        activeModifiersText.text = leText;
    }

    function addNewEvent(time:Float)
    {
        var event:Array<Dynamic> = ['ease', [time, 1, 'cubeInOut', ','], [false, 1, 1]];
        if (highlightedEvent != null) //copy over current event data (without acting as a reference)
        {
            event[EVENT_TYPE] = highlightedEvent[EVENT_TYPE];
            if (event[EVENT_TYPE] == 'ease')
            {
                event[EVENT_DATA][EVENT_EASETIME] = highlightedEvent[EVENT_DATA][EVENT_EASETIME];
                event[EVENT_DATA][EVENT_EASE] = highlightedEvent[EVENT_DATA][EVENT_EASE];
                event[EVENT_DATA][EVENT_EASEDATA] = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
            }
            else
            {
                event[EVENT_DATA][EVENT_SETDATA] = highlightedEvent[EVENT_TYPE][EVENT_SETDATA];
            }
            event[EVENT_REPEAT][EVENT_REPEATBOOL] = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBOOL];
            event[EVENT_REPEAT][EVENT_REPEATCOUNT] = highlightedEvent[EVENT_REPEAT][EVENT_REPEATCOUNT];
            event[EVENT_REPEAT][EVENT_REPEATBEATGAP] = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBEATGAP];

        }
        playfieldRenderer.modManager.modchartFile.data.events.push(event);
        hasUnsavedChanges = true;
        return event;
    }

    function updateEventSprites()
    {
        /*var i = eventSprites.length - 1;
        while (i >= 0) {
            var daEvent:ModchartEditorEvent = eventSprites.members[i];
            if(curBeat < daEvent.beatTime-4 && curBeat > daEvent.beatTime+16)
            {
                daEvent.active = false;
                daEvent.visible = false;
                eventSprites.remove(daEvent, true);
                trace(daEvent.beatTime);
                trace("removed event sprite "+ daEvent.beatTime);
            }
            --i;
        }*/
        eventSprites.clear();
        for (i in 0...playfieldRenderer.modManager.modchartFile.data.events.length)
        {
            var beat:Float = playfieldRenderer.modManager.modchartFile.data.events[i][1][0];
            if (curBeat > beat-5  && curBeat < beat+5)
            {
                var daEvent:ModchartEditorEvent = new ModchartEditorEvent(playfieldRenderer.modManager.modchartFile.data.events[i]);
                eventSprites.add(daEvent);
                //trace("added event sprite "+beat);
            }
        }
    }

    function deleteEvent()
    {
        if (highlightedEvent == null)
            return;
        for (i in 0...playfieldRenderer.modManager.modchartFile.data.events.length)
        {
            if (highlightedEvent == playfieldRenderer.modManager.modchartFile.data.events[i])
            {
                playfieldRenderer.modManager.modchartFile.data.events.remove(playfieldRenderer.modManager.modchartFile.data.events[i]);
                dirtyUpdateEvents = true;
                break;
            }
        }
        updateEventSprites();
    }

    override public function beatHit()
    {
        updateEventSprites();
        //trace("beat hit");
        super.beatHit();
    }

    override public function draw()
    {
        super.draw();
    }

    public function clearNotesBefore(time:Float)
    {
        var i:Int = loadedNotes.length - 1;
        while (i >= 0) {
            var daNote:Note = loadedNotes[i];
            if(daNote.strumTime+350 < time)
            {
                daNote.active = false;
                daNote.visible = false;
                //daNote.ignoreNote = true;

                //daNote.kill();
                loadedNotes.remove(daNote);
                //daNote.destroy();
            }
            --i;
        }

        i = notes.length - 1;
        while (i >= 0) {
            var daNote:Note = notes.members[i];
            if(daNote.strumTime+350 < time)
            {
                daNote.active = false;
                daNote.visible = false;
                //daNote.ignoreNote = true;

                //daNote.kill();
                notes.remove(daNote, true);
                //daNote.destroy();
            }
            --i;
        }
    }
    public function clearNotesAfter(time:Float)
    {
        var i = notes.length - 1;
        while (i >= 0) {
            var daNote:Note = notes.members[i];
            if(daNote.strumTime > time)
            {
                daNote.active = false;
                daNote.visible = false;
                //daNote.ignoreNote = true;

                //daNote.kill();
                notes.remove(daNote, true);
                //daNote.destroy();
            }
            --i;
        }
    }

    /**
	 * Load song audio (vocals, inst) - separated from chart generation for preload mode
	 */
	private function loadSongAudio():Void {
		var songData = PlayState.SONG;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		gfVocals = new FlxSound();
		var usable = Paths.isAssetInMod;

		// Standard audio loading logic
        try
        {
            if (songData.needsVoices)
            {
                var currentMod = "";
                if (backend.WeekData.getCurrentWeek() != null)
                    currentMod = backend.WeekData.getCurrentWeek().folder; //istg this is somehow the root cause to all my problems ong
                if (currentMod != null && currentMod != "")
                {
                    var generalVocals = Paths.voices(songData.song);
                    if (generalVocals != null && generalVocals.length > 0)
                    {
                        vocals.loadEmbedded(generalVocals);

                        // Check for the other vocals as well
                        var oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

                        var gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
                    }
                    else
                    {
                        var playerVocals = Paths.voices(songData.song, 'Player');
                        if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song, 'Player');
                        if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song);
                        vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));

                        var oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

                        var gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
                    }
                }
                else
                {
                    var generalVocals = Paths.voices(songData.song);
                    if (generalVocals != null && generalVocals.length > 0)
                    {
                        vocals.loadEmbedded(generalVocals);

                        // Check for the other vocals as well
                        var oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

                        var gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
                    }
                    else
                    {
                        var playerVocals = Paths.voices(songData.song, 'Player');
                        if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song, 'Player');
                        if (playerVocals == null || playerVocals.length < 1) playerVocals = Paths.voices(songData.song);
                        vocals.loadEmbedded(playerVocals != null && playerVocals.length > 0 ? playerVocals : Paths.voices(songData.song));

                        var oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals == null || oppVocals.length < 1) oppVocals = Paths.voices(songData.song, 'Opponent');
                        if (oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);

                        var gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal == null || gfVocal.length < 1) gfVocal = Paths.voices(songData.song, 'GF');
                        if (gfVocal != null && gfVocal.length > 0) gfVocals.loadEmbedded(gfVocal);
                    }
                }
            }
        }
        catch (e:Dynamic) {trace("Vocals Broke.");}

		#if FLX_PITCH
		vocals.pitch = playbackSpeed;
		opponentVocals.pitch = playbackSpeed;
		gfVocals.pitch = playbackSpeed;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);
		FlxG.sound.list.add(gfVocals);

		inst = new FlxSound();

		// Standard inst loading logic
        try {
            inst.loadEmbedded(Paths.inst(songData.song));
        }
        catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);

		trace('Song audio loaded successfully');
        @:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
        FlxG.sound.music.pause();
	}


    private function generateSong(dataPath:String):Void
    {

        var songData = PlayState.SONG;


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
        };

        notes = new FlxTypedGroup<Note>();
        add(notes);

        var noteData:Array<SwagSection>;

        // NEW SHIT
        noteData = songData.notes;

        var playerCounter:Int = 0;

        var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

        //var songName:String = Paths.formatToSongPath(PlayState.SONG.song);

        for (section in noteData)
        {
            for (songNotes in section.sectionNotes)
            {
                var daStrumTime:Float = songNotes[0];
                var daNoteData:Int = Std.int(songNotes[1] % 4);
                var gottaHitNote:Bool = section.mustHitSection;
                if (songNotes[1] > 3)
                {
                    gottaHitNote = !section.mustHitSection;
                }
                var oldNote:Note;
                if (loadedNotes.length > 0)
                    oldNote = loadedNotes[Std.int(loadedNotes.length - 1)];
                else
                    oldNote = null;


                var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
                swagNote.sustainLength = songNotes[2];
                swagNote.mustPress = gottaHitNote;
                swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
                swagNote.noteType = songNotes[3];
                swagNote.visualTime = playfieldRenderer.getNoteInitialTime(swagNote.strumTime);
                if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = states.editors.ChartingStateOG.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

                swagNote.scrollFactor.set();

                var susLength:Float = swagNote.sustainLength;

                susLength = susLength / Conductor.stepCrochet;
                var playfield:PlayField = swagNote.field;

                if (playfield == null && playfieldRenderer.playfields.length > 0) {
                    if (swagNote.fieldIndex == -1)
                        swagNote.fieldIndex = swagNote.mustPress ? 0 : 1;

                    if (playfieldRenderer.playfields.members[swagNote.fieldIndex] != null) {
                        playfield = playfieldRenderer.playfields.members[swagNote.fieldIndex];
                        swagNote.field = playfield;
                    }
                }
                //notes.insert(swagNote.ID, swagNote); // just for the sake of convenience

                if (playfield != null)
                {
                    if (playfield != null) {
                        playfield.queue(swagNote); // queues the note to be spawned
                    }
                    loadedNotes.push(swagNote); // just for the sake of convenience
                }

                var floorSus:Int = Math.floor(susLength);
                if(floorSus > 0) {
                    for (susNote in 0...floorSus+1)
                    {
                        oldNote = loadedNotes[Std.int(loadedNotes.length - 1)];
                        var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(PlayState.SONG.speed, 2)), daNoteData, oldNote, true);
                        sustainNote.mustPress = gottaHitNote;
                        sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
                        sustainNote.noteType = swagNote.noteType;
                        swagNote.tail.push(sustainNote);
                        sustainNote.parent = swagNote;
                        sustainNote.scrollFactor.set();
                        if (playfield != null) {
                            playfield.queue(sustainNote);
                        }
                        loadedNotes.push(sustainNote);
                    }
                }
            }
            daBeats += 1;
        }

        loadedNotes.sort(sortByTime);
        allNotes = loadedNotes.copy();
        generatedMusic = true;
    }

    function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
    {
        return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
    }

    public static function createGrid(CellWidth:Int, CellHeight:Int, Width:Int, Height:Int):BitmapData
    {
        // How many cells can we fit into the width/height? (round it UP if not even, then trim back)
        var Color1 = FlxColor.RED; //quant colors!!!
        var Color2 = FlxColor.BLUE;
        var Color3 = FlxColor.LIME;
        var rowColor:Int = Color1;
        var lastColor:Int = Color1;
        var grid:BitmapData = new BitmapData(Width, Height, true);

        // If there aren't an even number of cells in a row then we need to swap the lastColor value
        var y:Int = 0;
        var timesFilled:Int = 0;
        while (y <= Height)
        {

            var x:Int = 0;
            while (x <= Width)
            {
                if (timesFilled % 4 == 0)
                    lastColor = Color1;
                else if (timesFilled % 4 == 2)
                    lastColor = Color2;
                else
                    lastColor = Color3;

                grid.fillRect(new Rectangle(x, y, CellWidth, CellHeight), lastColor);
                timesFilled++;

                x += CellWidth;
            }

            y += CellHeight;
        }

        return grid;
    }
    var currentModifier:Array<Dynamic> = null;
    var modNameInputText:PsychUIInputText;
    var modClassInputText:PsychUIInputText;
    var modTypeInputText:PsychUIInputText;
    var playfieldStepper:PsychUINumericStepper;
    var targetLaneStepper:PsychUINumericStepper;
    var modifierDropDown:PsychUIDropDownMenu;
    var mods:Array<String> = [];
    var subMods:Array<String> = [""];

    function updateModList()
    {
        mods = [];
        for (modName in playfieldRenderer.modManager.register.keys())
            mods.push(modName);
        if (mods.length == 0)
            mods.push('');
        modifierDropDown.list = mods;
        eventModifierDropDown.list = mods;

    }

    function updateSubModList(modName:String)
    {
        subMods = [""];
        if (playfieldRenderer.modManager.register.exists(modName))
        {
            for (subMod in playfieldRenderer.modManager.register.get(modName).submods)
            {
                subMods.push(subMod.getName());
            }
        }
        subModDropDown.list = subMods;
    }
    function setupModifierUI()
    {
        var tab_group = UI_box.getTab('Modifiers').menu;

        for (i in 0...playfieldRenderer.modManager.modchartFile.data.modifiers.length)
            mods.push(playfieldRenderer.modManager.modchartFile.data.modifiers[i][MOD_NAME]);

        if (mods.length == 0)
            mods.push('');

        modifierDropDown = new PsychUIDropDownMenu(25, 50, mods, function(id:Int, mod:String)
        {
            var modName = mods[Std.parseInt(mod)];
            for (i in 0...playfieldRenderer.modManager.modchartFile.data.modifiers.length)
                if (playfieldRenderer.modManager.modchartFile.data.modifiers[i][MOD_NAME] == modName)
                    currentModifier = playfieldRenderer.modManager.modchartFile.data.modifiers[i];

            if (currentModifier != null)
            {
                //trace(currentModifier);
                modNameInputText.text = currentModifier[MOD_NAME];
                modClassInputText.text = currentModifier[MOD_CLASS];
                modTypeInputText.text = currentModifier[MOD_TYPE];
                playfieldStepper.value = currentModifier[MOD_PF];
                if (currentModifier[MOD_LANE] != null)
                    targetLaneStepper.value = currentModifier[MOD_LANE];
            }
        });




        var refreshModifiers:PsychUIButton = new PsychUIButton(25+modifierDropDown.width+10, modifierDropDown.y, 'Refresh Modifiers', function ()
        {
            updateModList();
        });
        refreshModifiers.scale.y *= 1.5;
        refreshModifiers.updateHitbox();

        var saveModifier:PsychUIButton = new PsychUIButton(refreshModifiers.x, refreshModifiers.y+refreshModifiers.height+20, 'Save Modifier', function ()
        {
            var alreadyExists = false;
            for (i in 0...playfieldRenderer.modManager.modchartFile.data.modifiers.length)
                if (playfieldRenderer.modManager.modchartFile.data.modifiers[i][MOD_NAME] == modNameInputText.text)
                {
                    playfieldRenderer.modManager.modchartFile.data.modifiers[i] = [modNameInputText.text, modClassInputText.text, modTypeInputText.text, playfieldStepper.value, targetLaneStepper.value];
                    alreadyExists = true;
                }

            if (!alreadyExists)
            {
                playfieldRenderer.modManager.modchartFile.data.modifiers.push([modNameInputText.text, modClassInputText.text, modTypeInputText.text, playfieldStepper.value, targetLaneStepper.value]);
            }
            dirtyUpdateModifiers = true;
            updateModList();
            hasUnsavedChanges = true;
        });

        var removeModifier:PsychUIButton = new PsychUIButton(saveModifier.x, saveModifier.y+saveModifier.height+20, 'Remove Modifier', function ()
        {
            for (i in 0...playfieldRenderer.modManager.modchartFile.data.modifiers.length)
                if (playfieldRenderer.modManager.modchartFile.data.modifiers[i][MOD_NAME] == modNameInputText.text)
                {
                    playfieldRenderer.modManager.modchartFile.data.modifiers.remove(playfieldRenderer.modManager.modchartFile.data.modifiers[i]);
                }
            dirtyUpdateModifiers = true;
            updateModList();
            hasUnsavedChanges = true;
        });
        removeModifier.scale.y *= 1.5;
        removeModifier.updateHitbox();

        modNameInputText = new PsychUIInputText(modifierDropDown.x + 300, modifierDropDown.y, 160, '', 8);
        modClassInputText = new PsychUIInputText(modifierDropDown.x + 500, modifierDropDown.y, 160, '', 8);
        modTypeInputText = new PsychUIInputText(modifierDropDown.x + 700, modifierDropDown.y, 160, '', 8);
        playfieldStepper = new PsychUINumericStepper(modifierDropDown.x + 900, modifierDropDown.y, 1, -1, -1, 100, 0);
        targetLaneStepper = new PsychUINumericStepper(modifierDropDown.x + 900, modifierDropDown.y+300, 1, -1, -1, 100, 0);

        textBlockers.push(modNameInputText);
        textBlockers.push(modClassInputText);
        textBlockers.push(modTypeInputText);
        scrollBlockers.push(modifierDropDown);


        var modClassList:Array<String> = [];
        var modNameList:Array<String> = [];
        for (i in 0...modifierList.length)
        {
            var index = Std.string(modifierList[i]).lastIndexOf(".");
            modClassList.push(Std.string(modifierList[i]).substr(index));
            modClassList.push(Std.string(modifierList[i]).substr(index));
        }

        var modClassDropDown = new PsychUIDropDownMenu(modClassInputText.x, modClassInputText.y+30, modClassList, function(id:Int, mod:String)
        {
            modClassInputText.text = modClassList[Std.parseInt(mod)];
            modClassInputText.text = modClassList[Std.parseInt(mod)];
        });
        centerXToObject(modClassInputText, modClassDropDown);
        var modTypeList = ["All", "Player", "Opponent", "Lane"];
        var modTypeDropDown = new PsychUIDropDownMenu(modTypeInputText.x, modClassInputText.y+30, modTypeList, function(id:Int, mod:String)
        {
            modTypeInputText.text = modTypeList[Std.parseInt(mod)];
        });
        centerXToObject(modTypeInputText, modTypeDropDown);

        scrollBlockers.push(modTypeDropDown);
        scrollBlockers.push(modClassDropDown);

        activeModifiersText = new FlxText(50, 180);
        /*tab_group.add(activeModifiersText);


        tab_group.add(modNameInputText);
        tab_group.add(modClassInputText);
        tab_group.add(modTypeInputText);
        tab_group.add(playfieldStepper);
        tab_group.add(targetLaneStepper);

        tab_group.add(refreshModifiers);
        tab_group.add(saveModifier);
        tab_group.add(removeModifier);

        tab_group.add(makeLabel(modNameInputText, 0, -15, "Modifier Name"));
        tab_group.add(makeLabel(modClassInputText, 0, -15, "Modifier Class"));
        tab_group.add(makeLabel(modTypeInputText, 0, -15, "Modifier Type"));
        tab_group.add(makeLabel(playfieldStepper, 0, -15, "Playfield (-1 = all)"));
        tab_group.add(makeLabel(targetLaneStepper, 0, -15, "Target Lane (only for Lane mods!)"));
        tab_group.add(makeLabel(playfieldStepper, 0, 15, "Playfield number starts at 0!"));

        tab_group.add(modifierDropDown);
        tab_group.add(modClassDropDown);
        tab_group.add(modTypeDropDown);*/
    }



    function findCorrectModData(data:Array<Dynamic>) //the data is stored at different indexes based on the type (maybe should have kept them the same)
    {
        switch(data[EVENT_TYPE])
        {
            case "ease":
                return data[EVENT_DATA][EVENT_EASEDATA];
            case "set":
                return data[EVENT_DATA][EVENT_SETDATA];
        }
        return null;
    }
    function setCorrectModData(data:Array<Dynamic>, dataStr:String)
    {
        switch(data[EVENT_TYPE])
        {
            case "ease":
                data[EVENT_DATA][EVENT_EASEDATA] = dataStr;
            case "set":
                data[EVENT_DATA][EVENT_SETDATA] = dataStr;
        }
        return data;
    }
    //TODO: fix this shit
    function convertModData(data:Array<Dynamic>, newType:String)
    {
        switch(data[EVENT_TYPE]) //convert stuff over i guess
        {
            case "ease":
                if (newType == 'set')
                {
                    trace('converting ease to set');
                    var temp:Array<Dynamic> = [newType, [
                        data[EVENT_DATA][EVENT_TIME],
                        data[EVENT_DATA][EVENT_EASEDATA],
                    ], data[EVENT_REPEAT]];
                    data = temp.copy();
                }
            case "set":
                if (newType == 'ease')
                {
                    trace('converting set to ease');
                    var temp:Array<Dynamic> = [newType, [
                        data[EVENT_DATA][EVENT_TIME],
                        1,
                        "linear",
                        data[EVENT_DATA][EVENT_SETDATA],
                    ], data[EVENT_REPEAT]];
                    trace(temp);
                    data = temp.copy();
                }
        }
        //trace(data);
        return data;
    }

    function updateEventModData(shitToUpdate:String, isMod:Bool)
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            var dataSplit = dataStr.split(',');
            //the way the data works is it goes "value,mod,value,mod,....." and goes on forever, so it has to deconstruct and reconstruct to edit it and shit

            dataSplit[(getEventModIndex()*2)+(isMod ? 1 : 0)] = shitToUpdate;
            dataStr = stringifyEventModData(dataSplit);
            data = setCorrectModData(data, dataStr);
        }
    }
    function getEventModData(isMod:Bool) : String
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            var dataSplit = dataStr.split(',');
            return dataSplit[(getEventModIndex()*2)+(isMod ? 1 : 0)];
        }
        return "";
    }
    function stringifyEventModData(dataSplit:Array<String>) : String
    {
        var dataStr = "";
        for (i in 0...dataSplit.length)
        {
            dataStr += dataSplit[i];
            if (i < dataSplit.length-1)
                dataStr += ',';
        }
        return dataStr;
    }
    function addNewModData()
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            dataStr += ",,"; //just how it works lol
            data = setCorrectModData(data, dataStr);
        }
        return data;
    }
    function removeModData()
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            if (selectedEventDataStepper.max > 0) //dont remove if theres only 1
            {
                var dataStr:String = findCorrectModData(data);
                var dataSplit = dataStr.split(',');
                dataSplit.resize(dataSplit.length-2); //remove last 2 things
                dataStr = stringifyEventModData(dataSplit);
                data = setCorrectModData(data, dataStr);
            }
        }
        return data;
    }
    var eventTimeStepper:PsychUINumericStepper;
    var eventModInputText:PsychUIInputText;
    var eventValueInputText:PsychUIInputText;
    var eventDataInputText:PsychUIInputText;
    var eventModifierDropDown:PsychUIDropDownMenu;
    var eventTypeDropDown:PsychUIDropDownMenu;
    var eventEaseInputText:PsychUIInputText;
    var eventTimeInputText:PsychUIInputText;
    var selectedEventDataStepper:PsychUINumericStepper;
    var repeatCheckbox:PsychUICheckBox;
    var repeatBeatGapStepper:PsychUINumericStepper;
    var repeatCountStepper:PsychUINumericStepper;
    var easeDropDown:PsychUIDropDownMenu;
    var subModDropDown:PsychUIDropDownMenu;
    var builtInModDropDown:PsychUIDropDownMenu;
    var stackedEventStepper:PsychUINumericStepper;
    function setupEventUI()
    {
        var tab_group = UI_box.getTab('Events').menu;

        eventTimeStepper = new PsychUINumericStepper(850, 50, 0.25, 0, 0, 9999, 3);

        repeatCheckbox = new PsychUICheckBox(950, 50, "Repeat Event?");
        repeatCheckbox.checked = false;
        repeatCheckbox.onClick = function()
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                data[EVENT_REPEAT][EVENT_REPEATBOOL] = repeatCheckbox.checked;
                highlightedEvent = data;
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        }
        repeatBeatGapStepper = new PsychUINumericStepper(950, 100, 0.25, 0, 0, 9999, 3);
        repeatBeatGapStepper.name = 'repeatBeatGap';
        repeatCountStepper = new PsychUINumericStepper(950, 150, 1, 1, 1, 9999, 3);
        repeatCountStepper.name = 'repeatCount';
        centerXToObject(repeatCheckbox, repeatBeatGapStepper);
        centerXToObject(repeatCheckbox, repeatCountStepper);



        eventModInputText = new PsychUIInputText(25, 50, 160, '', 8);
        eventModInputText.onChange = function(str:String, str2:String)
        {
            updateEventModData(eventModInputText.text, true);
            var data = getCurrentEventInData();
            if (data != null)
            {
                highlightedEvent = data;
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        };
        eventValueInputText = new PsychUIInputText(25 + 200, 50, 160, '', 8);
        eventValueInputText.onChange = function(str:String, str2:String)
        {
            updateEventModData(eventValueInputText.text, false);
            var data = getCurrentEventInData();
            if (data != null)
            {
                highlightedEvent = data;
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        };

        selectedEventDataStepper = new PsychUINumericStepper(25 + 400, 50, 1, 0, 0, 0, 0);
        selectedEventDataStepper.name = "selectedEventMod";

        stackedEventStepper = new PsychUINumericStepper(25 + 400, 200, 1, 0, 0, 0, 0);
        stackedEventStepper.name = "stackedEvent";

        var addStacked:PsychUIButton = new PsychUIButton(stackedEventStepper.x, stackedEventStepper.y+30, 'Add', function ()
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                var event = addNewEvent(data[EVENT_DATA][EVENT_TIME]);
                highlightedEvent = event;
                onSelectEvent();
                updateEventSprites();
                dirtyUpdateEvents = true;
            }
        });
        centerXToObject(stackedEventStepper, addStacked);

        eventTypeDropDown = new PsychUIDropDownMenu(25 + 500, 50, eventTypes, function(id:Int, mod:String)
        {
            var et = eventTypes[Std.parseInt(mod)];
            trace(et);
            var data = getCurrentEventInData();
            if (data != null)
            {
                //if (data[EVENT_TYPE] != et)
                data = convertModData(data, et);
                highlightedEvent = data;
                trace(highlightedEvent);
            }
            eventEaseInputText.alpha = 1;
            eventTimeInputText.alpha = 1;
            if (et != 'ease')
            {
                eventEaseInputText.alpha = 0.5;
                eventTimeInputText.alpha = 0.5;
            }
            dirtyUpdateEvents = true;
            hasUnsavedChanges = true;
        });
        eventEaseInputText = new PsychUIInputText(25 + 650, 50+100, 160, '', 8);
        eventTimeInputText = new PsychUIInputText(25 + 650, 50, 160, '', 8);
        eventEaseInputText.onChange = function(str:String, str2:String)
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                if (data[EVENT_TYPE] == 'ease')
                    data[EVENT_DATA][EVENT_EASE] = eventEaseInputText.text;
            }
            dirtyUpdateEvents = true;
            hasUnsavedChanges = true;
        }
        eventTimeInputText.onChange = function(str:String, str2:String)
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                if (data[EVENT_TYPE] == 'ease')
                    data[EVENT_DATA][EVENT_EASETIME] = eventTimeInputText.text;
            }
            dirtyUpdateEvents = true;
            hasUnsavedChanges = true;
        }

        easeDropDown = new PsychUIDropDownMenu(25, eventEaseInputText.y+30, easeList, function(id:Int, ease:String)
        {
            var easeStr = easeList[Std.parseInt(ease)];
            eventEaseInputText.text = easeStr;
            eventEaseInputText.onChange("", ""); //make sure it updates
            hasUnsavedChanges = true;
        });
        centerXToObject(eventEaseInputText, easeDropDown);


        eventModifierDropDown = new PsychUIDropDownMenu(25, 50+20, mods, function(id:Int, mod:String)
        {
            var modName = mods[Std.parseInt(mod)];
            eventModInputText.text = modName;
            updateSubModList(modName);
            eventModInputText.onChange("", ""); //make sure it updates
            hasUnsavedChanges = true;
        });
        centerXToObject(eventModInputText, eventModifierDropDown);

        subModDropDown = new PsychUIDropDownMenu(25, 50+80, subMods, function(id:Int, mod:String)
        {
            var modName = subMods[Std.parseInt(mod)];
            var splitShit = eventModInputText.text.split(":"); //use to get the normal mod

            if (modName == "")
            {
                eventModInputText.text = splitShit[0]; //remove the sub mod
            }
            else
            {
                eventModInputText.text = splitShit[0] + ":" + modName;
            }

            eventModInputText.onChange("", ""); //make sure it updates
            hasUnsavedChanges = true;
        });
        centerXToObject(eventModInputText, subModDropDown);

        eventDataInputText = new PsychUIInputText(25, 300, 300, '', 8);
        //eventDataInputText.resize(300, 300);
        eventDataInputText.onChange = function(str:String, str2:String)
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                data[EVENT_DATA][EVENT_EASEDATA] = eventDataInputText.text;
                highlightedEvent = data;
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        };

        var add:PsychUIButton = new PsychUIButton(0, selectedEventDataStepper.y+30, 'Add', function ()
        {
            var data = addNewModData();
            if (data != null)
            {
                highlightedEvent = data;
                updateSelectedEventDataStepper();
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                eventModInputText.text = getEventModData(true);
                eventValueInputText.text = getEventModData(false);
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        });

        var remove:PsychUIButton = new PsychUIButton(0, selectedEventDataStepper.y+50, 'Remove', function ()
        {
            var data = removeModData();
            if (data != null)
            {
                highlightedEvent = data;
                updateSelectedEventDataStepper();
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                eventModInputText.text = getEventModData(true);
                eventValueInputText.text = getEventModData(false);
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        });
        centerXToObject(selectedEventDataStepper, add);
        centerXToObject(selectedEventDataStepper, remove);
        tab_group.add(add);
        tab_group.add(remove);


        textBlockers.push(eventModInputText);
        textBlockers.push(eventDataInputText);
        textBlockers.push(eventValueInputText);
        textBlockers.push(eventEaseInputText);
        textBlockers.push(eventTimeInputText);
        scrollBlockers.push(eventModifierDropDown);
        scrollBlockers.push(eventTypeDropDown);
        scrollBlockers.push(subModDropDown);
        scrollBlockers.push(easeDropDown);

        addUI(tab_group, "addStacked", addStacked, 'Add New Stacked Event', 'Adds a new stacked event and duplicates the current one.');

        addUI(tab_group, "eventDataInputText", eventDataInputText, 'Raw Event Data', 'The raw data used in the event, you wont really need to use this.');
        addUI(tab_group, "stackedEventStepper", stackedEventStepper, 'Stacked Event Stepper', 'Allows you to find/switch to stacked events.');
        tab_group.add(makeLabel(stackedEventStepper, 0, -15, "Stacked Events Index"));

        addUI(tab_group, "eventValueInputText", eventValueInputText, 'Event Value', 'The value that the modifier will change to.');
        addUI(tab_group, "eventModInputText", eventModInputText, 'Event Modifier', 'The name of the modifier used in the event.');

        addUI(tab_group, "repeatBeatGapStepper", repeatBeatGapStepper, 'Repeat Beat Gap', 'The amount of beats in between each repeat.');
        addUI(tab_group, "repeatCheckbox", repeatCheckbox, 'Repeat', 'Check the box if you want the event to repeat.');
        addUI(tab_group, "repeatCountStepper", repeatCountStepper, 'Repeat Count', 'How many times the event will repeat.');
        tab_group.add(makeLabel(repeatBeatGapStepper, 0, -30, "How many beats in between\neach repeat?"));
        tab_group.add(makeLabel(repeatCountStepper, 0, -15, "How many times to repeat?"));

        addUI(tab_group, "eventEaseInputText", eventEaseInputText, 'Event Ease', 'The easing function used by the event (only for "ease" type).');
        addUI(tab_group, "eventTimeInputText", eventTimeInputText, 'Event Ease Time', 'How long the tween takes to finish in beats (only for "ease" type).');
        tab_group.add(makeLabel(eventEaseInputText, 0, -15, "Event Ease"));
        tab_group.add(makeLabel(eventTimeInputText, 0, -15, "Event Ease Time (in Beats)"));
        tab_group.add(makeLabel(eventTypeDropDown, 0, -15, "Event Type"));

        addUI(tab_group, "eventTimeStepper", eventTimeStepper, 'Event Time', 'The beat that the event occurs on.');
        addUI(tab_group, "selectedEventDataStepper", selectedEventDataStepper, 'Selected Event', 'Which modifier event is selected within the event.');
        tab_group.add(makeLabel(selectedEventDataStepper, 0, -15, "Selected Data Index"));
        tab_group.add(makeLabel(eventDataInputText, 0, -15, "Raw Event Data"));
        tab_group.add(makeLabel(eventValueInputText, 0, -15, "Event Value"));
        tab_group.add(makeLabel(eventModInputText, 0, -15, "Event Mod"));
        tab_group.add(makeLabel(subModDropDown, 0, -15, "Sub Mods"));






        addUI(tab_group, "subModDropDown", subModDropDown, 'Sub Mods', 'Drop down for sub mods on the currently selected modifier, not all mods have them.');
        addUI(tab_group, "eventModifierDropDown", eventModifierDropDown, 'Stored Modifiers', 'Drop down for stored modifiers.');
        addUI(tab_group, "eventTypeDropDown", eventTypeDropDown, 'Event Type', 'Drop down to swtich the event type, currently there is only "set" and "ease", "set" makes the event happen instantly, and "ease" has a time and an ease function to smoothly change the modifiers.');
        addUI(tab_group, "easeDropDown", easeDropDown, 'Eases', 'Drop down that stores all the built-in easing functions.');
    }
    function getCurrentEventInData() //find stored data to match with highlighted event
    {
        if (highlightedEvent == null)
            return null;
        for (i in 0...playfieldRenderer.modManager.modchartFile.data.events.length)
        {
            if (playfieldRenderer.modManager.modchartFile.data.events[i] == highlightedEvent)
            {
                return playfieldRenderer.modManager.modchartFile.data.events[i];
            }
        }

        return null;
    }
    function getMaxEventModDataLength() //used for the stepper so it doesnt go over max and break something
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            var dataSplit = dataStr.split(',');
            return Math.floor((dataSplit.length/2)-1);
        }
        return 0;
    }
    function updateSelectedEventDataStepper() //update the stepper
    {
        selectedEventDataStepper.max = getMaxEventModDataLength();
        if (selectedEventDataStepper.value > selectedEventDataStepper.max)
            selectedEventDataStepper.value = 0;
    }
    function updateStackedEventDataStepper() //update the stepper
    {
        stackedEventStepper.max = stackedHighlightedEvents.length-1;
        stackedEventStepper.value = stackedEventStepper.max; //when you select an event, if theres stacked events it should be the one at the end of the list so just set it to the end
    }
    function getEventModIndex() { return Math.floor(selectedEventDataStepper.value); }
    var eventTypes:Array<String> = ["ease", "set"];
    function onSelectEvent(fromStackedEventStepper = false)
    {
        //update texts and stuff
        updateSelectedEventDataStepper();
        eventTimeStepper.value = Std.parseFloat(highlightedEvent[EVENT_DATA][EVENT_TIME]);
        eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];

        eventEaseInputText.alpha = 0.5;
        eventTimeInputText.alpha = 0.5;
        if (highlightedEvent[EVENT_TYPE] == 'ease')
        {
            eventEaseInputText.alpha = 1;
            eventTimeInputText.alpha = 1;
            eventEaseInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASE];
            eventTimeInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASETIME];
        }
        eventTypeDropDown.selectedLabel = highlightedEvent[EVENT_TYPE];
        eventModInputText.text = getEventModData(true);
        eventValueInputText.text = getEventModData(false);
        repeatBeatGapStepper.value = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBEATGAP];
        repeatCountStepper.value = highlightedEvent[EVENT_REPEAT][EVENT_REPEATCOUNT];
        repeatCheckbox.checked = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBOOL];
        if (!fromStackedEventStepper)
            stackedEventStepper.value = 0;
        dirtyUpdateEvents = true;
    }

    public function UIEvent(id:String, sender:Dynamic)
    {
        //trace(id, sender);
        switch(id)
        {
            case PsychUINumericStepper.CHANGE_EVENT:
                if (sender is PsychUINumericStepper) {
                    var nums:PsychUINumericStepper = cast sender;
                    var wname = nums.name;
                    switch(wname)
                    {
                        case "selectedEventMod": //stupid steppers which dont have normal callbacks
                            if (highlightedEvent != null)
                            {
                                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                                eventModInputText.text = getEventModData(true);
                                eventValueInputText.text = getEventModData(false);
                            }
                        case "repeatBeatGap":
                            var data = getCurrentEventInData();
                            if (data != null)
                            {
                                data[EVENT_REPEAT][EVENT_REPEATBEATGAP] = repeatBeatGapStepper.value;
                                highlightedEvent = data;
                                hasUnsavedChanges = true;
                                dirtyUpdateEvents = true;
                            }
                        case "repeatCount":
                            var data = getCurrentEventInData();
                            if (data != null)
                            {
                                data[EVENT_REPEAT][EVENT_REPEATCOUNT] = repeatCountStepper.value;
                                highlightedEvent = data;
                                hasUnsavedChanges = true;
                                dirtyUpdateEvents = true;
                            }
                        case "stackedEvent":
                            if (highlightedEvent != null)
                            {
                                //trace(stackedHighlightedEvents);
                                highlightedEvent = stackedHighlightedEvents[Std.int(stackedEventStepper.value)];
                                onSelectEvent(true);
                            }
                    }
                }

        }
    }

    var playfieldCountStepper:PsychUINumericStepper;
    function setupPlayfieldUI()
    {
        var tab_group = UI_box.getTab('Playfields').menu;

        playfieldCountStepper = new PsychUINumericStepper(25, 50, 1, 2, 1, 100, 0);
        playfieldCountStepper.value = playfieldRenderer.modManager.modchartFile.data.playfields;


        tab_group.add(playfieldCountStepper);
        tab_group.add(makeLabel(playfieldCountStepper, 0, -15, "Playfield Count"));
        tab_group.add(makeLabel(playfieldCountStepper, 55, 25, "Don't add too many or the game will lag!!!"));
    }
    var sliderRate:PsychUISlider;
    function setupEditorUI()
    {
        var tab_group = UI_box.getTab('Editor').menu;

        sliderRate = new PsychUISlider(20, 120, function(v:Float) return playbackSpeed = v, 1, 0.5, 2, 250, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.labelText.text = 'Playback Rate';
        sliderRate.onChange = function(val:Float)
        {
            playbackSpeed = val;
            dirtyUpdateEvents = true;
        };

        var songSlider = new PsychUISlider(20, 200, function(v:Float) return FlxG.sound.music.time = v, FlxG.sound.music.time, 0, FlxG.sound.music.length, 250, FlxColor.WHITE, FlxColor.BLACK);
		songSlider.valueText.visible = false;
		songSlider.labelText.text = 'Song Time';
		songSlider.onChange = function(fuck:Float)
		{
            FlxG.sound.music.time = fuck;
			vocals.time = FlxG.sound.music.time;
			Conductor.songPosition = FlxG.sound.music.time;
            dirtyUpdateEvents = true;
            dirtyUpdateNotes = true;
		};

        var check_mute_inst = new PsychUICheckBox(10, 20, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.onClick = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

        var check_mute_vocals = new PsychUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.onClick = function()
		{
			if(vocals != null) {
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
			}
		};

        var check_mute_opponent = new PsychUICheckBox(check_mute_vocals.x + 120, check_mute_inst.y, "Mute Opponent (in editor)", 100);
		check_mute_opponent.checked = false;
		check_mute_opponent.onClick = function()
		{
			if(opponentVocals != null) {
				var vol:Float = 1;

				if (check_mute_opponent.checked)
					vol = 0;

				opponentVocals.volume = vol;
			}
		};

        var check_mute_gf = new PsychUICheckBox(check_mute_vocals.x + 120, check_mute_inst.y, "Mute Girlfriend (in editor)", 100);
		check_mute_opponent.checked = false;
		check_mute_opponent.onClick = function()
		{
			if(gfVocals != null) {
				var vol:Float = 1;

				if (check_mute_opponent.checked)
					vol = 0;

				gfVocals.volume = vol;
			}
		};


        var resetSpeed:PsychUIButton = new PsychUIButton(sliderRate.x+300, sliderRate.y, 'Reset', function ()
        {
            playbackSpeed = 1.0;
        });

        var saveJson:PsychUIButton = new PsychUIButton(20, 300, 'Save Modchart', function ()
        {
            saveModchartJson();
        });
        addUI(tab_group, "saveJson", saveJson, 'Save Modchart', 'Saves the modchart to a .json file which can be stored and loaded later.');
        //tab_group.addAsset(saveJson, "saveJson");
		tab_group.add(sliderRate);
        addUI(tab_group, "resetSpeed", resetSpeed, 'Reset Speed', 'Resets playback speed to 1.');
        tab_group.add(songSlider);

        tab_group.add(check_mute_inst);
        tab_group.add(check_mute_vocals);
    }

    function addUI(tab_group:FlxSpriteGroup, name:String, ui:FlxSprite, title:String = "", body:String = "", anchor:Anchor = null)
        tab_group.add(ui);



    function centerXToObject(obj1:FlxSprite, obj2:FlxSprite) //snap second obj to first
    {
        obj2.x = obj1.x + (obj1.width/2) - (obj2.width/2);
    }

    function makeLabel(obj:FlxSprite, offsetX:Float, offsetY:Float, textStr:String)
    {
        var text = new FlxText(0, obj.y+offsetY, 0, textStr);
        centerXToObject(obj, text);
        text.x += offsetX;
        return text;
    }


    var _file:FileReference;
    public function saveModchartJson() : Void
    {
        var data:String = Json.stringify(playfieldRenderer.modManager.modchartFile.data, "\t");
        if (ImprovedFileHandling.saveOperation("Save Modchart", {ext: "json", desc: "JSON File"}, Text, data)) {
            var newPath:String = ImprovedFileHandling.lastPath;
            trace('Chart saved successfully to: $newPath');
        }
        else
            trace('Error on saving chart!');

        hasUnsavedChanges = false;

    }
}

class ModchartEditorExitSubstate extends MusicBeatSubstate
{
    var exitFunc:Void->Void;
    override public function new(funcOnExit:Void->Void)
    {
        exitFunc = funcOnExit;
        super();
    }

    override public function create()
    {
        super.create();

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});


        var warning:FlxText = new FlxText(0, 0, 0, 'You have unsaved changes!\nAre you sure you want to exit?', 48);
        warning.alignment = CENTER;
        warning.screenCenter();
        warning.y -= 150;
        add(warning);

        var goBackButton:PsychUIButton = new PsychUIButton(0, 500, 'Go Back', function()
        {
            close();
        });
        goBackButton.scale.set(2.5, 2.5);
        goBackButton.updateHitbox();
        goBackButton.text.size = 12;
        goBackButton.x = (FlxG.width*0.3)-(goBackButton.width*0.5);
        add(goBackButton);

        var exit:PsychUIButton = new PsychUIButton(0, 500, 'Exit without saving', function()
        {
            exitFunc();
        });
        exit.scale.set(2.5, 2.5);
        exit.updateHitbox();
        exit.text.size = 12;
        exit.text.fieldWidth = exit.width;

        exit.x = (FlxG.width*0.7)-(exit.width*0.5);
        add(exit);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
    }
}
