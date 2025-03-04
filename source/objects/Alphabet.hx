package objects;

import haxe.Json;
import openfl.utils.Assets;

using yutautil.CollectionUtils;

interface Scrollable extends IFlxSprite {
	public var targetY:Int;
	public var distancePerItem:FlxPoint;
	public var startPosition:FlxPoint;
	function snapToPosition():Void;

	var isMenuItem:Bool;
	var scaleX(default, set):Float;
	var scaleY(default, set):Float;

	// IFlxSprite doesn't have?
	public var width(get, set):Float;
	public var height(get, set):Float;
	public var cameras(get, set):Array<FlxCamera>;
}

enum Alignment
{
	LEFT;
	CENTERED;
	RIGHT;
}

class Alphabet extends FlxSpriteGroup implements Scrollable
{
	public var text(default, set):String;

	public var bold:Bool = false;
	public var letters:Array<AlphaCharacter> = [];

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var targetX:Float = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;
	public var itemType:String = "";

	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0); // for the calculations

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
	{
		super(x, y);

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		this.text = text;
	}

	public static function isValidText(text:String):Bool
	{
		for (character in text.split(''))
		{
			if (!AlphaCharacter.allLetters.exists(character.toLowerCase()))
				return false;
		}
		return true;
	}

	public function setAlignmentFromString(align:String)
	{
		switch (align.toLowerCase().trim())
		{
			case 'right':
				alignment = RIGHT;
			case 'center' | 'centered':
				alignment = CENTERED;
			default:
				alignment = LEFT;
		}
	}

	private function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	private function updateAlignment()
	{
		for (letter in letters)
		{
			var newOffset:Float = 0;
			switch (alignment)
			{
				case CENTERED:
					newOffset = letter.rowWidth / 2;
				case RIGHT:
					newOffset = letter.rowWidth;
				default:
					newOffset = 0;
			}

			letter.offset.x -= letter.alignOffset;
			letter.alignOffset = newOffset * scale.x;
			letter.offset.x += letter.alignOffset;
		}
	}

	private function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		this.text = newText;
		return newText;
	}

	public function clearLetters()
	{
		var i:Int = letters.length;
		while (i > 0)
		{
			--i;
			var letter:AlphaCharacter = letters[i];
			if (letter != null)
			{
				letter.kill();
				letters.remove(letter);
				remove(letter);
			}
		}
		letters = [];
		rows = 0;
	}

	public function setScale(newX:Float, newY:Null<Float> = null)
	{
		var lastX:Float = scale.x;
		var lastY:Float = scale.y;
		if (newY == null)
			newY = newX;
		@:bypassAccessor
		scaleX = newX;
		@:bypassAccessor
		scaleY = newY;

		scale.x = newX;
		scale.y = newY;
		softReloadLetters(newX / lastX, newY / lastY);
	}

	private function set_scaleX(value:Float)
	{
		if (value == scaleX)
			return value;

		var ratio:Float = value / scale.x;
		scale.x = value;
		scaleX = value;
		softReloadLetters(ratio, 1);
		return value;
	}

	private function set_scaleY(value:Float)
	{
		if (value == scaleY)
			return value;

		var ratio:Float = value / scale.y;
		scale.y = value;
		scaleY = value;
		softReloadLetters(1, ratio);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ratioY:Null<Float> = null)
	{
		if (ratioY == null)
			ratioY = ratioX;

		for (letter in letters)
		{
			if (letter != null)
			{
				letter.setupAlphaCharacter((letter.x - x) * ratioX + x, (letter.y - y) * ratioY + y);
			}
		}
	}

	override function update(elapsed:Float)
	{
		var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		var lerpVal:Float = Math.exp(-elapsed * 9.6);
		switch (itemType)
		{
			case "Classic":
				y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), lerpVal);
				x = FlxMath.lerp(x, (targetY * 20) + 90, lerpVal);

			case "Vertical":
				y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.5), lerpVal);
				x = FlxMath.lerp(x, (targetY * 0) + 308, lerpVal);
				x += targetX / (lerpVal);

			case "C-Shape":
				y = FlxMath.lerp(y, (scaledY * 65) + (FlxG.height * 0.39), lerpVal);

				x = FlxMath.lerp(x, Math.exp(scaledY * 0.8) * 70 + (FlxG.width * 0.1), lerpVal);
				if (scaledY < 0)
					x = FlxMath.lerp(x, Math.exp(scaledY * -0.8) * 70 + (FlxG.width * 0.1), lerpVal);

				if (x > FlxG.width + 30)
					x = FlxG.width + 30;
			case "D-Shape":
				y = FlxMath.lerp(y, (scaledY * 90) + (FlxG.height * 0.45), lerpVal);

				x = FlxMath.lerp(x, Math.exp(scaledY * 0.8) * -70 + (FlxG.width * 0.35), lerpVal);
				if (scaledY < 0)
					x = FlxMath.lerp(x, Math.exp(scaledY * -0.8) * -70 + (FlxG.width * 0.35), lerpVal);

				if (x < -900)
					x = -900;
			default:
				if (isMenuItem)
				{
					if (changeX)
						x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x, x, lerpVal);
					if (changeY)
						y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y, y, lerpVal);
				}
		}
		super.update(elapsed);
	}

	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if (changeX)
				x = (targetY * distancePerItem.x) + startPosition.x;
			if (changeY)
				y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
		}
	}

	private static var Y_PER_ROW:Float = 85;

	private function createLetters(newText:String)
	{
		var consecutiveSpaces:Int = 0;

		var xPos:Float = 0;
		var rowData:Array<Float> = [];
		rows = 0;
		for (character in newText.split(''))
		{
			if (character != '\n')
			{
				var spaceChar:Bool = (character == " " || (bold && character == "_"));
				if (spaceChar)
					consecutiveSpaces++;

				var isAlphabet:Bool = AlphaCharacter.isTypeAlphabet(character.toLowerCase());
				if (AlphaCharacter.allLetters.exists(character.toLowerCase()) && (!bold || !spaceChar))
				{
					if (consecutiveSpaces > 0)
					{
						xPos += 28 * consecutiveSpaces * scaleX;
						rowData[rows] = xPos;
						if (!bold && xPos >= FlxG.width * 0.65)
						{
							xPos = 0;
							rows++;
						}
					}
					consecutiveSpaces = 0;

					var letter:AlphaCharacter = cast recycle(AlphaCharacter, true);
					letter.scale.x = scaleX;
					letter.scale.y = scaleY;
					letter.rowWidth = 0;

					letter.setupAlphaCharacter(xPos, rows * Y_PER_ROW * scale.y, character, bold);
					@:privateAccess letter.parent = this;

					letter.row = rows;
					var off:Float = 0;
					if (!bold)
						off = 2;
					xPos += letter.width + (letter.letterOffset[0] + off) * scale.x;
					rowData[rows] = xPos;

					add(letter);
					letters.push(letter);
				}
			}
			else
			{
				xPos = 0;
				rows++;
			}
		}

		for (letter in letters)
		{
			letter.rowWidth = rowData[letter.row];
		}

		if (letters.length > 0)
			rows++;
	}
}

class ColoredAlphabet extends Alphabet
{
	var colour:FlxColor = 0xFFFFFF;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true, ?color:FlxColor = 0xFFFFFF)
	{
		super(x, y, text, bold);
		colour = color;
		SetColor();
	}

	public function SetColor()
	{
		for (letter in letters)
		{
			letter.color = colour;
		}
	}

	public function changeLetterColor(newColor:FlxColor, ?index:Int = null, ?letter:String = null)
	{
		if (index != null && index >= 0 && index < letters.length)
		{
			letters[index].color = newColor;
		}
		else if (letter != null)
		{
			for (l in letters)
			{
				if (l.character == letter)
				{
					l.color = newColor;
				}
			}
		}
		else
		{
			colour = newColor;
			SetColor();
		}
	}

	public function rainbowify(?jump:Int = 1)
	{ var index:Int = 0;
		var numLetters = letters.length;
		for (i in 0...numLetters)
		{
			var hue = (i / numLetters) * 360; // I dunno.
			var rainbow:Array<FlxColor> = FlxColor.getHSBColorWheel();
			letters[i].color = rainbow[(index) % rainbow.length];
			index = i + jump;
		}
	}
}

	class DynamicAlphabet extends Alphabet
	{
		private var originalText:String;
		private var preserveType:Bool;

		public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true, PreserveType:Bool = false)
		{
			super(x, y, text, bold);
			this.originalText = text;
			this.preserveType = PreserveType;
		}

		override public function update(elapsed:Float):Void
		{
			super.update(elapsed);
			this.text = getRandomizedText();
		}

		private function getRandomizedText():String
		{
			var randomizedText:String = '';
			for (i in 0...originalText.length)
			{
				var char = originalText.charAt(i);
				if (preserveType)
				{
					if (isLetter(char))
					{
						randomizedText += getRandomLetter();
					}
					else if (isNumber(char))
					{
						randomizedText += getRandomNumber();
					}
					else if (isSymbol(char))
					{
						randomizedText += getRandomSymbol();
					}
				}
				else
				{
					randomizedText += getRandomCharacter();
				}
			}
			return randomizedText;
		}

		private function isLetter(char:String):Bool
		{
			return char >= 'A' && char <= 'Z' || char >= 'a' && char <= 'z';
		}

		private function isNumber(char:String):Bool
		{
			return char >= '0' && char <= '9';
		}

		private function isSymbol(char:String):Bool
		{
			return !isLetter(char) && !isNumber(char);
		}

		private function getRandomLetter():String
		{
			var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
			return letters.charAt(FlxG.random.int(0, letters.length - 1));
		}

		private function getRandomNumber():String
		{
			var numbers = "0123456789";
			return numbers.charAt(FlxG.random.int(0, numbers.length - 1));
		}

		private function getRandomSymbol():String
		{
			var symbols = "!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~";
			return symbols.charAt(FlxG.random.int(0, symbols.length - 1));
		}

		private function getRandomCharacter():String
		{
			var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~";
			return characters.charAt(FlxG.random.int(0, characters.length - 1));
		}
	}
	class DynamicColoredAlphabet extends ColoredAlphabet
	{
		private var originalText:String;
		private var preserveType:Bool;
		private var dynamicRainbow:Bool;
		private var rainbowThings:Array<flixel.addons.effects.chainable.FlxRainbowEffect>;

		private var rainbowSettings = { index: 0, jump: 1 };

		public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true, ?color:FlxColor = 0xFFFFFF, PreserveType:Bool = false)
		{
			super(x, y, text, bold, color);
			this.originalText = text;
			this.preserveType = PreserveType;
		}

		override public function update(elapsed:Float):Void
		{
			super.update(elapsed);
			this.text = getRandomizedText();
			if (dynamicRainbow)
			{
				letters.forEachT(letter -> {
					if (letter != null)
					{
						var rainbowThing = new flixel.addons.effects.chainable.FlxRainbowEffect();
						rainbowThing.apply(letter.bitmap);
						rainbowThings.push(rainbowThing);
					}
				});
				// dynamicRainbowify(rainbowSettings.jump, rainbowSettings.index);
				// rainbowSettings.index += rainbowSettings.jump;
			}
		}

		public function startDynamicRainbow(?jump:Int = 1, ?index:Int = 0):Void
		{
			dynamicRainbow = true;
			// if (rainbowThing == null)
			// {
			// 	for (letter in letters)
			// 	{
			// 		rainbowThing = new flixel.addons.effects.chainable.FlxRainbowEffect();
			// 		rainbowThing.
			// 	}
			// }

		}

		// public function setDynamicRainbow(?on:Bool, ?jump):Void
		// {
		// 	if (on != null)
		// 		dynamicRainbow = on;
		// 	if (jump != null)
		// 		rainbowSettings.jump = jump;
		// 	}
	

		// private function dynamicRainbowify(jump:Int = 1, ?startIndex:Int = 0):Void
		// {
		// 	var index:Int = 0;
		// 	var numLetters = letters.length;
		// 	for (i in 0...numLetters)
		// 	{
		// 		var hue = (i / numLetters) * 360; // I dunno.
		// 		var rainbow:Array<FlxColor> = FlxColor.getHSBColorWheel();
		// 		letters[i].color = rainbow[(index) % rainbow.length];
		// 		index = i + jump;
		// 	}
		// }

		private function getRandomizedText():String
		{
			var randomizedText:String = '';
			for (i in 0...originalText.length)
			{
				var char = originalText.charAt(i);
				if (preserveType)
				{
					if (isLetter(char))
					{
						randomizedText += getRandomLetter();
					}
					else if (isNumber(char))
					{
						randomizedText += getRandomNumber();
					}
					else if (isSymbol(char))
					{
						randomizedText += getRandomSymbol();
					}
				}
				else
				{
					randomizedText += getRandomCharacter();
				}
			}
			return randomizedText;
		}

		private function isLetter(char:String):Bool
		{
			return char >= 'A' && char <= 'Z' || char >= 'a' && char <= 'z';
		}

		private function isNumber(char:String):Bool
		{
			return char >= '0' && char <= '9';
		}

		private function isSymbol(char:String):Bool
		{
			return !isLetter(char) && !isNumber(char);
		}

		private function getRandomLetter():String
		{
			var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
			return letters.charAt(FlxG.random.int(0, letters.length - 1));
		}

		private function getRandomNumber():String
		{
			var numbers = "0123456789";
			return numbers.charAt(FlxG.random.int(0, numbers.length - 1));
		}

		private function getRandomSymbol():String
		{
			var symbols = "!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~";
			return symbols.charAt(FlxG.random.int(0, symbols.length - 1));
		}

		private function getRandomCharacter():String
		{
			var characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[]{}|;:'\",.<>?/`~";
			return characters.charAt(FlxG.random.int(0, characters.length - 1));
		}
	}
	///////////////////////////////////////////
	// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
	///////////////////////////////////////////
	/*enum LetterType
		{
		ALPHABET;
		NUMBER_OR_SYMBOL;
	}*/
	typedef Letter =
	{
		?anim:Null<String>, ?offsets:Array<Float>, ?offsetsBold:Array<Float>
	}
	class AlphaCharacter extends FlxSprite
	{
		// public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
		// public static var numbers:String = "1234567890";
		// public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";
		public var image(default, set):String;

		public static var allLetters:Map<String, Null<Letter>> = [
			// alphabet
			'a' => null,
			'b' => null,
			'c' => null,
			'd' => null,
			'e' => null,
			'f' => null,
			'g' => null,
			'h' => null,
			'i' => null,
			'j' => null,
			'k' => null,
			'l' => null,
			'm' => null,
			'n' => null,
			'o' => null,
			'p' => null,
			'q' => null,
			'r' => null,
			's' => null,
			't' => null,
			'u' => null,
			'v' => null,
			'w' => null,
			'x' => null,
			'y' => null,
			'z' => null,
			// additional alphabet
			'á' => null,
			'é' => null,
			'í' => null,
			'ó' => null,
			'ú' => null,
			'à' => null,
			'è' => null,
			'ì' => null,
			'ò' => null,
			'ù' => null,
			'â' => null,
			'ê' => null,
			'î' => null,
			'ô' => null,
			'û' => null,
			'ã' => null,
			'ë' => null,
			'ï' => null,
			'õ' => null,
			'ü' => null,
			'ä' => null,
			'ö' => null,
			'å' => null,
			'ø' => null,
			'æ' => null,
			'ñ' => null,
			'ç' => {
				offsetsBold: [0, -11]
			},
			'š' => null,
			'ž' => null,
			'ý' => null,
			'ÿ' => null,
			'ß' => null,
			// numbers
			'0' => null,
			'1' => null,
			'2' => null,
			'3' => null,
			'4' => null,
			'5' => null,
			'6' => null,
			'7' => null,
			'8' => null,
			'9' => null,
			// symbols
			'&' => {offsetsBold: [0, 2]},
			'(' => {offsetsBold: [0, 0]},
			')' => {offsetsBold: [0, 0]},
			'[' => null,
			']' => {offsets: [0, -1]},
			'*' => {offsets: [0, 28], offsetsBold: [0, 40]},
			'+' => {offsets: [0, 7], offsetsBold: [0, 12]},
			'-' => {offsets: [0, 16], offsetsBold: [0, 16]},
			'<' => {offsetsBold: [0, -2]},
			'>' => {offsetsBold: [0, -2]},
			'\'' => {anim: 'apostrophe', offsets: [0, 32], offsetsBold: [0, 40]},
			'"' => {anim: 'quote', offsets: [0, 32], offsetsBold: [0, 40]},
			'!' => {anim: 'exclamation'},
			'?' => {anim: 'question'}, // also used for "unknown"
			'.' => {anim: 'period'},
			'❝' => {anim: 'start quote', offsets: [0, 24], offsetsBold: [0, 40]},
			'❞' => {anim: 'end quote', offsets: [0, 24], offsetsBold: [0, 40]},
			'_' => null,
			'#' => null,
			'$' => null,
			'%' => null,
			':' => {offsets: [0, 2], offsetsBold: [0, 8]},
			';' => {offsets: [0, -2], offsetsBold: [0, 4]},
			'@' => null,
			'^' => {offsets: [0, 28], offsetsBold: [0, 38]},
			',' => {anim: 'comma', offsets: [0, -6], offsetsBold: [0, -4]},
			'\\' => {anim: 'back slash', offsets: [0, 0]},
			'/' => {anim: 'forward slash', offsets: [0, 0]},
			'|' => null,
			'~' => {offsets: [0, 16], offsetsBold: [0, 20]},
			// additional symbols
			'¡' => {anim: 'inverted exclamation', offsets: [0, -20], offsetsBold: [0, -20]},
			'¿' => {anim: 'inverted question', offsets: [0, -20], offsetsBold: [0, -20]},
			'{' => null,
			'}' => null,
			'•' => {anim: 'bullet', offsets: [0, 18], offsetsBold: [0, 20]}
		];

		public static function loadAlphabetData(request:String = 'alphabet')
		{
			var path:String = Paths.getPath('images/$request.json');
			#if MODS_ALLOWED
			if (!FileSystem.exists(path))
			#else
			if (!Assets.exists(path, TEXT))
			#end
			path = Paths.getPath('images/alphabet.json');

			allLetters = new Map<String, Null<Letter>>();
			try
			{
				#if MODS_ALLOWED
				var data:Dynamic = Json.parse(File.getContent(path));
				#else
				var data:Dynamic = Json.parse(Assets.getText(path));
				#end

				if (data.allowed != null && data.allowed.length > 0)
				{
					for (i in 0...data.allowed.length)
					{
						var char:String = data.allowed.charAt(i);
						if (char == ' ')
							continue;

						allLetters.set(char.toLowerCase(), null); // Allows character to be used in Alphabet
					}
				}

				if (data.characters != null)
				{
					for (char in Reflect.fields(data.characters))
					{
						var letterData = Reflect.field(data.characters, char);
						var character:String = char.toLowerCase().substr(0, 1);
						if ((letterData.animation != null || letterData.normal != null || letterData.bold != null)
							&& allLetters.exists(character))
							allLetters.set(character, {anim: letterData.animation, offsets: letterData.normal, offsetsBold: letterData.bold});
					}
				}
				trace('Reloaded letters successfully ($path)!');
			}
			catch (e:Dynamic)
			{
				FlxG.log.error('Error on loading alphabet data: $e');
				trace('Error on loading alphabet data: $e');
			}

			if (!allLetters.exists('?'))
				allLetters.set('?', {anim: 'question'});
		}

		var parent:Alphabet;

		public var alignOffset:Float = 0; // Don't change this
		public var letterOffset:Array<Float> = [0, 0];

		public var row:Int = 0;
		public var rowWidth:Float = 0;
		public var character:String = '?';

		public function new()
		{
			super(x, y);
			image = 'alphabet';
			antialiasing = ClientPrefs.data.antialiasing;
		}

		public var curLetter:Letter = null;

		public function setupAlphaCharacter(x:Float, y:Float, ?character:String = null, ?bold:Null<Bool> = null)
		{
			this.x = x;
			this.y = y;

			if (parent != null)
			{
				if (bold == null)
					bold = parent.bold;
				this.scale.x = parent.scaleX;
				this.scale.y = parent.scaleY;
			}

			if (character != null)
			{
				this.character = character;
				curLetter = null;
				var lowercase:String = this.character.toLowerCase();
				if (allLetters.exists(lowercase))
					curLetter = allLetters.get(lowercase);
				else
					curLetter = allLetters.get('?');

				var suffix:String = '';
				if (!bold)
				{
					if (isTypeAlphabet(lowercase))
					{
						if (lowercase != this.character)
							suffix = ' uppercase';
						else
							suffix = ' lowercase';
					}
					else
						suffix = ' normal';
				}
				else
					suffix = ' bold';

				var alphaAnim:String = lowercase;
				if (curLetter != null && curLetter.anim != null)
					alphaAnim = curLetter.anim;

				var anim:String = alphaAnim + suffix;
				animation.addByPrefix(anim, anim, 24);
				animation.play(anim, true);
				if (animation.curAnim == null)
				{
					if (suffix != ' bold')
						suffix = ' normal';
					anim = 'question' + suffix;
					animation.addByPrefix(anim, anim, 24);
					animation.play(anim, true);
				}
			}
			updateHitbox();
		}

		public static function isTypeAlphabet(c:String) // thanks kade
		{
			var ascii = StringTools.fastCodeAt(c, 0);
			return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122) || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246)
				|| (ascii >= 248 && ascii <= 255);
		}

		private function set_image(name:String)
		{
			if (frames == null) // first setup
			{
				image = name;
				frames = Paths.getSparrowAtlas(name);
				return name;
			}

			var lastAnim:String = null;
			if (animation != null)
			{
				lastAnim = animation.name;
			}
			image = name;
			frames = Paths.getSparrowAtlas(name);
			this.scale.x = parent.scaleX;
			this.scale.y = parent.scaleY;
			alignOffset = 0;

			if (lastAnim != null)
			{
				animation.addByPrefix(lastAnim, lastAnim, 24);
				animation.play(lastAnim, true);

				updateHitbox();
			}
			return name;
		}

		public function updateLetterOffset()
		{
			if (animation.curAnim == null)
			{
				trace(character);
				return;
			}

			var add:Float = 110;
			if (animation.curAnim.name.endsWith('bold'))
			{
				if (curLetter != null && curLetter.offsetsBold != null)
				{
					letterOffset[0] = curLetter.offsetsBold[0];
					letterOffset[1] = curLetter.offsetsBold[1];
				}
				add = 70;
			}
			else
			{
				if (curLetter != null && curLetter.offsets != null)
				{
					letterOffset[0] = curLetter.offsets[0];
					letterOffset[1] = curLetter.offsets[1];
				}
			}
			add *= scale.y;
			offset.x += letterOffset[0] * scale.x;
			offset.y += letterOffset[1] * scale.y - (add - height);
		}

		override public function updateHitbox()
		{
			super.updateHitbox();
			updateLetterOffset();
		}
	}
