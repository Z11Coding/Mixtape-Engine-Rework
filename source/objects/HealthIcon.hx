package objects;

enum abstract IconType(Int) to Int from Int //abstract so it can hold int values for the frame count
{
	var SINGLE = 0;
	var DEFAULT = 1;
	var WINNING = 2;
	var ANIMSINGLE = 3;
	var ANIMDEFAULT = 4;
	var ANIMWINNING = 5;
	var ANIMSINGING = 6;
}

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	public var xMod:Float = 0;
	private var char:String = '';
	public var type:IconType = DEFAULT;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12 + xMod, sprTracker.y - 30);
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon(char);
	}

	public var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

			var file:Dynamic = Paths.image(name);

			var jsonPath:String = haxe.io.Path.directory(Paths.file('images/icons/icons/'));
			var jsonData:Dynamic = null;

			// Try to load JSON file
			if (Paths.fileExists(jsonPath, TEXT)) {
				try {
					jsonData = haxe.Json.parse(Paths.modsImagesJson(jsonPath));
				} catch (e:Dynamic) {
					trace('Invalid JSON file: ' + jsonPath);
				}
			}

			if(Paths.fileExists('images/' + name + '.xml', TEXT)) { //if the icon is animated
				frames = Paths.getSparrowAtlas(name);

				// Try to load JSON file
				if (Paths.fileExists(Paths.json(name), TEXT)) {
					try {
						jsonData = haxe.Json.parse(File.getContent(Paths.json(name)));
					} catch (e:Dynamic) {
						trace('Invalid JSON file: ' + jsonPath);
					}
					var jsonType:String = jsonData.type;
					switch (jsonType) {
						case 'ANIMSINGLE': type = ANIMSINGLE;
						case 'ANIMDEFAULT': type = ANIMDEFAULT;
						case 'ANIMWINNING': type = ANIMWINNING;
						case 'ANIMSINGING': type = ANIMSINGING;
						default:
							trace('WRONG TYPE USED! DEFAULTING TO SINGLEANIM!');
							type = ANIMSINGLE;
					}
				}
				else {
					trace('ANIMATED ICON DETECTED, BUT NO ICON JSON WAS FOUND! DEFAULTING TO ANIMSINGLE');
					type = ANIMSINGLE;
				}
				updateHitbox();

				switch (type) {
					case DEFAULT:
						trace('if you see this trace you messed up somewhere bro');
					case SINGLE:
						trace('if you see this trace you messed up somewhere bro');
					case WINNING:
						trace('if you see this trace you messed up somewhere bro');
					case ANIMSINGLE:
						animation.addByPrefix('idle', 'idle', 24, true);
						animation.play('idle');
					case ANIMDEFAULT:
						animation.addByPrefix('normal', 'normal', 24, true);
						animation.addByPrefix('losing', 'losing', 24, true);
						animation.play('normal');
					case ANIMWINNING:
						animation.addByPrefix('winning', 'winning', 24, true);
						animation.addByPrefix('normal', 'normal', 24, true);
						animation.addByPrefix('losing', 'losing', 24, true);
						animation.play('normal');
					case ANIMSINGING:
						animation.addByPrefix('idle',  'idle', 24, true);
						animation.addByPrefix('left',  'left', 24, true);
						animation.addByPrefix('down',  'down', 24, true);
						animation.addByPrefix('up',    'up',   24, true);
						animation.addByPrefix('right', 'right',24, true);
						animation.play('idle');
				}
			}
			else {
				// Determine type based on JSON or fallback to size-based guessing
				if (jsonData != null && Reflect.hasField(jsonData, 'type')) {
					var jsonType:String = jsonData.type;
					switch (jsonType) {
						case 'SINGLE': type = SINGLE;
						case 'DEFAULT': type = DEFAULT;
						case 'WINNING': type = WINNING;
						default:
							trace('Invalid type in JSON: ' + jsonType);
							loadGraphic(file); // Load to guess size
							type = (width < 200 ? SINGLE : ((width > 199 && width < 301) ? DEFAULT : WINNING));
					}
				} else {
					loadGraphic(file); // Load to guess size
					type = (width < 200 ? SINGLE : ((width > 199 && width < 301) ? DEFAULT : WINNING));

					//trace('No JSON file found, guessing type based on size: ' + type + ' (' + width + 'px)');

					// Create or update JSON file with guessed type
					jsonData = { type: switch (type) {
						case SINGLE: 'SINGLE';
						case DEFAULT: 'DEFAULT';
						case WINNING: 'WINNING';
						case ANIMSINGLE: 'ANIMSINGLE';
						case ANIMDEFAULT: 'ANIMDEFAULT';
						case ANIMWINNING: 'ANIMWINNING';
						case ANIMSINGING: 'ANIMSINGING';
					}};
					if (!sys.FileSystem.exists(jsonPath)) {
						try {
							var file = sys.io.File.write(jsonPath, true); // ???
							file.close();
						} catch(e) {trace("Failed to write JSON for " + char);}
					}
					sys.io.File.saveContent(jsonPath, haxe.Json.stringify(jsonData, null, '\t'));
					//trace('Remembering this type for future use: ' + jsonPath);
				}

				loadGraphic(file, true, Math.floor(width / (type+1)), Math.floor(height));
				iconOffsets[0] = iconOffsets[1] = (width - 150) / (type+1);
				var frames:Array<Int> = [];
				for (i in 0...type+1) frames.push(i);
				updateHitbox();

				animation.add(char, frames, 0, false, isPlayer);
				animation.play(char);
			}
			
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}