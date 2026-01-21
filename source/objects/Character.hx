package objects;

import backend.Song;
import backend.animation.PsychAnimationController;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;
import haxe.Json;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import stages.objects.TankmenBG;

#if LUA_ALLOWED
import backend.funkinmodchart.Manager;
import psychlua.*;

using psychlua.IntegratedScript;
#else
import psychlua.HScript;
import psychlua.LuaUtils;
#end

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	@:optional var name:String;
	@:optional var pronouns:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray = {
	var anim:Null<String>;
	var name:Null<String>;
	var prefix:Null<String>;
	var fps:Null<Int>;
	var loop:Null<Bool>;
	var indices:Null<Array<Int>>;
	var offsets:Null<Array<Int>>;
}

enum CharType {
	BF;
	GF;
	DAD;
	OTHER;
}

class Character extends FunkinSprite
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var charName:String = '???';
	public var charPronouns:Array<String> = ['???', '???']; // please dont make me regret this

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	public var invuln:Bool = false;
	public var controlled:Bool = false;

	public var doubleGhosts:Array<FlxSprite> = [];
	public var ghostID:Int = 0;
	public var ghostAnim:String = '';
	public var ghostTweenGrp:Array<FlxTween> = [];

	public var mostRecentRow:Int = 0; // for ghost anims n shit

	// This is literally only for the dropshadow shader
	public var charType:CharType = OTHER;

	public static var animationsLoaded:Bool = false;

	//Stuff from base game
	/**
   * The offset between the corner of the sprite and the origin of the sprite (at the character's feet).
   * cornerPosition = stageData - characterOrigin
   */
  public var characterOrigin(get, never):FlxPoint;

  function get_characterOrigin():FlxPoint
  {
    var xPos = (width / 2); // Horizontal center
    var yPos = (height); // Vertical bottom
    return new FlxPoint(xPos, yPos);
  }

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?chType:CharType = OTHER)
	{
		super(x, y);

		for(i in 0...4){
			var ghost = new FlxSprite();
			ghost.visible = false;
			ghost.antialiasing = true;
			ghost.alpha = 0.6;
			doubleGhosts.push(ghost);
		}

		animOffsets = new Map<String, Array<Dynamic>>();
		this.isPlayer = isPlayer;
		this.charType = chType;
		changeCharacter(character);

		switch(curCharacter)
		{
			case 'pico-speaker'|'otis-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}

		if (PlayState.instance != null)
		{
			switch(Paths.formatToSongPath(Song.loadedSongName))
			{
				case 'fangirl-frenzy':
					if ((curCharacter == "Zenetta" || curCharacter == "Z11-true-player") && !animationsLoaded)
					{
						trace("Load FF");
						loadMappedAnimsFF();
					}
			}
		}
	}

	public function changeCharacter(character:String)
	{

		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'characters/$character.json';

		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;

		if (json.version != null) {
			switch (json.version) {
				default:
					var animToFind:String = Paths.getPath('images/' + json.assetPath + '/Animation.json', TEXT);
					if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
						isAnimateAtlas = true;

					scale.set(1, 1);
					updateHitbox();

					if(!isAnimateAtlas)
					{
						frames = Paths.getMultiAtlas(json.assetPath.split(','));
					}
					else
					{
						loadTextureAtlas(json.assetPath);
					}

					charName = json.name != null ? json.name : '???';
					charPronouns = json.pronouns != null ? json.pronouns.split('/') : ['???', '???'];

					imageFile = json.assetPath;
					jsonScale = json.scale;
					if(json.scale != 1) {
						scale.set(jsonScale, jsonScale);
						updateHitbox();
					}

					// positioning
					positionArray = [0, 0];
					cameraPosition = [0, 0];

					// data
					healthIcon = json.healthicon.id;
					singDuration = json.singTime;
					flipX = (json.flipX != isPlayer);
					healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
					vocalsFile = json.vocals_file != null ? json.vocals_file : '';
					originalFlipX = (json.flipX == true);
					editorIsPlayer = (json._editor_isPlayer != null ? json._editor_isPlayer : false);

					// antialiasing
					noAntialiasing = (json.no_antialiasing != null && (json.no_antialiasing == true));
					antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

					// animations
					animationsArray = json.animations;
					if(animationsArray != null && animationsArray.length > 0) {
						for (anims in animationsArray) {
							var animAnim:String = '' + anims.anim;
							var animName:String = '' + anims.prefix;
							var animFps:Int = (anims.fps != null ? anims.fps : 24);
							var animLoop:Bool = (anims.loop != null ? !!anims.loop : false); //Bruh
							var animIndices:Array<Int> = (anims.indices != null ? anims.indices : []);

							if(!isAnimateAtlas)
							{
								if(animIndices != null && animIndices.length > 0)
									animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
								else
									animation.addByPrefix(animAnim, animName, animFps, animLoop);
							}
							else
							{
								if(animIndices != null && animIndices.length > 0)
									anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
								else
									anim.addBySymbol(animAnim, animName, animFps, animLoop);
							}

							if(anims.offsets != null && anims.offsets.length > 1) addOffset(anims.anim, anims.offsets[0], anims.offsets[1]);
							else addOffset(anims.anim, 0, 0);
						}
					}
			}
		} else {

			var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind)) {
				isAnimateAtlas = true;
			}

			trace('isAnimateAtlas: $isAnimateAtlas');

			scale.set(1, 1);
			updateHitbox();

			if(!isAnimateAtlas)
			{
				frames = Paths.getMultiAtlas(json.image.split(','));
			}
			else
			{
				loadTextureAtlas(json.image);
			}

			imageFile = json.image;
			jsonScale = json.scale;
			if(json.scale != 1) {
				scale.set(jsonScale, jsonScale);
				updateHitbox();
			}

			// positioning
			positionArray = json.position;
			cameraPosition = json.camera_position;

			// data
			healthIcon = json.healthicon;
			singDuration = json.sing_duration;
			flipX = (json.flip_x != isPlayer);
			healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
			vocalsFile = json.vocals_file != null ? json.vocals_file : '';
			originalFlipX = (json.flip_x == true);
			editorIsPlayer = json._editor_isPlayer;

			// antialiasing
			noAntialiasing = (json.no_antialiasing == true);
			antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

			// animations
			animationsArray = json.animations;
			if(animationsArray != null && animationsArray.length > 0) {
				for (anims in animationsArray) {
					var animAnim:String = '' + anims.anim;
					var animName:String = '' + anims.name;
					var animFps:Int = anims.fps;
					var animLoop:Bool = !!anims.loop; //Bruh
					var animIndices:Array<Int> = anims.indices;

					if(!isAnimateAtlas)
					{
						if(animIndices != null && animIndices.length > 0)
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						else
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
					else
					{
						if(animIndices != null && animIndices.length > 0)
							anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
						else
							anim.addBySymbol(animAnim, animName, animFps, animLoop);
					}

					if(anims.offsets != null && anims.offsets.length > 1) addOffset(anims.anim, anims.offsets[0], anims.offsets[1]);
					else addOffset(anims.anim, 0, 0);
				}
			}
		}
		//trace('Loaded file to character ' + curCharacter);
	}

	public static function grabCharInfo(character:String):Map<String, Dynamic> {
		var infoArray:Map<String, Dynamic> = [];

		var characterPath:String = 'characters/$character.json';
		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		var json:Dynamic = null;
		try
		{
			#if MODS_ALLOWED
			json = Json.parse(File.getContent(path));
			#else
			json = Json.parse(Assets.getText(path));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		infoArray.set("Image", json.image);
		infoArray.set("Scale", json.scale);
		// positioning
		infoArray.set("Position", json.position);
		infoArray.set("Camera Position", json.camera_position);
		// data
		infoArray.set("Health Icon", json.healthicon);
		infoArray.set("Sing Duration", json.sing_duration);
		infoArray.set("Flip X", json.flip_x);
		infoArray.set("Health Colors", (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161]);
		infoArray.set("Vocal File", json.vocals_file != null ? json.vocals_file : '');
		infoArray.set("Original Flip X", (json.flip_x == true));
		// antialiasing
		infoArray.set("No Antialiasing", (json.no_antialiasing == true));
		// animations
		infoArray.set("Animations", json.animations);
		return infoArray;
	}

	override function update(elapsed:Float)
	{
		if (debugMode || isAnimationNull())
		{
			super.update(elapsed);
			return;
		}

		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}

		if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch(curCharacter)
		{
			case 'pico-speaker'|'otis-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (PlayState.instance != null)
		{
			switch(Paths.formatToSongPath(Song.loadedSongName))
			{
				case 'fangirl-frenzy':
					switch (curCharacter)
					{
						case 'Z11-true-player':
							if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
							{
								var noteData:Int = -1;
								noteData = Std.int(animationNotes[0][1] % 4);
								var animToPlay:String = Note.keysShit.get(3).get('singAnims')[Std.int(Math.abs(noteData))];
								playAnim(animToPlay, true);
								holdTimer = -Math.max(Conductor.stepCrochet * 1.25, (FlxG.sound.music.time - animationNotes[0][0])) / 1000 / PlayState.instance?.playbackRate;
								animationNotes.shift();
							}
							//if (isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);

						case "Zenetta":
							if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
							{
								var noteData:Int = 1;
								noteData = Std.int(animationNotes[0][1] % 4);
								var animToPlay:String = Note.keysShit.get(3).get('singAnims')[Std.int(Math.abs(noteData))];
								playAnim(animToPlay, true);
								holdTimer = -Math.max(Conductor.stepCrochet * 1.25, (FlxG.sound.music.time - animationNotes[0][0])) / 1000 / PlayState.instance?.playbackRate;
								animationNotes.shift();
							}
							//if (isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
					}
			}
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && hasAnimation('$name-loop'))
			playAnim('$name-loop');

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && anim.curAnim == null))
		{
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
	{
		@:privateAccess
		return !isAnimateAtlas ? (animation.curAnim == null) : (anim.curAnim == null);
	}

	var _lastPlayedAnimation:String;
	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		else anim.curAnim.curFrame = anim.curAnim.numFrames - 1;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : !anim.curAnim.paused;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else anim.curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;
	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(hasAnimation('idle' + idleSuffix))
				playAnim((hasAnimation('blink') && FlxG.random.float(0, 1) < 0.025) ? 'blink' : 'idle' + idleSuffix);
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		var ret:Dynamic = PlayState.instance?.callOnScripts('onPlayAnimPre', [AnimName, Force, Reversed, Frame]);
		if(ret != LuaUtils.Function_Stop) {
			specialAnim = false;
			if(!isAnimateAtlas)
			{
				try {animation.play(AnimName, Force, Reversed, Frame);}
				catch(e) {trace('Animation no workie :(\nAnim that attempted to play: $AnimName\nCharacter that tried to play it: $curCharacter');}
			}
			else
			{
				anim.play(AnimName, Force, Reversed, Frame);
				update(0);
			}
			_lastPlayedAnimation = AnimName;

			try {
				if (hasAnimation(AnimName))
				{
					var daOffset = animOffsets.get(AnimName);
					offset.set(daOffset[0], daOffset[1]);
				}
			}
			catch(e) {trace('Animation offset no workie :(\nAnim that attempted to play: $AnimName\nCharacter that tried to play it: $curCharacter');}
			//else offset.set(0, 0);

			if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
			{
				if (AnimName == 'singLEFT')
					danced = true;

				else if (AnimName == 'singRIGHT')
					danced = false;

				if (AnimName == 'singUP' || AnimName == 'singDOWN')
					danced = !danced;
			}

			if (Paths.formatToSongPath(Song.loadedSongName) == 'fangirl-frenzy')
			{
				switch (curCharacter)
				{
					case 'Z11-true-player':
						if (animation.curAnim.name != 'idle') PlayState.instance.health += 0.023 * ClientPrefs.getGameplaySetting('healthgain', 1);
					case "Zenetta":
						if (!animation.curAnim.name.contains('dance')) PlayState.instance.health -= 0.023 * ClientPrefs.getGameplaySetting('healthloss', 1);
				}
			}
		}

		PlayState.instance?.callOnScripts('onPlayAnim', [AnimName, Force, Reversed, Frame]);
	}

	function loadMappedAnims():Void
	{
		try
		{
			var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function loadMappedAnimsFF():Void
	{
		trace("Loaded FF");
		try
		{
			var songData:SwagSong = Song.getChart('fangirl-frenzy-other', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for (section in songData.notes)
					for (songNotes in section.sectionNotes) {
						switch (curCharacter) {
							case 'Z11-true-player':
								if (songNotes[1] > 3) continue; // only player notes
							case "Zenetta":
								if (songNotes[1] < 4) continue; // only opponent notes
						}
						animationNotes.push(songNotes);
					}
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {trace("Failed To Load FF!");}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public function playGhostAnim(ghostID = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0) {
		try {
			var ghost:FlxSprite = doubleGhosts[ghostID];
			ghost.scale.copyFrom(scale);
			ghost.frames = frames;
			ghost.animation.copyFrom(animation);
			ghost.antialiasing = antialiasing;
			ghost.x = x;
			ghost.y = y;
			ghost.flipX = flipX;
			ghost.flipY = flipY;
			ghost.alpha = alpha * 0.6;
			ghost.visible = true;
			ghost.color = ghost.color = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
			ghost.animation.play(animName, force, reversed, frame);

			ghostTweenGrp[ghostID]?.cancel();

			var direction:String = animName.substring(4);

			var directionMap:Map<String, Array<Float>> = [
				'UP' => [0, -45],
				'DOWN' => [0, 45],
				'RIGHT' => [45, 0],
				'LEFT' => [-45, 0],
				'UP-alt' => [0, -45],
				'DOWN-alt' => [0, 45],
				'RIGHT-alt' => [45, 0],
				'LEFT-alt' => [-45, 0],
			];
			//had to add alt cuz it kept crashing on room code LOL

			var moveDirections:Array<Float> = [
				x + (directionMap.get(direction)[0]),
				y + (directionMap.get(direction)[1])
			];

			ghostTweenGrp[ghostID] = FlxTween.tween(ghost, {alpha: 0, x: moveDirections[0], y: moveDirections[1]}, 0.75,
			{
				onComplete: (twn) -> {
					ghost.visible = false;
					ghostTweenGrp[ghostID] = null;
				}
			});

			if (animOffsets.exists(animName))
			{
				final daOffset = animOffsets.get(animName);
				ghost.offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
			}
		} catch(e) {trace("Nah im good actually");}
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	public override function draw()
	{
		for(ghost in doubleGhosts){
			if(ghost.visible)
				ghost.draw();
		}

		var lastAlpha:Float = alpha;
		var lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		if(isAnimateAtlas)
		{
			if(anim.curAnim != null)
			{
				alpha = lastAlpha;
				color = lastColor;
				if(missingCharacter && visible)
				{
					missingText.x = getMidpoint().x - 150;
					missingText.y = getMidpoint().y - 10;
					missingText.draw();
				}
			}
			super.draw();
			return;
		}

		super.draw();

		if(missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.draw();
		}
	}

	public override function destroy()
	{
		if (ghostTweenGrp != null && ghostTweenGrp.length > 0)
		{
			for (i in ghostTweenGrp)
				i?.cancel();
		}

		ghostTweenGrp = FlxDestroyUtil.destroyArray(ghostTweenGrp);

		doubleGhosts = FlxDestroyUtil.destroyArray(doubleGhosts);
		super.destroy();
	}
}
