package states.editors.content;
import backend.modchart.ModManager;
import flixel.math.FlxMath;
import haxe.Exception;
import haxe.Json;
import haxe.format.JsonParser;
import hscript.*;
import lime.utils.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef ModchartJson =
{
  var modifiers:Array<Array<Dynamic>>;
  var events:Array<Array<Dynamic>>;
  var playfields:Int;
}


class ModchartFile
{

  //used for indexing
  public static final MOD_NAME = 0; //the modifier name
  public static final MOD_CLASS = 1; //the class/custom mod it uses
  public static final MOD_TYPE = 2; //the type, which changes if its for the player, opponent, a specific lane or all
  public static final MOD_PF = 3; //the playfield that mod uses
  public static final MOD_LANE = 4; //the lane the mod uses

  public static final EVENT_TYPE = 0; //event type (set or ease)
  public static final EVENT_DATA = 1; //event data
  public static final EVENT_REPEAT = 2; //event repeat data

  public static final EVENT_TIME = 0; //event time (in beats)
  public static final EVENT_SETDATA = 1; //event data (for sets)
  public static final EVENT_EASETIME = 1; //event ease time
  public static final EVENT_EASE = 2; //event ease
  public static final EVENT_EASEDATA = 3; //event data (for eases)

  public static final EVENT_REPEATBOOL = 0; //if event should repeat
  public static final EVENT_REPEATCOUNT = 1; //how many times it repeats
  public static final EVENT_REPEATBEATGAP = 2; //how many beats in between each repeat


  public var data:ModchartJson = null;
  private var modManager:ModManager;
  public var scriptListen:Bool = false;
  public function new(modManager:ModManager)
  {

    data = loadFromJson(PlayState.SONG.song.toLowerCase());
    this.modManager = modManager;
    loadEvents();
  }

  public function loadFromJson(folder:String):ModchartJson //load da shit
  {
    var rawJson = null;
    var folderShit:String = "";
    #if sys
    var moddyFile:String = Paths.modsJson(Paths.formatToSongPath(folder) + '/modchart');
    if(FileSystem.exists(moddyFile)) {
      rawJson = File.getContent(moddyFile).trim();
      folderShit = moddyFile.replace("modchart.json", "customMods/");
    }
    #end
    if (rawJson == null)
    {
      var filePath = Paths.json(folder + '/modchart');
      folderShit = filePath.replace("modchart.json", "customMods/");

      //trace(filePath);
      #if sys
      if(FileSystem.exists(filePath))
        rawJson = File.getContent(filePath).trim();
      else #end //should become else if i think???
        if (Assets.exists(filePath))
          rawJson = Assets.getText(filePath).trim();

    }
    var json:ModchartJson = null;
    if (rawJson != null)
    {
      json = cast Json.parse(rawJson);
      //trace('loaded json');
      trace(folderShit);
      #if sys
      if (FileSystem.isDirectory(folderShit))
      {
        //trace("folder le exists");
        for (file in FileSystem.readDirectory(folderShit))
        {
          //trace(file);
          if(file.endsWith('.hx')) //custom mods!!!!
          {
            modManager.addHScriptModifier(file.replace(".hx", ""));
            //trace('loaded custom mod: ' + file);
          }
        }
      }
      #end
    }
    else
    {
      json = {modifiers: [], events: [], playfields: 2};
    }
    return json;
  }
  public function loadEmpty()
  {
    data.modifiers = [];
    data.events = [];
    data.playfields = 2;
  }

  public function loadEvents()
  {
    if (data == null)
      return;

    for (i in data.events)
    {
      if (i[EVENT_REPEAT] == null) //add repeat data if it doesnt exist
        i[EVENT_REPEAT] = [false, 1, 0];

      if (i[EVENT_REPEAT][EVENT_REPEATBOOL])
      {
        for (j in 0...(Std.int(i[EVENT_REPEAT][EVENT_REPEATCOUNT])+1))
        {
          addEvent(i, (j*i[EVENT_REPEAT][EVENT_REPEATBEATGAP]));
        }
      }
      else
      {
        addEvent(i);
      }
    }
  }

  private function addEvent(i:Array<Dynamic>, ?beatOffset:Float = 0)
  {
    switch(i[EVENT_TYPE])
    {
      case "ease":
        var beat:Float = Std.parseFloat(i[EVENT_DATA][EVENT_TIME])+beatOffset;
        var time:Float = Std.parseFloat(i[EVENT_DATA][EVENT_EASETIME])*Conductor.crochet*0.001;
        var ease:String = i[EVENT_DATA][EVENT_EASEDATA];
        var argsAsString:String = i[EVENT_DATA][EVENT_EASEDATA];
        var args = argsAsString.trim().replace(' ', '').split(',');
        var func = function(arguments:Array<String>) {
          for (e in 0...Math.floor(arguments.length/2))
          {
            var name:String = Std.string(arguments[1 + (e*2)]);
            var value:Float = Std.parseFloat(arguments[0 + (e*2)]);
            if(Math.isNaN(value))
              value = 0;
            var subModCheck = name.split(':');
            if (subModCheck.length > 1)
            {
              var modName = subModCheck[0];
              var subModName = subModCheck[1];
              //trace(subModCheck);
              modManager.queueEaseLB(beat, time, subModName, value, ease);
            }
            else
              modManager.queueEaseLB(beat, time, name, value, ease);
          }
        }
        func(args);
      case "set":
        var argsAsString:String = i[EVENT_DATA][EVENT_SETDATA];
        var beat:Float = Std.parseFloat(i[EVENT_DATA][EVENT_TIME])+beatOffset;
        var args = argsAsString.trim().replace(' ', '').split(',');
        var func = function(arguments:Array<String>) {
          for (e in 0...Math.floor(arguments.length/2))
          {
            var name:String = Std.string(arguments[1 + (e*2)]);
            var value:Float = Std.parseFloat(arguments[0 + (e*2)]);
            if(Math.isNaN(value))
              value = 0;
            if (modManager.register.exists(name))
            {
              modManager.queueSet(beat, name, value);
            }
            else
            {
              var subModCheck = name.split(':');
              if (subModCheck.length > 1)
              {
                var modName = subModCheck[0];
                var subModName = subModCheck[1];
                if (modManager.register.exists(modName))
                  modManager.queueSet(beat, subModName, value);
              }
            }
          }
        }
        func(args);
      case "hscript":
        //maybe just run some code???
    }
  }

  public function createDataFromRenderer() //a way to convert script modcharts into json modcharts
  {
    scriptListen = true;
  }
}
