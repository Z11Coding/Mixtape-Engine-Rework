package undertale;

typedef DialogueSettings = {
  var sound:String;
  var color:FlxColor;
  var music:String;
  var addStatic:Bool;
  var addChroma:Bool;
  var font:String;
  var speed:Float;
}

class UnderDialManager implements FlxTypedGroup<Dynamic> {
  public var textBox:UnderTextBox;
  public var curDialogue:Array<String> = [];
  public var portrait:FlxSprite = null; // TODO: Get this working

  var daStatic:FlxSprite;
  var camfilters:Array<BitmapFilter> = [];
  var alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];

  // Dialogue Manager
  var curDial:Int = 0;

  public var onDialStart:Void->Void;
  public var onDialNext:Void->Void;
  public var onDialSkip:Void->Void;
  public var onDialEnd:Void->Void;

  final defaultSettings:DialogueSettings = {
    sound: "uifont",
    color: FlxColor.WHITE,
    music: "",
    addStatic: false,
    addChroma: false,
    font: "fnf1",
    speed: 0.2
  };

  public function new(dialSetting:DialogueSettings) {
    var settings:DialogueSettings = dialSetting ?? defaultSettings;

    textBox = new UnderTextBox(settings.font, settings.sounds, settings.color, settings.speed);
    curDial = 0;

    daStatic = new FlxSprite(0, 0);
		daStatic.frames = Paths.getSparrowAtlas('effects/static');
		daStatic.setGraphicSize(FlxG.width, FlxG.height);
		daStatic.screenCenter();
		daStatic.animation.addByPrefix('static','lestatic',24, true);
		daStatic.animation.play('static', true);
		add(daStatic);
    daStatic.visible = settings.addStatic ?? false;

    if (settings.addChroma != null && settings.addChroma) {
      FlxG.camera.setFilters(camfilters);
      FlxG.camera.filtersEnabled = true;
      camfilters.push(shaders.ShadersHandler.chromaticAberration);
    }
    if (settings.music != null && settings.music != "")
      FlxG.sound.music.play(Paths.music(settings.music));
  }

  override function update(elapsed:Float)
  {
    if (curDial <= curDialogue.length && (FlxG.keys.justPressed.ENTER || controls.ACCEPT)) {
      if (onDialNext != null) onDialNext();
      textBox.typeFunc(curDialogue[curDial]);
      curDial++;
    } else if (curDial <= curDialogue.length && (FlxG.keys.justPressed.ESCAPE || controls.BACK)) {
      if (onDialSkip != null) onDialSkip();
      curDial = curDialogue.length+1;
      textBox.typeFunc(true);
    } else if (curDial > curDialogue.length) {
      if (onDialEnd != null) onDialEnd();
      textBox.typeFunc(true);
    }

    super.update(elapsed);
  }

  public function loadDialogue(dial:Array<String>, ?dialSetting:DialogueSettings) {
    var settings:DialogueSettings = dialSetting ?? defaultSettings;
    curDial = 0;
    curDialogue = dial;
    daStatic.visible = settings.addStatic ?? false;
    textBox.formatText(settings.font, settings.sounds, settings.color, settings.speed);
    if (settings.addChroma != null && settings.addChroma) {
      FlxG.camera.setFilters(camfilters);
    } else {
      FlxG.camera.setFilters([]);
    }

    if (settings.music != null && settings.music != "")
      FlxG.sound.music.play(settings.music);
    if (onDialStart != null) onDialStart();
  }
}
