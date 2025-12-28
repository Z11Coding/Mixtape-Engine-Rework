package states.freeplay;

class VSliceFreeplayMidState extends MusicBeatState
{
    //Gonna start shoving static variables that actually matter here
    /*
	 * The difficulty we were on when this menu was last accessed.
	*/
	public static var rememberedDifficulty:String = 'normal';

	/**
	 * The song we were on when this menu was last accessed.
	 * NOTE: `null` if the last song was `Random`.
	*/
	public static var rememberedSongId:Null<String> = 'tutorial';
    override public function create():Void
    {
        super.create();

        // Build the V-Slice freeplay menu here
        FlxG.state.openSubState(new substates.StickerSubState(null, (sticker) -> VSliceFreeplayState.build(null, sticker)));
    }
}
