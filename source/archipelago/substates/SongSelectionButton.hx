package archipelago.substates;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Paths;

/**
 * Helper class for individual song selection button
 * Used by APPlandoSongListSubstate and APPlandoLocalSongsSubstate
 */
class SongSelectionButton extends FlxSprite
{
	private var songName:String;
	private var modName:String;
	private var labelText:FlxText;
	private var isSelected:Bool = false;
	private var isHovered:Bool = false;
	
	public function new(x:Float, y:Float, width:Float, height:Float, songName:String, modName:String)
	{
		super(x, y);
		this.songName = songName;
		this.modName = modName;
		
		makeGraphic(Std.int(width), Std.int(height), FlxColor.fromRGB(80, 80, 80));
		
		var displayText = (modName.length > 0) ? songName + "\n(" + modName + ")" : songName;
		labelText = new FlxText(0, 0, width - 10, displayText);
		labelText.setFormat(Paths.font("vcr.ttf"), 13, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		labelText.borderSize = 1;
		labelText.x = x + 5;
		labelText.y = y + Std.int(Math.max(5, (height - labelText.height) / 2));
	}
	
	public function setSelected(selected:Bool):Void
	{
		isSelected = selected;
		updateColor();
	}
	
	public function setHovered(hovered:Bool):Void
	{
		isHovered = hovered;
		updateColor();
	}
	
	private function updateColor():Void
	{
		if (isSelected)
		{
			color = FlxColor.LIME;
		}
		else if (isHovered)
		{
			color = FlxColor.YELLOW;
		}
		else
		{
			color = FlxColor.fromRGB(80, 80, 80);
		}
	}
	
	override function draw()
	{
		super.draw();
		if (labelText != null)
		{
			labelText.draw();
		}
	}
}
