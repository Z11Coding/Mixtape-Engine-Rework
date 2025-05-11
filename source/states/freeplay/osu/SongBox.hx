package states.freeplay.osu;

class SongBox extends FlxSprite
{
    public var posY:Float = 0;
    public var songID:Int = -1;

    override function update(elapsed:Float):Void {
        var targetY = FlxMath.lerp(y, (FlxG.height - height) / 2 + posY * 82, CoolUtil.boundTo(elapsed * 9, 0, 1));
        y = targetY;
    }

}

class DiffBox extends SongBox
{
    public var difID:Int = 0;
    public var difName:String = '';
}


class SongGroup extends FlxTypedGroup<SongBox>
{
    public var songBox:SongBox;
    public var diffBoxes:Array<DiffBox>;

    public function new(songBox:SongBox, diffNames:Array<String>)
    {
        super();
        this.songBox = songBox;
        this.diffBoxes = [];

        add(songBox);

        for (i in 0...diffNames.length)
        {
            var diffBox = new DiffBox();
            diffBox.difID = i;
            diffBox.difName = diffNames[i];
            diffBox.posY = i + 1; // Position below the SongBox
            diffBox.songID = songBox.songID;
            diffBoxes.push(diffBox);
            add(diffBox);
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        for (diffBox in diffBoxes)
        {
            diffBox.posY = diffBoxes.indexOf(diffBox) + 1;
        }
    }
}