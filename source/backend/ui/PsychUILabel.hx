package backend.ui;

class PsychUILabel extends FlxSprite
{
    public var text:FlxText;

    public function new(x:Float, y:Float, labelText:String, ?width:Int = 200)
    {
        super(x, y);

        // Create transparent background
        makeGraphic(width, 20, FlxColor.TRANSPARENT);

        text = new FlxText(0, 0, width, labelText);
        text.color = FlxColor.WHITE;
        text.alignment = LEFT;
        text.size = 12;
    }

    override function draw()
    {
        super.draw();

        if (text != null && text.exists && text.visible) {
            text.x = x;
            text.y = y + height/2 - text.height/2;
            text.draw();
        }
    }

    override function destroy()
    {
        if (text != null) {
            text.destroy();
            text = null;
        }
        super.destroy();
    }

    public function setLabel(newText:String)
    {
        if (text != null) {
            text.text = newText;
        }
    }
}
