package objects.notes;

import backend.NoteTypesConfig;
import play.objects.SustainSplash;
import shaders.RGBPalette.RGBShaderReference;
import shaders.RGBPalette;

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 *
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/

class Note extends FlxSprite
{
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var parentST:Float = 0;
	public var parentSL:Float = 0;
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var doOppStuff:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false; //For Opponent notes

	public var blockHit:Bool = false; // only works for player

	public var noteDensity:Float = 1;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = Type.getClassName(Type.getClass(FlxG.state)) == 'editors.ChartingState';

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 0.5;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static final SUSTAIN_SIZE:Int = 44;
	public static final swagWidth:Float = 160 * 0.7;

	public static final colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteskins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? (!PlayState.SONG.disableNoteRGB) : true,
		r: -1,
		g: -1,
		b: -1,
		a: 1
	};
	public var noteHoldSplash:SustainSplash;

	// Lua shit
	public var noteSplashDisabled:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyScaleX:Bool = true;
	public var copyScaleY:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var sustainScale:Float = 1.0;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	public var pixelNote:Bool = false;
	public var useRGBShader(default, set):Bool = true;

	private function set_useRGBShader(value:Bool):Bool {
		if (useRGBShader != value)
		{
			useRGBShader = value;
			if (rgbShader != null) rgbShader.enabled = value;
		}
		return value;
	}

	var changeSize:Bool = false;

	private function set_texture(value:String):String {
		if (value.length == 0) value = Paths.defaultSkin;
		if (!pixelNote && texture != value)
		{
			changeSize = false;
			if (!Paths.noteSkinFramesMap.exists(value)) Paths.initNote(value);
			if (frames != @:privateAccess Paths.noteSkinFramesMap.get(value)) frames = @:privateAccess Paths.noteSkinFramesMap.get(value);
			if (animation != @:privateAccess Paths.noteSkinAnimsMap.get(value)) animation.copyFrom(@:privateAccess Paths.noteSkinAnimsMap.get(value));

			antialiasing = ClientPrefs.globalAntialiasing;

			if (!changeSize)
			{
				changeSize = true;
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
			}
			offsetX = 0;
		}
		else if (!pixelNote) return value;
		else if (pixelNote && inEditor) reloadNote(value);
		texture = value;
		return value;
	}

	var noteColor:Array<FlxColor>;
	public function defaultRGB()
	{
		noteColor = !PlayState.isPixelStage ? ClientPrefs.data.arrowRGBExtra[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] : ClientPrefs.data.arrowRGBPixelExtra[ExtraKeys.keysShit.get(ExtraKeys.mania).get('pixelAnimIndex')[noteData]];

    if (noteColor != null && noteData > -1 && noteData <= ExtraKeys.mania) {
      rgbShader.r = noteColor[0];
      rgbShader.g = noteColor[1];
      rgbShader.b = noteColor[2];

      #if ARCHIPELAGO_ALLOWED
      if (this is archipelago.APNote)
      {
        trace("AP Color.");
        shader = null;
      }
      #end
    }
    else
		{
			if (rgbShader != null) {
				rgbShader.r = 0xFFFF0000;
				rgbShader.g = 0xFF00FF00;
				rgbShader.b = 0xFF0000FF;
			}
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		if (ClientPrefs.noteColorStyle == 'Normal' && rgbShader != null && useRGBShader) defaultRGB();

		if(noteData > -1 && noteType != value) {
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
      if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound);
			noteType = value;
		}
		return value;
	}

	public function toJson(){
		return Json.stringify({
			type:"Note",
			strumTime:strumTime,
			noteData:noteData,
			noteType:noteType,
			mustPress:mustPress
		});
	}
	public override function toString(){
		return Std.string({
			type:"Note",
			strumTime:strumTime,
			noteData:noteData,
			noteType:noteType,
			mustPress:mustPress
		});
	}

	public function new(?newStrumTime:Float, ?newNoteData:Int)
	{
		super();

		pixelNote = PlayState.isPixelStage;

		if (!Math.isNaN(newNoteData) && pixelNote) noteData = newNoteData;
		if (!Math.isNaN(newStrumTime)) strumTime = newStrumTime;

		y -= 2000;
		antialiasing = ClientPrefs.data.globalAntialiasing && !pixelNote;

		if(noteData > -1) {
			texture = '';

      try{ rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this)); }
      catch(e) {};
      if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;

      if (PlayState.isPixelStage || getNoteSkinPostfix().toLowerCase() == '-retribution')
				rgbShader.enabled = false;

      x += swagWidth * (noteData % Note.ammo[ExtraKeys.mania]);
		}
	}

	public static function initializeGlobalRGBShader(noteData:Int = 0, ?note:Note = null)
	{
		if (note == null)
		{
			if(globalRgbShaders[noteData] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[noteData] = newRGB;

				var arr:Array<FlxColor> = ClientPrefs.data.noteColorStyle != 'Quant-Based' ? (!PlayState.isPixelStage) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData] : ClientPrefs.quantRGB[noteData];
				if (arr != null && noteData > -1 && noteData <= arr.length)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return globalRgbShaders[noteData];
		}
		else switch(ClientPrefs.noteColorStyle)
		{
			case 'Quant-Based':
			if(globalRgbShaders[0] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[0] = newRGB;

				var arr:Array<FlxColor> = (!note.pixelNote) ? ClientPrefs.arrowRGB[3] : ClientPrefs.arrowRGBPixel[3];
				if (noteData > -1)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return globalRgbShaders[0];
			case 'Grayscale', 'Rainbow', 'Char-Based':
			if(globalRgbShaders[0] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[0] = newRGB;

				if (noteData > -1)
				{
					newRGB.r = 0xFFA0A0A0;
					newRGB.g = FlxColor.WHITE;
					newRGB.b = 0xFF424242;
				}
			}
			return globalRgbShaders[0];
			default:
			if(globalRgbShaders[noteData] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[noteData] = newRGB;

				var arr:Array<FlxColor> = (!note.pixelNote) ? ClientPrefs.arrowRGB[noteData] : ClientPrefs.arrowRGBPixel[noteData];
				if (noteData > -1 && noteData <= arr.length)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return globalRgbShaders[noteData];
		}
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	private function reloadNote(?texture:String = '', ?postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			skin = PlayfieldManager.SONG != null ? PlayfieldManager.SONG.arrowSkin : null;
			if (skin == null || skin.length < 1)
				skin = "noteSkins/NOTE_assets" + postfix;
		}

		var animName:String = null;
		if(animation != null && animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = (scale != null ? scale.y : 0.7);
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = pixelNote ? 'pixelUI/' : '';
		if(skinPostfix != '' && (customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE)))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

    //Now lets do a psych 0.6.x and below check to see if the notes ARE there, just not in a noteSkins folder
		var pixelFolder:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		var skinPostfix:String = Note.getNoteSkinPostfix();
		if (Paths.fileExists('images/$pixelFolder$texture$skinPostfix.png', IMAGE)) { // If a varient of a skin exists and is selected, load it
			skin = texture + skinPostfix;
		} else if (Paths.fileExists('images/${pixelFolder}noteSkins/$texture$skinPostfix.png', IMAGE)) { // If a noteSkins folder exists and the note is in it, use that
			skin = 'noteSkins/$texture$skinPostfix';
		}

		if(pixelNote) {
      switch (noteType)
			{
				case 'Mine Note':
					loadGraphic(Paths.image("streamervschat/pixelUI/minenote"), false);
				case 'Warning Note':
					loadGraphic(Paths.image("streamervschat/pixelUI/warningnote"), false);
				case 'Heal Note':
					loadGraphic(Paths.image("streamervschat/pixelUI/healnote"), false);
				case 'Ice Note':
					loadGraphic(Paths.image("streamervschat/pixelUI/icenote"), false);
				case 'Fake Heal Note':
					loadGraphic(Paths.image("streamervschat/pixelUI/fakehealnote"), false);
				default:
          if(isSustainNote) {
            var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
            loadGraphic(graphic, true, Math.floor(graphic.width / ExtraKeys.pixelNotesDivisionValue[graphic.width == 126 ? 1 : 0]), Math.floor(graphic.height / 2));
            originalHeight = graphic.height / 2;
          } else {
            var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
            loadGraphic(graphic, true, Math.floor(graphic.width / ExtraKeys.pixelNotesDivisionValue[graphic.width == 306 ? 1 : 0]), Math.floor(graphic.height / 5));
          }
          setGraphicSize(Std.int(width * PlayState.daPixelZoom * ExtraKeys.pixelScales[ExtraKeys.mania]));
          loadPixelNoteAnims();
          antialiasing = false;

          if(isSustainNote) {
            offsetX += _lastNoteOffX;
            _lastNoteOffX = (width - 7) * ((PlayState.daPixelZoom * ExtraKeys.pixelScales[ExtraKeys.mania]) / 2);
            offsetX -= _lastNoteOffX;
          }
      }
		} else {
      switch (noteType)
			{
				case 'Mine Note':
					loadGraphic(Paths.image("streamervschat/minenote"), false);
				case 'Warning Note':
					loadGraphic(Paths.image("streamervschat/warningnote"), false);
				case 'Heal Note':
					loadGraphic(Paths.image("streamervschat/healnote"), false);
				case 'Ice Note':
					loadGraphic(Paths.image("streamervschat/icenote"), false);
				case 'Fake Heal Note':
					loadGraphic(Paths.image("streamervschat/fakehealnote"), false);
				default:
          frames = Paths.getSparrowAtlas(skin);
          loadNoteAnims();
          if(!isSustainNote)
          {
            centerOffsets();
            centerOrigin();
          }
          antialiasing = ClientPrefs.data.globalAntialiasing;
      }
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(editors.ChartingState.GRID_SIZE, editors.ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

  function loadNoteAnims() {
		for (i in 0...gfxLetter.length)
		{
			attemptToAddAnimationByPrefix(gfxLetter[i], gfxLetter[i] + '0');
			attemptToAddAnimationByPrefix(gfxLetter[i], colArray[Note.keysShit.get(PlayfieldManager.mania[0]).get('colArray')[noteData]] + '0');
			attemptToAddAnimationByPrefix(gfxLetter[i], colArray[Note.keysShit.get(PlayfieldManager.mania[0]).get('colArray')[noteData]] + '0');

			if (isSustainNote)
			{
				attemptToAddAnimationByPrefix(gfxLetter[i] + ' tail', colArray[Note.keysShit.get(PlayfieldManager.mania[0]).get('colArray')[noteData]] + ' hold end');
				attemptToAddAnimationByPrefix(gfxLetter[i] + ' hold', colArray[Note.keysShit.get(PlayfieldManager.mania[0]).get('colArray')[noteData]] + ' hold piece');
				attemptToAddAnimationByPrefix(gfxLetter[i] + ' hold', gfxLetter[i] + ' hold');
				attemptToAddAnimationByPrefix(gfxLetter[i] + ' tail', gfxLetter[i] + ' tail');

				attemptToAddAnimationByPrefix(gfxLetter[i] + ' tail', 'pruple end hold');
				attemptToAddAnimationByPrefix(gfxLetter[i] + ' tail', colArray[Note.keysShit.get(PlayfieldManager.mania[0]).get('colArray')[noteData]] + ' hold end');

				attemptToAddAnimationByPrefix(gfxLetter[i] + ' hold', colArray[Note.keysShit.get(PlayfieldManager.mania[0]).get('colArray')[noteData]] + ' hold piece');
			}
		}

		if (isSustainNote)
			setGraphicSize(Std.int(width * scales[PlayfieldManager.mania[0]]), Std.int(defaultHeight * scales[PlayfieldManager.mania[0]] * 5));
		else
			setGraphicSize(Std.int(width * scales[PlayfieldManager.mania[0]]));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		// Optimize Anim Loading.
		var colorIndex:Int = Note.keysShit.get(PlayfieldManager.mania[0]).get('pixelAnimIndex')[noteData];
		var animName:String = gfxLetter[noteData];

		if (animName != null) {
			var graphic = Paths.image(publicTexture);
			animation.add(animName, [colorIndex + pixelNotesDivisionValue[graphic.width == 306 ? 1 : 0]]);
			if (isSustainNote)
			{
				animation.add(animName + ' hold', [colorIndex]);
				animation.add(animName + ' tail', [colorIndex + (pixelNotesDivisionValue[graphic.width == 126 ? 1 : 0] * 2)]);
			}
		}
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		try {
			var animFrames = [];
			@:privateAccess
			animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
			if(animFrames.length < 1) return;

			animation.addByPrefix(name, prefix, framerate, doLoop);
		}
		catch(e){
			//trace("Anim was null!: " + prefix);
		}
	}

	override function update(elapsed:Float)
	{
		if (Main.isPlayState() && PlayState.instance.cpuControlled) return;

		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit && !ignoreNote)
				tooLate = true;
			else tooLate = false;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if(strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	inline public function followStrum(strum:StrumNote, songSpeed:Float = 1):Void
	{
		if (isSustainNote)
		{
			flipY = strum.downScroll;
			scale.set(0.7, animation != null && animation.curAnim != null && animation.curAnim.name.endsWith('end') ? 1 : Conductor.stepCrochet * 0.0105 * (songSpeed * multSpeed) * sustainScale);

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom * 1.20;
				scale.x *= PlayState.daPixelZoom;
			}
			updateHitbox();
		}

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!ClientPrefs.downScroll) distance *= -1;

		if (copyAngle)
			angle = strum.direction - 90 + strum.angle + offsetAngle;

		if(copyAlpha)
			alpha = strum.alpha * multAlpha;

		if(copyX)
			x = strum.x + offsetX + Math.cos(strum.direction * Math.PI / 180) * distance;

		if(copyY)
		{
			y = strum.y + offsetY + (!isSustainNote || strum.downScroll ? 0 : 55) + Math.sin(strum.direction * Math.PI / 180) * distance;
			if(strum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}
		}

		if(copyScaleX)
		{
			scale.x = strum.scale.x;
			if (isSustainNote) updateHitbox();
		}
		if(copyScaleY && !isSustainNote)
		{
			scale.y = strum.scale.y;
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		final center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if (!isSustainNote || (!mustPress && ignoreNote) ||
			(mustPress && !wasGoodHit && canBeHit)) return;

		if (clipRect == null) clipRect = FlxRect.get(0, 0, frameWidth, frameHeight);
		final swagRect = clipRect;

		if (myStrum.downScroll)
		{
			if (y - offset.y * scale.y + height >= center)
			{
				swagRect.height = (center - y) / scale.y;
				swagRect.y = frameHeight - swagRect.height;
				swagRect.width = frameWidth;
			}
		}
		else if (y + offset.y * scale.y <= center)
		{
			swagRect.y = (center - y) / scale.y;
			swagRect.height = (height / scale.y) - swagRect.y;
			swagRect.width = width / scale.x;
		}

		// Bypass accessor + directly update _frame like the Codename approach
		@:bypassAccessor clipRect = swagRect;
		@:privateAccess if (frame != null && _frame != null)
			_frame = frame.clipTo(swagRect, _frame);
		dirty = true;
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect {
		@:bypassAccessor clipRect = rect;

		@:privateAccess if (frame != null) {
			if (rect != null && _frame != null)
				_frame = frame.clipTo(rect, _frame);
			else if (_frame != null)
				_frame = frame.copyTo(_frame);
			dirty = true;
		}

		return rect;
	}

	public override function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	var superCoolColor = null;
	var arr:Array<Int> = [255, 255, 255];
	var rainbowTime = 0.0;
	public function updateRGBColors(?r:FlxColor, ?g:FlxColor, ?b:FlxColor)
	{
		if (!useRGBShader) return;

		if (rgbShader == null) rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this));
		else switch(ClientPrefs.noteColorStyle)
		{
			case 'Rainbow':
			rainbowTime = (ClientPrefs.rainbowTime != 0 ? ClientPrefs.rainbowTime * 1000 : Conductor.crochet);
			superCoolColor = new FlxColor(0xFFFF0000);
			superCoolColor.hue = (strumTime / rainbowTime * 360) % 360;
			rgbShader.r = superCoolColor;
			rgbShader.g = FlxColor.WHITE;
			rgbShader.b = superCoolColor.getDarkened(0.7);

			case 'Quant-Based':
			CoolUtil.checkNoteQuant(this, (!isSustainNote ? strumTime : parentST), rgbShader);

			case 'Char-Based':
			if (PlayState.instance != null)
			{
				arr = CoolUtil.getHealthColors(doOppStuff ? PlayState.instance.dad : PlayState.instance.boyfriend);
				if (gfNote) arr = CoolUtil.getHealthColors(PlayState.instance.gf);
				if (noteData > -1)
				{
					rgbShader.r = FlxColor.fromRGB(arr[0], arr[1], arr[2]);
					rgbShader.g = FlxColor.WHITE;
					rgbShader.b = rgbShader.r;
					rgbShader.b = rgbShader.b.getDarkened(0.7);
				}
			}
			else defaultRGB();

			default:

		}
		if (noteType == 'Hurt Note' && rgbShader != null)
		{
			// note colors
			rgbShader.r = 0xFF101010;
			rgbShader.g = 0xFFFF0000;
			rgbShader.b = 0xFF990022;

			// splash data and colors
			noteSplashData.r = 0xFFFF0000;
			noteSplashData.g = 0xFF101010;
			noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
		}
		else if (rgbShader != null)
		{
			noteSplashData.r = -1;
			noteSplashData.g = -1;
			noteSplashData.b = -1;
		}
		rgbShader.r = r ?? rgbShader.r;
		rgbShader.g = g ?? rgbShader.g;
		rgbShader.b = b ?? rgbShader.b;
	}

  override function draw()
	{
		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		super.draw();
	}

	// this is used for note recycling
	// or was before I removed the option, now it's just kept for reasons
	var firstOffX = false;
	var shouldCenterOffsets:Bool = true;
	public function setupNoteData(chartNoteData:PreloadedChartNote):Void
	{
		var ns = chartNoteData.noteskin ?? "";
		var tx = chartNoteData.texture ?? "";

		wasGoodHit = hitByOpponent = tooLate = canBeHit = false; // Don't make an update call of this for the note group

		if (ns.length > 0 && ns != texture) {
			texture = 'noteskins/' + ns;
			useRGBShader = false;
		}

		if (tx.length > 0 && tx != texture) {
			texture = tx;
			shouldCenterOffsets = false;
		}

		if (ns.length < 1 && tx.length < 1 && texture != Paths.defaultSkin) {
			texture = Paths.defaultSkin;
			useRGBShader = (ClientPrefs.enableColorShader && PlayState.SONG != null && !PlayState.SONG.disableNoteRGB);
			shouldCenterOffsets = useRGBShader;
		}

		strumTime = chartNoteData.strumTime;
		noteData = chartNoteData.noteData;
		noteType = chartNoteData.noteType;
		animSuffix = chartNoteData.animSuffix;
		noAnimation = noMissAnimation = chartNoteData.noAnimation;
		mustPress = chartNoteData.mustPress;
		doOppStuff = chartNoteData.oppNote;
		gfNote = chartNoteData.gfNote;
		isSustainNote = chartNoteData.isSustainNote;
		isSustainEnd = chartNoteData.isSustainEnd;
		lowPriority = chartNoteData.lowPriority;
		multAlpha = chartNoteData.multAlpha;
		if (isSustainNote) {
			parentST = chartNoteData.parentST;
			parentSL = chartNoteData.parentSL;
		}

		hitHealth = chartNoteData.hitHealth;
		missHealth = chartNoteData.missHealth;
		hitCausesMiss = chartNoteData.hitCausesMiss ?? false;
		ignoreNote = chartNoteData.ignoreNote;
		blockHit = chartNoteData.blockHit;
		multSpeed = chartNoteData.multSpeed;
		noteDensity = chartNoteData.noteDensity;

		if (ClientPrefs.enableColorShader && useRGBShader)
		{
			if (rgbShader == null) rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this));
			updateRGBColors(
				chartNoteData.rgbShader?.r,
				chartNoteData.rgbShader?.g,
				chartNoteData.rgbShader?.b
			);
		}

		if(!inEditor) strumTime += ClientPrefs.noteOffset;

		if (noteType == 'Hurt Note' && !ClientPrefs.enableColorShader)
		{
			texture = 'HURTNOTE_assets';
			noteSplashData.texture = 'noteSplashes/HURTnoteSplashes';
		}

		if (PlayState.isPixelStage)
		{
			@:privateAccess reloadNote(texture);
			if (isSustainNote && !firstOffX)
			{
				firstOffX = true;
				offsetX += 30;
			}
		}

		if (!changeSize && !PlayState.isPixelStage)
		{
			changeSize = true;
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
		}

		if (isSustainNote) {
			offsetX += width / 2;
			copyAngle = false;
			animation.play(colArray[noteData] + (chartNoteData.isSustainEnd ? 'holdend' : 'hold'));
			updateHitbox();
			offsetX -= width / 2;

			if (!PlayState.isPixelStage)
				sustainScale = Note.SUSTAIN_SIZE / frameHeight;

			updateHitbox();
		}
		else {
			animation.play(colArray[noteData] + 'Scroll');
			if (!copyAngle) copyAngle = true;
			offsetX = 0; //Just in case we recycle a sustain note to a regular note
			if (useRGBShader && shouldCenterOffsets)
			{
				centerOffsets();
				centerOrigin();
			}
		}
		angle = 0;

		clipRect = null;
		if (!mustPress)
		{
			visible = ClientPrefs.opponentStrums;
			alpha = ClientPrefs.middleScroll ? ClientPrefs.oppNoteAlpha : 1;
		}
		else
		{
			if (!visible) visible = true;
			if (alpha != 1) alpha = 1; //if (multAlpha != 1) multAlpha = 1;
		}
		if (flipY) flipY = false;
	}
}
