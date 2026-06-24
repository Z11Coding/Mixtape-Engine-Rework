package managers;
import objects.Character;

enum CManType {
  NONE;
  BF;
  DAD;
  GF;
  BF2;
  DAD2;
}

class CharacterManager {

  public static var instance:CharacterManager;

  public var dad:Character = null;
	public var dad2:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	public var bf2:Character = null;

  public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var BF2_X:Float = 770;
	public var BF2_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var DAD2_X:Float = 100;
	public var DAD2_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

  public var characterMap:Map<String, Map<String, Character>> = new Map<String, Map<String, Character>>();
  public var characterGroupMap:Map<String, FlxSpriteGroup> = new Map<String, FlxSpriteGroup>();

  public var curState:MusicBeatState = null;
  public var curSubState:MusicBeatSubstate = null;

  public function new() {
    instance = this;
  }

  public function addCharacterToState(chara:Character)
    (curSubState != null ? curSubState : curState).add(chara);

  public function makeNewCharacter(x:Int, y:Int, character:String, isBF:Bool, cType:CharType, manType:CManType):Character {
    var chara = new Character(x, y, character, isBF, cType);
    startCharacterPos(chara, (cType != GF));
    var charGroup:FlxSpriteGroup = switch(manType) {
      case BF:
        if (!characterGroupMap.exists("boyfriendGroup")) characterGroupMap.set("boyfriendGroup", new FlxSpriteGroup(BF_X, BF_Y));
        characterGroupMap.get("boyfriendGroup");
      case DAD:
        if (!characterGroupMap.exists("dadGroup")) characterGroupMap.set("dadGroup", new FlxSpriteGroup(DAD_X, DAD_Y));
        characterGroupMap.get("dadGroup");
      case GF:
        if ((!characterGroupMap.exists("gfGroup") || characterGroupMap.exists("gfGroup") && characterGroupMap.get("gfGroup") == null)) characterGroupMap.set("gfGroup", new FlxSpriteGroup(GF_X, GF_Y));
        characterGroupMap.get("gfGroup");
      case BF2:
        if (!characterGroupMap.exists("boyfriendGroup2")) characterGroupMap.set("boyfriendGroup2", new FlxSpriteGroup(BF2_X, BF2_Y));
        characterGroupMap.get("boyfriendGroup2");
      case DAD2:
        if (!characterGroupMap.exists("dadGroup2")) characterGroupMap.set("dadGroup2", new FlxSpriteGroup(DAD2_X, DAD2_Y));
        characterGroupMap.get("dadGroup2");
      case NONE:
        if (!characterGroupMap.exists("exGroup")) characterGroupMap.set("exGroup", new FlxSpriteGroup());
        characterGroupMap.get("exGroup");
    }
    charGroup.add(chara);
    return chara;
  }

  public function preloadCharacter(character:String, isBF:Bool, cType:CharType, manType:CManType):Character {
    var charMap = switch(manType) {
      case BF:
        if (!characterMap.exists("boyfriendMap")) characterMap.set("boyfriendMap", new Map<String, Character>());
        characterMap.get("boyfriendMap");
      case DAD:
        if (!characterMap.exists("dadMap")) characterMap.set("dadMap", new Map<String, Character>());
        characterMap.get("dadMap");
      case GF:
        if (!characterMap.exists("gfMap")) characterMap.set("gfMap", new Map<String, Character>());
        characterMap.get("gfMap");
      case BF2:
        if (!characterMap.exists("boyfriendMap2")) characterMap.set("boyfriendMap2", new Map<String, Character>());
        characterMap.get("boyfriendMap2");
      case DAD2:
        if (!characterMap.exists("dadMap2")) characterMap.set("dadMap2", new Map<String, Character>());
        characterMap.get("dadMap2");
      case NONE:
        if (!characterMap.exists("exMap")) characterMap.set("exMap", new Map<String, Character>());
        characterMap.get("exMap");
    }

    var chara:Character = makeNewCharacter(0, 0, character, isBF, cType, manType);
    if (!charMap.exists(character)) {
      charMap.set(character, chara);
    }
    return chara;
  }

  public function makeExistingCharacter(character:Character, manType:CManType):Character {
    startCharacterPos(character, (character.charType != GF));
    var charGroup:FlxSpriteGroup = switch(manType) {
      case BF:
        if (!characterGroupMap.exists("boyfriendGroup")) characterGroupMap.set("boyfriendGroup", new FlxSpriteGroup(BF_X, BF_Y));
        characterGroupMap.get("boyfriendGroup");
      case DAD:
        if (!characterGroupMap.exists("dadGroup")) characterGroupMap.set("dadGroup", new FlxSpriteGroup(DAD_X, DAD_Y));
        characterGroupMap.get("dadGroup");
      case GF:
        if ((!characterGroupMap.exists("gfGroup") || characterGroupMap.exists("gfGroup") && characterGroupMap.get("gfGroup") == null)) characterGroupMap.set("gfGroup", new FlxSpriteGroup(GF_X, GF_Y));
        characterGroupMap.get("gfGroup");
      case BF2:
        if (!characterGroupMap.exists("boyfriendGroup2")) characterGroupMap.set("boyfriendGroup2", new FlxSpriteGroup(BF2_X, BF2_Y));
        characterGroupMap.get("boyfriendGroup2");
      case DAD2:
        if (!characterGroupMap.exists("dadGroup2")) characterGroupMap.set("dadGroup2", new FlxSpriteGroup(DAD2_X, DAD2_Y));
        characterGroupMap.get("dadGroup2");
      case NONE:
        if (!characterGroupMap.exists("exGroup")) characterGroupMap.set("exGroup", new FlxSpriteGroup());
        characterGroupMap.get("exGroup");
    }
    charGroup.add(character);
    return character;
  }

  public function preloadExistingCharacter(charaName:String, character:Character, manType:CManType):Character {
    var charMap = switch(manType) {
      case BF:
        if (!characterMap.exists("boyfriendMap")) characterMap.set("boyfriendMap", new Map<String, Character>());
        characterMap.get("boyfriendMap");
      case DAD:
        if (!characterMap.exists("dadMap")) characterMap.set("dadMap", new Map<String, Character>());
        characterMap.get("dadMap");
      case GF:
        if (!characterMap.exists("gfMap")) characterMap.set("gfMap", new Map<String, Character>());
        characterMap.get("gfMap");
      case BF2:
        if (!characterMap.exists("boyfriendMap2")) characterMap.set("boyfriendMap2", new Map<String, Character>());
        characterMap.get("boyfriendMap2");
      case DAD2:
        if (!characterMap.exists("dadMap2")) characterMap.set("dadMap2", new Map<String, Character>());
        characterMap.get("dadMap2");
      case NONE:
        if (!characterMap.exists("exMap")) characterMap.set("exMap", new Map<String, Character>());
        characterMap.get("exMap");
    }

    if (!charMap.exists(charaName)) {
      charMap.set(charaName, character);
      return character;
    }
    return null;
  }

  public function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in PlayState.instance.luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
      @:privateAccess
			if(doPush)
				MusicBeatState.getState().scripts.startLuasNamed(luaFile);

		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			for (script in PlayState.instance.hscriptArray)
			{
				if(script.origin == scriptFile)
				{
					doPush = false;
					break;
				}
			}

			if(doPush) MusicBeatState.getState().scripts.initHScript(scriptFile);
		}
		#end

		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.ys';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			for (script in PlayState.instance.yscriptArray)
			{
				if(script.scriptPath == scriptFile)
				{
					doPush = false;
					break;
				}
			}

			if(doPush) MusicBeatState.getState().scripts.initYScript(scriptFile);
		}
	}

  public function startCharListFromScripts(charList:Array<Character>) {
    for (char in charList) {
      if (char != null) startCharacterScripts(char.curCharacter);
    }
  }

  public function destroyAll(?includeCGroups:Bool = true, ?includeCMaps:Bool = true) {
    if (includeCGroups) {
      for (group in characterGroupMap) {
        if (group != null) {
          for (char in group) {
            char.destroy();
            char = null;
          }
          group.clear();
          group.destroy();
          group = null;
        }
      }
      characterGroupMap.clear();
      characterGroupMap = new Map<String, FlxSpriteGroup>();
    }

    if (includeCMaps) {
      for (map in characterMap) {
        if (map != null) {
          for (char in map) {
            char = null;
          }
          map.clear();
          map = null;
        }
      }
      characterMap.clear();
      characterMap = new Map<String, Map<String, Character>>();
    }

    dad = null;
    dad2 = null;
    gf = null;
    boyfriend = null;
    bf2 = null;

    BF_X = 770;
    BF_Y = 100;
    BF2_X = 770;
    BF2_Y = 100;
    DAD_X = 100;
    DAD_Y = 100;
    DAD2_X = 100;
    DAD2_Y = 100;
    GF_X = 400;
    GF_Y = 130;
  }

  public function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}
}
