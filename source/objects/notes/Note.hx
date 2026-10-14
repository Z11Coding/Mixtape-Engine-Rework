package objects.notes;

import backend.animation.PsychAnimationController;
import backend.modchartSystem.NoteData;
import objects.funkin.graphics.ZSpriteProjected;
import objects.notes.NoteTypesConfig;
import objects.notes.SustainSplash;
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

class Note extends BaseNote
{
	public var rgbShader:RGBShaderReference;

	public var texture(default, set):String = null;

	public var hitsoundDisabled:Bool = false;
	public var hitsound:String = 'hitsound';
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}

	public var useRGBShader(default, set):Bool = true;

	private function set_useRGBShader(value:Bool):Bool {
		if (useRGBShader != value)
		{
			useRGBShader = value;
			if (rgbShader != null) rgbShader.enabled = value;
		}
		return value;
	}

	private function set_texture(value:String):String {
		if (value.length == 0) value = Paths.defaultSkin;
		if (!pixelNote && texture != value)
		{
			changeSize = false;
			if (!Paths.noteSkinFramesMap.exists(value)) Paths.initNote(value);
			if (frames != @:privateAccess Paths.noteSkinFramesMap.get(value)) frames = @:privateAccess Paths.noteSkinFramesMap.get(value);
			if (animation != @:privateAccess Paths.noteSkinAnimsMap.get(value)) animation.copyFrom(@:privateAccess Paths.noteSkinAnimsMap.get(value));

			antialiasing = ClientPrefs.data.antialiasing;

			if (!changeSize)
			{
				changeSize = true;
				setGraphicSize(Std.int(width * ExtraKeys.scales[ExtraKeys.mania]));
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
		noteSplashData.texture = PlayfieldManager.SONG != null ? PlayfieldManager.SONG.splashSkin : 'noteSplashes';
		if (ClientPrefs.data.noteColorStyle == 'Normal' && rgbShader != null && useRGBShader) defaultRGB();

		if(noteData > -1 && noteType != value) {
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
      if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound);
			noteType = value;
			reloadNote();
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

	//Base Game Stuff
	/**
   * The hold note sprite for this note.
   */
  public var sustainNote:SustainNote;

	public function new(?newStrumTime:Float, ?newNoteData:Int)
	{
		super();

		this.hsvShader = new HSVNotesShader();

    noteModData = new NoteData();

		animation = new PsychAnimationController(this);

		vwooshing = false;
		this.applyAngularVelocityOffset = true;

		pixelNote = PlayState.isPixelStage;

		if (!Math.isNaN(newNoteData) && pixelNote) noteData = newNoteData;
		if (!Math.isNaN(newStrumTime)) strumTime = newStrumTime;

		if(prevNote != null)
			prevNote.nextNote = this;

		if (prevNote == null)
			prevNote = this;

		y -= 2000;
		antialiasing = ClientPrefs.data.antialiasing && !pixelNote;

		if(noteData > -1) {
			texture = '';

      try{ rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this)); }
      catch(e) {};
      if(PlayfieldManager.SONG != null && PlayfieldManager.SONG.disableNoteRGB) useRGBShader = false;

      if (PlayState.isPixelStage || getNoteSkinPostfix().toLowerCase() == '-retribution')
				rgbShader.enabled = false;

      x += BaseNote.swagWidth * (noteData % ExtraKeys.ammo[ExtraKeys.mania]);
		}

		if (isSustainNote)
		{
			alphaLimit = 0.6;
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

				var arr:Array<FlxColor> = ClientPrefs.data.noteColorStyle != 'Quant-Based' ? (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGBExtra[noteData] : ClientPrefs.data.arrowRGBPixelExtra[noteData] : ClientPrefs.data.quantRGB[noteData];
				if (arr != null && noteData > -1 && noteData <= arr.length)
				{
					newRGB.r = arr[0];
					newRGB.g = arr[1];
					newRGB.b = arr[2];
				}
			}
			return globalRgbShaders[noteData];
		}
		else switch(ClientPrefs.data.noteColorStyle)
		{
			case 'Quant-Based':
			if(globalRgbShaders[0] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[0] = newRGB;

				var arr:Array<FlxColor> = (!note.pixelNote) ? ClientPrefs.data.arrowRGBExtra[3] : ClientPrefs.data.arrowRGBPixelExtra[3];
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

				var arr:Array<FlxColor> = (!note.pixelNote) ? ClientPrefs.data.arrowRGBExtra[noteData] : ClientPrefs.data.arrowRGBPixelExtra[noteData];
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
		var lastScaleY:Float = (scale != null ? scale.y : ExtraKeys.scales[ExtraKeys.mania]);
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

		BaseNote.defaultWidth = 157;
		BaseNote.defaultHeight = 154;

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
						publicTexture = 'pixelUI/' + skinPixel + 'ENDS' + skinPostfix;
            var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
            loadGraphic(graphic, true, Math.floor(graphic.width / ExtraKeys.pixelNotesDivisionValue[graphic.width == 126 ? 1 : 0]), Math.floor(graphic.height / 2));
            originalHeight = graphic.height / 2;
          } else {
						publicTexture = 'pixelUI/' + skinPixel + skinPostfix;
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
          antialiasing = ClientPrefs.data.antialiasing;
      }
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(states.editors.ChartingState.GRID_SIZE, states.editors.ChartingState.GRID_SIZE);
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
		for (i in 0...ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters').length)
		{
			attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i], ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + '0');
			attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i], ExtraKeys.colArray4k[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + '0');
			attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i], ExtraKeys.colArray4k[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + '0');

			if (isSustainNote)
			{
				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' tail', ExtraKeys.colArray4k[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + ' hold end');
				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' hold', ExtraKeys.colArray4k[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + ' hold piece');
				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' hold', ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' hold');
				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' tail', ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' tail');

				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' tail', 'pruple end hold');
				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' tail', ExtraKeys.colArray4k[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + ' hold end');

				attemptToAddAnimationByPrefix(ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[i] + ' hold', ExtraKeys.colArray4k[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + ' hold piece');
			}
		}

		if (isSustainNote)
			setGraphicSize(Std.int(width * ExtraKeys.scales[ExtraKeys.mania]), Std.int(BaseNote.defaultHeight * ExtraKeys.scales[ExtraKeys.mania] * 5));
		else
			setGraphicSize(Std.int(width * ExtraKeys.scales[ExtraKeys.mania]));
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		// Optimize Anim Loading.
		var colorIndex:Int = ExtraKeys.keysShit.get(ExtraKeys.mania).get('pixelAnimIndex')[noteData];
		var animName:String = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData];

		if (animName != null) {
			var graphic = Paths.image(publicTexture);
			animation.add(animName, [colorIndex + ExtraKeys.pixelNotesDivisionValue[graphic.width == 306 ? 1 : 0]]);
			if (isSustainNote)
			{
				animation.add(animName + ' hold', [colorIndex]);
				animation.add(animName + ' tail', [colorIndex + (ExtraKeys.pixelNotesDivisionValue[graphic.width == 126 ? 1 : 0] * 2)]);
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
			canBeHit = (strumTime > MegaManager.conductor.musicPosition - (RConductor.safeZoneOffset * lateHitMult) &&
						strumTime < MegaManager.conductor.musicPosition + (RConductor.safeZoneOffset * earlyHitMult));

			if (strumTime < MegaManager.conductor.musicPosition - RConductor.safeZoneOffset && !wasGoodHit && !ignoreNote)
				tooLate = true;
			else tooLate = false;
		}
		else
		{
			canBeHit = false;

			if (strumTime < MegaManager.conductor.musicPosition + (RConductor.safeZoneOffset * earlyHitMult))
			{
				if(strumTime <= MegaManager.conductor.musicPosition)
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
			scale.set(ExtraKeys.scales[ExtraKeys.mania], animation != null && animation.curAnim != null && animation.curAnim.name.endsWith('tail') ? 1 : MegaManager.conductor.stepLengthMs * 0.0105 * (songSpeed * multSpeed) * sustainScale);

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom * 1.20;
				scale.x *= PlayState.daPixelZoom;
			}
			updateHitbox();
		}

		distance = (0.45 * (MegaManager.conductor.musicPosition - strumTime) * songSpeed * multSpeed);
		if (!ClientPrefs.data.downScroll) distance *= -1;

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
				y -= (frameHeight * scale.y) - (BaseNote.swagWidth / 2);
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
		final center:Float = myStrum.y + offsetY + BaseNote.swagWidth / 2;
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
		// This function should ONLY get called as you leave PlayState entirely.
    // Otherwise, we want the game to keep reusing note sprites to save memory.
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
		else switch(ClientPrefs.data.noteColorStyle)
		{
			case 'Rainbow':
			rainbowTime = (ClientPrefs.data.rainbowTime != 0 ? ClientPrefs.data.rainbowTime * 1000 : MegaManager.conductor.currentStepTime);
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
		if (this.alpha <= 0 || !this.visible || !this.alive)
    {
      return;
    }

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		var strumExtraModData = noteModData?.whichStrumNote?.strumExtraModData ?? null;
    projectionEnabled = strumExtraModData?.threeD ?? false;
    playfieldSkewCenterX = (strumExtraModData?.playfieldX ?? FlxG.width / 2);
    playfieldSkewCenterY = (strumExtraModData?.playfieldY ?? FlxG.height / 2);
    playfieldSkewCenterZ = (strumExtraModData?.playfieldZ ?? 0);

		super.draw();
	}

	// this is used for note recycling
	// or was before I removed the option, now it's just kept for reasons
	var firstOffX = false;
	var shouldCenterOffsets:Bool = true;
	public function setupNoteData(chartNoteData:PreloadNotes):Void
	{
		var ns = chartNoteData.noteskin ?? "";
		var tx = chartNoteData.texture ?? "";

		wasGoodHit = hitByOpponent = tooLate = canBeHit = false; // Don't make an update call of this for the note group

		if (ns.length > 0 && ns != texture) {
			texture = 'noteSkins/' + ns;
			useRGBShader = false;
		}

		if (tx.length > 0 && tx != texture) {
			texture = tx;
			shouldCenterOffsets = false;
		}

		if (ns.length < 1 && tx.length < 1 && texture != Paths.defaultSkin) {
			texture = Paths.defaultSkin;
			useRGBShader = (ClientPrefs.data.enableColorShader && PlayfieldManager.SONG != null && !PlayfieldManager.SONG.disableNoteRGB);
			shouldCenterOffsets = useRGBShader;
		}

		stealthGlow = 0.0;
    stealthGlowBlue = 1.0;
    stealthGlowGreen = 1.0;
    stealthGlowRed = 1.0;
		updateStealthGlow();

		noteModData.clearNoteMods();
		angleAngularVelocityOffset = 0;
		angularVelocity = 0;
		spinVelocity = 0;
		spinAngle = 0;
		graphic.destroyOnNoUse = false;
		hitWindowMultiplier = 1.0;

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
		row = chartNoteData.row;

		if (ClientPrefs.data.enableColorShader && useRGBShader)
		{
			if (rgbShader == null) rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData, this));
			updateRGBColors(
				chartNoteData.rgbShader?.r,
				chartNoteData.rgbShader?.g,
				chartNoteData.rgbShader?.b
			);
		}

		if(!inEditor) strumTime += ClientPrefs.data.noteOffset;

		if (noteType == 'Hurt Note' && !ClientPrefs.data.enableColorShader)
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
			setGraphicSize(Std.int(width * ExtraKeys.scales[ExtraKeys.mania]));
			updateHitbox();
		}

		if (isSustainNote) {
			offsetX += width / 2;
			copyAngle = false;
			var animToPlay:String = '';
			animToPlay = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData] + (chartNoteData.isSustainEnd ? ' tail' : ' hold');
			if (!animation.exists(animToPlay))
			{
				animToPlay = ExtraKeys.colArray[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]] + (chartNoteData.isSustainEnd ? ' holdend' : ' hold');
			}
			animation.play(animToPlay);
			updateHitbox();
			offsetX -= width / 2;

			if (!PlayState.isPixelStage)
				sustainScale = BaseNote.SUSTAIN_SIZE / frameHeight;

			updateHitbox();
		}
		else {
			var animToPlay:String = '';
			animToPlay = ExtraKeys.keysShit.get(ExtraKeys.mania).get('letters')[noteData];
			if (animation.exists(animToPlay))
				animation.play(animToPlay);
			else
			{
				animToPlay = ExtraKeys.colArray[ExtraKeys.keysShit.get(ExtraKeys.mania).get('colArray')[noteData]];
				animation.play(animToPlay + 'Scroll');
			}
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
			visible = ClientPrefs.data.opponentStrums;
			alpha = ClientPrefs.data.middleScroll ? ClientPrefs.data.oppNoteAlpha : 1;
		}
		else
		{
			if (!visible) visible = true;
			if (alpha != 1) alpha = 1; //if (multAlpha != 1) multAlpha = 1;
		}
		if (flipY) flipY = false;

		var rowArray = MegaManager.playfield.noteRows[mustPress?0:1];
		if(rowArray[row]==null)
			rowArray[row]=[];
		rowArray[row].push(this);
	}

	 // call this to reset stealthGlow back to default values
  public function resetStealthGlow(skipUpdate:Bool = false):Void
  {
    this.stealthGlow = 0.0;
    this.stealthGlowBlue = 1.0;
    this.stealthGlowGreen = 1.0;
    this.stealthGlowRed = 1.0;
    if (!skipUpdate) updateStealthGlow();
  }

  // call this to update the stealthglow on the hsv shader
  public function updateStealthGlow():Void
  {
    this.hsvShader.stealthGlow = stealthGlow;
    this.hsvShader.stealthGlowBlue = stealthGlowBlue;
    this.hsvShader.stealthGlowGreen = stealthGlowGreen;
    this.hsvShader.stealthGlowRed = stealthGlowRed;

		var rgbConvert = FlxColor.fromRGB(stealthGlowRed, stealthGlowGreen, stealthGlowBlue, stealthGlow);
		this.rgbShader.mult = rgbConvert.alphaFloat;
		this.updateRGBColors(rgbConvert, rgbConvert, rgbConvert);
  }

	override public function kill():Void
  {
    super.kill();
    vwooshing = false;
  }
}
