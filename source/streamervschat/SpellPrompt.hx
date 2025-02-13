package streamervschat;

import flixel.ui.FlxBar;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import archipelago.APPlayState;
import states.PlayState;

class SpellPrompt extends FlxSprite
{
	var word:String;
	var wordSprite:Array<FlxText> = [];
	var charSize:Int = 24;
	var timeBar:FlxBar;
	var curChar:Int = 0;
	var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
	var letterArray:Array<String>;
	public var ttl:Float = 15;

	override public function new()
	{
		super();
		letterArray = alphabet.split("");
		loadGraphic(Paths.image("streamervschat/spell"));

		x = FlxG.random.float(0, FlxG.width - width);
		y = FlxG.random.float(0, FlxG.height - height);

		cameras = [PlayState.instance.camOther];
		PlayState.instance.add(this);

		word = FlxG.random.getObject(APPlayState.validWords);
		for (i in 0...word.length)
		{
			wordSprite[i] = new FlxText();
			wordSprite[i].text = word.charAt(i);
			wordSprite[i].setFormat(null, charSize, FlxColor.RED, CENTER, OUTLINE, FlxColor.BLACK);
			wordSprite[i].cameras = [PlayState.instance.camOther];
			if (i == 0)
			{
				wordSprite[i].x = x + width / 2 - (word.length * charSize) / 2;
				wordSprite[i].y = y + height / 2 - wordSprite[i].height / 2;
			}
			else
			{
				wordSprite[i].x = wordSprite[i - 1].x + charSize;
				wordSprite[i].y = y + height / 2 - wordSprite[i].height / 2;
			}
			PlayState.instance.add(wordSprite[i]);
		}

		timeBar = new FlxBar(0, 0, LEFT_TO_RIGHT, Std.int(width - 20), 20, this, "ttl", 0, ttl);
		timeBar.x = x + width / 2 - timeBar.width / 2;
		timeBar.y = y + height - timeBar.height - 10;
		timeBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		timeBar.cameras = [PlayState.instance.camOther];
		PlayState.instance.add(timeBar);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (curChar >= word.length - 1)
		{
			this.kill();
			this.destroy();
			return;
		}
		ttl -= FlxG.elapsed;
		for (key in FlxG.keys.getIsDown())
		{
			if ((key.justPressed && key.ID.toString().toLowerCase() == word.charAt(curChar)) || (word.charAt(curChar) == "" || word.charAt(curChar) == " " || word.charAt(curChar) == "\n") || PlayState.instance.cpuControlled) {
				var maxTries:Int = 10;
				var tries:Int = 0;
				while (tries < maxTries) {
					try {
						wordSprite[curChar].color = 0x0377fc;
						tries = 0;
						break;
					} catch (e:Dynamic) {
						trace("Error occurred while changing color: " + e);
						tries++;
					}
				}
				curChar++;
				FlxG.sound.play(Paths.sound('streamervschat/spellgood'));
			}
			else if (key.justPressed)
			{
				for (sprite in wordSprite)
					sprite.color = FlxColor.RED;
				curChar = 0;
				FlxG.sound.play(Paths.sound('streamervschat/spellbad'));
			}
		}
	}

	override public function kill()
	{
		for (i in 0...wordSprite.length)
		{
			wordSprite[i].kill();
		}
		timeBar.kill();
		super.kill();
	}

	override public function destroy()
	{
		FlxDestroyUtil.destroyArray(wordSprite);
		FlxDestroyUtil.destroy(timeBar);
		super.destroy();
	}
}