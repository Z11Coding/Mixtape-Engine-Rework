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
			var jsonData:Dynamic = null;

			// Try to load JSON file
			if (Paths.fileExists('images/$name.json', TEXT)) {
				try {
					jsonData = haxe.Json.parse(File.getContent(Paths.getPath('images/$name.json', TEXT)));
				} catch (e:Dynamic) {
					trace('Invalid JSON file: ' + name);
				}
			}

			if(Paths.fileExists('images/' + name + '.xml', TEXT)) { //if the icon is animated
				frames = Paths.getSparrowAtlas(name);

				// Try to load JSON file
				if (Paths.fileExists('images/' + name + '.json', TEXT)) {
					try {
						jsonData = haxe.Json.parse(File.getContent(Paths.getPath('images/$name.json', TEXT)));
					} catch (e:Dynamic) {
						trace('Invalid JSON file: ' + name);
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
						trace('Loaded Anim Single!');
						animation.addByPrefix('idle', 'idle', 24, true, isPlayer);
						animation.play('idle', true);
					case ANIMDEFAULT:
						trace('Loaded Anim Default!');
						animation.addByPrefix('normal', 'normal', 24, true, isPlayer);
						animation.addByPrefix('losing', 'losing', 24, true, isPlayer);
						animation.play('normal', true);
					case ANIMWINNING:
						trace('Loaded Anim Winning!');
						animation.addByPrefix('winning', 'winning', 24, true, isPlayer);
						animation.addByPrefix('normal', 'normal', 24, true, isPlayer);
						animation.addByPrefix('losing', 'losing', 24, true, isPlayer);
						animation.play('normal', true);
					case ANIMSINGING:
						trace('Loaded Anim Singing!');
						animation.addByPrefix('idle',  'idle', 24, true, isPlayer);
						animation.addByPrefix('left',  'left', 24, true, isPlayer);
						animation.addByPrefix('down',  'down', 24, true, isPlayer);
						animation.addByPrefix('up',    'up',   24, true, isPlayer);
						animation.addByPrefix('right', 'right',24, true, isPlayer);
						animation.play('idle', true);
				}

			}
			else {
				// Determine type based on JSON or fallback to size-based guessing
				if (jsonData != null && Reflect.hasField(jsonData, 'type')) {
					var jsonType:String = jsonData.type;
					switch (jsonType) {
						case 'SINGLE':
							loadGraphic(file);
							type = SINGLE;
						case 'DEFAULT':
							loadGraphic(file);
							type = DEFAULT;
						case 'WINNING':
							loadGraphic(file);
							type = WINNING;
						default:
							trace('Invalid type in JSON: ' + jsonType);
							loadGraphic(file); // Load to guess size
							type = (width < 200 ? SINGLE : ((width > 199 && width < 301) ? DEFAULT : WINNING));
					}
				} else {
					loadGraphic(file); // Load to guess size
					type = (width < 200 ? SINGLE : ((width > 199 && width < 301) ? DEFAULT : WINNING));
					//trace('Remembering this type for future use: ' + jsonPath);
				}

				var iSize:Float = ((Math.round(width / height)) + (type+1)); // I love math (this is a lie)
				loadGraphic(file, true, Math.floor(width / iSize), Math.floor(height));
				iconOffsets[0] = (width - 150) / iSize;
				iconOffsets[1] = (height - 150) / iSize;
				updateHitbox();

				var frames:Array<Int> = [];
				for (i in 0...type+1) frames.push(i);

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
