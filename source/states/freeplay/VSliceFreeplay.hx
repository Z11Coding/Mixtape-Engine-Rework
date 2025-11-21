package states.freeplay;

class VsliceFreeplay extends MusicBeatState
{
    override public function create():Void
    {
        super.create();

        // Build the V-Slice freeplay menu here
        FlxG.state.openSubState(new substates.StickerSubState(null, (sticker) -> VSliceFreeplayState.build(null, sticker)));
    }
}
